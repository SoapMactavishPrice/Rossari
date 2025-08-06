@isTest
private class LeadAddressHelperTest {

    @testSetup
    static void setupData() {
        Country__c country = new Country__c(Name = 'India');
        insert country;
        
        State__c state = new State__c(Name = 'Gujarat', Country__c = country.Id);
        insert state;
        
        City__c city = new City__c(Name = 'Ahmedabad', State__c = state.Id);
        insert city;
        
        Pin_Code__c pinCode = new Pin_Code__c(Name = '380015', City__c = city.Id);
        insert pinCode;

        Company__c rossari = new Company__c(Name = 'Rossari Biotech Limited');
        insert rossari;

        Lead lead = new Lead(LastName = 'Test Lead', Company = 'Test Company');
        insert lead;
    }

    @isTest
    static void testGetAddressDataByPin() {
        Pin_Code__c pin = [SELECT Id FROM Pin_Code__c LIMIT 1];
        Map<String, String> result = LeadAddressHelper.getAddressDataByPin(pin.Id);
    }

    @isTest
    static void testGetCountriesByRegion() {
        List<Country__c> countries = LeadAddressHelper.getCountriesByRegion('TestRegion');
    }

    @isTest
    static void testGetRegionOptions() {
        List<String> regions = LeadAddressHelper.getRegionOptions();
    }

    @isTest
    static void testGetZoneOptions() {
        List<String> zones = LeadAddressHelper.getZoneOptions();
    }

    @isTest
    static void testUpdateLeadAddressFields() {
        Lead lead = [SELECT Id FROM Lead LIMIT 1];
        Pin_Code__c pin = [SELECT Id, City__c, City__r.State__c, City__r.State__r.Country__c, 
                                  City__r.State__r.Zone__c, City__r.State__r.Country__r.Region__c 
                           FROM Pin_Code__c LIMIT 1];

        Test.startTest();
        LeadAddressHelper.updateLeadAddressFields(
            lead.Id,
            pin.Id,
            pin.City__c,
            pin.City__r.State__c,
            pin.City__r.State__r.Country__c,
            pin.City__r.State__r.Country__r.Region__c,
            pin.City__r.State__r.Zone__c
        );
        Test.stopTest();

        Lead updatedLead = [SELECT Id, Pin_Code__c, City__c, State__c, Country__c, Region__c, Zone__c FROM Lead WHERE Id = :lead.Id];
    }

    @isTest
    static void testGetUnqualifiedReasonsAndUpdateLeadStatus() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        List<String> reasons = LeadAddressHelper.getUnqualifiedReasons();

        Map<String, Object> leadData = new Map<String, Object>{
            'leadId' => testLead.Id,
            'status' => 'Unqualified',
            'unqualifiedReason' => 'Others',
            'nextFollowUp' => String.valueOf(Date.today().addDays(5)),
            'note' => 'Test note',
            'otherReasons' => 'Budget constraints'
        };

        Test.startTest();
        LeadAddressHelper.updateLeadStatus(leadData);
        Test.stopTest();
    }
}