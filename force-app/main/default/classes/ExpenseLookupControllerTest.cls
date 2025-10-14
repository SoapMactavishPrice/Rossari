@isTest
public class ExpenseLookupControllerTest {

    @testSetup
    static void setupTestData() {
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tuser',
            Email = 'testuser@example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            Division = 'North',
            Zone__c = 'East',
            IsActive = true
        );
        insert u;

        Type_of_Expense__c toe = new Type_of_Expense__c(Name = 'Travel');
        insert toe;
    }

    @isTest
    static void testSearchRecords_User() {
        Test.startTest();
        List<SObject> results = ExpenseLookupController.searchRecords('User', 'Test');
        Test.stopTest();
    }

    @isTest
    static void testSearchRecords_Expense() {
        Test.startTest();
        List<SObject> results = ExpenseLookupController.searchRecords('Type_of_Expense__c', 'Travel');
        Test.stopTest();
    }

    @isTest
    static void testGetUsers() {
        Test.startTest();
        List<Map<String, String>> users = ExpenseLookupController.getUsers('Test');
        Test.stopTest();
    }

    @isTest
    static void testGetTypeOfExpense() {
        Test.startTest();
        List<Map<String, String>> expenses = ExpenseLookupController.getTypeOfExpense('Travel');
        Test.stopTest();
    }
}