@isTest
private class ManagerEmailSenderTest {

    @testSetup
    static void setupTestData() {
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        try{
        update standardPricebook;
        }Catch(Exception e){}
        
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
        
        try{
        insert testManager;
		}Catch(Exception e){}
            
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
            Pricebook2Id = standardPricebook.Id, 
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
        
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity', 
            StageName = 'Prospecting', 
            CloseDate = Date.today(), 
            AccountId = testAccount.Id, 
            OwnerId = testOwner.Id,
            Pricebook2Id = testPricebook.Id
        );
        insert testOpportunity;

        OpportunityLineItem oppLineItem = new OpportunityLineItem(
            OpportunityId = testOpportunity.Id, 
            Product2Id = prod.Id, 
            Quantity = 1, 
            UnitPrice = 50, 
            PricebookEntryId = customPbe.Id
        );
        insert oppLineItem;

        Quote testQuote = new Quote(
            OpportunityId = testOpportunity.Id, 
            Name = 'Test Quote', 
            Status = 'Draft',
            Pricebook2Id = testPricebook.Id
        );
        insert testQuote;

        QuoteLineItem quoteLineItem = new QuoteLineItem(
            QuoteId = testQuote.Id, 
            Product2Id = prod.Id, 
            Quantity = 1, 
            UnitPrice = 50, 
            PricebookEntryId = customPbe.Id
        );
        insert quoteLineItem;
    }

    @isTest
    static void testSendEmailToManagerForQuote() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        QuoteLineItem qli = [SELECT Id FROM QuoteLineItem WHERE QuoteId = :testQuote.Id LIMIT 1];
        qli.UnitPrice = 50;
        update qli;
        
        Test.startTest();
        ManagerEmailSender.sendEmailToManagerForQuote(testQuote.Id);
        Test.stopTest();
    }

    @isTest
    static void testSendEmailToManagerForQuoteWithNull() {
        Test.startTest();
        ManagerEmailSender.sendEmailToManagerForQuote(null);
        Test.stopTest();
    }

    @isTest
    static void testSendEmailToManagerForQuoteNoDiscount() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        QuoteLineItem qli = [SELECT Id FROM QuoteLineItem WHERE QuoteId = :testQuote.Id LIMIT 1];
        qli.UnitPrice = 100;
        update qli;
        
        Test.startTest();
        ManagerEmailSender.sendEmailToManagerForQuote(testQuote.Id);
        Test.stopTest();
    }

    @isTest
    static void testSendEmailToManagerForQuoteNoManager() {
        User testOwner = [SELECT Id FROM User WHERE Username = 'managermnkj2015@example.com' LIMIT 1];
        testOwner.ManagerId = null;
        update testOwner;
        
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        QuoteLineItem qli = [SELECT Id FROM QuoteLineItem WHERE QuoteId = :testQuote.Id LIMIT 1];
        qli.UnitPrice = 50;
        update qli;
        
        Test.startTest();
        ManagerEmailSender.sendEmailToManagerForQuote(testQuote.Id);
        Test.stopTest();
    }

    @isTest
    static void testSendEmailToManagerForQuoteNoNotificationType() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        QuoteLineItem qli = [SELECT Id FROM QuoteLineItem WHERE QuoteId = :testQuote.Id LIMIT 1];
        qli.UnitPrice = 50;
        update qli;
        
        Test.startTest();
        ManagerEmailSender.sendEmailToManagerForQuote(testQuote.Id);
        Test.stopTest();
    }
}