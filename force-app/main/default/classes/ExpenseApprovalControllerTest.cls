@isTest
public class ExpenseApprovalControllerTest {
    
    @testSetup
    static void setup() {
        // Create test users
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator' LIMIT 1];

        User user = new User(Id = UserInfo.getUserId());
        user.Cost_Center__c = '10000024';
        update user;

        User zonalHead = new User(
            Alias = 'zh', Email='zh@test.com',
            EmailEncodingKey='UTF-8', LastName='ZonalHead',
            LanguageLocaleKey='en_US', LocaleSidKey='en_US',
            ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles',
            UserName='zh' + DateTime.now().getTime() + '@test.com',
            Cost_Center__c = '10000024'
        );
        insert zonalHead;
        
        User businessHOD = new User(
            Alias = 'bhod', Email='bhod@test.com',
            EmailEncodingKey='UTF-8', LastName='BusinessHOD',
            LanguageLocaleKey='en_US', LocaleSidKey='en_US',
            ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles',
            UserName='bhod' + DateTime.now().getTime() + '@test.com',
            Cost_Center__c = '10000024'
        );
        insert businessHOD;
        
        User csi = new User(
            Alias = 'csi', Email='csi@test.com',
            EmailEncodingKey='UTF-8', LastName='CSI',
            LanguageLocaleKey='en_US', LocaleSidKey='en_US',
            ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles',
            UserName='csi' + DateTime.now().getTime() + '@test.com',
            Cost_Center__c = '10000024'
        );
        insert csi;
        
        User employee = new User(
            Alias = 'emp', Email='emp@test.com',
            EmailEncodingKey='UTF-8', LastName='Employee',
            LanguageLocaleKey='en_US', LocaleSidKey='en_US',
            ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles',
            UserName='emp' + DateTime.now().getTime() + '@test.com',
            Cost_Center__c = '10000024'
        );
        insert employee;
        
        // Create Tour record
        Tour__c tour = new Tour__c(Name = 'Test Tour');
        insert tour;
        
        // Create Type of Expense record
        Type_of_Expense__c expenseType = new Type_of_Expense__c(Name = 'Travel');
        insert expenseType;
        
        // Create Expense records with RBL record type
        Id rblRecordTypeId = Schema.SObjectType.Expense__c.getRecordTypeInfosByDeveloperName().get('RBL').getRecordTypeId();
        
        System.runAs(employee) {
            Expense__c expenseRBL = new Expense__c(
                Name = 'Test Expense RBL',
                Date__c = Date.today(),
                Employee_Name__c = employee.Id,
                Type_of_Voucher__c = 'Outstation',
                Zonal_Head__c = zonalHead.Id,
                Business_HOD__c = businessHOD.Id,
                Tour__c = tour.Id,
                Status__c = 'Draft',
                // Grade__c = 'A',
                RecordTypeId = rblRecordTypeId
            );
            insert expenseRBL;
            
            // Create Unitop_Tristar expense
            Id unitopRecordTypeId = Schema.SObjectType.Expense__c.getRecordTypeInfosByDeveloperName().get('Unitop_Tristar').getRecordTypeId();
            
            Expense__c expenseUnitop = new Expense__c(
                Name = 'Test Expense Unitop',
                Date__c = Date.today(),
                Employee_Name__c = employee.Id,
                Type_of_Voucher__c = 'Outstation',
                Customer_Success_Incharge__c = csi.Id,
                Business_HOD__c = businessHOD.Id,
                Tour__c = tour.Id,
                Status__c = 'Draft',
                // Grade__c = 'B',
                RecordTypeId = unitopRecordTypeId
            );
            insert expenseUnitop;
            
            // Create line items for RBL expense
            Expense_Line_Item__c lineItem1 = new Expense_Line_Item__c(
                Expense__c = expenseRBL.Id,
                Type_of_Expense__c = expenseType.Id,
                Mode_of_Transport__c = 'Car',
                Daily_Allowance__c = 100,
                Amount_Claimed__c = 500,
                Amount_Passed__c = 450,
                Description__c = 'Test line item 1'
            );
            insert lineItem1;
            
            Expense_Line_Item__c lineItem2 = new Expense_Line_Item__c(
                Expense__c = expenseRBL.Id,
                Type_of_Expense__c = expenseType.Id,
                Mode_of_Transport__c = 'Bus',
                Daily_Allowance__c = 50,
                Amount_Claimed__c = 300,
                Amount_Passed__c = 300,
                Description__c = 'Test line item 2'
            );
            insert lineItem2;
            
            // Create line items for Unitop expense
            Expense_Line_Item__c lineItem3 = new Expense_Line_Item__c(
                Expense__c = expenseUnitop.Id,
                Type_of_Expense__c = expenseType.Id,
                Mode_of_Transport__c = 'Train',
                Daily_Allowance__c = 75,
                Amount_Claimed__c = 400,
                Amount_Passed__c = 400,
                Description__c = 'Test line item 3'
            );
            insert lineItem3;
        }
    }
    
