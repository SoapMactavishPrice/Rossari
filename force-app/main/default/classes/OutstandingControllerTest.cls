@isTest
private class OutstandingControllerTest {
    @testSetup
    static void setup() {
        FY__c testFy = new FY__c(Name = '2025');
        insert testFy;
        
        Account testAccount = new Account(Name = 'Test Customer');
        insert testAccount;
        
        Sales_Organisation__c testSalesOrg = new Sales_Organisation__c(Name = 'Test Org');
        insert testSalesOrg;
        
        Division__c testDivision = new Division__c(Name = 'Test Division');
        insert testDivision;
        
        Distribution_Channel__c testDistChannel = new Distribution_Channel__c(Name = 'Test Channel');
        insert testDistChannel;
        
        Product2 testProduct = new Product2(Name = 'Test Product', ProductCode = 'TEST');
        insert testProduct;
        
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@test.com',
            Username = 'testuser9182656@test.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        
        List<Budget__c> testBudgets = new List<Budget__c>();
        for (Integer i = 0; i < 5; i++) {
            Budget__c budget = new Budget__c(
                Customer_Name__c = testAccount.Id,
                Sales_Organisations__c = testSalesOrg.Id,
                Division__c = testDivision.Id,
                Distribution_Channel__c = testDistChannel.Id,
                Product_Description__c = testProduct.Id,
                Sales_Employee__c = testUser.Id,
                FY__c = testFy.Id,
                Month__c = 'January',
                Year__c = '2025',
                Sales_Quantity__c = 100 + i,
                Sales_Value__c = 1000 + (i * 100),
                Price__c = 10 + i,
                GM_Kg__c = 5 + i,
                COGS_Value__c = 500 + (i * 50),
                COGS_Kg__c = 8 + i,
                GM_Value__c = 200 + (i * 20)
            );
            testBudgets.add(budget);
        }
        insert testBudgets;
    }
    
    @isTest
    static void testAllScenarios() {
        User testUser = [SELECT Id FROM User WHERE Username = 'testuser9182656@test.com' LIMIT 1];
        FY__c testFy = [SELECT Id FROM FY__c LIMIT 1];
        
        Test.startTest();
        List<OutstandingController.PartyOutstandingWrapper> result1 = OutstandingController.getBudget(testUser.Id, testFy.Id);
        
        FY__c newFy = new FY__c(Name = '2026');
        insert newFy;
        List<OutstandingController.PartyOutstandingWrapper> result2 = OutstandingController.getBudget(testUser.Id, newFy.Id);
        
        Account testAccount2 = new Account(Name = 'Test Customer 2');
        insert testAccount2;
        Budget__c budgetWithNulls = new Budget__c(
            Customer_Name__c = testAccount2.Id,
            Sales_Employee__c = testUser.Id,
            FY__c = testFy.Id,
            Month__c = 'February'
        );
        insert budgetWithNulls;
        List<OutstandingController.PartyOutstandingWrapper> result3 = OutstandingController.getBudget(testUser.Id, testFy.Id);
        Test.stopTest();
    }
}