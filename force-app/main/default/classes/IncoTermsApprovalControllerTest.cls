@isTest
public class IncoTermsApprovalControllerTest {
    
    @testSetup
    static void setupTestData() {
        // Create a test user
        User testUser = new User(
            Alias = 'tuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testuser2312ss@example.com'
        );
        insert testUser;

        // Create another user for HOD
        User hodUser = new User(
            Alias = 'hoduser',
            Email = 'hoduser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'HOD',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'hoduserasasxs@example.com'
        );
        insert hodUser;

        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Opportunity opp = new Opportunity(
                Name = 'Test Opportunity',
                StageName = 'Prospecting',
                CloseDate = System.today().addDays(30),
                AccountId = acc.Id
            );
            insert opp;

        // Create Quotes for both scenarios
        List<Quote> quotes = new List<Quote>();
        quotes.add(new Quote(
            Name = 'Owned Quote',
           // AccountId = acc.Id,
            Inco_Terms__c = 'FOB',
            OpportunityId = opp.Id,
            Previous_Inco_Terms__c = 'CIF',
            Inco_Terms_Approval_Status__c = 'Rejected',
            OwnerId = testUser.Id,
            HOD_of_Sales_Department__c = hodUser.Id
        ));
        quotes.add(new Quote(
            Name = 'HOD Quote',
            //AccountId = acc.Id,
            OpportunityId = opp.Id,
            Inco_Terms__c = 'CIF',
            Previous_Inco_Terms__c = 'FOB',
            Inco_Terms_Approval_Status__c = 'Rejected',
            OwnerId = hodUser.Id,
            HOD_of_Sales_Department__c = testUser.Id
        ));
        insert quotes;
    }
    
    @isTest
    static void testGetQuotesWithChangedIncoTerms() {
        User currentUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        
        Test.startTest();
        List<Quote> result = IncoTermsApprovalController.getQuotesWithChangedIncoTerms(currentUser.Id);
        Test.stopTest();
        
        System.assertNotEquals(0, result.size(), 'Expected at least one quote returned');
        for (Quote q : result) {
            System.assert(q.Inco_Terms__c != q.Previous_Inco_Terms__c, 'Inco terms should differ');
        }
    }
    
    @isTest
    static void testUpdateIncoApproval() {
        // Fetch quotes to update
        List<Quote> quotesToUpdate = [SELECT Id, Inco_Terms_Approval_Status__c, Inco_Remark__c FROM Quote LIMIT 2];
        for (Quote q : quotesToUpdate) {
            q.Inco_Terms_Approval_Status__c = 'Approved';
            q.Inco_Remark__c = 'Approved by test';
        }
        
        Test.startTest();
        String result = IncoTermsApprovalController.updateIncoApproval(quotesToUpdate);
        Test.stopTest();
        
        System.assertEquals('Success', result, 'Expected success message');
        
        // Verify update
        List<Quote> updatedQuotes = [SELECT Inco_Terms_Approval_Status__c, Inco_Remark__c FROM Quote WHERE Id IN :quotesToUpdate];
        for (Quote q : updatedQuotes) {
            System.assertEquals('Approved', q.Inco_Terms_Approval_Status__c, 'Status should be updated');
            System.assertEquals('Approved by test', q.Inco_Remark__c, 'Remark should be updated');
        }
    }
}