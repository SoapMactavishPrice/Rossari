public with sharing class ProformaInvoiceLineItemTriggerHandler {
    public static void updateNetWeight(List<Proforma_Invoice_Line_Item__c> proformaInvoiceLines) {

        List<Id> productsIds = new List<Id>();
        for (Proforma_Invoice_Line_Item__c qli : proformaInvoiceLines) {
            productsIds.add(qli.Product__c);
        }

        Map<Id, Product2> productMap = new Map<Id, Product2>([SELECT Net_Wt__c FROM Product2 WHERE Id IN :productsIds]);

        for (Proforma_Invoice_Line_Item__c each : proformaInvoiceLines) {
            if (each.Product__c != null && productMap.get(each.Product__c).Net_Wt__c != null) {
                each.Net_weight__c = productMap.get(each.Product__c).Net_Wt__c;
            }
        }
    }
}