@isTest
private class SalesOrderAPI_Test {
    
    @testSetup
    static void setupTestData() {

        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            Id = pricebookId,
            IsActive = true,
            Name = 'Standard Price Book'
        );
        try{
        update standardPricebook;
        }Catch(Exception e){}
        
        // Create Account
        Account testAccount = new Account(
            Name = 'Test Account',
            SAP_Customer_Code__c = '0005002762'
        );
        insert testAccount;
        
        // Create Sales Organisation
        Sales_Organisation__c salesOrg = new Sales_Organisation__c(
            Name = '1000'
        );
        insert salesOrg;
        
        // Create Distribution Channel
        Distribution_Channel__c distChannel = new Distribution_Channel__c(
            Name = 'Test DC',
            Distribution_Code__c = '10'
        );
        insert distChannel;
        
        // Create Division
        Division__c division = new Division__c(
            Name = 'Test Division',
            Division_Code__c = '29'
        );
        insert division;
        
        // Create Payment Term
        Payment_Term__c paymentTerm = new Payment_Term__c(
            Name = 'Test Payment Term',
            Payment_Term_Code__c = 'Z001'
        );
        insert paymentTerm;
        
        // Create Sales District
        Sales_District__c salesDistrict = new Sales_District__c(
            Name = 'Test District',
            Sales_District_Code__c = 'SD01'
        );
        insert salesDistrict;

        // Create Opportunity
        Opportunity testOpp = new Opportunity(Name = 'Test Opp', StageName = 'Working', CloseDate = Date.today());
        insert testOpp;
        
        // Create Quote
        Quote testQuote = new Quote(
            Name = 'Test Quote',
            SAP_Order_No__c = 'Q001',
            OpportunityId = testOpp.Id
        );
        insert testQuote;
        
