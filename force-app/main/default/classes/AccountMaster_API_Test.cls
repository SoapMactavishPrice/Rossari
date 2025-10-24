@IsTest
public class AccountMaster_API_Test {

    // Helper method to generate mock JSON request body
    public static String getMockRequestBody() {
        AccountMaster_API.AccountMasterRequest req = new AccountMaster_API.AccountMasterRequest();
        req.SFDC_ID = null;
        req.CUSTOMER_NO = 'CUST001';
        req.CUST_NAME = 'Test Customer';
        req.CITY = 'TestCity';
        req.COUNTRY = 'India';
        req.REGION = 'MH';
        req.CRED_LIMIT = '10000';
        req.CURRNCY = 'INR';

        AccountMaster_API.SalesArea sa = new AccountMaster_API.SalesArea();
        sa.COCODE = 'COMP01';
        sa.SALES_ORG = 'SO1';
        sa.DISTR_CHL = 'DCH1';
        sa.DIVISION = 'DIV1';
        sa.PAYT_TERMS = 'PT01';
        sa.SALES_DISTRICT = 'SD01';
        sa.PARTNER_FUNCTIONS = new List<AccountMaster_API.PartnerFunction>();
        AccountMaster_API.PartnerFunction pf = new AccountMaster_API.PartnerFunction();
        pf.PARTNERFN = 'PF1';
        pf.CUSTOMR_NO = 'CUST001';
        pf.SALES_ORG0079 = 'SO1';
        pf.DISTR_CHANN = 'DCH1';
        pf.DIVISION0081 = 'DIV1';
        sa.PARTNER_FUNCTIONS.add(pf);

        req.SALES_AREA = new List<AccountMaster_API.SalesArea>{sa};

        AccountMaster_API.ContactData con = new AccountMaster_API.ContactData();
        con.FIRST_NAME0109 = 'John';
        con.LAST_NAME0110 = 'Doe';
        con.EMAIL_ID = 'john@example.com';
        con.CONTACT_CITY = 'TestCity';
        con.CONTACT_POSTCODE = '400001';
        req.CONTACT = new List<AccountMaster_API.ContactData>{con};

        AccountMaster_API.BankData bank = new AccountMaster_API.BankData();
        bank.CUSTOMER_NO0126 = 'CUST001';
        bank.BANK_ACC_NO = '123456';
        bank.BANK_KEY = 'BK001';
        req.BANK = new List<AccountMaster_API.BankData>{bank};

        return JSON.serialize(new List<AccountMaster_API.AccountMasterRequest>{req});
    }

    @IsTest
    static void testUpsertAccountMaster() {

        // Test with valid JSON body
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/UpsertAccountMaster/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(getMockRequestBody());
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        AccountMaster_API.upsertAccountMaster();
        Test.stopTest();

    }

    @IsTest
    static void testPrivateMethodsForCoverage() {
        Account acc = new Account(Name='Acc1', SAP_Customer_Code__c='CUST001');
        insert acc;

        List<AccountMaster_API.ContactData> contacts = new List<AccountMaster_API.ContactData>();
        AccountMaster_API.ContactData cd = new AccountMaster_API.ContactData();
        cd.FIRST_NAME0109 = 'f';
        cd.LAST_NAME0110 = 'l';
        cd.EMAIL_ID = 'a@test.com';
        contacts.add(cd);
        // AccountMaster_API.prepareContacts(contacts, acc);

        List<AccountMaster_API.BankData> bankList = new List<AccountMaster_API.BankData>();
        AccountMaster_API.BankData bd = new AccountMaster_API.BankData();
        bd.CUSTOMER_NO0126 = 'CUST001';
        bd.BANK_ACC_NO = '123';
        bd.BANKL = 'L';
        bankList.add(bd);
        // AccountMaster_API.prepareBankDetails(bankList, acc);

        List<AccountMaster_API.SalesArea> saList = new List<AccountMaster_API.SalesArea>();
        AccountMaster_API.SalesArea sa = new AccountMaster_API.SalesArea();
        sa.SALES_ORG = 'SO1';
        sa.DISTR_CHL = 'DC1';
        sa.DIVISION = 'DIV1';
        sa.PAYT_TERMS = 'PT1';
        sa.SALES_DISTRICT = 'SD1';
        saList.add(sa);
        // AccountMaster_API.prepareSalesAreas(saList, acc);

        Map<Id, Account> successAcc = new Map<Id, Account>{acc.Id => acc};
        Map<String, List<Contact>> accountContactsMap = new Map<String, List<Contact>>();
        Map<String, List<Bank_Information__c>> accountBankMap = new Map<String, List<Bank_Information__c>>();
        Map<String, List<Customer_Sales_Area__c>> accountSalesMap = new Map<String, List<Customer_Sales_Area__c>>();
        AccountMaster_API.ResponseWrapper resp = new AccountMaster_API.ResponseWrapper();

        AccountMaster_API.processAllContacts(successAcc, accountContactsMap, resp);
        AccountMaster_API.processAllBankDetails(successAcc, accountBankMap, resp);
        AccountMaster_API.processAllSalesAreas(successAcc, accountSalesMap, resp);
    }
}