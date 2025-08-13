@isTest
public class ProformaInvoiceControllerTest {

    @isTest
    static void testCreateProformaInvoiceSuccess() {

        Id stdPbId = Test.getStandardPricebookId();

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', Email = 'test@example.com', AccountId = acc.Id);
        insert con;

        Opportunity opp = new Opportunity(Name = 'Test Opportunity', StageName = 'Prospecting', CloseDate = Date.today().addDays(30), AccountId = acc.Id);
        insert opp;

        Product2 prod = new Product2(Name = 'Test Product', isActive = true);
        insert prod;

        PricebookEntry pbe = new PricebookEntry(Pricebook2Id = stdPbId, Product2Id = prod.Id, UnitPrice = 100, IsActive = true);
        insert pbe;

        Quote quote = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            ContactId = con.Id,
            Pricebook2Id = stdPbId,
            Status = 'Accepted',
            Inco_Terms__c = 'FOB',
            Payment_Terms__c = 'Net 30',
            Quote_Document_No__c = 1,
            Email = 'quote@example.com',
            Phone = '1234567890',
            Quote_Document_Version__c = 1,
            ExpirationDate = Date.today().addDays(15),
            Description = 'Test Quote Description',
            Revision_No__c = 1,
            Country_of_Origin__c = 'USA',
            Country_of_Destination__c = 'Germany',
            Place_of_Supplier__c = 'NYC',
            Pre_Carriage_Mode__c = 'Air',
            Loading_Port__c = 'JFK',
            Destination_Port__c = 'Frankfurt'
        );
        insert quote;

        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 5,
            UnitPrice = 100,
            Product2Id = prod.Id,
            Discount = 0.0,
            Description = 'Test Line Item'
        );
        insert qli;

        Test.setCurrentPage(Page.ProformaInvoiceController); 
        ApexPages.currentPage().getParameters().put('quoteId', quote.Id);

        ProformaInvoiceController controller = new ProformaInvoiceController();
        PageReference result = controller.createProformaInvoice();

        List<Proforma_Invoice__c> invoices = [SELECT Id, Quote__c FROM Proforma_Invoice__c WHERE Quote__c = :quote.Id];

        List<Proforma_Invoice_Line_Item__c> lineItems = [
            SELECT Id, Proforma_Invoice_Name__c FROM Proforma_Invoice_Line_Item__c
            WHERE Proforma_Invoice_Name__c = :invoices[0].Id
        ];
    }

    @isTest
    static void testCreateProformaInvoiceWithExistingInvoice() {

        Id stdPbId = Test.getStandardPricebookId();

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(Name = 'Test Opp', StageName = 'Prospecting', CloseDate = Date.today().addDays(10), AccountId = acc.Id);
        insert opp;

        Quote quote = new Quote(Name = 'Quote Existing', OpportunityId = opp.Id, Status = 'Accepted', Pricebook2Id = stdPbId);
        insert quote;

        Proforma_Invoice__c existingInvoice = new Proforma_Invoice__c(Name = 'Existing Invoice', Quote__c = quote.Id);
        insert existingInvoice;

        Test.setCurrentPage(Page.ProformaInvoiceController); 
        ApexPages.currentPage().getParameters().put('quoteId', quote.Id);

        ProformaInvoiceController controller = new ProformaInvoiceController();
        PageReference result = controller.createProformaInvoice();
    }

    @isTest
    static void testCreateProformaInvoiceWithInvalidQuoteStatus() {

        Id stdPbId = Test.getStandardPricebookId();

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(Name = 'Test Opp', StageName = 'Prospecting', CloseDate = Date.today().addDays(10), AccountId = acc.Id);
        insert opp;

        Quote quote = new Quote(Name = 'Quote Invalid Status', OpportunityId = opp.Id, Status = 'Draft', Pricebook2Id = stdPbId);
        insert quote;

        Test.setCurrentPage(Page.ProformaInvoiceController); 
        ApexPages.currentPage().getParameters().put('quoteId', quote.Id);

        ProformaInvoiceController controller = new ProformaInvoiceController();
        PageReference result = controller.createProformaInvoice();
    }

    @isTest
    static void testCreateProformaInvoiceWithMissingQuoteId() {

        Test.setCurrentPage(Page.ProformaInvoiceController); 

        ProformaInvoiceController controller = new ProformaInvoiceController();
        PageReference result = controller.createProformaInvoice();
    }
}