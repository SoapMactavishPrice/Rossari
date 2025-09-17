public with sharing class CreditApprovalController {
    @AuraEnabled(cacheable=true)
    public static List<Quote> getQuotesWithChangedPaymentTerms() {
        List<Quote> allQuotes = [
            SELECT Id, Name, Payment_Term__c, Previous_Payment_Terms__c, QuoteNumber,
            Payment_Term__r.Name, Previous_Payment_Terms__r.Name, Account.Name,
            HOD_of_Sales_Department__r.Name, HOD_of_Sales_Department__r.Email,
            Payment_Remark__c, Credit_Approval_Status__c, Owner.Name
            FROM Quote
            WHERE Payment_Term__c != null
            AND Previous_Payment_Terms__c != null
            AND Credit_Approval_Status__c != 'Approved'
        ];
        
        List<Quote> changedQuotes = new List<Quote>();
        for (Quote q : allQuotes) {
            if (q.Payment_Term__c != q.Previous_Payment_Terms__c) {
                changedQuotes.add(q);
            }
        }
        
        return changedQuotes;
    }
    
    
    @AuraEnabled
    public static String updateCreditApproval(List<Quote> updatedQuotes) {
        List<Quote> toUpdate = new List<Quote>();
        for (Quote q : updatedQuotes) {
            toUpdate.add(new Quote(
                Id = q.Id,
                Credit_Approval_Status__c = q.Credit_Approval_Status__c,
                Payment_Remark__c = q.Payment_Remark__c
            ));
        }
        
        update toUpdate;
                
        return 'Success';
    }
}