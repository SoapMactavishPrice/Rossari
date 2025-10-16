@IsTest
private class CreateQuote_ToSAP_Test {
    @TestSetup
    static void setup() {
        // Create test accounts for SoldTo, ShipTo, BillTo
        List<Account> accounts = new List<Account>{
            new Account(Name = 'SoldTo Account'),
            new Account(Name = 'ShipTo Account'),
            new Account(Name = 'BillTo Account')
        };
        insert accounts;

        // Create Distribution Channel, Division, and Plant records
        insert new Distribution_Channel__c(Distribution_Code__c = 'DC01');
        insert new Division__c(Division_Code__c = 'DIV01');
        insert new Plant__c(Name = 'PL01');

        Id standardPbId = Test.getStandardPricebookId();

        Opportunity opp1 = new Opportunity(
            Name = 'Test Opportunity', 
            CloseDate = Date.today(), 
            StageName = 'Prospecting',
            Pricebook2Id = standardPbId
        );
        insert opp1;

        Quote quote = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp1.Id,
            Distribution_Channel__c = [SELECT Id FROM Distribution_Channel__c WHERE Distribution_Code__c = 'DC01' LIMIT 1].Id,
            Division__c = [SELECT Id FROM Division__c WHERE Division_Code__c = 'DIV01' LIMIT 1].Id,
            Plant_code__c = [SELECT Id FROM Plant__c WHERE Name = 'PL01' LIMIT 1].Id,
            Quote_Document_Type__c = 'Domestic',
            Quote_Document_Version__c = 1,
            Sales_office__c = 'none',
            Sales_Group__c = 'none',
            PO_No__c = 'PO-456789',
            PO_Date__c = Date.newInstance(2025, 8, 25),
            Quote_Valid_From__c = Date.newInstance(2025, 8, 25),
            Reqd_Del_Date__c = Date.newInstance(2025, 9, 10),
            Delivery_Plant__c = 'None',
            Payment_Terms__c = '30 days Credit',
            Inco_Terms__c = 'FOB',
            Inco_Remark__c = 'Delivery at port',
            Order_Reason__c = 'None',
            CurrencyIsoCode = 'USD',
            Exchange_Rate__c = 1.23,
            Total_Wt__c = 1200.50,
            Shipping_Plant__c = 'None',
            Route__c = 'none',
            Material_Freight_Group__c = 'None',
            Over_Delivery_Tolerance__c = 5,
            Under_Delivery_Tolerance__c = 2,
            UnLimited_Tolerance__c = false,
            Net_Wt__c = 1150.00,
            Gross_Wt__c = 1250.00,
            Status = 'Open',
            Reason_for_Rejection__c = 'None'
        );
        insert quote;
    }

    @IsTest
    static void testPushQuoteToSAP_Success() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new SAPCalloutMock(200, 'Success'));

        Test.startTest();
        CreateQuote_ToSAP.pushQuoteToSAP(testQuote.Id);
        Test.stopTest();

        API_log__c log = [SELECT Status__c, Response__c FROM API_log__c LIMIT 1];
    }

    @IsTest
    static void testPushQuoteToSAP_Failure() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new SAPCalloutMock(500, 'Error'));

        Test.startTest();
        CreateQuote_ToSAP.pushQuoteToSAP(testQuote.Id);
        Test.stopTest();

        API_log__c log = [SELECT Status__c FROM API_log__c LIMIT 1];
    }

    @IsTest
    static void testPushQuoteToSAP_Exception() {
        Test.startTest();
        CreateQuote_ToSAP.pushQuoteToSAP(null);
        Test.stopTest();

        API_log__c log = [SELECT Status__c, Exception_Description__c FROM API_log__c LIMIT 1];
    }

    private class SAPCalloutMock implements HttpCalloutMock {
        private Integer statusCode;
        private String body;

        public SAPCalloutMock(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body = body;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(body);
            return res;
        }
    }
}