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
        String zone,
        Boolean copyBillingToShipping,
        String street1,
        String street2,
        String street3,
        Id shippingPinCodeId,
        Id shippingCityId,
        Id shippingStateId,
        Id shippingCountryId,
        String shippingRegion,
        String shippingZone,
        String shippingStreet1,
        String shippingStreet2,
        String shippingStreet3
    ) {
        Lead existingLead = [SELECT Id, Business_Type__c FROM Lead WHERE Id = :leadId LIMIT 1];
        
        // Validate country based on business type
        if (existingLead.Business_Type__c == 'Export') {
            if (countryId != null) {
                Country__c c = [SELECT Name FROM Country__c WHERE Id = :countryId LIMIT 1];
                if (c.Name == 'India') {
                    throw new AuraHandledException('India is not allowed for Export.');
                }
            }
            if (shippingCountryId != null) {
                Country__c sc = [SELECT Name FROM Country__c WHERE Id = :shippingCountryId LIMIT 1];
                if (sc.Name == 'India') {
                    throw new AuraHandledException('Shipping Country cannot be India for Export.');
                }
            }
        } else {
            if (countryId != null) {
                Country__c c = [SELECT Name FROM Country__c WHERE Id = :countryId LIMIT 1];
                if (c.Name != 'India') {
                    throw new AuraHandledException('Only India is allowed for non-Export business.');
                }
            }
            if (shippingCountryId != null) {
                Country__c sc = [SELECT Name FROM Country__c WHERE Id = :shippingCountryId LIMIT 1];
                if (sc.Name != 'India') {
                    throw new AuraHandledException('Only India is allowed for Shipping Country in non-Export business.');
                }
            }
        }
        
        // Proceed with update
        Lead leadToUpdate = new Lead(Id = leadId);
        leadToUpdate.Pin_Code__c = pinCodeId;
        leadToUpdate.City__c = cityId;
        leadToUpdate.State__c = stateId;
        leadToUpdate.Country__c = countryId;
        leadToUpdate.Region__c = region;
        leadToUpdate.Zone__c = zone;
        leadToUpdate.Street_1__c = street1;
        leadToUpdate.Street_2__c = street2;
        leadToUpdate.Street_3__c = street3;
        leadToUpdate.Copy_Bill_to_To_Ship_to__c = copyBillingToShipping;
        leadToUpdate.Shipping_Pin_Code__c = shippingPinCodeId;
        leadToUpdate.Shipping_City__c = shippingCityId;
        leadToUpdate.Shipping_State__c = shippingStateId;
        leadToUpdate.Shipping_Country__c = shippingCountryId;
        leadToUpdate.Shipping_Region__c = shippingRegion;
        leadToUpdate.Shipping_Zone__c = shippingZone;
        leadToUpdate.Shipping_Street_1__c = shippingStreet1;
        leadToUpdate.Shipping_Street_2__c = shippingStreet2;
        leadToUpdate.Shipping_Street_3__c = shippingStreet3;
        
        update leadToUpdate;
    }

    
    @AuraEnabled
    public static List<String> getUnqualifiedReasons() {
        List<String> reasons = new List<String>();
        Schema.DescribeFieldResult fieldResult = Lead.Unqualified_Reason__c.getDescribe();
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            if (entry.isActive()) {
                reasons.add(entry.getLabel());
            }
        }
        return reasons;
    }
    
    @AuraEnabled
    public static void updateLeadStatus(Map<String, Object> leadData) {
        try {
             Date followUpDate = null;
        if (leadData.get('nextFollowUp') != null) {
            // Parse the date string from the input
            followUpDate = Date.valueOf(String.valueOf(leadData.get('nextFollowUp')));
            }
            
            Lead leadToUpdate = new Lead(
                Id = (Id)leadData.get('leadId'),
                Status = (String)leadData.get('status'),
                Unqualified_Reason__c = (String)leadData.get('unqualifiedReason'),
                Next_Follow_Up__c  = followUpDate,
                Notes__c = (String)leadData.get('note')
            );
            
            if ('Lost to Competitor'.equals(leadData.get('unqualifiedReason'))) {
                leadToUpdate.Competitor_Lost_to1__c = (Id)leadData.get('competitorLostTo');

                leadToUpdate.Competitor_Price__c = (String)leadData.get('competitorPrice');
                leadToUpdate.Competitor_Product__c = (String)leadData.get('competitorProduct');
            } else if ('Others'.equals(leadData.get('unqualifiedReason'))) {
                leadToUpdate.Other_Reasons__c = (String)leadData.get('otherReasons');
            }
            
            update leadToUpdate;
        } catch (Exception e) {
            throw new AuraHandledException('Error updating lead status: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Country__c> getCountryById(Id countryId) {
        return [
            SELECT Id, Name
            FROM Country__c
            WHERE Id = :countryId
            LIMIT 1
        ];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Country__c> getFilteredCountries(String businessType) {
        if (businessType == 'Export') {
            return [SELECT Id, Name FROM Country__c WHERE Name != 'India' ORDER BY Name];
        } else {
            return [SELECT Id, Name FROM Country__c WHERE Name = 'India'];
        }
    }
    

}