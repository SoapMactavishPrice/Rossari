public with sharing class CustomSalesAreaLookupController {
    
    // In CustomSalesAreaLookupController
    @AuraEnabled(cacheable=true)
    public static List<sObject> searchRecords(String searchTerm, String objectApiName, String filterParams, String recordId) {
        try {
            if (String.isNotBlank(recordId)) {
                // Return specific record for initial load
                String query = 'SELECT Id, Name FROM ' + objectApiName + ' WHERE Id = :recordId LIMIT 1';
                return Database.query(query);
            }
            
            String searchPattern = '%' + String.escapeSingleQuotes(searchTerm) + '%';
            String query = 'SELECT Id, Name FROM ' + objectApiName + ' WHERE Name LIKE :searchPattern';
            
            // Add filters based on object type
            if (objectApiName == 'User') {
                query += ' AND IsActive = true';
            }
            else if (objectApiName == 'Division__c') {
                Map<String, Object> filters = (Map<String, Object>) JSON.deserializeUntyped(filterParams);
                if (filters.containsKey('plantId')) {
                    String plantId = (String) filters.get('plantId');
                    
                    Set<Id> divisionIds = new Set<Id>();
                    for (Sales_Area__c sa : [SELECT Division__c FROM Sales_Area__c 
                                             WHERE Plant_Code__c = :plantId 
                                             AND Division__c != null]) {
                                                 divisionIds.add(sa.Division__c);
                                             }
                    
                    if (!divisionIds.isEmpty()) {
                        query += ' AND Id IN :divisionIds';
                    } else {
                        query += ' AND Id = null';
                    }
                }
            } 
            else if (objectApiName == 'Product_Group__c') {
                Map<String, Object> filters = (Map<String, Object>) JSON.deserializeUntyped(filterParams);
                if (filters.containsKey('plantId') && filters.containsKey('divisionId')) {
                    String plantId = (String) filters.get('plantId');
                    String divisionId = (String) filters.get('divisionId');
                    
                    Set<Id> itemMasterIds = new Set<Id>();
                    for (Sales_Area__c sa : [SELECT Item_Master__c FROM Sales_Area__c 
                                             WHERE Plant_Code__c = :plantId 
                                             AND Division__c = :divisionId 
                                             AND Item_Master__c != null]) {
                                                 itemMasterIds.add(sa.Item_Master__c);
                                             }
                    
                    Set<Id> productGroupIds = new Set<Id>();
                    if (!itemMasterIds.isEmpty()) {
                        for (Product2 p : [SELECT Item_Group__c FROM Product2 
                                           WHERE Id IN :itemMasterIds 
                                           AND Item_Group__c != null]) {
                                               productGroupIds.add(p.Item_Group__c);
                                           }
                    }
                    
                    if (!productGroupIds.isEmpty()) {
                        query += ' AND Id IN :productGroupIds';
                    } else {
                        query += ' AND Id = null';
                    }
                }
            }
            
            query += ' ORDER BY Name LIMIT 20';
            return Database.query(query);
            
        } catch (Exception e) {
            throw new AuraHandledException('Search error: ' + e.getMessage());
        }
    }
    
    
    // In CustomSalesAreaLookupController.cls
    @AuraEnabled(cacheable=true)
    public static List<SObject> getAllRecords(String objectApiName, String filterParams) {
        try {
            Map<String, Object> filters = (Map<String, Object>) JSON.deserializeUntyped(filterParams);
            String query = 'SELECT Id, Name FROM ' + objectApiName;
            
            // Add WHERE clause based on filters
            List<String> whereClauses = new List<String>();
            for (String key : filters.keySet()) {
                Object value = filters.get(key);
                if (value != null) {
                    if (value instanceof String) {
                        whereClauses.add(key + ' = \'' + String.escapeSingleQuotes((String)value) + '\'');
                    } else if (value instanceof Id) {
                        whereClauses.add(key + ' = \'' + (Id)value + '\'');
                    } else {
                        whereClauses.add(key + ' = ' + value);
                    }
                }
            }
            
            if (!whereClauses.isEmpty()) {
                query += ' WHERE ' + String.join(whereClauses, ' AND ');
            }
            
            query += ' ORDER BY Name LIMIT 100';
            
            return Database.query(query);
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving records: ' + e.getMessage());
        }
    }
    
}