public with sharing class CustomerOrderScheduleLineItemHandler {
    
    
    public static void afterInsert(List<Customer_Order_Schedule_Line_Item__c> newList) {
        Map<Id, Decimal> mpQty = new Map<Id, Decimal>();

        for (Customer_Order_Schedule_Line_Item__c row : newList) {
            if (row.Order_Scheduling_Line_Item__c != null) {
                mpQty.put(row.Order_Scheduling_Line_Item__c, (mpQty.containsKey(row.Order_Scheduling_Line_Item__c) ? mpQty.get(row.Order_Scheduling_Line_Item__c) : 0) + row.Customer_Scheduled_Quantity__c);
            }
        }

        updateOrderItems(mpQty);
    }

    
    
    public static void afterUpdate(List<Customer_Order_Schedule_Line_Item__c> newList, List<Customer_Order_Schedule_Line_Item__c> oldList) {
        Map<Id, Decimal> mpQty = new Map<Id, Decimal>();

        for (Integer i = 0; i < newList.size(); i++) {
            Customer_Order_Schedule_Line_Item__c newRow = newList[i];
            Customer_Order_Schedule_Line_Item__c oldRow = oldList[i];

            if (newRow.Order_Scheduling_Line_Item__c != null) {
                Decimal diff = (newRow.Customer_Scheduled_Quantity__c != null ? newRow.Customer_Scheduled_Quantity__c : 0) - (oldRow.Customer_Scheduled_Quantity__c != null ? oldRow.Customer_Scheduled_Quantity__c : 0);
                if (diff != 0) {
                    mpQty.put(newRow.Order_Scheduling_Line_Item__c, (mpQty.containsKey(newRow.Order_Scheduling_Line_Item__c) ? mpQty.get(newRow.Order_Scheduling_Line_Item__c) : 0) + diff);
                }
            }
        }

        updateOrderItems(mpQty);
    }

    
    
    public static void afterDelete(List<Customer_Order_Schedule_Line_Item__c> oldList) {
        Map<Id, Decimal> mpQty = new Map<Id, Decimal>();

        for (Customer_Order_Schedule_Line_Item__c row : oldList) {
            if (row.Order_Scheduling_Line_Item__c != null && row.Customer_Scheduled_Quantity__c != null) {
                mpQty.put(row.Order_Scheduling_Line_Item__c, (mpQty.containsKey(row.Order_Scheduling_Line_Item__c) ? mpQty.get(row.Order_Scheduling_Line_Item__c) : 0) - row.Customer_Scheduled_Quantity__c);
            }
        }

        updateOrderItems(mpQty);
    }

    
    
    private static void updateOrderItems(Map<Id, Decimal> mpQty) {
        if (!mpQty.isEmpty()) {
            List<Order_Scheduling_Line_Item_wise__c> oiList = [SELECT Id, Scheduled_Quantity__c FROM Order_Scheduling_Line_Item_wise__c WHERE Id IN :mpQty.keySet()];
            for (Order_Scheduling_Line_Item_wise__c oi : oiList) {
                Decimal newQty = (oi.Scheduled_Quantity__c != null ? oi.Scheduled_Quantity__c : 0) + mpQty.get(oi.Id);
                oi.Scheduled_Quantity__c = newQty;
            }
            update oiList;
        }
    }

}