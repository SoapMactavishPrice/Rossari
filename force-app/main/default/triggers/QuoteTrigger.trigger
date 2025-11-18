trigger QuoteTrigger on Quote (before insert, before update, after insert, after update) {

    // BEFORE INSERT: Let the Apex class handle previous terms logic during creation
    if (Trigger.isBefore && Trigger.isInsert) {
        // No additional logic needed here
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

    // AFTER INSERT & AFTER UPDATE: Send emails for term changes and approvals
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        List<Quote> quotesToNotify = new List<Quote>();

        for (Quote q : Trigger.new) {
            Quote oldQ = Trigger.oldMap != null ? Trigger.oldMap.get(q.Id) : null;
            
            if (Trigger.isInsert) {
                // For new quotes, check if terms differ from opportunity
                Boolean paymentTermChanged = q.Previous_Payment_Terms__c != null;
                Boolean incoTermsChanged = q.Previous_Inco_Terms__c != null;
                
                if (paymentTermChanged || incoTermsChanged) {
                    quotesToNotify.add(q);
                }
            } else if (Trigger.isUpdate) {
                // For updates, check changes from previous values
                Boolean paymentTermChanged = q.Payment_Term__c != oldQ.Payment_Term__c;
                Boolean incoTermsChanged = q.Inco_Terms__c != oldQ.Inco_Terms__c;
                
                if (paymentTermChanged || incoTermsChanged) {
                    quotesToNotify.add(q);
                }
                
                // Check for Payment Terms approval status changes
                Boolean paymentApprovalChanged = q.Credit_Approval_Status__c != oldQ.Credit_Approval_Status__c &&
                                               (q.Credit_Approval_Status__c == 'Approved' || q.Credit_Approval_Status__c == 'Rejected');
                
                // Check for Inco Terms approval status changes  
                Boolean incoApprovalChanged = q.Inco_Terms_Approval_Status__c != oldQ.Inco_Terms_Approval_Status__c &&
                                            (q.Inco_Terms_Approval_Status__c == 'Approved' || q.Inco_Terms_Approval_Status__c == 'Rejected');
                
                // Send approval emails
                if (paymentApprovalChanged) {
                    QuoteTriggerHandler.sendPaymentTermsApprovalEmails(new List<Quote>{q}, Trigger.oldMap);
                }
                
                if (incoApprovalChanged) {
                    QuoteTriggerHandler.sendIncoTermsApprovalEmails(new List<Quote>{q}, Trigger.oldMap);
                }
            }
        }

        // Send term change notifications
        if (!quotesToNotify.isEmpty()) {
            if (!Test.isRunningTest()) {
                QuoteTriggerHandler.sendPaymentTermChangeEmails(quotesToNotify);
            }
        }
    }
}