@isTest
public class ProductInterestedTriggerTest {
    
    @isTest
    static void test_ProductInterestedTrigger_AllScenarios() {

        Lead leadRecord = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Status = 'New',
            MobilePhone = '9876543210'
        );
        insert leadRecord;

        Product_Interested__c prodInterest = new Product_Interested__c(
            Lead__c = leadRecord.Id
        );

        Test.startTest();

        insert prodInterest;

        prodInterest.New_Product_Name__c = 'New Product ABC';
        update prodInterest;

        delete prodInterest;

        undelete prodInterest;

        Test.stopTest();

        Lead updatedLead = [SELECT Id, Status FROM Lead WHERE Id = :leadRecord.Id];
    }
}