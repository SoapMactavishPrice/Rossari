@IsTest
public class DocumentApprovalHandlerTest {

    @TestSetup
    static void setupTestData() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        List<User> users = new List<User>{
            new User(FirstName='Test', LastName='User1', Alias='tuser1', Email='tuser1@example.com',
                     Username='tuser1' + System.currentTimeMillis() + '@example.com', ProfileId=p.Id,
                     TimeZoneSidKey='Asia/Kolkata', LocaleSidKey='en_US', EmailEncodingKey='UTF-8',
                     LanguageLocaleKey='en_US', IsActive=true),
            new User(FirstName='Test', LastName='User2', Alias='tuser2', Email='tuser2@example.com',
                     Username='tuser2' + System.currentTimeMillis() + '@example.com', ProfileId=p.Id,
                     TimeZoneSidKey='Asia/Kolkata', LocaleSidKey='en_US', EmailEncodingKey='UTF-8',
                     LanguageLocaleKey='en_US', IsActive=true),
            new User(FirstName='Test', LastName='User3', Alias='tuser3', Email='tuser3@example.com',
                     Username='tuser3' + System.currentTimeMillis() + '@example.com', ProfileId=p.Id,
                     TimeZoneSidKey='Asia/Kolkata', LocaleSidKey='en_US', EmailEncodingKey='UTF-8',
                     LanguageLocaleKey='en_US', IsActive=true)
        };
        insert users;
    }

    @IsTest
    static void testUpdateApproversAndSendEmails() {
        List<User> users = [SELECT Id FROM User WHERE IsActive=true ORDER BY CreatedDate ASC LIMIT 3];
        User u1 = users[0];
        User u2 = users[1];
        User u3 = users[2];

        Country__c country = new Country__c(Name='India');
        insert country;
        State__c state = new State__c(Name='Maharashtra', Country__c=country.Id);
        insert state;
        City__c city = new City__c(Name='Mumbai', State__c=state.Id);
        insert city;
        Pin_Code__c pin = new Pin_Code__c(Name='400001', City__c=city.Id);
        insert pin;
        Company__c company = new Company__c(Name='Rossari Biotech Limited');
        insert company;

        Lead leadRec = new Lead(
            FirstName='Test',
            LastName='Lead',
            Company='Test Company',
            OwnerId=u1.Id,
            Pin_Code__c=pin.Id,
            City__c=city.Id,
            State__c=state.Id,
            Rossari_Company__c=company.Id,
            MobilePhone='1234567890',
            Email='testlead@example.com',
            Status='Open - Not Contacted'
        );
        insert leadRec;

        DocumentApprovalHandler.ApproverModel approverModel = new DocumentApprovalHandler.ApproverModel();
        approverModel.tdsApproverId = u1.Id;
        approverModel.msdsApproverId = u2.Id;
        approverModel.technicalDocApproverId = u3.Id;
        String approverJson = JSON.serialize(approverModel);

        Test.startTest();
        DocumentApprovalHandler.updateApproversAndSendEmails(approverJson, leadRec.Id);
        Test.stopTest();
    }

    @IsTest
    static void testUploadDocuments() {
        User u = [SELECT Id FROM User WHERE IsActive=true ORDER BY CreatedDate ASC LIMIT 1];

        Country__c country = new Country__c(Name='India');
        insert country;
        State__c state = new State__c(Name='Maharashtra', Country__c=country.Id);
        insert state;
        City__c city = new City__c(Name='Mumbai', State__c=state.Id);
        insert city;
        Pin_Code__c pin = new Pin_Code__c(Name='400001', City__c=city.Id);
        insert pin;
        Company__c company = new Company__c(Name='Rossari Biotech Limited');
        insert company;

        Lead leadRec = new Lead(
            FirstName='Test',
            LastName='Lead',
            Company='Test Company',
            OwnerId=u.Id,
            Pin_Code__c=pin.Id,
            City__c=city.Id,
            State__c=state.Id,
            Rossari_Company__c=company.Id,
            MobilePhone='1234567890',
            Email='testlead@example.com',
            Status='Open - Not Contacted'
        );
        insert leadRec;

        List<Object> tdsFiles = new List<Object>{ new Map<Object,Object>{
            'fileName' => 'tdsfile.txt', 
            'base64' => EncodingUtil.base64Encode(Blob.valueOf('Test Content')),
            'contentType' => 'text/plain', 
            'isReadOnly' => false
        }};
        List<Object> msdsFiles = new List<Object>{ new Map<Object,Object>{
            'fileName' => 'msdsfile.txt', 
            'base64' => EncodingUtil.base64Encode(Blob.valueOf('Test Content')),
            'contentType' => 'text/plain', 
            'isReadOnly' => false
        }};
        List<Object> techFiles = new List<Object>{ new Map<Object,Object>{
            'fileName' => 'techfile.txt', 
            'base64' => EncodingUtil.base64Encode(Blob.valueOf('Test Content')),
            'contentType' => 'text/plain', 
            'isReadOnly' => false
        }};

        Test.startTest();
        DocumentApprovalHandler.uploadDocuments(tdsFiles, msdsFiles, techFiles, leadRec.Id);
        Test.stopTest();
    }
}