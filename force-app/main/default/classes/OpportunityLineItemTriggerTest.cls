@isTest
private class OpportunityLineItemTriggerTest {

    @TestSetup
    static void setupTestData() {
        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = acc.Id
        );
        insert opp;

        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        try{
        update standardPricebook;
        }Catch(Exception e){}
        
        Base_UoM_Master__c baseUom = new Base_UoM_Master__c(Name = 'Kilogram');
        insert baseUom;
 
        Product2 prod = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP001',
            Pack_Size__c = '10kg',
            Base_UOM__c = baseUom.Id,
            IsActive = true
        );
        insert prod;
 
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

    }

    @isTest
    static void testTriggerWithZeroUnitPrice() {
        // Get data from setup
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];

        // Create OpportunityLineItem with UnitPrice = 0
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Quantity = 1,
            PricebookEntryId = pbe.Id,
            UnitPrice = 0
        );

        Test.startTest();
        insert oli;
        Test.stopTest();
    }

    @isTest
    static void testTriggerWithNonZeroUnitPrice() {
        // Get data from setup
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];

        // Create OpportunityLineItem with UnitPrice = 100
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Quantity = 1,
            PricebookEntryId = pbe.Id,
            UnitPrice = 100
        );

        Test.startTest();
        insert oli;
        Test.stopTest();
    }

    @isTest
    static void testTriggerWithMultipleOLIs() {
        // Get data from setup
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];

        // Create multiple OpportunityLineItems
        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
        for(Integer i = 0; i < 5; i++) {
            olis.add(new OpportunityLineItem(
                OpportunityId = opp.Id,
                Quantity = i + 1,
                PricebookEntryId = pbe.Id,
                UnitPrice = 50 + (i * 10)
            ));
        }

        Test.startTest();
        insert olis;
        Test.stopTest();
    }

    @isTest
    static void testTriggerWithDifferentProducts() {
        // Create additional product
        Product2 prod2 = new Product2(Name = 'Test Product 2', IsActive = true);
        insert prod2;

        // Create standard pricebook entry first for the new product
        PricebookEntry standardPbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = prod2.Id,
            UnitPrice = 200,
            IsActive = true
        );
        insert standardPbe;

        // Get existing data from setup
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        PricebookEntry pbe1 = [SELECT Id FROM PricebookEntry WHERE Product2.Name = 'Test Product' LIMIT 1];

        // Create OLIs with different products
        List<OpportunityLineItem> olis = new List<OpportunityLineItem>{
            new OpportunityLineItem(
                OpportunityId = opp.Id,
                Quantity = 2,
                PricebookEntryId = pbe1.Id,
                UnitPrice = 100
            ),
            new OpportunityLineItem(
                OpportunityId = opp.Id,
                Quantity = 1,
                PricebookEntryId = standardPbe.Id,
                UnitPrice = 200
            )
        };

        Test.startTest();
        insert olis;
        Test.stopTest();
    }

    @isTest
    static void testTriggerWithZeroQuantity() {
        // Get data from setup
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];

        // Create OpportunityLineItem with zero quantity
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Quantity = 0,
            PricebookEntryId = pbe.Id,
            UnitPrice = 100
        );

        Test.startTest();
        try {
            insert oli;
        } catch (Exception e) {
            // Expected behavior - validation rule may prevent zero quantity
        }
        Test.stopTest();
    }

    @isTest
    static void testTriggerUpdateScenario() {
        // Get data from setup
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];

        // Create initial OLI
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Quantity = 1,
            PricebookEntryId = pbe.Id,
            UnitPrice = 100
        );
        insert oli;

        Test.startTest();
        // Update the OLI
        oli.Quantity = 2;
        oli.UnitPrice = 150;
        update oli;
        Test.stopTest();
    }

    @isTest
    static void testTriggerDeleteScenario() {
        // Get data from setup
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];

        // Create OLI
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Quantity = 1,
            PricebookEntryId = pbe.Id,
            UnitPrice = 100
        );
        insert oli;

        Test.startTest();
        // Delete the OLI
        delete oli;
        Test.stopTest();
    }

    @isTest
    static void testTriggerWithCustomPricebook() {
        // Create product first
        Product2 prod = new Product2(Name = 'Custom PB Product', IsActive = true);
        insert prod;

        // Create standard pricebook entry first (required)
        PricebookEntry standardPbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = prod.Id,
            UnitPrice = 150,
            IsActive = true
        );
        insert standardPbe;

        // Create custom pricebook
        Pricebook2 customPb = new Pricebook2(
            Name = 'Custom Pricebook',
            IsActive = true
        );
        insert customPb;

        // Create pricebook entry in custom pricebook
        PricebookEntry customPbe = new PricebookEntry(
            Pricebook2Id = customPb.Id,
            Product2Id = prod.Id,
            UnitPrice = 200,
            IsActive = true
        );
        insert customPbe;

        // Create account and opportunity with custom pricebook
        Account acc = new Account(Name = 'Custom PB Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Custom PB Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = acc.Id,
            Pricebook2Id = customPb.Id
        );
        insert opp;

        // Create OLI with custom pricebook
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Quantity = 1,
            PricebookEntryId = customPbe.Id,
            UnitPrice = 200
        );

        Test.startTest();
        insert oli;
        Test.stopTest();
    }

    @isTest
    static void testTriggerBulkOperations() {
        // Get data from setup
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];

        // Create bulk OLIs
        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
        for(Integer i = 0; i < 200; i++) {
            olis.add(new OpportunityLineItem(
                OpportunityId = opp.Id,
                Quantity = 1,
                PricebookEntryId = pbe.Id,
                UnitPrice = 100 + i
            ));
        }

        Test.startTest();
        insert olis;
        Test.stopTest();
    }

    @isTest
    static void testTriggerWithMixedUnitPrices() {
        // Get data from setup
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];

        // Create OLIs with mixed unit prices
        List<OpportunityLineItem> olis = new List<OpportunityLineItem>{
            new OpportunityLineItem(
                OpportunityId = opp.Id,
                Quantity = 1,
                PricebookEntryId = pbe.Id,
                UnitPrice = 0
            ),
            new OpportunityLineItem(
                OpportunityId = opp.Id,
                Quantity = 2,
                PricebookEntryId = pbe.Id,
                UnitPrice = 50
            ),
            new OpportunityLineItem(
                OpportunityId = opp.Id,
                Quantity = 3,
                PricebookEntryId = pbe.Id,
                UnitPrice = 100
            )
        };

        Test.startTest();
        insert olis;
        Test.stopTest();
    }
}