public with sharing class TargetController {

    public class PicklistValues {
        @AuraEnabled public List<Map<String, String>> monthOptions { get; set; }
        @AuraEnabled public List<Map<String, String>> yearOptions { get; set; }
    }

    @AuraEnabled(cacheable=true)
    public static List<Product2> getAllProducts() {
        return [SELECT Id, Name FROM Product2 WHERE IsActive = true ORDER BY Name LIMIT 25];
    }

    @AuraEnabled
    public static List<Target__c> getExistingTargets(String fyId, String employeeId) {
        return [
            SELECT Id, Product__c, Month__c, Year__c, Quantity__c, Amount__c 
            FROM Target__c 
            WHERE FY__c = :fyId AND Sales_Employee__c = :employeeId
        ];
    }

    @AuraEnabled(cacheable=true)
    public static PicklistValues getPicklistValues() {
        PicklistValues values = new PicklistValues();

        values.monthOptions = new List<Map<String, String>>();
        for (Schema.PicklistEntry entry : Target__c.Month__c.getDescribe().getPicklistValues()) {
            if (entry.isActive()) {
                values.monthOptions.add(new Map<String, String>{
                    'label' => entry.getLabel(),
                    'value' => entry.getValue()
                });
            }
        }

        values.yearOptions = new List<Map<String, String>>();
        for (Schema.PicklistEntry entry : Target__c.Year__c.getDescribe().getPicklistValues()) {
            if (entry.isActive()) {
                values.yearOptions.add(new Map<String, String>{
                    'label' => entry.getLabel(),
                    'value' => entry.getValue()
                });
            }
        }

        return values;
    }

    @AuraEnabled
    public static void saveTargets(List<Target__c> targets) {
        if (targets == null || targets.isEmpty()) {
            throw new AuraHandledException('No targets to save');
        }

        try {
            upsert targets;
        } catch (Exception e) {
            throw new AuraHandledException('Error saving targets: ' + e.getMessage());
        }
    }
}