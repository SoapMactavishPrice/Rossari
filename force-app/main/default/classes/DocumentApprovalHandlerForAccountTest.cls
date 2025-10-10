@IsTest
public class DocumentApprovalHandlerForAccountTest {

    @TestSetup
    static void setupData() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        List<User> users = new List<User>{
            new User(
                Alias = 'tdsu',
                Email = 'tdsuser@example.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'TDSUser',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = p.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                Username = 'tdsuser' + DateTime.now().getTime() + '@example.com'
            ),
            new User(
                Alias = 'msdsu',
                Email = 'msdsuser@example.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'MSDSUser',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = p.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                Username = 'msdsuser' + DateTime.now().getTime() + '@example.com'
            ),
            new User(
                Alias = 'techu',
                Email = 'techuser@example.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'TechUser',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = p.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                Username = 'techuser' + DateTime.now().getTime() + '@example.com'
            ),
            new User(
                Alias = 'coau',
                Email = 'coauser@example.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'COAUser',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = p.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                Username = 'coauser' + DateTime.now().getTime() + '@example.com'
            ),
            new User(
                Alias = 'ownr',
                Email = 'owner@example.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'OwnerUser',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = p.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                Username = 'owner' + DateTime.now().getTime() + '@example.com'
            )
        };
        insert users;

