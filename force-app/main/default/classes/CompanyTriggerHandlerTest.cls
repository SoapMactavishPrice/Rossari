@isTest
private class CompanyTriggerHandlerTest {

    @isTest
    static void testUpdateCompanyAddresses() {
        // Step 1: Create Country
        Country__c country = new Country__c(Name = 'Test Country');
        insert country;

        // Step 2: Create State linked to Country
        State__c state = new State__c(Name = 'Test State', Country__c = country.Id);
        insert state;

        // Step 3: Create City linked to State
        City__c city = new City__c(Name = 'Test City', State__c = state.Id);
        insert city;

        // Step 4: Create Pin Code linked to City
        Pin_Code__c pin = new Pin_Code__c(Name = '123456', City__c = city.Id);
        insert pin;

        // Step 5: Create Company__c with only Postal Code
        Company__c company1 = new Company__c(
            Name = 'Company Using Pin',
            Company_Postal_Code__c = pin.Id
        );

        // Step 6: Create Company__c with only City
        Company__c company2 = new Company__c(
            Name = 'Company Using City',
            Company_City__c = city.Id
        );

        // Step 7: Create Company__c with only State
        Company__c company3 = new Company__c(
            Name = 'Company Using State',
            Company_State__c = state.Id
        );

        // Call the method directly with a list of companies
        List<Company__c> companies = new List<Company__c>{company1, company2, company3};

        Test.startTest();
        CompanyTriggerHandler.updateCompanyAddresses(companies);
        Test.stopTest();

       
    }
}