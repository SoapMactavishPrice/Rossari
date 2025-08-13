trigger SampleRequestLineItemTrigger on Sample_Request_Line_Item__c (after insert, after update) {
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        SampleRequestController.updateParentStatus(Trigger.newMap.keySet());
    }
}