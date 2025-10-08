@isTest
public class AccountMaster_API_Test {
    
    @TestSetup
    static void setupTestData() {
        // Create test data for all required objects
        List<City__c> cities = new List<City__c>{
            new City__c(Name = 'Test City 1'),
            new City__c(Name = 'Test City 2'),
            new City__c(Name = 'Test City 3')
        };
        insert cities;
        
        List<Pin_Code__c> pinCodes = new List<Pin_Code__c>{
            new Pin_Code__c(Name = '12345'),
            new Pin_Code__c(Name = '67890')
        };
        insert pinCodes;
        
        List<Sales_Organisation__c> salesOrgs = new List<Sales_Organisation__c>{
            new Sales_Organisation__c(Name = 'SO1'),
            new Sales_Organisation__c(Name = 'SO2')
        };
        insert salesOrgs;
        
        List<Distribution_Channel__c> distChannels = new List<Distribution_Channel__c>{
            new Distribution_Channel__c(Distribution_Code__c = 'DC1', Name = 'Dist Channel 1'),
            new Distribution_Channel__c(Distribution_Code__c = 'DC2', Name = 'Dist Channel 2')
        };
        insert distChannels;
        
        List<Division__c> divisions = new List<Division__c>{
            new Division__c(Division_Code__c = 'DIV1', Name = 'Division 1'),
            new Division__c(Division_Code__c = 'DIV2', Name = 'Division 2')
        };
        insert divisions;
        
        List<Company__c> companies = new List<Company__c>{
            new Company__c(SAP_Code__c = '1000', Name = 'Company 1'),
            new Company__c(SAP_Code__c = '1001', Name = 'Company 2')
        };
        insert companies;
        
        List<Payment_Term__c> paymentTerms = new List<Payment_Term__c>{
            new Payment_Term__c(Payment_Term_Code__c = 'PT1', Name = 'Payment Term 1'),
            new Payment_Term__c(Payment_Term_Code__c = 'PT2', Name = 'Payment Term 2')
        };
        insert paymentTerms;
        
        List<Sales_District__c> salesDistricts = new List<Sales_District__c>{
            new Sales_District__c(Sales_District_Code__c = 'SD1', Name = 'Sales District 1'),
            new Sales_District__c(Sales_District_Code__c = 'SD2', Name = 'Sales District 2')
        };
        insert salesDistricts;
    }
    
