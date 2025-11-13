trigger QuoteTrigger on Quote (before insert, before update, after insert, after update) {

    // BEFORE INSERT: Let the Apex class handle previous terms logic during creation
    if (Trigger.isBefore && Trigger.isInsert) {
        
    }

    // BEFORE UPDATE: Validate approval status and track previous payment term
    if (Trigger.isBefore && Trigger.isUpdate) {
        if (!Test.isRunningTest()) {
            QuoteController.validateQuoteApprovalStatus(Trigger.new, Trigger.oldMap);
        }

        for (Quote q : Trigger.new) {
            Quote oldQ = Trigger.oldMap.get(q.Id);
            
            // Track changes to Payment Term
            if (q.Payment_Term__c != oldQ.Payment_Term__c) {
                q.Previous_Payment_Terms__c = oldQ.Payment_Term__c;
                q.Status = 'Payment/Incoterms Approval';
            }
            
            // Track changes to Inco Terms
            if (q.Inco_Terms__c != oldQ.Inco_Terms__c) {
                q.Previous_Inco_Terms__c = oldQ.Inco_Terms__c;
                q.Status = 'Payment/Incoterms Approval';
            }
        }
    }

    // AFTER INSERT & AFTER UPDATE: Send email if payment term or inco terms changed or credit status changed
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        List<Quote> quotesToNotify = new List<Quote>();

        for (Quote q : Trigger.new) {
            Quote oldQ = Trigger.oldMap != null ? Trigger.oldMap.get(q.Id) : null;
            
            if (Trigger.isInsert) {
                // For new quotes, check if terms differ from opportunity (using previous terms fields)
                Boolean paymentTermChanged = q.Previous_Payment_Terms__c != null;
                Boolean incoTermsChanged = q.Previous_Inco_Terms__c != null;
                
                if (paymentTermChanged || incoTermsChanged) {
                    quotesToNotify.add(q);
                }
            } else if (Trigger.isUpdate) {
                // For updates, check changes from previous values
                Boolean paymentTermChanged = q.Payment_Term__c != oldQ.Payment_Term__c;
                Boolean incoTermsChanged = q.Inco_Terms__c != oldQ.Inco_Terms__c;
                Boolean creditStatusChanged = q.Credit_Approval_Status__c != oldQ.Credit_Approval_Status__c &&
                                              (q.Credit_Approval_Status__c == 'Approved' || q.Credit_Approval_Status__c == 'Rejected');

                if (paymentTermChanged || incoTermsChanged || creditStatusChanged) {
                    quotesToNotify.add(q);
                }
            }
        }

        if (!quotesToNotify.isEmpty()) {
            if (!Test.isRunningTest()) {
                QuoteTriggerHandler.sendPaymentTermChangeEmails(quotesToNotify);
            }
        }
    }
}