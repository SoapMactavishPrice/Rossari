trigger CompanyTrigger on Company__c (before insert, before update) {
    // Call the handler class method to process the address updates
    if (Trigger.isBefore) {
        CompanyTriggerHandler.updateCompanyAddresses(Trigger.new);
    }
}