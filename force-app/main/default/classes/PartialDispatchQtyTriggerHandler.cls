public with sharing class PartialDispatchQtyTriggerHandler {
    
    
    public static void afterInsert(List<Partial_Disptach_Qty__c> newList) {
        Map<Id, Decimal> mpQty = new Map<Id, Decimal>();

        for (Partial_Disptach_Qty__c row : newList) {
            if (row.Order_Product__c != null) {
                mpQty.put(row.Order_Product__c, (mpQty.containsKey(row.Order_Product__c) ? mpQty.get(row.Order_Product__c) : 0) + row.Disptach_Qty__c);
            }
        }

        updateOrderItems(mpQty);
    }

    
    
    public static void afterUpdate(List<Partial_Disptach_Qty__c> newList, List<Partial_Disptach_Qty__c> oldList) {
        Map<Id, Decimal> mpQty = new Map<Id, Decimal>();

        for (Integer i = 0; i < newList.size(); i++) {
            Partial_Disptach_Qty__c newRow = newList[i];
            Partial_Disptach_Qty__c oldRow = oldList[i];

            if (newRow.Order_Product__c != null) {
                Decimal diff = (newRow.Disptach_Qty__c != null ? newRow.Disptach_Qty__c : 0) - (oldRow.Disptach_Qty__c != null ? oldRow.Disptach_Qty__c : 0);
                if (diff != 0) {
                    mpQty.put(newRow.Order_Product__c, (mpQty.containsKey(newRow.Order_Product__c) ? mpQty.get(newRow.Order_Product__c) : 0) + diff);
                }
            }
        }

        updateOrderItems(mpQty);
    }

    
    
    public static void afterDelete(List<Partial_Disptach_Qty__c> oldList) {
        Map<Id, Decimal> mpQty = new Map<Id, Decimal>();

        for (Partial_Disptach_Qty__c row : oldList) {
            if (row.Order_Product__c != null && row.Disptach_Qty__c != null) {
                mpQty.put(row.Order_Product__c, (mpQty.containsKey(row.Order_Product__c) ? mpQty.get(row.Order_Product__c) : 0) - row.Disptach_Qty__c);
            }
        }

        updateOrderItems(mpQty);
    }

    
    
    private static void updateOrderItems(Map<Id, Decimal> mpQty) {
        if (!mpQty.isEmpty()) {
            List<OrderItem> oiList = [SELECT Id, Dispatch_Quantity__c FROM OrderItem WHERE Id IN :mpQty.keySet()];
            for (OrderItem oi : oiList) {
                Decimal newQty = (oi.Dispatch_Quantity__c != null ? oi.Dispatch_Quantity__c : 0) + mpQty.get(oi.Id);
                oi.Dispatch_Quantity__c = newQty;
            }
            update oiList;
        }
    }

}