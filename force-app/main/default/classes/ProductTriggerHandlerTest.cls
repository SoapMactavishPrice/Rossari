@isTest
private class ProductTriggerHandlerTest {

    @isTest
    static void testUpdateQuoteLineItem() {
        Product2 prod = new Product2(Name='Test Product', IsActive=true, Net_Wt__c=10);
        insert prod;
        
        Id stdPbId = Test.getStandardPricebookId();
        insert new PricebookEntry(Pricebook2Id=stdPbId, Product2Id=prod.Id, UnitPrice=100, IsActive=true, UseStandardPrice=true);
        
        Pricebook2 customPb = new Pricebook2(Name='Custom PB', IsActive=true);
        insert customPb;
        PricebookEntry customPbe = new PricebookEntry(Pricebook2Id=customPb.Id, Product2Id=prod.Id, UnitPrice=100, IsActive=true, UseStandardPrice=false);
        insert customPbe;
        
        Account acc = new Account(Name='Test Account');
        insert acc;
        
        Opportunity opp = new Opportunity(Name='Test Opp', AccountId=acc.Id, StageName='Prospecting', CloseDate=Date.today(), Pricebook2Id=customPb.Id);
        insert opp;
        
        Quote qt = new Quote(Name='Test Quote', OpportunityId=opp.Id, Status='Draft', Pricebook2Id=customPb.Id);
        insert qt;
        
        QuoteLineItem qli = new QuoteLineItem(QuoteId=qt.Id, Product2Id=prod.Id, Quantity=1, UnitPrice=100, Net_Weight__c=10, PricebookEntryId=customPbe.Id);
        insert qli;

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