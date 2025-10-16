@IsTest
private class SalesAreaTriggerTest {

    @IsTest
    static void testSalesAreaTrigger_Coverage() {

        Id standardPricebookId = Test.getStandardPricebookId();

        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert testProduct;

        PricebookEntry standardPBE = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = testProduct.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert standardPBE;

        Distribution_Channel__c dist = new Distribution_Channel__c(Name = 'Distribution A');
        insert dist;

        Plant__c plant = new Plant__c(Name = 'Plant A');
        insert plant;

        Sales_Organisation__c salesOrg = new Sales_Organisation__c(Name = 'Sales Org A');
        insert salesOrg;

        Sales_Area__c sa1 = new Sales_Area__c(
            Distribution_Channel__c = dist.Id,
            Item_Master__c = testProduct.Id,
            Plant_Code__c = plant.Id,
            Sales_Organisation__c = salesOrg.Id
        );
        insert sa1;

        Sales_Area__c saDuplicate = new Sales_Area__c(
            Distribution_Channel__c = dist.Id,
            Item_Master__c = testProduct.Id,
            Plant_Code__c = plant.Id,
            Sales_Organisation__c = salesOrg.Id
        );
        try {
            insert saDuplicate;
        } catch (DmlException e) {}

        Sales_Area__c sa2 = new Sales_Area__c(
            Distribution_Channel__c = dist.Id,
            Item_Master__c = testProduct.Id,
            Plant_Code__c = plant.Id,
            Sales_Organisation__c = salesOrg.Id
        );

        Sales_Area__c sa3 = new Sales_Area__c(
            Distribution_Channel__c = dist.Id,
            Item_Master__c = testProduct.Id,
            Plant_Code__c = plant.Id,
            Sales_Organisation__c = salesOrg.Id
        );

        try {
            insert new List<Sales_Area__c>{ sa2, sa3 };
        } catch (DmlException e) {}
    }
}