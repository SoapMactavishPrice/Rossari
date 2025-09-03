@isTest
public class ProformaInvoicePdfControllerTest {

    @isTest
    static void testDefaultConstructor() {
        Id standardPbId = Test.getStandardPricebookId();
        Pricebook2 stdPb = new Pricebook2(Id = standardPbId, IsActive = true);
        update stdPb;

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Bank__c bank = new Bank__c(Name = 'Test Bank', Bank_Account_No__c = '123456', Branch__c = 'Main', SWIFT_Code__c = 'SWFT123');
        insert bank;

        Opportunity opp = new Opportunity(Name = 'Test Opp', CloseDate = Date.today(), StageName = 'Prospecting', AccountId = acc.Id);
        insert opp;

        Quote quote = new Quote(Name = 'Test Quote', OpportunityId = opp.Id);
        insert quote;

        Proforma_Invoice__c pi = new Proforma_Invoice__c(
            Quote__c = quote.Id,
            Name = 'PI-001',
            Account_Name__c = acc.Id,
            Payment_Terms__c = 'Advance',
            Inco_Terms__c = 'FOB',
            Pre_Carriage_Mode__c = 'Sea',
            Country_of_Origin__c = 'India',
            Country_of_Destination__c = 'USA',
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

        Product2 prod = new Product2(Name = 'Prod A', ProductCode = 'PA001', IsActive = true);
        insert prod;

        PricebookEntry pbe = new PricebookEntry(Product2Id = prod.Id, Pricebook2Id = standardPbId, UnitPrice = 100, IsActive = true);
        insert pbe;

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

        ProformaInvoicePdfController controller = new ProformaInvoicePdfController();
     //   controller.buildEmailContent();
    }

    @isTest
    static void testParamConstructorAndEmailBody() {
        Id standardPbId = Test.getStandardPricebookId();
        Pricebook2 stdPb = new Pricebook2(Id = standardPbId, IsActive = true);
        update stdPb;

        Account acc = new Account(Name = 'Test Account 2');
        insert acc;

        Bank__c bank = new Bank__c(Name = 'Test Bank 2', Bank_Account_No__c = '654321', Branch__c = 'BranchX', SWIFT_Code__c = 'SWFT999');
        insert bank;

        Opportunity opp = new Opportunity(Name = 'Test Opp 2', CloseDate = Date.today(), StageName = 'Qualification', AccountId = acc.Id);
        insert opp;

        Quote quote = new Quote(Name = 'Test Quote 2', OpportunityId = opp.Id);
        insert quote;

        Proforma_Invoice__c pi = new Proforma_Invoice__c(
            Quote__c = quote.Id,
            Name = 'PI-002',
            Account_Name__c = acc.Id,
            Payment_Terms__c = 'Advance',
            Inco_Terms__c = 'CIF',
            Destination__c = 'California',
            CurrencyIsoCode = 'USD',
            Grand_Total__c = 5000,
            Bank__c = bank.Id,
            Terms_and_Conditions__c = 'Terms 2',
            Declaration__c = 'Declaration 2'
        );
        insert pi;

        Product2 prod = new Product2(Name = 'Prod B', ProductCode = 'PB002', IsActive = true);
        insert prod;

        PricebookEntry pbe = new PricebookEntry(Product2Id = prod.Id, Pricebook2Id = standardPbId, UnitPrice = 200, IsActive = true);
        insert pbe;

        Proforma_Invoice_Line_Item__c li = new Proforma_Invoice_Line_Item__c(
            Proforma_Invoice_Name__c = pi.Id,
            Product__c = prod.Id,
            Line_Item_Description__c = 'Item Desc 2',
            Quantity__c = 5,
            Sales_Price__c = 200,
            List_Price__c = 220,
            Total_Price__c = 1000
        );
        insert li;

    //    ProformaInvoicePdfController controller = new ProformaInvoicePdfController(pi.Id, 'invoice');
     //   controller.buildEmailContent();

      //  String body = ProformaInvoicePdfController.getEmailBody(pi.Id, 'invoice');
    }
}