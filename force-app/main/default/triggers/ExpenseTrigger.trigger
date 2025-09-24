trigger ExpenseTrigger on Expense__c (before insert) {
    if (Trigger.isBefore && Trigger.isInsert) {
        ExpenseTriggerHandler.populateExpenseName(Trigger.new);
    }
}