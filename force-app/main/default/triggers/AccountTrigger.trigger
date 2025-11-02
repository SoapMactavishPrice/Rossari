trigger AccountTrigger on Account (before insert, before update) {
    AccountTriggerHandler.validateDistributorAccount(Trigger.new);
    AccountTriggerHandler.addSFCustomerSequence(Trigger.new);
}