@IsTest
private class TestAccountTrigger {

    @IsTest
    static void testValidateDistributorAccount() {

        RecordType primaryRT = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType='Account' AND DeveloperName='Primary' LIMIT 1];
        RecordType secondaryRT = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType='Account' AND DeveloperName='Secondary' LIMIT 1];

        Account primaryAcc = new Account(
            Name = 'Primary Distributor',
            RecordTypeId = primaryRT.Id
        );
        insert primaryAcc;

        Account secondaryAcc = new Account(
            Name = 'Secondary Account 1',
            RecordTypeId = secondaryRT.Id,
            Distributor_Name__c = primaryAcc.Id
        );

        insert secondaryAcc; 

        Account nonPrimaryParent = new Account(
            Name = 'NonPrimary Parent',
            RecordTypeId = secondaryRT.Id // Note: not Primary
        );
        insert nonPrimaryParent;

        Account secondaryAccInvalid = new Account(
            Name = 'Secondary Account 2',
            RecordTypeId = secondaryRT.Id,
            Distributor_Name__c = nonPrimaryParent.Id
        );

        try {
            insert secondaryAccInvalid;
        } catch (DmlException e) {
        }

        secondaryAcc.Distributor_Name__c = nonPrimaryParent.Id;
        try {
            update secondaryAcc;
        } catch (DmlException e) {
        }
    }
}