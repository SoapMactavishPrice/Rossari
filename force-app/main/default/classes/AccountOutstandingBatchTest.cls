@isTest
public class AccountOutstandingBatchTest {

    // Mock class for callouts
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
        // Create Company__c records
        List<Company__c> companies = new List<Company__c>();
        for(Integer i = 0; i < 2; i++){
            companies.add(new Company__c(
                Name = 'Company ' + i,
                SAP_Code__c = 'SAP' + i
            ));
        }
        insert companies;
        
        // Create Account records
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
        // Set callout mock for queueable execution
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Date fromDate = Date.today().addDays(-10);
        Date toDate = Date.today();

        // Instantiate batch
        AccountOutstandingBatch batch = new AccountOutstandingBatch(fromDate, toDate);

        // Run the batch
        Test.startTest();
        Database.executeBatch(batch, 2); // batch size 2
        Test.stopTest();

       
    }

    @isTest
    static void testBatchWithChaining() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        List<Account> accounts = [SELECT Id, SAP_Customer_Code__c FROM Account LIMIT 2];
        Date fromDate = Date.today().addDays(-5);
        Date toDate = Date.today();

        // Instantiate batch with accounts and index
        AccountOutstandingBatch batch = new AccountOutstandingBatch(fromDate, toDate, accounts, 0);

        Test.startTest();
        // Execute manually one batch execution to simulate chaining
        batch.execute(null, accounts);
        Test.stopTest();

        // Should have queued a job for first account
        // You can verify queued jobs like this:
    }
}