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
            Account__c = acc.Id,
            Product__c = prod.Id
        );
        insert pi;

        Product_Document__c pd = new Product_Document__c(
            Name = 'Test Product Doc',
            Product__c = prod.Id
        );
        insert pd;

        ContentVersion cv = new ContentVersion(
            Title = 'TestFile',
            PathOnClient = 'TestFile.txt',
            VersionData = Blob.valueOf('Test Content')
        );
        try{
        insert cv;
        }Catch(Exception e){}
        
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
        System.assertNotEquals(null, result, 'Email details should be returned.');
    }

    @IsTest
    static void testGetLead() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        SendTdsFileFromAccount.LeadWrapper wrapper = SendTdsFileFromAccount.getLead(acc.Id);
        System.assertNotEquals(null, wrapper, 'Lead wrapper should be returned.');
    }

    @IsTest
    static void testGetProductData() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        String jsonData = SendTdsFileFromAccount.getProductData(acc.Id);
        System.assertNotEquals(null, jsonData, 'Product data JSON should be returned.');
    }

    @IsTest
    static void testGetFiledDisplay() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        String jsonData = SendTdsFileFromAccount.getFiledDisplay(acc.Id);
        System.assertNotEquals(null, jsonData, 'Field display JSON should be returned.');
    }

    @IsTest
    static void testGetDocumentUrl() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        ContentDocumentLink cdl = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :acc.Id LIMIT 1];
        String docId = SendTdsFileFromAccount.getDocumentUrl(cdl.Id);
        System.assertNotEquals(null, docId, 'Document URL should be returned.');
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
        System.assertNotEquals(null, resultJson, 'Email result JSON should be returned.');
    }

    @IsTest
    static void testGetCurrentUserDetails() {
        SendTdsFileFromAccount.UserDetailWrapper userDetails = SendTdsFileFromAccount.getCurrentUserDetails();
        System.assertNotEquals(null, userDetails, 'User details should be returned.');
    }
}