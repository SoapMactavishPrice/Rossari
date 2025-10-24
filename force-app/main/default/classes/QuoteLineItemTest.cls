@isTest
private class QuoteLineItemTest {

    @isTest
    static void testQuoteLineItemTrigger() {
        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id
        );
        insert opp;

        // Get Standard Pricebook ID without updating (fix for UNABLE_TO_LOCK_ROW)
        Id standardPricebookId = Test.getStandardPricebookId();
        
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

        // Create Quote with custom pricebook
        Quote quote = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Pricebook2Id = standardPricebook.Id
        );
        insert quote;

        Test.startTest();

        PricebookEntry priceBookEntry = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert priceBookEntry;
        // Test Case 1: Insert QuoteLineItem with UnitPrice as 0 (should trigger email)
        QuoteLineItem qli1 = new QuoteLineItem(
            QuoteId = quote.Id,
            PricebookEntryId = priceBookEntry.Id,
            Quantity = 1,
            UnitPrice = 0
        );
        insert qli1;

        // Test Case 2: Update QuoteLineItem to have UnitPrice as 0 (should trigger email)
        QuoteLineItem qli2 = new QuoteLineItem(
            QuoteId = quote.Id,
            PricebookEntryId = priceBookEntry.Id,
            Quantity = 1,
            UnitPrice = 150
        );
        insert qli2;
        
        // Update to trigger the condition
        qli2.UnitPrice = 0;
        update qli2;

        // Test Case 3: Insert QuoteLineItem with valid UnitPrice (should NOT trigger email)
        QuoteLineItem qli4 = new QuoteLineItem(
            QuoteId = quote.Id,
            PricebookEntryId = priceBookEntry.Id,
            Quantity = 1,
            UnitPrice = 200
        );
        insert qli4;

        Test.stopTest();
    }

    @isTest
    static void testTriggerWithMultipleQuotes() {
        // Test bulk scenario with multiple quotes
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id
        );
        insert opp;

        // Get Standard Pricebook ID without updating
        Id standardPricebookId = Test.getStandardPricebookId();

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


        Pricebook2 customPb = new Pricebook2(Name = 'Custom Pricebook', IsActive = true);
        insert customPb;

        PricebookEntry customPbe = new PricebookEntry(
            Pricebook2Id = customPb.Id,
            Product2Id = Prod.Id,
            UnitPrice = 120.00,
            IsActive = true,
            UseStandardPrice = false
        );
        insert customPbe;

        // Create multiple quotes
        Quote quote1 = new Quote(Name = 'Test Quote 1', OpportunityId = opp.Id, Pricebook2Id = customPb.Id);
        Quote quote2 = new Quote(Name = 'Test Quote 2', OpportunityId = opp.Id, Pricebook2Id = customPb.Id);
        insert new List<Quote>{quote1, quote2};

        Test.startTest();
        // Create QLIs for multiple quotes in bulk with UnitPrice = 0
        List<QuoteLineItem> qlis = new List<QuoteLineItem>();
        qlis.add(new QuoteLineItem(QuoteId = quote1.Id, PricebookEntryId = customPbe.Id, Quantity = 1, UnitPrice = 0));
        qlis.add(new QuoteLineItem(QuoteId = quote2.Id, PricebookEntryId = customPbe.Id, Quantity = 1, UnitPrice = 0));
        insert qlis;
        Test.stopTest();
    }
}