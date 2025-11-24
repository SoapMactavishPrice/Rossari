@isTest
public class LeadShareTriggerTest {
    @isTest
    static void testLeadShareTrigger() {

        User u1 = new User(
            FirstName = 'A',
            LastName = 'User',
            Alias = 'auser',
            Email = 'auser@test.com',
            Username = 'auser9878@test.com.' + System.currentTimeMillis(),
            CommunityNickname = 'auser1',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id
        );

        User u2 = new User(
            FirstName = 'B',
            LastName = 'User',
            Alias = 'buser',
            Email = 'buser@test.com',
            Username = 'buser87945@test.com.' + System.currentTimeMillis(),
            CommunityNickname = 'buser1',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id
        );

        insert u1;
        insert u2;

        Lead l = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Co',
            MobilePhone = '9087896754'
        );
        insert l;

        l.TDS_Approver__c = u1.Id;
        l.COA_Document_Approver__c = u2.Id;
        update l;
    }
}