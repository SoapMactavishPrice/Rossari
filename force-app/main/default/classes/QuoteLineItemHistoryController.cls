public with sharing class QuoteLineItemHistoryController {

    @AuraEnabled(cacheable=true)
    public static List<QuoteLineItemHistoryWrapper> getQuoteLineItemHistory(Id quoteId) {
        List<QuoteLineItemHistoryWrapper> historyList = new List<QuoteLineItemHistoryWrapper>();

        // Fetch all Quote Line Items for the Quote
        List<QuoteLineItem> qliList = [
            SELECT Id, Product2.Name 
            FROM QuoteLineItem 
            WHERE QuoteId = :quoteId
        ];

        if (qliList.isEmpty()) return historyList;

        // Map to hold QLI Id to Product Name
        Map<Id, String> qliIdToProductName = new Map<Id, String>();
        for (QuoteLineItem qli : qliList) {
            qliIdToProductName.put(qli.Id, qli.Product2.Name);
        }

        List<Id> qliIds = new List<Id>(qliIdToProductName.keySet());

        // Fetch history for all Quote Line Items
        List<QuoteLineItemHistory> histories = [
            SELECT Id, Field, OldValue, NewValue, CreatedDate, QuoteLineItemId
            FROM QuoteLineItemHistory
            WHERE Field IN ('Quantity', 'UnitPrice') AND QuoteLineItemId IN :qliIds
            ORDER BY CreatedDate DESC
        ];

        // Now add all history entries individually
        for (QuoteLineItemHistory history : histories) {
            String productName = qliIdToProductName.get(history.QuoteLineItemId);

            historyList.add(new QuoteLineItemHistoryWrapper(
                history.Id,
                history.QuoteLineItemId,
                history.Field,
                String.valueOf(history.OldValue),
                String.valueOf(history.NewValue),
                history.CreatedDate,
                productName
            ));
        }

        return historyList;
    }

    // Wrapper class to return to LWC or Aura
    public class QuoteLineItemHistoryWrapper {
        @AuraEnabled public Id id;
        @AuraEnabled public Id quoteLineItemId;
        @AuraEnabled public String field;
        @AuraEnabled public String oldValue;
        @AuraEnabled public String newValue;
        @AuraEnabled public DateTime modifiedDate;
        @AuraEnabled public String productName;

        public QuoteLineItemHistoryWrapper(
            Id id,
            Id quoteLineItemId,
            String field,
            String oldValue,
            String newValue,
            DateTime modifiedDate,
            String productName
        ) {
            this.id = id;
            this.quoteLineItemId = quoteLineItemId;
            this.field = field;
            this.oldValue = oldValue;
            this.newValue = newValue;
            this.modifiedDate = modifiedDate;
            this.productName = productName;
        }
    }
}