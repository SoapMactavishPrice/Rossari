public with sharing class COAUnlockOnSubmit {
    @InvocableMethod
    public static void unlock(List<Id> recordIds) {
        System.enqueueJob(new UnlockJob(recordIds));
    }

    public class UnlockJob implements Queueable {
        private List<Id> recordIds;
        public UnlockJob(List<Id> recordIds) {
            this.recordIds = recordIds;
        }
        public void execute(QueueableContext context) {
            for (Id recordId : recordIds) {
                Approval.UnlockResult unlockResult = Approval.unlock(recordId);
                if (!unlockResult.isSuccess()) {
                    System.debug('Failed to unlock record: ' + recordId + ' Error: ' + unlockResult.getErrors());
                } else {
                    System.debug('Successfully unlocked record: ' + recordId);
                }
            }
        }
    }
}