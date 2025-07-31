trigger AddressInformationTrigger on Address_Information__c (before insert, before update) {
    if (Trigger.isBefore) {
        AddressInformationHelper.updateAddressFields(Trigger.new);
    }
}