@isTest
public class CustomerOnboardingFormController_Test {

    @testSetup
    static void setupData() {
        // Create Sales Org, Division, and Distribution Channel
        insert new Sales_Organisation__c(Name = 'Sales Org 1');
        insert new Division__c(Name = 'Division 1');
        insert new Distribution_Channel__c(Name = 'Channel 1');
        
        // Create supporting lookup records
        Pin_Code__c postalCode = new Pin_Code__c(Name = '400001');
        insert postalCode;

        City__c city = new City__c(Name = 'Mumbai');
        insert city;

        Country__c country = new Country__c(Name = 'India');
        insert country;

        // Activate standard pricebook
        Pricebook2 standardPb = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPb;

        // Create test Account with related fields
        Account acc = new Account(
            Name = 'Test Account',
            SAP_Customer_Code__c = '123456',
            Street1__c = '123 Test Street'
        );
        insert acc;
        
        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = acc.Id,
            Pricebook2Id = standardPb.Id
        );
        insert opp;
    
        // Create Quote linked to Account
        Quote quo = new Quote(Name = 'Test Quote',OpportunityId = opp.Id);
        insert quo;
        
        // Create ContentVersion → automatically creates ContentDocument
        ContentVersion cv = new ContentVersion(
            Title = 'TestFile',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('Dummy Content')
        );
        insert cv;

        // Fetch the ContentDocumentId created automatically
        Id contentDocId = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :cv.Id
            LIMIT 1
        ].ContentDocumentId;

        // Create a valid ContentDocumentLink (must filter properly in tests)
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = contentDocId,
            LinkedEntityId = acc.Id,
            ShareType = 'V'
        );
        insert cdl;
    }

    @isTest
    static void testGetCustomerOnboardingEmailLabel() {
        Test.startTest();
        String labelValue = CustomerOnboardingFormController.getCustomerOnboardingEmailLabel();
        Test.stopTest();
        System.assertNotEquals(null, labelValue);
    }

    @isTest
    static void testGetCustomerDetail() {
        Quote q = [SELECT Id FROM Quote LIMIT 1];
        Test.startTest();
        Quote result = CustomerOnboardingFormController.getCustomerDetail(q.Id);
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetDocumentUrl() {
        Id cdId = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            LIMIT 1
        ].ContentDocumentId;

        Test.startTest();
        String docUrl = CustomerOnboardingFormController.getDocumentUrl(cdId);
        Test.stopTest();

        System.assertNotEquals(null, docUrl, 'Document URL should not be null');
    }

    @isTest
    static void testGetSalesData() {
        Test.startTest();
        Map<String, Object> result = CustomerOnboardingFormController.getSalesData();
        Test.stopTest();
        System.assert(result.containsKey('SalesOrg'));
        System.assert(result.containsKey('Division'));
        System.assert(result.containsKey('DistributionChannel'));
    }

    @isTest
    static void testDeleteFile() {
        // Get ContentDocumentLink with proper filtering
        Id accId = [SELECT Id FROM Account LIMIT 1].Id;
        Id cdlId = [
            SELECT Id 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :accId 
            LIMIT 1
        ].Id;

        Test.startTest();
        //String result = CustomerOnboardingFormController.deletefile(cdlId);
        Test.stopTest();

        //System.assertEquals('Files deleted successfully', result);
    }

    @isTest
    static void testSendEmailWithAttachment() {
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test PDF Content'));

        Test.startTest();
        CustomerOnboardingFormController.sendEmailWithAttachment(
            'to@example.com',
            'cc@example.com',
            'Test Subject',
            'Test Body',
            'TestFile.pdf',
            base64Data
        );
        Test.stopTest();
    }

    @isTest
    static void testSendXlsxEmail() {
        Id contentDocId = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            LIMIT 1
        ].ContentDocumentId;

        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Excel File Content'));

        Test.startTest();
        CustomerOnboardingFormController.sendXlsxEmail(
            'TestFile.xlsx',
            base64Data,
            'recipient@example.com',
            'Email Body',
            'Subject',
            'cc1@example.com,cc2@example.com',
            new List<Id>{ contentDocId }
        );
        Test.stopTest();
    }
}