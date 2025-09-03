@isTest
public class LeadLookupControllerTest {

    @isTest
    static void testSearchAccounts() {
        // Create related lookup records
        Pin_Code__c pin = new Pin_Code__c(Name = '400001');
        insert pin;

        City__c city = new City__c(Name = 'Mumbai');
        insert city;

        Country__c country = new Country__c(Name = 'India');
        insert country;

        State__c state = new State__c(Name = 'Maharashtra');
        insert state;

        // Create a test Lead with all related fields
        Lead lead = new Lead(
            FirstName = 'John', 
            LastName = 'Doe',
            Company = 'Test Company',
            MobilePhone = '9999999999', 
            Title = 'Manager',
            Street_1__c = 'Street 1',
            Street_2__c = 'Street 2',
            Street_3__c = 'Street 3',
            Region__c = 'Africa',
            Zone__c = 'East',
            Pin_Code__c = pin.Id,
            City__c = city.Id,
            Country__c = country.Id,
            State__c = state.Id,
            Status = 'Open - Not Contacted'
        );
        insert lead;

        Test.startTest();
        List<LeadLookupController.AccountWrapper> results = LeadLookupController.searchAccounts('Test', 'Lead');
        Test.stopTest();

        LeadLookupController.AccountWrapper wrapper = results[0];
    }
}