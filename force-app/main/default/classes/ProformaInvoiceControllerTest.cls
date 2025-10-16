@isTest
public class ProformaInvoiceControllerTest {

    @TestSetup
    static void setupData() {
    }

    static void createDynamicTestData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', Email = 'test@example.com', AccountId = acc.Id);
        insert con;

        Product2 prod1 = new Product2(Name = 'Test Product 1', isActive = true);
        Product2 prod2 = new Product2(Name = 'Test Product 2', isActive = true);
        insert new List<Product2>{prod1, prod2};

        Id stdPbId = Test.getStandardPricebookId();

        PricebookEntry pbe1 = new PricebookEntry(Pricebook2Id = stdPbId, Product2Id = prod1.Id, UnitPrice = 100, IsActive = true, UseStandardPrice = false);
        PricebookEntry pbe2 = new PricebookEntry(Pricebook2Id = stdPbId, Product2Id = prod2.Id, UnitPrice = 200, IsActive = true, UseStandardPrice = false);
        insert new List<PricebookEntry>{pbe1, pbe2};

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity', 
            StageName = 'Prospecting', 
            CloseDate = Date.today().addDays(30), 
            AccountId = acc.Id,
            Pricebook2Id = stdPbId
        );
        insert opp;
    }

    @isTest
    static void testSuccessCase() {
        createDynamicTestData();
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Product2 prod1 = [SELECT Id FROM Product2 WHERE Name = 'Test Product 1' LIMIT 1];
        PricebookEntry pbe1 = [SELECT Id FROM PricebookEntry WHERE Product2Id = :prod1.Id LIMIT 1];
        Id stdPbId = Test.getStandardPricebookId();

        Test.startTest();
        
        Quote quote1 = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            ContactId = con.Id,
            Pricebook2Id = stdPbId,
            Status = 'Accepted',
            Inco_Terms__c = 'FOB',
            Payment_Terms__c = 'Advance',
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
            Pre_Carriage_Mode__c = 'Sea',
            Loading_Port__c = 'JFK',
            Destination_Port__c = 'Frankfurt',
            ShippingHandling = 50,
            Quote_Valid_From__c = Date.today(),
            Partial_Shipment__c = 'Yes',
            Destination__c = 'Germany',
            Terms_and_Conditions__c = 'Test Terms',
            Declaration__c = 'Test Declaration',
            BillingName = 'Test Bill Name',
            BillingStreet = 'Test Bill Street',
            BillingPostalCode = '12345',
            BillingCity = 'Test Bill City',
            BillingState = 'Test Bill State',
            BillingCountry = 'Test Bill Country',
            ShippingName = 'Test Ship Name',
            ShippingStreet = 'Test Ship Street',
            ShippingPostalCode = '54321',
            ShippingCity = 'Test Ship City',
            ShippingState = 'Test Ship State',
            ShippingCountry = 'Test Ship Country',
            Pre_Carriage_Destination__c = 'Test Destination',
            Vessel_Flight_No__c = 'VF123'
        );
        insert quote1;

        QuoteLineItem qli1 = new QuoteLineItem(
            QuoteId = quote1.Id,
            PricebookEntryId = pbe1.Id,
            Quantity = 5,
            UnitPrice = 100,
            Product2Id = prod1.Id,
            Discount = 0.0,
            Description = 'Test Line Item',
            Quality__c = 'High',
            Previous_Quantity__c = 4,
            Previous_Sales_Price__c = 90,
            Reject_Reason__c = 'None',
            Approver__c = UserInfo.getUserId(),
            Approval_Status__c = 'Approved',
            Approval_Comments__c = 'Test Comments',
            Status__c = 'Won'
        );
        insert qli1;

        Test.setCurrentPage(Page.ProformaInvoiceController); 
        ApexPages.currentPage().getParameters().put('quoteId', quote1.Id);

        ProformaInvoiceController controller1 = new ProformaInvoiceController();
        PageReference result1 = controller1.createProformaInvoice();

        Test.stopTest();
    }

    @isTest
    static void testExistingInvoice() {
        createDynamicTestData();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Id stdPbId = Test.getStandardPricebookId();

        Test.startTest();
        
        Quote quote2 = new Quote(
            Name = 'Quote Existing', 
            OpportunityId = opp.Id, 
            Status = 'Accepted', 
            Pricebook2Id = stdPbId
        );
        insert quote2;

        Proforma_Invoice__c existingInvoice = new Proforma_Invoice__c(
            Name = 'Existing Invoice', 
            Quote__c = quote2.Id
        );
        insert existingInvoice;

        ApexPages.currentPage().getParameters().put('quoteId', quote2.Id);
        ProformaInvoiceController controller2 = new ProformaInvoiceController();
        PageReference result2 = controller2.createProformaInvoice();

        Test.stopTest();
    }

    @isTest
    static void testInvalidQuoteStatus() {
        createDynamicTestData();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Id stdPbId = Test.getStandardPricebookId();

        Test.startTest();
        
        Quote quote3 = new Quote(
            Name = 'Quote Invalid Status', 
            OpportunityId = opp.Id, 
            Status = 'Draft', 
            Pricebook2Id = stdPbId
        );
        insert quote3;

        ApexPages.currentPage().getParameters().put('quoteId', quote3.Id);
        ProformaInvoiceController controller3 = new ProformaInvoiceController();
        PageReference result3 = controller3.createProformaInvoice();

        Test.stopTest();
    }

    @isTest
    static void testMissingQuoteId() {
        Test.startTest();
        
        ApexPages.currentPage().getParameters().clear();
        ProformaInvoiceController controller4 = new ProformaInvoiceController();
        PageReference result4 = controller4.createProformaInvoice();

        Test.stopTest();
    }

    @isTest
    static void testCancelMethod() {
        createDynamicTestData();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Id stdPbId = Test.getStandardPricebookId();

        Test.startTest();
        
        Quote quote5 = new Quote(
            Name = 'Test Quote', 
            OpportunityId = opp.Id, 
            Status = 'Accepted', 
            Pricebook2Id = stdPbId
        );
        insert quote5;

        ApexPages.currentPage().getParameters().put('quoteId', quote5.Id);
        ProformaInvoiceController controller5 = new ProformaInvoiceController();
        PageReference result5 = controller5.cancel();

        Test.stopTest();
    }

    @isTest
    static void testExceptionWithInvalidId() {
        Test.startTest();
        
        ApexPages.currentPage().getParameters().put('quoteId', 'invalidId');
        try {
            ProformaInvoiceController controller6 = new ProformaInvoiceController();
            PageReference result6 = controller6.createProformaInvoice();
        } catch (Exception e) {
        }

        Test.stopTest();
    }

    @isTest
    static void testAllFieldsQuote() {
        createDynamicTestData();
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Product2 prod1 = [SELECT Id FROM Product2 WHERE Name = 'Test Product 1' LIMIT 1];
        PricebookEntry pbe1 = [SELECT Id FROM PricebookEntry WHERE Product2Id = :prod1.Id LIMIT 1];
        Id stdPbId = Test.getStandardPricebookId();

        Test.startTest();
        
        Quote quote7 = new Quote(
            Name = 'Test Quote Full',
            OpportunityId = opp.Id,
            ContactId = con.Id,
            Pricebook2Id = stdPbId,
            Status = 'Accepted',
            Inco_Terms__c = 'FOB',
            Payment_Terms__c = 'Advance',
            Quote_Document_No__c = 1,
            Email = 'quote@example.com',
            Phone = '1234567890',
            Quote_Document_Version__c = 1,
            ExpirationDate = Date.today().addDays(15),
            Quote_Valid_From__c = Date.today(),
            ShippingHandling = 50,
            Partial_Shipment__c = 'Yes',
            Destination__c = 'Germany',
            Description = 'Test Description',
            Revision_No__c = 1,
            Country_of_Origin__c = 'USA',
            Country_of_Destination__c = 'Germany',
            Place_of_Supplier__c = 'NYC',
            Pre_Carriage_Mode__c = 'Sea',
            Loading_Port__c = 'JFK',
            Destination_Port__c = 'Frankfurt',
            Terms_and_Conditions__c = 'Test Terms',
            Declaration__c = 'Test Declaration',
            BillingName = 'Bill Name',
            BillingStreet = 'Bill Street',
            BillingPostalCode = '12345',
            BillingCity = 'Bill City',
            BillingState = 'Bill State',
            BillingCountry = 'Bill Country',
            ShippingName = 'Ship Name',
            ShippingStreet = 'Ship Street',
            ShippingPostalCode = '54321',
            ShippingCity = 'Ship City',
            ShippingState = 'Ship State',
            ShippingCountry = 'Ship Country',
            Pre_Carriage_Destination__c = 'Test Destination',
            Vessel_Flight_No__c = 'VF123'
        );
        insert quote7;

        QuoteLineItem qli7 = new QuoteLineItem(
            QuoteId = quote7.Id,
            PricebookEntryId = pbe1.Id,
            Quantity = 5,
            UnitPrice = 100,
            Product2Id = prod1.Id,
            Discount = 10.0
        );
        insert qli7;

        ApexPages.currentPage().getParameters().put('quoteId', quote7.Id);
        ProformaInvoiceController controller7 = new ProformaInvoiceController();
        PageReference result7 = controller7.createProformaInvoice();

        Test.stopTest();
    }

    @isTest
    static void testNoQuoteLineItems() {
        createDynamicTestData();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Id stdPbId = Test.getStandardPricebookId();

        Test.startTest();
        
        Quote quote8 = new Quote(
            Name = 'Quote No Items', 
            OpportunityId = opp.Id, 
            ContactId = con.Id, 
            Pricebook2Id = stdPbId, 
            Status = 'Accepted'
        );
        insert quote8;

        ApexPages.currentPage().getParameters().put('quoteId', quote8.Id);
        ProformaInvoiceController controller8 = new ProformaInvoiceController();
        PageReference result8 = controller8.createProformaInvoice();

        Test.stopTest();
    }

    @isTest
    static void testMultipleQuoteLineItems() {
        createDynamicTestData();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Product2 prod1 = [SELECT Id FROM Product2 WHERE Name = 'Test Product 1' LIMIT 1];
        Product2 prod2 = [SELECT Id FROM Product2 WHERE Name = 'Test Product 2' LIMIT 1];
        PricebookEntry pbe1 = [SELECT Id FROM PricebookEntry WHERE Product2Id = :prod1.Id LIMIT 1];
        PricebookEntry pbe2 = [SELECT Id FROM PricebookEntry WHERE Product2Id = :prod2.Id LIMIT 1];
        Id stdPbId = Test.getStandardPricebookId();

        Test.startTest();
        
        Quote quote9 = new Quote(
            Name = 'Quote Multiple Items', 
            OpportunityId = opp.Id, 
            ContactId = con.Id, 
            Pricebook2Id = stdPbId, 
            Status = 'Accepted'
        );
        insert quote9;

        QuoteLineItem qli9a = new QuoteLineItem(
            QuoteId = quote9.Id, 
            PricebookEntryId = pbe1.Id, 
            Quantity = 2, 
            UnitPrice = 100, 
            Product2Id = prod1.Id, 
            Discount = 5.0
        );
        QuoteLineItem qli9b = new QuoteLineItem(
            QuoteId = quote9.Id, 
            PricebookEntryId = pbe2.Id, 
            Quantity = 3, 
            UnitPrice = 200, 
            Product2Id = prod2.Id, 
            Discount = 10.0
        );
        insert new List<QuoteLineItem>{qli9a, qli9b};

        ApexPages.currentPage().getParameters().put('quoteId', quote9.Id);
        ProformaInvoiceController controller9 = new ProformaInvoiceController();
        PageReference result9 = controller9.createProformaInvoice();

        Test.stopTest();
    }

    @isTest
    static void testQuoteNotFound() {
        Test.startTest();
        
        ApexPages.currentPage().getParameters().put('quoteId', '001000000000000');
        ProformaInvoiceController controller10 = new ProformaInvoiceController();
        PageReference result10 = controller10.createProformaInvoice();

        Test.stopTest();
    }

    @isTest
    static void testQuoteWithSpecialCharacters() {
        createDynamicTestData();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Product2 prod1 = [SELECT Id FROM Product2 WHERE Name = 'Test Product 1' LIMIT 1];
        PricebookEntry pbe1 = [SELECT Id FROM PricebookEntry WHERE Product2Id = :prod1.Id LIMIT 1];
        Id stdPbId = Test.getStandardPricebookId();

        Test.startTest();
        
        Quote quote11 = new Quote(
            Name = 'Quote Special & Chars',
            OpportunityId = opp.Id,
            ContactId = con.Id,
            Pricebook2Id = stdPbId,
            Status = 'Accepted',
            Inco_Terms__c = 'FOB',
            Payment_Terms__c = 'LC AT SIGHT',
            Description = 'Test & Description <with> special chars',
            BillingName = 'Bill & Name',
            ShippingName = 'Ship & Name'
        );
        insert quote11;

        QuoteLineItem qli11 = new QuoteLineItem(
            QuoteId = quote11.Id,
            PricebookEntryId = pbe1.Id,
            Quantity = 1,
            UnitPrice = 99.99,
            Product2Id = prod1.Id,
            Description = 'Line & Item <Special>'
        );
        insert qli11;

        ApexPages.currentPage().getParameters().put('quoteId', quote11.Id);
        ProformaInvoiceController controller11 = new ProformaInvoiceController();
        PageReference result11 = controller11.createProformaInvoice();

        Test.stopTest();
    }

    @isTest
    static void testBulkQuoteLineItems() {
        createDynamicTestData();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Product2 prod1 = [SELECT Id FROM Product2 WHERE Name = 'Test Product 1' LIMIT 1];
        PricebookEntry pbe1 = [SELECT Id FROM PricebookEntry WHERE Product2Id = :prod1.Id LIMIT 1];
        Id stdPbId = Test.getStandardPricebookId();

        Test.startTest();
        
        Quote quote12 = new Quote(
            Name = 'Quote Bulk Items',
            OpportunityId = opp.Id,
            ContactId = con.Id,
            Pricebook2Id = stdPbId,
            Status = 'Accepted'
        );
        insert quote12;

        List<QuoteLineItem> bulkItems = new List<QuoteLineItem>();
        for(Integer i = 0; i < 20; i++) {
            bulkItems.add(new QuoteLineItem(
                QuoteId = quote12.Id,
                PricebookEntryId = pbe1.Id,
                Quantity = i + 1,
                UnitPrice = 50 + (i * 10),
                Product2Id = prod1.Id,
                Description = 'Bulk Item ' + i
            ));
        }
        insert bulkItems;

        ApexPages.currentPage().getParameters().put('quoteId', quote12.Id);
        ProformaInvoiceController controller12 = new ProformaInvoiceController();
        PageReference result12 = controller12.createProformaInvoice();

        Test.stopTest();
    }
}