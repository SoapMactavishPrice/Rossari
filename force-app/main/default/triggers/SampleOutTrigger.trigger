trigger SampleOutTrigger on Sample_Out__c (before insert, before update, after insert) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            SampleOutController.updateSampleOutAddresses(Trigger.new);
        }
    }
    
    if (Trigger.isAfter && Trigger.isInsert) {
        SampleOutController.markRequestsCompleted(Trigger.new);
    }
}