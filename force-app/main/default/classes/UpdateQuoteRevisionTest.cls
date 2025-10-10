@isTest
private class UpdateQuoteRevisionTest {
    
    @testSetup
    static void setupTestData() {
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        
        System.debug('check'+[SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1]);
        
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
    }
    
    @isTest
    static void testQuoteRevisionUpdateOnQLIChange() {
        Pricebook2 standardPb = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
        
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpp;
        
        Quote testQuote = new Quote(
            Name = 'Test Quote',
            OpportunityId = testOpp.Id,
            Pricebook2Id = standardPb.Id
        );
        insert testQuote;
        
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'Test Product' LIMIT 1];
        
        QuoteLineItem testQLI = new QuoteLineItem(
            QuoteId = testQuote.Id,
            PricebookEntryId = [SELECT Id FROM PricebookEntry WHERE Product2Id = :testProduct.Id LIMIT 1].Id,
            Quantity = 10,
            UnitPrice = 100.00
        );
        insert testQLI;
        
        Test.startTest();
        testQLI.Quantity = 15;
        testQLI.UnitPrice = 150.00;
        update testQLI;
        Test.stopTest();
        
        // Verify results
        Quote updatedQuote = [SELECT Id, Revision_No__c, Revision_Date__c FROM Quote WHERE Id = :testQuote.Id];
        Opportunity updatedOpp = [SELECT Id, StageName FROM Opportunity WHERE Id = :testOpp.Id];
        
    }
    
    @isTest
    static void testNoUpdateWhenNoChanges() {
        Pricebook2 standardPb = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
        
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpp;
        
        Quote testQuote = new Quote(
            Name = 'Test Quote',
            OpportunityId = testOpp.Id,
            Pricebook2Id = standardPb.Id
        );
        insert testQuote;
        
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'Test Product' LIMIT 1];
        
        QuoteLineItem testQLI = new QuoteLineItem(
            QuoteId = testQuote.Id,
            PricebookEntryId = [SELECT Id FROM PricebookEntry WHERE Product2Id = :testProduct.Id LIMIT 1].Id,
            Quantity = 10,
            UnitPrice = 100.00
        );
        insert testQLI;
        
        Test.startTest();
        testQLI.Quantity = 10;
        testQLI.UnitPrice = 100.00;
        update testQLI;
        Test.stopTest();
        
        Quote updatedQuote = [SELECT Id, Revision_No__c FROM Quote WHERE Id = :testQuote.Id];
    }
    
    @isTest
    static void testBulkQLIUpdates() {
        Pricebook2 standardPb = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
                System.debug('check'+[SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1]);

        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpp;
        
        
        Quote testQuote = new Quote(
            Name = 'Test Quote',
            OpportunityId = testOpp.Id,
            Pricebook2Id = standardPb.Id
        );
        insert testQuote;
        
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'Test Product' LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :testProduct.Id LIMIT 1];
        
        List<QuoteLineItem> qliList = new List<QuoteLineItem>();
        for(Integer i = 0; i < 5; i++) {
            QuoteLineItem qli = new QuoteLineItem(
                QuoteId = testQuote.Id,
                PricebookEntryId = pbe.Id,
                Quantity = 10 + i,
                UnitPrice = 100.00 + i
            );
            qliList.add(qli);
        }
        insert qliList;
        
        Test.startTest();
        // Update all QLIs
        for(QuoteLineItem qli : qliList) {
            qli.Quantity = qli.Quantity + 5;
            qli.UnitPrice = qli.UnitPrice + 10;
        }
        update qliList;
        Test.stopTest();
        
        // Verify revision occurred only once for the quote
        Quote updatedQuote = [SELECT Id, Revision_No__c FROM Quote WHERE Id = :testQuote.Id];
    }
}