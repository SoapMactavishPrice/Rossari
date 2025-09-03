@isTest
private class SendTDSFileTest {
    @testSetup
    static void setupData() {

        // Setup mock data
        Country__c country = new Country__c(
            Name = 'India'
        );
        insert country;
        
        State__c state = new State__c(
            Name = 'Gujarat',
            Country__c = country.Id
        );
        insert state;
        
        City__c city = new City__c(
            Name = 'Ahmedabad',
            State__c = state.Id
        );
        insert city;
        
        Pin_Code__c pinCode = new Pin_Code__c(
            Name = '380015',
            City__c = city.Id
        );
        insert pinCode;
        
        Company__c rossari = new Company__c(
            Name = 'Rossari Biotech Limited'
        );
        insert rossari;
    }
    
    private static Map<String, Object> setupTestData() {
        
            User user1 = new User(
            FirstName = 'Manager',
            LastName = 'User',
            Email = 'manager@gmail.com',
            Username = 'managr1876t@gmail.com',
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
            Username = 'managr1874r@gmail.com',
            Alias = 'dirUsr',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert user2;
        
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Email = 'testlead@example.com',
            Status = 'Open - Not Contacted',
            MobilePhone = '9999999999',
            COA_Approval_Level_1__c = user1.Id,
            COA_Approval_Level_2__c = user2.Id,
            COA_Approval_Level_1_Status__c = 'Approved',
            COA_Approval_Level_2_Status__c = 'Submitted'
        );
        insert testLead;

        
        
        Product2 prod = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP001',
            IsActive = true
        );
        insert prod;
        
        Product_Interested__c pi = new Product_Interested__c(
            Lead__c = testLead.Id,
            Product__c = prod.Id
        );
        insert pi;
        
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'testfile.pdf',
            VersionData = Blob.valueOf('Test File Content')
        );
        insert cv;
        
        ContentVersion insertedVersion = [
            SELECT Id, ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :cv.Id
        ];
        
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = insertedVersion.ContentDocumentId,
            LinkedEntityId = prod.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
        
        return new Map<String, Object>{
            'lead' => testLead,
                'product' => prod,
                'cdl' => cdl,
                'cv' => cv
                };
                    }
    
    @isTest
    static void testGetEmailDetails() {
        Map<String, Object> data = setupTestData();
        Lead testLead = (Lead) data.get('lead');
        Test.startTest();
        String emailJson = SendTDSFile.getEmailDetails(testLead.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testGetProductData() {
        Map<String, Object> data = setupTestData();
        Lead testLead = (Lead) data.get('lead');
        Test.startTest();
        String productJson = SendTDSFile.getProductData(testLead.Id);
        SendTDSFile.LeadWrapper leadData = SendTDSFile.getLead(testLead.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testGetFiledDisplay() {
        Map<String, Object> data = setupTestData();
        Product2 prod = (Product2) data.get('product');
        Test.startTest();
        String fileJson = SendTDSFile.getFiledDisplay(prod.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testGetDocumentUrl() {
        Map<String, Object> data = setupTestData();
        ContentDocumentLink cdl = (ContentDocumentLink) data.get('cdl');
        Test.startTest();
        String docUrl = SendTDSFile.getDocumentUrl(cdl.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testSendMailToCustomerWithFileAttachments() {
        Map<String, Object> data = setupTestData();
        ContentDocumentLink cdl = (ContentDocumentLink) data.get('cdl');
        String fileIdJson = JSON.serialize(new List<String>{cdl.Id});
        
        Test.startTest();
        String resultJson = SendTDSFile.sendMailToCustomer(
            'test@example.com',
            new List<String>{'cc@example.com'},
            'Test Subject',
            'Test Body',
            fileIdJson,
            new List<Object>()
        );
        Test.stopTest();
    }
    
    @isTest
    static void testSendMailToCustomerWithUploadedAttachments() {
        Map<String, Object> uploadAttachment = new Map<String, Object>{
            'filename' => 'test.txt',
                'base64' => EncodingUtil.base64Encode(Blob.valueOf('Test content'))
                };
                    List<Object> attachments = new List<Object>{uploadAttachment};
                        
                        Test.startTest();
        String resultJson = SendTDSFile.sendMailToCustomer(
            'test@example.com',
            new List<String>{'cc@example.com'},
            'Test Subject',
            'Test Body',
            '[]',
            attachments
        );
        Test.stopTest();
    }
    
    @isTest
    static void testSendMailToCustomerWithBothAttachments() {
        Map<String, Object> data = setupTestData();
        ContentDocumentLink cdl = (ContentDocumentLink) data.get('cdl');
        String fileIdJson = JSON.serialize(new List<String>{cdl.Id});
        
        Map<String, Object> uploadAttachment = new Map<String, Object>{
            'filename' => 'test.txt',
                'base64' => EncodingUtil.base64Encode(Blob.valueOf('Test content'))
                };
                    List<Object> attachments = new List<Object>{uploadAttachment};
                        
                        Test.startTest();
        String resultJson = SendTDSFile.sendMailToCustomer(
            'test@example.com',
            new List<String>{'cc@example.com'},
            'Test Subject',
            'Test Body',
            fileIdJson,
            attachments
        );
        Test.stopTest();
    }
    
    @isTest
    static void testSendMailToCustomerWithNoAttachments() {
        Test.startTest();
        try {
            String resultJson = SendTDSFile.sendMailToCustomer(
                'test@example.com',
                new List<String>{'cc@example.com'},
                'Test Subject',
                'Test Body',
                '[]',
                new List<Object>()
            );
        } catch (Exception e) {
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetCurrentUserDetails() {
        Test.startTest();
        SendTDSFile.UserDetailWrapper userDetails = SendTDSFile.getCurrentUserDetails();
        Test.stopTest();
    }
    
    @isTest
    static void testRequestApproval() {
        Map<String, Object> data = setupTestData();
        Lead testLead = (Lead) data.get('lead');
        
        User user1 = new User(
            FirstName = 'Manager',
            LastName = 'User',
            Email = 'manager@example.com',
            Username = 'manager' + DateTime.now().getTime() + '@example.com',
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
            Email = 'director@gmail.com',
            Username = 'director43256s@gmail.com',
            Alias = 'dirUsr',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert user2;
        
        Map<String, Object> wrapperData = new Map<String, Object>{
            'leadId' => testLead.Id,
                'level1User' => user1.Id,
                'level2User' => user2.Id
                };
                    String wrapperJson = JSON.serialize(wrapperData);
        
        Test.startTest();
        String result = SendTDSFile.requestApproval(wrapperJson);
        Test.stopTest();
    }

}