public with sharing class CustomSalesAreaLookupController {
    
    @AuraEnabled(cacheable=true)
    public static List<sObject> searchRecords(String searchTerm, String objectApiName, String filterParams, String recordId) {
        try {
            if (String.isNotBlank(recordId)) {
                // Return specific record for initial load
                if (objectApiName == 'Product_Group__c') {
                    return [SELECT Id, Item_Group_Description__c FROM Product_Group__c WHERE Id = :recordId LIMIT 1];
                } else {
                    String query = 'SELECT Id, Name FROM ' + objectApiName + ' WHERE Id = :recordId LIMIT 1';
                    return Database.query(query);
                }
            }
            
            String searchPattern = '%' + String.escapeSingleQuotes(searchTerm) + '%';
            
            // Build query based on object type
            String query;
            String displayField;
            String whereField;
            String orderField;
            
            if (objectApiName == 'Product_Group__c') {
                displayField = 'Item_Group_Description__c';
                whereField = 'Item_Group_Description__c';
                orderField = 'Item_Group_Description__c';
                query = 'SELECT Id, Item_Group_Description__c FROM Product_Group__c WHERE Item_Group_Description__c LIKE :searchPattern';
            } else {
                displayField = 'Name';
                whereField = 'Name';
                orderField = 'Name';
                query = 'SELECT Id, Name FROM ' + objectApiName + ' WHERE Name LIKE :searchPattern';
            }
            
            // Add filters based on object type
            if (objectApiName == 'User') {
                query += ' AND IsActive = true';
            }
            else if (objectApiName == 'Division__c') {
                Map<String, Object> filters = (Map<String, Object>) JSON.deserializeUntyped(filterParams);
                if (filters.containsKey('sapCodes')) {
                    // Convert List<Object> to List<String>
                    List<Object> sapCodesObject = (List<Object>) filters.get('sapCodes');
                    List<String> sapCodes = new List<String>();
                    for (Object obj : sapCodesObject) {
                        if (obj != null) {
                            sapCodes.add(String.valueOf(obj));
                        }
                    }
                    
                    if (!sapCodes.isEmpty()) {
                        // Get limited set of Division IDs first
                        Set<Id> divisionIds = new Set<Id>();
                        for (AggregateResult agg : [
                            SELECT Item_Master__r.Division__c divisionId
                            FROM Sales_Area__c 
                            WHERE Sales_Organisation__r.Name IN :sapCodes 
                            AND (Distribution_Channel__r.Name = '20' OR Distribution_Channel__r.Name = '10')
                            AND Item_Master__r.Division__c != null
                            AND Item_Master__r.IsActive = true
                            GROUP BY Item_Master__r.Division__c
                        ]) {
                            Id divId = (Id)agg.get('divisionId');
                            if (divId != null) {
                                divisionIds.add(divId);
                            }
                        }
                        
                        if (!divisionIds.isEmpty()) {
                            query += ' AND Id IN :divisionIds';
                        } else {
                            query += ' AND Id = null';
                        }
                    }
                }
            } 
            else if (objectApiName == 'Product_Group__c') {
                Map<String, Object> filters = (Map<String, Object>) JSON.deserializeUntyped(filterParams);
                if (filters.containsKey('sapCodes') && filters.containsKey('divisionId')) {
                    // Convert List<Object> to List<String>
                    List<Object> sapCodesObject = (List<Object>) filters.get('sapCodes');
                    List<String> sapCodes = new List<String>();
                    for (Object obj : sapCodesObject) {
                        if (obj != null) {
                            sapCodes.add(String.valueOf(obj));
                        }
                    }
                    
                    String divisionId = (String) filters.get('divisionId');
                    
                    if (!sapCodes.isEmpty() && String.isNotBlank(divisionId)) {
                        // Get limited set of Product Group IDs first
                        Set<Id> productGroupIds = new Set<Id>();
                        for (AggregateResult agg : [
                            SELECT Item_Master__r.Item_Group__c productGroupId
                            FROM Sales_Area__c 
                            WHERE Sales_Organisation__r.Name IN :sapCodes 
                            AND (Distribution_Channel__r.Name = '20' OR Distribution_Channel__r.Name = '10')
                            AND Item_Master__r.Division__c = :divisionId
                            AND Item_Master__r.Item_Group__c != null
                            AND Item_Master__r.IsActive = true
                            GROUP BY Item_Master__r.Item_Group__c
                        ]) {
                            Id pgId = (Id)agg.get('productGroupId');
                            if (pgId != null) {
                                productGroupIds.add(pgId);
                            }
                        }
                        
                        if (!productGroupIds.isEmpty()) {
                            query += ' AND Id IN :productGroupIds';
                        }
                        // Don't add "AND Id = null" here because we want to include "All Product Group"
                    }
                }
            }
            
            query += ' ORDER BY ' + orderField;
            List<sObject> results = Database.query(query);
            
            // For Product Group, always include "All Product Group" and sort it to the top
            if (objectApiName == 'Product_Group__c') {
                results = includeAndSortAllProductGroup(results);
            }
            
            return results;
            
        } catch (Exception e) {
            throw new AuraHandledException('Search error: ' + e.getMessage());
        }
    }
    
    private static List<sObject> includeAndSortAllProductGroup(List<sObject> productGroups) {
        // Get "All Product Group" record
        List<Product_Group__c> allProductGroups = [
            SELECT Id, Item_Group_Description__c 
            FROM Product_Group__c 
            WHERE Item_Group_Description__c = 'All Product Group' 
            LIMIT 1
        ];
        
        if (allProductGroups.isEmpty()) {
            return productGroups;
        }
        
        Product_Group__c allProductGroup = allProductGroups[0];
        List<sObject> allProductGroupList = new List<sObject>();
        List<sObject> otherProductGroups = new List<sObject>();
        
        // Check if "All Product Group" is already in the results
        Boolean allProductGroupExists = false;
        for (sObject pg : productGroups) {
            String description = (String)pg.get('Item_Group_Description__c');
            if (description == 'All Product Group') {
                allProductGroupExists = true;
                allProductGroupList.add(pg);
            } else {
                otherProductGroups.add(pg);
            }
        }
        
        // If "All Product Group" is not in the results, add it
        if (!allProductGroupExists) {
            allProductGroupList.add(allProductGroup);
        }
        
        // Add "All Product Group" first, then the rest
        allProductGroupList.addAll(otherProductGroups);
        return allProductGroupList;
    }
}