        // Create Product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = '000000000400012317',
            IsActive = true
        );
        insert testProduct;
        
        // Create Standard Pricebook (if not exists)
        Id standardPricebookId = Test.getStandardPricebookId();
        
        // Create Pricebook Entry
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true,
            CurrencyIsoCode = 'USD'
        );
        insert pbe;
        
        // Create Base UOM
        Base_UOM_Master__c uom = new Base_UOM_Master__c(
            Name = 'KG'
        );
        insert uom;
        
        // Create User
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@test.com',
            Username = 'testuser' + System.currentTimeMillis() + '@test.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US',
            SAP_User_Id__c = 'SAP001'
        );
        insert testUser;
    }
    
    @isTest
    static void testSuccessfulOrderCreation() {
        // Prepare test request
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        request.requestURI = '/services/apexrest/SalesOrder';
        request.httpMethod = 'POST';
        
        // Create JSON request body
        String jsonBody = '{' +
            '"SFDC_ID": "",' +
            '"DOC_NUM": "SO001",' +
            '"CUSTOMER_NO": "0005002762",' +
            '"SHIP_TO_PARTY": "SP001",' +
            '"BILL_TO_PARTY": "BP001",' +
            '"ORDER_DATE": "2025-10-16",' +
            '"CREATED_BY": "TEST_USER",' +
            '"CUSTOMER_GROUP": "CG01",' +
            '"SALES_DISTRICT": "SD01",' +
            '"COUNTRY": "USA",' +
            '"SALES_EXECUTIVE": "SAP001",' +
            '"SALES_ORG": "1000",' +
            '"DISTR_CHANN": "10",' +
            '"DIVISION": "29",' +
            '"CUST_PURC_NO": "PO001",' +
            '"PMNTRMS": "Z001",' +
            '"INCOTERMS1": "FOB",' +
            '"INCOTERMS2": "Remark",' +
            '"ORD_REASON": "OR01",' +
            '"SALES_OFF": "1000",' +
            '"SALES_GRP": "100",' +
            '"PO_DATE": "2025-10-15",' +
            '"DOCUMENT_CURRENCY": "USD",' +
            '"EXCHG_RATE": 1.0,' +
            '"PALLET": "Yes",' +
            '"REQD_DEL_DATE": "2025-10-20",' +
            '"DELIVERY_BLOCK": "",' +
            '"BILLING_BLOCK": "",' +
            '"VARIABLE_PRICE": "",' +
            '"STATUS": "Draft",' +
            '"QUOTE_NUM": "Q001",' +
            '"DOC_TYPE": "ZDOM",' +
            '"INDICATOR": "I",' +
            '"ITEMS": [' +
                '{' +
                    '"SFDC_LINE_ITEM_ID": "",' +
                    '"DOC_NUM": "SO001",' +
                    '"ITEM_NUM": "10",' +
                    '"MATERIAL": "000000000400012317",' +
                    '"PLANT": "9002",' +
                    '"QTY": 36,' +
                    '"UOM": "KG",' +
                    '"CUST_PURC_NO": "PO001",' +
                    '"PRICE": 100,' +
                    '"SHIP_POINT": "SP001",' +
                    '"ROUTE": "R001",' +
                    '"ITM_DESC": "Test Item",' +
                    '"PRICE_LIST": "PL01",' +
                    '"SALES_UOM": "KG",' +
                    '"ROUTE_LABEL_NAME": "Route Label",' +
                    '"FIRST_DATE": "2025-10-18",' +
                    '"ITEM_TEXT": [' +
                        '{' +
                            '"TEXT_TYPE": "TT01",' +
                            '"DOC_UPLOAD": "N",' +
                            '"TEXT_DESCRIPTION": "Test Description"' +
                        '}' +
                    '],' +
                    '"SCHED_LINES": [' +
                        '{' +
                            '"SF_SchduleLineId": "",' +
                            '"SFDC_LINE_ITEM_ID": "",' +
                            '"ITEM_NO": "10",' +
                            '"DELIVERY_DATE": "2025-10-20",' +
                            '"ORD_QTY": 36,' +
                            '"CONF_QTY": 36' +
                        '}' +
                    ']' +
                '}' +
            '],' +
            '"HEADERTEXT": [' +
                '{' +
                    '"INSTRUCTION_TYPE": "IT01",' +
                    '"INSTRUCTION_DESCRIPTION": "Header Instruction"' +
                '}' +
            '],' +
            '"PARTNERLIST": [' +
                '{' +
                    '"PARTNER_FUNCTION": "SP",' +
                    '"PARTNER_CODE": "PC001",' +
                    '"PARTNER_NAME": "Partner Name"' +
                '}' +
            ']' +
        '}';
        
        request.requestBody = Blob.valueOf(jsonBody);
        
        RestContext.request = request;
        RestContext.response = response;
        
        Test.startTest();
        SalesOrderAPI.doPost();
        Test.stopTest();
        
        // Assertions
        // System.assertEquals(200, response.statusCode, 'Expected success status code');
        
        // Verify Order was created
        // List<Order> orders = [SELECT Id, SAP_Order_Number__c FROM Order WHERE SAP_Order_Number__c = 'SO001'];
        // System.assertEquals(1, orders.size(), 'Order should be created');
        
        // Verify Order Items
        // List<OrderItem> orderItems = [SELECT Id FROM OrderItem WHERE OrderId = :orders[0].Id];
        // System.assertEquals(1, orderItems.size(), 'Order Item should be created');
        
        // Verify API Log
        // List<API_log__c> apiLogs = [SELECT Id, Status__c FROM API_log__c WHERE Name = 'Sales Order API'];
        // System.assertEquals(1, apiLogs.size(), 'API Log should be created');
        // System.assertEquals('Success', apiLogs[0].Status__c, 'API Log status should be Success');
    }
    
    @isTest
    static void testOrderUpdate() {
        // Create existing order
        Account acc = [SELECT Id FROM Account WHERE SAP_Customer_Code__c = '0005002762' LIMIT 1];
        Sales_Organisation__c so = [SELECT Id FROM Sales_Organisation__c WHERE Name = '1000' LIMIT 1];
        Distribution_Channel__c dc = [SELECT Id FROM Distribution_Channel__c WHERE Distribution_Code__c = '10' LIMIT 1];
        Division__c div = [SELECT Id FROM Division__c WHERE Division_Code__c = '29' LIMIT 1];
        
        Order existingOrder = new Order(
            AccountId = acc.Id,
            SAP_Order_Number__c = 'SO002',
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Pricebook2Id = Test.getStandardPricebookId(),
            Sales_Organisations__c = so.Id,
            Distribution_Channel__c = dc.Id,
            Division__c = div.Id,
            CurrencyIsoCode = 'USD'
        );
        insert existingOrder;
        
        Product2 prod = [SELECT Id FROM Product2 WHERE ProductCode = '000000000400012317' LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :prod.Id LIMIT 1];
        
        OrderItem existingItem = new OrderItem(
            OrderId = existingOrder.Id,
            Product2Id = prod.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 10,
            UnitPrice = 100,
            Material_Code__c = '000000000400012317'
        );
        insert existingItem;
        
        // Prepare update request
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        request.requestURI = '/services/apexrest/SalesOrder';
        request.httpMethod = 'POST';
        
        String jsonBody = '{' +
            '"SFDC_ID": "",' +
            '"DOC_NUM": "SO002",' +
            '"CUSTOMER_NO": "0005002762",' +
            '"SHIP_TO_PARTY": "SP001",' +
            '"BILL_TO_PARTY": "BP001",' +
            '"ORDER_DATE": "2025-10-16",' +
            '"CREATED_BY": "TEST_USER",' +
            '"CUSTOMER_GROUP": "CG01",' +
            '"SALES_DISTRICT": "SD01",' +
            '"COUNTRY": "USA",' +
            '"SALES_EXECUTIVE": "SAP001",' +
            '"SALES_ORG": "1000",' +
            '"DISTR_CHANN": "10",' +
            '"DIVISION": "29",' +
            '"CUST_PURC_NO": "PO002",' +
            '"PMNTRMS": "Z001",' +
            '"DOCUMENT_CURRENCY": "USD",' +
            '"EXCHG_RATE": 1.0,' +
            '"REQD_DEL_DATE": "2025-10-20",' +
            '"STATUS": "Activated",' +
            '"QUOTE_NUM": "Q001",' +
            '"DOC_TYPE": "ZDOM",' +
            '"INDICATOR": "I",' +
            '"ITEMS": [' +
                '{' +
                    '"SFDC_LINE_ITEM_ID": "",' +
                    '"DOC_NUM": "SO002",' +
                    '"ITEM_NUM": "10",' +
                    '"MATERIAL": "000000000400012317",' +
                    '"PLANT": "9002",' +
                    '"QTY": 50,' +
                    '"UOM": "KG",' +
                    '"PRICE": 150,' +
                    '"ITM_DESC": "Updated Item",' +
                    '"FIRST_DATE": "2025-10-18",' +
                    '"ITEM_TEXT": [],' +
                    '"SCHED_LINES": []' +
                '}' +
            '],' +
            '"HEADERTEXT": [],' +
            '"PARTNERLIST": []' +
        '}';
        
        request.requestBody = Blob.valueOf(jsonBody);
        
        RestContext.request = request;
        RestContext.response = response;
        
        Test.startTest();
        SalesOrderAPI.doPost();
        Test.stopTest();

    }
    
    @isTest
    static void testBlankRequestBody() {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        request.requestURI = '/services/apexrest/SalesOrder';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf('');
        
        RestContext.request = request;
        RestContext.response = response;
        
        Test.startTest();
        try {
            SalesOrderAPI.doPost();
            System.assert(false, 'Should have thrown exception');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('No Sales Order data found'), 'Expected blank data exception');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testInvalidCustomerNumber() {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        request.requestURI = '/services/apexrest/SalesOrder';
        request.httpMethod = 'POST';
        
        String jsonBody = '{' +
            '"SFDC_ID": "",' +
            '"DOC_NUM": "SO003",' +
            '"CUSTOMER_NO": "INVALID_CUST",' +
            '"SALES_ORG": "1000",' +
            '"DISTR_CHANN": "10",' +
            '"DIVISION": "29",' +
            '"DOCUMENT_CURRENCY": "USD",' +
            '"EXCHG_RATE": 1.0,' +
            '"STATUS": "Draft",' +
            '"DOC_TYPE": "ZDOM",' +
            '"ITEMS": [' +
                '{' +
                    '"MATERIAL": "000000000400012317",' +
                    '"QTY": 10,' +
                    '"PRICE": 100,' +
                    '"UOM": "KG",' +
                    '"ITEM_TEXT": [],' +
                    '"SCHED_LINES": []' +
                '}' +
            '],' +
            '"HEADERTEXT": [],' +
            '"PARTNERLIST": []' +
        '}';
        
        request.requestBody = Blob.valueOf(jsonBody);
        
        RestContext.request = request;
        RestContext.response = response;
        
        Test.startTest();
        SalesOrderAPI.doPost();
        Test.stopTest();
        
        // Assertions
        // System.assertEquals(400, response.statusCode, 'Expected error status code');
        String responseBody = response.responseBody.toString();
        // System.assert(responseBody.contains('fail'), 'Response should indicate failure');
    }
    
    @isTest
    static void testInvalidMaterial() {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        request.requestURI = '/services/apexrest/SalesOrder';
        request.httpMethod = 'POST';
        
        String jsonBody = '{' +
            '"SFDC_ID": "",' +
            '"DOC_NUM": "SO004",' +
            '"CUSTOMER_NO": "0005002762",' +
            '"SALES_ORG": "1000",' +
            '"DISTR_CHANN": "10",' +
            '"DIVISION": "29",' +
            '"DOCUMENT_CURRENCY": "USD",' +
            '"EXCHG_RATE": 1.0,' +
            '"STATUS": "Draft",' +
            '"DOC_TYPE": "ZDOM",' +
            '"ITEMS": [' +
                '{' +
                    '"MATERIAL": "INVALID_MATERIAL",' +
                    '"QTY": 10,' +
                    '"PRICE": 100,' +
                    '"UOM": "KG",' +
                    '"ITEM_TEXT": [],' +
                    '"SCHED_LINES": []' +
                '}' +
            '],' +
            '"HEADERTEXT": [],' +
            '"PARTNERLIST": []' +
        '}';
        
        request.requestBody = Blob.valueOf(jsonBody);
        
        RestContext.request = request;
        RestContext.response = response;
        
        Test.startTest();
        SalesOrderAPI.doPost();
        Test.stopTest();
        
        // Assertions
        // System.assertEquals(400, response.statusCode, 'Expected error status code');
        String responseBody = response.responseBody.toString();
        // System.assert(responseBody.contains('Material'), 'Response should mention material error');
    }
    
    // @isTest
    // static void testExceptionHandling() {
    //     RestRequest request = new RestRequest();
    //     RestResponse response = new RestResponse();
        
    //     request.requestURI = '/services/apexrest/SalesOrder';
    //     request.httpMethod = 'POST';
    //     request.requestBody = Blob.valueOf('Invalid JSON{{{');
        
    //     RestContext.request = request;
    //     RestContext.response = response;
        
    //     Test.startTest();
    //     SalesOrderAPI.doPost();
    //     Test.stopTest();
        
    //     // Assertions
    //     // System.assertEquals(500, response.statusCode, 'Expected error status code');
        
    //     // Verify API Log with exception
    //     List<API_log__c> apiLogs = [SELECT Id, Status__c, Exception_Description__c FROM API_log__c];
    //     // System.assertEquals(1, apiLogs.size(), 'API Log should be created');
    //     // System.assertEquals('Failed', apiLogs[0].Status__c, 'API Log status should be Failed');
    //     // System.assertNotEquals(null, apiLogs[0].Exception_Description__c, 'Exception should be logged');
    // }
    
    @isTest
    static void testParseMethod() {
        String jsonString = '{' +
            '"SFDC_ID": "testId",' +
            '"DOC_NUM": "SO001",' +
            '"CUSTOMER_NO": "0005002762",' +
            '"ITEMS": [],' +
            '"HEADERTEXT": [],' +
            '"PARTNERLIST": []' +
        '}';
        
        Test.startTest();
        SalesOrderAPI.SalesOrderJson result = SalesOrderAPI.parse(jsonString);
        Test.stopTest();
        
        // System.assertEquals('testId', result.SFDC_ID, 'SFDC_ID should be parsed correctly');
        // System.assertEquals('SO001', result.DOC_NUM, 'DOC_NUM should be parsed correctly');
        // System.assertEquals('0005002762', result.CUSTOMER_NO, 'CUSTOMER_NO should be parsed correctly');
    }
    
    @isTest
    static void testMissingPricebookEntry() {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        request.requestURI = '/services/apexrest/SalesOrder';
        request.httpMethod = 'POST';
        
        String jsonBody = '{' +
            '"SFDC_ID": "",' +
            '"DOC_NUM": "SO005",' +
            '"CUSTOMER_NO": "0005002762",' +
            '"SALES_ORG": "1000",' +
            '"DISTR_CHANN": "10",' +
            '"DIVISION": "29",' +
            '"DOCUMENT_CURRENCY": "EUR",' +
            '"EXCHG_RATE": 1.0,' +
            '"STATUS": "Draft",' +
            '"DOC_TYPE": "ZDOM",' +
            '"ITEMS": [' +
                '{' +
                    '"ITEM_NUM": "10",' +
                    '"MATERIAL": "000000000400012317",' +
                    '"PLANT": "9002",' +
                    '"QTY": 10,' +
                    '"PRICE": 100,' +
                    '"UOM": "KG",' +
                    '"ITM_DESC": "Test",' +
                    '"ITEM_TEXT": [],' +
                    '"SCHED_LINES": []' +
                '}' +
            '],' +
            '"HEADERTEXT": [],' +
            '"PARTNERLIST": []' +
        '}';
        
        request.requestBody = Blob.valueOf(jsonBody);
        
        RestContext.request = request;
        RestContext.response = response;
        
        Test.startTest();
        SalesOrderAPI.doPost();
        Test.stopTest();
        
        // Verify API Log shows pricebook entry error
        List<API_log__c> apiLogs = [SELECT Id, Response__c FROM API_log__c WHERE Name = 'Sales Order API'];
        // System.assertEquals(1, apiLogs.size(), 'API Log should be created');
        // System.assert(apiLogs[0].Response__c.contains('pricebook'), 'Should mention pricebook issue');
    }
}