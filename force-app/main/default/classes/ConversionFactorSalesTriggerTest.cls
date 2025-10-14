@IsTest
    public class ConversionFactorSalesTriggerTest {

    @TestSetup
    static void setupTestData() {
        // Activate Standard Pricebook
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

        // Create Base UoM
         Base_UoM_Master__c baseUom1 = new Base_UoM_Master__c(Name = 'PCS');
        Base_UoM_Master__c baseUom2 = new Base_UoM_Master__c(Name = 'KG');
        insert new List<Base_UoM_Master__c>{baseUom1, baseUom2};

        // Create Product
        Product2 prod = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP001',
            Pack_Size__c = '10kg',
            Base_UOM__c = baseUom2.Id,
            IsActive = true
        );
        insert prod;

        // Create Pricebook Entry
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;
    }

    @IsTest
    static void testInsertUniqueConversionFactor() {
        // Get Product for Item Master
        Product2 prod = [SELECT Id FROM Product2 WHERE Name='Test Product' LIMIT 1];
        
        Base_UoM_Master__c baseUom1 = [SELECT Id FROM Base_UoM_Master__c WHERE Name='PCS' LIMIT 1];
        Base_UoM_Master__c baseUom2 = [SELECT Id FROM Base_UoM_Master__c WHERE Name='KG' LIMIT 1];

        // Insert unique Conversion Factor
        Conversion_factor_for_Sales__c conv1 = new Conversion_factor_for_Sales__c(
            Item_Master__c = prod.Id,
            Alt_Quantity__c = 10,
            Alt_UOM__c = baseUom1.Id,
            Base_Qty__c = 1,
            Base_UOM__c = baseUom2.Id
        );

        Test.startTest();
        insert conv1;
        Test.stopTest();

        // Verify record inserted
        Conversion_factor_for_Sales__c insertedRec = [SELECT Id, Item_Master__c FROM Conversion_factor_for_Sales__c WHERE Id=:conv1.Id];
        System.assertNotEquals(null, insertedRec, 'Conversion Factor record should be inserted successfully.');
    }

    @IsTest
    static void testInsertDuplicateConversionFactor() {
        // Get Product for Item Master
        Product2 prod = [SELECT Id FROM Product2 WHERE Name='Test Product' LIMIT 1];
        
         Base_UoM_Master__c baseUom1 = [SELECT Id FROM Base_UoM_Master__c WHERE Name='PCS' LIMIT 1];
        Base_UoM_Master__c baseUom2 = [SELECT Id FROM Base_UoM_Master__c WHERE Name='KG' LIMIT 1];

        // Insert initial Conversion Factor
        Conversion_factor_for_Sales__c conv1 = new Conversion_factor_for_Sales__c(
            Item_Master__c = prod.Id,
            Alt_Quantity__c = 10,
            Alt_UOM__c = baseUom1.Id,
            Base_Qty__c = 1,
            Base_UOM__c = baseUom2.Id
        );
        insert conv1;

        // Try inserting duplicate
        Conversion_factor_for_Sales__c convDuplicate = new Conversion_factor_for_Sales__c(
            Item_Master__c = prod.Id,
            Alt_Quantity__c = 10,
            Alt_UOM__c = baseUom1.Id,
            Base_Qty__c = 1,
            Base_UOM__c =  baseUom2.Id
        );

        Test.startTest();
        try {
            insert convDuplicate;
            System.assert(false, 'Expected duplicate record to throw an error');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Duplicate record found'), 'Duplicate error message should be thrown.');
        }
        Test.stopTest();
    }

    @IsTest
    static void testInsertMultipleRecordsWithInternalDuplicates() {
        // Get Product for Item Master
        Product2 prod = [SELECT Id FROM Product2 WHERE Name='Test Product' LIMIT 1];
        
        Base_UoM_Master__c baseUom1 = [SELECT Id FROM Base_UoM_Master__c WHERE Name='PCS' LIMIT 1];
        Base_UoM_Master__c baseUom2 = [SELECT Id FROM Base_UoM_Master__c WHERE Name='KG' LIMIT 1];

        // Prepare multiple records, including internal duplicates
        List<Conversion_factor_for_Sales__c> records = new List<Conversion_factor_for_Sales__c>();

        records.add(new Conversion_factor_for_Sales__c(
            Item_Master__c = prod.Id,
            Alt_Quantity__c = 5,
            Alt_UOM__c = baseUom1.Id,
            Base_Qty__c = 1,
            Base_UOM__c = baseUom2.Id
        ));

        records.add(new Conversion_factor_for_Sales__c(
            Item_Master__c = prod.Id,
            Alt_Quantity__c = 5,
            Alt_UOM__c = baseUom1.Id,
            Base_Qty__c = 1,
            Base_UOM__c = baseUom2.Id
        )); // duplicate in same insert

        Test.startTest();
        try {
            insert records;
            System.assert(false, 'Expected duplicate record within same transaction to throw error');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Duplicate record found'), 'Duplicate error message should be thrown for internal duplicates.');
        }
        Test.stopTest();
    }
}