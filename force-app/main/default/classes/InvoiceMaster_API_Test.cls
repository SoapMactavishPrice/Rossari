@isTest
public class InvoiceMaster_API_Test {

    @isTest
    static void test_AllScenariosInOneMethod() {
        // Setup test data
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Sales_Organisation__c so = new Sales_Organisation__c(Name = 'TestSO');
        insert so;

        Distribution_Channel__c dc = new Distribution_Channel__c(Name = 'TestDC', Distribution_Code__c = 'DC1');
        insert dc;

        Division__c div = new Division__c(Name = 'TestDiv', Division_Code__c = 'DIV1');
        insert div;

        Payment_Term__c pt = new Payment_Term__c(Name = 'TestPT', Payment_Term_Code__c = 'PT1');
        insert pt;

        Order ord = new Order(AccountId = acc.Id, SAP_Order_Number__c = 'SO123', Status = 'Draft', EffectiveDate = System.today());
        insert ord;

        Company__c comp = new Company__c(Name = 'TestComp', SAP_Code__c = 'COMP');
        insert comp;

        FY__c fy = new FY__c(Name = '2024');
        insert fy;

        Sales_District__c sd = new Sales_District__c(Name = 'TestSD', Sales_District_Code__c = 'SD1');
        insert sd;

        Country__c country = new Country__c(Name = 'TestCountry', Country_Code__c = 'CN1');
        insert country;

        Plant__c plant = new Plant__c(Name = 'PLANT1');
        insert plant;

        Profit_Center__c pc = new Profit_Center__c(Name = 'PC1');
        insert pc;

        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1]; 
        User u = new User(
            Alias = 'standt',
            Email='standarduser@testorg.com',
            EmailEncodingKey='UTF-8',
            LastName='Testing',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId = p.Id,
            TimeZoneSidKey='America/Los_Angeles',
            UserName='standarduser' + DateTime.now().getTime() + '@testorg.com',
            SAP_User_Id__c = 'USER1',
            Employee_Code__c = 'EMP1'
        );
        insert u;


        Id standardPricebookId = Test.getStandardPricebookId();

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


        // insert new Invoice__c(Name = 'INV001');

        // === SCENARIO 1: Valid Request ===
        String validJson = '{' +
            '"invoiceNo": "INV001",' +
            '"gstInvoiceNumber": "GST001",' +
            '"billingDate": "2024-01-15",' +
            '"billingTypeDescription": "Test Billing",' +
            '"netValue": 1000,' +
            '"billedQty": 10,' +
            '"documentCurrency": "USD",' +
            '"sdDocumentCategory": "CAT1",' +
            '"salesOrg": "TestSO",' +
            '"distributionChannel": "DC1",' +
            '"division": "DIV1",' +
            '"salesOrderNo": "SO123",' +
            '"soldToParty": "SOLD123",' +
            '"billToPartyCode": "BILL123",' +
            '"payer": "PAYER123",' +
            '"shipToParty": "SHIP123",' +
            '"paymentTerm": "PT1",' +
            '"exchangeRate": 1.5,' +
            '"companyCode": "COMP",' +
            '"incoTerm": "EXW",' +
            '"fiscalYear": "2024",' +
            '"salesDistrict": "SD1",' +
            '"country": "CN1",' +
            '"creditControlArea": "CCA1",' +
            '"ccaCurrency": "INR",' +
            '"customerZone": "ZONE1",' +
            '"totalTaxValue": 180,' +
            '"totalGrossValue": 1180,' +
            '"invoiceStatus": "Active",' +
            '"salesPerson": "USER1",' +
            '"invline": [{' +
                '"baseUOM": "UOM1",' +
                '"cgstRate": 9,' +
                '"cgstValue": 90,' +
                '"plant": "PLANT1",' +
                '"plantGstinNo": "GSTIN123",' +
                '"salesValueInDocCurrency": 1000,' +
                '"salesValueInLocalCurrency": 75000,' +
                '"profitCentre": "PC1",' +
                '"igstRate": 0,' +
                '"igstValue": 0,' +
                '"itemDescription": "Test Item",' +
                '"itemQty": 10,' +
                '"itemTaxableValue": 1000,' +
                '"name": "Line1",' +
                '"packSize": "10kg",' +
                '"productCode": "PROD1",' +
                '"salesItemNo": "SI001",' +
                '"salesUOM": "UOM1",' +
                '"sgstRate": 9,' +
                '"sgstValue": 90' +
            '}]' +
        '}';

        // === SCENARIO 2: Missing Invoice No ===
        String missingInvoiceNoJson = '{' +
            '"gstInvoiceNumber": "GST001",' +
            '"billingDate": "2024-01-15",' +
            '"billingTypeDescription": "Test Billing",' +
            '"netValue": 1000,' +
            '"billedQty": 10,' +
            '"documentCurrency": "USD",' +
            '"salesOrg": "TestSO",' +
            '"invline": []' +
        '}';

        // === SCENARIO 3: Invalid Product Code ===
        String invalidProductJson = '{' +
            '"invoiceNo": "INV002",' +
            '"gstInvoiceNumber": "GST001",' +
            '"billingDate": "2024-01-15",' +
            '"netValue": 1000,' +
            '"billedQty": 10,' +
            '"documentCurrency": "USD",' +
            '"salesOrg": "TestSO",' +
            '"invline": [{' +
                '"productCode": "INVALID_PROD",' +
                '"salesItemNo": "SI001",' +
                '"itemDescription": "Test Item"' +
            '}]' +
        '}';

        // === SCENARIO 4: Empty Request Body ===
        String emptyBody = '';

        // === SCENARIO 5: Invalid JSON Format ===
        String invalidJson = 'invalid json {';

        List<String> testBodies = new List<String>{
            validJson,
            missingInvoiceNoJson,
            invalidProductJson,
            emptyBody,
            invalidJson
        };

        Test.startTest();

        for (String testJson : testBodies) {
            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();

            req.requestURI = '/InvoiceMaster';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueOf(testJson);

            RestContext.request = req;
            RestContext.response = res;

            InvoiceMaster_API.doPost();
        }

        Test.stopTest();
    }
}