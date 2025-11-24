public with sharing class CreditApprovalController {

    @AuraEnabled(cacheable=true)
    public static List<Quote> getQuotesWithChangedPaymentTerms(Id currentUserId) {

        List<Quote> data = [
            SELECT Id, Name, QuoteNumber,
                   Payment_Term__c, Previous_Payment_Terms__c,
                   Payment_Term__r.Name, Previous_Payment_Terms__r.Name,
                   Account.Name, Payment_Remark__c, Credit_Approval_Status__c,
                   OwnerId, Owner.Name,
                   HOD_of_Sales_Department__c, 
                   HOD_of_Sales_Department__r.Name, 
                   HOD_of_Sales_Department__r.Email,

                   (SELECT Id, Product2.Name, Quantity, ListPrice, UnitPrice, Discount
                    FROM QuoteLineItems)

            FROM Quote
            WHERE Payment_Term__c != null
            AND Previous_Payment_Terms__c != null
            AND Credit_Approval_Status__c != 'Approved'
            AND (OwnerId = :currentUserId OR HOD_of_Sales_Department__c = :currentUserId)
        ];

        // Filter only if changed
        List<Quote> finalList = new List<Quote>();
        for (Quote q : data) {
            if (q.Payment_Term__c != q.Previous_Payment_Terms__c) {
                finalList.add(q);
            }
        }

        return finalList;
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