@isTest
public class SalesOrderAPI_Test {

    @testSetup
    static void setupData() {
        // Activate Standard Pricebook
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

        System.debug('Standard Pricebook: ' + [SELECT Id, IsStandard FROM Pricebook2 WHERE IsStandard = true LIMIT 1]);

        // Create test Product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'MAT001',
            IsActive = true
        );
        insert testProduct;

        // Create PricebookEntry
        PricebookEntry standardPBE = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100.00,
            IsActive = true,
            CurrencyIsoCode = 'USD'
        );
        insert standardPBE;

        // Create Account
        Account acc = new Account(Name='Test Account', SAP_Customer_Code__c='CUST001');
        insert acc;

        // Create supporting data
        insert new Sales_Organisation__c(Name='1000');
        insert new Distribution_Channel__c(Distribution_Code__c='10');
        insert new Division__c(Division_Code__c='29');
        insert new Payment_Term__c(Payment_Term_Code__c='PT1');
        insert new Sales_District__c(Sales_District_Code__c='SD1');
    }

    @isTest
    static void testSalesOrderAPISuccess() {
        // Prepare SalesOrder JSON
        SalesOrderAPI.SalesOrderJson so = new SalesOrderAPI.SalesOrderJson();
        so.DOC_NUM = 'SO123';
        so.CUSTOMER_NO = 'CUST001';
        so.SALES_ORG = '1000';
        so.DISTR_CHANN = '10';
        so.DIVISION = '29';
        so.PMNTRMS = 'PT1';
        so.SALES_DISTRICT = 'SD1';
        so.DOCUMENT_CURRENCY = 'USD';
        so.ORDER_DATE = String.valueOf(Date.today());
        so.ITEMS = new List<SalesOrderAPI.cls_ITEMS>();

        // Add item
        SalesOrderAPI.cls_ITEMS item = new SalesOrderAPI.cls_ITEMS();
        item.MATERIAL = 'MAT001';
        item.ITEM_NUM = '10';
        item.QTY = 5;
        item.PRICE = 100;
        item.UOM = 'EA';
        item.ITM_DESC = 'Test Item';
        item.FIRST_DATE = String.valueOf(Date.today());
        item.ITEM_TEXT = new List<SalesOrderAPI.cls_ITEM_TEXT>();
        item.SCHED_LINES = new List<SalesOrderAPI.cls_SCHED_LINES>();
        so.ITEMS.add(item);

        // Add Header Text
        so.HEADERTEXT = new List<SalesOrderAPI.cls_HEADERTEXT>();
        SalesOrderAPI.cls_HEADERTEXT header = new SalesOrderAPI.cls_HEADERTEXT();
        header.INSTRUCTION_TYPE = 'INST1';
        header.INSTRUCTION_DESCRIPTION = 'Instruction 1';
        so.HEADERTEXT.add(header);

        // Add Partner
        so.PARTNERLIST = new List<SalesOrderAPI.cls_PARTNER_LIST>();
        SalesOrderAPI.cls_PARTNER_LIST partner = new SalesOrderAPI.cls_PARTNER_LIST();
        partner.PARTNER_FUNCTION = 'Bill-to party';
        partner.PARTNER_CODE = 'CUST001';
        partner.PARTNER_NAME = 'Test Account';
        so.PARTNERLIST.add(partner);

        String jsonInput = JSON.serialize(so);

        // Set RestContext
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/SalesOrder';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonInput);
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
        SalesOrderAPI.doPost();
        Test.stopTest();

        // Verify API log
        API_log__c log = [SELECT Status__c, Response__c FROM API_log__c ORDER BY CreatedDate DESC LIMIT 1];

        // Verify Order creation
        List<Order> ordList = [SELECT Id, SAP_Order_Number__c FROM Order WHERE SAP_Order_Number__c='SO123'];
        Order ord = ordList[0];

        // Verify OrderItem creation
        List<OrderItem> ordItems = [SELECT Id, Product2Id, Quantity, UnitPrice FROM OrderItem WHERE OrderId = :ord.Id];
    }

    @isTest
    static void testSalesOrderAPIError_MissingCustomer() {
        // Prepare SalesOrder JSON with invalid customer
        SalesOrderAPI.SalesOrderJson so = new SalesOrderAPI.SalesOrderJson();
        so.DOC_NUM = 'SO124';
        so.CUSTOMER_NO = 'INVALID';
        so.ITEMS = new List<SalesOrderAPI.cls_ITEMS>();
        SalesOrderAPI.cls_ITEMS item = new SalesOrderAPI.cls_ITEMS();
        item.MATERIAL = 'MAT001';
        item.ITEM_NUM = '10';
        item.QTY = 5;
        item.PRICE = 100;
        item.UOM = 'EA';
        item.ITM_DESC = 'Test Item';
        so.ITEMS.add(item);

        String jsonInput = JSON.serialize(so);

        // Set RestContext
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/SalesOrder';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonInput);
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
        SalesOrderAPI.doPost();
        Test.stopTest();

        // Verify API log shows error
        List<API_log__c> logList = [SELECT Status__c, Response__c FROM API_log__c ORDER BY CreatedDate DESC LIMIT 1];
    }
}