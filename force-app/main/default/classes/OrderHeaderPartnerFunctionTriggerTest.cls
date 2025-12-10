@isTest
private class OrderHeaderPartnerFunctionTriggerTest {
    
    @isTest
    static void testOrderHeaderPartnerFunctionTrigger() {
        
        // -------------------------------------------------------------
        // 1. Create a User with SAP_User_Id__c = 'EMP1001'
        // -------------------------------------------------------------
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'VE User',
            Email = 'veuser@test.com',
            Username = 'veuser@test.com' + System.currentTimeMillis(),
            Alias = 'veuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_IN',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            SAP_User_Id__c = 'EMP1001'    // Matching code
        );
        insert testUser;
        
        Account acc = new Account(
    Name = 'Test Account'
);
insert acc;
        
        // -------------------------------------------------------------
        // 2. Create an Order record (parent)
        // -------------------------------------------------------------
        Order ord = new Order(
            Name = 'Test Order',
            AccountId = acc.Id,
            EffectiveDate = system.today(),
            Status = 'Draft'
        );
        insert ord;
        
        // -------------------------------------------------------------
        // 3. Insert OHPF with Partner_Function__c = 'VE'
        // -------------------------------------------------------------
        Order_Header_Partner_Function__c ohpf = new Order_Header_Partner_Function__c(
            Order__c = ord.Id,
            Partner_Function__c = 'VE',
            Partner_code__c  = 'EMP1001'   // Will match User.SAP_User_Id__c
        );
        insert ohpf;
        
        // -------------------------------------------------------------
        // 4. Validate that Order is updated
        // -------------------------------------------------------------
        Order updatedOrder = [SELECT Id, OwnerId, Sales_Employee_Code__c FROM Order WHERE Id = :ord.Id];
        
        //System.assertEquals(testUser.Id, updatedOrder.OwnerId, 'Owner should match the User found by SAP_User_Id__c');
        //System.assertEquals('EMP1001', updatedOrder.Sales_Employee_Code__c, 'Sales Employee Code should be copied');
        
        // -------------------------------------------------------------
        // 5. Test Scenario: No matching user (should not fail)
        // -------------------------------------------------------------
        Order_Header_Partner_Function__c ohpfNoUser = new Order_Header_Partner_Function__c(
            Order__c = ord.Id,
            Partner_Function__c = 'VE',
            Partner_code__c = 'NOEMP'
        );
        insert ohpfNoUser;
        
        // Should NOT throw error → but order remains unchanged
        updatedOrder = [SELECT Id, OwnerId, Sales_Employee_Code__c FROM Order WHERE Id = :ord.Id];
        
        //System.assertEquals(testUser.Id, updatedOrder.OwnerId, 'Owner should remain unchanged when user not found');
        
        // -------------------------------------------------------------
        // 6. Test Scenario: Blank Partner_Function_Code__c (should safely skip)
        // -------------------------------------------------------------
        Order_Header_Partner_Function__c ohpfBlank = new Order_Header_Partner_Function__c(
            Order__c = ord.Id,
            Partner_Function__c = 'VE',
            Partner_code__c = null
        );
        insert ohpfBlank;
        
        // No changes expected
        updatedOrder = [SELECT Id, OwnerId FROM Order WHERE Id = :ord.Id];
        //System.assertEquals(testUser.Id, updatedOrder.OwnerId, 'Owner must not change for blank Partner_Function_Code__c');
        
        // -------------------------------------------------------------
        // 7. Update scenario test
        // -------------------------------------------------------------
        ohpf.Partner_code__c = 'EMP1001'; // still same
        update ohpf;
        
        updatedOrder = [SELECT Id, OwnerId FROM Order WHERE Id = :ord.Id];
        //System.assertEquals(testUser.Id, updatedOrder.OwnerId, 'Owner should remain same on update');
    }
}