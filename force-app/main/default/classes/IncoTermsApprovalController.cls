public with sharing class IncoTermsApprovalController {
    
    @AuraEnabled(cacheable=true)
    public static List<Quote> getQuotesWithChangedIncoTerms(Id currentUserId) {
        // Quotes owned by the current user
        List<Quote> ownedQuotes = [
            SELECT Id, Name, Inco_Terms__c, Previous_Inco_Terms__c, QuoteNumber,
            Payment_Term__r.Name, Previous_Payment_Terms__r.Name, Account.Name,
            HOD_of_Sales_Department__c, HOD_of_Sales_Department__r.Name, HOD_of_Sales_Department__r.Email,
            Inco_Remark__c, Inco_Terms_Approval_Status__c, OwnerId, Owner.Name
            FROM Quote
            WHERE Inco_Terms__c != null
            AND Previous_Inco_Terms__c != null
            AND Inco_Terms_Approval_Status__c != 'Approved'
            AND OwnerId = :currentUserId
        ];
        
        // Quotes where current user is HOD
        List<Quote> hodQuotes = [
            SELECT Id, Name, Inco_Terms__c, Previous_Inco_Terms__c, QuoteNumber,
            Payment_Term__r.Name, Previous_Payment_Terms__r.Name, Account.Name,
            HOD_of_Sales_Department__c, HOD_of_Sales_Department__r.Name, HOD_of_Sales_Department__r.Email,
            Inco_Remark__c, Inco_Terms_Approval_Status__c, OwnerId, Owner.Name
            FROM Quote
            WHERE Inco_Terms__c != null
            AND Previous_Inco_Terms__c != null
            AND Inco_Terms_Approval_Status__c != 'Approved'
            AND HOD_of_Sales_Department__c = :currentUserId
        ];
        
        // Combine and remove duplicates
        Map<Id, Quote> quoteMap = new Map<Id, Quote>();
        for (Quote q : ownedQuotes) {
            if (q.Inco_Terms__c != q.Previous_Inco_Terms__c) {
                quoteMap.put(q.Id, q);
            }
        }
        for (Quote q : hodQuotes) {
            if (q.Inco_Terms__c != q.Previous_Inco_Terms__c) {
                quoteMap.put(q.Id, q);
            }
        }
        
        return quoteMap.values();
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