public class ContactTriggerHandler {
    public static void updateContactAddresses(List<Contact> newContacts) {
        Set<Id> pinCodeIds = new Set<Id>();
        for (Contact contact : newContacts) {
            if (contact.Pin_Code__c != null) {
                pinCodeIds.add(contact.Pin_Code__c);
            }
        }

        if (pinCodeIds.isEmpty()) return;

        Map<Id, Pin_Code__c> pinMap = new Map<Id, Pin_Code__c>([
            SELECT Id, City__c,
                   City__r.State__c,
                   City__r.State__r.Country__c,
                   City__r.State__r.Zone__c,
                   City__r.State__r.Country__r.Region__c
            FROM Pin_Code__c
            WHERE Id IN :pinCodeIds
        ]);

        for (Contact contact : newContacts) {
            if (contact.Pin_Code__c != null && pinMap.containsKey(contact.Pin_Code__c)) {
                Pin_Code__c pin = pinMap.get(contact.Pin_Code__c);
                contact.City__c    = pin.City__c;
                contact.State__c   = pin.City__r.State__c;
                contact.Country__c = pin.City__r.State__r.Country__c;
                contact.Zone__c    = pin.City__r.State__r.Zone__c;
                contact.Region__c  = pin.City__r.State__r.Country__r.Region__c;
            }
        }
    }
}