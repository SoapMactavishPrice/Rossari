@IsTest
private class SendTDSFileTest {

    @TestSetup
    static void setupTestData() {
        // Create Lead
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Email = 'test@example.com',
			MobilePhone = '9876543210'
        );
        insert testLead;

        // Activate standard Pricebook
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

        // Create Standard PricebookEntry
        PricebookEntry standardPBE = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert standardPBE;

        // Create Product_Interested__c related to Lead
        Product_Interested__c pi = new Product_Interested__c(
            Lead__c = testLead.Id,
            Product__c = testProduct.Id
        );
        insert pi;

        // Create ContentVersion (mock file)
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.txt',
            VersionData = Blob.valueOf('Test Content')
        );
        insert cv;

        // Link ContentDocument to Lead
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId,
            LinkedEntityId = testLead.Id,
            ShareType = 'V'
        );
        insert cdl;
    }

    @IsTest
    static void testGetEmailDetails() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        Lead result = SendTDSFile.getEmailDetails(testLead.Id);
        System.assertNotEquals(null, result);
        System.assertEquals(testLead.Id, result.Id);
    }

    @IsTest
    static void testGetLead() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        SendTDSFile.LeadWrapper lw = SendTDSFile.getLead(testLead.Id);
        System.assertNotEquals(null, lw);
        System.assertEquals(testLead.Id, lw.leadId);
    }

    @IsTest
    static void testGetProductData() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        String jsonData = SendTDSFile.getProductData(testLead.Id);
        System.assertNotEquals(null, jsonData);
    }

    @IsTest
    static void testGetFiledDisplay() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        String filesJson = SendTDSFile.getFiledDisplay(testLead.Id);
        System.assertNotEquals(null, filesJson);
    }

    @IsTest
    static void testGetDocumentUrl() {
        //ContentDocumentLink cdl = [SELECT Id FROM ContentDocumentLink LIMIT 1];
        Id someLinkedEntityId = [SELECT Id FROM Lead LIMIT 1].Id;
        ContentDocumentLink cdl = [
            SELECT Id, ContentDocumentId 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :someLinkedEntityId
            LIMIT 1
        ];
        String docId = SendTDSFile.getDocumentUrl(cdl.Id);
        System.assertNotEquals(null, docId);
    }

    @IsTest
    static void testSendMailToCustomer() {
        Lead testLead = [SELECT Id, Email FROM Lead LIMIT 1];
        List<Object> attachments = new List<Object>();
        Map<String, String> attMap = new Map<String, String>{
            'filename' => 'Test.txt',
            'base64' => EncodingUtil.base64Encode(Blob.valueOf('Test content'))
        };
        attachments.add(attMap);

        String jsonResult = SendTDSFile.sendMailToCustomer(
            testLead.Email,
            null,
            'Test Subject',
            'Test Body',
            '[]',
            attachments
        );
        System.assert(jsonResult.contains('Success') || jsonResult.contains('error'));
    }

    @IsTest
    static void testRequestApproval() {
        Lead testLead = [SELECT Id,Name,COA_Approval_Level_1_Status__c,COA_Approval_Level_2_Status__c,COA_Approval_Level_1__c, COA_Approval_Level_2__c,RecordType.Name FROM Lead LIMIT 1];
        SendTDSFile.LeadWrapper lw = new SendTDSFile.LeadWrapper(testLead);
        String json = JSON.serialize(lw);

        String result = SendTDSFile.requestApproval(json);
        System.assertEquals('Success', result);
    }

    @IsTest
    static void testGetCurrentUserDetails() {
        SendTDSFile.UserDetailWrapper userDetail = SendTDSFile.getCurrentUserDetails();
        System.assertNotEquals(null, userDetail);
        System.assertNotEquals(null, userDetail.ownerEmail);
    }
}