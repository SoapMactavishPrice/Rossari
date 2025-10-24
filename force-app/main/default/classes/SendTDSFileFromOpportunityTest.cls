@IsTest
private class SendTDSFileFromOpportunityTest {

    @TestSetup
    static void setupTestData() {
        // Get standard pricebook ID without updating (fix for UNABLE_TO_LOCK_ROW)
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

        User user1 = new User(
            FirstName = 'Manager',
            LastName = 'User',
            Email = 'manager@gmail.com',
            Username = 'manager' + DateTime.now().getTime() + '@test.com',
            Alias = 'mgrUsr',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert user1;

        User user2 = new User(
            FirstName = 'Director',
            LastName = 'User',
            Email = 'director@example.com',
            Username = 'director' + DateTime.now().getTime() + '@test.com',
            Alias = 'dirUsr',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert user2;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Pricebook2Id = standardPricebookId
        );
        insert opp;

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Quantity = 1,
            UnitPrice = 100,
            PricebookEntryId = pbe.Id
        );
        insert oli;

        Product_Document__c pd = new Product_Document__c(
            Name = 'Test Product Doc',
            Product__c = Prod.Id
        );
        insert pd;

        ContentVersion cv = new ContentVersion(
            Title = 'TestFile',
            PathOnClient = 'TestFile.txt',
            VersionData = Blob.valueOf('Test Content')
        );
        insert cv;

        ContentVersion contentVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = contentVersion.ContentDocumentId,
            LinkedEntityId = opp.Id,
            ShareType = 'V'
        );
        insert cdl;
    }

    @IsTest
    static void testGetEmailDetails() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Opportunity result = SendTDSFileFromOpportunity.getEmailDetails(opp.Id);
    }

    @IsTest
    static void testGetLead() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        SendTDSFileFromOpportunity.LeadWrapper wrapper = SendTDSFileFromOpportunity.getLead(opp.Id);
    }

    @IsTest
    static void testGetProductData() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        String jsonData = SendTDSFileFromOpportunity.getProductData(opp.Id);
    }

    @IsTest
    static void testGetFiledDisplay() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        String jsonData = SendTDSFileFromOpportunity.getFiledDisplay(opp.Id);
    }

    @IsTest
    static void testGetDocumentUrl() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        ContentDocumentLink cdl = [SELECT Id, ContentDocumentId 
                                   FROM ContentDocumentLink 
                                   WHERE LinkedEntityId = :opp.Id 
                                   LIMIT 1];
        String docId = SendTDSFileFromOpportunity.getDocumentUrl(cdl.Id);
    }

    @IsTest
    static void testSendMailToCustomer() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        ContentDocumentLink cdl = [SELECT Id, ContentDocumentId 
                                   FROM ContentDocumentLink 
                                   WHERE LinkedEntityId = :opp.Id 
                                   LIMIT 1];

        List<String> fileIds = new List<String>{cdl.Id};
        List<Object> attachments = new List<Object>();
        Map<String, String> fileMap = new Map<String, String>{
            'filename' => 'upload.txt',
            'base64' => EncodingUtil.base64Encode(Blob.valueOf('Test'))
        };
        attachments.add(fileMap);

        String resultJson = SendTDSFileFromOpportunity.sendMailToCustomer(
            'test@example.com',
            new List<String>{'cc@example.com'},
            'Test Subject',
            'Test Body',
            JSON.serialize(fileIds),
            attachments
        );
    }

    @IsTest
    static void testGetCurrentUserDetails() {
        SendTDSFileFromOpportunity.UserDetailWrapper userDetails = SendTDSFileFromOpportunity.getCurrentUserDetails();
    }
    
    @IsTest
    static void testGetDocumentUrlWithContentDocumentFilter() {
        ContentVersion cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Title = 'TestFile' LIMIT 1];
        ContentDocumentLink cdl = [SELECT Id 
                                   FROM ContentDocumentLink 
                                   WHERE ContentDocumentId = :cv.ContentDocumentId 
                                   LIMIT 1];
        String docId = SendTDSFileFromOpportunity.getDocumentUrl(cdl.Id);
    }
}