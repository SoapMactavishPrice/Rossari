@isTest
public class addProductIntrestedTest {
    
    @testSetup
    static void setupData() {
        //  Insert required Account record that LeadTrigger depends on
        Account acc = new Account(Name = 'Rossari Chemicals Ltd.');
        insert acc;
        
        Company__c rossari = new Company__c(
            Name = 'Rossari Biotech Limited'
        );
        insert rossari;
        
        //  Insert test Lead (AFTER inserting the Account above)
        Lead testLead = new Lead(
            FirstName ='Prince',
            LastName = 'TestLead',
            MobilePhone = '1928374650',
            Company = 'Rossari Chemicals Ltd.', 
            Status = 'Open - Not Contacted'
        );
        insert testLead;
        
        //  Insert test Product2
         Product2 prod = new Product2(Name = 'Test Product');
        insert prod;
        
        //  Ensure Standard Pricebook is Active
        Id stdPricebookId = Test.getStandardPricebookId();
        
        Pricebook2 standardpricebook = new Pricebook2(
            Name = 'Test Pricebook 2',
            IsActive = true
        );
        insert standardpricebook ;
        
        if (!standardpricebook.IsActive) {
            standardpricebook.IsActive = true;
            update standardpricebook;
        }
        
        //  Insert PricebookEntry
        PricebookEntry pbe = new PricebookEntry(
            Product2Id = prod.Id,
            Pricebook2Id = stdPricebookId,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;
        
        Product_Interested__c pi = new Product_Interested__c(
            Lead__c = testLead.Id, // Ensure this is a valid Lead record
            Product__c = prod.Id, // Ensure this is a valid Product2 record
            New_Product_Name__c = 'New Product',
            New_Product__c = true,
            List_Price__c = 100,
            Quantity_in_Kgs__c = 10,
            Expected_Price__c = 95,
            Add_in_Opportunity__c = true,
            Quantity_Frequency__c = 'Per/Month'
        );
        insert pi;
        
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
        
        Test.startTest();
        Map<String, String> result = addProductIntrested.saveProductInterested(testLead.Id, jsonInput);
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
                'price' => null, // Null price
                'pbeId' => pbe.Id,
                'unitPrice' => pbe.UnitPrice,
                'prodFamily' => prod.Family,
                'Add_In_Opty' => true,
                'New_Product_Name' => 'Null Price Product',
                'New_Product' => true,
                'frequency' => 'Monthly'
                });
        
        String jsonInput = JSON.serialize(inputList);
        
        Test.startTest();
        Map<String, String> result = addProductIntrested.saveProductInterested(testLead.Id, jsonInput);
        Test.stopTest();
        
    }
}