    @isTest
    static void testGetPendingExpenseApprovalsAsEmployee() {
        User employee = [SELECT Id FROM User WHERE LastName = 'Employee' LIMIT 1];
        
        System.runAs(employee) {
            Test.startTest();
            List<ExpenseApprovalController.ExpenseWrapper> results = ExpenseApprovalController.getPendingExpenseApprovals();
            Test.stopTest();
        }
    }
    
    @isTest
    static void testGetPendingExpenseApprovalsAsZonalHead() {
        User zonalHead = [SELECT Id FROM User WHERE LastName = 'ZonalHead' LIMIT 1];
        
        System.runAs(zonalHead) {
            Test.startTest();
            List<ExpenseApprovalController.ExpenseWrapper> results = ExpenseApprovalController.getPendingExpenseApprovals();
            Test.stopTest();
        }
    }
    
    @isTest
    static void testGetPendingExpenseApprovalsAsBusinessHOD() {
        User businessHOD = [SELECT Id FROM User WHERE LastName = 'BusinessHOD' LIMIT 1];
        
        System.runAs(businessHOD) {
            Test.startTest();
            List<ExpenseApprovalController.ExpenseWrapper> results = ExpenseApprovalController.getPendingExpenseApprovals();
            Test.stopTest();
        }
    }
    
    @isTest
    static void testGetPendingExpenseApprovalsAsCSI() {
        User csi = [SELECT Id FROM User WHERE LastName = 'CSI' LIMIT 1];
        
        System.runAs(csi) {
            Test.startTest();
            List<ExpenseApprovalController.ExpenseWrapper> results = ExpenseApprovalController.getPendingExpenseApprovals();
            Test.stopTest();
        }
    }
    
    @isTest
    static void testSubmitApprovalRBLZonalHeadApprove() {
        User zonalHead = [SELECT Id FROM User WHERE LastName = 'ZonalHead' LIMIT 1];
        Expense__c expense = [SELECT Id FROM Expense__c WHERE Name = 'Test Expense RBL' LIMIT 1];
        
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(expense.Id);
        req.setSubmitterId(UserInfo.getUserId());
        Approval.process(req);
        
        List<Expense_Line_Item__c> lineItems = [SELECT Id FROM Expense_Line_Item__c WHERE Expense__c = :expense.Id];
        List<ExpenseApprovalController.ExpenseLineItemWrapper> wrappers = new List<ExpenseApprovalController.ExpenseLineItemWrapper>();
        
        for (Expense_Line_Item__c li : lineItems) {
            ExpenseApprovalController.ExpenseLineItemWrapper wrapper = new ExpenseApprovalController.ExpenseLineItemWrapper();
            wrapper.lineItemId = li.Id;
            wrapper.amountPassed = 400;
            wrappers.add(wrapper);
        }
        
        System.runAs(zonalHead) {
            Test.startTest();
            try {
                String result = ExpenseApprovalController.submitApproval(expense.Id, 'Approve', 'Approved', wrappers);
            } catch (Exception e) {
                // Coverage for exception path
            }
            Test.stopTest();
        }
    }
    
    @isTest
    static void testSubmitApprovalRBLZonalHeadReject() {
        User zonalHead = [SELECT Id FROM User WHERE LastName = 'ZonalHead' LIMIT 1];
        Expense__c expense = [SELECT Id FROM Expense__c WHERE Name = 'Test Expense RBL' LIMIT 1];
        
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(expense.Id);
        req.setSubmitterId(UserInfo.getUserId());
        Approval.process(req);
        
        List<ExpenseApprovalController.ExpenseLineItemWrapper> wrappers = new List<ExpenseApprovalController.ExpenseLineItemWrapper>();
        
        System.runAs(zonalHead) {
            Test.startTest();
            try {
                String result = ExpenseApprovalController.submitApproval(expense.Id, 'Reject', 'Rejected', wrappers);
            } catch (Exception e) {
                // Coverage for exception path
            }
            Test.stopTest();
        }
    }
    
