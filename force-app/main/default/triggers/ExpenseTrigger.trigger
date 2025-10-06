trigger ExpenseTrigger on Expense__c (before insert, after update) {
    if (Trigger.isBefore && Trigger.isInsert) {
        ExpenseTriggerHandler.populateExpenseName(Trigger.new);
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        ExpenseTriggerHandler.statusChangeToSubmitted(Trigger.new, Trigger.oldMap);
    }
}