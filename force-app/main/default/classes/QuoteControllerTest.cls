@isTest
public class QuoteControllerTest {
    
    @TestSetup
    static void setupTestData() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Contact testContact = new Contact(LastName = 'Test Contact', AccountId = testAccount.Id);
        insert testContact;
        
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount.Id
        );
        insert testOpp;
        
        Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true);
        insert testProduct;
        
        Pricebook2 standardPricebook = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
        
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
        System.assert(!result.isEmpty());
    }
    
    @IsTest
    static void testGetQuoteInitialData() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        Map<String, Object> result = QuoteController.getQuoteInitialData(testOpp.Id);
        Test.stopTest();
        System.assert(!result.isEmpty());
    }
    
    @IsTest
    static void testCreateQuoteFromOpportunity() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        OpportunityLineItem testOli = [SELECT Id, Product2Id, PricebookEntryId, UnitPrice, Quantity FROM OpportunityLineItem LIMIT 1];
        
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
        System.assert(quoteId != null);
    }
    
    @IsTest
    static void testDeleteProductInterested() {
        OpportunityLineItem testOli = [SELECT Id FROM OpportunityLineItem LIMIT 1];
        Test.startTest();
        String result = QuoteController.deleteProductInterested(testOli.Id);
        Test.stopTest();
        System.assert(result.contains('deleted'));
    }
}