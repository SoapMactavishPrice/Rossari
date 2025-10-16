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
            //Name = 'Interest A',
            Lead__c = leadRecord.Id
            //Quantity__c = 5
        );

        Test.startTest();

        insert prodInterest;

        delete prodInterest;

        undelete prodInterest;

        Test.stopTest();

        Lead updatedLead = [SELECT Id, Status FROM Lead WHERE Id = :leadRecord.Id];
    }
}