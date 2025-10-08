@isTest
private class BookingSummaryControllerTest {
    
    static testMethod void testAllMethods() {
        
        // ====== 1. Create Test Data ======
        User u = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        
        FY__c fy = new FY__c(
            Name = 'FY2025',
            FY_Start_Date__c = Date.today(),
            FY_End_Date__c = Date.today().addMonths(12)
            // isActive__c = true
        );
        insert fy;
        
        Account acc = new Account(
            Name = 'Test Account',
            CurrencyIsoCode = 'USD',
            OwnerId = u.Id
        );
        insert acc;
        
        // Create Item Group (if referenced)
        RecordType rt;
        try {
            rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Product2' LIMIT 1];
        } catch (Exception e) {}
        
        // Create Item Group record first
    //    Item_Group__c itemGroup = new Item_Group__c(
     //       Name = 'Test Item Group'
     //   );
     //   insert itemGroup;
        
        // Now create Product with that Item Group
      /*  Product2 prod = new Product2(
            Name = 'Test Product',
            ProductCode = 'P001',
            IsActive = true
         //   Item_Group__c = itemGroup.Id   // link to Item Group
        );
        insert prod; */
        
        // Booking Target for testing getExistingData
        Booking_Target__c bt = new Booking_Target__c(
            FY__c = fy.Id,
         //   Product__c = prod.Id,
            Sales_Employee__c = u.Id,
            Month__c = 'September',
            Year__c = '2025',
            Account__c = acc.Id,
            Sales_Quantity__c = 10,
            COGS_Rate__c = 20,
            Budget_Rate__c = 25
        );
        insert bt;
        
        
        // ====== 2. Test getDefualtFiscId ======
        Test.startTest();
        FY__c fyRec = BookingSummaryController.getDefualtFiscId();
        
        
        // ====== 3. Test getDefualtAccount ======
        List<Account> accList = BookingSummaryController.getDefualtAccount(u.Id);
        
        
        // ====== 4. Test getAllExistingData ======
        List<Booking_Target__c> allList = BookingSummaryController.getAllExistingData(u.Id, fy.Id);
        
        
        // ====== 5. Test getExistingData ======
        List<Booking_Target__c> existList = BookingSummaryController.getExistingData(u.Id, fy.Id, acc.Id);
        
        
        // ====== 6. Test updateOnDemand for all fields ======
        // a) Sales_Qauntity__c
        BookingSummaryController.updateOnDemand(bt.Id, 'Sales_Qauntity__c', '55');
        // b) COGS_Kg__c
        BookingSummaryController.updateOnDemand(bt.Id, 'COGS_Kg__c', '30');
        // c) Price__c
        BookingSummaryController.updateOnDemand(bt.Id, 'Price__c', '100');
        
        
        // ====== 7. Test getProductList ======
        List<Product2> prodList = BookingSummaryController.getProductList();
        
        
        // ====== 8. Test saveToServer ======
        List<Map<String, Object>> jsonList = new List<Map<String, Object>>();
        Map<String, Object> recordMap = new Map<String, Object>();
      //  recordMap.put('ProductId', prod.Id);
        recordMap.put('MonthName', 'Jan-2025');
        recordMap.put('Sales_Qauntity__c', 100);
        recordMap.put('COGS_Kg__c', 40.5);
        recordMap.put('Price__c', 60);
        recordMap.put('CustomerId', acc.Id);
        recordMap.put('ProductCode', 'P001');
        jsonList.add(recordMap);
        
        String jsonString = JSON.serialize(jsonList);
        String result = BookingSummaryController.saveToServer(jsonString, u.Id, fy.Id);
        
        
        // ====== 9. Test saveToServer Exception handling ======
        String badJson = '[{badJson:true}]';
        String errResult = BookingSummaryController.saveToServer(badJson, u.Id, fy.Id);
        
        Test.stopTest();
    }
}