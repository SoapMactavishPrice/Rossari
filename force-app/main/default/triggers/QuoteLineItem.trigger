trigger QuoteLineItem on QuoteLineItem (after insert) {
    Set<Id> quoteIds = new Set<Id>();

    for (QuoteLineItem qli : Trigger.new) {
        if ((qli.ListPrice == 0 || qli.ListPrice == null) &&
            (qli.UnitPrice == 0 || qli.UnitPrice == null) &&
            qli.QuoteId != null) {
            quoteIds.add(qli.QuoteId);
        }
    }

    // Avoid sending multiple emails for the same quote in a batch
    for (Id quoteId : quoteIds) {
        SendEmail.sendEmailNotificationQuote(quoteId);
    }
}