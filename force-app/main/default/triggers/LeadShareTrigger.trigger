trigger LeadShareTrigger on Lead (after update) {

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