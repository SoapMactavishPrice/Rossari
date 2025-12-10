trigger OpportunityTrigger on Opportunity (before insert, after insert, after update) {

    if (Trigger.isBefore && Trigger.isInsert) {
        OpportunityTriggerHandler.setStandardPricebook(Trigger.new);
    }

    if (Trigger.isAfter && Trigger.isInsert) {
        OpportunityTriggerHandler.markConvertedOpportunitiesFuture(Trigger.newMap.keySet());
        OpportunityTriggerHandler.handleFollowUpTask(Trigger.new, null);
    }

    if (Trigger.isAfter && Trigger.isUpdate) {

        OpportunityTriggerHandler.handleFollowUpTask(Trigger.new, Trigger.oldMap);

        List<OpportunityShare> sharesToInsert = new List<OpportunityShare>();

        for (Opportunity newOpp : Trigger.new) {
            Opportunity oldOpp = Trigger.oldMap.get(newOpp.Id);

            Map<String, Id> newValues = new Map<String, Id>{
                'TDS'  => newOpp.TDS_Approver__c,
                'COA'  => newOpp.COA_Document_Approver__c,
                'MSDS' => newOpp.MSDS_Approver__c,
                'TECH' => newOpp.Technical_Document_Approver__c
            };

            Map<String, Id> oldValues = new Map<String, Id>{
                'TDS'  => oldOpp.TDS_Approver__c,
                'COA'  => oldOpp.COA_Document_Approver__c,
                'MSDS' => oldOpp.MSDS_Approver__c,
                'TECH' => oldOpp.Technical_Document_Approver__c
            };

            for (String key : newValues.keySet()) {

                Id newUser = newValues.get(key);
                Id oldUser = oldValues.get(key);

                if (oldUser == null && newUser != null) {
                    OpportunityShare share = new OpportunityShare();
                    share.OpportunityId = newOpp.Id;
                    share.UserOrGroupId = newUser;
                    share.OpportunityAccessLevel = 'Edit';
                    share.RowCause = Schema.OpportunityShare.RowCause.Manual;
                    sharesToInsert.add(share);
                }
            }
        }

        if (!sharesToInsert.isEmpty()) {
            insert sharesToInsert;
        }
    }
}