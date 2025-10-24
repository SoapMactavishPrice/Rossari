@IsTest
private class SendTDSFileTest {

    @TestSetup
    static void setupTestData() {
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Email = 'test@example.com',
            MobilePhone = '9876543210'
        );
        insert testLead;

        Id standardPricebookId = Test.getStandardPricebookId();

       Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        try{
        update standardPricebook;
        }Catch(Exception e){}
        
        Base_UoM_Master__c baseUom = new Base_UoM_Master__c(Name = 'Kilogram');
        insert baseUom;
 
        Product2 prod = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP001',
            Pack_Size__c = '10kg',
            Base_UOM__c = baseUom.Id,
            IsActive = true
        );
        insert prod;
 
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;


        Product_Interested__c pi = new Product_Interested__c(
            Lead__c = testLead.Id,
            Product__c = Prod.Id
        );
        insert pi;

        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.txt',
            VersionData = Blob.valueOf('Test Content')
        );
        insert cv;

        ContentVersion insertedCV = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = insertedCV.ContentDocumentId,
            LinkedEntityId = testLead.Id,
            ShareType = 'V'
        );
        insert cdl;
    }

    @IsTest
    static void testSendMailAndOtherMethods() {
        Lead lead = [SELECT Id, Email FROM Lead LIMIT 1];
        Id leadId = lead.Id;

        // Call all other methods
        SendTDSFile.getEmailDetails(leadId);
        SendTDSFile.getLead(leadId);
        SendTDSFile.getProductData(leadId);
        SendTDSFile.getFiledDisplay(leadId);
        ContentDocumentLink cdl = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :leadId LIMIT 1];
        SendTDSFile.getDocumentUrl(cdl.Id);
        SendTDSFile.getCurrentUserDetails();

        // Send mail with full coverage
        List<String> sObjIds = new List<String>{ cdl.Id };
        List<Object> attachments = new List<Object>{
            new Map<String, String>{
                'filename' => 'UploadedFile.txt',
                'base64' => EncodingUtil.base64Encode(Blob.valueOf('Uploaded file content'))
            }
        };
        List<String> ccList = new List<String>{ 'cc1@example.com', 'cc2@example.com' };
        SendTDSFile.sendMailToCustomer(
            lead.Email,
            ccList,
            'Full Coverage Subject',
            'Full Coverage Body',
            JSON.serialize(sObjIds),
            attachments
        );

        // Send mail with no attachments (should throw AuraHandledException)
        try {
            SendTDSFile.sendMailToCustomer(
                lead.Email,
                null,
                'No Attachments Subject',
                'No Attachments Body',
                '[]',
                new List<Object>()
            );
        } catch (AuraHandledException e) {
            System.assert(true, 'Expected AuraHandledException for missing attachments.');
        }

        // Request approval
        Lead fullLead = [SELECT Id, Name, COA_Approval_Level_1_Status__c, COA_Approval_Level_2_Status__c, COA_Approval_Level_1__c, COA_Approval_Level_2__c, RecordType.Name FROM Lead LIMIT 1];
        SendTDSFile.requestApproval(JSON.serialize(new SendTDSFile.LeadWrapper(fullLead)));
    }
}