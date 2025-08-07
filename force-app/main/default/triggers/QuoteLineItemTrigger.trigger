trigger QuoteLineItemTrigger on QuoteLineItem (before insert, before update, after update) {
    

    if (Trigger.isBefore) {
        if (Trigger.isUpdate) {
            QuoteLineItemTriggerHandler.updateIsSPlessThanLP(Trigger.new, Trigger.oldMap);
        }

        if (Trigger.isInsert) {
            QuoteLineItemTriggerHandler.updateIsSPlessThanLPForInsert(Trigger.new);
        }
    }

    // Store old values before the update happens
    if (Trigger.isBefore && Trigger.isUpdate) {
        QuoteLineItemTriggerHandler.storeOldValues(Trigger.oldMap);
    }
    
    // After update, check if values have changed and update custom fields
    if (Trigger.isAfter && Trigger.isUpdate) {
        QuoteLineItemTriggerHandler.updatePreviousValues(Trigger.newMap);
    }
}