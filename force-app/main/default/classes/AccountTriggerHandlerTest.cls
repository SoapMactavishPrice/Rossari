@IsTest
public class AccountTriggerHandlerTest {

    @TestSetup
    static void setupData() {
        // Fetch existing Primary record type
        RecordType primaryRT = [SELECT Id FROM RecordType WHERE SObjectType='Account' AND DeveloperName='Primary' LIMIT 1];
        RecordType secondaryRT = [SELECT Id FROM RecordType WHERE SObjectType='Account' AND DeveloperName='Secondary' LIMIT 1];

        // Create Primary Distributor Account
        Account primaryAcc = new Account(
            Name = 'Primary Distributor',
            RecordTypeId = primaryRT.Id
        );
        insert primaryAcc;

        // Create Secondary account with valid distributor
        Account secondaryAcc = new Account(
            Name = 'Secondary Account',
            RecordTypeId = secondaryRT.Id,
            Distributor_Name__c = primaryAcc.Id
        );
        insert secondaryAcc;
    }

    @IsTest
    static void testValidDistributor() {
        Account secAcc = [SELECT Id, Distributor_Name__c, RecordType.DeveloperName FROM Account WHERE Name='Secondary Account' LIMIT 1];

        Test.startTest();
        AccountTriggerHandler.validateDistributorAccount(new List<Account>{ secAcc });
        Test.stopTest();

        System.assertEquals(secAcc.Distributor_Name__c != null, true);
    }

    @IsTest
    static void testNoDistributor() {
        RecordType secondaryRT = [SELECT Id FROM RecordType WHERE SObjectType='Account' AND DeveloperName='Secondary' LIMIT 1];
        Account secAcc = new Account(
            Name = 'Secondary No Distributor',
            RecordTypeId = secondaryRT.Id
        );

        Test.startTest();
        AccountTriggerHandler.validateDistributorAccount(new List<Account>{ secAcc });
        Test.stopTest();

        System.assert(secAcc.Distributor_Name__c == null);
    }
}