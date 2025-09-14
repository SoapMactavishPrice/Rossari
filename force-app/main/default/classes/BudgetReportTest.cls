@isTest
public class BudgetReportTest {
    
    @testSetup
    static void setupData() {
        // Create FY record
        FY__c fy = new FY__c(
            Name = 'FY2025'
            //isActive__c = true
        );
        insert fy;

        // Create a User
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + System.currentTimeMillis() + '@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert u;

        // Create a related Division record (if required for lookup)
        Division__c div = new Division__c(Name = 'Test Division');
        insert div;

        // Create Budget record
        Budget__c bud = new Budget__c(
            //Name = 'Test Budget',
            FY__c = fy.Id,
            Sales_Employee__c = u.Id,
            Division__c = div.Id,
            Sales_Quantity__c = 100,
            Price__c = 500,
            GM_Kg__c = 50,
            COGS_Value__c = 200,
            COGS_Kg__c = 40,
            GM_Value__c = 300,
            Sales_Value__c = 800
        );
        insert bud;
    }

 /*   @isTest
    static void testGetDefualtFiscId() {
        Test.startTest();
        String fiscId = BudgetReport.getDefualtFiscId();
        Test.stopTest();
    } */

    @isTest
    static void testGetBudget() {
        User u = [SELECT Id FROM User WHERE Username LIKE 'testuser%@example.com' LIMIT 1];
        FY__c fy = [SELECT Id FROM FY__c WHERE Name = 'FY2025'];

        Test.startTest();
        List<Budget__c> budgets = BudgetReport.getBudget(u.Id, fy.Id);
        Test.stopTest();

        
    }

    @isTest
    static void testGetBudgetSummary() {
        User u = [SELECT Id FROM User WHERE Username LIKE 'testuser%@example.com' LIMIT 1];
        FY__c fy = [SELECT Id FROM FY__c WHERE Name = 'FY2025'];

        Test.startTest();
        BudgetReport.PartyOutstandingWrapper summary = BudgetReport.getBudgetSummary(u.Id, fy.Id);
        Test.stopTest();

       
    }
}