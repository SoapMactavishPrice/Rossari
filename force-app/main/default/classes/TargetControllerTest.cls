@isTest
private class TargetControllerTest {

    @testSetup
    static void setupData() {
        Id standardPricebookId = Test.getStandardPricebookId();

        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert testProduct;

        PricebookEntry standardPBE = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
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

        FY__c fy = new FY__c(Name = 'FY25');
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

        System.assert(!products.isEmpty(), 'Products should be returned.');
    }

    @isTest
    static void testGetExistingTargets() {
        FY__c fy = [SELECT Id FROM FY__c LIMIT 1];
        User u = [SELECT Id FROM User WHERE Username LIKE 'testuser%@example.com' LIMIT 1];

        Test.startTest();
        List<Target__c> targets = TargetController.getExistingTargets(fy.Id, u.Id);
        Test.stopTest();

        System.assert(!targets.isEmpty(), 'Targets should be returned for this FY and User.');
    }

    @isTest
    static void testGetPicklistValues() {
        Test.startTest();
        TargetController.PicklistValues values = TargetController.getPicklistValues();
        Test.stopTest();

        System.assertNotEquals(null, values, 'Picklist values should not be null.');
    }

    @isTest
    static void testSaveTargets_Insert() {
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
        TargetController.saveTargets(new List<Target__c>{ newTarget });
        Test.stopTest();

        Target__c insertedTarget = [
            SELECT Id, Quantity__c 
            FROM Target__c 
            WHERE Month__c = 'February' 
            LIMIT 1
        ];
        System.assertEquals(20, insertedTarget.Quantity__c, 'Target should be inserted correctly.');
    }

    @isTest
    static void testSaveTargets_ExceptionBranch() {
        Boolean exceptionThrown = false;
        try {
            Test.startTest();
            TargetController.saveTargets(new List<Target__c>());
            Test.stopTest();
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        System.assertEquals(true, exceptionThrown, 'Expected exception for empty list.');
    }
}