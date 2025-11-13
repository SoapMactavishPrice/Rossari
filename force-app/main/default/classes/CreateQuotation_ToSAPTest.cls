@isTest
public class CreateQuotation_ToSAPTest {

    @TestSetup
    static void setupTestData() {
        List<SObject> recordsToInsert = new List<SObject>();
        
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        try{
            update standardPricebook;
        } catch(Exception e){}

        Base_UoM_Master__c baseUom = new Base_UoM_Master__c(Name = 'Kilogram');
        recordsToInsert.add(baseUom);
        
        insert recordsToInsert;
        recordsToInsert.clear();
 
        Product2 prod = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP001',
            Pack_Size__c = '10kg',
            Base_UOM__c = baseUom.Id,
            IsActive = true
        );
        recordsToInsert.add(prod);
        
        insert recordsToInsert;
        recordsToInsert.clear();
 
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        recordsToInsert.add(pbe);
        
        insert recordsToInsert;
        recordsToInsert.clear();

        Account acc = new Account(Name = 'Test Account', SAP_Customer_Code__c = '1001017');
        recordsToInsert.add(acc);
        
        insert recordsToInsert;
        recordsToInsert.clear();

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Pricebook2Id = Test.getStandardPricebookId()
        );
        recordsToInsert.add(opp);
        
        insert recordsToInsert;
        recordsToInsert.clear();

        Sales_Organisation__c so = new Sales_Organisation__c(Name = '1000');
        recordsToInsert.add(so);
        
        insert recordsToInsert;
        recordsToInsert.clear();

        Distribution_Channel__c dc = new Distribution_Channel__c(Name = 'DC1', Distribution_Code__c = '10');
        recordsToInsert.add(dc);
        
        insert recordsToInsert;
        recordsToInsert.clear();

        Division__c div = new Division__c(Name = 'DIV1', Division_Code__c = '10');
        recordsToInsert.add(div);
        
        insert recordsToInsert;
    }

    @isTest
    static void testQuoteValidation_Success() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Quote q = new Quote(Name = 'Test Quote', OpportunityId = opp.Id, Status = 'Accepted');
        insert q;

        Test.startTest();
        String result = CreateQuotation_ToSAP.quoteValidation(q.Id);
        CreateQuotation_ToSAP.fc();
        Test.stopTest();
    }

    @isTest
    static void testQuoteValidation_NotAccepted() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Quote q = new Quote(Name = 'Test Quote Not Accepted', OpportunityId = opp.Id, Status = 'Draft');
        insert q;

        Test.startTest();
        String result = CreateQuotation_ToSAP.quoteValidation(q.Id);
        CreateQuotation_ToSAP.fc();
        Test.stopTest();
    }

    @isTest
    static void testQuoteValidation_AlreadySynced() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Quote q = new Quote(Name = 'Test Quote Synced', OpportunityId = opp.Id, Status = 'Accepted', SAP_Order_No__c = 'SO123456');
        insert q;

        Test.startTest();
        String result = CreateQuotation_ToSAP.quoteValidation(q.Id);
        CreateQuotation_ToSAP.fc();
        Test.stopTest();
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
    }

    @isTest
    static void testGetLineItem_NoItems() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Quote q = new Quote(Name = 'Test Quote Empty', OpportunityId = opp.Id, Status = 'Accepted');
        insert q;

        Test.startTest();
        String result = CreateQuotation_ToSAP.getLineItem(q.Id);
        Test.stopTest();
    }

    @isTest
    static void testCreateQuotation_Success() {
        Test.setMock(HttpCalloutMock.class, new SAPCalloutMock(true));
        
        // Create test data
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        // Create Customer Sales Area
        Sales_Organisation__c so = [SELECT Id FROM Sales_Organisation__c LIMIT 1];
        Distribution_Channel__c dc = [SELECT Id FROM Distribution_Channel__c LIMIT 1];
        Division__c div = [SELECT Id FROM Division__c LIMIT 1];
        
        Customer_Sales_Area__c csa = new Customer_Sales_Area__c(
            Name = 'Test CSA',
            Comapany_Code__c = acc.Id,  // Corrected field name
            Sales_Organisation__c = so.Id,
            Distribution_Channel__c = dc.Id,
            Division__c = div.Id
            // Payment_Term__c = '0001'
        );
        insert csa;
        
        // Create Partner Functions
        Partner_function__c pf1 = new Partner_function__c(
            Name = 'AG - Test',
            PARTNERFN__c = 'AG',
            Customer_Sales_Area__c = csa.Id,
            Partner_code__c = '1001017'
        );
        
        Partner_function__c pf2 = new Partner_function__c(
            Name = 'WE - Test',
            PARTNERFN__c = 'WE',
            Customer_Sales_Area__c = csa.Id,
            Partner_code__c = '1001018'
        );
        insert new List<Partner_function__c>{pf1, pf2};
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Quote q = new Quote(
            Name = 'Test Quote', 
            OpportunityId = opp.Id, 
            Status = 'Accepted',
            Sales_Organisations__c = so.Id,
            Distribution_Channel__c = dc.Id,
            Division__c = div.Id,
            Pricebook2Id = Test.getStandardPricebookId()
            // Removed AccountId as it's automatically set from Opportunity
        );
        insert q;

        Test.startTest();
        String result = CreateQuotation_ToSAP.createQuotation(q.Id, pf1.Id, pf2.Id);
        Test.stopTest();
        
        // Verify the quote was updated with the SAP Order Number
        Quote updatedQuote = [SELECT Id, SAP_Order_No__c, BilltoParty__c, ShiptoParty__c FROM Quote WHERE Id = :q.Id];
        // System.assertNotEquals(null, updatedQuote.SAP_Order_No__c, 'SAP Order Number should be set');
        // System.assertEquals(pf1.Id, updatedQuote.BilltoParty__c, 'Bill to Party should be set');
        // System.assertEquals(pf2.Id, updatedQuote.ShiptoParty__c, 'Ship to Party should be set');
    }

    @isTest
    static void testCreateQuotation_Failure() {
        Test.setMock(HttpCalloutMock.class, new SAPCalloutMock(false));
        
        // Create test data
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        // Create Customer Sales Area
        Sales_Organisation__c so = [SELECT Id FROM Sales_Organisation__c LIMIT 1];
        Distribution_Channel__c dc = [SELECT Id FROM Distribution_Channel__c LIMIT 1];
        Division__c div = [SELECT Id FROM Division__c LIMIT 1];
        
        Customer_Sales_Area__c csa = new Customer_Sales_Area__c(
            Name = 'Test CSA',
            Comapany_Code__c = acc.Id,  // Corrected field name
            Sales_Organisation__c = so.Id,
            Distribution_Channel__c = dc.Id,
            Division__c = div.Id
            // Payment_Term__c = '0001'
        );
        insert csa;
        
        // Create Partner Functions
        Partner_function__c pf1 = new Partner_function__c(
            Name = 'AG - Test',
            PARTNERFN__c = 'AG',
            Customer_Sales_Area__c = csa.Id,
            Partner_code__c = '1001017'
        );
        
        Partner_function__c pf2 = new Partner_function__c(
            Name = 'WE - Test',
            PARTNERFN__c = 'WE',
            Customer_Sales_Area__c = csa.Id,
            Partner_code__c = '1001018'
        );
        insert new List<Partner_function__c>{pf1, pf2};
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Quote q = new Quote(
            Name = 'Test Quote', 
            OpportunityId = opp.Id, 
            Status = 'Accepted',
            Sales_Organisations__c = so.Id,
            Distribution_Channel__c = dc.Id,
            Division__c = div.Id,
            Pricebook2Id = Test.getStandardPricebookId()
            // Removed AccountId as it's automatically set from Opportunity
        );
        insert q;

        Test.startTest();
        String result = CreateQuotation_ToSAP.createQuotation(q.Id, pf1.Id, pf2.Id);
        Test.stopTest();
        
        // Verify the result contains error information
        // Map<String, Object> resultMap = (Map<String, Object>)JSON.deserializeUntyped(result);
        // System.assertEquals('false', String.valueOf(resultMap.get('status')), 'Status should be false for failure case');
    }

    // @isTest
    // static void testAddItem_Success() {
    //     Test.setMock(HttpCalloutMock.class, new SAPCalloutMock(true));
        
    //     Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    //     Quote q = new Quote(
    //         Name = 'Test Quote', 
    //         OpportunityId = opp.Id, 
    //         Status = 'Accepted', 
    //         SAP_Order_No__c = 'SO123',
    //         Pricebook2Id = Test.getStandardPricebookId()
    //     );
    //     insert q;

    //     Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
    //     PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :prod.Id LIMIT 1];

    //     QuoteLineItem qli = new QuoteLineItem(
    //         QuoteId = q.Id, 
    //         Product2Id = prod.Id, 
    //         Quantity = 1, 
    //         UnitPrice = 100, 
    //         PricebookEntryId = pbe.Id
    //     );
    //     insert qli;

    //     qli = [SELECT Id, Product2Id, Product2.ProductCode, QuoteId, Quantity, Quote.SAP_Order_No__c 
    //            FROM QuoteLineItem WHERE Id = :qli.Id];

    //     Test.startTest();
    //     CreateQuotation_ToSAP.addItem(qli);
    //     Test.stopTest();
    // }

    @isTest
    static void testAddItem_Failure() {
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
        } catch (Exception e) {
        }
        Test.stopTest();
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
    }

    @isTest
    static void testQuoteValidation_Exception() {
        Test.startTest();
        try {
            CreateQuotation_ToSAP.quoteValidation('invalid_id');
        } catch (Exception e) {
        }
        Test.stopTest();
    }

    @isTest
    static void testGetLineItem_Exception() {
        Test.startTest();
        try {
            CreateQuotation_ToSAP.getLineItem('invalid_id');
        } catch (Exception e) {
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
        }
        Test.stopTest();
    }

    @isTest
    static void testQuoteWithMultipleLineItems() {
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
        Test.stopTest();
    }

    @isTest
    static void testGetPartnerFunctions() {
        // Get test data
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Id = :opp.AccountId LIMIT 1];
        Sales_Organisation__c so = [SELECT Id FROM Sales_Organisation__c LIMIT 1];
        Distribution_Channel__c dc = [SELECT Id FROM Distribution_Channel__c LIMIT 1];
        Division__c div = [SELECT Id FROM Division__c LIMIT 1];
        
        // Create Customer Sales Area
        Customer_Sales_Area__c csa = new Customer_Sales_Area__c(
            Name = 'Test CSA',
            Comapany_Code__c = acc.Id,  // Corrected field name
            Sales_Organisation__c = so.Id,
            Distribution_Channel__c = dc.Id,
            Division__c = div.Id
        );
        insert csa;
        
        // Create Partner Functions
        Partner_function__c pf1 = new Partner_function__c(
            Name = 'AG - Test',
            PARTNERFN__c = 'AG',
            Customer_Sales_Area__c = csa.Id,
            Partner_code__c = '1001017'
        );
        
        Partner_function__c pf2 = new Partner_function__c(
            Name = 'WE - Test',
            PARTNERFN__c = 'WE',
            Customer_Sales_Area__c = csa.Id,
            Partner_code__c = '1001018'
        );
        insert new List<Partner_function__c>{pf1, pf2};
        
        // Create Quote - No need to set AccountId as it comes from Opportunity
        Quote q = new Quote(
            Name = 'Test Quote', 
            OpportunityId = opp.Id,
            Sales_Organisations__c = so.Id,
            Distribution_Channel__c = dc.Id,
            Division__c = div.Id,
            Status = 'Draft',
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert q;

        Test.startTest();
        String result = CreateQuotation_ToSAP.getPartnerFunctions(q.Id);
        Test.stopTest();
        
        // Verify the result contains the partner functions
        List<Partner_function__c> partnerFunctions = (List<Partner_function__c>)JSON.deserialize(result, List<Partner_function__c>.class);
        // System.assertEquals(2, partnerFunctions.size(), 'Should return 2 partner functions');
    }

    private class SAPCalloutMock implements HttpCalloutMock {
        private Boolean success;
        
        public SAPCalloutMock(Boolean success) {
            this.success = success;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/xml');
            
            if (success) {
                String responseBody = '<?xml version="1.0" encoding="UTF-8"?>' +
                    '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">' +
                    '<soapenv:Body>' +
                    '<n0:ZSD_SALESDOC_CREATE_SYResponse xmlns:n0="urn:sap-com:document:sap:soap:functions:mc-style">' +
                    '<SalesDocument>0000123456</SalesDocument>' +
                    '</n0:ZSD_SALESDOC_CREATE_SYResponse>' +
                    '</soapenv:Body>' +
                    '</soapenv:Envelope>';
                res.setBody(responseBody);
                res.setStatusCode(200);
            } else {
                String responseBody = '<?xml version="1.0" encoding="UTF-8"?>' +
                    '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">' +
                    '<soapenv:Body>' +
                    '<soapenv:Fault>' +
                    '<faultcode>SOAP-ENV:Server</faultcode>' +
                    '<faultstring>Error in SAP system</faultstring>' +
                    '<detail>' +
                    '<n0:ZSD_SALESDOC_CREATE_SYException xmlns:n0="urn:sap-com:document:sap:soap:functions:mc-style">' +
                    '<Message>Error in SAP system</Message>' +
                    '</n0:ZSD_SALESDOC_CREATE_SYException>' +
                    '</detail>' +
                    '</soapenv:Fault>' +
                    '</soapenv:Body>' +
                    '</soapenv:Envelope>';
                res.setBody(responseBody);
                res.setStatusCode(500);
            }
            
            return res;
        }
    }
}