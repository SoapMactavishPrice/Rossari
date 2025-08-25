trigger productTrigger on Product2 (before insert) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        ProductTriggerHandler.updateQuoteLineItem(Trigger.new, Trigger.oldMap);
        ProductTriggerHandler.updateProformaInvoiceLineItem(Trigger.new, Trigger.oldMap);
    }
}