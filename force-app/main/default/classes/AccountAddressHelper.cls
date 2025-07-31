public with sharing class AccountAddressHelper {

      @AuraEnabled(cacheable=true)
    public static List<Address_Information__c> getAddressesByAccount(Id accountId, String recordTypeName) {
        try {
            return [
                SELECT Id, Name, Street_1__c, Street_2__c, Street_3__c, 
                       Pin_Code__c, Pin_Code__r.Name,
                       City__c, City__r.Name,
                       State__c, State__r.Name,
                       Country__c, Country__r.Name,
                       Region__c, Zone__c,
                       RecordType.DeveloperName
                FROM Address_Information__c
                WHERE Account__c = :accountId 
                AND RecordType.DeveloperName = :recordTypeName
                ORDER BY CreatedDate DESC
                LIMIT 100
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error loading addresses: ' + e.getMessage());
        }
    }
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
        result.put('cityName', pin.City__r.Name); // Add this line
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

    @AuraEnabled(cacheable=true)
    public static Id getRecordTypeId(String objectApiName, String recordTypeName) {
        return Schema.SObjectType.Address_Information__c.getRecordTypeInfosByDeveloperName()
            .get(recordTypeName).getRecordTypeId();
    }

    @AuraEnabled
    public static void deleteAddress(Id addressId) {
        delete [SELECT Id FROM Address_Information__c WHERE Id = :addressId];
    }
    
    @AuraEnabled
    public static Id saveAddress(Map<String, Object> addressFields, String recordTypeName) {
        try {
            // Validate required fields
            if (addressFields.get('Street_1__c') == null || addressFields.get('City__c') == null) {
                throw new AuraHandledException('Street 1 and City are required fields');
            }

            Address_Information__c address = new Address_Information__c();
            
            // Set all fields from the input map
            for (String fieldName : addressFields.keySet()) {
                if (addressFields.get(fieldName) != null) {
                    address.put(fieldName, addressFields.get(fieldName));
                }
            }
            
            // Get city name for the address name
            String cityName = [SELECT Name FROM City__c WHERE Id = :(String)addressFields.get('City__c') LIMIT 1].Name;
            String prefix = recordTypeName == 'Bill_To' ? 'Bill To' : 'Ship To';
            
            // Create the name in "Bill To - City Name" format
            address.Name = prefix + ' - ' + cityName;
            if (address.Name.length() > 80) {
                address.Name = address.Name.substring(0, 80);
            }
            
            address.RecordTypeId = Schema.SObjectType.Address_Information__c
                                  .getRecordTypeInfosByDeveloperName()
                                  .get(recordTypeName)
                                  .getRecordTypeId();
            
            // Upsert the record
            upsert address;
            return address.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error saving address: ' + e.getMessage());
        }
    }

}