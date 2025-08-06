trigger TaskTrigger on Task (after insert) {
    Set<Id> leadIds = new Set<Id>();
    
    for (Task t : Trigger.new) {
        
        if (t.WhoId != null && 
            ((String)t.WhoId).startsWith('00Q') && 
            t.TaskSubtype == 'Call') {
            leadIds.add(t.WhoId);
        }
    }
    
    if (!leadIds.isEmpty()) {
        List<Lead> leadsToUpdate = new List<Lead>();
        for (Lead l : [SELECT Id, Status FROM Lead WHERE Id IN :leadIds AND Status = 'New']) {
            l.Status = 'Working';
            leadsToUpdate.add(l);
        }
        
        if (!leadsToUpdate.isEmpty()) {
            update leadsToUpdate;
        }
    }
}