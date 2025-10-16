@IsTest
public class DocumentApprovalHandlerForOppTest {
    
    @TestSetup
    static void setupTestData() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Contact testContact = new Contact(LastName = 'Test Contact', AccountId = testAccount.Id);
        insert testContact;
        
        User testUser1 = new User(
            FirstName = 'Test1',
            LastName = 'User1',
            Email = 'testuser1@test.com',
            Username = 'testuser1@test.com.testorg',
            Alias = 'tuser1',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testUser1;
        
        User testUser2 = new User(
            FirstName = 'Test2',
            LastName = 'User2',
            Email = 'testuser2@test.com',
            Username = 'testuser2@test.com.testorg',
            Alias = 'tuser2',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testUser2;
    }

    static void createDynamicTestData() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        User testUser1 = [SELECT Id FROM User WHERE Email = 'testuser1@test.com'];
        User testUser2 = [SELECT Id FROM User WHERE Email = 'testuser2@test.com'];
        
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            Contact__c = testContact.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Company__c = 'Test Company',
            TDS_Upload_Status__c = 'Not Uploaded',
            MSDS_Upload_Status__c = 'Not Uploaded',
            Technical_Doc_Upload_Status__c = 'Not Uploaded',
            COA_Doc_Upload_Status__c = 'Not Uploaded',
            TDS_Approver__c = testUser1.Id,
            MSDS_Approver__c = testUser1.Id,
            Technical_Document_Approver__c = testUser2.Id,
            COA_Document_Approver__c = testUser2.Id,
            OwnerId = UserInfo.getUserId()
        );
        insert testOpp;
    }
    
    @IsTest
    static void testUpdateApproversAndSendEmails() {
        createDynamicTestData();
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        User testUser1 = [SELECT Id FROM User WHERE Email = 'testuser1@test.com'];
        User testUser2 = [SELECT Id FROM User WHERE Email = 'testuser2@test.com'];
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        DocumentApprovalHandlerForOpp.ApproverModel approvers = new DocumentApprovalHandlerForOpp.ApproverModel();
        approvers.tdsApproverId = testUser1.Id;
        approvers.msdsApproverId = testUser1.Id;
        approvers.technicalDocApproverId = testUser2.Id;
        approvers.coaDocApproverId = testUser2.Id;
        String approverString = JSON.serialize(approvers);
        
        DocumentApprovalHandlerForOpp.SampleDocumentWrapper sampleDocs = new DocumentApprovalHandlerForOpp.SampleDocumentWrapper();
        sampleDocs.tdsSampleFiles = new List<DocumentApprovalHandlerForOpp.ContentVersionWrapper>();
        sampleDocs.msdsSampleFiles = new List<DocumentApprovalHandlerForOpp.ContentVersionWrapper>();
        sampleDocs.techDocSampleFiles = new List<DocumentApprovalHandlerForOpp.ContentVersionWrapper>();
        sampleDocs.coaSampleFiles = new List<DocumentApprovalHandlerForOpp.ContentVersionWrapper>();
        
        DocumentApprovalHandlerForOpp.ContentVersionWrapper sampleFile = new DocumentApprovalHandlerForOpp.ContentVersionWrapper();
        sampleFile.fileName = 'sample.txt';
        sampleFile.base64Data = EncodingUtil.base64Encode(Blob.valueOf('sample content'));
        sampleDocs.tdsSampleFiles.add(sampleFile);
        
        String sampleDocsString = JSON.serialize(sampleDocs);
        
        Test.startTest();
        try {
            String result = DocumentApprovalHandlerForOpp.updateApproversAndSendEmails(approverString, sampleDocsString, testOpp.Id);
        } catch (Exception e) {
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdateApproversAndSendEmailsWithNullApprovers() {
        createDynamicTestData();
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        DocumentApprovalHandlerForOpp.ApproverModel approvers = new DocumentApprovalHandlerForOpp.ApproverModel();
        approvers.tdsApproverId = null;
        approvers.msdsApproverId = null;
        approvers.technicalDocApproverId = null;
        approvers.coaDocApproverId = null;
        String approverString = JSON.serialize(approvers);
        
        DocumentApprovalHandlerForOpp.SampleDocumentWrapper sampleDocs = new DocumentApprovalHandlerForOpp.SampleDocumentWrapper();
        sampleDocs.tdsSampleFiles = new List<DocumentApprovalHandlerForOpp.ContentVersionWrapper>();
        sampleDocs.msdsSampleFiles = new List<DocumentApprovalHandlerForOpp.ContentVersionWrapper>();
        sampleDocs.techDocSampleFiles = new List<DocumentApprovalHandlerForOpp.ContentVersionWrapper>();
        sampleDocs.coaSampleFiles = new List<DocumentApprovalHandlerForOpp.ContentVersionWrapper>();
        String sampleDocsString = JSON.serialize(sampleDocs);
        
        Test.startTest();
        try {
            String result = DocumentApprovalHandlerForOpp.updateApproversAndSendEmails(approverString, sampleDocsString, testOpp.Id);
        } catch (Exception e) {
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdateApproversAndSendEmailsWithException() {
        Test.startTest();
        try {
            String result = DocumentApprovalHandlerForOpp.updateApproversAndSendEmails('invalid json', 'invalid json', 'invalid id');
        } catch (Exception e) {
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testUploadDocumentsAllFiles() {
        createDynamicTestData();
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        List<Object> tdsFiles = new List<Object>();
        Map<Object, Object> tdsFile = new Map<Object, Object>();
        tdsFile.put('fileName', 'test_tds.pdf');
        tdsFile.put('base64', EncodingUtil.base64Encode(Blob.valueOf('test content')));
        tdsFile.put('contentType', 'application/pdf');
        tdsFile.put('isReadOnly', false);
        tdsFiles.add(tdsFile);
        
        List<Object> msdsFiles = new List<Object>();
        Map<Object, Object> msdsFile = new Map<Object, Object>();
        msdsFile.put('fileName', 'test_msds.pdf');
        msdsFile.put('base64', EncodingUtil.base64Encode(Blob.valueOf('test content')));
        msdsFile.put('contentType', 'application/pdf');
        msdsFile.put('isReadOnly', false);
        msdsFiles.add(msdsFile);
        
        List<Object> technicalDocumentFiles = new List<Object>();
        Map<Object, Object> techFile = new Map<Object, Object>();
        techFile.put('fileName', 'test_tech.pdf');
        techFile.put('base64', EncodingUtil.base64Encode(Blob.valueOf('test content')));
        techFile.put('contentType', 'application/pdf');
        techFile.put('isReadOnly', false);
        technicalDocumentFiles.add(techFile);
        
        List<Object> coaDocumentFiles = new List<Object>();
        Map<Object, Object> coaFile = new Map<Object, Object>();
        coaFile.put('fileName', 'test_coa.pdf');
        coaFile.put('base64', EncodingUtil.base64Encode(Blob.valueOf('test content')));
        coaFile.put('contentType', 'application/pdf');
        coaFile.put('isReadOnly', false);
        coaDocumentFiles.add(coaFile);
        
        Test.startTest();
        String result = DocumentApprovalHandlerForOpp.uploadDocuments(tdsFiles, msdsFiles, technicalDocumentFiles, coaDocumentFiles, testOpp.Id);
        Test.stopTest();
    }
    
    @IsTest
    static void testUploadDocumentsEmptyFiles() {
        createDynamicTestData();
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        List<Object> tdsFiles = new List<Object>();
        List<Object> msdsFiles = new List<Object>();
        List<Object> technicalDocumentFiles = new List<Object>();
        List<Object> coaDocumentFiles = new List<Object>();
        
        Test.startTest();
        String result = DocumentApprovalHandlerForOpp.uploadDocuments(tdsFiles, msdsFiles, technicalDocumentFiles, coaDocumentFiles, testOpp.Id);
        Test.stopTest();
    }
    
    @IsTest
    static void testUploadDocumentsMixedFiles() {
        createDynamicTestData();
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        List<Object> tdsFiles = new List<Object>();
        Map<Object, Object> tdsFile1 = new Map<Object, Object>();
        tdsFile1.put('fileName', 'test_tds1.pdf');
        tdsFile1.put('base64', EncodingUtil.base64Encode(Blob.valueOf('test content')));
        tdsFile1.put('contentType', 'application/pdf');
        tdsFile1.put('isReadOnly', false);
        tdsFiles.add(tdsFile1);
        
        Map<Object, Object> tdsFile2 = new Map<Object, Object>();
        tdsFile2.put('fileName', 'test_tds2.pdf');
        tdsFile2.put('base64', EncodingUtil.base64Encode(Blob.valueOf('test content')));
        tdsFile2.put('contentType', 'application/pdf');
        tdsFile2.put('isReadOnly', true);
        tdsFiles.add(tdsFile2);
        
        List<Object> msdsFiles = new List<Object>();
        List<Object> technicalDocumentFiles = new List<Object>();
        List<Object> coaDocumentFiles = new List<Object>();
        
        Test.startTest();
        String result = DocumentApprovalHandlerForOpp.uploadDocuments(tdsFiles, msdsFiles, technicalDocumentFiles, coaDocumentFiles, testOpp.Id);
        Test.stopTest();
    }

    @IsTest
    static void testGetDocumentModel() {
        createDynamicTestData();
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        DocumentApprovalHandlerForOpp.DocumentModel docModel = DocumentApprovalHandlerForOpp.getDocumentModel(testOpp.Id);
        Test.stopTest();
    }

    @IsTest
    static void testIsRequestDocumentSubmitted() {
        createDynamicTestData();
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        Boolean result1 = DocumentApprovalHandlerForOpp.isRequestDocumentSubmitted(testOpp.Id);
        Test.stopTest();
    }

    @IsTest
    static void testSendLeadDocumentEmail() {
        createDynamicTestData();
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        ContentVersion cv = new ContentVersion(
            Title = 'TDS_test.pdf',
            PathOnClient = 'TDS_test.pdf',
            VersionData = Blob.valueOf('Test file content')
        );
        insert cv;
        
        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = testOpp.Id,
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId,
            ShareType = 'V'
        );
        insert cdl;
        
        List<String> toAddrs = new List<String>{ 'test@example.com' };
        List<String> ccAddrs = new List<String>{};
        
        Test.startTest();
        String result = DocumentApprovalHandlerForOpp.sendLeadDocumentEmail(testOpp.Id, toAddrs, ccAddrs, 'Test Subject', '<b>Test Body</b>');
        Test.stopTest();
    }

    @IsTest
    static void testSendLeadDocumentEmailNoFiles() {
        createDynamicTestData();
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        List<String> toAddrs = new List<String>{ 'test@example.com' };
        List<String> ccAddrs = new List<String>{};
        
        Test.startTest();
        String result = DocumentApprovalHandlerForOpp.sendLeadDocumentEmail(testOpp.Id, toAddrs, ccAddrs, 'Test Subject', '<b>Test Body</b>');
        Test.stopTest();
    }

    @IsTest
    static void testSaveAndGetPreviousViewType() {
        createDynamicTestData();
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        String saveResult = DocumentApprovalHandlerForOpp.savePreviousViewType(testOpp.Id, 'DetailedView');
        String viewType = DocumentApprovalHandlerForOpp.getPreviousViewType(testOpp.Id);
        Test.stopTest();
    }

    @IsTest
    static void testGetPreviousViewTypeNull() {
        createDynamicTestData();
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        testOpp.Previous_View_Type__c = null;
        update testOpp;
        
        Test.startTest();
        String viewType = DocumentApprovalHandlerForOpp.getPreviousViewType(testOpp.Id);
        Test.stopTest();
    }

    @IsTest
    static void testSaveRemarks() {
        createDynamicTestData();
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        String result = DocumentApprovalHandlerForOpp.saveRemarks('TDS Remark', 'MSDS Remark', 'TechDoc Remark', 'COA Remark', testOpp.Id);
        Test.stopTest();
    }

    @IsTest
    static void testSaveRemarksWithNullValues() {
        createDynamicTestData();
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        String result = DocumentApprovalHandlerForOpp.saveRemarks(null, null, null, null, testOpp.Id);
        Test.stopTest();
    }

    @IsTest
    static void testUpdateApproversWithoutMock() {
        createDynamicTestData();
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        User testUser1 = [SELECT Id FROM User WHERE Email = 'testuser1@test.com'];
        
        DocumentApprovalHandlerForOpp.ApproverModel approvers = new DocumentApprovalHandlerForOpp.ApproverModel();
        approvers.tdsApproverId = testUser1.Id;
        approvers.msdsApproverId = testUser1.Id;
        approvers.technicalDocApproverId = testUser1.Id;
        approvers.coaDocApproverId = testUser1.Id;
        String approverString = JSON.serialize(approvers);
        
        DocumentApprovalHandlerForOpp.SampleDocumentWrapper sampleDocs = new DocumentApprovalHandlerForOpp.SampleDocumentWrapper();
        sampleDocs.tdsSampleFiles = new List<DocumentApprovalHandlerForOpp.ContentVersionWrapper>();
        sampleDocs.msdsSampleFiles = new List<DocumentApprovalHandlerForOpp.ContentVersionWrapper>();
        sampleDocs.techDocSampleFiles = new List<DocumentApprovalHandlerForOpp.ContentVersionWrapper>();
        sampleDocs.coaSampleFiles = new List<DocumentApprovalHandlerForOpp.ContentVersionWrapper>();
        String sampleDocsString = JSON.serialize(sampleDocs);
        
        Test.startTest();
        try {
            String result = DocumentApprovalHandlerForOpp.updateApproversAndSendEmails(approverString, sampleDocsString, testOpp.Id);
        } catch (Exception e) {
        }
        Test.stopTest();
    }

    @IsTest
    static void testUploadDocumentsSingleFileType() {
        createDynamicTestData();
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        List<Object> tdsFiles = new List<Object>();
        Map<Object, Object> tdsFile = new Map<Object, Object>();
        tdsFile.put('fileName', 'test_tds.pdf');
        tdsFile.put('base64', EncodingUtil.base64Encode(Blob.valueOf('test content')));
        tdsFile.put('contentType', 'application/pdf');
        tdsFile.put('isReadOnly', false);
        tdsFiles.add(tdsFile);
        
        List<Object> msdsFiles = new List<Object>();
        List<Object> technicalDocumentFiles = new List<Object>();
        List<Object> coaDocumentFiles = new List<Object>();
        
        Test.startTest();
        String result = DocumentApprovalHandlerForOpp.uploadDocuments(tdsFiles, msdsFiles, technicalDocumentFiles, coaDocumentFiles, testOpp.Id);
        Test.stopTest();
    }
    
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"success"}');
            res.setStatusCode(200);
            return res;
        }
    }
}