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

        Id standardPricebookId = Test.getStandardPricebookId(); // ✅ Reference only, no update

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


        Quote quote = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Pricebook2Id = standardPricebookId,
            Status = 'Draft'
        );
        insert quote;

        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            PricebookEntryId = pbe.Id,
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