@IsTest
private class SendTDSFileFromOpportunityTest {

    @TestSetup
    static void setupTestData() {
        User user1 = new User(
            FirstName = 'Manager',
            LastName = 'User',
            Email = 'manager@gmail.com',
            Username = 'managr1876t@gmail.com.test',
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
            Username = 'managr1874r@gmail.com.test',
            Alias = 'dirUsr',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert user2;

        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today()
        );
        insert opp;

        // Create Product
        Product2 prod = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP001',
            Description = 'Test Description',
            IsActive = true
        );
        insert prod;

        // Create OpportunityLineItem
        Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pb.Id,
            Product2Id = prod.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbe;
        
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Quantity = 1,
            UnitPrice = 100,
            PricebookEntryId = pbe.Id
        );
        insert oli;

        // Create Product Document
        Product_Document__c pd = new Product_Document__c(
            Name = 'Test Product Doc',
            Product__c = prod.Id
        );
        insert pd;

        // Create ContentVersion for file attachment
        ContentVersion cv = new ContentVersion(
            Title = 'TestFile',
            PathOnClient = 'TestFile.txt',
            VersionData = Blob.valueOf('Test Content')
        );
        insert cv;

        // Get ContentDocumentId
        ContentVersion contentVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        
        // Create ContentDocumentLink
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
        // Get ContentDocumentLink with proper filter
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        ContentDocumentLink cdl = [SELECT Id, ContentDocumentId 
                                 FROM ContentDocumentLink 
                                 WHERE LinkedEntityId = :opp.Id 
                                 LIMIT 1];
        
        String docId = SendTDSFileFromOpportunity.getDocumentUrl(cdl.Id);
        System.assertNotEquals(null, docId, 'Document URL should not be null');
    }

    @IsTest
    static void testSendMailToCustomer() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Get ContentDocumentLink with proper filter
        ContentDocumentLink cdl = [SELECT Id, ContentDocumentId 
                                 FROM ContentDocumentLink 
                                 WHERE LinkedEntityId = :opp.Id 
                                 LIMIT 1];
        
        List<String> fileIds = new List<String>();
        fileIds.add(cdl.Id);

        List<Object> attachments = new List<Object>();
        Map<String, String> fileMap = new Map<String, String>();
        fileMap.put('filename', 'upload.txt');
        fileMap.put('base64', EncodingUtil.base64Encode(Blob.valueOf('Test')));
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
    
    // Additional test method to cover ContentDocumentLink queries with ContentDocumentId filter
    @IsTest
    static void testGetDocumentUrlWithContentDocumentFilter() {
        // Get ContentVersion first to get ContentDocumentId
        ContentVersion cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Title = 'TestFile' LIMIT 1];
        
        // Get ContentDocumentLink using ContentDocumentId filter
        ContentDocumentLink cdl = [SELECT Id 
                                 FROM ContentDocumentLink 
                                 WHERE ContentDocumentId = :cv.ContentDocumentId 
                                 LIMIT 1];
        
        String docId = SendTDSFileFromOpportunity.getDocumentUrl(cdl.Id);
    }
}