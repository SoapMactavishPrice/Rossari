@IsTest
public class CreditApprovalControllerTest {

    @IsTest
    static void testCreditApprovalController() {

        // Create a test user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tuser',
            Email = 'testuser@example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            CommunityNickname = 'tuser',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;

        System.runAs(testUser) {

            // Create test Account
            Account acc = new Account(Name = 'Test Account');
            insert acc;

            // Create test Opportunity
            Opportunity opp = new Opportunity(
                Name = 'Test Opportunity',
                StageName = 'Prospecting',
                CloseDate = System.today().addDays(30),
                AccountId = acc.Id
            );
            insert opp;

            // Create dummy Payment Term records (replace with your custom object)
            Payment_Term__c payment1 = new Payment_Term__c(Name = 'Term 1');
            Payment_Term__c payment2 = new Payment_Term__c(Name = 'Term 2');
            insert new List<Payment_Term__c>{payment1, payment2};

            // Create Quote owned by test user
            Quote q1 = new Quote(
                Name = 'Quote 1',
                //AccountId = acc.Id,
                OpportunityId = opp.Id,
                OwnerId = testUser.Id,
                Payment_Term__c = payment1.Id,
                Previous_Payment_Terms__c = payment2.Id,
                Credit_Approval_Status__c = 'Rejected'
            );
            insert q1;

            // Create Quote where test user is HOD
            Quote q2 = new Quote(
                Name = 'Quote 2',
                //AccountId = acc.Id,
                OpportunityId = opp.Id,
                Payment_Term__c = payment2.Id,
                Previous_Payment_Terms__c = payment1.Id,
                Credit_Approval_Status__c = 'Rejected',
                HOD_of_Sales_Department__c = testUser.Id
            );
            insert q2;

            // Test getQuotesWithChangedPaymentTerms
            List<Quote> quotes = CreditApprovalController.getQuotesWithChangedPaymentTerms(testUser.Id);
            System.debug('Quotes retrieved: ' + quotes);

            // Update Credit Approval
            for (Quote q : quotes) {
                q.Credit_Approval_Status__c = 'Rejected';
                q.Payment_Remark__c = 'Test remark';
            }
            String result = CreditApprovalController.updateCreditApproval(quotes);
            System.debug('Update result: ' + result);
        }
    }
}