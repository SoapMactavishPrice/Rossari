trigger SampleFeedbackTrigger on Sample_Feedback__c (before insert) {
    
    Set<Id> sampleOutIds = new Set<Id>();
    
    
    for (Sample_Feedback__c feedback : Trigger.new) {
        if (feedback.Sample_Request__c == null && feedback.Sample_Out__c != null) {
            sampleOutIds.add(feedback.Sample_Out__c);
        }
    }
    
    
    Map<Id, Sample_Out__c> sampleOutMap = new Map<Id, Sample_Out__c>(
        [SELECT Id, Sample_Request__c FROM Sample_Out__c WHERE Id IN :sampleOutIds]
    );
    
    
    for (Sample_Feedback__c feedback : Trigger.new) {
        if (feedback.Sample_Request__c == null && feedback.Sample_Out__c != null) {
            Sample_Out__c relatedOut = sampleOutMap.get(feedback.Sample_Out__c);
            if (relatedOut != null) {
                feedback.Sample_Request__c = relatedOut.Sample_Request__c;
            }
        }
    }
}