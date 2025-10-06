@isTest
public class QuoteTriggerHandlerTest {
    
    // Helper method to setup test pricebook
    private static void setupPricebook() {
        // Get the standard pricebook
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
    }
    
    @isTest
    static void testSendPaymentTermChangeEmails() {
        // Setup pricebook first
        setupPricebook();
        
        User hodUser = new User(
            Username = 'hoduserkgn12985bu87s@gmail.com',
            LastName = 'HOD',
            Email = 'hoduser@test.com',
            Alias = 'hodusr',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert hodUser;

        User ownerUser = new User(
            Username = 'owneruserkgn12987bu87s@gmail.com',
            LastName = 'Owner',
            Email = 'owneruser@test.com',
            Alias = 'ownusr',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert ownerUser;

        Account acc = new Account(Name = 'Test Account', SAP_Customer_Code__c = 'SAP123');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id,
            Pricebook2Id = Test.getStandardPricebookId() // Explicitly set pricebook
        );
        insert opp;

        // Rest of your test code remains the same...
        Payment_Term__c previousTerm = new Payment_Term__c(Name = 'Net 30');
        insert previousTerm;

        Payment_Term__c newTerm = new Payment_Term__c(Name = 'Net 60');
        insert newTerm;

        Quote q = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            OwnerId = ownerUser.Id,
            HOD_of_Sales_Department__c = hodUser.Id,
            Payment_Term__c = newTerm.Id,
            Previous_Payment_Terms__c = previousTerm.Id,
            Credit_Approval_Status__c = 'Approved',
            Payment_Remark__c = 'Customer requested extension'
        );
        insert q;

        List<Quote> quotes = [SELECT Id, Name, AccountId, OwnerId, HOD_of_Sales_Department__c, 
                              Payment_Term__c, Previous_Payment_Terms__c, Credit_Approval_Status__c, 
                              QuoteNumber, Payment_Remark__c 
                              FROM Quote WHERE Id = :q.Id];

        Test.startTest();
        QuoteTriggerHandler.sendPaymentTermChangeEmails(quotes);
        Test.stopTest();

    }
}