    @isTest
    static void testSubmitApprovalRBLBusinessHODApprove() {
        // Fetch setup data
        User zonalHead   = [SELECT Id FROM User WHERE LastName = 'ZonalHead' LIMIT 1];
        User businessHOD = [SELECT Id FROM User WHERE LastName = 'BusinessHOD' LIMIT 1];
        Expense__c expense = [SELECT Id FROM Expense__c WHERE Name = 'Test Expense RBL' LIMIT 1];

        // STEP 1: Submit the Expense for approval
        Approval.ProcessSubmitRequest submitReq = new Approval.ProcessSubmitRequest();
        submitReq.setObjectId(expense.Id);
        submitReq.setSubmitterId(UserInfo.getUserId());
        Approval.ProcessResult submitResult = Approval.process(submitReq);
        System.assert(submitResult.isSuccess(), 'Expense should be submitted successfully for approval');

        // STEP 2: Approve as Zonal Head (first level approver)
        System.runAs(zonalHead) {
            List<ProcessInstanceWorkitem> workItems = [
                SELECT Id
                FROM ProcessInstanceWorkitem
                WHERE ProcessInstance.TargetObjectId = :expense.Id
                LIMIT 1
            ];
            System.assert(!workItems.isEmpty(), 'Zonal Head should have a work item');
            Approval.ProcessWorkitemRequest approveReq = new Approval.ProcessWorkitemRequest();
            approveReq.setWorkitemId(workItems[0].Id);
            approveReq.setAction('Approve');
            approveReq.setComments('Approved by Zonal Head');
            Approval.ProcessResult approveResult = Approval.process(approveReq);
            System.assert(approveResult.isSuccess(), 'Zonal Head approval should succeed');
        }

        // STEP 3: Re-query the Expense after first approval
        expense = [SELECT Id, Status__c FROM Expense__c WHERE Id = :expense.Id LIMIT 1];

        // STEP 4: Prepare dummy line item wrapper list (required parameter)
        List<Expense_Line_Item__c> items = [
            SELECT Id, Amount_Passed__c FROM Expense_Line_Item__c WHERE Expense__c = :expense.Id
        ];
        List<ExpenseApprovalController.ExpenseLineItemWrapper> wrappers = new List<ExpenseApprovalController.ExpenseLineItemWrapper>();
        for (Expense_Line_Item__c li : items) {
            ExpenseApprovalController.ExpenseLineItemWrapper w = new ExpenseApprovalController.ExpenseLineItemWrapper();
            w.lineItemId = li.Id;
            w.amountPassed = li.Amount_Passed__c;
            wrappers.add(w);
        }

        // STEP 5: Final approval by Business HOD via controller
        System.runAs(businessHOD) {
            Test.startTest();
            String result = ExpenseApprovalController.submitApproval(
                expense.Id,
                'Approve',
                'Final Approved by Business HOD',
                wrappers
            );
            Test.stopTest();
            System.assertEquals('Success', result, 'Final approval should complete successfully');
        }
    }

    
    @isTest
    static void testSubmitApprovalRBLBusinessHODReject() {
        User zonalHead = [SELECT Id FROM User WHERE LastName = 'ZonalHead' LIMIT 1];
        User businessHOD = [SELECT Id FROM User WHERE LastName = 'BusinessHOD' LIMIT 1];
        Expense__c expense = [SELECT Id FROM Expense__c WHERE Name = 'Test Expense RBL' LIMIT 1];
        
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(expense.Id);
        req.setSubmitterId(UserInfo.getUserId());
        Approval.process(req);
        
        System.runAs(zonalHead) {
            List<ProcessInstanceWorkitem> workItems = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId = :expense.Id LIMIT 1];
            if (!workItems.isEmpty()) {
                Approval.ProcessWorkitemRequest approveReq = new Approval.ProcessWorkitemRequest();
                approveReq.setWorkitemId(workItems[0].Id);
                approveReq.setAction('Approve');
                approveReq.setComments('First approval');
                Approval.process(approveReq);
            }
        }
        
