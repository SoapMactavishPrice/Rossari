@isTest
private class SendEmailTest {

    @testSetup
    static void setupTestData() {
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert testProduct;

        PricebookEntry standardPBE = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert standardPBE;

        Profile stdProfile = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];

        User testManager = new User(
            Alias = 'mgruser', Email='manager@example.com', ProfileId=stdProfile.Id,
            Username='manager'+System.currentTimeMillis()+'@example.com', FirstName='Manager', LastName='Test',
            TimeZoneSidKey='America/New_York', LocaleSidKey='en_US', EmailEncodingKey='UTF-8', LanguageLocaleKey='en_US',
            CommunityNickname='manager'
        );
        insert testManager;

        User testOwner = new User(
            Alias = 'ownuser', Email='owner@example.com', ProfileId=stdProfile.Id,
            Username='owner'+System.currentTimeMillis()+'@example.com', FirstName='Owner', LastName='Test',
            TimeZoneSidKey='America/New_York', LocaleSidKey='en_US', EmailEncodingKey='UTF-8', LanguageLocaleKey='en_US',
            CommunityNickname='owner', ManagerId = testManager.Id
        );
        insert testOwner;

        Account acc = new Account(Name='Test Account');
        insert acc;

        Pricebook2 customPB = new Pricebook2(Name='Custom Pricebook', IsActive=true);
        insert customPB;

        PricebookEntry customPBE = new PricebookEntry(
            Pricebook2Id = customPB.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 0,
            IsActive = true
        );
        insert customPBE;

        Opportunity opp = new Opportunity(
            Name='Test Opportunity', StageName='Prospecting', CloseDate=Date.today(),
            AccountId=acc.Id, OwnerId=testOwner.Id, Pricebook2Id=customPB.Id
        );
        insert opp;

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id, Product2Id = testProduct.Id, Quantity = 1,
            UnitPrice = 0, PricebookEntryId = customPBE.Id, Quality__c='High'
        );
        insert oli;

        Quote quote = new Quote(
            Name='Test Quote', OpportunityId = opp.Id, Status='Draft', Pricebook2Id=customPB.Id,
            OwnerId = testOwner.Id
        );
        insert quote;

        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id, Product2Id = testProduct.Id, Quantity=1, UnitPrice=0,
            PricebookEntryId = customPBE.Id, Quality__c='Standard'
        );
        insert qli;
    }

    @isTest
    static void testSendEmailNotification_ValidOpportunity() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        SendEmail.sendEmailNotification(opp.Id);
        Test.stopTest();
    }

    @isTest
    static void testSendEmailNotification_NullOpportunity() {
        Test.startTest();
        SendEmail.sendEmailNotification(null);
        Test.stopTest();
    }

    @isTest
    static void testSendEmailNotification_UnitPriceNotZero() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        OpportunityLineItem oli = [SELECT Id, UnitPrice FROM OpportunityLineItem WHERE OpportunityId=:opp.Id LIMIT 1];
        oli.UnitPrice = 50;
        update oli;

        Test.startTest();
        SendEmail.sendEmailNotification(opp.Id);
        Test.stopTest();
    }

    @isTest
    static void testSendEmailNotificationQuote_ValidQuote() {
        Quote q = [SELECT Id FROM Quote LIMIT 1];
        Test.startTest();
        SendEmail.sendEmailNotificationQuote(q.Id);
        Test.stopTest();
    }

    @isTest
    static void testSendEmailNotificationQuote_NullQuote() {
        Test.startTest();
        SendEmail.sendEmailNotificationQuote(null);
        Test.stopTest();
    }

    @isTest
    static void testSendEmailNotificationQuote_UnitPriceNotZero() {
        QuoteLineItem qli = [SELECT Id, UnitPrice FROM QuoteLineItem LIMIT 1];
        qli.UnitPrice = 50;
        update qli;

        Quote q = [SELECT Id FROM Quote LIMIT 1];
        Test.startTest();
        SendEmail.sendEmailNotificationQuote(q.Id);
        Test.stopTest();
    }
}