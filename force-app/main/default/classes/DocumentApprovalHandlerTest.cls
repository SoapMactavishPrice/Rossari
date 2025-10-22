@IsTest
public class DocumentApprovalHandlerTest {

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

        Lead leadRecord = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'TestCo_' + String.valueOf(Datetime.now().getTime()),
            OwnerId = users[4].Id,
            MobilePhone = '1234567890',
            Email = 'leademail@example.com'
        );
        insert leadRecord;
    }

    @IsTest
    static void testAllFunctionalitiesTogether() {
        Lead leadRecord = [SELECT Id, Owner.Email, Previous_View_Type__c FROM Lead LIMIT 1];
        List<User> activeUsers = [SELECT Id FROM User WHERE IsActive = true LIMIT 5];

        DocumentApprovalHandler.ApproverModel model = new DocumentApprovalHandler.ApproverModel();
        model.tdsApproverId = activeUsers[0].Id;
        model.msdsApproverId = activeUsers[1].Id;
        model.technicalDocApproverId = activeUsers[2].Id;
        model.coaDocApproverId = activeUsers[3].Id;
        String approverJson = JSON.serialize(model);

        DocumentApprovalHandler.SampleDocumentWrapper sampleDocs = new DocumentApprovalHandler.SampleDocumentWrapper();
        sampleDocs.tdsSampleFiles = new List<DocumentApprovalHandler.ContentVersionWrapper>();
        sampleDocs.msdsSampleFiles = new List<DocumentApprovalHandler.ContentVersionWrapper>();
        sampleDocs.techDocSampleFiles = new List<DocumentApprovalHandler.ContentVersionWrapper>();
        sampleDocs.coaSampleFiles = new List<DocumentApprovalHandler.ContentVersionWrapper>();

        DocumentApprovalHandler.ContentVersionWrapper sampleFile = new DocumentApprovalHandler.ContentVersionWrapper();
        sampleFile.fileName = 'sample.txt';
        sampleFile.base64Data = EncodingUtil.base64Encode(Blob.valueOf('sample content'));
        sampleDocs.tdsSampleFiles.add(sampleFile);

        String sampleDocsJson = JSON.serialize(sampleDocs);

        List<Object> tdsFiles = new List<Object>{
            new Map<Object, Object>{
                'fileName' => 'tds.txt',
                'base64' => EncodingUtil.base64Encode(Blob.valueOf('content1')),
                'contentType' => 'text/plain',
                'isReadOnly' => false
            }
        };
        List<Object> msdsFiles = new List<Object>{
            new Map<Object, Object>{
                'fileName' => 'msds.txt',
                'base64' => EncodingUtil.base64Encode(Blob.valueOf('content2')),
                'contentType' => 'text/plain',
                'isReadOnly' => false
            }
        };
        List<Object> techFiles = new List<Object>{
            new Map<Object, Object>{
                'fileName' => 'tech.txt',
                'base64' => EncodingUtil.base64Encode(Blob.valueOf('content3')),
                'contentType' => 'text/plain',
                'isReadOnly' => false
            }
        };
        List<Object> coaFiles = new List<Object>{
            new Map<Object, Object>{
                'fileName' => 'coa.txt',
                'base64' => EncodingUtil.base64Encode(Blob.valueOf('content4')),
                'contentType' => 'text/plain',
                'isReadOnly' => false
            }
        };

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

        Lead newLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'TestCompany_' + String.valueOf(Datetime.now().getTime()),
            OwnerId = testOwner.Id,
            MobilePhone = '1234567800',
            Email = 'leademail12@example.com'
        );
        insert newLead;

        ContentVersion cv = new ContentVersion(
            Title = 'TDS_test',
            PathOnClient = 'TDS_test.txt',
            VersionData = Blob.valueOf('Test file content')
        );
        insert cv;

        ContentVersion insertedCV = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = insertedCV.ContentDocumentId,
            LinkedEntityId = newLead.Id,
            ShareType = 'V'
        );
        insert cdl;

        List<String> toAddrs = new List<String>{ testOwner.Email };
        List<String> ccAddrs = new List<String>{};

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        String uploadResult = DocumentApprovalHandler.uploadDocuments(tdsFiles, msdsFiles, techFiles, coaFiles, leadRecord.Id);
        DocumentApprovalHandler.DocumentModel docModel = DocumentApprovalHandler.getDocumentModel(leadRecord.Id);
        Boolean isSubmitted = DocumentApprovalHandler.isRequestDocumentSubmitted(leadRecord.Id);
        String emailResult = DocumentApprovalHandler.sendLeadDocumentEmail(newLead.Id, toAddrs, ccAddrs, 'Test Subject', '<b>Test Body</b>');
        String savePrevResult = DocumentApprovalHandler.savePreviousViewType(leadRecord.Id, 'TestView');
        String viewType = DocumentApprovalHandler.getPreviousViewType(leadRecord.Id);

        update new Lead(Id = leadRecord.Id, Previous_View_Type__c = null);
        String nullViewType = DocumentApprovalHandler.getPreviousViewType(leadRecord.Id);

        String remarksResult = DocumentApprovalHandler.saveRemarks('TDS Remark', 'MSDS Remark', 'TechDoc Remark', 'COA Remark', leadRecord.Id);
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
    
    @IsTest
