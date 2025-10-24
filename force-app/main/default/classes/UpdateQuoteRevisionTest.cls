@isTest
private class UpdateQuoteRevisionTest {
    
    @testSetup
    static void setupTestData() {
        Id standardPricebookId = Test.getStandardPricebookId();

        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        try{
        update standardPricebook;
        }Catch(Exception e){}
    
        Base_UoM_Master__c baseUom = new Base_UoM_Master__c(Name = 'Kilogram');
        insert baseUom;
 
        Product2 prod = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP001',
            Pack_Size__c = '10kg',
            Base_UOM__c = baseUom.Id,
            IsActive = true
        );
        insert prod;
 
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

    }
    
    @isTest
    static void testQuoteRevisionUpdateOnQLIChange() {
        Id standardPbId = Test.getStandardPricebookId();
        
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
            Pricebook2Id = standardPbId
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
        
        Quote updatedQuote = [SELECT Id, Revision_No__c, Revision_Date__c FROM Quote WHERE Id = :testQuote.Id];
        Opportunity updatedOpp = [SELECT Id, StageName FROM Opportunity WHERE Id = :testOpp.Id];
    }
    
    @isTest
    static void testNoUpdateWhenNoChanges() {
        Id standardPbId = Test.getStandardPricebookId();
        
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
            Pricebook2Id = standardPbId
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
        Id standardPbId = Test.getStandardPricebookId();

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
            Pricebook2Id = standardPbId
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
        for(QuoteLineItem qli : qliList) {
            qli.Quantity += 5;
            qli.UnitPrice += 10;
        }
        update qliList;
        Test.stopTest();
        
        Quote updatedQuote = [SELECT Id, Revision_No__c FROM Quote WHERE Id = :testQuote.Id];
    }
}