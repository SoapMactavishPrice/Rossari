public with sharing class ExpenseController {
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> initializeExpense() {
        Map<String, Object> result = new Map<String, Object>();
        try {
            User currentUser = [SELECT Id, Name, Division, Zone__c, Cost_Center__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            
            List<Map<String, String>> voucherOptions = new List<Map<String, String>>();
            for (Schema.PicklistEntry entry : Expense__c.Type_of_Voucher__c.getDescribe().getPicklistValues()) {
                if (entry.isActive()) {
                    voucherOptions.add(new Map<String, String>{
                        'label' => entry.getLabel(),
                        'value' => entry.getValue()
                    });
                }
            }
            
            // Get Cost Center record ID based on user's Cost_Center__c picklist value
            Id costCenterId = null;
            if (String.isNotBlank(currentUser.Cost_Center__c)) {
                List<Cost_Center__c> costCenters = [SELECT Id FROM Cost_Center__c 
                                                   WHERE Name = :currentUser.Cost_Center__c 
                                                   LIMIT 1];
                if (!costCenters.isEmpty()) {
                    costCenterId = costCenters[0].Id;
                }
            }
            
            result.put('currentUser', currentUser);
            result.put('voucherOptions', voucherOptions);
            result.put('costCenterId', costCenterId); // Add the actual Cost Center record ID
            
        } catch (Exception e) {
            throw new AuraHandledException('Error initializing expense: ' + e.getMessage());
        }
        return result;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getUsers(String searchTerm) {
        try {
            searchTerm = '%' + String.escapeSingleQuotes(searchTerm) + '%';
            List<User> users = [SELECT Id, Name, Division, Zone__c, Cost_Center__c 
                                FROM User 
                                WHERE Name LIKE :searchTerm 
                                AND IsActive = true
                                ORDER BY Name 
                                LIMIT 50];
            
            List<Map<String, String>> options = new List<Map<String, String>>();
            for (User u : users) {
                options.add(new Map<String, String>{
                    'label' => u.Name,
                        'value' => u.Id,
                        'division' => u.Division != null ? u.Division : '',
                            'zone' => u.Zone__c != null ? u.Zone__c : '',
                                'costCenter' => u.Cost_Center__c != null ? u.Cost_Center__c : ''
                                });
            }
            return options;
        } catch (Exception e) {
            throw new AuraHandledException('Error getting users: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getTypeOfExpense(String searchTerm, String voucherType) {
        try {
            String query = 'SELECT Id, Name, Type_of_Voucher__c, GL_Code__c, GL_Code__r.Name FROM Type_of_Expense__c ';
            List<String> conditions = new List<String>();
            
            if (String.isNotBlank(searchTerm)) {
                conditions.add('Name LIKE \'%' + String.escapeSingleQuotes(searchTerm) + '%\'');
            }
            
            if (String.isNotBlank(voucherType)) {
                conditions.add('Type_of_Voucher__c = \'' + String.escapeSingleQuotes(voucherType) + '\'');
            }
            
            if (!conditions.isEmpty()) {
                query += 'WHERE ' + String.join(conditions, ' AND ');
            }
            
            query += ' ORDER BY Name LIMIT 50';
            
            List<Type_of_Expense__c> expenses = Database.query(query);
            
            List<Map<String, String>> options = new List<Map<String, String>>();
            for (Type_of_Expense__c e : expenses) {
                options.add(new Map<String, String>{
                    'label' => e.Name,
                    'value' => e.Id,
                    'name' => e.Name, // Add the name to identify Public/Private
                        'glCodeId' => e.GL_Code__c != null ? e.GL_Code__c : '',
                    'glCodeName' => e.GL_Code__r != null ? e.GL_Code__r.Name : ''
                });
            }
            return options;
        } catch (Exception e) {
            throw new AuraHandledException('Error getting expense types: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getExpenseRecordTypes() {
        Map<String, String> recordTypeMap = new Map<String, String>();
        try {
            for (RecordType rt : [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Expense__c']) {
                recordTypeMap.put(rt.DeveloperName, rt.Id);
            }
        } catch (Exception e) {
            System.debug('Error getting record types: ' + e.getMessage());
        }
        return recordTypeMap;
    }
    
    @AuraEnabled
    public static String createExpenseWithFiles(
        Expense__c expense,
        List<Expense_Line_Item__c> lineItems,
        Map<String, List<String>> filesPerLineItem
    ) {
        Savepoint sp = Database.setSavepoint();
        try {
            // Get current user with Entity Code fields
            User currentUser = [SELECT Id, Cost_Center__c, Entity_Code_1__c, Entity_Code_2__c, Entity_Code_3__c 
                               FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            
            // Determine record type based on Entity Codes
            String recordTypeId = determineRecordType(currentUser);
            if (String.isNotBlank(recordTypeId)) {
                expense.RecordTypeId = recordTypeId;
            }
            
            // Set Cost Center
            if (String.isNotBlank(currentUser.Cost_Center__c)) {
                List<Cost_Center__c> costCenters = [SELECT Id FROM Cost_Center__c 
                                                   WHERE Name = :currentUser.Cost_Center__c 
                                                   LIMIT 1];
                if (!costCenters.isEmpty()) {
                    expense.Cost_Center__c = costCenters[0].Id;
                }
            }
            
            // Set default currency
            if (expense.CurrencyIsoCode == null) {
                expense.CurrencyIsoCode = 'INR';
            }
            
            insert expense;
            
            // Process line items and GL codes
            Map<Id, Id> expenseTypeToGLCodeMap = new Map<Id, Id>();
            Set<Id> typeOfExpenseIds = new Set<Id>();
            for (Expense_Line_Item__c li : lineItems) {
                if (li.Type_of_Expense__c != null) {
                    typeOfExpenseIds.add(li.Type_of_Expense__c);
                }
            }
            
            if (!typeOfExpenseIds.isEmpty()) {
                for (Type_of_Expense__c et : [
                    SELECT Id, GL_Code__c
                    FROM Type_of_Expense__c
                    WHERE Id IN :typeOfExpenseIds
                ]) {
                    if (et.GL_Code__c != null) {
                        expenseTypeToGLCodeMap.put(et.Id, et.GL_Code__c);
                    }
                }
            }
            
            // Prepare and insert line items
            List<Expense_Line_Item__c> createdItems = new List<Expense_Line_Item__c>();
            for (Expense_Line_Item__c li : lineItems) {
                li.Expense__c = expense.Id;
                
                // Map GL Code from Type_of_Expense__c
                if (li.Type_of_Expense__c != null && expenseTypeToGLCodeMap.containsKey(li.Type_of_Expense__c)) {
                    li.GL_Code__c = expenseTypeToGLCodeMap.get(li.Type_of_Expense__c);
                }
                
                createdItems.add(li);
            }
            
            if (!createdItems.isEmpty()) {
                insert createdItems;
            }
            
            // Process file attachments
            if (filesPerLineItem != null && !filesPerLineItem.isEmpty()) {
                List<ContentDocumentLink> linksToCreate = new List<ContentDocumentLink>();
                
                for (Integer i = 0; i < createdItems.size(); i++) {
                    String indexKey = String.valueOf(i);
                    if (filesPerLineItem.containsKey(indexKey)) {
                        List<String> documentIds = filesPerLineItem.get(indexKey);
                        
                        for (String docId : documentIds) {
                            if (String.isNotBlank(docId)) {
                                ContentDocumentLink newLink = new ContentDocumentLink();
                                newLink.ContentDocumentId = docId;
                                newLink.LinkedEntityId = createdItems[i].Id;
                                newLink.ShareType = 'V';
                                newLink.Visibility = 'AllUsers';
                                
                                linksToCreate.add(newLink);
                            }
                        }
                    }
                }
                
                if (!linksToCreate.isEmpty()) {
                    insert linksToCreate;
                }
            }
            
            return expense.Id;
            
        } catch (Exception e) {
            Database.rollback(sp);
            throw new AuraHandledException('Error creating expense: ' + e.getMessage() + ' at line: ' + e.getLineNumber());
        }
    }
    
    // Method to determine record type based on Entity Codes
    private static String determineRecordType(User currentUser) {
        Map<String, String> recordTypeMap = getExpenseRecordTypes();
        String recordTypeId = null;
        
        // Check Entity_Code_1__c for RBL record type
        if (currentUser.Entity_Code_1__c == '1000' && recordTypeMap.containsKey('RBL')) {
            recordTypeId = recordTypeMap.get('RBL');
        }
        // Check Entity_Code_2__c or Entity_Code_3__c for Unitop/Tristar record type
        else if ((currentUser.Entity_Code_2__c == '3000' || currentUser.Entity_Code_3__c == '4000') && 
                 recordTypeMap.containsKey('Unitop_Tristar')) {
            // Use the exact Developer Name of your record type
            recordTypeId = recordTypeMap.get('Unitop_Tristar');
        }
        
        return recordTypeId;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getTransportModes() {
        try {
            List<Map<String, String>> options = new List<Map<String, String>>();
            
            // Get picklist values from Mode_of_Transport__c field on Expense_Line_Item__c
            Schema.DescribeFieldResult fieldResult = Expense_Line_Item__c.Mode_of_Transport__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            
            for (Schema.PicklistEntry entry : ple) {
                if (entry.isActive()) {
                    options.add(new Map<String, String>{
                        'label' => entry.getLabel(),
                            'value' => entry.getValue()
                            });
                }
            }
            
            return options;
        } catch (Exception e) {
            throw new AuraHandledException('Error getting transport modes: ' + e.getMessage());
        }
    }
    
    private static void handleFileAttachments(
        List<Expense_Line_Item__c> lineItems,
        Map<String, Object> filesPerLineItem
    ) {
        List<ContentDocumentLink> linksToCreate = new List<ContentDocumentLink>();
        Set<Id> contentVersionIds = new Set<Id>();
        
        // Collect ContentVersion IDs
        for (String indexStr : filesPerLineItem.keySet()) {
            List<Object> fileIds = (List<Object>)filesPerLineItem.get(indexStr);
            if (fileIds != null) {
                for (Object fileId : fileIds) {
                    contentVersionIds.add((Id)fileId);
                }
            }
        }
        
        // Map ContentVersionId to ContentDocumentId
        Map<Id, Id> versionToDocumentMap = new Map<Id, Id>();
        for (ContentVersion cv : [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id IN :contentVersionIds
        ]) {
            versionToDocumentMap.put(cv.Id, cv.ContentDocumentId);
        }
        
        // Create ContentDocumentLinks
        for (String indexStr : filesPerLineItem.keySet()) {
            Integer index = Integer.valueOf(indexStr);
            if (index >= 0 && index < lineItems.size()) {
                Expense_Line_Item__c lineItem = lineItems[index];
                List<Object> fileIds = (List<Object>)filesPerLineItem.get(indexStr);
                
                for (Object fileIdObj : fileIds) {
                    Id versionId = (Id)fileIdObj;
                    Id docId = versionToDocumentMap.get(versionId);
                    
                    if (docId != null) {
                        linksToCreate.add(new ContentDocumentLink(
                            LinkedEntityId = lineItem.Id,
                            ContentDocumentId = docId,
                            ShareType = 'I',
                            Visibility = 'AllUsers'
                        ));
                    }
                }
            }
        }
        
        if (!linksToCreate.isEmpty()) {
            insert linksToCreate;
        }
    }
    
    
    
    private static Boolean isValidId(String idString) {
        try {
            Id testId = idString;
            return testId != null;
        } catch (Exception e) {
            return false;
        }
    }
    
    private static Map<Id, Set<Id>> getExistingContentDocumentLinks(Set<Id> documentIds) {
        Map<Id, Set<Id>> existingLinks = new Map<Id, Set<Id>>();
        
        for (ContentDocumentLink link : [
            SELECT ContentDocumentId, LinkedEntityId 
            FROM ContentDocumentLink 
            WHERE ContentDocumentId IN :documentIds
        ]) {
            if (!existingLinks.containsKey(link.ContentDocumentId)) {
                existingLinks.put(link.ContentDocumentId, new Set<Id>());
            }
            existingLinks.get(link.ContentDocumentId).add(link.LinkedEntityId);
        }
        
        return existingLinks;
    }
    
    private static Boolean isAlreadyLinked(Map<Id, Set<Id>> existingLinks, Id documentId, Id entityId) {
        return existingLinks.containsKey(documentId) && existingLinks.get(documentId).contains(entityId);
    }
    
    private static ContentDocumentLink createContentDocumentLink(Id documentId, Id entityId) {
        return new ContentDocumentLink(
            LinkedEntityId = entityId,
            ContentDocumentId = documentId,
            ShareType = 'I', // Inferred permission
            Visibility = 'AllUsers' // Visible to all users with access to the record
        );
    }
    
   @AuraEnabled
    public static Id createCustomerVisit(Id tourId, Id accountId) {
        try {
            // Validate inputs
            if (tourId == null) {
                throw new AuraHandledException('Tour ID is required.');
            }
            if (accountId == null) {
                throw new AuraHandledException('Account ID is required.');
            }

            // Check if Customer_Visited__c already exists
            List<Customer_Visited__c> existingVisits = [
                SELECT Id 
                FROM Customer_Visited__c 
                WHERE Tour__c = :tourId AND Account__c = :accountId
                LIMIT 1
            ];
            
            if (!existingVisits.isEmpty()) {
                return existingVisits[0].Id;
            }

            // Get account details
            Account acc = [SELECT Id, Name FROM Account WHERE Id = :accountId LIMIT 1];

            // Create new Customer_Visited__c record
            Customer_Visited__c visit = new Customer_Visited__c();
            visit.Tour__c = tourId;
            visit.Account__c = accountId;
            visit.Name = acc.Name;

            insert visit;
            return visit.Id;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error creating Customer Visit: ' + e.getMessage());
        }
    }


    @AuraEnabled(cacheable=true)
public static List<Map<String, String>> getSalesTypeOptions() {
    try {
        System.debug('Starting getSalesTypeOptions method');
        
        List<Map<String, String>> options = new List<Map<String, String>>();
        
        // First, let's check if Expense__c object is accessible
        if (!Schema.getGlobalDescribe().containsKey('Expense__c')) {
            throw new AuraHandledException('Expense__c object not found');
        }
        
        // Get the object describe
        Schema.DescribeSObjectResult objDescribe = Expense__c.sObjectType.getDescribe();
        if (!objDescribe.isAccessible()) {
            throw new AuraHandledException('Expense__c object is not accessible');
        }
        
        // Check if Sales_Type__c field exists and is accessible
        Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
        if (!fieldMap.containsKey('Sales_Type__c')) {
            throw new AuraHandledException('Sales_Type__c field not found on Expense__c object');
        }
        
        Schema.SObjectField salesTypeField = fieldMap.get('Sales_Type__c');
        Schema.DescribeFieldResult fieldResult = salesTypeField.getDescribe();
        
        if (!fieldResult.isAccessible()) {
            throw new AuraHandledException('Sales_Type__c field is not accessible');
        }
        
        // Get picklist values
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        System.debug('Number of picklist entries found: ' + ple.size());
        
        for (Schema.PicklistEntry entry : ple) {
            System.debug('Processing picklist entry: ' + entry.getLabel() + ' - ' + entry.getValue() + ' - Active: ' + entry.isActive());
            if (entry.isActive()) {
                options.add(new Map<String, String>{
                    'label' => entry.getLabel(),
                    'value' => entry.getValue()
                });
            }
        }
        
        System.debug('Final options count: ' + options.size());
        
        // If no active options found, return empty list
        return options;
        
    } catch (Exception e) {
        System.debug('Error in getSalesTypeOptions: ' + e.getMessage() + ' - Stack: ' + e.getStackTraceString());
        throw new AuraHandledException('Failed to load Sales Type options: ' + e.getMessage());
    }
}
    
}