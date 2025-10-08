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
        // Query existing lead and users
        Lead leadRecord = [SELECT Id, Owner.Email, Previous_View_Type__c FROM Lead LIMIT 1];
        List<User> activeUsers = [SELECT Id FROM User WHERE IsActive = true LIMIT 5];

        DocumentApprovalHandler.ApproverModel model = new DocumentApprovalHandler.ApproverModel();
        model.tdsApproverId = activeUsers[0].Id;
        model.msdsApproverId = activeUsers[1].Id;
        model.technicalDocApproverId = activeUsers[2].Id;
        model.coaDocApproverId = activeUsers[3].Id;
        String json = JSON.serialize(model);

        // Prepare files for upload
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

        // Prepare email test data
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

        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId,
            LinkedEntityId = newLead.Id,
            ShareType = 'V'
        );
        insert cdl;

        List<String> toAddrs = new List<String>{ testOwner.Email };
        List<String> ccAddrs = new List<String>{};

        Test.startTest();

        // Call all the methods to test
        String res = DocumentApprovalHandler.updateApproversAndSendEmails(json, leadRecord.Id);
        String uploadResult = DocumentApprovalHandler.uploadDocuments(tdsFiles, msdsFiles, techFiles, coaFiles, leadRecord.Id);
        DocumentApprovalHandler.DocumentModel docModel = DocumentApprovalHandler.getDocumentModel(leadRecord.Id);
        Boolean isSubmitted = DocumentApprovalHandler.isRequestDocumentSubmitted(leadRecord.Id);
        String emailResult = DocumentApprovalHandler.sendLeadDocumentEmail(newLead.Id, toAddrs, ccAddrs, 'Test Subject', '<b>Test Body</b>');
        String savePrevResult = DocumentApprovalHandler.savePreviousViewType(leadRecord.Id, 'TestView');
        String viewType = DocumentApprovalHandler.getPreviousViewType(leadRecord.Id);
        update new Lead(Id=leadRecord.Id, Previous_View_Type__c = null);
        String nullViewType = DocumentApprovalHandler.getPreviousViewType(leadRecord.Id);
        String remarksResult = DocumentApprovalHandler.saveRemarks('TDS Remark', 'MSDS Remark', 'TechDoc Remark', 'COA Remark', leadRecord.Id);

        Test.stopTest();

        // No assertions as per request
    }
}