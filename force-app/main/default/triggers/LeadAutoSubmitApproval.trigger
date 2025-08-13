trigger LeadAutoSubmitApproval on Lead (after update) {
    List<Approval.ProcessSubmitRequest> requests = new List<Approval.ProcessSubmitRequest>();

    for (Lead l : Trigger.new) {
        Lead oldL = Trigger.oldMap.get(l.Id);

        // Avoid infinite loops - only run when status changes to Submitted
        Boolean level1JustSubmitted = 
            l.COA_Approval_Level_1_Status__c == 'Submitted' &&
            oldL.COA_Approval_Level_1_Status__c != 'Submitted';

        Boolean level2JustSubmitted = 
            l.COA_Approval_Level_2_Status__c == 'Submitted' &&
            oldL.COA_Approval_Level_2_Status__c != 'Submitted';

        // --- Condition 1: Only Level 1 ---
        if (l.COA_Approval_Level_1__c != null &&
            l.COA_Approval_Level_2__c == null &&
            level1JustSubmitted) {

            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setObjectId(l.Id);
            req.setSubmitterId(UserInfo.getUserId());
            requests.add(req);
        }

        // --- Condition 2: Only Level 2 ---
        else if (l.COA_Approval_Level_1__c == null &&
                 l.COA_Approval_Level_2__c != null &&
                 level2JustSubmitted) {

            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setObjectId(l.Id);
            req.setSubmitterId(UserInfo.getUserId());
            requests.add(req);
        }

        // --- Condition 3: Both Levels ---
        else if (l.COA_Approval_Level_1__c != null &&
                 l.COA_Approval_Level_2__c != null &&
                 level1JustSubmitted &&
                 level2JustSubmitted) {

            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setObjectId(l.Id);
            req.setSubmitterId(UserInfo.getUserId());
            requests.add(req);
        }
    }

    if (!requests.isEmpty()) {
        List<Approval.ProcessResult> results = Approval.process(requests);
        System.debug('Approval submission results: ' + results);
    }
}