public with sharing class LeadAddressHelper {

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getAddressDataByPin(Id pinCodeId) {
        Map<String, String> result = new Map<String, String>();

        Pin_Code__c pin = [
            SELECT Id, Name, City__c, City__r.Name, 
                   City__r.State__c, City__r.State__r.Name,
                   City__r.State__r.Country__c, City__r.State__r.Country__r.Name,
                   City__r.State__r.Zone__c, City__r.State__r.Country__r.Region__c
            FROM Pin_Code__c
            WHERE Id = :pinCodeId
            LIMIT 1
        ];

        if (pin != null) {
            result.put('cityId', pin.City__c);
            result.put('stateId', pin.City__r.State__c);
            result.put('countryId', pin.City__r.State__r.Country__c);
            result.put('zone', pin.City__r.State__r.Zone__c);
            result.put('region', pin.City__r.State__r.Country__r.Region__c);
        }

        return result;
    }

    @AuraEnabled(cacheable=true)
    public static List<Country__c> getCountriesByRegion(String region) {
        return [
            SELECT Id, Name 
            FROM Country__c 
            WHERE Region__c = :region 
            ORDER BY Name
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getRegionOptions() {
        Set<String> regions = new Set<String>();
        for (Country__c country : [
            SELECT Region__c FROM Country__c WHERE Region__c != null
        ]) {
            regions.add(country.Region__c);
        }
        return new List<String>(regions);
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getZoneOptions() {
        Set<String> zones = new Set<String>();
        for (State__c state : [
            SELECT Zone__c FROM State__c WHERE Zone__c != null
        ]) {
            zones.add(state.Zone__c);
        }
        return new List<String>(zones);
    }

    @AuraEnabled
    public static void updateLeadAddressFields(
        Id leadId,
        Id pinCodeId,
        Id cityId,
        Id stateId,
        Id countryId,
        String region,
        String zone
    ) {
        Lead leadToUpdate = new Lead(Id = leadId);
        leadToUpdate.Pin_Code__c = pinCodeId;
        leadToUpdate.City__c = cityId;
        leadToUpdate.State__c = stateId;
        leadToUpdate.Country__c = countryId;
        leadToUpdate.Region__c = region;
        leadToUpdate.Zone__c = zone;
        update leadToUpdate;
    }
}