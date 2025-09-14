@isTest
private class SendEmailTest {
    @testSetup
    static void setupTestData() {
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        
        Profile stdProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User testManager = new User(
            Alias = 'testmgr', 
            Email = 'manager@example.com', 
            ProfileId = stdProfile.Id, 
            Username = 'managerkdlf2008@example.com', 
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
            ProfileId = stdProfile.Id, 
            Username = 'managerkdlf2012@example.com', 
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
        
        Pricebook2 testPricebook1 = new Pricebook2(
            Name = 'Test Pricebook 2',
            IsActive = true
        );
        insert testPricebook1;
        
        Account testAccount = new Account(
            Name = 'Test Account', 
            CurrencyIsoCode = 'USD'
        );
        insert testAccount;
        
        Product2 prod = new Product2(
            Name = 'Test Product', 
            Family = 'Test Family', 
            IsActive = true
        );
        insert prod;
        
        PricebookEntry standardPbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id, 
            Product2Id = prod.Id, 
            UnitPrice = 100, 
            IsActive = true
        );
        insert standardPbe;
        
        PricebookEntry customPbe = new PricebookEntry(
            Pricebook2Id = testPricebook.Id, 
            Product2Id = prod.Id, 
            UnitPrice = 0, 
            IsActive = true
        );
        insert customPbe;
        
        PricebookEntry customPbe1 = new PricebookEntry(
            Pricebook2Id = testPricebook1.Id, 
            Product2Id = prod.Id, 
            UnitPrice = 10,
            IsActive = true
        );
        insert customPbe1;
        
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity', 
            StageName = 'Prospecting', 
            CloseDate = Date.today(), 
            AccountId = testAccount.Id, 
            OwnerId = testOwner.Id,
            Pricebook2Id = testPricebook.Id
        );
        insert testOpportunity;
        
        Opportunity testOpportunityWithPriceAlert = new Opportunity(
            Name = 'Test Opportunity With Price Alert', 
            StageName = 'Prospecting', 
            CloseDate = Date.today(), 
            AccountId = testAccount.Id, 
            OwnerId = testOwner.Id,
            Pricebook2Id = testPricebook1.Id
        );
        insert testOpportunityWithPriceAlert;
        
        OpportunityLineItem oppLineItem = new OpportunityLineItem(
            OpportunityId = testOpportunity.Id, 
            Product2Id = prod.Id, 
            Quantity = 1, 
            UnitPrice = 0, 
            Quality__c = 'High',
            PricebookEntryId = customPbe.Id
        );
        insert oppLineItem;
        
        OpportunityLineItem oppLineItemWithPriceAlert = new OpportunityLineItem(
            OpportunityId = testOpportunityWithPriceAlert.Id, 
            Product2Id = prod.Id, 
            Quantity = 1, 
            UnitPrice = 5,
            //      ListPrice = 10,
            Quality__c = 'Medium',
            PricebookEntryId = customPbe1.Id
        );
        insert oppLineItemWithPriceAlert;
        
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
            UnitPrice = 0, 
            Quality__c = 'Standard',
            PricebookEntryId = customPbe.Id
        );
        insert quoteLineItem;
    }
    
    @isTest
    static void testSendEmailNotification_ValidOppId() {
        
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        
        Opportunity opp1 = new Opportunity(
            Name = 'Test Opportunity', 
            CloseDate = Date.today(), 
            StageName = 'Prospecting',
            Pricebook2Id = standardPricebook.Id
        );
        insert opp1;
        
        Test.startTest();
        SendEmail.sendEmailNotification(opp1.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testSendEmailNotification_NullOppId() {
        Test.startTest();
        SendEmail.sendEmailNotification(null);
        Test.stopTest();
    }
    
    @isTest
    static void testSendEmailNotification_NoZeroPrice() {
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        
        Opportunity opp1 = new Opportunity(
            Name = 'Test Opportunity', 
            CloseDate = Date.today(), 
            StageName = 'Prospecting',
            Pricebook2Id = standardPricebook.Id
        );
        insert opp1;
        
         OpportunityLineItem testOli = new OpportunityLineItem(
            OpportunityId = opp1.Id,
            PricebookEntryId = standardPricebook.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert testOli;
        
        testOli.UnitPrice = 100;
        update testOli;
        
        Test.startTest();
        SendEmail.sendEmailNotification(opp1.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testSendEmailNotification_ManagerEmail() {
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        
        Opportunity opp1 = new Opportunity(
            Name = 'Test Opportunity', 
            CloseDate = Date.today(), 
            StageName = 'Prospecting',
            Pricebook2Id = standardPricebook.Id
        );
        insert opp1;
        
        Test.startTest();
        SendEmail.sendEmailNotification(opp1.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testSendEmailNotification_ManagerEmailNoManager() {
        User testOwner = [SELECT Id FROM User WHERE Username = 'managerkdlf2012@example.com' LIMIT 1];
        testOwner.ManagerId = null;
        update testOwner;
        
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        
        Opportunity opp1 = new Opportunity(
            Name = 'Test Opportunity', 
            CloseDate = Date.today(), 
            StageName = 'Prospecting',
            Pricebook2Id = standardPricebook.Id
        );
        insert opp1;
        
        Test.startTest();
        SendEmail.sendEmailNotification(opp1.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testSendEmailNotificationQuote_ValidQuoteId() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        
        Test.startTest();
        SendEmail.sendEmailNotificationQuote(testQuote.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testSendEmailNotificationQuote_NullQuoteId() {
        Test.startTest();
        SendEmail.sendEmailNotificationQuote(null);
        Test.stopTest();
    }
    
    @isTest
    static void testSendEmailNotificationQuote_NoZeroPrice() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        QuoteLineItem qli = [SELECT Id FROM QuoteLineItem WHERE QuoteId = :testQuote.Id LIMIT 1];
        qli.UnitPrice = 100;
        update qli;
        
        Test.startTest();
        SendEmail.sendEmailNotificationQuote(testQuote.Id);
        Test.stopTest();
    }
    
    
}