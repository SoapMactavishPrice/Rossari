@isTest
private class AccountSampleRequestControllerTest {

    @TestSetup
    static void setupTestData() {
        List<SObject> recordsToInsert = new List<SObject>();
        
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
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        recordsToInsert.add(pbe);

        Account acc = new Account(Name = 'Test Account', CurrencyIsoCode = 'USD');
        recordsToInsert.add(acc);

        Plant__c plant = new Plant__c(Name = 'Test Plant');
        recordsToInsert.add(plant);
        
        insert recordsToInsert;
        recordsToInsert.clear();

        Product2 prod2 = new Product2(
            Name = 'Test Product UnitPrice', 
            ProductCode = 'UP001', 
            IsActive = true
        );
        recordsToInsert.add(prod2);
        
        insert recordsToInsert;
        recordsToInsert.clear();

        PricebookEntry pbe2 = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = prod2.Id,
            UnitPrice = 199.99,
            IsActive = true,
            UseStandardPrice = false
        );
        recordsToInsert.add(pbe2);
        
        insert recordsToInsert;
    }

    @isTest
    static void testAllAccountSampleMethods() {
        Account testAcc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Product2 prod2 = [SELECT Id FROM Product2 WHERE ProductCode = 'UP001' LIMIT 1];

        Test.startTest();
        
        Map<String, Object> accountResult = AccountSampleRequestController.getAccountInfo(testAcc.Id);
        
        List<Plant__c> plantResults = AccountSampleRequestController.getPlantOptions();
        
        String zone = AccountSampleRequestController.getCurrentUserZone();
        
        Map<String, List<String>> picklistDeps = AccountSampleRequestController.getPicklistDependencies();
        
        Decimal unitPrice = AccountSampleRequestController.getUnitPrice(prod2.Id);
        
        Test.stopTest();
    }

    @isTest
    static void testSaveSampleAndUploadFiles() {
        Account testAcc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 WHERE ProductCode = 'TP001' LIMIT 1];
        Plant__c plant = [SELECT Id FROM Plant__c WHERE Name = 'Test Plant' LIMIT 1];

        Test.startTest();
        
        String sampleJs = JSON.serialize(new Map<String, Object>{
            'Request_Date' => String.valueOf(Date.today()),
            'Sample_Expected_Date' => String.valueOf(Date.today().addDays(3)),
            'Consignee_Name' => 'Test Consignee',
            'Send_Email_To_Plant' => true,
            'Remark' => 'Test remark',
            'Sample_Follow_Up_Date' => String.valueOf(Date.today().addDays(7)),
            'CurrencyIsoCode' => 'USD',
            'Sample_Category' => 'Unpaid'
        });

        List<Map<String, Object>> sampleLines = new List<Map<String, Object>>{
            new Map<String, Object>{
                'prodId' => prod.Id,
                'Sample_Request_To_Plant' => plant.Id,
                'Sample_Qty_in_Kgs' => 10,
                'Sales_Price' => 50
            }
        };
        String sampleLine = JSON.serialize(sampleLines);

        Blob fileBody = Blob.valueOf('Test file content');
        String base64Data = EncodingUtil.base64Encode(fileBody);

        List<Map<String, Object>> attachments = new List<Map<String, Object>>{
            new Map<String, Object>{
                'filename' => 'TestFile.txt',
                'base64' => base64Data
            }
        };

        String resultId;
        try {
            resultId = AccountSampleRequestController.saveSample(testAcc.Id, sampleJs, attachments, sampleLine);
        } catch (Exception e) {
        }

        if (resultId != null) {
            List<Map<String, Object>> files = new List<Map<String, Object>>{
                new Map<String, Object>{
                    'filename' => 'UploadedTestFile.txt',
                    'base64' => base64Data
                }
            };

            try {
                AccountSampleRequestController.uploadFiles(testAcc.Id, files);
            } catch (Exception e) {
            }
        }
        
        Test.stopTest();
        
        if (resultId != null) {
            Sample_Request__c insertedRequest = [
                SELECT Id, Consignee_Name__c FROM Sample_Request__c WHERE Id = :resultId
            ];
        }

        List<ContentDocumentLink> uploadedFiles = [
            SELECT Id, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId = :testAcc.Id
        ];
    }

    @isTest
    static void testSaveSampleWithMinimalData() {
        Account testAcc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 WHERE ProductCode = 'TP001' LIMIT 1];
        Plant__c plant = [SELECT Id FROM Plant__c WHERE Name = 'Test Plant' LIMIT 1];

        Test.startTest();
        
        String sampleJs = JSON.serialize(new Map<String, Object>{
            'Request_Date' => String.valueOf(Date.today()),
            'Sample_Expected_Date' => String.valueOf(Date.today().addDays(3)),
            'Consignee_Name' => 'Test Consignee',
            'Sample_Category' => 'Unpaid',
            'CurrencyIsoCode' => 'USD'
        });

        List<Map<String, Object>> sampleLines = new List<Map<String, Object>>{
            new Map<String, Object>{
                'prodId' => prod.Id,
                'Sample_Request_To_Plant' => plant.Id,
                'Sample_Qty_in_Kgs' => 10,
                'Sales_Price' => 50
            }
        };
        String sampleLine = JSON.serialize(sampleLines);

        List<Map<String, Object>> attachments = new List<Map<String, Object>>();

        String resultId;
        try {
            resultId = AccountSampleRequestController.saveSample(testAcc.Id, sampleJs, attachments, sampleLine);
        } catch (Exception e) {
        }
        
        Test.stopTest();
        
        if (resultId != null) {
            Sample_Request__c insertedRequest = [
                SELECT Id, Consignee_Name__c, Sample_Category__c 
                FROM Sample_Request__c WHERE Id = :resultId
            ];
        }
    }
}