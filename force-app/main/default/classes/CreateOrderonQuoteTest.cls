@isTest
public class CreateOrderonQuoteTest {

    @testSetup
    static void setupData() {
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
        
        // Create Product
        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;
        
        // Get Standard Pricebook
        Id stdPbId = Test.getStandardPricebookId();
        
        // Insert a Standard PricebookEntry (REQUIRED)
        PricebookEntry stdPbe = new PricebookEntry(
            Product2Id = prod.Id,
            Pricebook2Id = stdPbId,
            UnitPrice = 100,
            IsActive = true
        );
        insert stdPbe;
        
        // Create Custom Pricebook
        Pricebook2 customPb = new Pricebook2(Name = 'Test Pricebook 2', IsActive = true);
        insert customPb;
        
        // Insert Custom PricebookEntry (after standard price is set)
        PricebookEntry customPbe = new PricebookEntry(
            Product2Id = prod.Id,
            Pricebook2Id = customPb.Id,
            UnitPrice = 150,
            IsActive = true
        );
        insert customPbe;
        
        // Create Quote
        Quote quote = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Pricebook2Id = stdPbId,
            Status = 'Draft',
            CurrencyIsoCode = 'INR'
        );
        insert quote;
        
        // Create Quote Line Item
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            Product2Id = prod.Id,
            PricebookEntryId = stdPbe.Id,
            UnitPrice = 150,
            Quantity = 3,
            Description = 'Test QLI'
        );
        insert qli;
    }


    @isTest
    static void testGetQuoteLineItems() {
        Quote q = [SELECT Id FROM Quote LIMIT 1];

        Test.startTest();
        List<QuoteLineItem> result = CreateOrderonQuote.getQuoteLineItems(q.Id);
        Test.stopTest();

    }

    @isTest
    static void testCreateOrderFromQuote() {
        Quote q = [SELECT Id FROM Quote LIMIT 1];
        List<QuoteLineItem> qlis = [SELECT Id, Product2Id, PricebookEntryId, UnitPrice, Quantity, Description FROM QuoteLineItem WHERE QuoteId = :q.Id];

        Test.startTest();
        Id orderId = CreateOrderonQuote.createOrderFromQuote(q.Id, qlis, 'INR', Test.getStandardPricebookId());
        Test.stopTest();

        Order createdOrder = [SELECT Id, QuoteId FROM Order WHERE Id = :orderId];
    }

    @isTest
    static void testDeleteQuoteLineItem() {
        QuoteLineItem qli = [SELECT Id FROM QuoteLineItem LIMIT 1];

        Test.startTest();
        CreateOrderonQuote.deleteQuoteLineItem(qli.Id);
        Test.stopTest();

        List<QuoteLineItem> remaining = [SELECT Id FROM QuoteLineItem WHERE Id = :qli.Id];
    }
}