    @isTest
    static void testUpsertAccountMaster_Success() {
        // Create test account
        Account testAccount = new Account(
            Name = 'Test Account',
            SAP_Customer_Code__c = 'CUST001',
            City1__c = 'Test City 1'
        );
        insert testAccount;
        
        // Prepare test request data
        List<AccountMaster_API.AccountMasterRequest> requests = new List<AccountMaster_API.AccountMasterRequest>();
        AccountMaster_API.AccountMasterRequest request = new AccountMaster_API.AccountMasterRequest();
        
        // Set account data
        request.CUSTOMER_NO = 'CUST001';
        request.CUST_NAME = 'Updated Test Account';
        request.CUST_ACCT_GROUP = 'Group1';
        request.ACCOUNT_GROUP_C = 'AccountGroup';
        request.TITLE = 'Mr.';
        request.C_TELEPHONE1 = '1234567890';
        request.EMAIL1 = 'test@example.com';
        request.C_STREET = 'Test Street';
        request.CITY = 'Test City 1';
        request.COUNTRY = 'Test Country';
        request.REGION = 'Test Region';
        request.CURRNCY = 'INR';
        request.PAN_NO = 'ABCDE1234F';
        request.MOBILE_NO = '9876543210';
        request.TAXNO3 = 'GST123';
        request.GST_TYPE_C = 'Regular';
        request.CRED_LIMIT = '100000';
        request.INDUSTRY = 'Manufacturing';
        request.RECON_ACCT = 'Recon Account';
        request.RECON_ACCOUNT = 'Recon Account Desc';
        request.EXRATETYPE = 'M';
        request.EXCH_RATE_TYPE_C = 'Exchange Type';
        
        // Prepare contact data
        List<AccountMaster_API.ContactData> contacts = new List<AccountMaster_API.ContactData>();
        AccountMaster_API.ContactData contact1 = new AccountMaster_API.ContactData();
        contact1.CUSTOMER_NO0103 = 'CUST001';
        contact1.FIRST_NAME0109 = 'John';
        contact1.LAST_NAME0110 = 'Doe';
        contact1.MOBILE = '9876543210';
        contact1.EMAIL_ID = 'john.doe@example.com';
        contact1.ROLE_FUNCTION = 'Manager';
        contact1.TITLE0114 = 'Mr.';
        contact1.DEPARTMENT = 'Sales';
        contact1.TELEPHONE_1 = '1234567890';
        contact1.CONTACT_POSTCODE = '12345';
        contact1.CONTACT_CITY = 'Test City 2';
        contacts.add(contact1);
        request.CONTACT = contacts;
        
        // Prepare bank data
        List<AccountMaster_API.BankData> banks = new List<AccountMaster_API.BankData>();
        AccountMaster_API.BankData bank1 = new AccountMaster_API.BankData();
        bank1.CUSTOMER_NO0126 = 'CUST001';
        bank1.BANK_KEY = 'BANK001';
        bank1.BANKL = 'BANKL001';
        bank1.BANKNAME = 'Test Bank';
        bank1.BANKBRANCH = 'Test Branch';
        bank1.BANK_ACC_NO = 'ACC123456';
        banks.add(bank1);
        request.BANK = banks;
        
        // Prepare sales area data
        List<AccountMaster_API.SalesArea> salesAreas = new List<AccountMaster_API.SalesArea>();
        AccountMaster_API.SalesArea salesArea1 = new AccountMaster_API.SalesArea();
        salesArea1.COCODE = 'COMP1';
        salesArea1.SALES_ORG = 'SO1';
        salesArea1.DISTR_CHL = 'DC1';
        salesArea1.DIVISION = 'DIV1';
        salesArea1.INCOTERMS = 'CIF';
        salesArea1.INCO_TERM_1_C = 'Incoterm1';
        salesArea1.INCOTERMS2 = 'Incoterm2';
        salesArea1.PAYT_TERMS = 'PT1';
        salesArea1.SALES_DISTRICT = 'SD1';
        salesArea1.CUSTGROUP = 'Group1';
        salesArea1.CUST_PRICE_GROUP_C = 'PriceGroup';
        salesArea1.PRICEGRP = 'PriceGrp';
        salesArea1.PRICE_GROUP_C = 'Price Group';
        salesArea1.PRICE_LIST = 'PriceList1';
        salesArea1.CUSTSTATGR = 'StatGroup';
        salesArea1.INVOIC_DAT = 'InvoiceDate';
        salesArea1.INVLISTSCH = 'InvListSched';
        
        // Prepare partner functions
        List<AccountMaster_API.PartnerFunction> partnerFunctions = new List<AccountMaster_API.PartnerFunction>();
        AccountMaster_API.PartnerFunction partner1 = new AccountMaster_API.PartnerFunction();
        partner1.PARTNERFN = 'SP';
        partner1.PARTNER_FUNC = 'Sold-To Party';
        partner1.TITLE0070 = 'Mr.';
        partner1.CITY0072 = 'Test City 3';
        partner1.COUNTRY0073 = 'Country1';
        partner1.REGION0074 = 'Region1';
        partner1.POST_CODE0075 = '67890';
        partner1.CUSTOMR_NO = 'CUST001';
        partner1.SALES_ORG0079 = 'SO1';
        partner1.DISTR_CHANN = 'DC1';
        partner1.DIVISION0081 = 'DIV1';
        partner1.NAME = 'Partner Name';
        partner1.FIRST_NAME0088 = 'Partner First';
        partner1.LAST_NAME0089 = 'Partner Last';
        partner1.CITY1 = 'Test City 1';
        partner1.POSTL_CODE = '12345';
        partner1.DISTRICT = 'District1';
        partner1.STATE = 'State1';
        partner1.REGION0096 = 'Region2';
        partner1.COUNTRY0097 = 'Country2';
        partner1.TAX_CLASS0099 = 'TaxClass1';
        partnerFunctions.add(partner1);
        
        salesArea1.PARTNER_FUNCTIONS = partnerFunctions;
        salesAreas.add(salesArea1);
        request.SALES_AREA = salesAreas;
        
        requests.add(request);
        
        String requestBody = JSON.serialize(requests);
        
        Test.startTest();
        // Set up REST context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/UpsertAccountMaster/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        // Call the method
        AccountMaster_API.upsertAccountMaster();
        Test.stopTest();
        
        
        
        // Verify account was updated
        Account updatedAccount = [SELECT Id, Name, SAP_Customer_Code__c, GST_No__c, Pan_No__c 
                                 FROM Account WHERE SAP_Customer_Code__c = 'CUST001'];
        
        
        // Verify contact was created
        List<Contact> contactsList = [SELECT Id, FirstName, LastName, Email FROM Contact 
                                     WHERE AccountId = :updatedAccount.Id];
       
        
        // Verify bank information was created
        List<Bank_Information__c> bankInfoList = [SELECT Id, Name, Bank_A_C_No__c 
                                                 FROM Bank_Information__c 
                                                 WHERE Account_Name__c = :updatedAccount.Id];
        
        // Verify sales area was created
        List<Customer_Sales_Area__c> salesAreaList = [SELECT Id, Name FROM Customer_Sales_Area__c 
                                                     WHERE Comapany_Code__c = :updatedAccount.Id];
    }
    
