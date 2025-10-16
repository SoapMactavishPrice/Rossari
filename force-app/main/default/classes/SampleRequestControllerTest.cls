@IsTest
private class SampleRequestControllerTest {

    @TestSetup
    static void setupTestData() {
        // Create Lead
        Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Status = 'Working',
            CurrencyIsoCode = 'USD',
            MobilePhone = '9876543210'
        );
        insert lead;

        // Get standard pricebook ID without updating (fix for UNABLE_TO_LOCK_ROW)
        Id standardPricebookId = Test.getStandardPricebookId();

        // Create Product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert testProduct;

        // Create PricebookEntry for standard pricebook
        PricebookEntry standardPBE = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = testProduct.Id,
            UnitPrice = 100.00,
            IsActive = true,
            UseStandardPrice = false
        );
        insert standardPBE;

        // Product Interested
        Product_Interested__c pi = new Product_Interested__c(
            Lead__c = lead.Id,
            Product__c = testProduct.Id,
            Quantity_in_Kgs__c = 10,
            New_Product__c = false
        );
        insert pi;

        // Plant
        Plant__c plant = new Plant__c(Name='Test Plant', Plant_Name__c='Plant A');
        insert plant;

        // Sample Request
        Sample_Request__c sampleRequest = new Sample_Request__c(
            Lead__c = lead.Id,
            CurrencyIsoCode = lead.CurrencyIsoCode,
            Sample_Category__c = 'Unpaid',
            Consignee_Name__c = 'Test Company'
        );
        insert sampleRequest;

        // Sample Request Line Item
        Sample_Request_Line_Item__c lineItem = new Sample_Request_Line_Item__c(
            Sample_Request__c = sampleRequest.Id,
            Product__c = testProduct.Id,
            Sample_Qty_in_Kgs__c = 5,
            CurrencyIsoCode = lead.CurrencyIsoCode,
            Sales_Price__c = 0,
            Status__c = 'Ready'
        );
        insert lineItem;
    }

    @IsTest
    static void testGetLeadInfo() {
        Lead lead = [SELECT Id FROM Lead LIMIT 1];
        String result = SampleRequestController.getLeadInfo(lead.Id);
    }

    @IsTest
    static void testGetPlantOptions() {
        List<Plant__c> plants = SampleRequestController.getPlantOptions();
    }

    @IsTest
    static void testSaveSampleWithAttachment() {
        Lead lead = [SELECT Id, CurrencyIsoCode FROM Lead LIMIT 1];

        Map<String, Object> sampleMap = new Map<String, Object>{
            'Sample_Category' => 'Unpaid',
            'Request_Date' => Date.today(),
            'Sample_Expected_Date' => Date.today().addDays(5),
            'Consignee_Name' => 'Test Company',
            'Email' => 'test@example.com',
            'Remark' => 'Test Remark',
            'Customer_Code__c' => 'C123',
            'Sample_Follow_Up_Date' => Date.today().addDays(2).format(),
            'SAP_Doc_Type' => 'Type A'
        };

        List<Map<String, Object>> lineItems = new List<Map<String, Object>>();
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        lineItems.add(new Map<String, Object>{
            'prodId' => product.Id,
            'Sample_Qty_in_Kgs' => 5,
            'Sales_Price' => 50
        });

        // Create dummy attachment
        List<Object> attachments = new List<Object>();
        Map<Object, Object> fileMap = new Map<Object, Object>{
            'filename' => 'TestFile.txt',
            'base64' => EncodingUtil.base64Encode(Blob.valueOf('This is test file content'))
        };
        attachments.add(fileMap);

        String sampleJs = JSON.serialize(sampleMap);
        String lineItemsJs = JSON.serialize(lineItems);

        Test.startTest();
        String sampleRequestId = SampleRequestController.saveSample(lead.Id, sampleJs, attachments, lineItemsJs);
        Test.stopTest();
    }

    @IsTest
    static void testGetExistingLineItems() {
        Sample_Request__c sampleRequest = [SELECT Id FROM Sample_Request__c LIMIT 1];
        List<Sample_Request_Line_Item__c> items = SampleRequestController.getExistingLineItems(sampleRequest.Id);
    }

    @IsTest
    static void testGetStatusPicklistValues() {
        List<String> statuses = SampleRequestController.getStatusPicklistValues();
    }

    @IsTest
    static void testGetPicklistDependencies() {
        Map<String, List<String>> deps = SampleRequestController.getPicklistDependencies();
    }

    @IsTest
    static void testGetUnitPrice() {
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        Decimal price = SampleRequestController.getUnitPrice(product.Id);
    }

    @IsTest
    static void testDeleteLineItem() {
        Sample_Request_Line_Item__c item = [SELECT Id FROM Sample_Request_Line_Item__c LIMIT 1];
        Test.startTest();
        SampleRequestController.deleteLineItem(item.Id);
        Test.stopTest();
    }

    @IsTest
    static void testGetCurrentUserZone() {
        String zone = SampleRequestController.getCurrentUserZone();
    }

    @IsTest
    static void testSaveLineItemsMethod() {
        Sample_Request__c sampleRequest = [SELECT Id FROM Sample_Request__c LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        Plant__c plant = [SELECT Id FROM Plant__c LIMIT 1];

        List<Map<String, Object>> lineItems = new List<Map<String, Object>>();
        lineItems.add(new Map<String, Object>{
            'productId' => product.Id,
            'plantId' => plant.Id,
            'quantity' => 10,
            'status' => 'Ready'
        });

        String lineItemsJson = JSON.serialize(lineItems);

        Test.startTest();
        SampleRequestController.saveLineItems(string.valueOf(sampleRequest.Id), lineItemsJson);
        Test.stopTest();
    }
}