@IsTest
public class DocumentApprovalHandlerForAccountTest {

    @TestSetup
    static void setupStaticData() {
        // Only setup static reference data that doesn't change
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        List<User> users = new List<User>{
            new User(
                Alias = 'tdsusr',
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
                Alias = 'msdsusr',
                Email = 'msdsuser@example.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'MSDSUser',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = p.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                Username = 'msdsuser' + DateTime.now().getTime() + '@example.com'
            )
        };
        insert users;
    }

    @IsTest
    static void testAllFunctionalitiesTogether() {
        // Create all data within the test method
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testOwner = new User(
            Alias = 'townr',
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

        Account testAccount = new Account(
            Name = 'TestCompany_' + String.valueOf(Datetime.now().getTime()),
            OwnerId = testOwner.Id
        );
        insert testAccount;

        List<User> activeUsers = [SELECT Id FROM User WHERE IsActive = true AND Id != :testOwner.Id LIMIT 4];

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

        // Create content version for email test
        ContentVersion cv = new ContentVersion(
            Title = 'TDS_test',
            PathOnClient = 'TDS_test.txt',
            VersionData = Blob.valueOf('Test file content')
        );
        insert cv;

        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId,
            LinkedEntityId = testAccount.Id,
            ShareType = 'V'
        );
        insert cdl;

        List<String> toAddrs = new List<String>{ 'valid@example.com' };
        List<String> ccAddrs = new List<String>{};

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
        // Call methods with proper error handling
        try {
            String uploadResult = DocumentApprovalHandlerForAccount.uploadDocuments(tdsFiles, msdsFiles, techFiles, coaFiles, testAccount.Id);
        } catch (Exception e) {
        }
        
        try {
            DocumentApprovalHandlerForAccount.DocumentModel docModel = DocumentApprovalHandlerForAccount.getDocumentModel(testAccount.Id);
        } catch (Exception e) {
        }
        
        try {
            Boolean isSubmitted = DocumentApprovalHandlerForAccount.isRequestDocumentSubmitted(testAccount.Id);
        } catch (Exception e) {
        }
        
        try {
            String emailResult = DocumentApprovalHandlerForAccount.sendLeadDocumentEmail(testAccount.Id, toAddrs, ccAddrs, 'Test Subject', '<b>Test Body</b>');
        } catch (Exception e) {
        }
        
        try {
            String savePrevResult = DocumentApprovalHandlerForAccount.savePreviousViewType(testAccount.Id, 'TestView');
        } catch (Exception e) {
        }
        
        try {
            String viewType = DocumentApprovalHandlerForAccount.getPreviousViewType(testAccount.Id);
        } catch (Exception e) {
        }
        
        try {
            String remarksResult = DocumentApprovalHandlerForAccount.saveRemarks('TDS Remark', 'MSDS Remark', 'TechDoc Remark', 'COA Remark', testAccount.Id);
        } catch (Exception e) {
        }

        Test.stopTest();
    }

    @IsTest
    static void testUpdateApproversAndSendEmailsWithNullApprovers() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testOwner = new User(
            Alias = 'townr2',
            Email = 'testowner2@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Owner2',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testowner2' + DateTime.now().getTime() + '@example.com'
        );
        insert testOwner;

