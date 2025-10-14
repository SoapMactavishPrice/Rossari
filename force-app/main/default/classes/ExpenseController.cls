public with sharing class ExpenseController {
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> initializeExpense() {
        Map<String, Object> result = new Map<String, Object>();
        try {
            // Get current user with Grade field
            User currentUser = [SELECT Id, Name, Division, Zone__c, Cost_Center__c, Grades__c 
                               FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            
            List<Map<String, String>> voucherOptions = new List<Map<String, String>>();
            for (Schema.PicklistEntry entry : Expense__c.Type_of_Voucher__c.getDescribe().getPicklistValues()) {
                if (entry.isActive()) {
                    voucherOptions.add(new Map<String, String>{
                        'label' => entry.getLabel(),
                        'value' => entry.getValue()
                    });
                }
            }
            
            // Get Cost Center record ID
            Id costCenterId = null;
            if (String.isNotBlank(currentUser.Cost_Center__c)) {
                List<Cost_Center__c> costCenters = [SELECT Id FROM Cost_Center__c 
                                                   WHERE Name = :currentUser.Cost_Center__c 
                                                   LIMIT 1];
                if (!costCenters.isEmpty()) {
                    costCenterId = costCenters[0].Id;
                }
            }
            
            // Get Grade details based on user's grade - FIXED
            Decimal dailyAllowance = 0;
            Decimal fourWheelerPerKm = 0;
            Decimal twoWheelerPerKm = 0;
            List<String> modeOfTravelOptions = new List<String>();
            Boolean canEditDailyAllowance = false;
            
            System.debug('User Grade: ' + currentUser.Grades__c);
            
            if (String.isNotBlank(currentUser.Grades__c)) {
                List<Grade__c> grades = [SELECT Id, Name, Daily_Allowance_A_class_cities__c, 
                                        Daily_Allowance_B_class_cities__c, Four_Wheeler_per_km__c, 
                                        Two_Wheeler_per_km__c, Mode_of_Travel__c
                                        FROM Grade__c 
                                        WHERE Name = :currentUser.Grades__c 
                                        LIMIT 1];
                
                System.debug('Found grades: ' + grades.size());
                
                if (!grades.isEmpty()) {
                    Grade__c userGrade = grades[0];
                    dailyAllowance = userGrade.Daily_Allowance_A_class_cities__c != null ? userGrade.Daily_Allowance_A_class_cities__c : 0;
                    fourWheelerPerKm = userGrade.Four_Wheeler_per_km__c != null ? userGrade.Four_Wheeler_per_km__c : 0;
                    twoWheelerPerKm = userGrade.Two_Wheeler_per_km__c != null ? userGrade.Two_Wheeler_per_km__c : 0;
                    
                    System.debug('Grade Details - DA: ' + dailyAllowance + ', 4W: ' + fourWheelerPerKm + ', 2W: ' + twoWheelerPerKm);
                    
                    // Parse multi-picklist values
                    if (String.isNotBlank(userGrade.Mode_of_Travel__c)) {
                        modeOfTravelOptions = userGrade.Mode_of_Travel__c.split(';');
                        System.debug('Mode of Travel Options: ' + modeOfTravelOptions);
                    }
                    
                    // Check if user can edit daily allowance (only for DR or EM grades)
                    canEditDailyAllowance = (currentUser.Grades__c == 'DR' || currentUser.Grades__c == 'EM');
                }
            }
            
            result.put('currentUser', currentUser);
            result.put('voucherOptions', voucherOptions);
            result.put('costCenterId', costCenterId);
            result.put('dailyAllowance', dailyAllowance);
            result.put('fourWheelerPerKm', fourWheelerPerKm);
            result.put('twoWheelerPerKm', twoWheelerPerKm);
            result.put('modeOfTravelOptions', modeOfTravelOptions);
            result.put('canEditDailyAllowance', canEditDailyAllowance);
            
        } catch (Exception e) {
            System.debug('Error in initializeExpense: ' + e.getMessage() + ' - ' + e.getStackTraceString());
            throw new AuraHandledException('Error initializing expense: ' + e.getMessage());
        }
        return result;
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getGradeDetails(String gradeName) {
        try {
            Map<String, Object> result = new Map<String, Object>();
            
            System.debug('getGradeDetails called with: ' + gradeName);
            
            if (String.isBlank(gradeName)) {
                return result;
            }
            
            List<Grade__c> grades = [SELECT Id, Name, Daily_Allowance_A_class_cities__c, 
                                    Daily_Allowance_B_class_cities__c, Four_Wheeler_per_km__c, 
                                    Two_Wheeler_per_km__c, Mode_of_Travel__c
                                    FROM Grade__c 
                                    WHERE Name = :gradeName 
                                    LIMIT 1];
            
            System.debug('Found grades for ' + gradeName + ': ' + grades.size());
            
            if (!grades.isEmpty()) {
                Grade__c grade = grades[0];
                result.put('dailyAllowance', grade.Daily_Allowance_A_class_cities__c != null ? grade.Daily_Allowance_A_class_cities__c : 0);
                result.put('fourWheelerPerKm', grade.Four_Wheeler_per_km__c != null ? grade.Four_Wheeler_per_km__c : 0);
                result.put('twoWheelerPerKm', grade.Two_Wheeler_per_km__c != null ? grade.Two_Wheeler_per_km__c : 0);
                
                System.debug('Grade details - DA: ' + result.get('dailyAllowance') + 
                           ', 4W: ' + result.get('fourWheelerPerKm') + 
                           ', 2W: ' + result.get('twoWheelerPerKm'));
                
                // Parse multi-picklist values
                List<String> modeOfTravelOptions = new List<String>();
                if (String.isNotBlank(grade.Mode_of_Travel__c)) {
                    modeOfTravelOptions = grade.Mode_of_Travel__c.split(';');
                    System.debug('Mode of Travel Options: ' + modeOfTravelOptions);
                }
                result.put('modeOfTravelOptions', modeOfTravelOptions);
                
                // Check if grade can edit daily allowance
                Boolean canEditDailyAllowance = (gradeName == 'DR' || gradeName == 'EM');
                result.put('canEditDailyAllowance', canEditDailyAllowance);
            }
            
            return result;
            
        } catch (Exception e) {
            System.debug('Error in getGradeDetails: ' + e.getMessage());
            throw new AuraHandledException('Error getting grade details: ' + e.getMessage());
        }
    }
    
    // Add this new method to get daily allowance by grade name
    @AuraEnabled(cacheable=true)
    public static Decimal getDailyAllowanceByGrade(String gradeName) {
        try {
            System.debug('getDailyAllowanceByGrade called with gradeName: ' + gradeName);
            
            if (String.isBlank(gradeName)) {
                System.debug('Grade name is blank, returning 0');
                return 0;
            }
            
            List<Grade__c> grades = [SELECT Id, Name, Daily_Allowance_A_class_cities__c 
                                    FROM Grade__c 
                                    WHERE Name = :gradeName 
                                    LIMIT 1];
            
            System.debug('Found grades: ' + grades.size());
            
            if (!grades.isEmpty() && grades[0].Daily_Allowance_A_class_cities__c != null) {
                Decimal allowance = grades[0].Daily_Allowance_A_class_cities__c;
                System.debug('Returning daily allowance: ' + allowance);
                return allowance;
            }
            
            System.debug('No grade found or allowance is null, returning 0');
            return 0;
            
        } catch (Exception e) {
            System.debug('Error in getDailyAllowanceByGrade: ' + e.getMessage());
            throw new AuraHandledException('Error getting daily allowance: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getUsers(String searchTerm) {
        try {
            searchTerm = '%' + String.escapeSingleQuotes(searchTerm) + '%';
            List<User> users = [SELECT Id, Name, Division, Zone__c, Cost_Center__c, Grades__c 
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
                    'costCenter' => u.Cost_Center__c != null ? u.Cost_Center__c : '',
                    'grade' => u.Grades__c != null ? u.Grades__c : ''
                });
            }
            return options;
        } catch (Exception e) {
            throw new AuraHandledException('Error getting users: ' + e.getMessage());
        }
    }
    
    // Fix the SOQL injection vulnerability in getTypeOfExpense method
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getTypeOfExpense(String searchTerm, String voucherType) {
        try {
            String baseQuery = 'SELECT Id, Name, Type_of_Voucher__c, GL_Code__c, GL_Code__r.Name FROM Type_of_Expense__c';
            List<String> conditions = new List<String>();
            
            if (String.isNotBlank(searchTerm)) {
                conditions.add('Name LIKE :searchTerm');
            }
            
            if (String.isNotBlank(voucherType)) {
                conditions.add('Type_of_Voucher__c = :voucherType');
            }
            
            String whereClause = '';
            if (!conditions.isEmpty()) {
                whereClause = ' WHERE ' + String.join(conditions, ' AND ');
            }
            
            String finalQuery = baseQuery + whereClause + ' ORDER BY Name LIMIT 50';
            
            // Use dynamic SOQL with bind variables
            List<Type_of_Expense__c> expenses = Database.query(finalQuery);
            
            List<Map<String, String>> options = new List<Map<String, String>>();
            for (Type_of_Expense__c e : expenses) {
                options.add(new Map<String, String>{
                    'label' => e.Name,
                    'value' => e.Id,
                    'name' => e.Name,
                    'glCodeId' => e.GL_Code__c != null ? e.GL_Code__c : '',
                    'glCodeName' => e.GL_Code__r != null ? e.GL_Code__r.Name : ''
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
            recordTypeId = recordTypeMap.get('Unitop_Tristar');
        }
        
        return recordTypeId;
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