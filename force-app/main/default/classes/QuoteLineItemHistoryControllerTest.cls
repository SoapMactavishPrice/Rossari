@isTest
public class QuoteLineItemHistoryControllerTest {

    @isTest
    static void testGetQuoteLineItemHistory() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10)
        );
        insert opp;

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

        Quote quote = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Pricebook2Id = standardPricebook.Id,
            Status = 'Draft'
        );
        insert quote;

        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            PricebookEntryId = standardPBE.Id,
            Quantity = 5,
            UnitPrice = 100.0
        );
        insert qli;

        QuoteLineItemHistory history1 = new QuoteLineItemHistory(
            Field = 'Quantity',
            QuoteLineItemId = qli.Id
        );
        QuoteLineItemHistory history2 = new QuoteLineItemHistory(
            Field = 'UnitPrice',
            QuoteLineItemId = qli.Id
        );
        insert new List<QuoteLineItemHistory>{ history1, history2 };

        Test.startTest();
        List<QuoteLineItemHistoryController.QuoteLineItemHistoryWrapper> results =
            QuoteLineItemHistoryController.getQuoteLineItemHistory(quote.Id);
        Test.stopTest();

    }
}