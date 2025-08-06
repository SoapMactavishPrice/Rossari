@isTest
public class TestUpdateQuoteRevision {
    @isTest
    static void testRevisionIncrementOnUpdate() {
        Id standardPbId = Test.getStandardPricebookId(); // Ensure standard pricebook is available

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id
        );
        insert opp;

        Quote q = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Status = 'Draft',
            Pricebook2Id = standardPbId
        );
        insert q;

        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;

        PricebookEntry pbe = new PricebookEntry(
            Product2Id = prod.Id,
            Pricebook2Id = standardPbId,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = q.Id,
            Quantity = 1,
            UnitPrice = 100,
            PricebookEntryId = pbe.Id
        );
        insert qli;

        Test.startTest();
        qli.Quantity = 2;
        update qli;
        Test.stopTest();

        Quote updatedQuote = [SELECT Revision_No__c FROM Quote WHERE Id = :q.Id];
        System.assertEquals(1, updatedQuote.Revision_No__c, 'Revision number should increment to 1');
    }

    @isTest
    static void testNoRevisionWhenNoChange() {
        Id standardPbId = Test.getStandardPricebookId(); // Ensure standard pricebook is available

        Account acc = new Account(Name = 'Test Account 2');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity 2',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id
        );
        insert opp;

        Quote q = new Quote(
            Name = 'Test Quote 2',
            OpportunityId = opp.Id,
            Status = 'Draft',
            Pricebook2Id = standardPbId
        );
        insert q;

        Product2 prod = new Product2(Name = 'Test Product 2', IsActive = true);
        insert prod;

        PricebookEntry pbe = new PricebookEntry(
            Product2Id = prod.Id,
            Pricebook2Id = standardPbId,
            UnitPrice = 200,
            IsActive = true
        );
        insert pbe;

        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = q.Id,
            Quantity = 3,
            UnitPrice = 200,
            PricebookEntryId = pbe.Id
        );
        insert qli;

        Test.startTest();
        update qli; // No change
        Test.stopTest();

        Quote updatedQuote = [SELECT Revision_No__c FROM Quote WHERE Id = :q.Id];
        System.assertEquals(null, updatedQuote.Revision_No__c, 'Revision number should remain null if no relevant change');
    }
}