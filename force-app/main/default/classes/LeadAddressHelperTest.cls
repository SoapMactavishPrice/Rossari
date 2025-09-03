@isTest
private class LeadAddressHelperTest {

    @testSetup
    static void setupData() {
        Country__c country = new Country__c(Name = 'India', Region__c = 'Asia');
        insert country;

        State__c state = new State__c(Name = 'Gujarat', Country__c = country.Id, Zone__c = 'West');
        insert state;

        City__c city = new City__c(Name = 'Ahmedabad', State__c = state.Id);
        insert city;

        Pin_Code__c pinCode = new Pin_Code__c(Name = '380015', City__c = city.Id);
        insert pinCode;

        Company__c rossari = new Company__c(Name = 'Rossari Biotech Limited');
        insert rossari;

        Lead lead = new Lead(FirstName='Test', LastName = 'Lead', Company = 'Test Company', MobilePhone='9999888898');
        insert lead;
    }

    @isTest
    static void testLeadAddressHelperMethods() {
        Pin_Code__c pin = [SELECT Id, City__c, City__r.State__c, City__r.State__r.Country__c, 
                                  City__r.State__r.Zone__c, City__r.State__r.Country__r.Region__c 
                           FROM Pin_Code__c LIMIT 1];
        Lead lead = [SELECT Id FROM Lead LIMIT 1];

        Map<String, String> addressData = LeadAddressHelper.getAddressDataByPin(pin.Id);
        List<Country__c> countries = LeadAddressHelper.getCountriesByRegion('Asia');
        List<String> regions = LeadAddressHelper.getRegionOptions();
        List<String> zones = LeadAddressHelper.getZoneOptions();
        List<String> reasons = LeadAddressHelper.getUnqualifiedReasons();

        Map<String, Object> leadData = new Map<String, Object>{
            'leadId' => lead.Id,
            'status' => 'Unqualified',
            'unqualifiedReason' => 'Others',
            'nextFollowUp' => String.valueOf(Date.today().addDays(5)),
            'note' => 'Test note',
            'otherReasons' => 'Budget constraints'
        };

        Test.startTest();

        LeadAddressHelper.updateLeadAddressFields(
            lead.Id,
            pin.Id,
            pin.City__c,
            pin.City__r.State__c,
            pin.City__r.State__r.Country__c,
            pin.City__r.State__r.Country__r.Region__c,
            pin.City__r.State__r.Zone__c,
            true,
            'Billing Street 1',
            'Billing Street 2',
            'Billing Street 3',
            pin.Id,
            pin.City__c,
            pin.City__r.State__c,
            pin.City__r.State__r.Country__c,
            pin.City__r.State__r.Country__r.Region__c,
            pin.City__r.State__r.Zone__c,
            'Shipping Street 1',
            'Shipping Street 2',
            'Shipping Street 3'
        );

        LeadAddressHelper.updateLeadStatus(leadData);

        Test.stopTest();

        Lead updatedLead = [SELECT Id, Pin_Code__c, City__c, State__c, Country__c, Region__c, Zone__c,
                                   Shipping_Pin_Code__c, Shipping_City__c, Shipping_State__c, Shipping_Country__c,
                                   Shipping_Region__c, Shipping_Zone__c
                            FROM Lead
                            WHERE Id = :lead.Id];
    }
}