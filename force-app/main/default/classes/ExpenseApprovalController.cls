public with sharing class ExpenseApprovalController {
    
    @AuraEnabled(cacheable=true)
    public static List<ExpenseWrapper> getPendingExpenseApprovals() {
        List<ExpenseWrapper> expenseWrappers = new List<ExpenseWrapper>();
        
        // Get current user ID
        Id currentUserId = UserInfo.getUserId();
        
        // Get ProcessInstanceWorkitems for Expense__c
        List<ProcessInstanceWorkitem> pendingApprovals = [
            SELECT Id, ProcessInstanceId, ProcessInstance.TargetObjectId,
                   ProcessInstance.SubmittedById, ProcessInstance.SubmittedBy.Name,
                   ProcessInstance.Status, ProcessInstance.CreatedDate,
                   ActorId, Actor.Name
            FROM ProcessInstanceWorkitem 
            WHERE ProcessInstance.TargetObject.Type = 'Expense__c'
            ORDER BY CreatedDate DESC
        ];
        
        Set<Id> expenseIds = new Set<Id>();
        Set<Id> processInstanceIds = new Set<Id>();
        Map<Id, ProcessInstanceWorkitem> expenseToWorkitemMap = new Map<Id, ProcessInstanceWorkitem>();
        
        for (ProcessInstanceWorkitem approval : pendingApprovals) {
            expenseIds.add(approval.ProcessInstance.TargetObjectId);
            processInstanceIds.add(approval.ProcessInstanceId);
            expenseToWorkitemMap.put(approval.ProcessInstance.TargetObjectId, approval);
        }
        
        // Get ProcessInstanceSteps separately
        Map<Id, List<ProcessInstanceStep>> processStepsMap = new Map<Id, List<ProcessInstanceStep>>();
        if (!processInstanceIds.isEmpty()) {
            List<ProcessInstanceStep> steps = [
                SELECT Id, ProcessInstanceId, StepStatus, OriginalActorId, 
                       OriginalActor.Name, ActorId, Actor.Name, Comments,
                       CreatedDate, SystemModstamp
                FROM ProcessInstanceStep 
                WHERE ProcessInstanceId IN :processInstanceIds
                ORDER BY ProcessInstanceId, CreatedDate
            ];
            
            for (ProcessInstanceStep step : steps) {
                if (!processStepsMap.containsKey(step.ProcessInstanceId)) {
                    processStepsMap.put(step.ProcessInstanceId, new List<ProcessInstanceStep>());
                }
                processStepsMap.get(step.ProcessInstanceId).add(step);
            }
        }
        
        if (!expenseIds.isEmpty()) {
            // Query Expense__c records with related line items
            List<Expense__c> expenses = [
                SELECT Id, Name, Date__c, Employee_Name__c, Employee_Name__r.Name,
                       Type_of_Voucher__c, Zonal_Head__c, Zonal_Head__r.Name,
                       Business_HOD__c, Business_HOD__r.Name, Tour__c, Tour__r.Name,
                       Status__c, CreatedDate,
                       (SELECT Id, Name, Type_of_Expense__c, Type_of_Expense__r.Name, Amount_Claimed__c,
                               Description__c, Expense__c, Mode_of_Transport__c, From_Location__c, To_Location__c
                        FROM Expense_Line_Items__r 
                        ORDER BY CreatedDate)
                FROM Expense__c 
                WHERE Id IN :expenseIds
                ORDER BY CreatedDate DESC
            ];
            
            // Create wrapper objects with user-based filtering
            for (Expense__c expense : expenses) {
                // Check if current user should see this approval
                if (shouldUserSeeApproval(expense, currentUserId, expenseToWorkitemMap.get(expense.Id))) {
                    ExpenseWrapper wrapper = new ExpenseWrapper();
                    wrapper.expenseId = expense.Id;
                    wrapper.expenseName = expense.Name;
                    wrapper.expenseDate = expense.Date__c;
                    wrapper.employeeName = expense.Employee_Name__r?.Name;
                    wrapper.isEmployeeUser = (expense.Employee_Name__c == currentUserId);
                    wrapper.typeOfVoucher = expense.Type_of_Voucher__c;
                    wrapper.zonalHead = expense.Zonal_Head__r?.Name;
                    wrapper.businessHOD = expense.Business_HOD__r?.Name;
                    wrapper.tourName = expense.Tour__r?.Name;
                    wrapper.status = expense.Status__c;
                    wrapper.createdDate = expense.CreatedDate;
                    
                    // Determine current approval level based on process steps
                    ProcessInstanceWorkitem workitem = expenseToWorkitemMap.get(expense.Id);
                    if (workitem != null) {
                        List<ProcessInstanceStep> steps = processStepsMap.get(workitem.ProcessInstanceId);
                        wrapper.currentApprovalLevel = determineApprovalLevel(steps, expense);
                        wrapper.currentApprover = getCurrentApprover(steps, expense, wrapper.currentApprovalLevel);
                        wrapper.isPendingWithCurrentUser = (workitem.ActorId == currentUserId);
                    } else {
                        wrapper.currentApprovalLevel = 'Level 1';
                        wrapper.currentApprover = expense.Zonal_Head__r?.Name;
                        wrapper.isPendingWithCurrentUser = (expense.Zonal_Head__c == currentUserId);
                    }
                    
                    // Add line items
                    wrapper.lineItems = new List<ExpenseLineItemWrapper>();
                    for (Expense_Line_Item__c lineItem : expense.Expense_Line_Items__r) {
                        ExpenseLineItemWrapper lineWrapper = new ExpenseLineItemWrapper();
                        lineWrapper.lineItemId = lineItem.Id;
                        lineWrapper.typeOfExpense = lineItem.Type_of_Expense__r.Name;
                        lineWrapper.amountClaimed = lineItem.Amount_Claimed__c;
                        
                        // Build description with extra details
                        List<String> details = new List<String>();
                        if (String.isNotBlank(lineItem.Description__c)) details.add(lineItem.Description__c);
                        if (String.isNotBlank(lineItem.Mode_of_Transport__c)) details.add('Mode: ' + lineItem.Mode_of_Transport__c);
                        if (String.isNotBlank(lineItem.From_Location__c)) details.add('From: ' + lineItem.From_Location__c);
                        if (String.isNotBlank(lineItem.To_Location__c)) details.add('To: ' + lineItem.To_Location__c);
                        
                        lineWrapper.description = String.join(details, ' | ');
                        
                        wrapper.lineItems.add(lineWrapper);
                    }
                    
                    expenseWrappers.add(wrapper);
                }
            }
        }
        
        return expenseWrappers;
    }
    
    // Method to determine if current user should see the approval
    private static Boolean shouldUserSeeApproval(Expense__c expense, Id currentUserId, ProcessInstanceWorkitem workitem) {
        // Employee can always see their own expense approvals
        if (expense.Employee_Name__c == currentUserId) {
            return true;
        }
        
        // Check if user is Zonal Head and approval is pending with them
        if (expense.Zonal_Head__c == currentUserId) {
            if (workitem != null && workitem.ActorId == currentUserId) {
                return true; // Approval is pending with this Zonal Head
            }
            // Also show if it's Level 1 approval and no workitem yet (initial state)
            if (workitem == null) {
                return true;
            }
        }
        
        // Check if user is Business HOD and approval is pending with them
        if (expense.Business_HOD__c == currentUserId) {
            if (workitem != null && workitem.ActorId == currentUserId) {
                return true; // Approval is pending with this Business HOD
            }
        }
        
        // System Administrators or other privileged users can see all (optional)
        // You can add additional logic here for specific profiles or permission sets
        
        return false;
    }
    
    private static String determineApprovalLevel(List<ProcessInstanceStep> steps, Expense__c expense) {
        if (steps == null || steps.isEmpty()) {
            return 'Level 1'; // No steps yet - first approval pending
        }
        
        // Check if any step is approved
        Boolean hasApprovedStep = false;
        for (ProcessInstanceStep step : steps) {
            if (step.StepStatus == 'Approved') {
                hasApprovedStep = true;
            }
        }
        
        // If there are approved steps, we're at level 2
        // If no approved steps, we're at level 1
        return hasApprovedStep ? 'Level 2' : 'Level 1';
    }
    
    private static String getCurrentApprover(List<ProcessInstanceStep> steps, Expense__c expense, String approvalLevel) {
        if (approvalLevel == 'Level 1') {
            return expense.Zonal_Head__r?.Name;
        } else if (approvalLevel == 'Level 2') {
            return expense.Business_HOD__r?.Name;
        }
        return 'Unknown';
    }
    
    @AuraEnabled
    public static String submitApproval(String expenseId, String action, String comments) {
        try {
            // Find the workitem ID for this expense
            List<ProcessInstanceWorkitem> workItems = [
                SELECT Id FROM ProcessInstanceWorkitem 
                WHERE ProcessInstance.TargetObjectId = :expenseId
                LIMIT 1
            ];
            
            if (workItems.isEmpty()) {
                throw new AuraHandledException('No pending approval found for this expense.');
            }
            
            // Create approval request
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setWorkitemId(workItems[0].Id);
            req.setAction(action); // 'Approve' or 'Reject'
            req.setComments(comments);
            
            // Submit approval
            Approval.ProcessResult result = Approval.process(req);
            
            return 'Success';
        } catch (Exception e) {
            throw new AuraHandledException('Error submitting approval: ' + e.getMessage());
        }
    }
    
    // Wrapper classes
    public class ExpenseWrapper {
        @AuraEnabled public String expenseId { get; set; }
        @AuraEnabled public String expenseName { get; set; }
        @AuraEnabled public Date expenseDate { get; set; }
        @AuraEnabled public String employeeName { get; set; }
        @AuraEnabled public String tourName { get; set; }
        @AuraEnabled public String typeOfVoucher { get; set; }
        @AuraEnabled public String zonalHead { get; set; }
        @AuraEnabled public String businessHOD { get; set; }
        @AuraEnabled public Decimal totalAmount { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public Datetime createdDate { get; set; }
        @AuraEnabled public String currentApprovalLevel { get; set; }
        @AuraEnabled public String currentApprover { get; set; }
        @AuraEnabled public Boolean isPendingWithCurrentUser { get; set; }
        @AuraEnabled public Boolean isEmployeeUser { get; set; }
        @AuraEnabled public List<ExpenseLineItemWrapper> lineItems { get; set; }
    }
    
    public class ExpenseLineItemWrapper {
        @AuraEnabled public String lineItemId { get; set; }
        @AuraEnabled public String typeOfExpense { get; set; }
        @AuraEnabled public Decimal amountClaimed { get; set; }
        @AuraEnabled public String description { get; set; }
    }
}