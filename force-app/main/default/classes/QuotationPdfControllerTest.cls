@isTest
public class QuotationPdfControllerTest {
    @isTest
    static void testAllControllerScenarios() {
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

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

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Bank__c bank1 = new Bank__c(Name = 'Test Bank', Bank_Account_No__c = '123456', Branch__c = 'Main', SWIFT_Code__c = 'SWFT123');
        insert bank1;

        Opportunity opp1 = new Opportunity(
            Name = 'Test Opportunity', 
            CloseDate = Date.today(), 
            StageName = 'Prospecting',
            Pricebook2Id = standardPricebook.Id
        );
        insert opp1;

        Quote quote1 = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp1.Id,
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
            Bank__c = bank1.Id,
            Pricebook2Id = standardPricebook.Id
        );
        insert quote1;

        QuoteLineItem qli1 = new QuoteLineItem(
            QuoteId = quote1.Id, 
            Quantity = 2, 
            UnitPrice = 100, 
            PricebookEntryId = pbe.Id,
            Product2Id = prod.Id
        );
        insert qli1;

        Test.setCurrentPage(Page.QuotationPdf);
        ApexPages.currentPage().getParameters().put('id', quote1.Id);

        QuotationPdfController controller1 = new QuotationPdfController();
        controller1.buildEmailContent();

        Bank__c bank2 = new Bank__c(Name = 'Test Bank 2', Bank_Account_No__c = '654321', Branch__c = 'BranchX', SWIFT_Code__c = 'SWFT999');
        insert bank2;

        Opportunity opp2 = new Opportunity(
            Name = 'Test Opp 2', 
            CloseDate = Date.today(), 
            StageName = 'Qualification',
            Pricebook2Id = standardPricebook.Id
        );
        insert opp2;

        Quote quote2 = new Quote(
            Name = 'Quote Two',
            OpportunityId = opp2.Id,
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
            Bank__c = bank2.Id,
            Pricebook2Id = standardPricebook.Id
        );
        insert quote2;

        QuoteLineItem qli2 = new QuoteLineItem(
            QuoteId = quote2.Id, 
            Quantity = 1, 
            UnitPrice = 200, 
            PricebookEntryId = pbe.Id,
            Product2Id = prod.Id
        );
        insert qli2;

        QuotationPdfController controller2 = new QuotationPdfController(quote2.Id, 'quotation');
        controller2.buildEmailContent();

        String emailBody = QuotationPdfController.getEmailBody(quote2.Id, 'quotation');
    }
}