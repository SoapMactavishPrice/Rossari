@isTest
public class ProductTriggerTest {

    @isTest
    static void testProductTrigger_AllScenarios() {

        Pricebook2 standardPB = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPB;

        Product2 prod1 = new Product2(
            Name = 'Test Product 1',
            ProductCode = 'TP001',
            Family = 'Electronics',
            IsActive = true,
            Create_PricebookEntry__c = true
        );

        Test.startTest();
        insert prod1;

        List<PricebookEntry> pbes = [
            SELECT Id, Product2Id, Pricebook2Id, UnitPrice, IsActive 
            FROM PricebookEntry 
            WHERE Product2Id = :prod1.Id
        ];
        System.assert(!pbes.isEmpty(), 'PricebookEntry should be auto-created for product.');
        System.assertEquals(standardPB.Id, pbes[0].Pricebook2Id, 'PricebookEntry should belong to Standard Pricebook.');

        Product2 duplicateProd = new Product2(
            Name = 'Duplicate Product',
            ProductCode = 'TP001',
            Family = 'Electronics',
            IsActive = true
        );

        try {
            insert duplicateProd;
            System.assert(false, 'Expected duplicate ProductCode error not thrown.');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Duplicate Item Number not allowed'), 
                'Duplicate error should be triggered for same ProductCode.');
        }

        Product2 prod2 = new Product2(
            Name = 'Test Product 2',
            ProductCode = 'TP002',
            Family = 'Hardware',
            IsActive = true,
            Create_PricebookEntry__c = false
        );
        insert prod2;

        prod2.Create_PricebookEntry__c = true;

        update prod2;
        Test.stopTest();

        List<PricebookEntry> pbes2 = [
            SELECT Id, Product2Id 
            FROM PricebookEntry 
            WHERE Product2Id = :prod2.Id
        ];
        System.assert(!pbes2.isEmpty(), 'PricebookEntries should be created on update when flag changes.');

        prod1.Name = 'Updated Product';
        update prod1;

    }
}