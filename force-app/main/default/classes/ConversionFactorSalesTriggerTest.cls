@IsTest
public class ConversionFactorSalesTriggerTest {

    @TestSetup
    static void setupTestData() {
        List<SObject> recordsToInsert = new List<SObject>();
        
        recordsToInsert.add(new Base_UoM_Master__c(Name = 'PCS'));
        recordsToInsert.add(new Base_UoM_Master__c(Name = 'KG'));
        
        insert recordsToInsert;
        recordsToInsert.clear();

        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        try{
        update standardPricebook;
        }Catch(Exception e){}
    
        Base_UoM_Master__c baseUom = new Base_UoM_Master__c(Name = 'Kilogram');
        recordsToInsert.add(baseUom);
        
        insert recordsToInsert;
        recordsToInsert.clear();
 
        Product2 prod = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP001',
            Pack_Size__c = '10kg',
            Base_UOM__c = baseUom.Id,
            IsActive = true
        );
        recordsToInsert.add(prod);
        
        insert recordsToInsert;
        recordsToInsert.clear();
 
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        recordsToInsert.add(pbe);
        
        insert recordsToInsert;
    }

    @IsTest
    static void testConversionFactorInsertions() {
        Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Test Product' LIMIT 1];
        Base_UoM_Master__c baseUomPCS = [SELECT Id FROM Base_UoM_Master__c WHERE Name = 'PCS' LIMIT 1];
        Base_UoM_Master__c baseUomKG = [SELECT Id FROM Base_UoM_Master__c WHERE Name = 'KG' LIMIT 1];

        Conversion_factor_for_Sales__c unique = new Conversion_factor_for_Sales__c(
            Item_Master__c = prod.Id,
            Alt_Quantity__c = 10,
            Alt_UOM__c = baseUomPCS.Id,
            Base_Qty__c = 1,
            Base_UOM__c = baseUomKG.Id
        );
        insert unique;

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