public with sharing class ProductTriggerHandler {
    public static void updateQuoteLineItem(List<Product2> products, Map<Id, Product2> oldMap) {
        
        Set<Id> updatedProductIds = new Set<Id>();
        for (Product2 prod : products) {
            Product2 oldProd = oldMap.get(prod.Id);
            if (oldProd != null && prod.Net_Wt__c != oldProd.Net_Wt__c) {
                updatedProductIds.add(prod.Id);
            }
        }

        if (updatedProductIds.isEmpty()) {
            return;
        }

        List<QuoteLineItem> qlisToUpdate = [
            SELECT Id, Product2Id, Net_Weight__c
            FROM QuoteLineItem
            WHERE Product2Id IN :updatedProductIds
        ];

        Map<Id, Decimal> productNetWtMap = new Map<Id, Decimal>();
        for (Product2 prod : products) {
            if (updatedProductIds.contains(prod.Id)) {
                productNetWtMap.put(prod.Id, prod.Net_Wt__c);
            }
        }

        for (QuoteLineItem qli : qlisToUpdate) {
            Decimal newNetWt = productNetWtMap.get(qli.Product2Id);
            if (qli.Net_Weight__c != newNetWt) {
                qli.Net_Weight__c = newNetWt;
            }
        }

        if (!qlisToUpdate.isEmpty()) {
            update qlisToUpdate;
        }
    }


    public static void updateProformaInvoiceLineItem(List<Product2> products, Map<Id, Product2> oldMap) {
        
        Set<Id> updatedProductIds = new Set<Id>();
        for (Product2 prod : products) {
            Product2 oldProd = oldMap.get(prod.Id);
            if (oldProd != null && prod.Net_Wt__c != oldProd.Net_Wt__c) {
                updatedProductIds.add(prod.Id);
            }
        }

        if (updatedProductIds.isEmpty()) {
            return;
        }

        List<Proforma_Invoice_Line_Item__c> qlisToUpdate = [
            SELECT Id, Product__c, Net_Weight__c
            FROM Proforma_Invoice_Line_Item__c
            WHERE Product__c IN :updatedProductIds
        ];

        Map<Id, Decimal> productNetWtMap = new Map<Id, Decimal>();
        for (Product2 prod : products) {
            if (updatedProductIds.contains(prod.Id)) {
                productNetWtMap.put(prod.Id, prod.Net_Wt__c);
            }
        }

        for (Proforma_Invoice_Line_Item__c qli : qlisToUpdate) {
            Decimal newNetWt = productNetWtMap.get(qli.Product__c);
            if (qli.Net_Weight__c != newNetWt) {
                qli.Net_Weight__c = newNetWt;
            }
        }

        if (!qlisToUpdate.isEmpty()) {
            update qlisToUpdate;
        }
    }
}