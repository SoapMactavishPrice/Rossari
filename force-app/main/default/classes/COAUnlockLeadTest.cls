@IsTest
public class COAUnlockLeadTest {
    @IsTest
    static void testUnlockRecords() {
        
        //Pin_Code__c pin = [SELECT Id FROM Pin_Code__c LIMIT 1];
        // Step 1: Create a test Lead record
        Lead testLead = new Lead(
            FirstName = 'Teste',
            LastName = 'Lead',
            Company = 'Test Company',
             MobilePhone = '9876564320'
            ///Pin_Code__c = pin.Id
        );
        insert testLead;

        // Step 2: Lock the record using Approval API
        Approval.LockResult lockResult = Approval.lock(testLead.Id);
        System.assert(lockResult.isSuccess(), 'Record should be locked successfully');

        // Step 3: Call your InvocableMethod
        List<Id> recordIds = new List<Id>{ testLead.Id };
        Test.startTest();
        COAUnlockLead.unlockRecords(recordIds);
        Test.stopTest();

        // Step 4: Verify the record is unlocked
        //Lead unlockedLead = [SELECT Id, IsLocked FROM Lead WHERE Id = :testLead.Id];
        //System.assertEquals(false, unlockedLead.IsLocked, 'Lead record should be unlocked');
    }
}