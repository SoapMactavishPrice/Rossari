trigger LeadShareTrigger on Lead (before update, after update) {

    if (Trigger.isAfter) {

        List<LeadShare> sharesToInsert = new List<LeadShare>();

        for (Lead newLead : Trigger.new) {
            Lead oldLead = Trigger.oldMap.get(newLead.Id);

            Map<String, Id> newValues = new Map<String, Id>{
                'TDS'       => newLead.TDS_Approver__c,
                'COA'       => newLead.COA_Document_Approver__c,
                'MSDS'      => newLead.MSDS_Approver__c,
                'TECH'      => newLead.Technical_Document_Approver__c
            };

            Map<String, Id> oldValues = new Map<String, Id>{
                'TDS'       => oldLead.TDS_Approver__c,
                'COA'       => oldLead.COA_Document_Approver__c,
                'MSDS'      => oldLead.MSDS_Approver__c,
                'TECH'      => oldLead.Technical_Document_Approver__c
            };

            for (String key : newValues.keySet()) {
                Id newUser = newValues.get(key);
                Id oldUser = oldValues.get(key);

                if (oldUser == null && newUser != null) {
                    LeadShare ls = new LeadShare();
                    ls.LeadId = newLead.Id;
                    ls.UserOrGroupId = newUser;
                    ls.LeadAccessLevel = 'Edit'; 
                    ls.RowCause = Schema.LeadShare.RowCause.Manual;
                    sharesToInsert.add(ls);
                }
            }
        }

        if (!sharesToInsert.isEmpty()) {
            insert sharesToInsert;
        }
    }
    
    
    
    
        /* ------------------------  
       NEW: PREVENT LEAD CONVERSION
       ------------------------ */
    if (Trigger.isBefore) {
        Set<Id> convertingLeadIds = new Set<Id>();

        for (Lead ld : Trigger.new) {
            Lead oldLd = Trigger.oldMap.get(ld.Id);

            // Check conversion attempt
            if (!oldLd.IsConverted && ld.IsConverted) {
                convertingLeadIds.add(ld.Id);
            }
        }

        if (!convertingLeadIds.isEmpty()) {
            // Query product interested count
            Map<Id, Integer> countMap = new Map<Id, Integer>();
            for (AggregateResult ag : [
                SELECT Lead__c leadId, COUNT(Id) cnt
                FROM Product_Interested__c
                WHERE Lead__c IN :convertingLeadIds
                GROUP BY Lead__c
            ]) {
                countMap.put((Id)ag.get('leadId'), (Integer)ag.get('cnt'));
            }

            // Add error if no product interested
            for (Id leadId : convertingLeadIds) {
                if (!countMap.containsKey(leadId)) {
                    Trigger.newMap.get(leadId).addError('Please add at least one Product in Product Interested.');
                }
            }
        }
        return; // Stop before-update logic. After-update logic executes separately.
    }
}