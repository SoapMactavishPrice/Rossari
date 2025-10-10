@isTest
private class ExpenseTriggerHandlerTest {

    private static User createTestUser(String costCenterValue) {
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tuser',
            Email = 'testuser' + Math.round(Math.random() * 10000) + '@example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US',
            Sales_Type_Code1__c = '10',
            Cost_Center__c = costCenterValue  // assign picklist string value here
        );
        insert u;
        return u;
    }

    private static Cost_Center__c createCostCenter() {
        // The Name here must be a valid picklist value for User.Cost_Center__c field
        Cost_Center__c cc = new Cost_Center__c(Name = '10000013'); 
        insert cc;
        return cc;
    }

    private static Company__c createCompany(String companyName) {
        Company__c comp = new Company__c(Name = companyName);
        insert comp;
        return comp;
    }

    private static Code_Master__c createCodeMaster(String companyName, String salesType) {
        Company__c comp = createCompany(companyName);
        Code_Master__c cm = new Code_Master__c(
            Sales_Type__c = salesType,
            Company__c = comp.Id,
            Current_Sequence__c = 1,
            IsActive__c = true
        );
        insert cm;
        return cm;
    }

    @isTest
    static void testPopulateExpenseName() {
        Cost_Center__c cc = createCostCenter();
        User u = createTestUser(cc.Name);

        Code_Master__c cm = createCodeMaster('Rossari Biotech Limited', '10');

        System.runAs(u) {
            List<Expense__c> expenses = new List<Expense__c>();
            expenses.add(new Expense__c(Sales_Type__c = 'Domestic'));
            expenses.add(new Expense__c(Sales_Type__c = 'Domestic'));
            ExpenseTriggerHandler.populateExpenseName(expenses);
        }
    }

    @isTest
    static void testStatusChangeToSubmitted() {
        Cost_Center__c cc = createCostCenter();
        User u = createTestUser(cc.Name);

        Expense__c expOld = new Expense__c(Status__c = 'Draft', OwnerId = u.Id);
        insert expOld;

        Expense__c expNew = new Expense__c(Id = expOld.Id, Status__c = 'Submitted', OwnerId = u.Id);

        Map<Id, Expense__c> oldMap = new Map<Id, Expense__c>{expOld.Id => expOld};
        List<Expense__c> newList = new List<Expense__c>{expNew};

        Test.startTest();
        ExpenseTriggerHandler.statusChangeToSubmitted(newList, oldMap);
        Test.stopTest();
    }
}