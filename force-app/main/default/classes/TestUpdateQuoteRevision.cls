@isTest
public class TestUpdateQuoteRevision {
    
    @testSetup
    static void setupAllData() {
        Id standardPbId = Test.getStandardPricebookId();
        
        // Create base test data once
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id
        );
        insert opp;

        Quote q = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Status = 'Draft',
            Pricebook2Id = standardPbId
        );
        insert q;

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


        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = q.Id,
            Quantity = 1,
            UnitPrice = 100,
            PricebookEntryId = pbe.Id
        );
        insert qli;
    }

    @isTest
    static void testRevisionIncrementOnUpdate() {
        // Get existing data from setup
        QuoteLineItem qli = [SELECT Id, Quantity, UnitPrice FROM QuoteLineItem LIMIT 1];
        Quote q = [SELECT Id, Revision_No__c FROM Quote LIMIT 1];

        Test.startTest();
        // Update the quote line item
        qli.Quantity = 2;
        update qli;
        Test.stopTest();

        // Verify results
        Quote updatedQuote = [SELECT Revision_No__c FROM Quote WHERE Id = :q.Id];
        System.assertEquals(1, updatedQuote.Revision_No__c, 'Revision number should increment to 1');
    }

    @isTest
    static void testNoRevisionWhenNoChange() {
        // Get existing data from setup
        QuoteLineItem qli = [SELECT Id, Quantity, UnitPrice FROM QuoteLineItem LIMIT 1];
        Quote q = [SELECT Id, Revision_No__c FROM Quote LIMIT 1];

        Test.startTest();
        // Update with same values - no actual change
        update qli;
        Test.stopTest();

        Quote updatedQuote = [SELECT Revision_No__c FROM Quote WHERE Id = :q.Id];
        System.assertEquals(null, updatedQuote.Revision_No__c, 'Revision number should remain null if no relevant change');
    }

    @isTest
    static void testBulkQuoteLineItemUpdates() {
        // Get base data from setup
        Quote q = [SELECT Id FROM Quote LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];

        // Create additional quote line items for bulk testing
        List<QuoteLineItem> qlis = new List<QuoteLineItem>();
        for(Integer i = 0; i < 5; i++) {
            qlis.add(new QuoteLineItem(
                QuoteId = q.Id,
                Quantity = 1,
                UnitPrice = 100 + i,
                PricebookEntryId = pbe.Id
            ));
        }
        insert qlis;

        Test.startTest();
        // Update all quote line items in bulk
        for(QuoteLineItem qli : qlis) {
            qli.Quantity = 2;
        }
        update qlis;
        Test.stopTest();

        // Verify the quote was updated only once despite multiple QLI updates
        Quote updatedQuote = [SELECT Revision_No__c FROM Quote WHERE Id = :q.Id];
        System.assertEquals(1, updatedQuote.Revision_No__c, 'Revision number should be 1 for bulk updates in same transaction');
    }

    @isTest
    static void testRevisionIncrementMultipleTimes() {
        // Get existing data from setup
        QuoteLineItem qli = [SELECT Id, Quantity, UnitPrice FROM QuoteLineItem LIMIT 1];
        Quote q = [SELECT Id, Revision_No__c FROM Quote LIMIT 1];

        Test.startTest();
        // First update
        qli.Quantity = 2;
        update qli;

        // Second update
        qli.UnitPrice = 150;
        update qli;

        // Third update
        qli.Quantity = 3;
        update qli;
        Test.stopTest();

        Quote updatedQuote = [SELECT Revision_No__c FROM Quote WHERE Id = :q.Id];
        System.assertEquals(3, updatedQuote.Revision_No__c, 'Revision number should increment to 3 after multiple updates');
    }

    @isTest
    static void testNoRevisionForUnchangedFields() {
        // Get existing data from setup
        QuoteLineItem qli = [SELECT Id, Quantity, UnitPrice, Description FROM QuoteLineItem LIMIT 1];
        Quote q = [SELECT Id FROM Quote LIMIT 1];
        
        // Update quote to have existing revision
        q.Revision_No__c = 5;
        update q;

        Test.startTest();
        // Update only description field which shouldn't trigger revision
        qli.Description = 'Updated Description';
        update qli;
        Test.stopTest();

        Quote updatedQuote = [SELECT Revision_No__c FROM Quote WHERE Id = :q.Id];
        System.assertEquals(5, updatedQuote.Revision_No__c, 'Revision number should remain unchanged when only non-triggering fields are updated');
    }

    @isTest
    static void testMultipleQuotesScenario() {
        // Get base data from setup
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];
        Id standardPbId = Test.getStandardPricebookId();

        // Create additional quotes for testing multiple quotes scenario
        List<Quote> quotes = new List<Quote>();
        for(Integer i = 0; i < 3; i++) {
            quotes.add(new Quote(
                Name = 'Additional Test Quote ' + i,
                OpportunityId = opp.Id,
                Status = 'Draft',
                Pricebook2Id = standardPbId
            ));
        }
        insert quotes;

        // Create QLIs for each quote
        List<QuoteLineItem> qlis = new List<QuoteLineItem>();
        for(Quote quote : quotes) {
            qlis.add(new QuoteLineItem(
                QuoteId = quote.Id,
                Quantity = 1,
                UnitPrice = 100,
                PricebookEntryId = pbe.Id
            ));
        }
        insert qlis;

        Test.startTest();
        // Update all QLIs
        for(QuoteLineItem qli : qlis) {
            qli.Quantity = 2;
        }
        update qlis;
        Test.stopTest();

        // Verify each quote has its own revision
        List<Quote> updatedQuotes = [SELECT Id, Revision_No__c FROM Quote WHERE Id IN :quotes];
        for(Quote updatedQuote : updatedQuotes) {
            System.assertEquals(1, updatedQuote.Revision_No__c, 'Each quote should have revision 1');
        }
    }

    @isTest
    static void testMixedUpdatesScenario() {
        // Get base data from setup
        QuoteLineItem qli = [SELECT Id, Quantity, UnitPrice, Description FROM QuoteLineItem LIMIT 1];
        Quote q = [SELECT Id, Revision_No__c FROM Quote LIMIT 1];

        Test.startTest();
        // First update - should trigger revision (quantity change)
        qli.Quantity = 5;
        update qli;

        // Second update - should NOT trigger revision (description only)
        qli.Description = 'Test Description';
        update qli;

        // Third update - should trigger revision (unit price change)
        qli.UnitPrice = 200;
        update qli;
        Test.stopTest();

        Quote updatedQuote = [SELECT Revision_No__c FROM Quote WHERE Id = :q.Id];
        System.assertEquals(2, updatedQuote.Revision_No__c, 'Revision number should be 2 after mixed updates (only quantity and price changes should trigger)');
    }

    @isTest
    static void testInitialNullRevisionScenario() {
        // Create fresh data for this specific scenario
        Id standardPbId = Test.getStandardPricebookId();
        Account acc = new Account(Name = 'Null Revision Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Null Revision Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id
        );
        insert opp;

        Quote q = new Quote(
            Name = 'Null Revision Test Quote',
            OpportunityId = opp.Id,
            Status = 'Draft',
            Pricebook2Id = standardPbId,
            Revision_No__c = null // Explicitly set to null
        );
        insert q;

        Product2 prod = new Product2(Name = 'Null Revision Test Product', IsActive = true);
        insert prod;

        PricebookEntry pbe = new PricebookEntry(
            Product2Id = prod.Id,
            Pricebook2Id = standardPbId,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = q.Id,
            Quantity = 1,
            UnitPrice = 100,
            PricebookEntryId = pbe.Id
        );
        insert qli;

        Test.startTest();
        // First update from null revision
        qli.Quantity = 10;
        update qli;
        Test.stopTest();

        Quote updatedQuote = [SELECT Revision_No__c FROM Quote WHERE Id = :q.Id];
        System.assertEquals(1, updatedQuote.Revision_No__c, 'Revision should start from 1 when initial revision is null');
    }
}