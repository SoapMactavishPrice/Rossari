@isTest
public class ProformaInvoicePdfControllerTest {

    @isTest
    static void testAllMethods() {
        Id standardPbId = Test.getStandardPricebookId();
        Pricebook2 stdPb = new Pricebook2(Id = standardPbId, IsActive = true);
        update stdPb;

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Bank__c bank = new Bank__c(Name = 'Test Bank', Bank_Account_No__c = '123456', Branch__c = 'Main', SWIFT_Code__c = 'SWFT123');
        insert bank;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            CloseDate = Date.today(),
            StageName = 'Prospecting',
            AccountId = acc.Id
        );
        insert opp;

        Quote quote = new Quote(Name = 'Test Quote', OpportunityId = opp.Id);
        insert quote;

        // HSN Master record
        HSN_Master__c hsn = new HSN_Master__c(Name = 'HSN 123');
        insert hsn;

        // Product with HSN Code lookup
        Product2 prod = new Product2(
            Name = 'Prod A',
            ProductCode = 'PA001',
            IsActive = true,
            HSN_Code__c = hsn.Id,
            Pack_Size__c = '10kg'
          //  Base_UOM__c = 'KG'
        );
        insert prod;

        PricebookEntry pbe = new PricebookEntry(
            Product2Id = prod.Id,
            Pricebook2Id = standardPbId,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        Proforma_Invoice__c pi = new Proforma_Invoice__c(
            Quote__c = quote.Id,
            Name = 'PI-001',
            Account_Name__c = acc.Id,
            Payment_Terms__c = 'Advance',
            Inco_Terms__c = 'FOB',
            Pre_Carriage_Mode__c = 'Sea',
            Country_of_Origin__c = 'India',
            Country_of_Destination__c = 'USA',
            Vessel_Flight_No__c = 'V123',
            Pre_Carriage_Destination__c = 'Mumbai',
            Destination__c = 'New York',
            Loading_Port__c = 'Mumbai',
            Destination_Port__c = 'NY Port',
            Place_of_Supplier__c = 'India Office',
            Partial_Shipment__c = 'Yes',
            Bill_To_Name__c = 'Bill Name',
            Bill_To_Street__c = '123 Bill St',
            Bill_To_City__c = 'Bill City',
            Bill_To_State__c = 'Bill State',
            Bill_To_Zip_Postal_Code__c = '12345',
            Bill_To_Country__c = 'India',
            Ship_To_Name__c = 'Ship Name',
            Ship_To_Street__c = '456 Ship St',
            Ship_To_City__c = 'Ship City',
            Ship_To_State__c = 'Ship State',
            Ship_To_Zip_Postal_Code__c = '67890',
            Ship_To_Country__c = 'USA',
            CurrencyIsoCode = 'INR',
            Grand_Total__c = 10000,
            Bank__c = bank.Id,
            Terms_and_Conditions__c = 'Standard terms',
            Declaration__c = 'Test declaration'
        );
        insert pi;

        Proforma_Invoice_Line_Item__c li = new Proforma_Invoice_Line_Item__c(
            Proforma_Invoice_Name__c = pi.Id,
            Product__c = prod.Id,
            Line_Item_Description__c = 'Item Desc',
            Quantity__c = 10,
            Sales_Price__c = 100,
            List_Price__c = 120,
            Total_Price__c = 1000
        );
        insert li;

        Test.setCurrentPage(Page.ProformaInvoicePdf);
        ApexPages.currentPage().getParameters().put('id', pi.Id);

        // Test default constructor
        ProformaInvoicePdfController controller1 = new ProformaInvoicePdfController();
        String billingAddress = controller1.getFormattedBillingAddress(pi);
        String shippingAddress = controller1.getFormattedShippingAddress(pi);
        String emailContent1 = controller1.buildEmailContent();

        // Test constructor with parameters
        ProformaInvoicePdfController controller2 = new ProformaInvoicePdfController(pi.Id, 'invoice');
        String emailContent2 = controller2.buildEmailContent();

        // Static method test
        String emailBody = ProformaInvoicePdfController.getEmailBody(pi.Id, 'invoice');

        // Additional test with clone
        Proforma_Invoice__c pi2 = pi.clone(false, false, false, false);
        pi2.Name = 'PI-002';
        insert pi2;

        ProformaInvoicePdfController controller3 = new ProformaInvoicePdfController(pi2.Id, 'quotation');
        String emailContent3 = controller3.buildEmailContent();

        // USD currency test
        Proforma_Invoice__c pi3 = pi.clone(false, false, false, false);
        pi3.Name = 'PI-003';
        pi3.CurrencyIsoCode = 'USD';
        insert pi3;

        ProformaInvoicePdfController controller4 = new ProformaInvoicePdfController(pi3.Id, 'invoice');
        String emailContent4 = controller4.buildEmailContent();
    }
}