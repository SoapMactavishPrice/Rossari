@isTest
public class CaseTriggerHandlerTest {
    
    @isTest
    static void testSendSampleEmail() {
        // Create a test user to assign to RND_User__c
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testusercase1212@example.com.test',
            Alias = 'tuser',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_IN',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;

        // Create a test Case record
        Case testCase = new Case(
            Subject = 'Test Case Subject',
            Description = 'Test Case Description',
            Nature_of_Complaint__c = 'Quality',
            Rejection__c = 15.5,
            Sample_IN_Sent__c = false,
            RND_User__c = testUser.Id
        );
        insert testCase;

        // Update Sample_IN_Sent__c to true to trigger the email
        testCase.Sample_IN_Sent__c = true;
        update testCase;

    }
}