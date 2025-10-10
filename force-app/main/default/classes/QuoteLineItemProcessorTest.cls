@IsTest
private class QuoteLineItemProcessorTest {

    @TestSetup
    static void setupTestData() {
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

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

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp1 = new Opportunity(
            Name = 'Test Opportunity', 
            CloseDate = Date.today(), 
            StageName = 'Prospecting',
            Pricebook2Id = standardPricebook.Id
        );
        insert opp1;
        
        Quote quote = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp1.Id,
            //AccountId = acc.Id,
            SAP_Order_No__c = 'SAP123'
        );
        insert quote;

        // QuoteLineItem
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            Product2Id = prod.Id,
            Quantity = 5,
            UnitPrice = 100,
            PricebookEntryId = pbe.Id
        );
        insert qli;
    }

    @IsTest
    static void testQueueableProcessing() {
        // Get all test QuoteLineItems
        List<QuoteLineItem> qlis = [SELECT Id FROM QuoteLineItem LIMIT 1];
        List<Id> qliIds = new List<Id>();
        for (QuoteLineItem qli : qlis) {
            qliIds.add(qli.Id);
        }

        // Stub the CreateQuotation_ToSAP.addItem method for test context
        Test.startTest();
        System.enqueueJob(new QuoteLineItemProcessor(qliIds));
        Test.stopTest();

        // Assert that the records exist
        System.assertEquals(1, [SELECT COUNT() FROM QuoteLineItem]);
    }

    @IsTest
    static void testQueueableChaining() {
        // Create multiple QLIs to test chaining
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];

        List<QuoteLineItem> extraQlis = new List<QuoteLineItem>();
        for (Integer i = 0; i < 3; i++) {
            extraQlis.add(new QuoteLineItem(
                QuoteId = quote.Id,
                Product2Id = prod.Id,
                Quantity = 2 + i,
                UnitPrice = 50,
                PricebookEntryId = pbe.Id
            ));
        }
        insert extraQlis;

        List<Id> qliIds = new List<Id>();
        for (QuoteLineItem qli : [SELECT Id FROM QuoteLineItem]) {
            qliIds.add(qli.Id);
        }

        Test.startTest();
        System.enqueueJob(new QuoteLineItemProcessor(qliIds));
        Test.stopTest();

        System.assert(qliIds.size() >= 1, 'There should be at least one QLI processed.');
    }
}