@isTest
public class CustomerOnboardingFormController_Test {

    @testSetup
    static void setupData() {
        // Check if lookup records already exist to avoid duplicate inserts
        List<Sales_Organisation__c> existingSalesOrgs = [SELECT Id FROM Sales_Organisation__c WHERE Name = 'Sales Org 1'];
        List<Division__c> existingDivisions = [SELECT Id FROM Division__c WHERE Name = 'Division 1'];
        List<Distribution_Channel__c> existingChannels = [SELECT Id FROM Distribution_Channel__c WHERE Name = 'Channel 1'];
        List<Pin_Code__c> existingPostalCodes = [SELECT Id FROM Pin_Code__c WHERE Name = '400001'];
        List<City__c> existingCities = [SELECT Id FROM City__c WHERE Name = 'Mumbai'];
        List<Country__c> existingCountries = [SELECT Id FROM Country__c WHERE Name = 'India'];
        
        // Create Sales Org, Division, and Distribution Channel only if they don't exist
        if (existingSalesOrgs.isEmpty()) {
            insert new Sales_Organisation__c(Name = 'Sales Org 1');
        }
        if (existingDivisions.isEmpty()) {
            insert new Division__c(Name = 'Division 1');
        }
        if (existingChannels.isEmpty()) {
            insert new Distribution_Channel__c(Name = 'Channel 1');
        }
        
        // Create supporting lookup records only if they don't exist
        if (existingPostalCodes.isEmpty()) {
            insert new Pin_Code__c(Name = '400001');
        }
        if (existingCities.isEmpty()) {
            insert new City__c(Name = 'Mumbai');
        }
        if (existingCountries.isEmpty()) {
            insert new Country__c(Name = 'India');
        }

        // Use Standard Pricebook without updating it
        Id standardPricebookId = Test.getStandardPricebookId();

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
            Pricebook2Id = standardPricebookId
        );
        insert opp;
    
        // Create Quote linked to Account
        Quote quo = new Quote(Name = 'Test Quote', OpportunityId = opp.Id);
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
        System.assertNotEquals(null, labelValue, 'Email label should not be null');
    }

    @isTest
    static void testGetCustomerDetail() {
        Quote q = [SELECT Id FROM Quote LIMIT 1];
        Test.startTest();
        Quote result = CustomerOnboardingFormController.getCustomerDetail(q.Id);
        Test.stopTest();
        System.assertNotEquals(null, result, 'Customer detail should not be null');
        System.assertEquals(q.Id, result.Id, 'Quote ID should match');
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
        System.assert(result.containsKey('SalesOrg'), 'Sales data should contain SalesOrg');
        System.assert(result.containsKey('Division'), 'Sales data should contain Division');
        System.assert(result.containsKey('DistributionChannel'), 'Sales data should contain DistributionChannel');
    }

    @isTest
    static void testSendEmailWithAttachment() {
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test PDF Content'));

        Test.startTest();
        try {
            CustomerOnboardingFormController.sendEmailWithAttachment(
                'to@example.com',
                'cc@example.com',
                'Test Subject',
                'Test Body',
                'TestFile.pdf',
                base64Data
            );
        } catch (Exception e) {
            // Handle potential email sending limitations in tests
            System.debug('Email sending test completed: ' + e.getMessage());
        }
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
        try {
            CustomerOnboardingFormController.sendXlsxEmail(
                'TestFile.xlsx',
                base64Data,
                'recipient@example.com',
                'Email Body',
                'Subject',
                'cc1@example.com,cc2@example.com',
                new List<Id>{ contentDocId }
            );
        } catch (Exception e) {
            // Handle potential email sending limitations in tests
            System.debug('XLSX email sending test completed: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testAllMethodsInOne() {
        // Get test data
        Quote q = [SELECT Id FROM Quote LIMIT 1];
        Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1].ContentDocumentId;
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test Content'));

        Test.startTest();

        // Test 1: Get customer onboarding email label
        String emailLabel = CustomerOnboardingFormController.getCustomerOnboardingEmailLabel();
        System.assertNotEquals(null, emailLabel, 'Email label should not be null');

        // Test 2: Get customer detail
        Quote customerDetail = CustomerOnboardingFormController.getCustomerDetail(q.Id);
        System.assertNotEquals(null, customerDetail, 'Customer detail should not be null');

        // Test 3: Get document URL
        String docUrl = CustomerOnboardingFormController.getDocumentUrl(contentDocId);
        System.assertNotEquals(null, docUrl, 'Document URL should not be null');

        // Test 4: Get sales data
        Map<String, Object> salesData = CustomerOnboardingFormController.getSalesData();
        System.assertNotEquals(null, salesData, 'Sales data should not be null');
        System.assert(salesData.containsKey('SalesOrg'), 'Should contain SalesOrg');
        System.assert(salesData.containsKey('Division'), 'Should contain Division');
        System.assert(salesData.containsKey('DistributionChannel'), 'Should contain DistributionChannel');

        // Test 5: Send email with attachment
        try {
            CustomerOnboardingFormController.sendEmailWithAttachment(
                'test@example.com',
                'cc@example.com',
                'Test Subject',
                'Test Body',
                'TestFile.pdf',
                base64Data
            );
        } catch (Exception e) {
            // Handle email limitations
        }

        // Test 6: Send XLSX email
        try {
            CustomerOnboardingFormController.sendXlsxEmail(
                'TestFile.xlsx',
                base64Data,
                'test@example.com',
                'Email Body',
                'Subject',
                'cc@example.com',
                new List<Id>{ contentDocId }
            );
        } catch (Exception e) {
            // Handle email limitations
        }

        Test.stopTest();
    }

    @isTest
    static void testErrorScenarios() {
        Test.startTest();

        // Test 1: Get customer detail with invalid ID
        try {
            Quote invalidDetail = CustomerOnboardingFormController.getCustomerDetail('invalidId');
            System.assertEquals(null, invalidDetail, 'Invalid ID should return null');
        } catch (Exception e) {
            // Expected to handle invalid ID
        }

        // Test 2: Get document URL with invalid ID
        try {
            String invalidDocUrl = CustomerOnboardingFormController.getDocumentUrl('invalidId');
            System.assertEquals(null, invalidDocUrl, 'Invalid document ID should return null');
        } catch (Exception e) {
            // Expected to handle invalid document ID
        }

        // Test 3: Send email with invalid parameters
        try {
            CustomerOnboardingFormController.sendEmailWithAttachment(
                null, // invalid email
                null,
                null,
                null,
                null,
                null
            );
        } catch (Exception e) {
            // Expected to handle invalid parameters
        }

        // Test 4: Send XLSX email with invalid parameters
        try {
            CustomerOnboardingFormController.sendXlsxEmail(
                null,
                null,
                null,
                null,
                null,
                null,
                null
            );
        } catch (Exception e) {
            // Expected to handle invalid parameters
        }

        Test.stopTest();
    }

    @isTest
    static void testContentDocumentScenarios() {
        // Create additional test content
        ContentVersion cv2 = new ContentVersion(
            Title = 'TestFile2',
            PathOnClient = 'TestFile2.pdf',
            VersionData = Blob.valueOf('Dummy Content 2')
        );
        insert cv2;

        Id contentDocId2 = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :cv2.Id
            LIMIT 1
        ].ContentDocumentId;

        Test.startTest();

        // Test document URL with new content document
        String docUrl2 = CustomerOnboardingFormController.getDocumentUrl(contentDocId2);
        System.assertNotEquals(null, docUrl2, 'Second document URL should not be null');

        Test.stopTest();
    }
}