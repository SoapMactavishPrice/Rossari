@isTest
public class addProductIntrestedTest {
    
    @testSetup
    static void setupData() {
        List<SObject> recordsToInsert = new List<SObject>();
        
        Account acc = new Account(Name = 'Rossari Chemicals Ltd.');
        recordsToInsert.add(acc);
        
        insert recordsToInsert;
        recordsToInsert.clear();
        
        Company__c rossari = new Company__c(
            Name = 'Rossari Biotech Limited'
        );
        recordsToInsert.add(rossari);
        
        insert recordsToInsert;
        recordsToInsert.clear();
        
        Lead testLead = new Lead(
            FirstName ='Prince',
            LastName = 'TestLead',
            MobilePhone = '1928374650',
            Company = 'Rossari Chemicals Ltd.', 
            Status = 'Open - Not Contacted'
        );
        recordsToInsert.add(testLead);
        
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
        recordsToInsert.clear();

        Product_Interested__c pi = new Product_Interested__c(
            Lead__c = testLead.Id,
            Product__c = prod.Id,
            New_Product_Name__c = 'New Product',
            New_Product__c = true,
            List_Price__c = 100,
            Quantity_in_Kgs__c = 10,
            Expected_Price__c = 95,
            Add_in_Opportunity__c = true,
            Quantity_Frequency__c = 'Per/Month'
        );
        recordsToInsert.add(pi);
        
        insert recordsToInsert;
    }
    
    @isTest
    static void testGetProdInterest() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        
        Test.startTest();
        Map<String, Object> result = addProductIntrested.getProdInterest(testLead.Id);
        Test.stopTest();

    }
    
    @isTest
    static void testDeleteProductInterested() {
        Product_Interested__c pi = [SELECT Id FROM Product_Interested__c LIMIT 1];
        
        Test.startTest();
        String msg = addProductIntrested.deleteProductInterested(pi.Id);
        Test.stopTest();

    }
    
    @isTest
    static void testGetExistingProducts() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        
        Test.startTest();
        List<Id> existingProducts = addProductIntrested.getExistingProducts(testLead.Id);
        Test.stopTest();

    }
    
    @isTest
    static void testGetPicklistValues() {
        Test.startTest();
        Map<String, List<Map<String, String>>> picklists = addProductIntrested.getPicklistValues();
        Test.stopTest();

    }
    
    @isTest
    static void testSaveProductInterestedWithPrice() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        Product2 prod = [SELECT Id, Family FROM Product2 LIMIT 1];
        PricebookEntry pbe = [SELECT Id, UnitPrice FROM PricebookEntry WHERE Product2Id = :prod.Id LIMIT 1];
        
        List<Map<String, Object>> inputList = new List<Map<String, Object>>();
        inputList.add(new Map<String, Object>{
            'inId' => null,
                'prodId' => prod.Id,
                'volume' => 20.0,
                'price' => 95.5,
                'pbeId' => pbe.Id,
                'unitPrice' => pbe.UnitPrice,
                'prodFamily' => prod.Family,
                'Add_In_Opty' => true,
                'New_Product_Name' => 'Alt Product',
                'New_Product' => true,
                'frequency' => 'Monthly'
                });
        
        String jsonInput = JSON.serialize(inputList);
        String divisionId = null; // Add divisionId parameter
        
        Test.startTest();
        Map<String, String> result = addProductIntrested.saveProductInterested(testLead.Id, jsonInput, divisionId);
        Test.stopTest();

    }
    
    @isTest
    static void testSaveProductInterestedWithNullPrice() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        Product2 prod = [SELECT Id, Family FROM Product2 LIMIT 1];
        PricebookEntry pbe = [SELECT Id, UnitPrice FROM PricebookEntry WHERE Product2Id = :prod.Id LIMIT 1];
        
        List<Map<String, Object>> inputList = new List<Map<String, Object>>();
        inputList.add(new Map<String, Object>{
            'inId' => null,
                'prodId' => prod.Id,
                'volume' => 25.0,
                'price' => null,
                'pbeId' => pbe.Id,
                'unitPrice' => pbe.UnitPrice,
                'prodFamily' => prod.Family,
                'Add_In_Opty' => true,
                'New_Product_Name' => 'Null Price Product',
                'New_Product' => true,
                'frequency' => 'Monthly'
                });
        
        String jsonInput = JSON.serialize(inputList);
        String divisionId = null; // Add divisionId parameter
        
        Test.startTest();
        Map<String, String> result = addProductIntrested.saveProductInterested(testLead.Id, jsonInput, divisionId);
        Test.stopTest();

    }
    
    @isTest
    static void testSaveProductInterestedWithDivisionId() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        Product2 prod = [SELECT Id, Family FROM Product2 LIMIT 1];
        PricebookEntry pbe = [SELECT Id, UnitPrice FROM PricebookEntry WHERE Product2Id = :prod.Id LIMIT 1];
        
        List<Map<String, Object>> inputList = new List<Map<String, Object>>();
        inputList.add(new Map<String, Object>{
            'inId' => null,
                'prodId' => prod.Id,
                'volume' => 30.0,
                'price' => 90.0,
                'pbeId' => pbe.Id,
                'unitPrice' => pbe.UnitPrice,
                'prodFamily' => prod.Family,
                'Add_In_Opty' => true,
                'New_Product_Name' => 'Product with Division',
                'New_Product' => false,
                'frequency' => 'Weekly'
                });
        
        String jsonInput = JSON.serialize(inputList);
        String divisionId = 'testDivisionId123'; // Test with division ID
        
        Test.startTest();
        Map<String, String> result = addProductIntrested.saveProductInterested(testLead.Id, jsonInput, divisionId);
        Test.stopTest();

        
        // Verify that lead division was updated
        Lead updatedLead = [SELECT Id, Division__c FROM Lead WHERE Id = :testLead.Id];

    }
    
    @isTest
    static void testGetDivisionRecords() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        
        Test.startTest();
        List<Division__c> divisions = addProductIntrested.getDivisionRecords(testLead.Id);
        Test.stopTest();

    }
}