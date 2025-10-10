@IsTest
public class COAUnlockOnSubmitTest {

    @IsTest
    static void testUnlockQueueableJob() {
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            MobilePhone = '9876564320'
        );
        insert testLead;

        Approval.LockResult lockResult = Approval.lock(testLead.Id);
        System.assert(lockResult.isSuccess(), 'Record should be locked successfully');
        System.assert(Approval.isLocked(testLead.Id), 'Lead should be locked before unlocking');

        List<Id> recordIds = new List<Id>{ testLead.Id };
        Test.startTest();
        COAUnlockOnSubmit.unlock(recordIds);
        Test.stopTest(); 

        System.assert(!Approval.isLocked(testLead.Id), 'Lead should be unlocked after job execution');
    }
}