trigger CustomerOrderScheduleLineItemTrigger on Customer_Order_Schedule_Line_Item__c (after insert, after update, after delete) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            CustomerOrderScheduleLineItemHandler.afterInsert(Trigger.new);
        }

        if (Trigger.isUpdate) {
            CustomerOrderScheduleLineItemHandler.afterUpdate(Trigger.new, Trigger.old);
        }

        if (Trigger.isDelete) {
            CustomerOrderScheduleLineItemHandler.afterDelete(Trigger.old);
        }
    }
}