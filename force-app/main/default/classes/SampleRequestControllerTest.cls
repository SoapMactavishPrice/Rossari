/*@isTest
private class SampleRequestControllerTest {
    
    @isTest
    static void testAllMethods() {
        Country__c india = new Country__c(Name = 'India');
        insert india;
        
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Status = 'Open - Not Contacted',
            CurrencyIsoCode = 'USD',
            MobilePhone = '1234567890'
        );
        insert testLead;
        
        Product2 testProduct = new Product2(
            Name = 'Sample Product',
            ProductCode = 'SP001',
            Description = 'Test Description',
            IsActive = true
        );
        insert testProduct;
        
        Product_Interested__c productInterested = new Product_Interested__c(
            Lead__c = testLead.Id,
            Product__c = testProduct.Id,
            Quantity_in_Kgs__c = 5,
            New_Product__c = false
        );
        insert productInterested;
        
        Plant__c plant = new Plant__c(Name = 'Plant 1', Plant_Name__c = 'Main Plant');
        insert plant;
        
        String leadInfo = SampleRequestController.getLeadInfo(testLead.Id);
        List<Plant__c> plantOptions = SampleRequestController.getPlantOptions();
        
        Map<String, Object> sampleMap = new Map<String, Object>{
            'Request_Date' => String.valueOf(Date.today()),
                'Sample_Expected_Date' => String.valueOf(Date.today().addDays(5)),
                'Consignee_Name' => 'Consignee',
                'Send_Email_To_Plant' => true,
                'Remark' => 'Test Remark',
                'Sample_Follow_Up_Date' => String.valueOf(Date.today().addDays(10))
                };
                    String sampleJs = JSON.serialize(sampleMap);
        
        List<Map<String, Object>> lineItems = new List<Map<String, Object>>{
            new Map<String, Object>{
                'prodId' => testProduct.Id,
                    'Sample_Request_To_Plant' => plant.Id,
                    'Sample_Qty_in_Kgs' => 10
                    }
        };
            String sampleLine = JSON.serialize(lineItems);
        
        List<Object> attachments = new List<Object>{
            new Map<String, Object>{
                'filename' => 'test_large.txt',
                    'base64' => EncodingUtil.base64Encode(Blob.valueOf(
                        'This is a longer test content to exceed 100 characters for base64 encoding coverage. ' +
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.'
                    ))
                    }
        };
            
            String sampleRequestId = SampleRequestController.saveSample(testLead.Id, sampleJs, attachments, sampleLine);
        List<Sample_Request_Line_Item__c> existingItems = SampleRequestController.getExistingLineItems(sampleRequestId);
        List<String> picklistValues = SampleRequestController.getStatusPicklistValues();
        
        List<String> validStatuses = SampleRequestController.getStatusPicklistValues();
        
        List<Map<String, Object>> upsertLineItemList = new List<Map<String, Object>>();
        for (Sample_Request_Line_Item__c item : existingItems) {
            upsertLineItemList.add(new Map<String, Object>{
                'id' => item.Id,
                    'productId' => testProduct.Id,
                    'plantId' => plant.Id,
                    'quantity' => '15',
                    'status' => validStatuses.isEmpty() ? 'In Progress' : validStatuses[0]
                        });
        }
        
        String upsertLineItemsJson = JSON.serialize(upsertLineItemList);
        SampleRequestController.saveLineItems(sampleRequestId, upsertLineItemsJson);
        
        Set<Id> lineItemIds = new Set<Id>();
        for (Sample_Request_Line_Item__c item : existingItems) {
            lineItemIds.add(item.Id);
        }
        SampleRequestController.updateParentStatus(lineItemIds);
        
        for (Sample_Request_Line_Item__c item : existingItems) {
            SampleRequestController.deleteLineItem(item.Id);
        }
        
        Map<String, List<String>> picklistDeps = SampleRequestController.getPicklistDependencies();
        String userZone = SampleRequestController.getCurrentUserZone();
    }
}*/
@IsTest
private class SampleRequestControllerTest {

