@isTest
public class AccountOutstandingQueueableTest {
    
    @testSetup
    static void setupData() {
        // Create and insert Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        // Create and insert Company__c records
        Company__c company1 = new Company__c(Name = 'Company 1', SAP_Code__c = 'C001');
        Company__c company2 = new Company__c(Name = 'Company 2', SAP_Code__c = 'C002');
        insert new List<Company__c>{company1, company2};
        
        // Create a Lead or any related objects required in your logic
        Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            MobilePhone = '9650421782',
            Company = 'Test Account',
            Status = 'Open - Not Contacted'
        );
        insert lead;
    }

    @isTest
    static void testQueueableJobExecution() {
        // Test the execution of the queueable job

        // Prepare test data
        String customerNumber = '12345';
        String currentCompanyCode = 'C001';
        Date fromDate = Date.today().addDays(-30);
        Date toDate = Date.today();
        String accountId = [SELECT Id FROM Account LIMIT 1].Id;
        List<String> companyIds = new List<String>{'Company1', 'Company2'};
        
        // Enqueue the job
        Test.startTest();
        AccountOutstandingQueueable job = new AccountOutstandingQueueable(customerNumber, currentCompanyCode, 
                                                                         fromDate, toDate, accountId, companyIds);
        System.enqueueJob(job);
        Test.stopTest();
        
        // Assert if the job was queued successfully

        // Assert the behavior in the system after the job is executed
        // Here you should check the API Log and other related records
        
        API_Log__c[] logs = [SELECT Id, Status__c FROM API_Log__c WHERE Name = :('Outstanding_API_' + customerNumber + '_C001')];
      
    }

    @isTest
    static void testMakeCalloutToSAP() {
        // Mock the HTTP callout to SAP API
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        String customerNumber = '12345';
        String currentCompanyCode = 'C001';
        Date fromDate = Date.today().addDays(-30);
        Date toDate = Date.today();
        String accountId = [SELECT Id FROM Account LIMIT 1].Id;
        List<String> companyIds = new List<String>{'Company1', 'Company2'};
        
        // Enqueue the queueable job
        Test.startTest();
        AccountOutstandingQueueable job = new AccountOutstandingQueueable(customerNumber, currentCompanyCode, 
                                                                         fromDate, toDate, accountId, companyIds);
        System.enqueueJob(job);
        Test.stopTest();
        
        // Verify if the HTTP request was made and processed
        // Additional assertions can be added here based on the mock response
    }
    
    // Mock HTTP Response generator for the callout
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"outstanding": [{"amount": 1000}, {"amount": 2000}]}'); // Mock a valid SAP response
            return res;
        }
    }
}