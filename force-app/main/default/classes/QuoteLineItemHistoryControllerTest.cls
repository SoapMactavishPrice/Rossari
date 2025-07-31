@isTest
public class QuoteLineItemHistoryControllerTest {

    @isTest
    static void testGetQuoteLineItemHistory() {
        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10)
        );
        insert opp;

        // Activate Standard Pricebook
        Id stdPricebookId = Test.getStandardPricebookId();

        // Create Product
        Product2 prod = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert prod;

        // Create PricebookEntry
        PricebookEntry pbe = new PricebookEntry(
            Product2Id = prod.Id,
            Pricebook2Id = stdPricebookId,
            UnitPrice = 100.0,
            IsActive = true
        );
        insert pbe;

        // Create Quote
        Quote quote = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Pricebook2Id = stdPricebookId,
            Status = 'Draft'
        );
        insert quote;

        // Create Quote Line Item
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 5,
            UnitPrice = 100.0
        );
        insert qli;

        // Create History Records manually (Note: Normally Salesforce manages History records, but we insert them for testing)
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