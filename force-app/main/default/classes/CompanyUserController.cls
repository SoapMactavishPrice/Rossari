public with sharing class CompanyUserController {
    
    @AuraEnabled(cacheable=true)
    public static List<User> getUsers() {
        return [SELECT Id, Name FROM User WHERE IsActive = true ORDER BY Name];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getCompanySAPCodes(String companyId) {
        List<String> sapCodes = new List<String>();
        
        // Get SAP codes from Company object
        List<Company__c> companies = [SELECT SAP_Code__c FROM Company__c WHERE Id = :companyId LIMIT 1];
        
        if (!companies.isEmpty() && companies[0].SAP_Code__c != null) {
            // Split SAP codes by comma and trim spaces
            String[] codes = companies[0].SAP_Code__c.split(',');
            for (String code : codes) {
                sapCodes.add(code.trim());
            }
        }
        
        return sapCodes;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Division__c> getDivisions(List<String> sapCodes) {
        if (sapCodes == null || sapCodes.isEmpty()) {
            return new List<Division__c>();
        }
        
        // Use aggregate query with limits to avoid too many rows
        List<AggregateResult> aggResults = [
            SELECT Item_Master__r.Division__c divisionId
            FROM Sales_Area__c 
            WHERE Sales_Organisation__r.Name IN :sapCodes 
            AND (Distribution_Channel__r.Name = '20' OR Distribution_Channel__r.Name = '10')
            AND Item_Master__r.Division__c != null
            AND Item_Master__r.IsActive = true
            GROUP BY Item_Master__r.Division__c
        ];
        
        if (aggResults.isEmpty()) {
            return new List<Division__c>();
        }
        
        // Extract Division IDs from aggregate results
        Set<Id> divisionIds = new Set<Id>();
        for (AggregateResult agg : aggResults) {
            Id divId = (Id)agg.get('divisionId');
            if (divId != null) {
                divisionIds.add(divId);
            }
        }
        
        return [SELECT Id, Name FROM Division__c WHERE Id IN :divisionIds ORDER BY Name];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Product_Group__c> getProductGroups(List<String> sapCodes, String divisionId) {
        if (sapCodes == null || sapCodes.isEmpty() || String.isBlank(divisionId)) {
            return new List<Product_Group__c>();
        }
        
        // Use aggregate query with limits to avoid too many rows
        List<AggregateResult> aggResults = [
            SELECT Item_Master__r.Item_Group__c productGroupId
            FROM Sales_Area__c 
            WHERE Sales_Organisation__r.Name IN :sapCodes 
            AND (Distribution_Channel__r.Name = '20' OR Distribution_Channel__r.Name = '10')
            AND Item_Master__r.Division__c = :divisionId
            AND Item_Master__r.Item_Group__c != null
            AND Item_Master__r.IsActive = true
            GROUP BY Item_Master__r.Item_Group__c
        ];
        
        // Extract Product Group IDs from aggregate results
        Set<Id> productGroupIds = new Set<Id>();
        for (AggregateResult agg : aggResults) {
            Id pgId = (Id)agg.get('productGroupId');
            if (pgId != null) {
                productGroupIds.add(pgId);
            }
        }
        
        // Query Product Groups from the filtered IDs
        List<Product_Group__c> productGroups = new List<Product_Group__c>();
        if (!productGroupIds.isEmpty()) {
            productGroups = [
                SELECT Id, Item_Group_Description__c 
                FROM Product_Group__c 
                WHERE Id IN :productGroupIds 
                ORDER BY Item_Group_Description__c
            ];
        }
        
        // ALWAYS include "All Product Group" regardless of association
        Product_Group__c allProductGroup = getAllProductGroup();
        if (allProductGroup != null) {
            // Check if "All Product Group" is not already in the list
            Boolean allProductGroupExists = false;
            for (Product_Group__c pg : productGroups) {
                if (pg.Item_Group_Description__c == 'All Product Group') {
                    allProductGroupExists = true;
                    break;
                }
            }
            
            if (!allProductGroupExists) {
                productGroups.add(0, allProductGroup); // Add at the beginning
            } else {
                // If it exists, ensure it's at the top
                productGroups = sortProductGroups(productGroups);
            }
        }
        
        return productGroups;
    }
    
    // Helper method to get the "All Product Group" record
    private static Product_Group__c getAllProductGroup() {
        List<Product_Group__c> allProductGroups = [
            SELECT Id, Item_Group_Description__c 
            FROM Product_Group__c 
            WHERE Item_Group_Description__c = 'All Product Group' 
            LIMIT 1
        ];
        
        return allProductGroups.isEmpty() ? null : allProductGroups[0];
    }
    
    private static List<Product_Group__c> sortProductGroups(List<Product_Group__c> productGroups) {
        List<Product_Group__c> allProductGroups = new List<Product_Group__c>();
        List<Product_Group__c> otherProductGroups = new List<Product_Group__c>();
        
        for (Product_Group__c pg : productGroups) {
            if (pg.Item_Group_Description__c == 'All Product Group') {
                allProductGroups.add(pg);
            } else {
                otherProductGroups.add(pg);
            }
        }
        
        // Add "All Product Group" first, then the rest
        allProductGroups.addAll(otherProductGroups);
        return allProductGroups;
    }
    
    @AuraEnabled
    public static List<Company_User__c> getCompanyUsers(String companyId) {
        return [SELECT Id, User__c, User__r.Name, 
                       Division__c, Division__r.Name, 
                       Product_Group__c, Product_Group__r.Item_Group_Description__c
                FROM Company_User__c 
                WHERE Company__c = :companyId
                ORDER BY CreatedDate];
    }
    
    @AuraEnabled
    public static void saveCompanyUsers(String companyId, List<Company_User__c> companyUsers, List<String> deletedRecordIds) {
        try {
            if (deletedRecordIds != null && !deletedRecordIds.isEmpty()) {
                delete [SELECT Id FROM Company_User__c WHERE Id IN :deletedRecordIds];
            }
            
            if (companyUsers != null && !companyUsers.isEmpty()) {
                for (Company_User__c cu : companyUsers) {
                    cu.Company__c = companyId;
                }
                upsert companyUsers;
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error saving company users: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Company__c getCompanyInfo(String companyId) {
        return [SELECT Id, Name, SAP_Code__c, Email__c, Phone__c, Company_Code__c 
                FROM Company__c 
                WHERE Id = :companyId 
                LIMIT 1];
    }
}