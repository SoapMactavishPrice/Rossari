@isTest
private class ProductTriggerHandlerTest {
    
    @TestSetup
    static void setupTestData() {
        // Get Standard Pricebook
        //	Pricebook2
		Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        try{
        update standardPricebook;
        }Catch(Exception e){}
    
        // Create Products
        List<Product2> products = new List<Product2>{
            new Product2(Name = 'Prod A', Net_Wt__c = 10, IsActive = true),
            new Product2(Name = 'Prod B', Net_Wt__c = 20, IsActive = true)
        };
        insert products;

        // Create PricebookEntries for Products
        List<PricebookEntry> pbes = new List<PricebookEntry>();
        for (Product2 p : products) {
            pbes.add(new PricebookEntry(
                Product2Id = p.Id,
                UnitPrice = 100,
                Pricebook2Id = standardPricebook.Id,
                IsActive = true
            ));
        }
        insert pbes;
         Opportunity opp1 = new Opportunity(
            Name = 'Test Opportunity', 
            CloseDate = Date.today(), 
            StageName = 'Prospecting',
            Pricebook2Id = standardPricebook.Id
        );
        insert opp1;

        // Create a Quote (you can tie it to an Opportunity if needed)
        Quote q = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp1.Id,
            Pricebook2Id = standardPricebook.Id
        );
        insert q;

        // Create QuoteLineItems referencing the products
        List<QuoteLineItem> qlis = new List<QuoteLineItem>();
        for (PricebookEntry pbe : pbes) {
            qlis.add(new QuoteLineItem(
                QuoteId = q.Id,
                PricebookEntryId = pbe.Id,
                Quantity = 1,
                UnitPrice = 100,
                Net_Weight__c = (pbe.Product2.Name == 'Prod A' ? 10 : 20)
            ));
        }
        insert qlis;
    }

   @isTest
static void testUpdateQuoteLineItem() {
    Product2 prod = new Product2(Name='Test Product', IsActive=true, Net_Wt__c=10);
    insert prod;
    
    Id stdPbId = Test.getStandardPricebookId();
    // Get the Standard PricebookEntry created automatically
     PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = stdPbId,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

    
    // Create a custom Pricebook and PBE
    Pricebook2 customPb = new Pricebook2(Name='Custom PB', IsActive=true);
    insert customPb;
    PricebookEntry customPbe = new PricebookEntry(
        Pricebook2Id = customPb.Id,
        Product2Id = prod.Id,
        UnitPrice = 100,
        IsActive = true
    );
    insert customPbe;
    
    Account acc = new Account(Name='Test Account');
    insert acc;
    
    Opportunity opp = new Opportunity(
        Name='Test Opp',
        AccountId=acc.Id,
        StageName='Prospecting',
        CloseDate=Date.today(),
        Pricebook2Id=customPb.Id
    );
    insert opp;
    
    Quote qt = new Quote(
        Name='Test Quote',
        OpportunityId=opp.Id,
        Status='Draft',
        Pricebook2Id=customPb.Id
    );
    try{
    insert qt;
    }Catch(Exception e){}
    
    QuoteLineItem qli = new QuoteLineItem(
        QuoteId=qt.Id,
        PricebookEntryId=customPbe.Id,
        Quantity=1,
        UnitPrice=100,
        Net_Weight__c=10
    );
    insert qli;

    // Update Product
    Product2 updatedProd = [SELECT Id, Net_Wt__c FROM Product2 WHERE Id=:prod.Id];
    updatedProd.Net_Wt__c = 20;

    Test.startTest();
    ProductTriggerHandler.updateQuoteLineItem(
        new List<Product2>{updatedProd},
        new Map<Id, Product2>{updatedProd.Id => prod}
    );
    Test.stopTest();
}


    @isTest
    static void testUpdateProformaInvoiceLineItem() {
        Product2 prod = new Product2(Name='Test Product', IsActive=true, Net_Wt__c=15);
        insert prod;
        
        Proforma_Invoice__c inv = new Proforma_Invoice__c(Name='Test Invoice');
        insert inv;
        
        Proforma_Invoice_Line_Item__c pli = new Proforma_Invoice_Line_Item__c(Product__c=prod.Id, Net_Weight__c=15, Proforma_Invoice_Name__c=inv.Id);
        insert pli;

        Product2 updatedProd = [SELECT Id, Net_Wt__c FROM Product2 WHERE Id = :prod.Id];
        updatedProd.Net_Wt__c = 25;

        Test.startTest();
        ProductTriggerHandler.updateProformaInvoiceLineItem(
            new List<Product2>{updatedProd},
            new Map<Id, Product2>{updatedProd.Id => prod}
        );
        Test.stopTest();
    }
}