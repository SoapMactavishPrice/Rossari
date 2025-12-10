@isTest
private class NewExpenseApprovalControllerTest {
    
    // Helper to get a Profile Id (Standard User fallback)
    private static Id getStandardProfileId() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        return p.Id;
    }
    
    private static User createUser(String alias, String lastName, String emailSuffix, String userType) {
        Id profId = getStandardProfileId();
        String uname = 'test' + alias + '@example' + emailSuffix + '.com';
        User u = new User(
            Alias = alias.substring(0,Math.min(8, alias.length())),
            Email = uname,
            EmailEncodingKey = 'UTF-8',
            LastName = lastName,
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Asia/Kolkata',
            ProfileId = profId,
            Username = uname,
            User_Type__c = 'AHN'
        );
        insert u;
        return u;
    }
    
    @isTest static void testGetFilterOptionsAndPendingExpenses() {
        // Create users
        User owner = createUser('own', 'Owner', '1', 'AHN');
        User zonal = createUser('zonal', 'Zonal', '2', 'AHN');
        User hod = createUser('hod', 'Hod', '3', 'AHN');
        User csi = createUser('csi', 'Csi', '4', 'AHN');
        
        // Create an Expense (with a completed status so getPendingExpenseApprovals picks it up via completedExpenses)
        Expense__c e = new Expense__c(
            Name = 'Test Expense 1',
            Date__c = Date.today().addDays(-5),
            Employee_Name__c = owner.Id,
            Type_of_Voucher__c = 'Special',
            Zonal_Head__c = zonal.Id,
            Business_HOD__c = hod.Id,
            Customer_Success_Incharge__c = csi.Id,
            Status__c = 'Approved by Zonal Head' // included in getCompletedStatusValues()
        );
        insert e;
        
        // Add two line items
        Expense_Line_Item__c li1 = new Expense_Line_Item__c(
            Expense__c = e.Id,
            Amount_Claimed__c = 100,
            Amount_Passed__c = null
        );
        Expense_Line_Item__c li2 = new Expense_Line_Item__c(
            Expense__c = e.Id,
            Amount_Claimed__c = 200,
            Amount_Passed__c = 150
        );
        insert new List<Expense_Line_Item__c>{ li1, li2 };
        
        Test.startTest();
            // Call getFilterOptions
            NewExpenseApprovalController.FilterOptionsWrapper opts = NewExpenseApprovalController.getFilterOptions();
            System.assertNotEquals(null, opts, 'Filter options should not be null');
            System.assert(opts.monthOptions.size() >= 1, 'Month options expected');
            System.assert(opts.voucherTypeOptions.size() >= 1, 'Voucher type options expected');
            
            // Call getPendingExpenseApprovals - should pick up our expense via completed statuses
            List<NewExpenseApprovalController.ExpenseWrapper> wrappers = NewExpenseApprovalController.getPendingExpenseApprovals();
            System.assert(wrappers.size() > 0, 'Should return at least one wrapper');
            
            // Find our wrapper and assert totals and fields
            Boolean found = false;
            for (NewExpenseApprovalController.ExpenseWrapper w : wrappers) {
                if (w.expenseId == e.Id) {
                    found = true;
                    // totalAmount should be 300 (100 + 200)
                    System.assertEquals(
                        300,
                        w.totalAmount.setScale(0),
                        'Total amount calculation mismatch'
                    );
                    // totalAmountPassed should be 150 (only li2 passed)
                    System.assertEquals(
                        150,
                        w.totalAmountPassed.setScale(0),
                        'Total amount passed mismatch'
                    );
                    break;
                }
            }
            System.assert(found, 'Expense wrapper for inserted expense must be present');
            
            // getLineItemFiles - no files attached, expect empty
            List<ContentDocumentLink> files = NewExpenseApprovalController.getLineItemFiles(li1.Id);
            System.assertEquals(0, files.size(), 'No files expected for the line item');
        Test.stopTest();
    }
    
    @isTest static void testSubmitBulkApproval_updatesLineItems() {
        // Create users
        User owner = createUser('own2', 'Owner2', '11', 'AHN');
        
        // Create Expense
        Expense__c e = new Expense__c(
            Name = 'Bulk Expense',
            Date__c = Date.today(),
            Employee_Name__c = owner.Id,
            Type_of_Voucher__c = 'Special',
            Status__c = 'Draft' // not completed
        );
        insert e;
        
        // Create line items with Amount_Passed__c null (should be set to claimed by submitBulkApproval)
        Expense_Line_Item__c liA = new Expense_Line_Item__c(
            Expense__c = e.Id,
            Amount_Claimed__c = 500,
            Amount_Passed__c = null
        );
        Expense_Line_Item__c liB = new Expense_Line_Item__c(
            Expense__c = e.Id,
            Amount_Claimed__c = 250,
            Amount_Passed__c = null
        );
        insert new List<Expense_Line_Item__c>{ liA, liB };
        
        Test.startTest();
            // Call bulk approval - there will be no ProcessInstanceWorkitems in test context,
            // but submitBulkApproval is written to handle empty workItems (it will still update line items)
            String result = NewExpenseApprovalController.submitBulkApproval(
                new List<String>{ e.Id },
                'Approve',
                'Bulk approve test'
            );
            System.assert(result.contains('Successfully processed'), 'Bulk approval should return a success message');
        Test.stopTest();
        
        // Verify line items updated: Amount_Passed__c should be set to Amount_Claimed__c
        Expense_Line_Item__c updatedA = [SELECT Id, Amount_Claimed__c, Amount_Passed__c FROM Expense_Line_Item__c WHERE Id = :liA.Id LIMIT 1];
        Expense_Line_Item__c updatedB = [SELECT Id, Amount_Claimed__c, Amount_Passed__c FROM Expense_Line_Item__c WHERE Id = :liB.Id LIMIT 1];
        
        System.assertEquals(updatedA.Amount_Claimed__c, updatedA.Amount_Passed__c, 'Amount_Passed should be set to Amount_Claimed for liA');
        System.assertEquals(updatedB.Amount_Claimed__c, updatedB.Amount_Passed__c, 'Amount_Passed should be set to Amount_Claimed for liB');
    }
    
    
}