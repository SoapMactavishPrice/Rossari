public with sharing class IncoTermsApprovalController {

    @AuraEnabled(cacheable=true)
    public static List<Quote> getQuotesWithChangedIncoTerms(Id currentUserId) {
        
        List<Quote> data = [
            SELECT Id, Name, QuoteNumber,
                   Inco_Terms__c, Previous_Inco_Terms__c,
                   Account.Name,
                   Inco_Terms_Approval_Status__c, Inco_Remark__c,
                   OwnerId, Owner.Name,
                   HOD_of_Sales_Department__c,
                   HOD_of_Sales_Department__r.Name,
                   HOD_of_Sales_Department__r.Email,
                   (SELECT Id, Product2.Name, Quantity, ListPrice, UnitPrice, Discount
                    FROM QuoteLineItems)
            FROM Quote
            WHERE Inco_Terms__c != null
              AND Previous_Inco_Terms__c != null
              AND Inco_Terms_Approval_Status__c != 'Approved'
              AND (OwnerId = :currentUserId OR HOD_of_Sales_Department__c = :currentUserId)
        ];

        List<Quote> finalList = new List<Quote>();
        for (Quote q : data) {
            if (q.Inco_Terms__c != q.Previous_Inco_Terms__c) {
                finalList.add(q);
            }
        }
        return finalList;
    }

    @AuraEnabled
    public static String updateIncoApproval(List<Quote> updatedQuotes) {
        List<Quote> toUpdate = new List<Quote>();

        for (Quote q : updatedQuotes) {
            toUpdate.add(new Quote(
                Id = q.Id,
                Inco_Terms_Approval_Status__c = q.Inco_Terms_Approval_Status__c,
                Inco_Remark__c = q.Inco_Remark__c
            ));
        }

        update toUpdate;
        return 'Success';
    }
}