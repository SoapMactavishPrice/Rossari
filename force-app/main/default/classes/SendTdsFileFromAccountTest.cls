@IsTest
private class SendTdsFileFromAccountTest {

    @TestSetup
    static void setupTestData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser' + DateTime.now().getTime() + '@example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            Alias = 'tusr',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert u;

        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;


        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert testProduct;

        PricebookEntry standardPBE = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert standardPBE;

        Product_Interested__c pi = new Product_Interested__c(
            Account__c = acc.Id,
            Product__c = testProduct.Id
        );
        insert pi;

        Product_Document__c pd = new Product_Document__c(
            Name = 'Test Product Doc',
            Product__c = testProduct.Id
        );
        insert pd;

        ContentVersion cv = new ContentVersion(
            Title = 'TestFile',
            PathOnClient = 'TestFile.txt',
            VersionData = Blob.valueOf('Test Content')
        );
        insert cv;

        ContentVersion insertedCV = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = insertedCV.ContentDocumentId,
            LinkedEntityId = acc.Id,
            ShareType = 'V'
        );
        insert cdl;
    }

    @IsTest
    static void testGetEmailDetails() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Account result = SendTdsFileFromAccount.getEmailDetails(acc.Id);
    }

    @IsTest
    static void testGetLead() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        SendTdsFileFromAccount.LeadWrapper wrapper = SendTdsFileFromAccount.getLead(acc.Id);
    }

    @IsTest
    static void testGetProductData() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        String jsonData = SendTdsFileFromAccount.getProductData(acc.Id);
    }

    @IsTest
    static void testGetFiledDisplay() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        String jsonData = SendTdsFileFromAccount.getFiledDisplay(acc.Id);
    }

    @IsTest
    static void testGetDocumentUrl() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        ContentDocumentLink cdl = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :acc.Id LIMIT 1];
        String docId = SendTdsFileFromAccount.getDocumentUrl(cdl.Id);
    }

    @IsTest
    static void testSendMailToCustomer() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        ContentDocumentLink cdl = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :acc.Id LIMIT 1];

        List<String> fileIds = new List<String>{cdl.Id};
        List<Object> attachments = new List<Object>{
            new Map<String,String>{
                'filename' => 'upload.txt',
                'base64' => EncodingUtil.base64Encode(Blob.valueOf('Test'))
            }
        };

        String resultJson = SendTdsFileFromAccount.sendMailToCustomer(
            'test@example.com', new List<String>{'cc@example.com'}, 
            'Test Subject', 'Test Body', JSON.serialize(fileIds), attachments
        );
    }

    @IsTest
    static void testGetCurrentUserDetails() {
        SendTdsFileFromAccount.UserDetailWrapper userDetails = SendTdsFileFromAccount.getCurrentUserDetails();
    }
}