trigger PartialDispatchQtyTrigger on Partial_Disptach_Qty__c (after insert, after update, after delete) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            PartialDispatchQtyTriggerHandler.afterInsert(Trigger.new);
        }

        if (Trigger.isUpdate) {
            PartialDispatchQtyTriggerHandler.afterUpdate(Trigger.new, Trigger.old);
        }

        if (Trigger.isDelete) {
            PartialDispatchQtyTriggerHandler.afterDelete(Trigger.old);
        }
    }
}