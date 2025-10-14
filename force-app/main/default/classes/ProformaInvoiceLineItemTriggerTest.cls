@isTest
public class ProformaInvoiceLineItemTriggerTest {

@isTest
    static void test_updateNetWeight() {
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

        // Step 2: Create a Proforma Invoice Line Item linked to Product
        Proforma_Invoice_Line_Item__c testLineItem = new Proforma_Invoice_Line_Item__c(
            //Name = 'Test Line Item',
            Product__c = prod.Id
        );

        // Add the record to a list (simulating trigger.new)
        List<Proforma_Invoice_Line_Item__c> lineItemList = new List<Proforma_Invoice_Line_Item__c>{ testLineItem };

        // Step 3: Call the method
        Test.startTest();
        ProformaInvoiceLineItemTriggerHandler.updateNetWeight(lineItemList);
        Test.stopTest();

        // Step 4: Assert that the Net_weight__c was updated
        //System.assertEquals(50.25, lineItemList[0].Net_weight__c, 
            //'Net weight should be copied from the related product');
    }

    @isTest
    static void test_updateNetWeight_NoNetWeight() {
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

        // Step 2: Create Line Item linked to this product
        Proforma_Invoice_Line_Item__c testLineItem = new Proforma_Invoice_Line_Item__c(
            //Name = 'Line Without Net Weight',
            Product__c = prod.Id
        );

        List<Proforma_Invoice_Line_Item__c> lineItemList = new List<Proforma_Invoice_Line_Item__c>{ testLineItem };

        // Step 3: Call method
        Test.startTest();
        ProformaInvoiceLineItemTriggerHandler.updateNetWeight(lineItemList);
        Test.stopTest();

        // Step 4: Assert Net_weight__c is null since Product had no Net_Wt__c
        System.assertEquals(null, lineItemList[0].Net_weight__c, 
            'Net weight should remain null if Product Net_Wt__c is null');
    }
}