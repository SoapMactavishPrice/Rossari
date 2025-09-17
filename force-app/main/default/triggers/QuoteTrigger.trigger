trigger QuoteTrigger on Quote (before update, after update) {

    // BEFORE UPDATE: Validate approval status and track previous payment term
    if (Trigger.isBefore && Trigger.isUpdate) {
        QuoteController.validateQuoteApprovalStatus(Trigger.new, Trigger.oldMap);

        for (Quote q : Trigger.new) {
            Quote oldQ = Trigger.oldMap.get(q.Id);
            if (q.Payment_Term__c != oldQ.Payment_Term__c) {
                q.Previous_Payment_Terms__c = oldQ.Payment_Term__c;
                q.Status = 'Credit Approval';
            }
        }
    }

    // AFTER UPDATE: Send email if payment term changed or credit status changed
    if (Trigger.isAfter && Trigger.isUpdate) {
        List<Quote> quotesToNotify = new List<Quote>();

        for (Quote q : Trigger.new) {
            Quote oldQ = Trigger.oldMap.get(q.Id);

            Boolean paymentTermChanged = q.Payment_Term__c != oldQ.Payment_Term__c;
            Boolean creditStatusChanged = q.Credit_Approval_Status__c != oldQ.Credit_Approval_Status__c &&
                                          (q.Credit_Approval_Status__c == 'Approved' || q.Credit_Approval_Status__c == 'Rejected');

            if (paymentTermChanged || creditStatusChanged) {
                quotesToNotify.add(q);
            }
        }

        if (!quotesToNotify.isEmpty()) {
            QuoteTriggerHandler.sendPaymentTermChangeEmails(quotesToNotify);
        }
    }
}