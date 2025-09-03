public with sharing class ExpenseLookupController {

    @AuraEnabled(cacheable=true)
    public static List<SObject> searchRecords(String objectApiName, String searchTerm) {
        try {
            if (String.isBlank(searchTerm)) {
                return new List<SObject>();
            }
            
            List<String> fieldsToQuery = new List<String>{'Id', 'Name'};
            
            // Only include Division and Zone__c for User objects
            if(objectApiName == 'User') {
                fieldsToQuery.add('Division');
                fieldsToQuery.add('Zone__c');
            }
            
            String fieldStr = String.join(fieldsToQuery, ', ');
            String searchPattern = '%' + String.escapeSingleQuotes(searchTerm) + '%';
            
            String query = 'SELECT ' + fieldStr + 
                           ' FROM ' + objectApiName +
                           ' WHERE Name LIKE :searchPattern';

            // Add object-specific conditions
            if(objectApiName == 'User') {
                query += ' AND IsActive = true';
            }
            
            // Add any specific conditions for Type_of_Expense__c if needed
            if(objectApiName == 'Type_of_Expense__c') {
                // Example: query += ' AND Is_Active__c = true';
            }

            query += ' ORDER BY Name LIMIT 10';

            return Database.query(query);
        } catch (Exception e) {
            throw new AuraHandledException('Error searching records: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getUsers(String searchTerm) {
        searchTerm = '%' + searchTerm + '%';
        List<User> users = [SELECT Id, Name, Division, Zone__c FROM User 
                            WHERE Name LIKE :searchTerm AND IsActive = true
                            ORDER BY Name LIMIT 50];
        List<Map<String, String>> options = new List<Map<String, String>>();
        for (User u : users) {
            options.add(new Map<String, String>{
                'label' => u.Name,
                'value' => u.Id,
                'division' => u.Division,
                'zone' => u.Zone__c
            });
        }
        return options;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getTypeOfExpense(String searchTerm) {
        searchTerm = '%' + searchTerm + '%';
        List<Type_of_Expense__c> expenses = [SELECT Id, Name FROM Type_of_Expense__c 
                                             WHERE Name LIKE :searchTerm ORDER BY Name LIMIT 50];
        List<Map<String, String>> options = new List<Map<String, String>>();
        for (Type_of_Expense__c e : expenses) {
            options.add(new Map<String, String>{
                'label' => e.Name,
                'value' => e.Id
            });
        }
        return options;
    }
    
}