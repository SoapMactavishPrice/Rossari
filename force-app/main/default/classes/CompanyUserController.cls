public with sharing class CompanyUserController {

    // Get active users for selection
    @AuraEnabled(cacheable=true)
    public static List<User> getUsers() {
        return [SELECT Id, Name FROM User WHERE IsActive = true ORDER BY Name];
    }

    // Get Business Units (Plant__c)
    @AuraEnabled(cacheable=true)
    public static List<Plant__c> getBusinessUnits() {
        return [SELECT Id, Name FROM Plant__c ORDER BY Name];
    }

    // Get Divisions
    @AuraEnabled(cacheable=true)
    public static List<Division__c> getDivisions() {
        return [SELECT Id, Name FROM Division__c ORDER BY Name];
    }

    // Get Product Groups
    @AuraEnabled(cacheable=true)
    public static List<Product_Group__c> getProductGroups() {
        return [SELECT Id, Name FROM Product_Group__c ORDER BY Name];
    }

     @AuraEnabled
    public static void saveCompanyUsers(Id companyId, List<Company_User__c> companyUsers, List<Id> deletedRecordIds) {
        try {
            if (deletedRecordIds != null && !deletedRecordIds.isEmpty()) {
                delete [SELECT Id FROM Company_User__c WHERE Id IN :deletedRecordIds];
            }
            
            List<Company_User__c> recordsToUpsert = new List<Company_User__c>();
            for (Company_User__c cu : companyUsers) {
                if (String.isNotBlank(cu.User__c)) {
                    recordsToUpsert.add(new Company_User__c(
                        Id = String.isNotBlank(cu.Id) ? cu.Id : null,
                        User__c = cu.User__c,
                        Business_Unit__c = cu.Business_Unit__c,
                        Division__c = cu.Division__c,
                        Product_Group__c = cu.Product_Group__c,
                        Company__c = companyId
                    ));
                }
            }
            
            upsert recordsToUpsert;
        } catch (Exception e) {
            throw new AuraHandledException('Error saving company users: ' + e.getMessage());
        }
    }

    // Retrieve existing Company_User__c records for a given Company__c
    @AuraEnabled(cacheable=true)
    public static List<Company_User__c> getCompanyUsers(Id companyId) {
        return [
            SELECT Id, Name, User__c, User__r.Name, 
                   Business_Unit__c, Business_Unit__r.Name,
                   Division__c, Division__r.Name,
                   Product_Group__c, Product_Group__r.Name
            FROM Company_User__c
            WHERE Company__c = :companyId
            ORDER BY Name
        ];
    }
}