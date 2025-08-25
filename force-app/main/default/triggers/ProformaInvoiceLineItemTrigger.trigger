trigger ProformaInvoiceLineItemTrigger on Proforma_Invoice_Line_Item__c (before insert) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            ProformaInvoiceLineItemTriggerHandler.updateNetWeight(Trigger.new);
        }
    }
}