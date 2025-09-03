@isTest
public class QuoteControllerTest {
    
    @TestSetup
    static void setupTestData() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Contact testContact = new Contact(LastName = 'Test Contact', AccountId = testAccount.Id);
        insert testContact;
        
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount.Id,
            Pricebook2Id = standardPricebook.Id
        );
        insert testOpp;
        
        Product2 testProduct = new Product2(
            Name = 'Test Product', 
            IsActive = true
        );
        insert testProduct;
        
        PricebookEntry testPbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert testPbe;
        
        OpportunityLineItem testOli = new OpportunityLineItem(
            OpportunityId = testOpp.Id,
            PricebookEntryId = testPbe.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert testOli;
    }
    
    @IsTest
    static void testGetOppLineItems() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        List<OpportunityLineItem> result = QuoteController.getOppLineItems(testOpp.Id);
        Test.stopTest();
    }
    
    @IsTest
    static void testGetQuoteInitialData() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        Map<String, Object> result = QuoteController.getQuoteInitialData(testOpp.Id);
        Test.stopTest();
    }
    
    @IsTest
    static void testCreateQuoteFromOpportunity() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        OpportunityLineItem testOli = [
            SELECT Id, Product2Id, Discount, Description, PricebookEntryId, UnitPrice, Quantity 
            FROM OpportunityLineItem 
            LIMIT 1
        ];
        Test.startTest();
        Id quoteId = QuoteController.createQuoteFromOpportunity(
            testOpp.Id,
            new List<OpportunityLineItem>{testOli},
            'Test Quote',
            'Draft',
            Date.today().addDays(30),
            'USD',
            null,
            null
        );
        Test.stopTest();
    }
    
    @IsTest
    static void testDeleteProductInterested() {
        OpportunityLineItem testOli = [SELECT Id FROM OpportunityLineItem LIMIT 1];
        Test.startTest();
        String result = QuoteController.deleteProductInterested(testOli.Id);
        Test.stopTest();
    }
    
    @IsTest
    static void testGetOppLineItems_NoItems() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Pricebook2 standardPricebook = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
        Opportunity emptyOpp = new Opportunity(
            Name = 'Empty Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount.Id,
            Pricebook2Id = standardPricebook.Id
        );
        insert emptyOpp;
        
        Test.startTest();
        List<OpportunityLineItem> result = QuoteController.getOppLineItems(emptyOpp.Id);
        Test.stopTest();
    }
    
    @IsTest
    static void testCreateQuoteFromOpportunity_WithNullValues() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        OpportunityLineItem testOli = [
            SELECT Id, Product2Id, Discount, Description, PricebookEntryId, UnitPrice, Quantity 
            FROM OpportunityLineItem 
            LIMIT 1
        ];
        Test.startTest();
        Id quoteId = QuoteController.createQuoteFromOpportunity(
            testOpp.Id,
            new List<OpportunityLineItem>{testOli},
            'Test Quote Null',
            'Draft',
            null,
            null,
            null,
            null
        );
        Test.stopTest();
    }
    
    @IsTest
    static void testDeleteProductInterested_InvalidId() {
        Test.startTest();
        String result = QuoteController.deleteProductInterested('001000000000000');
        Test.stopTest();
    }
    
    @IsTest
    static void testCreateQuoteFromOpportunity_EmptyLineItems() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        Id quoteId = QuoteController.createQuoteFromOpportunity(
            testOpp.Id,
            new List<OpportunityLineItem>(),
            'Test Empty Quote',
            'Draft',
            Date.today().addDays(30),
            'USD',
            null,
            null
        );
        Test.stopTest();
    }
    
    @IsTest
    static void testValidateQuoteApprovalStatus() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert opp;
        
        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;
        
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;
        
        Quote quote = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Status = 'Draft',
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert quote;
        
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            Product2Id = prod.Id,
            PricebookEntryId = pbe.Id,
            UnitPrice = 90,
            Quantity = 1,
            Approval_Status__c = 'Pending'
        );
        insert qli;
        
        quote.Status = 'Accepted';
        Map<Id, Quote> oldMap = new Map<Id, Quote>{
            quote.Id => new Quote(
                Id = quote.Id,
                Status = 'Draft'
            )
                };
                    
                    Test.startTest();
        QuoteController.validateQuoteApprovalStatus(new List<Quote>{quote}, oldMap);
        Test.stopTest();
    }
    
}