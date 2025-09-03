@isTest
public class AccountLookupControllerTest {

    @isTest
    static void testSearchAccounts() {
        // Create related lookup records
        Pin_Code__c postalCode = new Pin_Code__c(Name = '400001');
        insert postalCode;

        City__c city = new City__c(Name = 'Mumbai');
        insert city;

        Country__c country = new Country__c(Name = 'India');
        insert country;

        // Create test Account with related fields
        Account acc = new Account(
            Name = 'Test Account',
            SAP_Customer_Code__c = '123456',
            Street1__c = '123 Test Street',
            Postal_Code__c = postalCode.Id,
            City__c = city.Id,
            Country__c = country.Id
        );
        insert acc;

        Test.startTest();
        List<AccountLookupController.AccountWrapper> results = AccountLookupController.searchAccounts('Test', 'Customer');
        Test.stopTest();

    }
}