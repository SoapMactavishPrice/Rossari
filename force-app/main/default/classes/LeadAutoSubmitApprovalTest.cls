@isTest
public class LeadAutoSubmitApprovalTest {
        
    @testSetup
    static void setupData() {
        
         UserRole role = new UserRole(Name = 'Test Role');
    insert role;

    Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
    User manager = new User(
        Alias = 'mgr',
        Email = 'manager@test.com',
        EmailEncodingKey = 'UTF-8',
        LastName = 'Manager',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        ProfileId = p.Id,
        TimeZoneSidKey = 'America/Los_Angeles',
        UserName = 'manager@test.com',
        UserRoleId = role.Id,
        Street = '123 Test St',
        City = 'Test City',
        State = 'TS',
        PostalCode = '12345',
        Country = 'USA'
    );
    insert manager;

    // Now create lead with OwnerId set to manager and with address fields
    Lead l = new Lead(
        LastName = 'Test Lead',
        Company = 'Test Company',
        OwnerId = manager.Id,
        Street = '123 Test St',
        City = 'Test City',
        State = 'TS',
        PostalCode = '12345',
        Country = 'USA',
        COA_Approval_Level_1__c = null,
        COA_Approval_Level_2__c = null,
        COA_Approval_Level_1_Status__c = 'Submitted',
        COA_Approval_Level_2_Status__c = 'Submitted'
    );
    insert l;
    }

    @isTest
    static void testLevel1Only() {
        Lead l = [SELECT Id, COA_Approval_Level_1__c, COA_Approval_Level_2__c,
                         COA_Approval_Level_1_Status__c, COA_Approval_Level_2_Status__c
                  FROM Lead LIMIT 1];

        // Update to trigger Level 1 only
        l.COA_Approval_Level_1__c = 'Manager 1';
        l.COA_Approval_Level_1_Status__c = 'Submitted';
        update l;

    }

    @isTest
    static void testLevel2Only() {
        Lead l = new Lead(
            LastName = 'Level 2 Lead',
            Company = 'Company2',
            COA_Approval_Level_1__c = null,
            COA_Approval_Level_2__c = 'Manager 2',
            COA_Approval_Level_1_Status__c = 'Submitted',
            COA_Approval_Level_2_Status__c = 'Submitted'
        );
        insert l;

        l.COA_Approval_Level_2_Status__c = 'Submitted';
        update l;

    }

    @isTest
    static void testBothLevels() {
        Lead l = new Lead(
            LastName = 'Both Level Lead',
            Company = 'Company3',
            COA_Approval_Level_1__c = 'Manager 1',
            COA_Approval_Level_2__c = 'Manager 2',
            COA_Approval_Level_1_Status__c = 'Submitted',
            COA_Approval_Level_2_Status__c = 'Submitted'
        );
        insert l;

        // Submit Level 1 (this should trigger the Both-levels path)
        l.COA_Approval_Level_1_Status__c = 'Submitted';
        update l;

    }

    @isTest
    static void testNoSubmission() {
        Lead l = new Lead(
            LastName = 'No Submit Lead',
            Company = 'Company4',
            COA_Approval_Level_1__c = null,
            COA_Approval_Level_2__c = null,
            COA_Approval_Level_1_Status__c = 'Submitted',
            COA_Approval_Level_2_Status__c = 'Submitted'
        );
        insert l;

        Test.startTest();
        l.Company = 'Changed Company'; // No status update → should not trigger approval
        update l;
        Test.stopTest();

    }
}