    @TestSetup
    static void setupTestData() {
        // Create Lead
        Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Status = 'Open - Not Contacted',
            CurrencyIsoCode = 'USD',
            MobilePhone = '9876543210'
        );
        insert lead;

        // Activate Standard Pricebook
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

        // Create Product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert testProduct;

        // Create PricebookEntry for standard pricebook
        PricebookEntry standardPBE = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100.00,
            IsActive = true
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
            Sales_Price__c = 0
        );
        insert lineItem;
    }

    @IsTest
    static void testGetLeadInfo() {
        Lead lead = [SELECT Id FROM Lead LIMIT 1];
        String result = SampleRequestController.getLeadInfo(lead.Id);
        System.assert(result.contains('Consignee_Name'));
        System.assert(result.contains('piList'));
    }

    @IsTest
    static void testGetPlantOptions() {
        List<Plant__c> plants = SampleRequestController.getPlantOptions();
        System.assert(plants.size() > 0);
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

        Sample_Request__c savedRequest = [SELECT Id FROM Sample_Request__c WHERE Id = :sampleRequestId];

        // Verify that a ContentVersion exists linked to the sample request
        List<ContentVersion> contentVersions = [SELECT Id, ContentDocumentId
                                                FROM ContentVersion
                                                WHERE Title = 'TestFile.txt'];
        //System.assert(contentVersions.size() > 0, 'ContentVersion should be created');

        // Verify ContentDocumentLink exists
        List<ContentDocumentLink> links = [SELECT Id, ContentDocumentId, LinkedEntityId
                                           FROM ContentDocumentLink
                                           WHERE LinkedEntityId = :savedRequest.Id];
        System.assert(links.size() > 0, 'Attachment should be linked to the sample request');
    }

    @IsTest
    static void testGetExistingLineItems() {
        Sample_Request__c sampleRequest = [SELECT Id FROM Sample_Request__c LIMIT 1];
        List<Sample_Request_Line_Item__c> items = SampleRequestController.getExistingLineItems(sampleRequest.Id);
        System.assert(items.size() > 0, 'There should be existing line items.');
    }

    @IsTest
    static void testGetStatusPicklistValues() {
        List<String> statuses = SampleRequestController.getStatusPicklistValues();
        System.assert(statuses.size() > 0);
    }

    @IsTest
    static void testGetPicklistDependencies() {
        Map<String, List<String>> deps = SampleRequestController.getPicklistDependencies();
        System.assert(deps.containsKey('Sample_Category__c'));
        System.assert(deps.containsKey('SAP_Sample_Document_Type__c'));
    }

    @IsTest
    static void testGetUnitPrice() {
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        Decimal price = SampleRequestController.getUnitPrice(product.Id);
        System.assertEquals(100.00, price);
    }

    @IsTest
    static void testDeleteLineItem() {
        Sample_Request_Line_Item__c item = [SELECT Id FROM Sample_Request_Line_Item__c LIMIT 1];
        Test.startTest();
        SampleRequestController.deleteLineItem(item.Id);
        Test.stopTest();

        List<Sample_Request_Line_Item__c> items = [SELECT Id FROM Sample_Request_Line_Item__c WHERE Id = :item.Id];
        System.assertEquals(0, items.size());
    }

    @IsTest
    static void testGetCurrentUserZone() {
        String zone = SampleRequestController.getCurrentUserZone();
        System.assert(zone != null);
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
            'status' => 'Pending'
        });

        String lineItemsJson = JSON.serialize(lineItems);

        Test.startTest();
        SampleRequestController.saveLineItems(sampleRequest.Id, lineItemsJson);
        Test.stopTest();

        // Verify that the line item was upserted
        List<Sample_Request_Line_Item__c> items = [SELECT Id, Sample_Qty_in_Kgs__c, Status__c 
                                                  FROM Sample_Request_Line_Item__c 
                                                  WHERE Sample_Request__c = :sampleRequest.Id 
                                                  AND Product__c = :product.Id];
        System.assert(items.size() > 0, 'Line item should be upserted');
        System.assertEquals(10, items[0].Sample_Qty_in_Kgs__c);
        System.assertEquals('Pending', items[0].Status__c);
    }
}