@isTest
private class SendEmailTest {

    @testSetup
    static void setupTestData() {
        Profile stdProfile = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        
        // Create manager user
        User testManager = new User(
            Alias = 'mgruser',
            Email='manager@example.com',
            ProfileId=stdProfile.Id,
            Username='manager' + System.currentTimeMillis() + '@example.com',
            FirstName='Manager',
            LastName='Test',
            TimeZoneSidKey='America/New_York',
            LocaleSidKey='en_US',
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US',
            CommunityNickname='manager'
        );
        insert testManager;

        // Create owner user
        User testOwner = new User(
            Alias = 'ownuser',
            Email='owner@example.com',
            ProfileId=stdProfile.Id,
            Username='owner' + System.currentTimeMillis() + '@example.com',
            FirstName='Owner',
            LastName='Test',
            TimeZoneSidKey='America/New_York',
            LocaleSidKey='en_US',
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US',
            CommunityNickname='owner',
            ManagerId = testManager.Id
        );
        insert testOwner;

        // Create product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert testProduct;

        // Create standard pricebook entry
        PricebookEntry standardPBE = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProduct.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert standardPBE;

        // Create account
        Account acc = new Account(Name='Test Account');
        insert acc;

        // Create custom pricebook
        Pricebook2 customPB = new Pricebook2(Name='Custom Pricebook', IsActive=true);
        insert customPB;

        // Create custom pricebook entry with zero price
        PricebookEntry customPBE = new PricebookEntry(
            Pricebook2Id = customPB.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 0,
            IsActive = true
        );
        insert customPBE;

        // Create opportunity with zero price line item
        Opportunity opp = new Opportunity(
            Name='Test Opportunity',
            StageName='Prospecting',
            CloseDate=Date.today(),
            AccountId=acc.Id,
            OwnerId=testOwner.Id,
            Pricebook2Id=customPB.Id
        );
        insert opp;

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Product2Id = testProduct.Id,
            Quantity = 1,
            UnitPrice = 0,
            PricebookEntryId = customPBE.Id,
            Quality__c='High'
        );
        insert oli;

        // Create quote with zero price line item
        Quote quote = new Quote(
            Name='Test Quote',
            OpportunityId = opp.Id,
            Status='Draft',
            Pricebook2Id = customPB.Id,
            OwnerId = testOwner.Id
        );
        insert quote;

        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            Product2Id = testProduct.Id,
            Quantity=1,
            UnitPrice=0,
            PricebookEntryId = customPBE.Id,
            Quality__c='Standard'
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
        OpportunityLineItem oli = [SELECT Id, UnitPrice FROM OpportunityLineItem WHERE OpportunityId = :opp.Id LIMIT 1];
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

    @isTest
    static void testSendEmailNotification_InvalidOpportunityId() {
        Test.startTest();
        try {
            SendEmail.sendEmailNotification('001000000000000');
        } catch (Exception e) {
        }
        Test.stopTest();
    }

    @isTest
    static void testSendEmailNotificationQuote_InvalidQuoteId() {
        Test.startTest();
        try {
            SendEmail.sendEmailNotificationQuote('0Q000000000000');
        } catch (Exception e) {
        }
        Test.stopTest();
    }

