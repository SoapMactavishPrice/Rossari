@IsTest
private class ProductMasterAPITest {
    
    @TestSetup
    static void setupTestData() {
        // Create test data for all required objects
        Sales_Organisation__c so = new Sales_Organisation__c(Name = '1000');
        insert so;
        
        Distribution_Channel__c dc = new Distribution_Channel__c(Distribution_Code__c = '10');
        insert dc;
        
        Division__c div = new Division__c(Division_Code__c = '28');
        insert div;
        
        Base_UOM_Master__c baseUom = new Base_UOM_Master__c(Base_Code__c = 'L', Type__c = 'Base UOM');
        Base_UOM_Master__c salesUom = new Base_UOM_Master__c(Base_Code__c = 'NOS', Type__c = 'Base UOM');
        Base_UOM_Master__c wtUom = new Base_UOM_Master__c(Base_Code__c = 'KG', Type__c = 'Wt UOM');
        insert new List<Base_UOM_Master__c>{baseUom, salesUom, wtUom};
            
            HSN_Master__c hsn = new HSN_Master__c(Name = '27101990', SAP_HSN_Code__c = '27101990');
        insert hsn;
        
        Plant__c plant = new Plant__c(Name = '1000');
        insert plant;
        
        // Query existing Standard Pricebook instead of inserting
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        try{
        update standardPricebook;
        }Catch(Exception e){}

        // Create custom pricebooks
        Pricebook2 domesticPb = new Pricebook2(
            Name = 'Rossari Domestic Price Book',
            IsActive = true
        );
        insert domesticPb;
        
        Pricebook2 exportPb = new Pricebook2(
            Name = 'Rossari Export Price Book',
            IsActive = true
        );
        insert exportPb;
    }
    
    @IsTest
    static void testDoPostSuccess() {
        String jsonRequest = '[{' +
            '"SFDC_ID":"",' +
            '"ITEM_NUMBER":"000000000400009166",' +
            '"ITEM_DESCRIPTION":"KYROS STNSL 80DA-210LT HD BL",' +
            '"DISPLAY_NAME":"KYROS STNSL 80DA-210LT HD BL",' +
            '"ITEM_GROUP":"FG3000",' +
            '"ITEM_TYPE":"FERT",' +
            '"BASE_UOM":"L",' +
            '"OLD_MATERIAL_CODE":"KSL40401PM551",' +
            '"SALES_ORGANISATION":"1000",' +
            '"DISTRIBUTION_CHANNEL":"10",' +
            '"DIVISION":"28",' +
            '"SALES_UOM":"NOS",' +
            '"PLANT_CODE":"1000",' +
            '"PROD_HIERACHY":"000140001300000001",' +
            '"GENITEMCATGROUP":"NORM",' +
            '"GROSS_WT":"0",' +
            '"NET_WT":0,' +
            '"WT_UOM":"KG",' +
            '"VOLUME":"0",' +
            '"SIZE_DIMENSIONS":"210 LT",' +
            '"ITEM_TYPE_C":"Fertigerzeugnis",' +
            '"MATERIAL_GROUP_1":"AD",' +
            '"MATERIAL_GROUP_1_C":"SBU-4",' +
            '"MATERIAL_GROUP_2":"AO",' +
            '"MATERIAL_GROUP_2_C":"Kyros",' +
            '"MATERIAL_GROUP_3":"AS",' +
            '"MATERIAL_GROUP_3_C":"Solvent",' +
            '"MATERIAL_GROUP_4":"CL",' +
            '"MATERIAL_GROUP_4_C":"Solvents",' +
            '"MATERIAL_GROUP_5":"CM",' +
            '"MATERIAL_GROUP_5_C":"Commodity",' +
            '"MATERIAL_FREIGHT_GROUP":"AB",' +
            '"MATERIAL_FREIGHT_GROUP_C":"Non MRP(Barrel&Drum)",' +
            '"LIST_PRICE_MRP_PRICE":"100.50",' +
            '"HSN_CODE":"27101990",' +
            '"LEAD_TIME":0,' +
            '"PRODUCT_STATUS":"KCVEDALQBGZX",' +
            '"PLANT_EXTENTION":[{' +
            '"SFDC_ID":"",' +
            '"ITEM_NUMBER":"000000000400009166",' +
            '"PLANT_CODE":"1000",' +
            '"TOTAL_STOCK":0' +
            '}],' +
            '"SALES_AREA":[{' +
            '"SFDC_ID":"",' +
            '"ITEM_NUMBER":"000000000400009166",' +
            '"SALES_ORGANISATION":"1000",' +
            '"DISTRIBUTION_CHANNEL":"10",' +
            '"DIVISION":"28"' +
            '}],' +
            '"CONV_FACT_SALE":[{' +
            '"SFDC_ID":"",' +
            '"ALT_QUANITTY":"1",' +
            '"ALT_UOM":"NOS",' +
            '"BASE_QTY":"5",' +
            '"BASE_UOM":"L",' +
            '"ITEM_NUMBER":"000000000400009166",' +
            '"IS_DEFAULT":"true"' +
            '}]' +
            '}]';
        
        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(jsonRequest);
        RestContext.request = request;
        RestResponse response = new RestResponse();
        RestContext.response = response;
        
        Test.startTest();
        ProductMasterAPI.doPost();
        Test.stopTest();
        
        // Verify product was created
        List<Product2> products = [SELECT Id, ProductCode, Name FROM Product2];
        
    }
    
