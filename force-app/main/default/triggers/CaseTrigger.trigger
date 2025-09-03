trigger CaseTrigger on Case (after update) {
    
    if (Trigger.isAfter && Trigger.isUpdate) {
        CaseTriggerHandler.sendSampleEmail(Trigger.new, Trigger.oldMap);
    }
}