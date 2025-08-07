@isTest
private class ManagerEmailSenderTest {

    @testSetup
    static void setupTestData() {
        User testManager = new User(
            Alias = 'testmgr', 
            Email = 'manager@example.com', 
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id, 
            Username = 'managerkgdts2012@example.com', 
            FirstName = 'Manager', 
            LastName = 'Test', 
            TimeZoneSidKey = 'America/New_York', 
            LocaleSidKey = 'en_US', 
            EmailEncodingKey = 'UTF-8', 
            LanguageLocaleKey = 'en_US', 
            CommunityNickname = 'manager'
        );
        insert testManager;

        User testOwner = new User(
            Alias = 'dlftest', 
            Email = 'owner@example.com', 
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id, 
            Username = 'managermnkj2015@example.com', 
            FirstName = 'Owner', 
            LastName = 'Test', 
            TimeZoneSidKey = 'America/New_York', 
            LocaleSidKey = 'en_US', 
            EmailEncodingKey = 'UTF-8', 
            LanguageLocaleKey = 'en_US', 
            CommunityNickname = 'owner',
            ManagerId = testManager.Id
        );
        insert testOwner;
        
        Id standardPricebookId = Test.getStandardPricebookId();
        
        Pricebook2 testPricebook = new Pricebook2(
            Name = 'Test Pricebook',
            IsActive = true
        );
        insert testPricebook;

        Account testAccount = new Account(Name = 'Test Account', CurrencyIsoCode = 'USD');
        insert testAccount;
        
        Product2 prod = new Product2(Name = 'Test Product', Family = 'Test Family', IsActive = true);
        insert prod;
        
        PricebookEntry standardPbe = new PricebookEntry(
            Pricebook2Id = standardPricebookId, 
            Product2Id = prod.Id, 
            UnitPrice = 100, 
            IsActive = true, 
            UseStandardPrice = false
        );
        insert standardPbe;
        
        PricebookEntry customPbe = new PricebookEntry(
            Pricebook2Id = testPricebook.Id, 
            Product2Id = prod.Id, 
            UnitPrice = 100, 
            IsActive = true, 
            UseStandardPrice = false
        );
        insert customPbe;
        
        // Create Opportunity and assign Pricebook2
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity', 
            StageName = 'Prospecting', 
            CloseDate = Date.today(), 
            AccountId = testAccount.Id, 
            OwnerId = testOwner.Id,
            Pricebook2Id = testPricebook.Id
           
        );
        insert testOpportunity;

        // Create OpportunityLineItem after the Opportunity is inserted
        OpportunityLineItem oppLineItem = new OpportunityLineItem(
            OpportunityId = testOpportunity.Id, 
            Product2Id = prod.Id, 
            Quantity = 1, 
            UnitPrice = 50, 
            PricebookEntryId = customPbe.Id // Associate with the custom pricebook entry
        );
        insert oppLineItem;

        // Create Quote and assign Pricebook2
        Quote testQuote = new Quote(
            OpportunityId = testOpportunity.Id, 
            Name = 'Test Quote', 
            Status = 'Draft',
            Pricebook2Id = testPricebook.Id // Assigning the Pricebook to the Quote
        );
        insert testQuote;

        // Create QuoteLineItem after the Quote is inserted
        QuoteLineItem quoteLineItem = new QuoteLineItem(
            QuoteId = testQuote.Id, 
            Product2Id = prod.Id, 
            Quantity = 1, 
            UnitPrice = 50, 
            PricebookEntryId = customPbe.Id // Associate with the custom pricebook entry
        );
        insert quoteLineItem;
    }

    @isTest
    static void testSendEmailToManagerForQuote() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        ManagerEmailSender.sendEmailToManagerForQuote(testQuote.Id);
        
        Test.stopTest();
    }
}