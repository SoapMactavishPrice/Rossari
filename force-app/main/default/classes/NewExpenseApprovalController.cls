public with sharing class NewExpenseApprovalController {

    /* =======================================================================
       Constants
       ======================================================================= */
    private static final String RT_RBL                = 'RBL';
    private static final String RT_UNITOP_TRISTAR    = 'Unitop_Tristar';

    private static final String STS_APR_ZONAL        = 'Approved by Zonal Head';
    private static final String STS_APR_BUS_HOD      = 'Approved by Business HOD';
    private static final String STS_APR_CSI          = 'Approved by Customer Success Incharge';

    private static final String STS_REJ_ZONAL        = 'Rejected by Zonal Head';
    private static final String STS_REJ_BUS_HOD      = 'Rejected by Business HOD';
    private static final String STS_REJ_CSI          = 'Rejected by Customer Success Incharge';

    /* =======================================================================
       Filter options
       ======================================================================= */

    @AuraEnabled(cacheable=true)
    public static FilterOptionsWrapper getFilterOptions() {
        FilterOptionsWrapper options = new FilterOptionsWrapper();

        // 1) Get all Expense IDs that are in approval
        Set<Id> expenseIdsInApproval = new Set<Id>();
        List<ProcessInstanceWorkitem> pendingWorkItems = [
            SELECT ProcessInstance.TargetObjectId
            FROM ProcessInstanceWorkitem 
            WHERE ProcessInstance.TargetObject.Type = 'Expense__c'
        ];

        for (ProcessInstanceWorkitem wi : pendingWorkItems) {
            if (wi.ProcessInstance.TargetObjectId != null) {
                expenseIdsInApproval.add(wi.ProcessInstance.TargetObjectId);
            }
        }

        // Initialize option lists
        options.userTypeOptions    = new List<Map<String, String>>();
        options.userOptions        = new List<Map<String, Object>>();
        options.voucherTypeOptions = new List<Map<String, String>>();
        options.monthOptions       = new List<Map<String, String>>();

        // Default options
        options.userTypeOptions.add(new Map<String, String>{
            'label' => '-- All User Types --',
            'value' => ''
        });
        options.voucherTypeOptions.add(new Map<String, String>{
            'label' => '-- All Voucher Types --',
            'value' => ''
        });
        options.monthOptions.add(new Map<String, String>{
            'label' => '-- All Months --',
            'value' => ''
        });

        // If no expenses are in approval, we still return month options only
        if (!expenseIdsInApproval.isEmpty()) {

            // 2) User types
            List<AggregateResult> userTypeResults = [
                SELECT Employee_Name__r.User_Type__c userType
                FROM Expense__c
                WHERE Id IN :expenseIdsInApproval
                      AND Employee_Name__r.User_Type__c != null
                GROUP BY Employee_Name__r.User_Type__c
                ORDER BY Employee_Name__r.User_Type__c
            ];

            for (AggregateResult ar : userTypeResults) {
                String userType = (String)ar.get('userType');
                options.userTypeOptions.add(new Map<String, String>{
                    'label' => userType,
                    'value' => userType
                });
            }

            // 3) All unique users (filtered client-side by user type)
            List<AggregateResult> userResults = [
                SELECT Employee_Name__c userId,
                       Employee_Name__r.Name userName,
                       Employee_Name__r.User_Type__c userType
                FROM Expense__c
                WHERE Id IN :expenseIdsInApproval
                      AND Employee_Name__r.Name != null
                GROUP BY Employee_Name__c, Employee_Name__r.Name, Employee_Name__r.User_Type__c
                ORDER BY Employee_Name__r.Name
            ];

            for (AggregateResult ar : userResults) {
                String userId   = (String)ar.get('userId');
                String userName = (String)ar.get('userName');
                String userType = (String)ar.get('userType');

                options.userOptions.add(new Map<String, Object>{
                    'label'    => userName,
                    'value'    => userId,
                    'userName' => userName,
                    'userType' => userType
                });
            }

            // 4) Voucher types
            List<AggregateResult> voucherResults = [
                SELECT Type_of_Voucher__c voucherType
                FROM Expense__c
                WHERE Id IN :expenseIdsInApproval
                      AND Type_of_Voucher__c != null
                GROUP BY Type_of_Voucher__c
                ORDER BY Type_of_Voucher__c
            ];

            for (AggregateResult ar : voucherResults) {
                String voucherType = (String)ar.get('voucherType');
                options.voucherTypeOptions.add(new Map<String, String>{
                    'label' => voucherType,
                    'value' => voucherType
                });
            }
        }

        // 5) Month options for last 12 months
        Date today = Date.today();
        for (Integer i = 0; i < 12; i++) {
            Date referenceDate = today.addMonths(-i);
            Integer year  = referenceDate.year();
            Integer month = referenceDate.month();

            String monthName = getMonthName(month);
            String value     = year + '-' + month;
            String label     = monthName + ' ' + year;

            options.monthOptions.add(new Map<String, String>{
                'label' => label,
                'value' => value
            });
        }

        return options;
    }

    private static String getMonthName(Integer month) {
        Map<Integer, String> monthNames = new Map<Integer, String>{
            1 => 'January',  2 => 'February', 3 => 'March',     4 => 'April',
            5 => 'May',      6 => 'June',     7 => 'July',      8 => 'August',
            9 => 'September',10 => 'October', 11 => 'November', 12 => 'December'
        };
        return monthNames.get(month);
    }

    /* =======================================================================
       Main list API
       ======================================================================= */

    @AuraEnabled(cacheable=true)
    public static List<ExpenseWrapper> getPendingExpenseApprovals() {
        List<ExpenseWrapper> expenseWrappers = new List<ExpenseWrapper>();
        Id currentUserId = UserInfo.getUserId();

        // 1) Pending approvals
        List<ProcessInstanceWorkitem> pendingApprovals = [
            SELECT Id,
                   ProcessInstanceId,
                   ProcessInstance.TargetObjectId,
                   ProcessInstance.SubmittedById,
                   ProcessInstance.SubmittedBy.Name,
                   ProcessInstance.Status,
                   ProcessInstance.CreatedDate,
                   ActorId,
                   Actor.Name
            FROM ProcessInstanceWorkitem 
            WHERE ProcessInstance.TargetObject.Type = 'Expense__c'
            ORDER BY CreatedDate DESC
        ];

        Set<Id> expenseIds         = new Set<Id>();
        Set<Id> processInstanceIds = new Set<Id>();
        Map<Id, ProcessInstanceWorkitem> expenseToWorkitemMap = new Map<Id, ProcessInstanceWorkitem>();

        for (ProcessInstanceWorkitem approval : pendingApprovals) {
            if (approval.ProcessInstance.TargetObjectId != null) {
                Id expId = approval.ProcessInstance.TargetObjectId;
                expenseIds.add(expId);
                processInstanceIds.add(approval.ProcessInstanceId);
                // Latest entry for an Expense will overwrite previous, which is fine for the "current" pending WI
                expenseToWorkitemMap.put(expId, approval);
            }
        }

        // 2) Completed expenses (no pending workitems, but completed statuses)
        Set<String> completedStatusValues = getCompletedStatusValues();
        if (!completedStatusValues.isEmpty()) {
            List<Expense__c> completedExpenses = [
                SELECT Id
                FROM Expense__c 
                WHERE Status__c IN :completedStatusValues
                      AND Id NOT IN :expenseIds
            ];
            for (Expense__c exp : completedExpenses) {
                expenseIds.add(exp.Id);
            }
        }

        // Early exit if nothing to show
        if (expenseIds.isEmpty()) {
            return expenseWrappers;
        }

        // 3) ProcessInstanceSteps in bulk
        Map<Id, List<ProcessInstanceStep>> processStepsMap = new Map<Id, List<ProcessInstanceStep>>();
        if (!processInstanceIds.isEmpty()) {
            List<ProcessInstanceStep> steps = [
                SELECT Id,
                       ProcessInstanceId,
                       StepStatus,
                       OriginalActorId,
                       OriginalActor.Name,
                       ActorId,
                       Actor.Name,
                       Comments,
                       CreatedDate,
                       SystemModstamp
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

        // 4) Fetch Expenses with line items
        List<Expense__c> expenses = [
            SELECT Id, Name, Date__c, Employee_Name__c, Employee_Name__r.Name,
                   Type_of_Voucher__c, Zonal_Head__c, Zonal_Head__r.Name,
                   Business_HOD__c, Business_HOD__r.Name,
                   Customer_Success_Incharge__c, Customer_Success_Incharge__r.Name,
                   Tour__c, Tour__r.Name,
                   Status__c, CreatedDate,
                   RecordType.DeveloperName, Grade__c
                   ,
                   (SELECT Id, Name, Type_of_Expense__c, Type_of_Expense__r.Name, 
                           Mode_of_Transport__c, Daily_Allowance__c, Amount_Claimed__c,
                           Amount_Passed__c, Description__c, Expense__c, Desc__c,
                           From_Location__c, To_Location__c
                    FROM Expense_Line_Items__r 
                    ORDER BY CreatedDate)
            FROM Expense__c 
            WHERE Id IN :expenseIds
            ORDER BY CreatedDate DESC
        ];

        // 5) Collect all line item IDs for bulk file count
        Set<Id> lineItemIds = new Set<Id>();
        for (Expense__c exp : expenses) {
            if (exp.Expense_Line_Items__r != null) {
                for (Expense_Line_Item__c li : exp.Expense_Line_Items__r) {
                    lineItemIds.add(li.Id);
                }
            }
        }

        Map<Id, Integer> lineItemFileCountMap = new Map<Id, Integer>();
        if (!lineItemIds.isEmpty()) {
            List<AggregateResult> fileCountResults = [
                SELECT LinkedEntityId, COUNT(Id) fileCount
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :lineItemIds
                GROUP BY LinkedEntityId
            ];

            for (AggregateResult ar : fileCountResults) {
                lineItemFileCountMap.put(
                    (Id)ar.get('LinkedEntityId'),
                    (Integer)ar.get('fileCount')
                );
            }
        }

        // 6) Build wrappers
        for (Expense__c exp : expenses) {
            ExpenseWrapper wrapper = new ExpenseWrapper();
            wrapper.expenseId               = exp.Id;
            wrapper.expenseName             = exp.Name;
            wrapper.expenseDate             = exp.Date__c;
            wrapper.employeeName            = exp.Employee_Name__r != null ? exp.Employee_Name__r.Name : null;
            wrapper.gradeName               = exp.Grade__c;
            wrapper.isEmployeeUser          = (exp.Employee_Name__c == currentUserId);
            wrapper.typeOfVoucher           = exp.Type_of_Voucher__c;
            wrapper.zonalHead               = exp.Zonal_Head__r != null ? exp.Zonal_Head__r.Name : null;
            wrapper.businessHOD             = exp.Business_HOD__r != null ? exp.Business_HOD__r.Name : null;
            wrapper.customerSuccessIncharge = exp.Customer_Success_Incharge__r != null ? exp.Customer_Success_Incharge__r.Name : null;
            wrapper.tourName                = exp.Tour__r != null ? exp.Tour__r.Name : null;

            wrapper.status      = convertToAbbreviatedStatus(exp.Status__c);
            wrapper.createdDate = exp.CreatedDate;
            wrapper.recordType  = exp.RecordType.DeveloperName;

            ProcessInstanceWorkitem wi = expenseToWorkitemMap.get(exp.Id);
            if (wi != null) {
                List<ProcessInstanceStep> steps = processStepsMap.get(wi.ProcessInstanceId);
                wrapper.currentApprovalLevel     = determineApprovalLevel(steps);
                wrapper.currentApprover          = getCurrentApprover(steps, exp, wrapper.currentApprovalLevel);
                wrapper.isPendingWithCurrentUser = (wi.ActorId == currentUserId);
                wrapper.canEditAmountPassed      = canUserEditAmountPassed(exp, currentUserId, wrapper.currentApprovalLevel, wi);
            } else {
                wrapper.currentApprovalLevel     = 'Completed';
                wrapper.currentApprover          = 'Completed';
                wrapper.isPendingWithCurrentUser = false;
                wrapper.canEditAmountPassed      = false;
            }

            wrapper.totalAmount       = calculateTotalAmount(exp.Expense_Line_Items__r);
            wrapper.totalAmountPassed = calculateTotalAmountPassed(exp.Expense_Line_Items__r);

            wrapper.lineItems = new List<ExpenseLineItemWrapper>();
            if (exp.Expense_Line_Items__r != null) {
                for (Expense_Line_Item__c li : exp.Expense_Line_Items__r) {
                    ExpenseLineItemWrapper liWrap = new ExpenseLineItemWrapper();
                    liWrap.lineItemId     = li.Id;
                    liWrap.typeOfExpense  = (li.Type_of_Expense__r != null ? li.Type_of_Expense__r.Name : null);
                    liWrap.modeOfTransport= li.Mode_of_Transport__c;
                    liWrap.dailyAllowance = li.Daily_Allowance__c;
                    liWrap.amountClaimed  = li.Amount_Claimed__c;
                    liWrap.amountPassed   = li.Amount_Passed__c;
                    liWrap.description    = li.Desc__c;

                    Integer fileCount     = lineItemFileCountMap.get(li.Id);
                    liWrap.hasFiles       = (fileCount != null && fileCount > 0);

                    wrapper.lineItems.add(liWrap);
                }
            }

            expenseWrappers.add(wrapper);
        }

        return expenseWrappers;
    }

    private static Set<String> getCompletedStatusValues() {
        return new Set<String>{
            STS_APR_CSI, STS_APR_BUS_HOD, STS_APR_ZONAL,
            STS_REJ_CSI, STS_REJ_BUS_HOD, STS_REJ_ZONAL
        };
    }

    // Helper: abbreviated status text
    private static String convertToAbbreviatedStatus(String status) {
        if (status == null) return null;

        if (status.contains(STS_APR_CSI))       return 'Apr. by CSI';
        if (status.contains(STS_APR_BUS_HOD))   return 'Apr. by Bus. HOD';
        if (status.contains(STS_APR_ZONAL))     return 'Apr. by Zonal Head';
        if (status.contains(STS_REJ_CSI))       return 'Rej. by CSI';
        if (status.contains(STS_REJ_BUS_HOD))   return 'Rej. by Bus. HOD';
        if (status.contains(STS_REJ_ZONAL))     return 'Rej. by Zonal Head';

        return status;
    }

    private static Boolean canUserEditAmountPassed(
        Expense__c expense,
        Id currentUserId,
        String approvalLevel,
        ProcessInstanceWorkitem workitem
    ) {
        if (workitem == null || workitem.ActorId != currentUserId) {
            return false;
        }
        return (approvalLevel == 'Level 1' || approvalLevel == 'Level 2');
    }

    private static Decimal calculateTotalAmountPassed(List<Expense_Line_Item__c> lineItems) {
        Decimal total = 0;
        if (lineItems == null) return total;

        for (Expense_Line_Item__c li : lineItems) {
            if (li.Amount_Passed__c != null) {
                total += li.Amount_Passed__c;
            }
        }
        return total;
    }

    private static Decimal calculateTotalAmount(List<Expense_Line_Item__c> lineItems) {
        Decimal total = 0;
        if (lineItems == null) return total;

        for (Expense_Line_Item__c li : lineItems) {
            if (li.Amount_Claimed__c != null) {
                total += li.Amount_Claimed__c;
            }
        }
        return total;
    }

    private static String determineApprovalLevel(List<ProcessInstanceStep> steps) {
        if (steps == null || steps.isEmpty()) {
            // No steps yet – first approval pending
            return 'Level 1';
        }

        Boolean hasApprovedStep = false;
        for (ProcessInstanceStep step : steps) {
            if (step.StepStatus == 'Approved') {
                hasApprovedStep = true;
                break;
            }
        }
        return hasApprovedStep ? 'Level 2' : 'Level 1';
    }

    private static String getCurrentApprover(List<ProcessInstanceStep> steps, Expense__c expense, String approvalLevel) {
        String recordType = expense.RecordType.DeveloperName;

        if (approvalLevel == 'Level 1') {
            if (recordType == RT_RBL) {
                return expense.Zonal_Head__r != null && String.isNotBlank(expense.Zonal_Head__r.Name)
                    ? 'L1 - ' + expense.Zonal_Head__r.Name
                    : 'L1 - Pending';
            } else if (recordType == RT_UNITOP_TRISTAR) {
                return expense.Customer_Success_Incharge__r != null && String.isNotBlank(expense.Customer_Success_Incharge__r.Name)
                    ? 'L1 - ' + expense.Customer_Success_Incharge__r.Name
                    : 'L1 - Pending';
            }
        } else if (approvalLevel == 'Level 2') {
            return expense.Business_HOD__r != null && String.isNotBlank(expense.Business_HOD__r.Name)
                ? 'L2 - ' + expense.Business_HOD__r.Name
                : 'L2 - Pending';
        } else if (approvalLevel == 'Completed') {
            return 'Completed';
        }
        return 'Unknown';
    }

    /* =======================================================================
       Single approval submit
       ======================================================================= */

    @AuraEnabled
    public static String submitApproval(String expenseId, String action, String comments, List<ExpenseLineItemWrapper> lineItems) {
        Savepoint sp = Database.setSavepoint();
        try {
            if (String.isBlank(expenseId)) {
                throw new AuraHandledException('Expense Id is required.');
            }

            // 1) Update line items first
            if (lineItems != null && !lineItems.isEmpty()) {
                updateLineItemAmounts(lineItems);
            }

            // 2) Fetch expense
            Expense__c expense = [
                SELECT Id, Name, Status__c, Owner.Email, Owner.Name,
                       Zonal_Head__c, Zonal_Head__r.Email, Zonal_Head__r.Name,
                       Business_HOD__c, Business_HOD__r.Email, Business_HOD__r.Name,
                       Customer_Success_Incharge__c, Customer_Success_Incharge__r.Email, Customer_Success_Incharge__r.Name,
                       Date__c, Type_of_Voucher__c, Tour__r.Name, RecordType.DeveloperName,
                       Employee_Name__r.Name, Division__c, Zone__c
                FROM Expense__c
                WHERE Id = :expenseId
                LIMIT 1
            ];

            // 3) Get Workitem
            List<ProcessInstanceWorkitem> workItems = [
                SELECT Id, ProcessInstanceId, ActorId, ProcessInstance.TargetObjectId
                FROM ProcessInstanceWorkitem 
                WHERE ProcessInstance.TargetObjectId = :expenseId
                LIMIT 1
            ];

            if (workItems.isEmpty()) {
                throw new AuraHandledException('No pending approval found for this expense.');
            }

            ProcessInstanceWorkitem wi = workItems[0];

            // 4) Process approval
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setWorkitemId(wi.Id);
            req.setAction(action);
            req.setComments(comments);

            Approval.ProcessResult result = Approval.process(req);

            // If Approval.process fails, it will throw; if not, continue and update status
            Id actorId   = wi.ActorId;
            String rType = expense.RecordType.DeveloperName;

            if (action == 'Approve') {
                if (rType == RT_RBL) {
                    if (actorId == expense.Zonal_Head__c) {
                        expense.Status__c = STS_APR_ZONAL;
                        ExpenseApprovalEmailHandler.sendDecisionEmail(expense, action, expense.Owner.Email, expense.Zonal_Head__r.Email, comments);
                        ExpenseApprovalEmailHandler.sendEscalationToHOD(expense);
                    } else if (actorId == expense.Business_HOD__c) {
                        expense.Status__c = STS_APR_BUS_HOD;
                        ExpenseApprovalEmailHandler.sendDecisionEmail(expense, action, expense.Owner.Email, expense.Business_HOD__r.Email, comments);
                    }
                } else if (rType == RT_UNITOP_TRISTAR) {
                    if (actorId == expense.Customer_Success_Incharge__c) {
                        expense.Status__c = STS_APR_CSI;
                        ExpenseApprovalEmailHandler.sendDecisionEmail(expense, action, expense.Owner.Email, expense.Customer_Success_Incharge__r.Email, comments);
                        ExpenseApprovalEmailHandler.sendEscalationFromCSIToHOD(expense);
                    } else if (actorId == expense.Business_HOD__c) {
                        expense.Status__c = STS_APR_BUS_HOD;
                        ExpenseApprovalEmailHandler.sendDecisionEmail(expense, action, expense.Owner.Email, expense.Business_HOD__r.Email, comments);
                    }
                }
            } else if (action == 'Reject') {
                if (rType == RT_RBL) {
                    if (actorId == expense.Zonal_Head__c) {
                        expense.Status__c = STS_REJ_ZONAL;
                        ExpenseApprovalEmailHandler.sendDecisionEmail(expense, action, expense.Owner.Email, expense.Zonal_Head__r.Email, comments);
                    } else if (actorId == expense.Business_HOD__c) {
                        expense.Status__c = STS_REJ_BUS_HOD;
                        ExpenseApprovalEmailHandler.sendDecisionEmail(expense, action, expense.Owner.Email, expense.Business_HOD__r.Email, comments);
                    }
                } else if (rType == RT_UNITOP_TRISTAR) {
                    if (actorId == expense.Customer_Success_Incharge__c) {
                        expense.Status__c = STS_REJ_CSI;
                        ExpenseApprovalEmailHandler.sendDecisionEmail(expense, action, expense.Owner.Email, expense.Customer_Success_Incharge__r.Email, comments);
                    } else if (actorId == expense.Business_HOD__c) {
                        expense.Status__c = STS_REJ_BUS_HOD;
                        ExpenseApprovalEmailHandler.sendDecisionEmail(expense, action, expense.Owner.Email, expense.Business_HOD__r.Email, comments);
                    }
                }
            }

            update expense;
            return 'Success';

        } catch (Exception e) {
            Database.rollback(sp);
            System.debug('Error submitting: ' + e.getMessage() + ' at line ' + e.getLineNumber());
            System.debug('Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error submitting approval: ' + e.getMessage());
        }
    }

    private static void updateLineItemAmounts(List<ExpenseLineItemWrapper> lineItems) {
        Map<Id, Expense_Line_Item__c> toUpdate = new Map<Id, Expense_Line_Item__c>();

        for (ExpenseLineItemWrapper wrap : lineItems) {
            if (wrap.lineItemId != null) {
                toUpdate.put(
                    (Id)wrap.lineItemId,
                    new Expense_Line_Item__c(
                        Id              = (Id)wrap.lineItemId,
                        Amount_Passed__c= wrap.amountPassed
                    )
                );
            }
        }

        if (!toUpdate.isEmpty()) {
            System.debug('Updating line items: ' + toUpdate.values());
            update toUpdate.values();
            System.debug('Line items updated successfully');
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<ContentDocumentLink> getLineItemFiles(Id lineItemId) {
        if (lineItemId == null) {
            return new List<ContentDocumentLink>();
        }
        return [
            SELECT Id, ContentDocumentId, ContentDocument.Title, ContentDocument.FileType
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :lineItemId
        ];
    }

    /* =======================================================================
       Bulk approval submit
       ======================================================================= */

    @AuraEnabled
    public static String submitBulkApproval(List<String> expenseIds, String action, String comments) {
        Savepoint sp = Database.setSavepoint();
        try {
            if (expenseIds == null || expenseIds.isEmpty()) {
                throw new AuraHandledException('No expenses selected.');
            }

            // 1) Workitems for all expenses
            Map<Id, ProcessInstanceWorkitem> expenseToWorkitemMap = new Map<Id, ProcessInstanceWorkitem>();
            List<ProcessInstanceWorkitem> workItems = [
                SELECT Id, ProcessInstanceId, ActorId, ProcessInstance.TargetObjectId
                FROM ProcessInstanceWorkitem 
                WHERE ProcessInstance.TargetObjectId IN :expenseIds
            ];

            for (ProcessInstanceWorkitem wi : workItems) {
                if (wi.ProcessInstance.TargetObjectId != null) {
                    expenseToWorkitemMap.put(wi.ProcessInstance.TargetObjectId, wi);
                }
            }

            // 2) All expenses
            Map<Id, Expense__c> expenseMap = new Map<Id, Expense__c>([
                SELECT Id, Name, Status__c, Owner.Email, Owner.Name,
                       Zonal_Head__c, Zonal_Head__r.Email, Zonal_Head__r.Name,
                       Business_HOD__c, Business_HOD__r.Email, Business_HOD__r.Name,
                       Customer_Success_Incharge__c, Customer_Success_Incharge__r.Email, Customer_Success_Incharge__r.Name,
                       Date__c, Type_of_Voucher__c, Tour__r.Name, RecordType.DeveloperName,
                       Employee_Name__r.Name, Division__c, Zone__c
                FROM Expense__c 
                WHERE Id IN :expenseIds
            ]);

            // 3) All line items – default Amount_Passed__c = Amount_Claimed__c if null
            List<Expense_Line_Item__c> lineItemsToUpdate = new List<Expense_Line_Item__c>();
            List<Expense_Line_Item__c> allLineItems = [
                SELECT Id, Amount_Passed__c, Amount_Claimed__c, Expense__c
                FROM Expense_Line_Item__c 
                WHERE Expense__c IN :expenseIds
            ];

            for (Expense_Line_Item__c li : allLineItems) {
                if (li.Amount_Passed__c == null) {
                    li.Amount_Passed__c = li.Amount_Claimed__c;
                    lineItemsToUpdate.add(li);
                }
            }

            if (!lineItemsToUpdate.isEmpty()) {
                update lineItemsToUpdate;
            }

            // 4) Build Approval requests & update expenses in memory
            List<Approval.ProcessWorkitemRequest> approvalRequests = new List<Approval.ProcessWorkitemRequest>();
            List<Expense__c> expensesToUpdate = new List<Expense__c>();

            String emailComments = 'Bulk approval' + (String.isNotBlank(comments) ? ' - ' + comments : '');

            for (String expIdStr : expenseIds) {
                Id expId = (Id)expIdStr;
                ProcessInstanceWorkitem wi = expenseToWorkitemMap.get(expId);
                Expense__c expense = expenseMap.get(expId);

                if (wi == null || expense == null) {
                    // No pending WI or Expense missing – skip gracefully
                    continue;
                }

                // Prepare approval request
                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                req.setWorkitemId(wi.Id);
                req.setAction(action);
                req.setComments(comments);
                approvalRequests.add(req);

                // Update status & send mails in the same way as single approval
                Expense__c updated = updateExpenseStatusAfterApproval(expense, action, wi.ActorId, emailComments);
                if (updated != null) {
                    expensesToUpdate.add(updated);
                }
            }

            // 5) Process all approval requests in one call
            if (!approvalRequests.isEmpty()) {
                List<Approval.ProcessResult> results = Approval.process(approvalRequests);
                for (Approval.ProcessResult res : results) {
                    if (!res.isSuccess()) {
                        throw new AuraHandledException('Failed to process one or more approvals.');
                    }
                }
            }

            // 6) Single DML for expenses
            if (!expensesToUpdate.isEmpty()) {
                update expensesToUpdate;
            }

            return 'Successfully processed ' + expenseIds.size() + ' expense(s)';

        } catch (Exception e) {
            Database.rollback(sp);
            System.debug('Error in bulk approval: ' + e.getMessage() + ' at line ' + e.getLineNumber());
            System.debug('Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error in bulk approval: ' + e.getMessage());
        }
    }

    // Shared helper for bulk status update + emails
    private static Expense__c updateExpenseStatusAfterApproval(
        Expense__c expense,
        String action,
        Id actorId,
        String emailComments
    ) {
        String rType = expense.RecordType.DeveloperName;

        if (action == 'Approve') {
            if (rType == RT_RBL) {
                if (actorId == expense.Zonal_Head__c) {
                    expense.Status__c = STS_APR_ZONAL;
                    ExpenseApprovalEmailHandler.sendDecisionEmail(expense, action, expense.Owner.Email, expense.Zonal_Head__r.Email, emailComments);
                    ExpenseApprovalEmailHandler.sendEscalationToHOD(expense);
                } else if (actorId == expense.Business_HOD__c) {
                    expense.Status__c = STS_APR_BUS_HOD;
                    ExpenseApprovalEmailHandler.sendDecisionEmail(expense, action, expense.Owner.Email, expense.Business_HOD__r.Email, emailComments);
                }
            } else if (rType == RT_UNITOP_TRISTAR) {
                if (actorId == expense.Customer_Success_Incharge__c) {
                    expense.Status__c = STS_APR_CSI;
                    ExpenseApprovalEmailHandler.sendDecisionEmail(expense, action, expense.Owner.Email, expense.Customer_Success_Incharge__r.Email, emailComments);
                    ExpenseApprovalEmailHandler.sendEscalationFromCSIToHOD(expense);
                } else if (actorId == expense.Business_HOD__c) {
                    expense.Status__c = STS_APR_BUS_HOD;
                    ExpenseApprovalEmailHandler.sendDecisionEmail(expense, action, expense.Owner.Email, expense.Business_HOD__r.Email, emailComments);
                }
            }
        } else if (action == 'Reject') {
            if (rType == RT_RBL) {
                if (actorId == expense.Zonal_Head__c) {
                    expense.Status__c = STS_REJ_ZONAL;
                    ExpenseApprovalEmailHandler.sendDecisionEmail(expense, action, expense.Owner.Email, expense.Zonal_Head__r.Email, emailComments);
                } else if (actorId == expense.Business_HOD__c) {
                    expense.Status__c = STS_REJ_BUS_HOD;
                    ExpenseApprovalEmailHandler.sendDecisionEmail(expense, action, expense.Owner.Email, expense.Business_HOD__r.Email, emailComments);
                }
            } else if (rType == RT_UNITOP_TRISTAR) {
                if (actorId == expense.Customer_Success_Incharge__c) {
                    expense.Status__c = STS_REJ_CSI;
                    ExpenseApprovalEmailHandler.sendDecisionEmail(expense, action, expense.Owner.Email, expense.Customer_Success_Incharge__r.Email, emailComments);
                } else if (actorId == expense.Business_HOD__c) {
                    expense.Status__c = STS_REJ_BUS_HOD;
                    ExpenseApprovalEmailHandler.sendDecisionEmail(expense, action, expense.Owner.Email, expense.Business_HOD__r.Email, emailComments);
                }
            }
        }

        return expense;
    }

    /* =======================================================================
       Wrappers
       ======================================================================= */

    public class FilterOptionsWrapper {
        @AuraEnabled public List<Map<String, String>> userTypeOptions    { get; set; }
        @AuraEnabled public List<Map<String, Object>> userOptions        { get; set; }
        @AuraEnabled public List<Map<String, String>> voucherTypeOptions { get; set; }
        @AuraEnabled public List<Map<String, String>> monthOptions       { get; set; }
    }

    public class ExpenseWrapper {
        @AuraEnabled public String  expenseId               { get; set; }
        @AuraEnabled public String  expenseName             { get; set; }
        @AuraEnabled public Date    expenseDate             { get; set; }
        @AuraEnabled public String  employeeName            { get; set; }
        @AuraEnabled public String  gradeName               { get; set; }
        @AuraEnabled public String  tourName                { get; set; }
        @AuraEnabled public String  typeOfVoucher           { get; set; }
        @AuraEnabled public String  zonalHead               { get; set; }
        @AuraEnabled public String  businessHOD             { get; set; }
        @AuraEnabled public String  customerSuccessIncharge { get; set; }
        @AuraEnabled public Decimal totalAmount             { get; set; }
        @AuraEnabled public Decimal totalAmountPassed       { get; set; }
        @AuraEnabled public String  status                  { get; set; }
        @AuraEnabled public Datetime createdDate            { get; set; }
        @AuraEnabled public String  currentApprovalLevel    { get; set; }
        @AuraEnabled public String  currentApprover         { get; set; }
        @AuraEnabled public Boolean isPendingWithCurrentUser{ get; set; }
        @AuraEnabled public Boolean isEmployeeUser          { get; set; }
        @AuraEnabled public String  recordType              { get; set; }
        @AuraEnabled public Boolean canEditAmountPassed     { get; set; }
        @AuraEnabled public List<ExpenseLineItemWrapper> lineItems { get; set; }
    }

    public class ExpenseLineItemWrapper {
        @AuraEnabled public String  lineItemId     { get; set; }
        @AuraEnabled public String  typeOfExpense  { get; set; }
        @AuraEnabled public String  modeOfTransport{ get; set; }
        @AuraEnabled public Decimal dailyAllowance { get; set; }
        @AuraEnabled public Decimal amountClaimed  { get; set; }
        @AuraEnabled public Decimal amountPassed   { get; set; }
        @AuraEnabled public String  description    { get; set; }
        @AuraEnabled public Boolean hasFiles       { get; set; }
    }
}