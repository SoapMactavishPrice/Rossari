public class QuoteLineItemTriggerHandler {
    public static Map<Id, Decimal> oldPurchasePriceMap = new Map<Id, Decimal>();
    public static Map<Id, Decimal> oldQuantityMap = new Map<Id, Decimal>();

    // Store old values
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