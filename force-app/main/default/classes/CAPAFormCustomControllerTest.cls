@isTest
public class CAPAFormCustomControllerTest {
    
    
    private static User createRNDUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User u = new User(
            LastName = 'RND User',
            Email = 'rnduser@test.com',
            Username = 'rnduser' + System.currentTimeMillis() + '@test.com',
            Alias = 'rndu',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            R_D_User__c = true
        );
        
        insert u;
        return u;
    }


    // Utility method to create a Case record for testing
    private static Case createTestCase() {
        
         User rndUser = createRNDUser();
        
        Case c = new Case(
            Subject = 'Test CAPA Case',
            Status = 'New',
            Priority = 'Medium',
            CAPA_No__c = 'CAPA-001',
            CAPA_Date__c = Date.today(),
            Nature_of_Complaint__c = 'Quality',
            Ref_Document_No__c = 'DOC-123',
            Description_of_Non_Conformity__c = 'Test Non Conformity',
            Root_Cause__c = 'Test Root Cause',
            Action_Taken_By_Name_Designation__c = 'Test User',
            Date_of_completion_of_Corrective_Action__c = Date.today(),
            Corrective_Preventive_Action_Taken__c = 'Test Corrective Action',
            RND_User__c = rndUser.Id
        );
        insert c;
        return c;
    }

    @isTest
    static void testControllerWithValidId() {
        // Create test data
        Case testCase = createTestCase();
        
        // Set parameter
        Test.startTest();
        PageReference pageRef = Page.CAPAForm; // Replace with your VF page name
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', testCase.Id);

        // Call constructor
        CAPAFormCustomController controller = new CAPAFormCustomController();

        // Verify record is loaded
        System.assertNotEquals(null, controller.caseRecord, 'Case should not be null');
        System.assertEquals(testCase.Id, controller.caseRecord.Id, 'Should load correct case record');
        Test.stopTest();
    }

    @isTest
    static void testControllerWithNoId() {
        Test.startTest();
        PageReference pageRef = Page.CAPAForm; 
        Test.setCurrentPage(pageRef);

        // No Id provided
        CAPAFormCustomController controller = new CAPAFormCustomController();

        System.assertNotEquals(null, controller.caseRecord, 'Case record should not be null');
        Test.stopTest();
    }

    @isTest
    static void testControllerWithInvalidId() {
        Test.startTest();
        PageReference pageRef = Page.CAPAForm; 
        Test.setCurrentPage(pageRef);

        // Pass an invalid ID
        ApexPages.currentPage().getParameters().put('id', '500XXXXXXXXXXXX');

        CAPAFormCustomController controller = new CAPAFormCustomController();

        // Since record not found, controller should handle exception
        System.assertNotEquals(null, controller.caseRecord, 'Case record should still be initialized');
        Test.stopTest();
    }

    @isTest
    static void testGetFormattedDate() {
        CAPAFormCustomController controller = new CAPAFormCustomController();
        
        Date today = Date.today();
        String formatted = controller.getFormattedDate(today);

        System.assertEquals(today.format(), formatted, 'Formatted date should match system format');
        
        String empty = controller.getFormattedDate(null);
        System.assertEquals('', empty, 'Should return empty string for null date');
    }
}