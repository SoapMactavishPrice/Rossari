trigger LeadTrigger on Lead (before insert, before update, after insert, after update) {
    
    // === BEFORE INSERT or UPDATE ===
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            LeadTriggerHandler.updateLeadAddresses(Trigger.new);
            LeadTriggerHandler.setRossariCompany(Trigger.new);
            
            // Rating based on Lead Score
            for (Lead l : Trigger.new) {
                if (l.Lead_Score__c != null) {
                    if (l.Lead_Score__c <= 50) {
                        l.Rating = 'Cold';
                    } else if (l.Lead_Score__c <= 75) {
                        l.Rating = 'Warm';
                    } else {
                        l.Rating = 'Hot';
                    }
                }
            }
        }
        
        if (Trigger.isInsert) {
            LeadTriggerHandler.setDefaultLeadStatus(Trigger.new);
            LeadTriggerHandler.setLeadTypeBasedOnRecordType(Trigger.new);
        }
        
        if (Trigger.isUpdate) {
            Set<Id> convertingLeadIds = new Set<Id>();
            
            for (Lead lead : Trigger.new) {
                Lead oldLead = Trigger.oldMap.get(lead.Id);
                
                // Check if lead is being converted now
                if (lead.IsConverted && !oldLead.IsConverted) {
                    lead.Create_Quote_upon_Conversion__c = true;
                    convertingLeadIds.add(lead.Id);
                    
                }
            }
            
            // Block conversion if no Product_Interested__c records exist
            if (!convertingLeadIds.isEmpty()) {
                Map<Id, Integer> productCountMap = new Map<Id, Integer>();
                
                for (AggregateResult ar : [
                    SELECT Lead__c, COUNT(Id) total
                    FROM Product_Interested__c
                    WHERE Lead__c IN :convertingLeadIds
                    GROUP BY Lead__c
                ]) {
                    productCountMap.put((Id) ar.get('Lead__c'), (Integer) ar.get('total'));
                }
                
                for (Lead lead : Trigger.new) {
                    if (convertingLeadIds.contains(lead.Id) && !productCountMap.containsKey(lead.Id)) {
                        lead.addError('Cannot convert Lead: At least one Product Interested record must be added before conversion.');
                    }
                }
            }
            
        }
    }
    
    // === AFTER INSERT ===
    if (Trigger.isAfter && Trigger.isInsert) {
        LeadTriggerHandler.createContactInformation(Trigger.new);
    }
    
    // === AFTER UPDATE ===
    if (Trigger.isAfter && Trigger.isUpdate) {
        LeadTriggerHandler.handleAfterLeadConvert(Trigger.new, Trigger.oldMap);
        OpportunityTriggerHandler.convertHandler(Trigger.new, Trigger.oldMap);
        LeadTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        LeadTriggerHandler.createAddressInfoFromConvertedLead(Trigger.new, Trigger.oldMap);
        
        // Create Quotes for Converted Leads
        List<Id> convertedLeadIds = new List<Id>();
        for (Lead lead : Trigger.new) {
            Lead oldLead = Trigger.oldMap.get(lead.Id);
            if (lead.IsConverted && !oldLead.IsConverted) {
                convertedLeadIds.add(lead.Id);
                
            }
        }
        
        if (!convertedLeadIds.isEmpty()) {
            LeadTriggerHandler.createQuotesForConvertedLeads(convertedLeadIds);
        }
    }
    
    // === AFTER INSERT or UPDATE ===
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        LeadTriggerHandler.handleFollowUpTask(Trigger.new, Trigger.oldMap);
    }
}