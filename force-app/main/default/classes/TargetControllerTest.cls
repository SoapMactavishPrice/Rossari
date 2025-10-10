@isTest
private class TargetControllerTest {

    @testSetup
    static void setupData() {
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert testProduct;

        PricebookEntry standardPBE = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert standardPBE;

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            Alias = 'tusr',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert u;

        FY__c fy = new FY__c(Name='FY25');
        insert fy;

        Target__c target = new Target__c(
            Product__c = testProduct.Id,
            Month__c = 'January',
            Year__c = '2025',
            Quantity__c = 10,
            Amount__c = 1000,
            FY__c = fy.Id,
            Sales_Employee__c = u.Id
        );
        insert target;
    }

    @isTest
    static void testGetAllProducts() {
        Test.startTest();
        List<Product2> products = TargetController.getAllProducts();
        Test.stopTest();

    }

    @isTest
    static void testGetExistingTargets() {
        FY__c fy = [SELECT Id FROM FY__c LIMIT 1];
        User u = [SELECT Id FROM User WHERE Username LIKE 'testuser%@example.com' LIMIT 1];

        Test.startTest();
        List<Target__c> targets = TargetController.getExistingTargets(fy.Id, u.Id);
        Test.stopTest();

    }

    @isTest
    static void testGetPicklistValues() {
        Test.startTest();
        TargetController.PicklistValues values = TargetController.getPicklistValues();
        Test.stopTest();
    }

    @isTest
    static void testSaveTargets() {
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        FY__c fy = [SELECT Id FROM FY__c LIMIT 1];
        User u = [SELECT Id FROM User WHERE Username LIKE 'testuser%@example.com' LIMIT 1];

        Target__c newTarget = new Target__c(
            Product__c = prod.Id,
            Month__c = 'February',
            Year__c = '2025',
            Quantity__c = 20,
            Amount__c = 2000,
            FY__c = fy.Id,
            Sales_Employee__c = u.Id
        );

        Test.startTest();
        TargetController.saveTargets(new List<Target__c>{newTarget});
        Test.stopTest();

        Target__c insertedTarget = [SELECT Id, Quantity__c FROM Target__c WHERE Month__c = 'February' LIMIT 1];

        Boolean exceptionThrown = false;
        try {
            TargetController.saveTargets(new List<Target__c>());
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
    }
}