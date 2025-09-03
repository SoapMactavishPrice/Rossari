public class COAUnlockLead {
    @InvocableMethod
    public static void unlockRecords(List<Id> recordIds) {
        for (Id recId : recordIds) {
            Approval.UnlockResult unlockResult = Approval.unlock(recId);
            if (!unlockResult.isSuccess()) {
                for (Database.Error err : unlockResult.getErrors()) {
                    System.debug('Unlock error for ' + recId + ': ' + err.getMessage());
                }
            }
        }
    }
}