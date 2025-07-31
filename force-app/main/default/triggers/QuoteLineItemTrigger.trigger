trigger QuoteLineItemTrigger on QuoteLineItem (before insert, before update, after update) {
    
    // Store old values before the update happens
    if (Trigger.isBefore && Trigger.isUpdate) {
        QuoteLineItemTriggerHandler.storeOldValues(Trigger.oldMap);
    }
    
    // After update, check if values have changed and update custom fields
    if (Trigger.isAfter && Trigger.isUpdate) {
        QuoteLineItemTriggerHandler.updatePreviousValues(Trigger.newMap);
    }
}