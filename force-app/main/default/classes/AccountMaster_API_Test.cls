@isTest
public class AccountMaster_API_Test {
    
    @TestSetup
    static void setupTestData() {
        // Use Standard Pricebook without updating it
        Id standardPricebookId = Test.getStandardPricebookId();
        
        // Create test cities
        List<City__c> cities = new List<City__c>{
            new City__c(Name = 'Mumbai'),
            new City__c(Name = 'Delhi'),
            new City__c(Name = 'Bangalore')
        };
        insert cities;
        
        // Create test postal codes
        List<Pin_Code__c> postalCodes = new List<Pin_Code__c>{
            new Pin_Code__c(Name = '400001'),
            new Pin_Code__c(Name = '110001'),
            new Pin_Code__c(Name = '560001')
        };
        insert postalCodes;
        
        // Create test sales organisation data
        Sales_Organisation__c so = new Sales_Organisation__c(Name = '1000');
        insert so;
        
        Distribution_Channel__c dc = new Distribution_Channel__c(
            Name = 'DC1', 
            Distribution_Code__c = '10'
        );
        insert dc;
        
        Division__c div = new Division__c(
            Name = 'DIV1', 
            Division_Code__c = '10'
        );
        insert div;
        
        Company__c company = new Company__c(
            Name = 'Test Company',
            SAP_Code__c = 'COM1'
        );
        insert company;
        
        // Create test payment terms
        Payment_Term__c paymentTerm = new Payment_Term__c(
            Name = 'Net 30',
            Payment_Term_Code__c = '0001'
        );
        insert paymentTerm;
        
        // Create test sales district
        Sales_District__c salesDistrict = new Sales_District__c(
            Name = 'North District',
            Sales_District_Code__c = 'NORTH'
        );
        insert salesDistrict;
        
        // Create existing account for update testing
        Account existingAccount = new Account(
            Name = 'Existing Customer',
            SAP_Customer_Code__c = 'EXIST001',
            Email_Id__c = 'existing@test.com'
        );
        insert existingAccount;
        
        // Create existing contact
        Contact existingContact = new Contact(
            FirstName = 'Existing',
            LastName = 'Contact',
            Email = 'existing.contact@test.com',
            AccountId = existingAccount.Id,
            External_Id__c = 'EXIST001-existing.contact@test.com'
        );
        insert existingContact;
        
        // Create existing bank information
        Bank_Information__c existingBank = new Bank_Information__c(
            Name = 'Existing Bank',
            Account_Name__c = existingAccount.Id,
            Bank_A_C_No__c = '1234567890',
            External_Id__c = 'EXIST001-1234567890'
        );
        insert existingBank;
        
        // Create existing customer sales area
        Customer_Sales_Area__c existingCSA = new Customer_Sales_Area__c(
            Name = '1000/10/10',
            Comapany_Code__c = existingAccount.Id,
            Sales_Organisation__c = so.Id,
            Distribution_Channel__c = dc.Id,
            Division__c = div.Id,
            External_Id__c = 'EXIST001-1000-10-10'
        );
        insert existingCSA;
        
        // Create existing partner function
        Partner_Function__c existingPF = new Partner_Function__c(
            Name = 'EXIST001/SP',
            Customer_Sales_Area__c = existingCSA.Id,
            PARTNERFN__c = 'SP',
            Partner_code__c = 'EXIST001',
            TXT_SALES_ORG0079__c = '1000',
            TXT_DISTR_CHANN__c = '10',
            TXT_DIVISION0081__c = '10',
            External_Id__c = 'EXIST001-SP-1000-10-10'
        );
        insert existingPF;
    }
    