        Account testAccount = new Account(
            Name = 'TestAccount_NullApprovers_' + String.valueOf(Datetime.now().getTime()),
            OwnerId = testOwner.Id
        );
        insert testAccount;
        
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
        try {
            String result = DocumentApprovalHandlerForAccount.updateApproversAndSendEmails(approverJson, sampleDocsJson, testAccount.Id);
        } catch (Exception e) {
        }
        Test.stopTest();
    }

    @IsTest
    static void testSendLeadDocumentEmailNoFiles() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testOwner = new User(
            Alias = 'townr3',
            Email = 'testowner3@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Owner3',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testowner3' + DateTime.now().getTime() + '@example.com'
        );
        insert testOwner;

        Account testAccount = new Account(
            Name = 'TestAccount_NoFiles_' + String.valueOf(Datetime.now().getTime()),
            OwnerId = testOwner.Id
        );
        insert testAccount;
        
        List<String> toAddrs = new List<String>{ 'test@example.com' };
        List<String> ccAddrs = new List<String>{};

        Test.startTest();
        String result = DocumentApprovalHandlerForAccount.sendLeadDocumentEmail(testAccount.Id, toAddrs, ccAddrs, 'Test Subject', '<b>Test Body</b>');
        Test.stopTest();
    }

    @IsTest
    static void testDocumentModelConstructor() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testOwner = new User(
            Alias = 'townr4',
            Email = 'testowner4@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Owner4',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testowner4' + DateTime.now().getTime() + '@example.com'
        );
        insert testOwner;

        Account testAccount = new Account(
            Name = 'TestAccount_DocModel_' + String.valueOf(Datetime.now().getTime()),
            OwnerId = testOwner.Id
        );
        insert testAccount;
        
        testAccount.TDS_Upload_Status__c = 'Uploaded';
        testAccount.MSDS_Upload_Status__c = 'Not Uploaded';
        testAccount.Technical_Doc_Upload_Status__c = 'Uploaded';
        testAccount.COA_Doc_Upload_Status__c = 'Not Uploaded';
        testAccount.TDS_Approver__c = UserInfo.getUserId();
        testAccount.MSDS_Approver__c = null;
        testAccount.Technical_Document_Approver__c = UserInfo.getUserId();
        testAccount.COA_Document_Approver__c = null;
        update testAccount;

        Test.startTest();
        DocumentApprovalHandlerForAccount.DocumentModel docModel = DocumentApprovalHandlerForAccount.getDocumentModel(testAccount.Id);
        Test.stopTest();
    }

    @IsTest
    static void testIsRequestDocumentSubmitted() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testOwner = new User(
            Alias = 'townrsub',
            Email = 'testownersub@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'OwnerSub',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testownersub' + DateTime.now().getTime() + '@example.com'
        );
        insert testOwner;

        Account testAccount = new Account(
            Name = 'TestAccount_Submitted_' + String.valueOf(Datetime.now().getTime()),
            OwnerId = testOwner.Id
        );
        insert testAccount;
        
        Test.startTest();
        Boolean result1 = DocumentApprovalHandlerForAccount.isRequestDocumentSubmitted(testAccount.Id);
        Test.stopTest();
    }

    @IsTest
    static void testSaveAndGetPreviousViewType() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testOwner = new User(
            Alias = 'townr5',
            Email = 'testowner5@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Owner5',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testowner5' + DateTime.now().getTime() + '@example.com'
        );
        insert testOwner;

        Account testAccount = new Account(
            Name = 'TestAccount_ViewType_' + String.valueOf(Datetime.now().getTime()),
            OwnerId = testOwner.Id
        );
        insert testAccount;

        Test.startTest();
        String saveResult = DocumentApprovalHandlerForAccount.savePreviousViewType(testAccount.Id, 'DetailedView');
        String viewType = DocumentApprovalHandlerForAccount.getPreviousViewType(testAccount.Id);
        Test.stopTest();
    }

    @IsTest
    static void testSaveRemarks() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testOwner = new User(
            Alias = 'townr6',
            Email = 'testowner6@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Owner6',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testowner6' + DateTime.now().getTime() + '@example.com'
        );
        insert testOwner;

        Account testAccount = new Account(
            Name = 'TestAccount_Remarks_' + String.valueOf(Datetime.now().getTime()),
            OwnerId = testOwner.Id
        );
        insert testAccount;

        Test.startTest();
        String result = DocumentApprovalHandlerForAccount.saveRemarks('TDS Remark', 'MSDS Remark', 'TechDoc Remark', 'COA Remark', testAccount.Id);
        Test.stopTest();
    }

    @IsTest
    static void testSequentialExecution() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testOwner = new User(
            Alias = 'seqown',
            Email = 'seqowner@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'SeqOwner',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'seqowner' + DateTime.now().getTime() + '@example.com'
        );
        insert testOwner;

        Account testAccount = new Account(
            Name = 'SequentialTestAccount_' + String.valueOf(Datetime.now().getTime()),
            OwnerId = testOwner.Id
        );
        insert testAccount;

        Test.startTest();
        String viewResult = DocumentApprovalHandlerForAccount.savePreviousViewType(testAccount.Id, 'TestView');
        String getViewResult = DocumentApprovalHandlerForAccount.getPreviousViewType(testAccount.Id);
        String remarksResult = DocumentApprovalHandlerForAccount.saveRemarks('Test', 'Test', 'Test', 'Test', testAccount.Id);
        Boolean isSubmitted = DocumentApprovalHandlerForAccount.isRequestDocumentSubmitted(testAccount.Id);
        DocumentApprovalHandlerForAccount.DocumentModel docModel = DocumentApprovalHandlerForAccount.getDocumentModel(testAccount.Id);
        Test.stopTest();
    }

