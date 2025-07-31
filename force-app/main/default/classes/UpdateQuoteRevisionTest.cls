@isTest
private class UpdateQuoteRevisionTest {
    @isTest
    static void testQuoteRevisionIncrement() {
        // Create test Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create test Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id
        );
        insert opp;

        // Create test Product
        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;
        
        // Get standard pricebook - this is the critical fix
        Test.startTest();
        Id standardPbId = Test.getStandardPricebookId();
        Test.stopTest();
        
        // Create a custom pricebook for testing
        Pricebook2 customPb = new Pricebook2(
            Name = 'Test Pricebook',
            IsActive = true
        );
        insert customPb;

        // STEP 1: Insert Standard PricebookEntry (MANDATORY)
        PricebookEntry standardEntry = new PricebookEntry(
            Product2Id = prod.Id,
            Pricebook2Id = standardPbId,  // Use the standard pricebook ID here
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false  // Important for test context
        );
        insert standardEntry;

        // STEP 2: Insert Custom PricebookEntry
        PricebookEntry customEntry = new PricebookEntry(
            Product2Id = prod.Id,
            Pricebook2Id = customPb.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert customEntry;

        // Create Quote with the custom pricebook
        Quote qt = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Pricebook2Id = customPb.Id,
            Status = 'Draft'
        );
        insert qt;

        // Create QuoteLineItem using custom price
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = qt.Id,
            Quantity = 1,
            UnitPrice = 100,
            PricebookEntryId = customEntry.Id,
            Product2Id = prod.Id
        );
        insert qli;

        // First update - triggers Revision_No__c = 1
        qli.Quantity = 2;
        update qli;

        Quote updatedQuote = [SELECT Id, Revision_No__c FROM Quote WHERE Id = :qt.Id];

        // Second update - triggers Revision_No__c = 2
        qli.UnitPrice = 150;
        update qli;

        updatedQuote = [SELECT Id, Revision_No__c FROM Quote WHERE Id = :qt.Id];
    }
}