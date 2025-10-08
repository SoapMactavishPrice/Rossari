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
        
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            Contact__c = testContact.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Company__c = 'Test Company',
            TDS_Upload_Status__c = 'Uploaded',
            MSDS_Upload_Status__c = 'Uploaded',
            Technical_Doc_Upload_Status__c = 'Uploaded',
            COA_Doc_Upload_Status__c = 'Not Uploaded',
            OwnerId = UserInfo.getUserId()
        );
        insert testOpp;
    }
    
    @IsTest
    static void testUpdateApproversAndSendEmails() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        User testUser1 = [SELECT Id FROM User WHERE Email = 'testuser1@test.com'];
        User testUser2 = [SELECT Id FROM User WHERE Email = 'testuser2@test.com'];
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Map<String, Object> approversMap = new Map<String, Object>();
        approversMap.put('tdsApproverId', testUser1.Id);
        approversMap.put('msdsApproverId', testUser1.Id);
        approversMap.put('technicalDocApproverId', testUser2.Id);
        approversMap.put('coaDocApproverId', testUser2.Id);
        
        String approverString = JSON.serialize(approversMap);
        
        Test.startTest();
        String result = DocumentApprovalHandlerForOpp.updateApproversAndSendEmails(approverString, testOpp.Id);
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdateApproversAndSendEmailsWithNullApprovers() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Map<String, Object> approversMap = new Map<String, Object>();
        
        String approverString = JSON.serialize(approversMap);
        
        Test.startTest();
        String result = DocumentApprovalHandlerForOpp.updateApproversAndSendEmails(approverString, testOpp.Id);
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdateApproversAndSendEmailsWithException() {
        Test.startTest();
        try {
            String result = DocumentApprovalHandlerForOpp.updateApproversAndSendEmails('invalid json', 'invalid id');
        } catch (Exception e) {
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testUploadDocumentsAllFiles() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        List<Object> tdsFiles = new List<Object>();
        Map<String, Object> tdsFile = new Map<String, Object>();
        tdsFile.put('fileName', 'test_tds.pdf');
        tdsFile.put('base64', 'base64encodedstring');
        tdsFile.put('contentType', 'application/pdf');
        tdsFile.put('isReadOnly', false);
        tdsFiles.add(tdsFile);
        
        List<Object> msdsFiles = new List<Object>();
        Map<String, Object> msdsFile = new Map<String, Object>();
        msdsFile.put('fileName', 'test_msds.pdf');
        msdsFile.put('base64', 'base64encodedstring');
        msdsFile.put('contentType', 'application/pdf');
        msdsFile.put('isReadOnly', false);
        msdsFiles.add(msdsFile);
        
        List<Object> technicalDocumentFiles = new List<Object>();
        Map<String, Object> techFile = new Map<String, Object>();
        techFile.put('fileName', 'test_tech.pdf');
        techFile.put('base64', 'base64encodedstring');
        techFile.put('contentType', 'application/pdf');
        techFile.put('isReadOnly', false);
        technicalDocumentFiles.add(techFile);
        
        List<Object> coaDocumentFiles = new List<Object>();
        Map<String, Object> coaFile = new Map<String, Object>();
        coaFile.put('fileName', 'test_coa.pdf');
        coaFile.put('base64', 'base64encodedstring');
        coaFile.put('contentType', 'application/pdf');
        coaFile.put('isReadOnly', false);
        coaDocumentFiles.add(coaFile);
        
        Test.startTest();
        String result = DocumentApprovalHandlerForOpp.uploadDocuments(tdsFiles, msdsFiles, technicalDocumentFiles, coaDocumentFiles, testOpp.Id);
        Test.stopTest();
    }
    
    @IsTest
    static void testUploadDocumentsWithReadOnlyFiles() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        List<Object> tdsFiles = new List<Object>();
        Map<String, Object> tdsFile = new Map<String, Object>();
        tdsFile.put('fileName', 'test_tds.pdf');
        tdsFile.put('base64', 'base64encodedstring');
        tdsFile.put('contentType', 'application/pdf');
        tdsFile.put('isReadOnly', true);
        tdsFiles.add(tdsFile);
        
        List<Object> msdsFiles = new List<Object>();
        Map<String, Object> msdsFile = new Map<String, Object>();
        msdsFile.put('fileName', 'test_msds.pdf');
        msdsFile.put('base64', 'base64encodedstring');
        msdsFile.put('contentType', 'application/pdf');
        msdsFile.put('isReadOnly', true);
        msdsFiles.add(msdsFile);
        
        Test.startTest();
        String result = DocumentApprovalHandlerForOpp.uploadDocuments(tdsFiles, msdsFiles, null, null, testOpp.Id);
        Test.stopTest();
    }
    
    @IsTest
    static void testUploadDocumentsEmptyFiles() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        String result = DocumentApprovalHandlerForOpp.uploadDocuments(null, null, null, null, testOpp.Id);
        Test.stopTest();
    }
    
    @IsTest
    static void testUploadDocumentsMixedFiles() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        List<Object> tdsFiles = new List<Object>();
        Map<String, Object> tdsFile1 = new Map<String, Object>();
        tdsFile1.put('fileName', 'test_tds1.pdf');
        tdsFile1.put('base64', 'base64encodedstring');
        tdsFile1.put('contentType', 'application/pdf');
        tdsFile1.put('isReadOnly', false);
        tdsFiles.add(tdsFile1);
        
        Map<String, Object> tdsFile2 = new Map<String, Object>();
        tdsFile2.put('fileName', 'test_tds2.pdf');
        tdsFile2.put('base64', 'base64encodedstring');
        tdsFile2.put('contentType', 'application/pdf');
        tdsFile2.put('isReadOnly', true);
        tdsFiles.add(tdsFile2);
        
        Test.startTest();
        String result = DocumentApprovalHandlerForOpp.uploadDocuments(tdsFiles, null, null, null, testOpp.Id);
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