trigger ProductInterestedTrigger on Product_Interested__c (
    after insert, after update, after delete, after undelete
) {
    Set<Id> leadIds = new Set<Id>();

    if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
        for (Product_Interested__c pi : Trigger.new) {
            if (pi.Lead__c != null) {
                leadIds.add(pi.Lead__c);
            }
        }
    }

    if (Trigger.isUpdate || Trigger.isDelete) {
        for (Product_Interested__c pi : Trigger.old) {
            if (pi.Lead__c != null) {
                leadIds.add(pi.Lead__c);
            }
        }
    }

    if (!leadIds.isEmpty()) {
        ProductInterestedHelper.updateLeadTotalQuantities(leadIds);
        
        
        if (Trigger.isInsert || Trigger.isUndelete) {
            List<Lead> leadsToUpdate = new List<Lead>();
            for (Lead l : [SELECT Id, Status FROM Lead 
                          WHERE Id IN :leadIds AND Status = 'New']) {
                l.Status = 'Working';
                leadsToUpdate.add(l);
            }
            
            if (!leadsToUpdate.isEmpty()) {
                update leadsToUpdate;
            }
        }
    }
    
}