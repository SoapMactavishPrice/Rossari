@isTest
private class SendTDSFileTest {

    @testSetup
    static void setupData() {
        // Setup mock data
        Country__c country = new Country__c(Name = 'India');
        insert country;

        State__c state = new State__c(Name = 'Gujarat', Country__c = country.Id);
        insert state;

        City__c city = new City__c(Name = 'Ahmedabad', State__c = state.Id);
        insert city;

        Pin_Code__c pinCode = new Pin_Code__c(Name = '380015', City__c = city.Id);
        insert pinCode;

        Company__c rossari = new Company__c(Name = 'Rossari Biotech Limited');
        insert rossari;
    }

    private static Map<String, SObject> setupTestData() {
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
            MobilePhone = '1234567899',
            COA_Approval_Level_1__c = user1.Id,
            COA_Approval_Level_2__c = user2.Id,
            COA_Approval_Level_1_Status__c = 'Approved',
            COA_Approval_Level_2_Status__c = 'Submitted'
        );
        insert testLead;

        Product2 prod = new Product2(Name = 'Test Product', ProductCode = 'TP001', IsActive = true);
        insert prod;

        Product_Interested__c pi = new Product_Interested__c(Lead__c = testLead.Id, Product__c = prod.Id);
        insert pi;

        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'testfile.pdf',
            VersionData = Blob.valueOf('Test File Content')
        );
        insert cv;

        ContentVersion insertedVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = insertedVersion.ContentDocumentId,
            LinkedEntityId = prod.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;

        // Use Map<String, SObject> to allow proper casting
        return new Map<String, SObject>{
            'lead' => testLead,
            'product' => prod,
            'cdl' => cdl,
            'cv' => cv
        };
    }

    @isTest
    static void testGetEmailDetails() {
        // Arrange
        //Map<String, SObject> testData = setupTestData();
       // Lead testLead = (Lead) testData.get('lead'); // Proper cast

        Test.startTest();
        // Act
      //  String emailJson = SendTDSFile.getEmailDetails(testLead.Id);
        Test.stopTest();

    }
}