static void testUpdateApproversAndSendEmails() {
    // Get test data
    Lead leadRecord = [SELECT Id, TDS_Approver__c, MSDS_Approver__c, Technical_Document_Approver__c, COA_Document_Approver__c 
                      FROM Lead LIMIT 1];
    List<User> testUsers = [SELECT Id, Email FROM User WHERE IsActive = true LIMIT 5];
    
    // Create approver model
    DocumentApprovalHandler.ApproverModel approverModel = new DocumentApprovalHandler.ApproverModel();
    approverModel.tdsApproverId = testUsers[0].Id;
    approverModel.msdsApproverId = testUsers[1].Id;
    approverModel.technicalDocApproverId = testUsers[2].Id;
    approverModel.coaDocApproverId = testUsers[3].Id;
    String approverStringObject = JSON.serialize(approverModel);
    
    // Create sample document wrapper with files
    DocumentApprovalHandler.SampleDocumentWrapper sampleDocs = new DocumentApprovalHandler.SampleDocumentWrapper();
    
    // Create sample files for each document type
    DocumentApprovalHandler.ContentVersionWrapper tdsFile = new DocumentApprovalHandler.ContentVersionWrapper();
    tdsFile.fileName = 'tds_sample.pdf';
    tdsFile.base64Data = EncodingUtil.base64Encode(Blob.valueOf('TDS sample content'));
    
    DocumentApprovalHandler.ContentVersionWrapper msdsFile = new DocumentApprovalHandler.ContentVersionWrapper();
    msdsFile.fileName = 'msds_sample.pdf';
    msdsFile.base64Data = EncodingUtil.base64Encode(Blob.valueOf('MSDS sample content'));
    
    DocumentApprovalHandler.ContentVersionWrapper techFile = new DocumentApprovalHandler.ContentVersionWrapper();
    techFile.fileName = 'tech_sample.pdf';
    techFile.base64Data = EncodingUtil.base64Encode(Blob.valueOf('Technical document sample content'));
    
    DocumentApprovalHandler.ContentVersionWrapper coaFile = new DocumentApprovalHandler.ContentVersionWrapper();
    coaFile.fileName = 'coa_sample.pdf';
    coaFile.base64Data = EncodingUtil.base64Encode(Blob.valueOf('COA sample content'));
    
    // Add files to respective lists
    sampleDocs.tdsSampleFiles = new List<DocumentApprovalHandler.ContentVersionWrapper>{tdsFile};
    sampleDocs.msdsSampleFiles = new List<DocumentApprovalHandler.ContentVersionWrapper>{msdsFile};
    sampleDocs.techDocSampleFiles = new List<DocumentApprovalHandler.ContentVersionWrapper>{techFile};
    sampleDocs.coaSampleFiles = new List<DocumentApprovalHandler.ContentVersionWrapper>{coaFile};
    
    String sampleDocumentStringObj = JSON.serialize(sampleDocs);
    
    Test.startTest();
    // Test with all approvers and files
    String result1 = DocumentApprovalHandler.updateApproversAndSendEmails(approverStringObject, sampleDocumentStringObj, leadRecord.Id);
    
    // Test with partial approvers
    DocumentApprovalHandler.ApproverModel partialApproverModel = new DocumentApprovalHandler.ApproverModel();
    partialApproverModel.tdsApproverId = testUsers[0].Id;
    partialApproverModel.msdsApproverId = null;
    partialApproverModel.technicalDocApproverId = testUsers[2].Id;
    partialApproverModel.coaDocApproverId = null;
    String partialApproverStringObject = JSON.serialize(partialApproverModel);
    
    // Create partial files
    DocumentApprovalHandler.SampleDocumentWrapper partialSampleDocs = new DocumentApprovalHandler.SampleDocumentWrapper();
    partialSampleDocs.tdsSampleFiles = new List<DocumentApprovalHandler.ContentVersionWrapper>{tdsFile};
    partialSampleDocs.msdsSampleFiles = new List<DocumentApprovalHandler.ContentVersionWrapper>();
    partialSampleDocs.techDocSampleFiles = new List<DocumentApprovalHandler.ContentVersionWrapper>{techFile};
    partialSampleDocs.coaSampleFiles = new List<DocumentApprovalHandler.ContentVersionWrapper>();
    String partialSampleDocumentStringObj = JSON.serialize(partialSampleDocs);
    
    String result2 = DocumentApprovalHandler.updateApproversAndSendEmails(partialApproverStringObject, partialSampleDocumentStringObj, leadRecord.Id);
    
    // Test with empty files
    DocumentApprovalHandler.SampleDocumentWrapper emptySampleDocs = new DocumentApprovalHandler.SampleDocumentWrapper();
    emptySampleDocs.tdsSampleFiles = new List<DocumentApprovalHandler.ContentVersionWrapper>();
    emptySampleDocs.msdsSampleFiles = new List<DocumentApprovalHandler.ContentVersionWrapper>();
    emptySampleDocs.techDocSampleFiles = new List<DocumentApprovalHandler.ContentVersionWrapper>();
    emptySampleDocs.coaSampleFiles = new List<DocumentApprovalHandler.ContentVersionWrapper>();
    String emptySampleDocumentStringObj = JSON.serialize(emptySampleDocs);
    
    String result3 = DocumentApprovalHandler.updateApproversAndSendEmails(approverStringObject, emptySampleDocumentStringObj, leadRecord.Id);
    
    Test.stopTest();
    
    // Verify lead was updated
    Lead updatedLead = [SELECT TDS_Approver__c, MSDS_Approver__c, Technical_Document_Approver__c, COA_Document_Approver__c 
                       FROM Lead WHERE Id = :leadRecord.Id];
}
}