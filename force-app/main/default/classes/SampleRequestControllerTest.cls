@isTest
private class SampleRequestControllerTest {

    @isTest
    static void testAllMethods() {
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Status = 'Open - Not Contacted',
            CurrencyIsoCode = 'USD'
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
                'filename' => 'test.txt',
                'base64' => EncodingUtil.base64Encode(Blob.valueOf('Test content for file attachment'))
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
    }
}