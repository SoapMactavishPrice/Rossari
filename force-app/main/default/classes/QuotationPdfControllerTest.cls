@isTest
public class QuotationPdfControllerTest {

    @testSetup
    static void setupTestData() {
        // Setup standard pricebook first
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        
        // Create test products
        Product2 prod = new Product2(Name = 'Test Product', ProductCode = 'TP001',Pack_Size__c = '10kg', Base_UOM__c = '', IsActive = true);
        insert prod;
        
        // Create pricebook entry
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;
    }

    @isTest
    static void testControllerDefaultConstructor() {
        // Get the standard pricebook that was set up in testSetup
        Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
        
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Bank__c bank = new Bank__c(Name = 'Test Bank', Bank_Account_No__c = '123456', Branch__c = 'Main', SWIFT_Code__c = 'SWFT123');
        insert bank;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity', 
            CloseDate = Date.today(), 
            StageName = 'Prospecting',
            Pricebook2Id = pb.Id
        );
        insert opp;

        Quote quote = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Payment_Terms__c = 'Advance',
            BillingName = 'Billing Contact',
            BillingStreet = '123 Billing St',
            BillingCity = 'Billing City',
            BillingState = 'Billing State',
            BillingPostalCode = '12345',
            BillingCountry = 'India',
            ShippingStreet = '456 Shipping St',
            ShippingCity = 'Shipping City',
            ShippingState = 'Shipping State',
            ShippingPostalCode = '67890',
            ShippingCountry = 'India',
            ShippingName = 'Shipping Contact',
            Inco_Terms__c = 'FOB',
            Pre_Carriage_Mode__c = 'Sea',
            Country_of_Origin__c = 'India',
            Country_of_Destination__c = 'USA',
            Destination__c = 'New York',
            Loading_Port__c = 'Mumbai',
            Destination_Port__c = 'NY Port',
            Place_of_Supplier__c = 'India Office',
            Partial_Shipment__c = 'No',
            Terms_and_Conditions__c = 'Standard terms',
            Declaration__c = 'This is a declaration.',
            CurrencyIsoCode = 'INR',
            Bank__c = bank.Id,
            Pricebook2Id = pb.Id
        );
        insert quote;

        Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Test Product' LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :prod.Id LIMIT 1];

        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id, 
            Quantity = 2, 
            UnitPrice = 100, 
            PricebookEntryId = pbe.Id,
            Product2Id = prod.Id
        );
        insert qli;

        Test.setCurrentPage(Page.QuotationPdf);
        ApexPages.currentPage().getParameters().put('id', quote.Id);

        QuotationPdfController controller = new QuotationPdfController();
        controller.buildEmailContent();
    }

    @isTest
    static void testControllerParamConstructorAndEmailBody() {
        // Get the standard pricebook that was set up in testSetup
        Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
        
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Bank__c bank = new Bank__c(Name = 'Test Bank', Bank_Account_No__c = '654321', Branch__c = 'BranchX', SWIFT_Code__c = 'SWFT999');
        insert bank;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp 2', 
            CloseDate = Date.today(), 
            StageName = 'Qualification',
            Pricebook2Id = pb.Id
        );
        insert opp;

        Quote quote = new Quote(
            Name = 'Quote Two',
            OpportunityId = opp.Id,
            Payment_Terms__c = 'Advance',
            BillingName = 'Billing Contact 2',
            BillingStreet = 'Street 2',
            BillingCity = 'City 2',
            BillingState = 'State 2',
            BillingPostalCode = '22222',
            BillingCountry = 'USA',
            ShippingStreet = 'Ship St 2',
            ShippingCity = 'Ship City 2',
            ShippingState = 'Ship State 2',
            ShippingPostalCode = '33333',
            ShippingCountry = 'USA',
            ShippingName = 'Shipping Contact 2',
            Inco_Terms__c = 'CIF',
            Destination__c = 'California',
            Terms_and_Conditions__c = 'Test terms 2',
            Declaration__c = 'Test declaration 2',
            CurrencyIsoCode = 'USD',
            Bank__c = bank.Id,
            Pricebook2Id = pb.Id
        );
        insert quote;

        Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Test Product' LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :prod.Id LIMIT 1];

        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id, 
            Quantity = 1, 
            UnitPrice = 200, 
            PricebookEntryId = pbe.Id,
            Product2Id = prod.Id
        );
        insert qli;

        QuotationPdfController controller = new QuotationPdfController(quote.Id, 'quotation');
        controller.buildEmailContent();

        String emailBody = QuotationPdfController.getEmailBody(quote.Id, 'quotation');
    }
}