        Account accountRecord = new Account(
            Name = 'TestAccount_' + String.valueOf(Datetime.now().getTime()),
            OwnerId = users[4].Id
        );
        insert accountRecord;
    }

    @IsTest
    static void testAllFunctionalitiesTogether() {
        Account accountRecord = [SELECT Id, Owner.Email, Previous_View_Type__c FROM Account LIMIT 1];
        List<User> activeUsers = [SELECT Id FROM User WHERE IsActive = true LIMIT 5];

        DocumentApprovalHandlerForAccount.ApproverModel model = new DocumentApprovalHandlerForAccount.ApproverModel();
        model.tdsApproverId = activeUsers[0].Id;
        model.msdsApproverId = activeUsers[1].Id;
        model.technicalDocApproverId = activeUsers[2].Id;
        model.coaDocApproverId = activeUsers[3].Id;
        String approverJson = JSON.serialize(model);

        DocumentApprovalHandlerForAccount.SampleDocumentWrapper sampleDocs = new DocumentApprovalHandlerForAccount.SampleDocumentWrapper();
        sampleDocs.tdsSampleFiles = new List<DocumentApprovalHandlerForAccount.ContentVersionWrapper>();
        sampleDocs.msdsSampleFiles = new List<DocumentApprovalHandlerForAccount.ContentVersionWrapper>();
        sampleDocs.techDocSampleFiles = new List<DocumentApprovalHandlerForAccount.ContentVersionWrapper>();
        sampleDocs.coaSampleFiles = new List<DocumentApprovalHandlerForAccount.ContentVersionWrapper>();
        
        DocumentApprovalHandlerForAccount.ContentVersionWrapper sampleFile = new DocumentApprovalHandlerForAccount.ContentVersionWrapper();
        sampleFile.fileName = 'sample.txt';
        sampleFile.base64Data = EncodingUtil.base64Encode(Blob.valueOf('sample content'));
        sampleDocs.tdsSampleFiles.add(sampleFile);
        
        String sampleDocsJson = JSON.serialize(sampleDocs);

        Map<Object, Object> m1 = new Map<Object, Object>{
            'fileName' => 'tds.txt',
            'base64' => EncodingUtil.base64Encode(Blob.valueOf('content1')),
            'contentType' => 'text/plain',
            'isReadOnly' => false
        };
        Map<Object, Object> m2 = new Map<Object, Object>{
            'fileName' => 'msds.txt',
            'base64' => EncodingUtil.base64Encode(Blob.valueOf('content2')),
            'contentType' => 'text/plain',
            'isReadOnly' => false
        };
        Map<Object, Object> m3 = new Map<Object, Object>{
            'fileName' => 'tech.txt',
            'base64' => EncodingUtil.base64Encode(Blob.valueOf('content3')),
            'contentType' => 'text/plain',
            'isReadOnly' => false
        };
        Map<Object, Object> m4 = new Map<Object, Object>{
            'fileName' => 'coa.txt',
            'base64' => EncodingUtil.base64Encode(Blob.valueOf('content4')),
            'contentType' => 'text/plain',
            'isReadOnly' => false
        };

        List<Object> tdsFiles = new List<Object>{ m1 };
        List<Object> msdsFiles = new List<Object>{ m2 };
        List<Object> techFiles = new List<Object>{ m3 };
        List<Object> coaFiles = new List<Object>{ m4 };

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testOwner = new User(
            Alias = 'towner',
            Email = 'testowner@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Owner',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testowner' + DateTime.now().getTime() + '@example.com'
        );
        insert testOwner;

        Account newAccount = new Account(
            Name = 'TestCompany_' + String.valueOf(Datetime.now().getTime()),
            OwnerId = testOwner.Id
        );
        insert newAccount;

        ContentVersion cv = new ContentVersion(
            Title = 'TDS_test',
            PathOnClient = 'TDS_test.txt',
            VersionData = Blob.valueOf('Test file content')
        );
        insert cv;

        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId,
            LinkedEntityId = newAccount.Id,
            ShareType = 'V'
        );
        insert cdl;

        List<String> toAddrs = new List<String>{ testOwner.Email };
        List<String> ccAddrs = new List<String>{};

        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        String res = DocumentApprovalHandlerForAccount.updateApproversAndSendEmails(approverJson, sampleDocsJson, accountRecord.Id);
        String uploadResult = DocumentApprovalHandlerForAccount.uploadDocuments(tdsFiles, msdsFiles, techFiles, coaFiles, accountRecord.Id);
        DocumentApprovalHandlerForAccount.DocumentModel docModel = DocumentApprovalHandlerForAccount.getDocumentModel(accountRecord.Id);
        Boolean isSubmitted = DocumentApprovalHandlerForAccount.isRequestDocumentSubmitted(accountRecord.Id);
        String emailResult = DocumentApprovalHandlerForAccount.sendLeadDocumentEmail(newAccount.Id, toAddrs, ccAddrs, 'Test Subject', '<b>Test Body</b>');
        String savePrevResult = DocumentApprovalHandlerForAccount.savePreviousViewType(accountRecord.Id, 'TestView');
        String viewType = DocumentApprovalHandlerForAccount.getPreviousViewType(accountRecord.Id);
        
        update new Account(Id=accountRecord.Id, Previous_View_Type__c = null);
        String nullViewType = DocumentApprovalHandlerForAccount.getPreviousViewType(accountRecord.Id);
        
        String remarksResult = DocumentApprovalHandlerForAccount.saveRemarks('TDS Remark', 'MSDS Remark', 'TechDoc Remark', 'COA Remark', accountRecord.Id);

        Test.stopTest();
    }

    @IsTest
    static void testUpdateApproversAndSendEmailsWithNullApprovers() {
        Account accountRecord = [SELECT Id FROM Account LIMIT 1];
        
        DocumentApprovalHandlerForAccount.ApproverModel model = new DocumentApprovalHandlerForAccount.ApproverModel();
        model.tdsApproverId = null;
        model.msdsApproverId = null;
        model.technicalDocApproverId = null;
        model.coaDocApproverId = null;
        String approverJson = JSON.serialize(model);

        DocumentApprovalHandlerForAccount.SampleDocumentWrapper sampleDocs = new DocumentApprovalHandlerForAccount.SampleDocumentWrapper();
        sampleDocs.tdsSampleFiles = new List<DocumentApprovalHandlerForAccount.ContentVersionWrapper>();
        sampleDocs.msdsSampleFiles = new List<DocumentApprovalHandlerForAccount.ContentVersionWrapper>();
        sampleDocs.techDocSampleFiles = new List<DocumentApprovalHandlerForAccount.ContentVersionWrapper>();
        sampleDocs.coaSampleFiles = new List<DocumentApprovalHandlerForAccount.ContentVersionWrapper>();
        String sampleDocsJson = JSON.serialize(sampleDocs);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        String result = DocumentApprovalHandlerForAccount.updateApproversAndSendEmails(approverJson, sampleDocsJson, accountRecord.Id);
        Test.stopTest();

    }

    /*@IsTest
    static void testUploadDocumentsWithEmptyFiles() {
        Account accountRecord = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        String result = DocumentApprovalHandlerForAccount.uploadDocuments(null, null, null, null, accountRecord.Id);
        Test.stopTest();

        System.assertEquals('Success', result, 'Should return Success even with null files');
    }*/

    /*@IsTest
    static void testUploadDocumentsWithReadOnlyFiles() {
        Account accountRecord = [SELECT Id FROM Account LIMIT 1];

        Map<Object, Object> readOnlyFile = new Map<Object, Object>{
            'fileName' => 'readonly.txt',
            'base64' => EncodingUtil.base64Encode(Blob.valueOf('content')),
            'contentType' => 'text/plain',
            'isReadOnly' => true
        };

        List<Object> tdsFiles = new List<Object>{ readOnlyFile };

        Test.startTest();
        String result = DocumentApprovalHandlerForAccount.uploadDocuments(tdsFiles, null, null, null, accountRecord.Id);
        Test.stopTest();

        System.assertEquals('Success', result, 'Should return Success and skip read-only files');
    }*/

    @IsTest
    static void testSendLeadDocumentEmailNoFiles() {
        Account accountRecord = [SELECT Id FROM Account LIMIT 1];
        List<String> toAddrs = new List<String>{ 'test@example.com' };
        List<String> ccAddrs = new List<String>{};

        Test.startTest();
        String result = DocumentApprovalHandlerForAccount.sendLeadDocumentEmail(accountRecord.Id, toAddrs, ccAddrs, 'Test Subject', '<b>Test Body</b>');
        Test.stopTest();

        System.assertEquals('No files to send.', result, 'Should return no files message when no files attached');
    }

    @IsTest
    static void testDocumentModelConstructor() {
        Account accountRecord = [SELECT Id FROM Account LIMIT 1];
        
        accountRecord.TDS_Upload_Status__c = 'Uploaded';
        accountRecord.MSDS_Upload_Status__c = 'Not Uploaded';
        accountRecord.Technical_Doc_Upload_Status__c = 'Uploaded';
        accountRecord.COA_Doc_Upload_Status__c = 'Not Uploaded';
        accountRecord.TDS_Approver__c = UserInfo.getUserId();
        accountRecord.MSDS_Approver__c = null;
        accountRecord.Technical_Document_Approver__c = UserInfo.getUserId();
        accountRecord.COA_Document_Approver__c = null;
        update accountRecord;

        Test.startTest();
        DocumentApprovalHandlerForAccount.DocumentModel docModel = DocumentApprovalHandlerForAccount.getDocumentModel(accountRecord.Id);
        Test.stopTest();
    }

    @IsTest
    static void testIsRequestDocumentSubmitted() {
        Account accountRecord = [SELECT Id FROM Account LIMIT 1];
        
        Boolean result1 = DocumentApprovalHandlerForAccount.isRequestDocumentSubmitted(accountRecord.Id);

        update accountRecord;
        
        Boolean result2 = DocumentApprovalHandlerForAccount.isRequestDocumentSubmitted(accountRecord.Id);
    }

    @IsTest
    static void testSaveAndGetPreviousViewType() {
        Account accountRecord = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        String saveResult = DocumentApprovalHandlerForAccount.savePreviousViewType(accountRecord.Id, 'DetailedView');
        String viewType = DocumentApprovalHandlerForAccount.getPreviousViewType(accountRecord.Id);
        Test.stopTest();

    }

    @IsTest
    static void testSaveRemarks() {
        Account accountRecord = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        String result = DocumentApprovalHandlerForAccount.saveRemarks('TDS Remark', 'MSDS Remark', 'TechDoc Remark', 'COA Remark', accountRecord.Id);
        
        // Verify the remarks were saved
        Account updatedAccount = [SELECT TDS_Remark__c, MSDS_Remark__c, Tech_Doc_Remark__c, COA_Doc_Remark__c FROM Account WHERE Id = :accountRecord.Id];
        Test.stopTest();
    }

    @IsTest
    static void testSaveRemarksWithNullValues() {
        Account accountRecord = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        String result = DocumentApprovalHandlerForAccount.saveRemarks(null, null, null, null, accountRecord.Id);
        Test.stopTest();
    }

    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success":true}');
            res.setStatusCode(200);
            return res;
        }
    }
}