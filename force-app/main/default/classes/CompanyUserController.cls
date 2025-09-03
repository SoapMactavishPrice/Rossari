public with sharing class CompanyUserController {
    
    @AuraEnabled(cacheable=true)
    public static List<User> getUsers() {
        return [SELECT Id, Name FROM User WHERE IsActive = true ORDER BY Name];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Plant__c> getPlants() {
        return [SELECT Id, Name FROM Plant__c ORDER BY Name LIMIT 100];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Division__c> getDivisions(String plantId) {
        if (String.isBlank(plantId)) {
            return new List<Division__c>();
        }
        
        // First get division IDs from Sales_Area__c
        Set<Id> divisionIds = new Set<Id>();
        for (Sales_Area__c sa : [SELECT Division__c FROM Sales_Area__c WHERE Plant_Code__c = :plantId AND Division__c != null]) {
            divisionIds.add(sa.Division__c);
        }
        
        if (divisionIds.isEmpty()) {
            return new List<Division__c>();
        }
        
        return [SELECT Id, Name FROM Division__c WHERE Id IN :divisionIds ORDER BY Name LIMIT 100];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Product_Group__c> getProductGroups(String plantId, String divisionId) {
        if (String.isBlank(plantId) || String.isBlank(divisionId)) {
            return new List<Product_Group__c>();
        }
        
        // First get item master IDs from Sales_Area__c
        Set<Id> itemMasterIds = new Set<Id>();
        for (Sales_Area__c sa : [SELECT Item_Master__c FROM Sales_Area__c 
                                WHERE Plant_Code__c = :plantId 
                                AND Division__c = :divisionId 
                                AND Item_Master__c != null]) {
            itemMasterIds.add(sa.Item_Master__c);
        }
        
        if (itemMasterIds.isEmpty()) {
            return new List<Product_Group__c>();
        }
        
        // Then get product group IDs from Product2
        Set<Id> productGroupIds = new Set<Id>();
        for (Product2 p : [SELECT Item_Group__c FROM Product2 
                          WHERE Id IN :itemMasterIds 
                          AND Item_Group__c != null]) {
            productGroupIds.add(p.Item_Group__c);
        }
        
        if (productGroupIds.isEmpty()) {
            return new List<Product_Group__c>();
        }
        
        return [SELECT Id, Name FROM Product_Group__c WHERE Id IN :productGroupIds ORDER BY Name LIMIT 100];
    }
    
    @AuraEnabled
    public static List<Company_User__c> getCompanyUsers(String companyId) {
        return [SELECT Id, User__c, User__r.Name, 
                       Business_Unit__c, Business_Unit__r.Name, 
                       Division__c, Division__r.Name, 
                       Product_Group__c, Product_Group__r.Name
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
}