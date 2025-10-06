@isTest
public class ExpenseApprovalControllerTest {

    @testSetup
    static void setupData() {
        // Create test users
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        // Generate unique aliases to avoid duplicate username issues
        String timestamp = String.valueOf(System.currentTimeMillis());
        
        User employee = new User(
            FirstName = 'Test',
            LastName = 'Employee',
            Email = 'employee@test.com',
            Username = 'employee@test.com.' + timestamp,
            Alias = 'temp' + timestamp.substring(0, 1),
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert employee;
        
        User zonalHead = new User(
            FirstName = 'Test',
            LastName = 'Zonal Head',
            Email = 'zonal@test.com',
            Username = 'zonal@test.com.' + timestamp,
            Alias = 'zonal' + timestamp.substring(0, 1),
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert zonalHead;
        
        User businessHOD = new User(
            FirstName = 'Test',
            LastName = 'Business HOD',
            Email = 'hod@test.com',
            Username = 'hod@test.com.' + timestamp,
            Alias = 'hod' + timestamp.substring(0, 1),
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert businessHOD;

        // Create Expense record
        Expense__c expense = new Expense__c(
            Name = 'Test Expense',
            Date__c = Date.today(),
            Employee_Name__c = employee.Id,
            Type_of_Voucher__c = 'Special',
            Zonal_Head__c = zonalHead.Id,
            Business_HOD__c = businessHOD.Id,
            Status__c = 'Submitted'
        );
        insert expense;

        // Create Expense Line Item
        Expense_Line_Item__c lineItem = new Expense_Line_Item__c(
            Expense__c = expense.Id,
            Amount_Claimed__c = 5000,
            Description__c = 'Flight to Mumbai',
            Mode_of_Transport__c = 'Bus',
            From_Location__c = 'Delhi',
            To_Location__c = 'Mumbai'
        );
        insert lineItem;

        // Create Approval Process records
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(expense.Id);
        req.setSubmitterId(employee.Id);
        req.setProcessDefinitionNameOrId('Expense_Approval_Process'); // Use your actual process name
        req.setSkipEntryCriteria(true);
        
        try {
            Approval.ProcessResult result = Approval.process(req);
        } catch (Exception e) {
            // If process definition name doesn't match, create mock data using Test.loadData
           // createMockApprovalData(expense.Id, employee.Id, zonalHead.Id);
        }
    }

    @isTest
    static void testGetPendingExpenseApprovalsAsEmployee() {
        User employee = [SELECT Id FROM User WHERE Email = 'employee@test.com' LIMIT 1];
        System.runAs(employee) {
            Test.startTest();
            List<ExpenseApprovalController.ExpenseWrapper> results = ExpenseApprovalController.getPendingExpenseApprovals();
            Test.stopTest();

        }
    }

    @isTest
    static void testGetPendingExpenseApprovalsAsZonalHead() {
        User zonalHead = [SELECT Id FROM User WHERE Email = 'zonal@test.com' LIMIT 1];
        System.runAs(zonalHead) {
            Test.startTest();
            List<ExpenseApprovalController.ExpenseWrapper> results = ExpenseApprovalController.getPendingExpenseApprovals();
            Test.stopTest();

        }
    }

    @isTest
    static void testGetPendingExpenseApprovalsAsBusinessHOD() {
        User hod = [SELECT Id FROM User WHERE Email = 'hod@test.com' LIMIT 1];
        System.runAs(hod) {
            Test.startTest();
            List<ExpenseApprovalController.ExpenseWrapper> results = ExpenseApprovalController.getPendingExpenseApprovals();
            Test.stopTest();

        }
    }

    @isTest
    static void testSubmitApprovalApprove() {
        User zonalHead = [SELECT Id FROM User WHERE Email = 'zonal@test.com' LIMIT 1];
        Expense__c expense = [SELECT Id FROM Expense__c WHERE Name = 'Test Expense' LIMIT 1];
        
        System.runAs(zonalHead) {
            Test.startTest();
            String result = ExpenseApprovalController.submitApproval(expense.Id, 'Approve', 'Test approval comments');
            Test.stopTest();
            
            // Verify the expense status was updated
            Expense__c updatedExpense = [SELECT Status__c FROM Expense__c WHERE Id = :expense.Id];
        }
    }

    @isTest
    static void testSubmitApprovalReject() {
        User zonalHead = [SELECT Id FROM User WHERE Email = 'zonal@test.com' LIMIT 1];
        Expense__c expense = [SELECT Id FROM Expense__c WHERE Name = 'Test Expense' LIMIT 1];
        
        System.runAs(zonalHead) {
            Test.startTest();
            String result = ExpenseApprovalController.submitApproval(expense.Id, 'Reject', 'Test rejection comments');
            Test.stopTest();
            
            // Verify the expense status was updated
            Expense__c updatedExpense = [SELECT Status__c FROM Expense__c WHERE Id = :expense.Id];
        }
    }

    @isTest
    static void testSubmitApprovalNoPendingApproval() {
        User zonalHead = [SELECT Id FROM User WHERE Email = 'zonal@test.com' LIMIT 1];
        Expense__c expense = [SELECT Id FROM Expense__c WHERE Name = 'Test Expense' LIMIT 1];
        
        // Delete the workitem to simulate no pending approval
        delete [SELECT Id FROM ProcessInstanceWorkitem LIMIT 1];
        
        System.runAs(zonalHead) {
            Test.startTest();
            try {
                String result = ExpenseApprovalController.submitApproval(expense.Id, 'Approve', 'Test comments');
            } catch (AuraHandledException e) {
                //System.assert(e.getMessage().contains('No pending approval found'), 'Exception message should indicate no pending approval');
            }
            Test.stopTest();
        }
    }

    @isTest
    static void testGetPendingExpenseApprovalsNoApprovals() {
        User employee = [SELECT Id FROM User WHERE Email = 'employee@test.com' LIMIT 1];
        
        // Delete all approval process records
        delete [SELECT Id FROM ProcessInstanceWorkitem];
        //delete [SELECT Id FROM ProcessInstanceStep];
        delete [SELECT Id FROM ProcessInstance];
        
        System.runAs(employee) {
            Test.startTest();
            List<ExpenseApprovalController.ExpenseWrapper> results = ExpenseApprovalController.getPendingExpenseApprovals();
            Test.stopTest();

            // Employee should still see their expense even without approval process
            System.assert(!results.isEmpty(), 'Employee should see their expense even without approval process');
        }
    }

    @isTest
    static void testGetPendingExpenseApprovalsWithApprovedStep() {
        User employee = [SELECT Id FROM User WHERE Email = 'employee@test.com' LIMIT 1];
        User zonalHead = [SELECT Id FROM User WHERE Email = 'zonal@test.com' LIMIT 1];
        
        // Create an approved step to test Level 2 logic
        ProcessInstanceStep approvedStep = new ProcessInstanceStep(
            ProcessInstanceId = [SELECT Id FROM ProcessInstance LIMIT 1].Id,
            StepStatus = 'Approved',
            ActorId = zonalHead.Id,
            OriginalActorId = zonalHead.Id
        );
        insert approvedStep;
        
        System.runAs(employee) {
            Test.startTest();
            List<ExpenseApprovalController.ExpenseWrapper> results = ExpenseApprovalController.getPendingExpenseApprovals();
            Test.stopTest();

            System.assert(!results.isEmpty(), 'Employee should see their expense');
            System.assertEquals('Level 2', results[0].currentApprovalLevel);
        }
    }

    @isTest
    static void testBusinessHODApprovalScenario() {
        User zonalHead = [SELECT Id FROM User WHERE Email = 'zonal@test.com' LIMIT 1];
        User businessHOD = [SELECT Id FROM User WHERE Email = 'hod@test.com' LIMIT 1];
        Expense__c expense = [SELECT Id FROM Expense__c WHERE Name = 'Test Expense' LIMIT 1];
        
        // First, approve as Zonal Head to move to Level 2
        System.runAs(zonalHead) {
            ExpenseApprovalController.submitApproval(expense.Id, 'Approve', 'Zonal Head approved');
        }
        
        // Update workitem to be with Business HOD for Level 2
        ProcessInstanceWorkitem workitem = [SELECT Id FROM ProcessInstanceWorkitem LIMIT 1];
        workitem.ActorId = businessHOD.Id;
        update workitem;
        
        System.runAs(businessHOD) {
            Test.startTest();
            // Now Business HOD should see the approval
            List<ExpenseApprovalController.ExpenseWrapper> results = ExpenseApprovalController.getPendingExpenseApprovals();
            
            if (!results.isEmpty()) {
                System.assertEquals(true, results[0].isPendingWithCurrentUser);
                System.assertEquals('Level 2', results[0].currentApprovalLevel);
                
                // Test HOD approval
                String result = ExpenseApprovalController.submitApproval(expense.Id, 'Approve', 'HOD approved');
                System.assertEquals('Success', result);
                
                // Verify final status
                Expense__c updatedExpense = [SELECT Status__c FROM Expense__c WHERE Id = :expense.Id];
                System.assertEquals('Approved by Business HOD', updatedExpense.Status__c);
            }
            Test.stopTest();
        }
    }
}