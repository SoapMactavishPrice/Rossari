@isTest
public class QuoteControllerTest {

    @testSetup
    static void setupTestData() {
        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id
        );
        insert opp;

        // Create Product
        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;

        // Activate Standard Pricebook
        Id standardPBId = Test.getStandardPricebookId();
        
       Pricebook2 standardpricebook = new Pricebook2(
           Name = 'Test Pricebook 2', 
           IsActive = true
       );
        insert standardpricebook ;
        
        if (!standardpricebook.IsActive) {
            standardpricebook.IsActive = true;
            update standardpricebook;
        }

        // Create PricebookEntry
        PricebookEntry pbe = new PricebookEntry(
            Product2Id = prod.Id,
            Pricebook2Id = standardPBId,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        // Create OpportunityLineItem
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Product2Id = prod.Id,
            PricebookEntryId = pbe.Id,
            UnitPrice = 100,
            Quantity = 2,
            Description = 'Test Description'
        );
        insert oli;
    }

    @isTest
    static void testGetOppLineItems() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        List<OpportunityLineItem> items = QuoteController.getOppLineItems(opp.Id);
        Test.stopTest();

    }

    @isTest
    static void testCreateQuoteFromOpportunity() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        OpportunityLineItem oli = [SELECT Id, Product2Id, PricebookEntryId, UnitPrice, Quantity, Description FROM OpportunityLineItem WHERE OpportunityId = :opp.Id LIMIT 1];

        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>{ oli };

        Test.startTest();
        Id quoteId = QuoteController.createQuoteFromOpportunity(
            opp.Id,
            oliList,
            'USD',
            Test.getStandardPricebookId()
        );
        Test.stopTest();


        List<QuoteLineItem> qliList = [SELECT Id FROM QuoteLineItem WHERE QuoteId = :quoteId];
    }

    @isTest
    static void testDeleteProductInterested_found() {
        OpportunityLineItem oli = [SELECT Id FROM OpportunityLineItem LIMIT 1];

        Test.startTest();
        String msg = QuoteController.deleteProductInterested(oli.Id);
        Test.stopTest();

    }

    @isTest
    static void testDeleteProductInterested_notFound() {
        Test.startTest();
        String msg = QuoteController.deleteProductInterested('001000000000000AAA'); 
        Test.stopTest();

    }
}