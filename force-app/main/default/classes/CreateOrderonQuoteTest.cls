@IsTest
private class CreateOrderonQuoteTest {
    
    @TestSetup
    static void setupData() {
        List<SObject> recordsToInsert = new List<SObject>();
        
        Id standardPbId = Test.getStandardPricebookId();
        
        Account acc = new Account(Name = 'Test Account');
        recordsToInsert.add(acc);
        
        insert recordsToInsert;
        recordsToInsert.clear();
        
        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', Email = 'test@example.com', AccountId = acc.Id);
        recordsToInsert.add(con);
        
        insert recordsToInsert;
        recordsToInsert.clear();
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opp', 
            StageName = 'Quotation', 
            CloseDate = Date.today(), 
            AccountId = acc.Id,
            Pricebook2Id = standardPbId
        );
        recordsToInsert.add(opp);
        
        insert recordsToInsert;
        recordsToInsert.clear();

        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        try{
        update standardPricebook;
         }Catch(Exception e){}

        Base_UoM_Master__c baseUom = new Base_UoM_Master__c(Name = 'Kilogram');
        recordsToInsert.add(baseUom);
        
        insert recordsToInsert;
        recordsToInsert.clear();
 
        Product2 prod = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP001',
            Pack_Size__c = '10kg',
            Base_UOM__c = baseUom.Id,
            IsActive = true
        );
        recordsToInsert.add(prod);
        
        insert recordsToInsert;
        recordsToInsert.clear();
 
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        recordsToInsert.add(pbe);
        
        insert recordsToInsert;
        recordsToInsert.clear();

        Quote qt = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Pricebook2Id = standardPbId,
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
        recordsToInsert.add(qt);
        
        insert recordsToInsert;
        recordsToInsert.clear();

        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = qt.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 2,
            UnitPrice = 100,
            Product2Id = prod.Id
        );
        recordsToInsert.add(qli);
        
        insert recordsToInsert;
    }
    
    @IsTest
    static void testGetInitialData() {
        Quote qt = [SELECT Id FROM Quote LIMIT 1];
        CreateOrderonQuote.getInitialData(qt.Id);
    }

    @IsTest
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

    @IsTest
    static void testDeleteQuoteLineItem() {
        QuoteLineItem qli = [SELECT Id FROM QuoteLineItem LIMIT 1];
        CreateOrderonQuote.deleteQuoteLineItem(qli.Id);
    }
}