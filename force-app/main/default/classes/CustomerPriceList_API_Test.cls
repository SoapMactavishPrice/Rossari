@isTest
public class CustomerPriceList_API_Test {
    
    @testSetup
    static void setupTestData() {
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        
        Account acc = new Account(Name = 'Test Account', SAP_Customer_Code__c = 'CUST001');
        insert acc;
        
        Product2 prod = new Product2(Name = 'Test Product', ProductCode = 'PROD001');
        insert prod;
        
        // Create pricebook entry for the product
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false
        );
        insert pbe;
        
        Sales_Organisation__c salesOrg = new Sales_Organisation__c(Name = 'SO001');
        insert salesOrg;
        
        Base_UoM_Master__c uom = new Base_UoM_Master__c(Name = 'KG');
        insert uom;
        
        Distribution_Channel__c distChannel = new Distribution_Channel__c(Name = 'DC001');
        insert distChannel;
        
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