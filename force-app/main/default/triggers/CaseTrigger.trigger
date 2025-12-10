trigger CaseTrigger on Case (before insert, before update, after update) {

    // Set CAPA Date before save
    if (Trigger.isBefore) {
        CaseTriggerHandler.setCAPADate(Trigger.new, Trigger.oldMap);
    }

    // Existing logic for email
    if (Trigger.isAfter && Trigger.isUpdate) {
        CaseTriggerHandler.sendSampleEmail(Trigger.new, Trigger.oldMap);
    }
    
    // NEW: Send CAPA email after insert or update
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        CaseTriggerHandler.sendCAPAEmail(Trigger.new);
    }

}