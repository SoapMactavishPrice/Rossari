@isTest
public class CustomerPriceList_API_Test {
    
    @testSetup
    static void setupTestData() {
        // Get standard pricebook ID without updating (fix for UNABLE_TO_LOCK_ROW)
        Id standardPricebookId = Test.getStandardPricebookId();
        
        Account acc = new Account(Name = 'Test Account', SAP_Customer_Code__c = 'CUST001');
        insert acc;
        
        Product2 prod = new Product2(Name = 'Test Product', ProductCode = 'PROD001');
        insert prod;
        
        // Create pricebook entry for the product
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false
        );
        insert pbe;
        
        // Check if lookup records already exist to avoid duplicate inserts
        List<Sales_Organisation__c> existingSalesOrgs = [SELECT Id FROM Sales_Organisation__c WHERE Name = 'SO001'];
        List<Base_UoM_Master__c> existingUoms = [SELECT Id FROM Base_UoM_Master__c WHERE Name = 'KG'];
        List<Distribution_Channel__c> existingDistChannels = [SELECT Id FROM Distribution_Channel__c WHERE Name = 'DC001'];
        
        Sales_Organisation__c salesOrg;
        if (existingSalesOrgs.isEmpty()) {
            salesOrg = new Sales_Organisation__c(Name = 'SO001');
            insert salesOrg;
        } else {
            salesOrg = existingSalesOrgs[0];
        }
        
        Base_UoM_Master__c uom;
        if (existingUoms.isEmpty()) {
            uom = new Base_UoM_Master__c(Name = 'KG');
            insert uom;
        } else {
            uom = existingUoms[0];
        }
        
        Distribution_Channel__c distChannel;
        if (existingDistChannels.isEmpty()) {
            distChannel = new Distribution_Channel__c(Name = 'DC001');
            insert distChannel;
        } else {
            distChannel = existingDistChannels[0];
        }
        
