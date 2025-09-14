public with sharing class ExpenseController {
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> initializeExpense() {
        Map<String, Object> result = new Map<String, Object>();
        try {
            User currentUser = [SELECT Id, Name, Division, Zone__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            
            List<Map<String, String>> voucherOptions = new List<Map<String, String>>();
            for (Schema.PicklistEntry entry : Expense__c.Type_of_Voucher__c.getDescribe().getPicklistValues()) {
                if (entry.isActive()) {
                    voucherOptions.add(new Map<String, String>{
                        'label' => entry.getLabel(),
                            'value' => entry.getValue()
                            });
                }
            }
            
            result.put('currentUser', currentUser);
            result.put('voucherOptions', voucherOptions);
            
        } catch (Exception e) {
            throw new AuraHandledException('Error initializing expense: ' + e.getMessage());
        }
        return result;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getUsers(String searchTerm) {
        try {
            searchTerm = '%' + String.escapeSingleQuotes(searchTerm) + '%';
            List<User> users = [SELECT Id, Name, Division, Zone__c 
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
                            'zone' => u.Zone__c != null ? u.Zone__c : ''
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
            String query = 'SELECT Id, Name, Type_of_Voucher__c FROM Type_of_Expense__c ';
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
                    'name' => e.Name // Add the name to identify Public/Private
                });
            }
            return options;
        } catch (Exception e) {
            throw new AuraHandledException('Error getting expense types: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String createExpenseWithFiles(
        Expense__c expense,
        List<Expense_Line_Item__c> lineItems,
        Map<String, List<String>> filesPerLineItem) {
            
            insert expense;
            
            List<Expense_Line_Item__c> createdItems = new List<Expense_Line_Item__c>();
            for (Expense_Line_Item__c li : lineItems) {
                li.Expense__c = expense.Id;
                createdItems.add(li);
            }
            insert createdItems;
            
            // Re-parent uploaded files to correct Expense_Line_Item__c
            List<ContentDocumentLink> links = new List<ContentDocumentLink>();
            for (Integer i = 0; i < createdItems.size(); i++) {
                if (filesPerLineItem.containsKey(String.valueOf(i))) {
                    for (String docId : filesPerLineItem.get(String.valueOf(i))) {
                        links.add(new ContentDocumentLink(
                            ContentDocumentId = docId,
                            LinkedEntityId = createdItems[i].Id,
                            ShareType = 'V', // View
                            Visibility = 'AllUsers'
                        ));
                    }
                }
            }
            insert links;
            
            // Return the created expense record ID for navigation
            return expense.Id;
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


    
    
}