    @IsTest
    static void testDoPostUpdateExisting() {
        Product2 existingProduct = new Product2(
            Name = 'Existing Product',
            ProductCode = '000000000400009166',
            IsActive = true
        );
        insert existingProduct;
        
        Plant__c plant = [SELECT Id FROM Plant__c WHERE Name = '1000' LIMIT 1];
        Sales_Organisation__c so = [SELECT Id FROM Sales_Organisation__c WHERE Name = '1000' LIMIT 1];
        Distribution_Channel__c dc = [SELECT Id FROM Distribution_Channel__c WHERE Distribution_Code__c = '10' LIMIT 1];
        Division__c div = [SELECT Id FROM Division__c WHERE Division_Code__c = '28' LIMIT 1];
        
        Plant_Extension__c existingPlantExt = new Plant_Extension__c(
            Item_Master__c = existingProduct.Id,
            Plant_Code__c = plant.Id
        );
        insert existingPlantExt;
        
        Sales_Area__c existingSalesArea = new Sales_Area__c(
            Item_Master__c = existingProduct.Id,
            //Sales_Orgainisation__c = so.Id,
            Distribution_Channel__c = dc.Id,
            Division__c = div.Id
        );
        insert existingSalesArea;
        
        String jsonRequest = '[{' +
            '"SFDC_ID":"' + existingProduct.Id + '",' +
            '"ITEM_NUMBER":"000000000400009166",' +
            '"DISPLAY_NAME":"Updated Product Name",' +
            '"PLANT_EXTENTION":[{' +
            '"SFDC_ID":"' + existingPlantExt.Id + '",' +
            '"ITEM_NUMBER":"000000000400009166",' +
            '"PLANT_CODE":"1000",' +
            '"TOTAL_STOCK":10' +
            '}],' +
            '"SALES_AREA":[{' +
            '"SFDC_ID":"' + existingSalesArea.Id + '",' +
            '"ITEM_NUMBER":"000000000400009166",' +
            '"SALES_ORGANISATION":"1000",' +
            '"DISTRIBUTION_CHANNEL":"10",' +
            '"DIVISION":"28"' +
            '}]' +
            '}]';
        
        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(jsonRequest);
        RestContext.request = request;
        RestResponse response = new RestResponse();
        RestContext.response = response;
        
        Test.startTest();
        ProductMasterAPI.doPost();
        Test.stopTest();
        
        Product2 updatedProduct = [SELECT Id, Name FROM Product2 WHERE Id = :existingProduct.Id];
        
        Plant_Extension__c updatedPlantExt = [SELECT Id, Total_Stock__c FROM Plant_Extension__c WHERE Id = :existingPlantExt.Id];
    }
    
    @IsTest
    static void testDoPostException() {
        String jsonRequest = 'malformed json';
        
        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(jsonRequest);
        RestContext.request = request;
        RestResponse response = new RestResponse();
        RestContext.response = response;
        
        Test.startTest();
        ProductMasterAPI.doPost();
        Test.stopTest();
        
        List<API_log__c> apiLogs = [SELECT Id, Status__c FROM API_log__c];
    }
    