        Customer_Material_Pricelist__c existingPrice = new Customer_Material_Pricelist__c(
            Customer__c = acc.Id,
            Material__c = prod.Id,
            Sales_Organization__c = salesOrg.Id,
            UOM__c = uom.Id,
            Distribution_Channel__c = distChannel.Id,
            Material_Price__c = 100,
            PER__c = 1,
            Valid_From__c = Date.today(),
            Valid_To__c = Date.today().addDays(30)
        );
        insert existingPrice;
    }
    
    @isTest
    static void testDoPostSuccess() {
        String jsonBody = '[{"CUSTOMER_NUMBER":"CUST001","MATERIAL":"PROD001","MATERIAL_PRICE":"150.50","SALES_ORGANIZATION":"SO001","UOM":"KG","DISTRIBUTION_CHANNEL":"DC001","PER":"2","VALID_FROM":"2024-01-01","VALID_TO":"2024-12-31"}]';
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestBody = Blob.valueOf(jsonBody);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        CustomerPriceList_API.doPost();
        Test.stopTest();
        
    }
    
    @isTest
    static void testDoPostBlankCustomerNumber() {
        String jsonBody = '[{"CUSTOMER_NUMBER":"","MATERIAL":"PROD001","MATERIAL_PRICE":"150.50"}]';
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestBody = Blob.valueOf(jsonBody);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        CustomerPriceList_API.doPost();
        Test.stopTest();
        
    }
    
    @isTest
    static void testDoPostBlankMaterial() {
        String jsonBody = '[{"CUSTOMER_NUMBER":"CUST001","MATERIAL":"","MATERIAL_PRICE":"150.50"}]';
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestBody = Blob.valueOf(jsonBody);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        CustomerPriceList_API.doPost();
        Test.stopTest();
        
    }
    
    @isTest
    static void testDoPostNewRecord() {
        String jsonBody = '[{"CUSTOMER_NUMBER":"CUST001","MATERIAL":"PROD001","MATERIAL_PRICE":"200.75","SALES_ORGANIZATION":"SO001","UOM":"KG","DISTRIBUTION_CHANNEL":"DC001","PER":"3","VALID_FROM":"2024-01-01","VALID_TO":"2024-12-31"}]';
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestBody = Blob.valueOf(jsonBody);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        CustomerPriceList_API.doPost();
        Test.stopTest();
        
    }
    
    @isTest
    static void testDoPostMultipleRecords() {
        String jsonBody = '[{"CUSTOMER_NUMBER":"CUST001","MATERIAL":"PROD001","MATERIAL_PRICE":"150.50","SALES_ORGANIZATION":"SO001","UOM":"KG","DISTRIBUTION_CHANNEL":"DC001","PER":"2","VALID_FROM":"2024-01-01","VALID_TO":"2024-12-31"},{"CUSTOMER_NUMBER":"CUST001","MATERIAL":"PROD001","MATERIAL_PRICE":"250.75","SALES_ORGANIZATION":"SO001","UOM":"KG","DISTRIBUTION_CHANNEL":"DC001","PER":"3","VALID_FROM":"2024-02-01","VALID_TO":"2024-12-31"}]';
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestBody = Blob.valueOf(jsonBody);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        CustomerPriceList_API.doPost();
        Test.stopTest();
        
    }
    
    @isTest
    static void testDoPostInvalidDate() {
        String jsonBody = '[{"CUSTOMER_NUMBER":"CUST001","MATERIAL":"PROD001","MATERIAL_PRICE":"150.50","SALES_ORGANIZATION":"SO001","UOM":"KG","DISTRIBUTION_CHANNEL":"DC001","PER":"2","VALID_FROM":"invalid-date","VALID_TO":"2024-12-31"}]';
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestBody = Blob.valueOf(jsonBody);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        CustomerPriceList_API.doPost();
        Test.stopTest();
        
    }
    
    @isTest
    static void testDoPostValidTo9999() {
        String jsonBody = '[{"CUSTOMER_NUMBER":"CUST001","MATERIAL":"PROD001","MATERIAL_PRICE":"150.50","SALES_ORGANIZATION":"SO001","UOM":"KG","DISTRIBUTION_CHANNEL":"DC001","PER":"2","VALID_FROM":"2024-01-01","VALID_TO":"9999-12-31"}]';
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestBody = Blob.valueOf(jsonBody);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        CustomerPriceList_API.doPost();
        Test.stopTest();
        
    }
    
    @isTest
    static void testDoPostWithSpacesInPrice() {
        String jsonBody = '[{"CUSTOMER_NUMBER":"CUST001","MATERIAL":"PROD001","MATERIAL_PRICE":"  150.50  ","SALES_ORGANIZATION":"SO001","UOM":"KG","DISTRIBUTION_CHANNEL":"DC001","PER":"  2  ","VALID_FROM":"2024-01-01","VALID_TO":"2024-12-31"}]';
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestBody = Blob.valueOf(jsonBody);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        CustomerPriceList_API.doPost();
        Test.stopTest();
        
    }
    
    @isTest
    static void testParseMethod() {
        String json = '[{"CUSTOMER_NUMBER":"CUST001","MATERIAL":"PROD001","MATERIAL_PRICE":"150.50"}]';
        
        Test.startTest();
        List<CustomerPriceList_API.JSON2ApexSaveWebToLead> result = CustomerPriceList_API.parse(json);
        Test.stopTest();
        
       
    }
    
    @isTest
    static void testDoPostWithNonExistingProduct() {
        String jsonBody = '[{"CUSTOMER_NUMBER":"CUST001","MATERIAL":"NONEXISTENT","MATERIAL_PRICE":"150.50","SALES_ORGANIZATION":"SO001","UOM":"KG","DISTRIBUTION_CHANNEL":"DC001","PER":"2","VALID_FROM":"2024-01-01","VALID_TO":"2024-12-31"}]';
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestBody = Blob.valueOf(jsonBody);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        CustomerPriceList_API.doPost();
        Test.stopTest();
        
    }
}