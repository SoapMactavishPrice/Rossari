trigger QuoteTrigger on Quote (before update) {
    if (Trigger.isBefore && Trigger.isUpdate) {
        QuoteController.validateQuoteApprovalStatus(Trigger.new, Trigger.oldMap);
    }
}