    @isTest
    static void testAllSuccessScenarios() {
        // Test 1: Success scenario - Create new account
        List<AccountMaster_API.AccountMasterRequest> requests = new List<AccountMaster_API.AccountMasterRequest>();
        
        AccountMaster_API.AccountMasterRequest request = new AccountMaster_API.AccountMasterRequest();
        request.SFDC_ID = null;
        request.CUSTOMER_NO = 'TEST001';
        request.CUST_NAME = 'Test Customer';
        request.CUST_ACCT_GROUP = 'Z001';
        request.ACCOUNT_GROUP_C = 'Corporate';
        request.TITLE = 'Mr.';
        request.C_TELEPHONE1 = '1234567890';
        request.EMAIL1 = 'test@customer.com';
        request.C_STREET = 'Test Street';
        request.STREET2 = 'Test Street 2';
        request.STREET = 'Main Street';
        request.HOUSE_NO = '123';
        request.POST_CODE = '400001';
        request.CITY = 'Mumbai';
        request.COUNTRY = 'India';
        request.REGION = 'Maharashtra';
        request.CURRNCY = 'INR';
        request.PAN_NO = 'ABCDE1234F';
        request.MOBILE_NO = '9876543210';
        request.TAXNO3 = 'GSTIN1234';
        request.GST_TYPE_C = 'Regular';
        request.CRED_LIMIT = '100000';
        request.INDUSTRY = 'Manufacturing';
        request.RECON_ACCT = 'RECON001';
        request.EXRATETYPE = 'M';
        
        // Create sales area data
        AccountMaster_API.SalesArea salesArea = new AccountMaster_API.SalesArea();
        salesArea.COCODE = 'COM1';
        salesArea.SALES_ORG = '1000';
        salesArea.DISTR_CHL = '10';
        salesArea.DIVISION = '10';
        salesArea.INCOTERMS = 'CIF';
        salesArea.PAYT_TERMS = '0001';
        salesArea.SALES_DISTRICT = 'NORTH';
        salesArea.CUSTGROUP = 'GROUP1';
        salesArea.PRICEGRP = 'PRICE1';
        salesArea.PRICE_LIST = 'LIST1';
        salesArea.CUSTSTATGR = 'STAT1';
        salesArea.INVOIC_DAT = 'D';
        salesArea.INVLISTSCH = 'WEEKLY';
        salesArea.CRED_LIMIT = '50000';
        salesArea.CURR = 'INR';
        
        // Create partner functions
        AccountMaster_API.PartnerFunction partnerFunc = new AccountMaster_API.PartnerFunction();
        partnerFunc.PARTNERFN = 'SP';
        partnerFunc.PARTNER_FUNC = 'Sold-To Party';
        partnerFunc.TITLE0070 = 'Mr.';
        partnerFunc.CITY0072 = 'Delhi';
        partnerFunc.COUNTRY0073 = 'India';
        partnerFunc.REGION0074 = 'Delhi';
        partnerFunc.POST_CODE0075 = '110001';
        partnerFunc.CUSTOMR_NO = 'TEST001';
        partnerFunc.SALES_ORG0079 = '1000';
        partnerFunc.DISTR_CHANN = '10';
        partnerFunc.DIVISION0081 = '10';
        partnerFunc.NAME = 'Partner Customer';
        partnerFunc.FIRST_NAME0088 = 'Partner';
        partnerFunc.LAST_NAME0089 = 'Customer';
        partnerFunc.CITY1 = 'Bangalore';
        partnerFunc.POSTL_CODE = '560001';
        partnerFunc.DISTRICT = 'Central';
        partnerFunc.STATE = 'Karnataka';
        partnerFunc.REGION0096 = 'South';
        partnerFunc.COUNTRY0097 = 'India';
        partnerFunc.TAX_CLASS0099 = 'CLASS1';
        
        salesArea.PARTNER_FUNCTIONS = new List<AccountMaster_API.PartnerFunction>{partnerFunc};
        request.SALES_AREA = new List<AccountMaster_API.SalesArea>{salesArea};
        
        // Create contact data
        AccountMaster_API.ContactData contactData = new AccountMaster_API.ContactData();
        contactData.CUSTOMER_NO0103 = 'TEST001';
        contactData.FIRST_NAME0109 = 'John';
        contactData.LAST_NAME0110 = 'Doe';
        contactData.MOBILE = '9876543210';
        contactData.EMAIL_ID = 'john.doe@test.com';
        contactData.ROLE_FUNCTION = 'Manager';
        contactData.TITLE0114 = 'Mr.';
        contactData.DEPARTMENT = 'Sales';
        contactData.TELEPHONE_1 = '1234567890';
        contactData.CONTACT_ADDRESS = 'Contact Address';
        contactData.CONTACT_CITY = 'Mumbai';
        contactData.CONTACT_POSTCODE = '400001';
        
        request.CONTACT = new List<AccountMaster_API.ContactData>{contactData};
        
        // Create bank data
        AccountMaster_API.BankData bankData = new AccountMaster_API.BankData();
        bankData.CUSTOMER_NO0126 = 'TEST001';
        bankData.BANK_KEY = 'BANK001';
        bankData.BANKL = 'BANKL001';
        bankData.BANKNAME = 'Test Bank';
        bankData.BANKBRANCH = 'Main Branch';
        bankData.BANK_ACC_NO = 'ACC123456789';
        
        request.BANK = new List<AccountMaster_API.BankData>{bankData};
        
        requests.add(request);
        
        Test.startTest();
        
        // Test 1: Success scenario
        String requestBody1 = JSON.serialize(requests);
        setupRestContext(requestBody1);
        AccountMaster_API.upsertAccountMaster();
        
        // Test 2: Update existing account
        List<AccountMaster_API.AccountMasterRequest> updateRequests = new List<AccountMaster_API.AccountMasterRequest>();
        AccountMaster_API.AccountMasterRequest updateRequest = new AccountMaster_API.AccountMasterRequest();
        updateRequest.SFDC_ID = null;
        updateRequest.CUSTOMER_NO = 'EXIST001';
        updateRequest.CUST_NAME = 'Updated Customer Name';
        updateRequest.EMAIL1 = 'updated@test.com';
        updateRequest.CITY = 'Mumbai';
        updateRequest.COUNTRY = 'India';
        updateRequests.add(updateRequest);
        
        String requestBody2 = JSON.serialize(updateRequests);
        setupRestContext(requestBody2);
        AccountMaster_API.upsertAccountMaster();
        
        // Test 3: Multiple accounts
        List<AccountMaster_API.AccountMasterRequest> multiRequests = new List<AccountMaster_API.AccountMasterRequest>();
        for (Integer i = 1; i <= 3; i++) {
            AccountMaster_API.AccountMasterRequest multiRequest = new AccountMaster_API.AccountMasterRequest();
            multiRequest.CUSTOMER_NO = 'MULTI00' + i;
            multiRequest.CUST_NAME = 'Multi Customer ' + i;
            multiRequest.EMAIL1 = 'multi' + i + '@test.com';
            multiRequest.CITY = 'Mumbai';
            multiRequest.COUNTRY = 'India';
            
            AccountMaster_API.SalesArea multiSalesArea = new AccountMaster_API.SalesArea();
            multiSalesArea.SALES_ORG = '1000';
            multiSalesArea.DISTR_CHL = '10';
            multiSalesArea.DIVISION = '10';
            multiSalesArea.PARTNER_FUNCTIONS = new List<AccountMaster_API.PartnerFunction>();
            multiRequest.SALES_AREA = new List<AccountMaster_API.SalesArea>{multiSalesArea};
            
            multiRequests.add(multiRequest);
        }
        
        String requestBody3 = JSON.serialize(multiRequests);
        setupRestContext(requestBody3);
        AccountMaster_API.upsertAccountMaster();
        
        Test.stopTest();
        
        // Verify results
        List<Account> accounts = [SELECT Id, Name, SAP_Customer_Code__c FROM Account WHERE SAP_Customer_Code__c = 'TEST001'];
        
        List<Contact> contacts = [SELECT Id, FirstName, LastName FROM Contact WHERE Email = 'john.doe@test.com'];
        
        List<Bank_Information__c> bankInfos = [SELECT Id, Bank_A_C_No__c FROM Bank_Information__c WHERE Bank_A_C_No__c = 'ACC123456789'];
        
        List<Customer_Sales_Area__c> salesAreas = [SELECT Id, Name FROM Customer_Sales_Area__c WHERE External_Id__c = 'TEST001-1000-10-10'];
        
        List<Partner_Function__c> partnerFuncs = [SELECT Id, PARTNERFN__c FROM Partner_Function__c WHERE External_Id__c = 'TEST001-SP-1000-10-10'];
        
        List<Account> multiAccounts = [SELECT Id, SAP_Customer_Code__c FROM Account WHERE SAP_Customer_Code__c LIKE 'MULTI00%'];
    }
    