    @IsTest
    static void testDoPostWithEmptyValues() {
        String jsonRequest = '[{' +
            '"ITEM_NUMBER":"TEST001",' +
            '"DISPLAY_NAME":"Test Product",' +
            '"ITEM_GROUP":"",' +
            '"BASE_UOM":"",' +
            '"SALES_ORGANISATION":"",' +
            '"DISTRIBUTION_CHANNEL":"",' +
            '"DIVISION":"",' +
            '"SALES_UOM":"",' +
            '"PLANT_CODE":"",' +
            '"NET_WT":0,' +
            '"WT_UOM":"",' +
            '"LIST_PRICE_MRP_PRICE":"",' +
            '"HSN_CODE":"",' +
            '"PLANT_EXTENTION":[],' +
            '"SALES_AREA":[],' +
            '"CONV_FACT_SALE":[]' +
            '}]';
        
        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(jsonRequest);
        RestContext.request = request;
        RestResponse response = new RestResponse();
        RestContext.response = response;
        
        Test.startTest();
        ProductMasterAPI.doPost();
        Test.stopTest();
        
        
    }
    
    @IsTest
    static void testDoPostWithMultipleRecords() {
        String jsonRequest = '[{' +
            '"ITEM_NUMBER":"PROD001",' +
            '"DISPLAY_NAME":"Product 1",' +
            '"PLANT_EXTENTION":[],' +
            '"SALES_AREA":[],' +
            '"CONV_FACT_SALE":[]' +
            '},{' +
            '"ITEM_NUMBER":"PROD002",' +
            '"DISPLAY_NAME":"Product 2",' +
            '"PLANT_EXTENTION":[],' +
            '"SALES_AREA":[],' +
            '"CONV_FACT_SALE":[]' +
            '}]';
        
        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(jsonRequest);
        RestContext.request = request;
        RestResponse response = new RestResponse();
        RestContext.response = response;
        
        Test.startTest();
        ProductMasterAPI.doPost();
        Test.stopTest();
        
        List<Product2> products = [SELECT Id, ProductCode FROM Product2 WHERE ProductCode IN ('PROD001','PROD002')];
    }
    
    @IsTest
    static void testParseMethodIndirectly() {
        String jsonRequest = '[{"ITEM_NUMBER":"TEST001","DISPLAY_NAME":"Test Product"}]';
        
        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(jsonRequest);
        RestContext.request = request;
        RestResponse response = new RestResponse();
        RestContext.response = response;
        
        Test.startTest();
        ProductMasterAPI.doPost();
        Test.stopTest();
        
        List<Product2> products = [SELECT Id, ProductCode, Name FROM Product2 WHERE ProductCode = 'TEST001'];
    }
    
 /*   @IsTest
    static void testPricebookEntryCreation() {
        String jsonRequest = '[{' +
            '"ITEM_NUMBER":"PRICEBOOK_TEST",' +
            '"DISPLAY_NAME":"Pricebook Test Product",' +
            '"LIST_PRICE_MRP_PRICE":"150.75",' +
            '"BASE_UOM":"L",' +                       // added
            '"SALES_ORGANISATION":"1000",' +          // added
            '"DISTRIBUTION_CHANNEL":"10",' +          // added
            '"DIVISION":"28",' +                      // added
            '"HSN_CODE":"27101990",' +                // added
            '"PLANT_CODE":"1000",' +                  // added
            '"PLANT_EXTENTION":[],' +
            '"SALES_AREA":[],' +
            '"CONV_FACT_SALE":[]' +
            '}]';
        
        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(jsonRequest);
        RestContext.request = request;
        RestResponse response = new RestResponse();
        RestContext.response = response;
        
        Test.startTest();
        ProductMasterAPI.doPost();
        Test.stopTest();
        
        // Query safely
        List<Product2> productList = [SELECT Id FROM Product2 WHERE ProductCode = 'PRICEBOOK_TEST' LIMIT 1];
        
        List<PricebookEntry> pricebookEntries = [
            SELECT Id, UnitPrice 
            FROM PricebookEntry 
            WHERE Product2Id = :productList[0].Id
        ];
    } */
    
}