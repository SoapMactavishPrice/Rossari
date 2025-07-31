trigger UpdateQuoteRevision on QuoteLineItem (after update) {
    Set<Id> quoteIdsToUpdate = new Set<Id>();

    for (QuoteLineItem qli : Trigger.new) {
        QuoteLineItem oldQLI = Trigger.oldMap.get(qli.Id);
        
        // Check if Sales Price or Quantity is changed
        if (qli.Quantity != oldQLI.Quantity || qli.UnitPrice != oldQLI.UnitPrice) {
            if (qli.QuoteId != null) {
                quoteIdsToUpdate.add(qli.QuoteId);
            }
        }
    }

    if (!quoteIdsToUpdate.isEmpty()) {
        List<Quote> quotesToUpdate = [
            SELECT Id, Revision_No__c 
            FROM Quote 
            WHERE Id IN :quoteIdsToUpdate
        ];

        for (Quote q : quotesToUpdate) {
            if (q.Revision_No__c == null) {
                q.Revision_No__c = 1; // Start from 1 if null
            } else {
                q.Revision_No__c += 1; // Increment
            }
        }

        update quotesToUpdate;
    }
}