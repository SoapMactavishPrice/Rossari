trigger OpportunityTrigger on Opportunity (before insert, after insert, after update) {
    
    if (Trigger.isBefore && Trigger.isInsert) {
        // Handle before insert logic
        OpportunityTriggerHandler.setStandardPricebook(Trigger.new);
    }
    
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            // Handle after insert logic
            OpportunityTriggerHandler.markConvertedOpportunitiesFuture(Trigger.newMap.keySet());
            OpportunityTriggerHandler.handleFollowUpTask(Trigger.new, null);
        }
        
        if (Trigger.isUpdate) {
            // Handle after update logic
            OpportunityTriggerHandler.handleFollowUpTask(Trigger.new, Trigger.oldMap);
        }
    }
}