trigger ContactTrigger on Contact (before insert, before update) {
    if (Trigger.isBefore) {
        ContactTriggerHandler.updateContactAddresses(Trigger.new);
    }
}