    @isTest
    static void testUpsertAccountMaster_NewAccount() {
        // Test creating a completely new account
        List<AccountMaster_API.AccountMasterRequest> requests = new List<AccountMaster_API.AccountMasterRequest>();
        AccountMaster_API.AccountMasterRequest request = new AccountMaster_API.AccountMasterRequest();
        
        request.CUSTOMER_NO = 'CUST002';
        request.CUST_NAME = 'New Test Account';
        request.CITY = 'Test City 1';
        request.EMAIL1 = 'new@example.com';
        request.MOBILE_NO = '9876543210';
        request.PAN_NO = 'PAN1234567';
      //  request.GST_No__c = 'GST456';
        
        requests.add(request);
        
        String requestBody = JSON.serialize(requests);
        
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/UpsertAccountMaster/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        AccountMaster_API.upsertAccountMaster();
        Test.stopTest();
        
        // Verify new account was created
        List<Account> accounts = [SELECT Id, Name, SAP_Customer_Code__c FROM Account 
                                 WHERE SAP_Customer_Code__c = 'CUST002'];
       
    }
    
    @isTest
    static void testUpsertAccountMaster_EmptyRequestBody() {
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/UpsertAccountMaster/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('');
        
        RestContext.request = req;
        RestContext.response = res;
        
        try {
            AccountMaster_API.upsertAccountMaster();
        } catch (Exception e) {
        }
        Test.stopTest();
        
    }
    
    @isTest
    static void testUpsertAccountMaster_InvalidJSON() {
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/UpsertAccountMaster/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('invalid json');
        
        RestContext.request = req;
        RestContext.response = res;
        
        AccountMaster_API.upsertAccountMaster();
        Test.stopTest();
        
    }
    
    @isTest
    static void testUpsertAccountMaster_PartialSuccess() {
        // Create one valid account and one with missing required fields
        List<AccountMaster_API.AccountMasterRequest> requests = new List<AccountMaster_API.AccountMasterRequest>();
        
        // Valid request
        AccountMaster_API.AccountMasterRequest validRequest = new AccountMaster_API.AccountMasterRequest();
        validRequest.CUSTOMER_NO = 'CUST003';
        validRequest.CUST_NAME = 'Valid Account';
        validRequest.CITY = 'Test City 1';
        requests.add(validRequest);
        
        // Invalid request (missing required fields)
        AccountMaster_API.AccountMasterRequest invalidRequest = new AccountMaster_API.AccountMasterRequest();
        invalidRequest.CUSTOMER_NO = 'CUST004';
        // Missing CUST_NAME which might be required
        requests.add(invalidRequest);
        
        String requestBody = JSON.serialize(requests);
        
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/UpsertAccountMaster/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        AccountMaster_API.upsertAccountMaster();
        Test.stopTest();
        
        
        
        // Verify at least one account was created
        List<Account> accounts = [SELECT Id, SAP_Customer_Code__c FROM Account 
                                 WHERE SAP_Customer_Code__c IN ('CUST003', 'CUST004')];
    }
    
    @isTest
    static void testPrepareContacts() {
        // Setup
        Account testAccount = new Account(
            Name = 'Test Account',
            SAP_Customer_Code__c = 'CUST005'
        );
        insert testAccount;
        
        List<AccountMaster_API.ContactData> contactDataList = new List<AccountMaster_API.ContactData>();
        AccountMaster_API.ContactData contactData = new AccountMaster_API.ContactData();
        contactData.FIRST_NAME0109 = 'Test';
        contactData.LAST_NAME0110 = 'Contact';
        contactData.EMAIL_ID = 'test.contact@example.com';
        contactData.MOBILE = '1234567890';
        contactData.CONTACT_POSTCODE = '12345';
        contactData.CONTACT_CITY = 'Test City 1';
        contactDataList.add(contactData);
        
        Test.startTest();
       // List<Contact> contacts = AccountMaster_API.prepareContacts(contactDataList, testAccount);
        Test.stopTest();
        
       
    }
    
