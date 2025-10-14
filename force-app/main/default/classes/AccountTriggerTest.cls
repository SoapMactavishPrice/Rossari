@isTest
public class AccountTriggerTest {

    @isTest
    static void testTrigger_InsertUpdate() {
        Account acc = new Account(
            Name = 'Test Account',
            Type = 'Distributor',
            SAP_Customer_Code__c = 'CUST001'
        );

        
        insert acc;
        

        Account insertedAcc = [SELECT Id, Name, SAP_Customer_Code__c FROM Account WHERE Id = :acc.Id];


        insertedAcc.Name = 'Updated Account';

     	Test.startTest();
        update insertedAcc;
        Test.stopTest();

        Account updatedAcc = [SELECT Id, Name, SAP_Customer_Code__c FROM Account WHERE Id = :acc.Id];

    }
}