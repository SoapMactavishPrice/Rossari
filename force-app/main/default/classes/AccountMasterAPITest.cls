@isTest
private class AccountMasterAPITest {
    @isTest
    static void testDoPost_fullCoverage() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User testUser = new User(
            FirstName='Test', LastName='User', Email='testuser@example.com',
            Username='useru001@example.com', Alias='u001',
            TimeZoneSidKey='America/New_York', LocaleSidKey='en_US',
            EmailEncodingKey='UTF-8', LanguageLocaleKey='en_US',
            ProfileId=p.Id, SAP_User_Id__c='U001', CommunityNickname='u001nick'
        );
        insert testUser;

        insert new Pricebook2(Name='Rossari Domestic Price Book', IsActive=true);
        insert new Pricebook2(Name='Rossari Export Price Book', IsActive=true);

        insert new Company__c(Name='Test Company', Company_Code__c='1000');
        insert new Sales_Organisation__c(Name='2000');
        insert new Distribution_Channel__c(Name='Test DC', Distribution_Code__c='10');
        insert new Division__c(Name='Test Div', Division_Code__c='00');
        insert new Plant__c(Name='3000');

        City__c testCity = new City__c(Name='Test City');
        insert testCity;

        Account parentAcc = new Account(Name='Parent Account', SAP_Customer_Code__c='P001');
        insert parentAcc;

        Account mainAcc = new Account(Name='Main Account', SAP_Customer_Code__c='10001');
        insert mainAcc;

        Contact existingContact = new Contact(LastName='Existing', AccountId=mainAcc.Id);
        insert existingContact;

        Address_Information__c existingAddr = new Address_Information__c(
            Name='Existing Address', Account__c=mainAcc.Id,
            Partner_SAP_Code__c='P001', Address_Type__c='BP', Customer_No__c='10001'
        );
        insert existingAddr;

        Customer_Sales_Area_Line_Item__c existingSalesArea = new Customer_Sales_Area_Line_Item__c(
            Account__c=mainAcc.Id, Name='Existing SA'
        );
        insert existingSalesArea;

        Bank_Information__c existingBankInfo = new Bank_Information__c(
            Account_Name__c=mainAcc.Id, Bank_A_C_No__c='1234567890'
        );
        insert existingBankInfo;

        String jsonBody = '[{' +
            '"CUSTOMER_NO":"10001","COCODE":"1000","SFDC_ID":"",' +
            '"SALES_ORG":"2000","DISTR_CHL":"10","DIVISION":"00","DELIVERY_PLANT":"3000",' +
            '"CRED_LIMIT":"50000","INDUSTRY":"Chemicals","INSTR_KEY":"Special Instructions",' +
            '"C_TELEPHONE2":"0221234567","COUNTRY":"IN","C_STREET":"Street1","STREET":"Street2",' +
            '"STREET2":"Street3","HOUSE_NO":"123","POST_CODE":"400001","CITY":"Test City",' +
            '"SALES_DISTRICT":"SD001","SALES_OFF":"SO001","SALES_GRP":"SG001","CUSTGROUP":"CG001",' +
            '"ABC_CLASS":"A","PRICEGRP":"PG001","INVOIC_DAT":"2024-01-15","INVLISTSCH":"2024-01-20",' +
            '"RECON_ACCT":"RA001","EXRATETYPE":"M",' +
            '"CONTACT_LIST":[{"CUSTOMER_NO":"10001","PARTNERFN":"ZM","TITLE":"Mr.","FIRST_NAME":"John","LAST_NAME":"","EMAIL":"john@example.com","C_TELEPHONE1":"9999999999","C_SFDCID":""}],' +
            '"PARTNERFUNCTION_LIST":[' +
                '{"CUSTOMER_NO":"10001","PARTNERFN":"ZM","CUSTOMR_NO":"U001","STATE":"MH","COUNTRY":"IN","CITY1":"Mumbai","POSTL_CODE":"400001","NAME":"Test ZM","NAME2":"ZM2","NAME3":"ZM3","P_SFDCID":"","FIRST_NAME":"ZMFirst","LAST_NAME":"ZMLast"},' +
                '{"CUSTOMER_NO":"P001","PARTNERFN":"BP","CUSTOMR_NO":"P001","STATE":"MH","COUNTRY":"IN","CITY1":"Pune","POSTL_CODE":"411001","NAME":"BP Name","NAME2":"BP2","NAME3":"BP3","PARAM_VALUE":"ABCDE1234F","TAXNO3":"27ABCDE1234F1Z5","P_SFDCID":""},' +
                '{"CUSTOMER_NO":"P001","PARTNERFN":"SH","CUSTOMR_NO":"P001","STATE":"MH","COUNTRY":"IN","CITY1":"Nashik","POSTL_CODE":"422001","NAME":"SH Name","NAME2":"SH2","NAME3":"SH3","P_SFDCID":""},' +
                '{"CUSTOMER_NO":"","PARTNERFN":"ZE","CUSTOMR_NO":"U001","STATE":"MH","COUNTRY":"IN","CITY1":"Delhi","POSTL_CODE":"110001","NAME":"ZE Name","NAME2":"ZE2","NAME3":"ZE3","P_SFDCID":""}' +
            '],' +
            '"SALES_AREA":[{"CUSTOMER_NO":"10001","SALES_ORG":"2000","DISTR_CHL":"10","DIVISION":"00","S_SFDCID":""}],' +
            '"BANK_DETAILS":[{"BANK_ACC_NO":"1234567890","B_SFDCID":"","BANKNAME":"Test Bank","BANKBRANCH":"Test Branch","BANKL":"TEST0000001"}]' +
        '}]';

        Test.startTest();

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/accountMaster/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);
        RestContext.request = req;
        RestContext.response = res;

        AccountMasterAPI.doPost();

        Test.stopTest();
    }
}