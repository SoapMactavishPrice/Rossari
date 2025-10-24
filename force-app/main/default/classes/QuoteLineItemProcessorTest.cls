@IsTest
private class QuoteLineItemProcessorTest {

    @TestSetup
    static void setupTestData() {
        Id standardPricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            Id = standardPricebookId,
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

        Account acc = new Account(Name = 'Test Account', SAP_Customer_Code__c = 'SAP001');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            CloseDate = Date.today(),
            StageName = 'Prospecting',
            Pricebook2Id = standardPricebookId,
            AccountId = acc.Id
        );
        insert opp;

        Quote quote = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Pricebook2Id = standardPricebookId,
            SAP_Order_No__c = 'SAP123'
        );
        insert quote;

        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            Product2Id = prod.Id,
            Quantity = 5,
            UnitPrice = 100,
            PricebookEntryId = pbe.Id
        );
        insert qli;
    }

    @IsTest
    static void testQueueableProcessing() {
        List<QuoteLineItem> qlis = [SELECT Id FROM QuoteLineItem LIMIT 1];
        List<Id> qliIds = new List<Id>();
        for (QuoteLineItem qli : qlis) {
            qliIds.add(qli.Id);
        }

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        System.enqueueJob(new QuoteLineItemProcessor(qliIds));
        Test.stopTest();
    }

    @IsTest
    static void testQueueableChaining() {
        QuoteLineItem qli = [SELECT Id FROM QuoteLineItem LIMIT 1];
        List<Id> qliIds = new List<Id>{qli.Id};

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        System.enqueueJob(new QuoteLineItemProcessor(qliIds, 0));
        Test.stopTest();
    }

    @IsTest
    static void testEmptyList() {
        Test.startTest();
        System.enqueueJob(new QuoteLineItemProcessor(new List<Id>()));
        Test.stopTest();
    }

    @IsTest
    static void testErrorHandling() {
        Test.startTest();
        System.enqueueJob(new QuoteLineItemProcessor(new List<Id>{'001000000000000AAA'}, 0));
        Test.stopTest();
    }

    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success": true}');
            res.setStatusCode(200);
            return res;
        }
    }
}