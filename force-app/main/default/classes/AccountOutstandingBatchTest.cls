/*@isTest
public class AccountOutstandingBatchTest {

    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"success"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @testSetup
    static void setupTestData() {
        List<Company__c> companies = new List<Company__c>();
        for(Integer i = 0; i < 2; i++){
            companies.add(new Company__c(
                Name = 'Company ' + i,
                SAP_Code__c = 'SAP' + i
            ));
        }
        insert companies;
        
        List<Account> accounts = new List<Account>();
        for(Integer i = 0; i < 3; i++){
            accounts.add(new Account(
                Name = 'Test Account ' + i,
                SAP_Customer_Code__c = 'CUST' + i
            ));
        }
        insert accounts;
    }

    @isTest
    static void testBatchExecution() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Date fromDate = Date.today().addDays(-10);
        Date toDate = Date.today();

        AccountOutstandingBatch batch = new AccountOutstandingBatch(fromDate, toDate);

        Test.startTest();
        Database.executeBatch(batch, 2);
        Test.stopTest();

       
    }

    @isTest
    static void testBatchWithChaining() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        List<Account> accounts = [SELECT Id, SAP_Customer_Code__c FROM Account LIMIT 2];
        Date fromDate = Date.today().addDays(-5);
        Date toDate = Date.today();

        AccountOutstandingBatch batch = new AccountOutstandingBatch(fromDate, toDate, accounts, 0);

        Test.startTest();
        batch.execute(null, accounts);
        Test.stopTest();

    }
}*/

@IsTest
private class AccountOutstandingBatchTest {

    @IsTest
    static void testBatchExecutionSingleAccount() {
        // Step 1: Create Company__c records
        Company__c company = new Company__c(
            Name = 'Company 1',
            SAP_Code__c = 'COM1'
        );
        insert company;

        // Step 2: Create a single Account with SAP_Customer_Code__c
        Account acc = new Account(
            Name = 'Test Account 1',
            SAP_Customer_Code__c = 'CUST1'
        );
        insert acc;

        // Step 3: Set fromDate and toDate
        Date fromDate = Date.today().addDays(-30);
        Date toDate = Date.today();

        // Step 4: Execute batch
        Test.startTest();
            AccountOutstandingBatch batchJob = new AccountOutstandingBatch(fromDate, toDate);
            Database.executeBatch(batchJob, 1); // batch size = 1
        Test.stopTest();
    }

    @IsTest
    static void testBatchWithNoAccounts() {
        // No Account records inserted
        Date fromDate = Date.today().addDays(-30);
        Date toDate = Date.today();

        Test.startTest();
            AccountOutstandingBatch batchJob = new AccountOutstandingBatch(fromDate, toDate);
            Database.executeBatch(batchJob, 1);
        Test.stopTest();
    }
}