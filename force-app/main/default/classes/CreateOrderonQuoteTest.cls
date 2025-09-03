@isTest
private class CreateOrderonQuoteTest {
    
    @testSetup
    static void setupData() {
        // Setup standard pricebook first
        Pricebook2 standardPb = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPb;
        
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', Email = 'test@example.com', AccountId = acc.Id);
        insert con;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opp', 
            StageName = 'Quotation', 
            CloseDate = Date.today(), 
            AccountId = acc.Id,
            Pricebook2Id = standardPb.Id
        );
        insert opp;

        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;

        PricebookEntry pbe = new PricebookEntry(
            Product2Id = prod.Id, 
            Pricebook2Id = standardPb.Id, 
            UnitPrice = 100, 
            IsActive = true
        );
        insert pbe;

        Quote qt = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Pricebook2Id = standardPb.Id,
            BillingStreet = '123 St',
            BillingCity = 'City',
            BillingState = 'State',
            BillingPostalCode = '12345',
            BillingCountry = 'Country',
            ShippingStreet = '123 St',
            ShippingCity = 'City',
            ShippingState = 'State',
            ShippingPostalCode = '12345',
            ShippingCountry = 'Country',
            ContactId = con.Id
        );
        insert qt;

        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = qt.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 2,
            UnitPrice = 100,
            Product2Id = prod.Id
        );
        insert qli;
    }
    
    @isTest
    static void testGetInitialData() {
        Quote qt = [SELECT Id FROM Quote LIMIT 1];
        CreateOrderonQuote.getInitialData(qt.Id);
    }

    @isTest
    static void testCreateOrderFromQuote() {
        Quote qt = [SELECT Id, Pricebook2Id, Opportunity.AccountId, CurrencyIsoCode FROM Quote LIMIT 1];
        QuoteLineItem qli = [SELECT Id, Product2Id, PricebookEntryId, UnitPrice, Quantity FROM QuoteLineItem LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];

        Map<String, Object> item = new Map<String, Object>{
            'UnitPrice' => qli.UnitPrice,
            'Quantity' => qli.Quantity,
            'Discount' => 10,
            'Product2Id' => qli.Product2Id,
            'PricebookEntryId' => qli.PricebookEntryId,
            'Description' => 'Test item'
        };
        List<Map<String, Object>> lineItems = new List<Map<String, Object>>{ item };

        CreateOrderonQuote.createOrderFromQuote(
            qt.Id,
            lineItems,
            'Draft',
            Date.today(),
            con.Id,
            qt.CurrencyIsoCode,
            qt.Pricebook2Id
        );
    }

    @isTest
    static void testDeleteQuoteLineItem() {
        QuoteLineItem qli = [SELECT Id FROM QuoteLineItem LIMIT 1];
        CreateOrderonQuote.deleteQuoteLineItem(qli.Id);
    }
}