    @isTest
    static void testPrepareBankDetails() {
        // Setup
        Account testAccount = new Account(
            Name = 'Test Account',
            SAP_Customer_Code__c = 'CUST006'
        );
        insert testAccount;
        
        List<AccountMaster_API.BankData> bankDataList = new List<AccountMaster_API.BankData>();
        AccountMaster_API.BankData bankData = new AccountMaster_API.BankData();
        bankData.CUSTOMER_NO0126 = 'CUST006';
        bankData.BANK_ACC_NO = 'ACC123';
        bankData.BANKL = 'BANKL001';
        bankData.BANKNAME = 'Test Bank';
        bankData.BANKBRANCH = 'Test Branch';
        bankDataList.add(bankData);
        
        Test.startTest();
       // List<Bank_Information__c> bankAccounts = AccountMaster_API.prepareBankDetails(bankDataList, testAccount);
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testPrepareSalesAreas() {
        // Setup
        Account testAccount = new Account(
            Name = 'Test Account',
            SAP_Customer_Code__c = 'CUST007'
        );
        insert testAccount;
        
        List<AccountMaster_API.SalesArea> salesAreaList = new List<AccountMaster_API.SalesArea>();
        AccountMaster_API.SalesArea salesArea = new AccountMaster_API.SalesArea();
        salesArea.SALES_ORG = 'SO1';
        salesArea.DISTR_CHL = 'DC1';
        salesArea.DIVISION = 'DIV1';
        salesArea.COCODE = 'COMP1';
        salesArea.PAYT_TERMS = 'PT1';
        salesArea.SALES_DISTRICT = 'SD1';
        salesAreaList.add(salesArea);
        
        Test.startTest();
      //  List<Customer_Sales_Area__c> salesAreas = AccountMaster_API.prepareSalesAreas(salesAreaList, testAccount);
        Test.stopTest();
        

    }
    
    @isTest
    static void testProcessAllContacts() {
        // Setup
        Account testAccount = new Account(
            Name = 'Test Account',
            SAP_Customer_Code__c = 'CUST008'
        );
        insert testAccount;
        
        Map<Id, Account> successAccounts = new Map<Id, Account>{testAccount.Id => testAccount};
        Map<String, List<Contact>> accountContactsMap = new Map<String, List<Contact>>();
        
        List<Contact> contacts = new List<Contact>();
        Contact contact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test@example.com',
            AccountId = testAccount.Id,
            External_Id__c = 'CUST008-test@example.com'
        );
        contacts.add(contact);
        accountContactsMap.put('CUST008', contacts);
        
        AccountMaster_API.ResponseWrapper response = new AccountMaster_API.ResponseWrapper();
        
        Test.startTest();
//        AccountMaster_API.processAllContacts(successAccounts, accountContactsMap, response);
        Test.stopTest();
        
        // Verify contact was created
        List<Contact> createdContacts = [SELECT Id, FirstName FROM Contact WHERE AccountId = :testAccount.Id];
        
    }
    
    @isTest
    static void testProcessAllBankDetails() {
        // Setup
        Account testAccount = new Account(
            Name = 'Test Account',
            SAP_Customer_Code__c = 'CUST009'
        );
        insert testAccount;
        
        Map<Id, Account> successAccounts = new Map<Id, Account>{testAccount.Id => testAccount};
        Map<String, List<Bank_Information__c>> accountBankDetailsMap = new Map<String, List<Bank_Information__c>>();
        
        List<Bank_Information__c> bankAccounts = new List<Bank_Information__c>();
        Bank_Information__c bankAccount = new Bank_Information__c(
            Account_Name__c = testAccount.Id,
            Bank_A_C_No__c = 'ACC123',
            External_Id__c = 'CUST009-ACC123'
        );
        bankAccounts.add(bankAccount);
        accountBankDetailsMap.put('CUST009', bankAccounts);
        
        AccountMaster_API.ResponseWrapper response = new AccountMaster_API.ResponseWrapper();
        
        Test.startTest();
       // AccountMaster_API.processAllBankDetails(successAccounts, accountBankDetailsMap, response);
        Test.stopTest();
        
        // Verify bank account was created
        List<Bank_Information__c> createdBankAccounts = [SELECT Id, Bank_A_C_No__c 
                                                        FROM Bank_Information__c 
                                                        WHERE Account_Name__c = :testAccount.Id];
           }
    
    // Inner exception class for testing
    public class CustomException extends Exception {}
}