public class QuoteLineItemTriggerHandler {
    public static Map<Id, Decimal> oldPurchasePriceMap = new Map<Id, Decimal>();
    public static Map<Id, Decimal> oldQuantityMap = new Map<Id, Decimal>();

    public static void updateNetWeight(List<QuoteLineItem> quoteLineItems) {

        List<Id> productsIds = new List<Id>();
        for (QuoteLineItem qli : quoteLineItems) {
            productsIds.add(qli.Product2Id);
        }

        Map<Id, Product2> productMap = new Map<Id, Product2>([SELECT Net_Wt__c FROM Product2 WHERE Id IN :productsIds]);

        for (QuoteLineItem each : quoteLineItems) {
            if (each.Product2Id != null && productMap.get(each.Product2Id).Net_Wt__c != null) {
                each.Net_weight__c = productMap.get(each.Product2Id).Net_Wt__c;
            }
        }
    }

    public static void updateIsSPlessThanLP(List<QuoteLineItem> quoteLineItems, Map<Id, QuoteLineItem> oldMap) {
        Set<Id> pricebookEntryIds = new Set<Id>();
        
        // Collect all PricebookEntryIds
        for (QuoteLineItem qli : quoteLineItems) {
            if (qli.PricebookEntryId != null) {
                pricebookEntryIds.add(qli.PricebookEntryId);
            }
        }
        
        if (pricebookEntryIds.isEmpty()) {
            return;
        }
        
        // Fetch List Price from PricebookEntry
        Map<Id, PricebookEntry> pricebookEntryMap = new Map<Id, PricebookEntry>(
            [SELECT Id, UnitPrice FROM PricebookEntry WHERE Id IN :pricebookEntryIds]
        );
        
        // Update Is_SP_less_than_LP__c based on Sales Price and List Price
        for (QuoteLineItem qli : quoteLineItems) {
            if (qli.PricebookEntryId != null && pricebookEntryMap.containsKey(qli.PricebookEntryId)) {
                Decimal listPrice = pricebookEntryMap.get(qli.PricebookEntryId).UnitPrice;
                qli.Is_SP_less_than_LP__c = (qli.UnitPrice < listPrice);
                
                if (qli.UnitPrice != oldMap.get(qli.Id).UnitPrice) {
                    if (qli.Is_SP_less_than_LP__c) {
                        qli.Approval_Status__c = 'Pending';
                    }
                }
            }
        }
    }

    public static void updateIsSPlessThanLPForInsert(List<QuoteLineItem> quoteLineItems) {
        Set<Id> pricebookEntryIds = new Set<Id>();
        
        // Collect all PricebookEntryIds
        for (QuoteLineItem qli : quoteLineItems) {
            if (qli.PricebookEntryId != null) {
                pricebookEntryIds.add(qli.PricebookEntryId);
            }
        }
        
        if (pricebookEntryIds.isEmpty()) {
            return;
        }
        
        // Fetch List Price from PricebookEntry
        Map<Id, PricebookEntry> pricebookEntryMap = new Map<Id, PricebookEntry>(
            [SELECT Id, UnitPrice FROM PricebookEntry WHERE Id IN :pricebookEntryIds]
        );
        
        // Update Is_SP_less_than_LP__c based on Sales Price and List Price
        for (QuoteLineItem qli : quoteLineItems) {
            if (qli.PricebookEntryId != null && pricebookEntryMap.containsKey(qli.PricebookEntryId)) {
                Decimal listPrice = pricebookEntryMap.get(qli.PricebookEntryId).UnitPrice;
                qli.Is_SP_less_than_LP__c = (qli.UnitPrice < listPrice);

                if (qli.Is_SP_less_than_LP__c) {
                    qli.Approval_Status__c = 'Pending';
                }
            }
        }
    }

    public static void storeOldValues(Map<Id, QuoteLineItem> oldMap) {
        for (QuoteLineItem oli : oldMap.values()) {
            oldPurchasePriceMap.put(oli.Id, oli.UnitPrice);
            oldQuantityMap.put(oli.Id, oli.Quantity);
        }
    }

    // Compare and update changed values
    public static void updatePreviousValues(Map<Id, QuoteLineItem> newMap) {
        List<QuoteLineItem> itemsToUpdate = new List<QuoteLineItem>();

        for (QuoteLineItem oli : newMap.values()) {
            Decimal oldPurchasePrice = oldPurchasePriceMap.get(oli.Id);
            Decimal oldQuantity = oldQuantityMap.get(oli.Id);

            Boolean priceChanged = oldPurchasePrice != null && oldPurchasePrice != oli.UnitPrice;
            Boolean quantityChanged = oldQuantity != null && oldQuantity != oli.Quantity;

            if (priceChanged || quantityChanged) {
                QuoteLineItem oliToUpdate = new QuoteLineItem(Id = oli.Id);

                if (priceChanged) {
                    oliToUpdate.Previous_Sales_Price__c = oldPurchasePrice;
                }

                if (quantityChanged) {
                    oliToUpdate.Previous_Quantity__c = oldQuantity;
                }

                itemsToUpdate.add(oliToUpdate);
            }
        }

        if (!itemsToUpdate.isEmpty()) {
            update itemsToUpdate;
        }
    }
}