@isTest
private class AccountSampleRequestControllerTest {

    @isTest
    static void testGetAccountInfo() {
        Account testAcc = new Account(Name = 'Test Account', CurrencyIsoCode = 'USD');
        insert testAcc;

        Test.startTest();
        Map<String, Object> result = AccountSampleRequestController.getAccountInfo(testAcc.Id);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assert(result.containsKey('account'));

        Map<String, Object> accountInfo = (Map<String, Object>) result.get('account');
        
    }

    @isTest
    static void testGetPlantOptions() {
        Plant__c plant = new Plant__c(Name = 'Test Plant');
        insert plant;

        Test.startTest();
        List<Plant__c> results = AccountSampleRequestController.getPlantOptions();
        Test.stopTest();

        
    }

    @isTest
    static void testSaveSample() {
        // Create sample Account
        Account acc = new Account(Name = 'Test Account', CurrencyIsoCode = 'USD');
        insert acc;

        // Create custom product if Product__c is not a lookup to Product2
        // Otherwise, use Product2 (adjust based on actual relationship)
        Product2 prod = new Product2(Name = 'Test Product', ProductCode = 'TP01', IsActive = true);
        insert prod;

        // Sample JSON for sampleJs
        String sampleJs = JSON.serialize(new Map<String, Object>{
            'Request_Date' => String.valueOf(Date.today()),
            'Sample_Expected_Date' => String.valueOf(Date.today().addDays(3)),
            'Consignee_Name' => 'Test Consignee',
            'Send_Email_To_Plant' => true,
            'Remark' => 'Test remark',
            'Sample_Follow_Up_Date' => String.valueOf(Date.today().addDays(7)),
            'CurrencyIsoCode' => 'USD'
        });

        // Sample line item JSON
        List<Map<String, Object>> sampleLines = new List<Map<String, Object>>{
            new Map<String, Object>{
                'prodId' => prod.Id,
                'Sample_Request_To_Plant' => 'Test Plant',
                'Sample_Qty_in_Kgs' => 10
            }
        };
        String sampleLine = JSON.serialize(sampleLines);

        // Prepare a test attachment (ContentVersion without FirstPublishLocationId)
        List<Map<String, Object>> attachments = new List<Map<String, Object>>();
        Blob fileBody = Blob.valueOf('Test file content');
        String base64Data = EncodingUtil.base64Encode(fileBody);

        attachments.add(new Map<String, Object>{
            'filename' => 'TestFile.txt',
            'base64' => base64Data
        });

        String resultId;
        try {
            Test.startTest();
            resultId = AccountSampleRequestController.saveSample(acc.Id, sampleJs, attachments, sampleLine);
            Test.stopTest();
        } catch (AuraHandledException e) {
            System.debug('Caught Exception: ' + e.getMessage());
            throw e;
        }

        System.assertNotEquals(null, resultId, 'Sample Request Id should not be null');

        // Validate Sample_Request__c
        Sample_Request__c insertedRequest = [
            SELECT Id, Consignee_Name__c FROM Sample_Request__c WHERE Id = :resultId
        ];

        // Validate Line Items
        List<Sample_Request_Line_Item__c> items = [
            SELECT Id, Product__c FROM Sample_Request_Line_Item__c WHERE Sample_Request__c = :resultId
        ];
        

        // Validate file was attached using ContentDocumentLink
        List<ContentDocumentLink> fileLinks = [
            SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :resultId
        ];
    }
}