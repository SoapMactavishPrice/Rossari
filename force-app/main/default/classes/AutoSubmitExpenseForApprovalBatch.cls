public with sharing class AutoSubmitExpenseForApprovalBatch implements Database.Batchable<sObject>, Database.Stateful {
    // You can change this to any status values appropriate for your org
    private final List<String> processableStatuses = new List<String>{ 'Draft' };

    public AutoSubmitExpenseForApprovalBatch() { }

    // Start: pick candidate Expense__c records (RBL + Draft)
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String qry = 'SELECT Id, Name, Status__c, OwnerId, RecordType.DeveloperName ' +
                     'FROM Expense__c ' +
                     'WHERE RecordType.DeveloperName = \'RBL\' ' +
                     'AND Status__c IN :processableStatuses';
        return Database.getQueryLocator(qry);
    }

    // Execute: for each chunk, avoid duplicates and submit in bulk
    public void execute(Database.BatchableContext bc, List<Expense__c> scope) {
        if (scope == null || scope.isEmpty()) return;

        // collect ids
        Set<Id> expenseIds = new Set<Id>();
        for (Expense__c e : scope) expenseIds.add(e.Id);

        // Find ProcessInstance records already submitted and still pending (avoid double submit)
        // ProcessInstance.Status may vary by org; we look for any non-completed instances with the expense as target.
        // We'll treat 'Pending' or 'Started' as active — adjust logic if you have custom statuses.
        Map<Id, Boolean> hasActiveProcess = new Map<Id, Boolean>();
        for (AggregateResult ar : [
            SELECT TargetObjectId tId, COUNT(Id) cnt
            FROM ProcessInstance
            WHERE TargetObjectId IN :expenseIds
            AND (Status = 'Pending' OR Status = 'Started' OR Status = 'InProgress' OR Status = 'New')
            GROUP BY TargetObjectId
        ]) {
            Id tId = (Id) ar.get('tId');
            hasActiveProcess.put(tId, true);
        }

        // Build list of expenses to submit (exclude those having active process)
        List<Expense__c> toSubmitExpenses = new List<Expense__c>();
        for (Expense__c e : scope) {
            if (!hasActiveProcess.containsKey(e.Id)) {
                toSubmitExpenses.add(e);
            }
        }

        if (toSubmitExpenses.isEmpty()) return;

        // Prepare ProcessSubmitRequests
        List<Approval.ProcessSubmitRequest> submitRequests = new List<Approval.ProcessSubmitRequest>();
        Map<String, Id> requestKeyToExpenseId = new Map<String, Id>(); // map a key to expenseId to map results back

        for (Expense__c exp : toSubmitExpenses) {
            try {
                Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                req.setComments('Auto-submitted by scheduled job');
                req.setObjectId(exp.Id);
                // Optionally set submitter; by default system uses running user (the scheduled user)
                // req.setSubmitterId(UserInfo.getUserId());
                submitRequests.add(req);

                // keep mapping for result handling (use objectId as key)
                requestKeyToExpenseId.put(String.valueOf(exp.Id), exp.Id);
            } catch (Exception ex) {
                // swallow and continue, but log/debug
                System.debug('Error preparing submit request for Expense Id ' + exp.Id + ' : ' + ex.getMessage());
            }
        }

        if (submitRequests.isEmpty()) return;

        // Call Approval.process in bulk
        try {
            List<Approval.ProcessResult> results = Approval.process(submitRequests);

            List<Expense__c> expensesToUpdate = new List<Expense__c>();
            Integer idx = 0;
            for (Approval.ProcessResult r : results) {
                // Approval.process returns results in same order as requests
                Approval.ProcessSubmitRequest matchingReq = (Approval.ProcessSubmitRequest) submitRequests[idx];
                Id expenseId = (Id) requestKeyToExpenseId.get(String.valueOf(matchingReq.getObjectId()));
                idx++;

                if (r.isSuccess()) {
                    // update expense status to indicate submission; adjust string to match your picklist value
                    Expense__c eUpd = new Expense__c(Id = expenseId, Status__c = 'Submitted for Approval');
                    expensesToUpdate.add(eUpd);
                } else {
                    // Log failures
                    System.debug('Approval submit failed for Expense Id ' + expenseId + ': ' + r.getErrors());
                }
            }

            if (!expensesToUpdate.isEmpty()) {
                try {
                    update expensesToUpdate;
                } catch (DmlException dmx) {
                    System.debug('Failed to update status after approval submit: ' + dmx.getMessage());
                }
            }

        } catch (Exception e) {
            // If Approval.process throws for the whole batch, log and allow later scheduled run to retry
            System.debug('Approval.process failed for batch: ' + e.getMessage());
        }
    }

    // Finish: optional logging/notifications
    public void finish(Database.BatchableContext bc) {
        System.debug('AutoSubmitExpenseForApprovalBatch finished at ' + Datetime.now());
    }
}