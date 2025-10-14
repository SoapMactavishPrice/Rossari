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
            // Query Expense__c records with related line items and record type
            List<Expense__c> expenses = [
                SELECT Id, Name, Date__c, Employee_Name__c, Employee_Name__r.Name,
                       Type_of_Voucher__c, Zonal_Head__c, Zonal_Head__r.Name,
                       Business_HOD__c, Business_HOD__r.Name, Tour__c, Tour__r.Name,
                       Status__c, CreatedDate, RecordType.DeveloperName,
                       Customer_Success_Incharge__c, Customer_Success_Incharge__r.Name,
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
                    wrapper.customerSuccessIncharge = expense.Customer_Success_Incharge__r?.Name;
                    wrapper.tourName = expense.Tour__r?.Name;
                    wrapper.status = expense.Status__c;
                    wrapper.createdDate = expense.CreatedDate;
                    wrapper.recordType = expense.RecordType.DeveloperName;
                    
                    // Determine current approval level based on process steps
                    ProcessInstanceWorkitem workitem = expenseToWorkitemMap.get(expense.Id);
                    if (workitem != null) {
                        List<ProcessInstanceStep> steps = processStepsMap.get(workitem.ProcessInstanceId);
                        wrapper.currentApprovalLevel = determineApprovalLevel(steps, expense);
                        wrapper.currentApprover = getCurrentApprover(steps, expense, wrapper.currentApprovalLevel);
                        wrapper.isPendingWithCurrentUser = (workitem.ActorId == currentUserId);
                    } else {
                        wrapper.currentApprovalLevel = 'Level 1';
                        wrapper.currentApprover = getCurrentApprover(null, expense, 'Level 1');
                        wrapper.isPendingWithCurrentUser = isPendingWithCurrentUser(expense, currentUserId, 'Level 1');
                    }
                    
                    // Calculate total amount
                    wrapper.totalAmount = calculateTotalAmount(expense.Expense_Line_Items__r);
                    
                    // Add line items
                    wrapper.lineItems = new List<ExpenseLineItemWrapper>();
                    for (Expense_Line_Item__c lineItem : expense.Expense_Line_Items__r) {
                        ExpenseLineItemWrapper lineWrapper = new ExpenseLineItemWrapper();
                        lineWrapper.lineItemId = lineItem.Id;
                        lineWrapper.typeOfExpense = lineItem.Type_of_Expense__r?.Name;
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
        
        String recordType = expense.RecordType.DeveloperName;
        
        // Check Level 1 approvers based on record type
        if (recordType == 'RBL') {
            // For RBL - Zonal Head is Level 1 approver
            if (expense.Zonal_Head__c == currentUserId) {
                if (workitem != null && workitem.ActorId == currentUserId) {
                    return true; // Approval is pending with this Zonal Head
                }
                // Also show if it's Level 1 approval and no workitem yet (initial state)
                if (workitem == null) {
                    return true;
                }
            }
        } else if (recordType == 'Unitop_Tristar') {
            // For Unitop/Tristar - Customer Success Incharge is Level 1 approver
            if (expense.Customer_Success_Incharge__c == currentUserId) {
                if (workitem != null && workitem.ActorId == currentUserId) {
                    return true; // Approval is pending with this Customer Success Incharge
                }
                // Also show if it's Level 1 approval and no workitem yet (initial state)
                if (workitem == null) {
                    return true;
                }
            }
        }
        
        // Check Level 2 approver (Business HOD - same for both record types)
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
        String recordType = expense.RecordType.DeveloperName;
        
        if (approvalLevel == 'Level 1') {
            if (recordType == 'RBL') {
                return expense.Zonal_Head__r?.Name;
            } else if (recordType == 'Unitop_Tristar') {
                return expense.Customer_Success_Incharge__r?.Name;
            }
        } else if (approvalLevel == 'Level 2') {
            return expense.Business_HOD__r?.Name; // Same for both record types
        }
        return 'Unknown';
    }
    
    private static Boolean isPendingWithCurrentUser(Expense__c expense, Id currentUserId, String approvalLevel) {
        String recordType = expense.RecordType.DeveloperName;
        
        if (approvalLevel == 'Level 1') {
            if (recordType == 'RBL') {
                return (expense.Zonal_Head__c == currentUserId);
            } else if (recordType == 'Unitop_Tristar') {
                return (expense.Customer_Success_Incharge__c == currentUserId);
            }
        } else if (approvalLevel == 'Level 2') {
            return (expense.Business_HOD__c == currentUserId);
        }
        return false;
    }
    
    private static Decimal calculateTotalAmount(List<Expense_Line_Item__c> lineItems) {
        Decimal total = 0;
        for (Expense_Line_Item__c lineItem : lineItems) {
            if (lineItem.Amount_Claimed__c != null) {
                total += lineItem.Amount_Claimed__c;
            }
        }
        return total;
    }
    
    @AuraEnabled
    public static String submitApproval(String expenseId, String action, String comments) {
        try {
            // Step 1: Fetch expense with record type information
            Expense__c expense = [
                SELECT Id, Name, Status__c, Owner.Email, Owner.Name,
                Zonal_Head__c, Zonal_Head__r.Email, Zonal_Head__r.Name,
                Business_HOD__c, Business_HOD__r.Email, Business_HOD__r.Name,
                Customer_Success_Incharge__c, Customer_Success_Incharge__r.Email, Customer_Success_Incharge__r.Name,
                Date__c, Type_of_Voucher__c, Tour__r.Name, RecordType.DeveloperName,
                Employee_Name__r.Name, Division__c, Zone__c
                FROM Expense__c WHERE Id = :expenseId LIMIT 1
            ];

            // Step 2: Handle Approve/Reject actions
            List<ProcessInstanceWorkitem> workItems = [
                SELECT Id, ProcessInstanceId, ActorId, ProcessInstance.TargetObjectId
                FROM ProcessInstanceWorkitem 
                WHERE ProcessInstance.TargetObjectId = :expenseId
                LIMIT 1
            ];

            if (workItems.isEmpty()) {
                throw new AuraHandledException('No pending approval found for this expense.');
            }

            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setWorkitemId(workItems[0].Id);
            req.setAction(action); // 'Approve' or 'Reject'
            req.setComments(comments);

            Approval.ProcessResult result = Approval.process(req);

            // Step 3: Update Status__c based on approver and record type
            Id actorId = workItems[0].ActorId;
            String recordType = expense.RecordType.DeveloperName;

            if (action == 'Approve') {
                if (recordType == 'RBL') {
                    if (actorId == expense.Zonal_Head__c) {
                        expense.Status__c = 'Approved by Zonal Head';
                        // Send decision email to owner and CC Zonal Head
                        ExpenseApprovalEmailHandler.sendDecisionEmail(expense, action, expense.Owner.Email, expense.Zonal_Head__r.Email, comments);
                        // Notify HOD next
                        ExpenseApprovalEmailHandler.sendEscalationToHOD(expense);
                    } else if (actorId == expense.Business_HOD__c) {
                        expense.Status__c = 'Approved by Business HOD';
                        ExpenseApprovalEmailHandler.sendDecisionEmail(expense, action, expense.Owner.Email, expense.Business_HOD__r.Email, comments);
                    }
                } else if (recordType == 'Unitop_Tristar') {
                    if (actorId == expense.Customer_Success_Incharge__c) {
                        expense.Status__c = 'Approved by Customer Success Incharge';
                        // Send decision email to owner and CC Customer Success Incharge
                        ExpenseApprovalEmailHandler.sendDecisionEmail(expense, action, expense.Owner.Email, expense.Customer_Success_Incharge__r.Email, comments);
                        // Notify HOD next - use specific method for CSI to HOD escalation
                        ExpenseApprovalEmailHandler.sendEscalationFromCSIToHOD(expense);
                    } else if (actorId == expense.Business_HOD__c) {
                        expense.Status__c = 'Approved by Business HOD';
                        ExpenseApprovalEmailHandler.sendDecisionEmail(expense, action, expense.Owner.Email, expense.Business_HOD__r.Email, comments);
                    }
                }
            } else if (action == 'Reject') {
                if (recordType == 'RBL') {
                    if (actorId == expense.Zonal_Head__c) {
                        expense.Status__c = 'Rejected by Zonal Head';
                        ExpenseApprovalEmailHandler.sendDecisionEmail(expense, action, expense.Owner.Email, expense.Zonal_Head__r.Email, comments);
                    } else if (actorId == expense.Business_HOD__c) {
                        expense.Status__c = 'Rejected by Business HOD';
                        ExpenseApprovalEmailHandler.sendDecisionEmail(expense, action, expense.Owner.Email, expense.Business_HOD__r.Email, comments);
                    }
                } else if (recordType == 'Unitop_Tristar') {
                    if (actorId == expense.Customer_Success_Incharge__c) {
                        expense.Status__c = 'Rejected by Customer Success Incharge';
                        ExpenseApprovalEmailHandler.sendDecisionEmail(expense, action, expense.Owner.Email, expense.Customer_Success_Incharge__r.Email, comments);
                    } else if (actorId == expense.Business_HOD__c) {
                        expense.Status__c = 'Rejected by Business HOD';
                        ExpenseApprovalEmailHandler.sendDecisionEmail(expense, action, expense.Owner.Email, expense.Business_HOD__r.Email, comments);
                    }
                }
            }

            update expense;
            return 'Success';

        } catch (Exception e) {
            system.debug('Error submitting: ' + e.getMessage() + e.getLineNumber());
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
        @AuraEnabled public String customerSuccessIncharge { get; set; }
        @AuraEnabled public Decimal totalAmount { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public Datetime createdDate { get; set; }
        @AuraEnabled public String currentApprovalLevel { get; set; }
        @AuraEnabled public String currentApprover { get; set; }
        @AuraEnabled public Boolean isPendingWithCurrentUser { get; set; }
        @AuraEnabled public Boolean isEmployeeUser { get; set; }
        @AuraEnabled public String recordType { get; set; }
        @AuraEnabled public List<ExpenseLineItemWrapper> lineItems { get; set; }
    }
    
    public class ExpenseLineItemWrapper {
        @AuraEnabled public String lineItemId { get; set; }
        @AuraEnabled public String typeOfExpense { get; set; }
        @AuraEnabled public Decimal amountClaimed { get; set; }
        @AuraEnabled public String description { get; set; }
    }
}