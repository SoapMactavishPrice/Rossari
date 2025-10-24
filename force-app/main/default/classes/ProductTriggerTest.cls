@isTest
public class ProductTriggerTest {

    @isTest
    static void testProductTrigger_AllScenarios() {

        Id standardPBId = Test.getStandardPricebookId();

       Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        try{
        update standardPricebook;
        }Catch(Exception e){}
    
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
		
        Test.startTest();
        prod2.Create_PricebookEntry__c = true;
        update prod2;
        Test.stopTest();

        List<PricebookEntry> pbes2 = [
            SELECT Id, Product2Id 
            FROM PricebookEntry 
            WHERE Product2Id = :prod2.Id
        ];

        prod.Name = 'Updated Product';
        update prod;
    }
}