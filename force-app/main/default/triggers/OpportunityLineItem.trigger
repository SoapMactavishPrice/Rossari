trigger OpportunityLineItem on OpportunityLineItem (after insert) {
    Set<Id> oppIds = new Set<Id>();
    
    for (OpportunityLineItem oli : Trigger.new) {
        if ((oli.ListPrice == 0 || oli.ListPrice == null) && (oli.UnitPrice == 0 || oli.UnitPrice == null)) {
            if (oli.OpportunityId != null) {
                oppIds.add(oli.OpportunityId);
            }
        }
    }

    if (!oppIds.isEmpty()) {
        for (Id oppId : oppIds) {
            SendEmail.sendEmailNotification(oppId);
        }
    }
}