trigger SampleOutTrigger on Sample_Out__c (before insert, before update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            SampleOutController.updateSampleOutAddresses(Trigger.new);
        }
    }
}