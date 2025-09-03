@isTest
private class BookingSummaryControllerTest {
    @testSetup
    static void setup() {
        FY__c testFy = new FY__c(
            Name = '2025',
            FY_Start_Date__c = Date.today().addMonths(-1),
            FY_End_Date__c = Date.today().addMonths(1)
        );
        insert testFy;

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

        Account testAccount = new Account(Name = 'Test Customer', CurrencyIsoCode = 'USD', OwnerId = testUser.Id);
        insert testAccount;

        Product2 testProduct = new Product2(Name = 'Test Product', ProductCode = 'TEST', IsActive = true);
        insert testProduct;

        Booking_Target__c testTarget = new Booking_Target__c(
            FY__c = testFy.Id,
            Product__c = testProduct.Id,
            Sales_Employee__c = testUser.Id,
            Account__c = testAccount.Id,
            Month__c = 'January',
            Year__c = '2025',
            Sales_Quantity__c = 100,
            COGS_Rate__c = 50,
            Budget_Rate__c = 150,
            Product_Code__c = 'TEST'
        );
        insert testTarget;
    }

    @isTest
    static void testAllMethods() {
        User testUser = [SELECT Id FROM User WHERE Username = 'testuser9182656@test.com' LIMIT 1];
        FY__c testFy = [SELECT Id FROM FY__c WHERE FY_Start_Date__c <= :Date.today() AND FY_End_Date__c >= :Date.today() LIMIT 1];
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];
        Booking_Target__c testTarget = [SELECT Id FROM Booking_Target__c LIMIT 1];

        Test.startTest();
        FY__c defaultFy = BookingSummaryController.getDefualtFiscId();
        List<Account> defaultAccounts = BookingSummaryController.getDefualtAccount(testUser.Id);
        List<Booking_Target__c> allExistingData = BookingSummaryController.getAllExistingData(testUser.Id, testFy.Id);
        List<Booking_Target__c> existingData = BookingSummaryController.getExistingData(testUser.Id, testFy.Id, testAccount.Id);
        List<Product2> productList = BookingSummaryController.getProductList();

        Map<String, Object> dataMap = new Map<String, Object>{
            'ProductId' => testProduct.Id,
            'MonthName' => 'January-2025',
            'Sales_Qauntity__c' => '200',
            'COGS_Kg__c' => '60',
            'Price__c' => '160',
            'CustomerId' => testAccount.Id,
            'ProductCode' => 'TEST'
        };
        List<Object> dataList = new List<Object>{dataMap};
        String jsonData = JSON.serialize(dataList);

        String saveResult = BookingSummaryController.saveToServer(jsonData, testUser.Id, testFy.Id);
        BookingSummaryController.updateOnDemand(testTarget.Id, 'Sales_Qauntity__c', '300');
        BookingSummaryController.updateOnDemand(testTarget.Id, 'COGS_Kg__c', '70');
        BookingSummaryController.updateOnDemand(testTarget.Id, 'Price__c', '170');
        Test.stopTest();
    }
}