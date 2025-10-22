@IsTest
public class ConversionFactorSalesTriggerTest {

    @TestSetup
    static void setupTestData() {
        // Create Base UoMs
        insert new List<Base_UoM_Master__c>{
            new Base_UoM_Master__c(Name = 'PCS'),
            new Base_UoM_Master__c(Name = 'KG')
        };

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
    }

    @IsTest
    static void testConversionFactorInsertions() {
        Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Test Product' LIMIT 1];
        Base_UoM_Master__c baseUomPCS = [SELECT Id FROM Base_UoM_Master__c WHERE Name = 'PCS' LIMIT 1];
        Base_UoM_Master__c baseUomKG = [SELECT Id FROM Base_UoM_Master__c WHERE Name = 'KG' LIMIT 1];

        // ✅ Unique record
        Conversion_factor_for_Sales__c unique = new Conversion_factor_for_Sales__c(
            Item_Master__c = prod.Id,
            Alt_Quantity__c = 10,
            Alt_UOM__c = baseUomPCS.Id,
            Base_Qty__c = 1,
            Base_UOM__c = baseUomKG.Id
        );
        insert unique;

        // ✅ Duplicate record (existing)
        Conversion_factor_for_Sales__c duplicate = new Conversion_factor_for_Sales__c(
            Item_Master__c = prod.Id,
            Alt_Quantity__c = 10,
            Alt_UOM__c = baseUomPCS.Id,
            Base_Qty__c = 1,
            Base_UOM__c = baseUomKG.Id
        );
        try {
            insert duplicate;
        } catch (DmlException e) {}

        // ✅ Internal duplicates in same transaction
        List<Conversion_factor_for_Sales__c> batch = new List<Conversion_factor_for_Sales__c>{
            new Conversion_factor_for_Sales__c(
                Item_Master__c = prod.Id,
                Alt_Quantity__c = 5,
                Alt_UOM__c = baseUomPCS.Id,
                Base_Qty__c = 1,
                Base_UOM__c = baseUomKG.Id
            ),
            new Conversion_factor_for_Sales__c(
                Item_Master__c = prod.Id,
                Alt_Quantity__c = 5,
                Alt_UOM__c = baseUomPCS.Id,
                Base_Qty__c = 1,
                Base_UOM__c = baseUomKG.Id
            )
        };
        try {
            insert batch;
        } catch (DmlException e) {}
    }
}