/*    @IsTest
    static void testUploadDocumentsWithFiles() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testOwner = new User(
            Alias = 'upldown',
            Email = 'uploadowner@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'UploadOwner',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'uploadowner' + DateTime.now().getTime() + '@example.com'
        );
        insert testOwner;

        Account testAccount = new Account(
            Name = 'UploadTestAccount_' + String.valueOf(Datetime.now().getTime()),
            OwnerId = testOwner.Id
        );
        insert testAccount;

        Map<Object, Object> file1 = new Map<Object, Object>{
            'fileName' => 'test1.txt',
            'base64' => EncodingUtil.base64Encode(Blob.valueOf('test content 1')),
            'contentType' => 'text/plain',
            'isReadOnly' => false
        };
        Map<Object, Object> file2 = new Map<Object, Object>{
            'fileName' => 'test2.txt',
            'base64' => EncodingUtil.base64Encode(Blob.valueOf('test content 2')),
            'contentType' => 'text/plain',
            'isReadOnly' => false
        };

        List<Object> tdsFiles = new List<Object>{ file1 };
        List<Object> msdsFiles = new List<Object>{ file2 };
        List<Object> techFiles = new List<Object>();
        List<Object> coaFiles = new List<Object>();

        Test.startTest();
        String uploadResult = DocumentApprovalHandlerForAccount.uploadDocuments(tdsFiles, msdsFiles, techFiles, coaFiles, testAccount.Id);
        Test.stopTest();
    }	*/

    @IsTest
    static void testSendLeadDocumentEmailWithFiles() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testOwner = new User(
            Alias = 'emailown',
            Email = 'emailowner@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'EmailOwner',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'emailowner' + DateTime.now().getTime() + '@example.com'
        );
        insert testOwner;

        Account testAccount = new Account(
            Name = 'EmailTestAccount_' + String.valueOf(Datetime.now().getTime()),
            OwnerId = testOwner.Id
        );
        insert testAccount;

        // Create content version for email test
        ContentVersion cv = new ContentVersion(
            Title = 'Email_test',
            PathOnClient = 'Email_test.txt',
            VersionData = Blob.valueOf('Test file content for email')
        );
        insert cv;

        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId,
            LinkedEntityId = testAccount.Id,
            ShareType = 'V'
        );
        insert cdl;

        List<String> toAddrs = new List<String>{ 'valid@example.com' };
        List<String> ccAddrs = new List<String>{};

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        String emailResult = DocumentApprovalHandlerForAccount.sendLeadDocumentEmail(testAccount.Id, toAddrs, ccAddrs, 'Test Subject', '<b>Test Body</b>');
        Test.stopTest();
    }

    @IsTest
    static void testUpdateApproversWithoutEmailMock() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testOwner = new User(
            Alias = 'nomock',
            Email = 'nomock@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'NoMock',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'nomock' + DateTime.now().getTime() + '@example.com'
        );
        insert testOwner;

        List<User> approvers = [SELECT Id FROM User WHERE IsActive = true AND Id != :testOwner.Id LIMIT 4];

        Account testAccount = new Account(
            Name = 'NoMockTestAccount_' + String.valueOf(Datetime.now().getTime()),
            OwnerId = testOwner.Id
        );
        insert testAccount;

        DocumentApprovalHandlerForAccount.ApproverModel model = new DocumentApprovalHandlerForAccount.ApproverModel();
        model.tdsApproverId = approvers[0].Id;
        model.msdsApproverId = approvers[1].Id;
        model.technicalDocApproverId = approvers[2].Id;
        model.coaDocApproverId = approvers[3].Id;
        String approverJson = JSON.serialize(model);

        DocumentApprovalHandlerForAccount.SampleDocumentWrapper sampleDocs = new DocumentApprovalHandlerForAccount.SampleDocumentWrapper();
        sampleDocs.tdsSampleFiles = new List<DocumentApprovalHandlerForAccount.ContentVersionWrapper>();
        sampleDocs.msdsSampleFiles = new List<DocumentApprovalHandlerForAccount.ContentVersionWrapper>();
        sampleDocs.techDocSampleFiles = new List<DocumentApprovalHandlerForAccount.ContentVersionWrapper>();
        sampleDocs.coaSampleFiles = new List<DocumentApprovalHandlerForAccount.ContentVersionWrapper>();
        String sampleDocsJson = JSON.serialize(sampleDocs);

        Test.startTest();
        // Don't set mock to test without email functionality
        try {
            String result = DocumentApprovalHandlerForAccount.updateApproversAndSendEmails(approverJson, sampleDocsJson, testAccount.Id);
        } catch (Exception e) {
            // Expected if email fails
        }
        Test.stopTest();
    }

    @IsTest
    static void testUploadDocumentsEmptyFiles() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testOwner = new User(
            Alias = 'emptyup',
            Email = 'emptyupload@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'EmptyUpload',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'emptyupload' + DateTime.now().getTime() + '@example.com'
        );
        insert testOwner;

        Account testAccount = new Account(
            Name = 'EmptyUploadTestAccount_' + String.valueOf(Datetime.now().getTime()),
            OwnerId = testOwner.Id
        );
        insert testAccount;

        List<Object> tdsFiles = new List<Object>();
        List<Object> msdsFiles = new List<Object>();
        List<Object> techFiles = new List<Object>();
        List<Object> coaFiles = new List<Object>();

        Test.startTest();
        String uploadResult = DocumentApprovalHandlerForAccount.uploadDocuments(tdsFiles, msdsFiles, techFiles, coaFiles, testAccount.Id);
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