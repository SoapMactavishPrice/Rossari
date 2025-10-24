@isTest
private class ProformaInvoiceControllerTest {
    @isTest
    static void testCreateProformaInvoice() {
        // Create Account and Contact
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact con = new Contact(LastName = 'Test Contact', AccountId = acc.Id, Email = 'test@example.com');
        insert con;

        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        // Setup Standard Pricebook and Product
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

        // Create Quote
        Quote quote = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            ContactId = con.Id,
            Pricebook2Id = standardPricebook.Id,
            Status = 'Accepted',
            ExpirationDate = Date.today().addDays(15),
            Quote_Valid_From__c = Date.today()
        );
        insert quote;

        // Create QuoteLineItem with required PricebookEntryId
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 5,
            UnitPrice = 100
        );
        insert qli;

        // Simulate Visualforce page context
        ApexPages.currentPage().getParameters().put('quoteId', quote.Id);

        Test.startTest();
        ProformaInvoiceController controller = new ProformaInvoiceController();
        controller.createProformaInvoice();
        controller.cancel();
        Test.stopTest();
    }
}