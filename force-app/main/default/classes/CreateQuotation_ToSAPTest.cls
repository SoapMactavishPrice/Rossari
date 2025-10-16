@isTest
public class CreateQuotation_ToSAPTest {

    @TestSetup
    static void setupTestData() {
        // Create Product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert testProduct;
        
        // Create Standard PricebookEntry
        PricebookEntry standardPBE = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProduct.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert standardPBE;

        // Create Account
        Account acc = new Account(Name = 'Test Account', SAP_Customer_Code__c = '1001017');
        insert acc;

        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert opp;

        // Create Sales Organisation data
        Sales_Organisation__c so = new Sales_Organisation__c(Name = '1000');
        insert so;

        Distribution_Channel__c dc = new Distribution_Channel__c(Name = 'DC1', Distribution_Code__c = '10');
        insert dc;

        Division__c div = new Division__c(Name = 'DIV1', Division_Code__c = '10');
        insert div;
    }

    @isTest
    static void testQuoteValidation_Success() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Quote q = new Quote(Name = 'Test Quote', OpportunityId = opp.Id, Status = 'Accepted');
        insert q;

        Test.startTest();
        String result = CreateQuotation_ToSAP.quoteValidation(q.Id);
        Test.stopTest();

        Map<String, Object> resultMap = (Map<String, Object>)JSON.deserializeUntyped(result);
        System.assertEquals('true', resultMap.get('status'), 'Quote validation should pass for Accepted status');
    }

    @isTest
    static void testQuoteValidation_NotAccepted() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Quote q = new Quote(Name = 'Test Quote Not Accepted', OpportunityId = opp.Id, Status = 'Draft');
        insert q;

        Test.startTest();
        String result = CreateQuotation_ToSAP.quoteValidation(q.Id);
        Test.stopTest();

        Map<String, Object> resultMap = (Map<String, Object>)JSON.deserializeUntyped(result);
        System.assertEquals('false', resultMap.get('status'), 'Quote validation should fail for non-Accepted status');
        System.assertEquals('Quote status is not Accepted', resultMap.get('message'));
    }

    @isTest
    static void testQuoteValidation_AlreadySynced() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Quote q = new Quote(Name = 'Test Quote Synced', OpportunityId = opp.Id, Status = 'Accepted', SAP_Order_No__c = 'SO123456');
        insert q;

        Test.startTest();
        String result = CreateQuotation_ToSAP.quoteValidation(q.Id);
        Test.stopTest();

        Map<String, Object> resultMap = (Map<String, Object>)JSON.deserializeUntyped(result);
        System.assertEquals('false', resultMap.get('status'), 'Quote validation should fail when already synced');
        System.assertEquals('Quotation already sent to SAP', resultMap.get('message'));
    }

    @isTest
    static void testGetLineItem() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Quote q = new Quote(Name = 'Test Quote', OpportunityId = opp.Id, Status = 'Accepted');
        insert q;

        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :prod.Id LIMIT 1];

        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = q.Id, 
            Product2Id = prod.Id, 
            Quantity = 1, 
            UnitPrice = 100, 
            PricebookEntryId = pbe.Id
        );
        insert qli;

        Test.startTest();
        String result = CreateQuotation_ToSAP.getLineItem(q.Id);
        Test.stopTest();

        Map<String, Object> resultMap = (Map<String, Object>)JSON.deserializeUntyped(result);
        List<Object> lineItems = (List<Object>)resultMap.get('quoteLineItemList');
        System.assert(!lineItems.isEmpty(), 'Should return quote line items');
    }

    @isTest
    static void testGetLineItem_NoItems() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Quote q = new Quote(Name = 'Test Quote Empty', OpportunityId = opp.Id, Status = 'Accepted');
        insert q;

        Test.startTest();
        String result = CreateQuotation_ToSAP.getLineItem(q.Id);
        Test.stopTest();

        Map<String, Object> resultMap = (Map<String, Object>)JSON.deserializeUntyped(result);
        List<Object> lineItems = (List<Object>)resultMap.get('quoteLineItemList');
        System.assertEquals(0, lineItems.size(), 'Should return empty list when no line items');
    }

    @isTest
    static void testCreateQuotation_Success() {
        // Setup mock callout
        Test.setMock(HttpCalloutMock.class, new SAPCalloutMock(true));
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Sales_Organisation__c so = [SELECT Id FROM Sales_Organisation__c LIMIT 1];
        Distribution_Channel__c dc = [SELECT Id FROM Distribution_Channel__c LIMIT 1];
        Division__c div = [SELECT Id FROM Division__c LIMIT 1];

        Quote q = new Quote(
            Name = 'Test Quote', 
            OpportunityId = opp.Id, 
            Status = 'Accepted',
            Sales_Organisations__c = so.Id,
            Distribution_Channel__c = dc.Id,
            Division__c = div.Id,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert q;

        Test.startTest();
        String result = CreateQuotation_ToSAP.createQuotation(q.Id);
        Test.stopTest();

        // Verify the quote was updated with SAP order number
        Quote updatedQuote = [SELECT SAP_Order_No__c FROM Quote WHERE Id = :q.Id];
        System.assertNotEquals(null, updatedQuote.SAP_Order_No__c, 'SAP Order Number should be set');
    }

    @isTest
    static void testCreateQuotation_Failure() {
        // Setup mock callout that fails
        Test.setMock(HttpCalloutMock.class, new SAPCalloutMock(false));
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Sales_Organisation__c so = [SELECT Id FROM Sales_Organisation__c LIMIT 1];
        Distribution_Channel__c dc = [SELECT Id FROM Distribution_Channel__c LIMIT 1];
        Division__c div = [SELECT Id FROM Division__c LIMIT 1];

        Quote q = new Quote(
            Name = 'Test Quote', 
            OpportunityId = opp.Id, 
            Status = 'Accepted',
            Sales_Organisations__c = so.Id,
            Distribution_Channel__c = dc.Id,
            Division__c = div.Id,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert q;

        Test.startTest();
        String result = CreateQuotation_ToSAP.createQuotation(q.Id);
        Test.stopTest();

        // Verify API log was created with failed status
        List<API_log__c> logs = [SELECT Status__c FROM API_log__c WHERE Name LIKE 'Create_Quotation_Header%'];
        System.assert(!logs.isEmpty(), 'API log should be created');
        System.assertEquals('Failed', logs[0].Status__c, 'API log should show failed status');
    }

    @isTest
    static void testAddItem_Success() {
        // Setup mock callout
        Test.setMock(HttpCalloutMock.class, new SAPCalloutMock(true));
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Quote q = new Quote(
            Name = 'Test Quote', 
            OpportunityId = opp.Id, 
            Status = 'Accepted', 
            SAP_Order_No__c = 'SO123',
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert q;

        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :prod.Id LIMIT 1];

        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = q.Id, 
            Product2Id = prod.Id, 
            Quantity = 1, 
            UnitPrice = 100, 
            PricebookEntryId = pbe.Id
        );
        insert qli;

        qli = [SELECT Id, Product2Id, Product2.ProductCode, QuoteId, Quantity, Quote.SAP_Order_No__c 
               FROM QuoteLineItem WHERE Id = :qli.Id];

        Test.startTest();
        CreateQuotation_ToSAP.addItem(qli);
        Test.stopTest();

        // Verify API log was created
        List<API_log__c> logs = [SELECT Status__c FROM API_log__c WHERE Name LIKE 'Create_Quotation_Line%'];
        System.assert(!logs.isEmpty(), 'API log should be created for line item');
        System.assertEquals('Success', logs[0].Status__c, 'API log should show success status');
    }

    @isTest
    static void testAddItem_Failure() {
        // Setup mock callout that fails
        Test.setMock(HttpCalloutMock.class, new SAPCalloutMock(false));
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Quote q = new Quote(
            Name = 'Test Quote', 
            OpportunityId = opp.Id, 
            Status = 'Accepted', 
            SAP_Order_No__c = 'SO123',
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert q;

        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :prod.Id LIMIT 1];

        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = q.Id, 
            Product2Id = prod.Id, 
            Quantity = 1, 
            UnitPrice = 100, 
            PricebookEntryId = pbe.Id
        );
        insert qli;

        qli = [SELECT Id, Product2Id, Product2.ProductCode, QuoteId, Quantity, Quote.SAP_Order_No__c 
               FROM QuoteLineItem WHERE Id = :qli.Id];

        Test.startTest();
        try {
            CreateQuotation_ToSAP.addItem(qli);
            System.assert(false, 'Expected exception was not thrown');
        } catch (Exception e) {
            System.assert(e instanceof CalloutException, 'Expected CalloutException');
        }
        Test.stopTest();

        // Verify API log was created with failed status
        List<API_log__c> logs = [SELECT Status__c FROM API_log__c WHERE Name LIKE 'Create_Quotation_Line%'];
        System.assert(!logs.isEmpty(), 'API log should be created for line item');
        System.assertEquals('Failed', logs[0].Status__c, 'API log should show failed status');
    }

    @isTest
    static void testSyncQuoteLineItems() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Quote q = new Quote(
            Name = 'Test Quote', 
            OpportunityId = opp.Id, 
            Status = 'Accepted', 
            SAP_Order_No__c = 'SO123',
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert q;

        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :prod.Id LIMIT 1];

        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = q.Id, 
            Product2Id = prod.Id, 
            Quantity = 1, 
            UnitPrice = 100, 
            PricebookEntryId = pbe.Id
        );
        insert qli;

        Test.startTest();
        String result = CreateQuotation_ToSAP.syncQuoteLineItems(q.Id);
        Test.stopTest();

        System.assert(result.contains('Started processing'), 'Should return success message');
        System.assert(result.contains('1 items'), 'Should mention the number of items');
    }

    @isTest
    static void testSyncQuoteLineItems_NoItems() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Quote q = new Quote(
            Name = 'Test Quote Empty', 
            OpportunityId = opp.Id, 
            Status = 'Accepted', 
            SAP_Order_No__c = 'SO123',
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert q;

        Test.startTest();
        String result = CreateQuotation_ToSAP.syncQuoteLineItems(q.Id);
        Test.stopTest();

        System.assertEquals('No valid quote line items found. Please ensure all items have a product and quantity.', result);
    }

    @isTest
    static void testQuoteValidation_Exception() {
        Test.startTest();
        try {
            CreateQuotation_ToSAP.quoteValidation('invalid_id');
            System.assert(false, 'Expected exception was not thrown');
        } catch (Exception e) {
            System.assert(e instanceof AuraHandledException, 'Expected AuraHandledException');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetLineItem_Exception() {
        Test.startTest();
        try {
            CreateQuotation_ToSAP.getLineItem('invalid_id');
        } catch (Exception e) {
            // Expected behavior
        }
        Test.stopTest();
    }

    @isTest
    static void testMultipleQuoteScenarios() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Sales_Organisation__c so = [SELECT Id FROM Sales_Organisation__c LIMIT 1];
        Distribution_Channel__c dc = [SELECT Id FROM Distribution_Channel__c LIMIT 1];
        Division__c div = [SELECT Id FROM Division__c LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :prod.Id LIMIT 1];

        // Test multiple quotes with different scenarios
        List<Quote> quotes = new List<Quote>();
        for(Integer i = 0; i < 3; i++) {
            quotes.add(new Quote(
                Name = 'Test Quote ' + i,
                OpportunityId = opp.Id,
                Status = 'Accepted',
                Sales_Organisations__c = so.Id,
                Distribution_Channel__c = dc.Id,
                Division__c = div.Id,
                Pricebook2Id = Test.getStandardPricebookId()
            ));
        }
        insert quotes;

        // Create quote line items for each quote
        List<QuoteLineItem> qlis = new List<QuoteLineItem>();
        for(Quote q : quotes) {
            qlis.add(new QuoteLineItem(
                QuoteId = q.Id,
                Product2Id = prod.Id,
                Quantity = 1,
                UnitPrice = 100,
                PricebookEntryId = pbe.Id
            ));
        }
        insert qlis;

        Test.startTest();
        for(Quote q : quotes) {
            String validationResult = CreateQuotation_ToSAP.quoteValidation(q.Id);
            Map<String, Object> resultMap = (Map<String, Object>)JSON.deserializeUntyped(validationResult);
            System.assertEquals('true', resultMap.get('status'), 'All quotes should pass validation');
        }
        Test.stopTest();
    }

    @isTest
    static void testQuoteWithMultipleLineItems() {
        // Setup mock callout
        Test.setMock(HttpCalloutMock.class, new SAPCalloutMock(true));
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Sales_Organisation__c so = [SELECT Id FROM Sales_Organisation__c LIMIT 1];
        Distribution_Channel__c dc = [SELECT Id FROM Distribution_Channel__c LIMIT 1];
        Division__c div = [SELECT Id FROM Division__c LIMIT 1];

        Quote q = new Quote(
            Name = 'Multi Item Quote', 
            OpportunityId = opp.Id, 
            Status = 'Accepted',
            Sales_Organisations__c = so.Id,
            Distribution_Channel__c = dc.Id,
            Division__c = div.Id,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert q;

        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :prod.Id LIMIT 1];

        // Create multiple quote line items
        List<QuoteLineItem> qlis = new List<QuoteLineItem>();
        for(Integer i = 0; i < 5; i++) {
            qlis.add(new QuoteLineItem(
                QuoteId = q.Id,
                Product2Id = prod.Id,
                Quantity = i + 1,
                UnitPrice = 100 + (i * 10),
                PricebookEntryId = pbe.Id
            ));
        }
        insert qlis;

        Test.startTest();
        String lineItemsResult = CreateQuotation_ToSAP.getLineItem(q.Id);
        Map<String, Object> resultMap = (Map<String, Object>)JSON.deserializeUntyped(lineItemsResult);
        List<Object> lineItems = (List<Object>)resultMap.get('quoteLineItemList');
        System.assertEquals(5, lineItems.size(), 'Should return all 5 line items');
        Test.stopTest();
    }

    // Mock class for SAP callouts
    private class SAPCalloutMock implements HttpCalloutMock {
        private Boolean success;
        
        public SAPCalloutMock(Boolean success) {
            this.success = success;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            if (success) {
                res.setStatusCode(201);
                res.setBody('<?xml version="1.0" encoding="utf-8"?>' +
                           '<Sales_InquirySet>' +
                           '<Sales_Inquiry>' +
                           '<Return>' +
                           '<Message>Success</Message>' +
                           '</Return>' +
                           '<SalesDocument>SO123456</SalesDocument>' +
                           '</Sales_Inquiry>' +
                           '</Sales_InquirySet>');
            } else {
                res.setStatusCode(400);
                res.setBody('{"error": "Failed to create quotation"}');
            }
            
            return res;
        }
    }
}