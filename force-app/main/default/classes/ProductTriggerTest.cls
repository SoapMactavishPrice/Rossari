@isTest
public class ProductTriggerTest {

    @isTest
    static void testProductTrigger_AllScenarios() {

        Id standardPBId = Test.getStandardPricebookId();

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

        Product2 duplicateProd = new Product2(
            Name = 'Duplicate Product',
            ProductCode = 'TP001',
            Family = 'Electronics',
            IsActive = true
        );

        try {
            insert duplicateProd;
        } catch (DmlException e) {}

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

        prod1.Name = 'Updated Product';
        update prod1;
    }
}