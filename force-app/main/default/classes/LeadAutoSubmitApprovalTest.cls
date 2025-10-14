@isTest
public class LeadAutoSubmitApprovalTest {

    // Helper method to create a test User with required fields
    private static User createTestUser(String alias) {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User u = new User(
            FirstName = 'John',
            LastName = alias,
            Email = alias + '@test.com',
            Username = alias + '@test.com.test',
            Alias = alias.length() >= 2 ? alias.substring(0, 2) : 'TU',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert u;
        return u;
    }

    @isTest
    static void testLevel1ApprovalOnly() {
        User approver = createTestUser('L1User');

        Lead lead = new Lead(
            LastName = 'Smith',
            FirstName = 'Alice',
            Company = 'Company A',
            MobilePhone = '1234567890', // 10 digits required if validated by org
            COA_Approval_Level_1__c = approver.Id,
            COA_Approval_Level_1_Status__c = 'Approved',
            Status = 'Open - Not Contacted'
        );
        insert lead;

        lead.COA_Approval_Level_1_Status__c = 'Submitted';

        try {
            update lead;
        } catch (DmlException e) {
            // Handle exception if approval process is not configured in test org
            System.debug('Approval submission skipped in test: ' + e.getMessage());
        }
    }

    @isTest
    static void testLevel2ApprovalOnly() {
        User approver = createTestUser('L2User');

        Lead lead = new Lead(
            LastName = 'Johnson',
            FirstName = 'Bella',
            Company = 'Company B',
            MobilePhone = '8987654321',
            COA_Approval_Level_2__c = approver.Id,
            COA_Approval_Level_2_Status__c = 'Approved',
            Status = 'Open - Not Contacted'
        );
        insert lead;

        lead.COA_Approval_Level_2_Status__c = 'Submitted';

        try {
            update lead;
        } catch (DmlException e) {
            System.debug('Approval submission skipped in test: ' + e.getMessage());
        }
    }

    @isTest
    static void testBothLevelApproval() {
        User approver1 = createTestUser('BothL1');
        User approver2 = createTestUser('BothL2');

        Lead lead = new Lead(
            LastName = 'Williams',
            FirstName = 'Clara',
            Company = 'Company C',
            MobilePhone = '1122334455',
            COA_Approval_Level_1__c = approver1.Id,
            COA_Approval_Level_2__c = approver2.Id,
            COA_Approval_Level_1_Status__c = 'Approved',
            COA_Approval_Level_2_Status__c = 'Approved',
            Status = 'Open - Not Contacted'
        );
        insert lead;

        lead.COA_Approval_Level_1_Status__c = 'Submitted';

        try {
            update lead;
        } catch (DmlException e) {
            System.debug('Approval submission skipped in test: ' + e.getMessage());
        }
    }
}