    @isTest
    static void testSendEmailNotification_MultipleLineItems() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];
        PricebookEntry customPBE = [SELECT Id FROM PricebookEntry WHERE Pricebook2.Name = 'Custom Pricebook' LIMIT 1];
        
        OpportunityLineItem oli2 = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Product2Id = testProduct.Id,
            Quantity = 2,
            UnitPrice = 0,
            PricebookEntryId = customPBE.Id,
            Quality__c='Medium'
        );
        insert oli2;
        
        Test.startTest();
        SendEmail.sendEmailNotification(opp.Id);
        Test.stopTest();
    }

    @isTest
    static void testSendEmailNotificationQuote_MultipleLineItems() {
        Quote q = [SELECT Id FROM Quote LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];
        PricebookEntry customPBE = [SELECT Id FROM PricebookEntry WHERE Pricebook2.Name = 'Custom Pricebook' LIMIT 1];
        
        QuoteLineItem qli2 = new QuoteLineItem(
            QuoteId = q.Id,
            Product2Id = testProduct.Id,
            Quantity = 3,
            UnitPrice = 0,
            PricebookEntryId = customPBE.Id,
            Quality__c='Low'
        );
        insert qli2;
        
        Test.startTest();
        SendEmail.sendEmailNotificationQuote(q.Id);
        Test.stopTest();
    }

    @isTest
    static void testSendEmailNotification_NoLineItems() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        List<OpportunityLineItem> olis = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :opp.Id];
        delete olis;
        
        Test.startTest();
        SendEmail.sendEmailNotification(opp.Id);
        Test.stopTest();
    }

    @isTest
    static void testSendEmailNotificationQuote_NoLineItems() {
        Quote q = [SELECT Id FROM Quote LIMIT 1];
        
        List<QuoteLineItem> qlis = [SELECT Id FROM QuoteLineItem WHERE QuoteId = :q.Id];
        delete qlis;
        
        Test.startTest();
        SendEmail.sendEmailNotificationQuote(q.Id);
        Test.stopTest();
    }

    @isTest
    static void testSendEmailNotification_EmptyStringId() {
        Test.startTest();
        try {
            SendEmail.sendEmailNotification('');
        } catch (Exception e) {
        }
        Test.stopTest();
    }

    @isTest
    static void testSendEmailNotificationQuote_EmptyStringId() {
        Test.startTest();
        try {
            SendEmail.sendEmailNotificationQuote('');
        } catch (Exception e) {
        }
        Test.stopTest();
    }

    @isTest
    static void testSendEmailNotification_AllUnitPricesZero() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        SendEmail.sendEmailNotification(opp.Id);
        Test.stopTest();
    }

    @isTest
    static void testSendEmailNotificationQuote_AllUnitPricesZero() {
        Quote q = [SELECT Id FROM Quote LIMIT 1];
        
        Test.startTest();
        SendEmail.sendEmailNotificationQuote(q.Id);
        Test.stopTest();
    }

    @isTest
    static void testSendEmailNotification_MixedUnitPrices() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];
        PricebookEntry customPBE = [SELECT Id FROM PricebookEntry WHERE Pricebook2.Name = 'Custom Pricebook' LIMIT 1];
        
        OpportunityLineItem oli2 = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Product2Id = testProduct.Id,
            Quantity = 2,
            UnitPrice = 25,
            PricebookEntryId = customPBE.Id,
            Quality__c='Medium'
        );
        insert oli2;
        
        Test.startTest();
        SendEmail.sendEmailNotification(opp.Id);
        Test.stopTest();
    }

    @isTest
    static void testSendEmailNotificationQuote_MixedUnitPrices() {
        Quote q = [SELECT Id FROM Quote LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];
        PricebookEntry customPBE = [SELECT Id FROM PricebookEntry WHERE Pricebook2.Name = 'Custom Pricebook' LIMIT 1];
        
        QuoteLineItem qli2 = new QuoteLineItem(
            QuoteId = q.Id,
            Product2Id = testProduct.Id,
            Quantity = 3,
            UnitPrice = 30,
            PricebookEntryId = customPBE.Id,
            Quality__c='Low'
        );
        insert qli2;
        
        Test.startTest();
        SendEmail.sendEmailNotificationQuote(q.Id);
        Test.stopTest();
    }

    @isTest
    static void testSendEmailNotification_WithNonZeroPricebookEntry() {
        // Create additional product
        Product2 testProduct2 = new Product2(
            Name = 'Test Product 2',
            IsActive = true
        );
        insert testProduct2;

        // Create standard pricebook entry first (required)
        PricebookEntry standardPBE2 = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProduct2.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert standardPBE2;

        Pricebook2 customPB = [SELECT Id FROM Pricebook2 WHERE Name = 'Custom Pricebook' LIMIT 1];
        
        // Create custom pricebook entry with non-zero price
        PricebookEntry customPBE2 = new PricebookEntry(
            Pricebook2Id = customPB.Id,
            Product2Id = testProduct2.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert customPBE2;

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        OpportunityLineItem oli2 = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Product2Id = testProduct2.Id,
            Quantity = 1,
            UnitPrice = 100,
            PricebookEntryId = customPBE2.Id,
            Quality__c='High'
        );
        insert oli2;
        
        Test.startTest();
        SendEmail.sendEmailNotification(opp.Id);
        Test.stopTest();
    }

    @isTest
    static void testSendEmailNotificationQuote_WithNonZeroPricebookEntry() {
        // Create additional product
        Product2 testProduct2 = new Product2(
            Name = 'Test Product 2',
            IsActive = true
        );
        insert testProduct2;

        // Create standard pricebook entry first (required)
        PricebookEntry standardPBE2 = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProduct2.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert standardPBE2;

        Pricebook2 customPB = [SELECT Id FROM Pricebook2 WHERE Name = 'Custom Pricebook' LIMIT 1];
        
        // Create custom pricebook entry with non-zero price
        PricebookEntry customPBE2 = new PricebookEntry(
            Pricebook2Id = customPB.Id,
            Product2Id = testProduct2.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert customPBE2;

        Quote q = [SELECT Id FROM Quote LIMIT 1];
        
        QuoteLineItem qli2 = new QuoteLineItem(
            QuoteId = q.Id,
            Product2Id = testProduct2.Id,
            Quantity = 1,
            UnitPrice = 100,
            PricebookEntryId = customPBE2.Id,
            Quality__c='High'
        );
        insert qli2;
        
        Test.startTest();
        SendEmail.sendEmailNotificationQuote(q.Id);
        Test.stopTest();
    }

    @isTest
    static void testSendEmailNotification_OnlyZeroPriceItems() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Delete any existing items and create only zero price items
        List<OpportunityLineItem> existingItems = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :opp.Id];
        delete existingItems;

        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];
        PricebookEntry customPBE = [SELECT Id FROM PricebookEntry WHERE Pricebook2.Name = 'Custom Pricebook' LIMIT 1];
        
        OpportunityLineItem oli1 = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Product2Id = testProduct.Id,
            Quantity = 1,
            UnitPrice = 0,
            PricebookEntryId = customPBE.Id,
            Quality__c='High'
        );
        OpportunityLineItem oli2 = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Product2Id = testProduct.Id,
            Quantity = 2,
            UnitPrice = 0,
            PricebookEntryId = customPBE.Id,
            Quality__c='Medium'
        );
        insert new List<OpportunityLineItem>{oli1, oli2};
        
        Test.startTest();
        SendEmail.sendEmailNotification(opp.Id);
        Test.stopTest();
    }

    @isTest
    static void testSendEmailNotificationQuote_OnlyZeroPriceItems() {
        Quote q = [SELECT Id FROM Quote LIMIT 1];
        
        // Delete any existing items and create only zero price items
        List<QuoteLineItem> existingItems = [SELECT Id FROM QuoteLineItem WHERE QuoteId = :q.Id];
        delete existingItems;

        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];
        PricebookEntry customPBE = [SELECT Id FROM PricebookEntry WHERE Pricebook2.Name = 'Custom Pricebook' LIMIT 1];
        
        QuoteLineItem qli1 = new QuoteLineItem(
            QuoteId = q.Id,
            Product2Id = testProduct.Id,
            Quantity = 1,
            UnitPrice = 0,
            PricebookEntryId = customPBE.Id,
            Quality__c='Standard'
        );
        QuoteLineItem qli2 = new QuoteLineItem(
            QuoteId = q.Id,
            Product2Id = testProduct.Id,
            Quantity = 2,
            UnitPrice = 0,
            PricebookEntryId = customPBE.Id,
            Quality__c='Low'
        );
        insert new List<QuoteLineItem>{qli1, qli2};
        
        Test.startTest();
        SendEmail.sendEmailNotificationQuote(q.Id);
        Test.stopTest();
    }
}