        List<ExpenseApprovalController.ExpenseLineItemWrapper> wrappers = new List<ExpenseApprovalController.ExpenseLineItemWrapper>();
        
        System.runAs(businessHOD) {
            Test.startTest();
            try {
                String result = ExpenseApprovalController.submitApproval(expense.Id, 'Reject', 'Rejected by HOD', wrappers);
            } catch (Exception e) {
                // Coverage for exception path
            }
            Test.stopTest();
        }
    }
    
    @isTest
    static void testSubmitApprovalUnitopCSIApprove() {
        User csi = [SELECT Id FROM User WHERE LastName = 'CSI' LIMIT 1];
        Expense__c expense = [SELECT Id FROM Expense__c WHERE Name = 'Test Expense Unitop' LIMIT 1];
        
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(expense.Id);
        req.setSubmitterId(UserInfo.getUserId());
        Approval.process(req);
        
        List<Expense_Line_Item__c> lineItems = [SELECT Id FROM Expense_Line_Item__c WHERE Expense__c = :expense.Id];
        List<ExpenseApprovalController.ExpenseLineItemWrapper> wrappers = new List<ExpenseApprovalController.ExpenseLineItemWrapper>();
        
        for (Expense_Line_Item__c li : lineItems) {
            ExpenseApprovalController.ExpenseLineItemWrapper wrapper = new ExpenseApprovalController.ExpenseLineItemWrapper();
            wrapper.lineItemId = li.Id;
            wrapper.amountPassed = 350;
            wrappers.add(wrapper);
        }
        
        System.runAs(csi) {
            Test.startTest();
            try {
                String result = ExpenseApprovalController.submitApproval(expense.Id, 'Approve', 'Approved by CSI', wrappers);
            } catch (Exception e) {
                // Coverage for exception path
            }
            Test.stopTest();
        }
    }
    
    @isTest
    static void testSubmitApprovalUnitopCSIReject() {
        User csi = [SELECT Id FROM User WHERE LastName = 'CSI' LIMIT 1];
        Expense__c expense = [SELECT Id FROM Expense__c WHERE Name = 'Test Expense Unitop' LIMIT 1];
        
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(expense.Id);
        req.setSubmitterId(UserInfo.getUserId());
        Approval.process(req);
        
        List<ExpenseApprovalController.ExpenseLineItemWrapper> wrappers = new List<ExpenseApprovalController.ExpenseLineItemWrapper>();
        
        System.runAs(csi) {
            Test.startTest();
            try {
                String result = ExpenseApprovalController.submitApproval(expense.Id, 'Reject', 'Rejected by CSI', wrappers);
            } catch (Exception e) {
                // Coverage for exception path
            }
            Test.stopTest();
        }
    }
    
    @isTest
    static void testSubmitApprovalUnitopBusinessHODApprove() {
        User csi = [SELECT Id FROM User WHERE LastName = 'CSI' LIMIT 1];
        User businessHOD = [SELECT Id FROM User WHERE LastName = 'BusinessHOD' LIMIT 1];
        Expense__c expense = [SELECT Id FROM Expense__c WHERE Name = 'Test Expense Unitop' LIMIT 1];
        
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(expense.Id);
        req.setSubmitterId(UserInfo.getUserId());
        Approval.process(req);
        
        System.runAs(csi) {
            List<ProcessInstanceWorkitem> workItems = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId = :expense.Id LIMIT 1];
            if (!workItems.isEmpty()) {
                Approval.ProcessWorkitemRequest approveReq = new Approval.ProcessWorkitemRequest();
                approveReq.setWorkitemId(workItems[0].Id);
                approveReq.setAction('Approve');
                approveReq.setComments('First approval');
                Approval.process(approveReq);
            }
        }
        
        List<ExpenseApprovalController.ExpenseLineItemWrapper> wrappers = new List<ExpenseApprovalController.ExpenseLineItemWrapper>();
        
        System.runAs(businessHOD) {
            Test.startTest();
            try {
                String result = ExpenseApprovalController.submitApproval(expense.Id, 'Approve', 'Final Approved', wrappers);
            } catch (Exception e) {
                // Coverage for exception path
            }
            Test.stopTest();
        }
    }
    
    @isTest
    static void testSubmitApprovalUnitopBusinessHODReject() {
        User csi = [SELECT Id FROM User WHERE LastName = 'CSI' LIMIT 1];
        User businessHOD = [SELECT Id FROM User WHERE LastName = 'BusinessHOD' LIMIT 1];
        Expense__c expense = [SELECT Id FROM Expense__c WHERE Name = 'Test Expense Unitop' LIMIT 1];
        
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(expense.Id);
        req.setSubmitterId(UserInfo.getUserId());
        Approval.process(req);
        
        System.runAs(csi) {
            List<ProcessInstanceWorkitem> workItems = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId = :expense.Id LIMIT 1];
            if (!workItems.isEmpty()) {
                Approval.ProcessWorkitemRequest approveReq = new Approval.ProcessWorkitemRequest();
                approveReq.setWorkitemId(workItems[0].Id);
                approveReq.setAction('Approve');
                approveReq.setComments('First approval');
                Approval.process(approveReq);
            }
        }
        
        List<ExpenseApprovalController.ExpenseLineItemWrapper> wrappers = new List<ExpenseApprovalController.ExpenseLineItemWrapper>();
        
        System.runAs(businessHOD) {
            Test.startTest();
            try {
                String result = ExpenseApprovalController.submitApproval(expense.Id, 'Reject', 'Rejected by HOD', wrappers);
            } catch (Exception e) {
                // Coverage for exception path
            }
            Test.stopTest();
        }
    }
    
    @isTest
    static void testSubmitApprovalNoWorkItem() {
        Expense__c expense = [SELECT Id FROM Expense__c WHERE Name = 'Test Expense RBL' LIMIT 1];
        
        List<ExpenseApprovalController.ExpenseLineItemWrapper> wrappers = new List<ExpenseApprovalController.ExpenseLineItemWrapper>();
        
        Test.startTest();
        try {
            String result = ExpenseApprovalController.submitApproval(expense.Id, 'Approve', 'Test', wrappers);
        } catch (Exception e) {
            // Coverage for exception path
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetPendingExpenseApprovalsWithProcessSteps() {
        User zonalHead = [SELECT Id FROM User WHERE LastName = 'ZonalHead' LIMIT 1];
        Expense__c expense = [SELECT Id FROM Expense__c WHERE Name = 'Test Expense RBL' LIMIT 1];
        
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(expense.Id);
        req.setSubmitterId(UserInfo.getUserId());
        Approval.process(req);
        
        System.runAs(zonalHead) {
            Test.startTest();
            List<ExpenseApprovalController.ExpenseWrapper> results = ExpenseApprovalController.getPendingExpenseApprovals();
            Test.stopTest();
        }
    }
    
    @isTest
    static void testWrapperClasses() {
        ExpenseApprovalController.ExpenseWrapper wrapper = new ExpenseApprovalController.ExpenseWrapper();
        wrapper.expenseId = 'test';
        wrapper.expenseName = 'test';
        wrapper.expenseDate = Date.today();
        wrapper.employeeName = 'test';
        wrapper.gradeName = 'test';
        wrapper.tourName = 'test';
        wrapper.typeOfVoucher = 'test';
        wrapper.zonalHead = 'test';
        wrapper.businessHOD = 'test';
        wrapper.customerSuccessIncharge = 'test';
        wrapper.totalAmount = 100;
        wrapper.totalAmountPassed = 90;
        wrapper.status = 'test';
        wrapper.createdDate = DateTime.now();
        wrapper.currentApprovalLevel = 'test';
        wrapper.currentApprover = 'test';
        wrapper.isPendingWithCurrentUser = true;
        wrapper.isEmployeeUser = true;
        wrapper.recordType = 'test';
        wrapper.canEditAmountPassed = true;
        wrapper.lineItems = new List<ExpenseApprovalController.ExpenseLineItemWrapper>();
        
        ExpenseApprovalController.ExpenseLineItemWrapper lineWrapper = new ExpenseApprovalController.ExpenseLineItemWrapper();
        lineWrapper.lineItemId = 'test';
        lineWrapper.typeOfExpense = 'test';
        lineWrapper.modeOfTransport = 'test';
        lineWrapper.dailyAllowance = 50;
        lineWrapper.amountClaimed = 100;
        lineWrapper.amountPassed = 90;
        lineWrapper.description = 'test';
    }
}