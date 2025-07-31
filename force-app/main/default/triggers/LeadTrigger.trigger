trigger LeadTrigger on Lead (before insert, before update, after insert, after update) {
    
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            LeadTriggerHandler.updateLeadAddresses(Trigger.new);
            LeadTriggerHandler.setRossariCompany(Trigger.new);
        }
        
        if (Trigger.isInsert) {
            LeadTriggerHandler.setDefaultLeadStatus(Trigger.new);
            LeadTriggerHandler.setLeadTypeBasedOnRecordType(Trigger.new);
        }
    }

  /*  if (Trigger.isAfter && Trigger.isUpdate) {
        LeadTriggerHandler.handleLeadConversion(Trigger.newMap, Trigger.oldMap);
    }		*/
    
     if (Trigger.isAfter && Trigger.isInsert) {
        LeadTriggerHandler.createContactInformation(Trigger.new);
    }
    
        if (Trigger.isAfter && Trigger.isUpdate) {
        LeadTriggerHandler.handleAfterLeadConvert(Trigger.new, Trigger.oldMap);
        OptyTriggerHandler.convertHandler(trigger.New,Trigger.oldMap);
        LeadTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
    
    
    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            LeadTriggerHandler.handleFollowUpTask(Trigger.new, Trigger.oldMap);
        }
    }
    
    if (Trigger.isAfter && Trigger.isUpdate) {
        // Handle address information creation when lead is converted
        LeadTriggerHandler.createAddressInfoFromConvertedLead(Trigger.new, Trigger.oldMap);
    }
}