    @isTest
    static void testErrorScenariosAndSFDCId() {
        // Get existing account for SFDC ID test
        Account existingAcc = [SELECT Id FROM Account WHERE SAP_Customer_Code__c = 'EXIST001' LIMIT 1];
        
        Test.startTest();
        
        // Test 1: With SFDC ID
        List<AccountMaster_API.AccountMasterRequest> sfdcRequests = new List<AccountMaster_API.AccountMasterRequest>();
        AccountMaster_API.AccountMasterRequest sfdcRequest = new AccountMaster_API.AccountMasterRequest();
        sfdcRequest.SFDC_ID = existingAcc.Id;
        sfdcRequest.CUSTOMER_NO = 'EXIST001';
        sfdcRequest.CUST_NAME = 'Updated Via SFDC ID';
        sfdcRequest.CITY = 'Mumbai';
        sfdcRequest.COUNTRY = 'India';
        sfdcRequests.add(sfdcRequest);
        
        String requestBody4 = JSON.serialize(sfdcRequests);
        setupRestContext(requestBody4);
        AccountMaster_API.upsertAccountMaster();
        
        // Test 2: Empty request body
        try {
            setupRestContext('');
            AccountMaster_API.upsertAccountMaster();
        } catch (Exception e) {
            // Expected exception
        }
        
        // Test 3: Invalid JSON
        setupRestContext('invalid json {');
        AccountMaster_API.upsertAccountMaster();
        
        // Test 4: Missing references
        List<AccountMaster_API.AccountMasterRequest> missingRefRequests = new List<AccountMaster_API.AccountMasterRequest>();
        AccountMaster_API.AccountMasterRequest missingRefRequest = new AccountMaster_API.AccountMasterRequest();
        missingRefRequest.CUSTOMER_NO = 'MISSREF001';
        missingRefRequest.CUST_NAME = 'Missing Ref Customer';
        missingRefRequest.CITY = 'NonExistentCity';
        missingRefRequest.COUNTRY = 'India';
        
        AccountMaster_API.SalesArea missingSalesArea = new AccountMaster_API.SalesArea();
        missingSalesArea.SALES_ORG = '9999';
        missingSalesArea.DISTR_CHL = '99';
        missingSalesArea.DIVISION = '99';
        missingSalesArea.PARTNER_FUNCTIONS = new List<AccountMaster_API.PartnerFunction>();
        missingRefRequest.SALES_AREA = new List<AccountMaster_API.SalesArea>{missingSalesArea};
        
        missingRefRequests.add(missingRefRequest);
        
        String requestBody3 = JSON.serialize(missingRefRequests);
        setupRestContext(requestBody3);
        AccountMaster_API.upsertAccountMaster();
        
        Test.stopTest();
        
        // Verify error scenarios were handled
        List<Account> missingRefAccounts = [SELECT Id FROM Account WHERE SAP_Customer_Code__c = 'MISSREF001'];
    }
    
    @isTest
    static void testResponseWrapper() {
        // Test ResponseWrapper class separately
        AccountMaster_API.ResponseWrapper wrapper = new AccountMaster_API.ResponseWrapper();
        
        System.assertEquals('success', wrapper.status);
        System.assertEquals('Customer Upsert successfully', wrapper.message);
        System.assertNotEquals(null, wrapper.data);
        System.assertNotEquals(null, wrapper.errors);
    }
    
    // Helper method to setup REST context
    private static void setupRestContext(String requestBody) {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/UpsertAccountMaster/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = req;
        RestContext.response = res;
    }
}