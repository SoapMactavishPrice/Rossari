trigger UpdateQuoteRevision on QuoteLineItem (after update) {
    Set<Id> quoteIdsToUpdate = new Set<Id>();

    for (QuoteLineItem qli : Trigger.new) {
        QuoteLineItem oldQLI = Trigger.oldMap.get(qli.Id);

        if (qli.Quantity != oldQLI.Quantity || qli.UnitPrice != oldQLI.UnitPrice) {
            if (qli.QuoteId != null) {
                quoteIdsToUpdate.add(qli.QuoteId);
            }
        }
    }

    if (!quoteIdsToUpdate.isEmpty()) {
       
        List<Quote> quotesToUpdate = [
            SELECT Id, Revision_No__c, OpportunityId
            FROM Quote
            WHERE Id IN :quoteIdsToUpdate
        ];

        Set<Id> opportunityIdsToUpdate = new Set<Id>();

        for (Quote q : quotesToUpdate) {
            
            if (q.Revision_No__c == null) {
                q.Revision_No__c = 1;
            } else {
                q.Revision_No__c += 1;
            }

            
            q.Revision_Date__c = System.today();

            
            if (q.Revision_No__c > 0 && q.OpportunityId != null) {
                opportunityIdsToUpdate.add(q.OpportunityId);
            }
        }

        update quotesToUpdate;

        
        if (!opportunityIdsToUpdate.isEmpty()) {
            List<Opportunity> opportunitiesToUpdate = [
                SELECT Id, StageName
                FROM Opportunity
                WHERE Id IN :opportunityIdsToUpdate
            ];

            for (Opportunity opp : opportunitiesToUpdate) {
                opp.StageName = 'Negotiation';
            }

            update opportunitiesToUpdate;
        }
    }
}