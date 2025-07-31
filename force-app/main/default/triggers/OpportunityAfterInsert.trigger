trigger OpportunityAfterInsert on Opportunity (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        OptyTriggerHandler.handleLeadConversionOpportunities(Trigger.new);
    }
}