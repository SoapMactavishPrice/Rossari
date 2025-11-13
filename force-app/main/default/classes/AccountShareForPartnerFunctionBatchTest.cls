@IsTest
public class AccountShareForPartnerFunctionBatchTest {
    
    @TestSetup
    static void setupTestData() {
        // Create a user who will be the Sales Employee
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User salesEmp = new User(
            FirstName = 'Test',
            LastName = 'SalesEmp',
            Alias = 'tse',
            Email = 'test.salesemp@example.com',
            Username = 'test.salesemp' + DateTime.now().getTime() + '@example.com',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert salesEmp;
        
        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Customer_Sales_Area__c  csa = new Customer_Sales_Area__c ();
        csa.Comapany_Code__c = acc.Id;
        insert csa;
        
        // Create Partner_function__c record with PARTNER_FUNC__c = 'VE'
        Partner_function__c pf = new Partner_function__c(
            Name = 'Partner 1',
            PARTNER_FUNC__c = 'VE',
            Account__c = acc.Id,
            Customer_Sales_Area__c = csa.Id,
            Sales_Employee__c = salesEmp.Id
        );
        insert pf;
        
        // Create another record where PARTNER_FUNC__c is not VE (negative test)
        Partner_function__c pfInvalid = new Partner_function__c(
            Name = 'Partner 2',
            PARTNER_FUNC__c = 'DI',
            Account__c = acc.Id,
            Customer_Sales_Area__c = csa.Id,
            Sales_Employee__c = salesEmp.Id
        );
        insert pfInvalid;
    }
    
    @IsTest
    static void testBatchCreatesAccountShare() {
        Integer beforeCount = [SELECT COUNT() FROM AccountShare];
        
        Test.startTest();
        Database.executeBatch(new AccountShareForPartnerFunctionBatch(), 200);
        Test.stopTest();
        
        Integer afterCount = [SELECT COUNT() FROM AccountShare];
        System.assert(afterCount > beforeCount, 
                      'AccountShare count should increase after batch execution.');
        
        AccountShare createdShare = [
            SELECT AccountAccessLevel, OpportunityAccessLevel, CaseAccessLevel, RowCause 
            FROM AccountShare 
            WHERE RowCause = 'Manual' 
            LIMIT 1
        ];
        //System.assertEquals('Read', createdShare.AccountAccessLevel,'Access level should be Read.');
    }
    
    @IsTest
    static void testBatchDoesNotDuplicateShares() {
        Partner_function__c pf = [
            SELECT Account__c, Sales_Employee__c 
            FROM Partner_function__c 
            WHERE PARTNER_FUNC__c = 'VE' 
            LIMIT 1
        ];
        
        // Insert a manual AccountShare upfront
        AccountShare existingShare = new AccountShare(
            AccountId = pf.Account__c,
            UserOrGroupId = pf.Sales_Employee__c,
            AccountAccessLevel = 'Read',
            OpportunityAccessLevel = 'None',
            CaseAccessLevel = 'None',
            RowCause = Schema.AccountShare.RowCause.Manual
        );
        insert existingShare;
        
        Integer beforeCount = [SELECT COUNT() FROM AccountShare];
        
        Test.startTest();
        Database.executeBatch(new AccountShareForPartnerFunctionBatch(), 200);
        Test.stopTest();
        
        Integer afterCount = [SELECT COUNT() FROM AccountShare];
        System.assertEquals(beforeCount, afterCount, 'No duplicate AccountShare should be inserted.');
    }
    
    @IsTest
    static void testScheduledExecution() {
        Test.startTest();
        String cronExp = '0 0 2 * * ?';
        System.schedule('Test Schedule - AccountShareBatch', cronExp, new AccountShareForPartnerFunctionBatch());
        Test.stopTest();
        
        List<CronTrigger> ct = [
            SELECT Id, CronJobDetail.Name 
            FROM CronTrigger 
            WHERE CronJobDetail.Name = 'Test Schedule - AccountShareBatch'
        ];
        System.assert(ct.size() > 0, 'Scheduled job should be created.');
    }
}