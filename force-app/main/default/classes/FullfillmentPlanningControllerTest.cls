@isTest
public class FullfillmentPlanningControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test Account
        Account testAccount = new Account(
            Name = 'Test Account',
            Business_Type__c = 'Export'
        );
        insert testAccount;
        
        
        // Create Ship to and Bill to party accounts
        Address_Information__c shipToParty = new Address_Information__c(Name = 'Ship To Party');
        Address_Information__c billToParty = new Address_Information__c(Name = 'Bill To Party');
        insert new List<Address_Information__c>{shipToParty, billToParty};
        
        // Create test Product and UOM
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'TEST-001',
            Description = 'Test Description'
        );
        insert testProduct;
        
        // Create Standard Price Book Entry
        PricebookEntry standardPBE = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert standardPBE;
        
        // Create test Order
        Order testOrder = new Order(
            AccountId = testAccount.Id,
            Status = 'Draft',
            EffectiveDate = System.today(),
            Ship_to_party__c = shipToParty.Id,
            Bill_to_party__c = billToParty.Id,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert testOrder;
        
        // Create Order Product
        OrderItem testOrderProduct = new OrderItem(
            OrderId = testOrder.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            Quantity = 1,
            pricebookEntryId = standardPBE.Id
        );
        insert testOrderProduct;
        
        // Create Order Scheduling Line Item
        Order_Scheduling_Line_Item_wise__c orderSchedulingLine = new Order_Scheduling_Line_Item_wise__c(
            Order__c = testOrder.Id,
            Order_Product__c = testOrderProduct.Id,
            Confirmed_Quantity__c = 100,
            Scheduled_Quantity__c = 50,
            Delivery_Date__c = System.today().addDays(7)
        );
        insert orderSchedulingLine;
        
        // Create Customer Order Schedule Line Item
        Customer_Order_Schedule_Line_Item__c customerSchedule = new Customer_Order_Schedule_Line_Item__c(
            Order__c = testOrder.Id,
            Order_Product__c = testOrderProduct.Id,
            Order_Scheduling_Line_Item__c = orderSchedulingLine.Id,
            Customer_Scheduled_Quantity__c = 25,
            Customer_Scheduled_Date__c = System.today().addDays(5),
            Production_Scheduled_Date__c = System.today().addDays(3),
            Production_Revised_Date__c = System.today().addDays(4),
            Remarks_for_Production_Planner__c = 'Test Remarks'
        );
        insert customerSchedule;
    }
    
    @isTest
    static void testGetOrderData() {
        // Test getting order data
        Test.startTest();
        List<FullfillmentPlanningController.OrderMaster> results = FullfillmentPlanningController.getOrderData('B2B');
        Test.stopTest();
    }
    
    @isTest
    static void testGetFilteredOrderData() {
        // Create filter wrapper
        FullfillmentPlanningController.FilterWrapper filter = new FullfillmentPlanningController.FilterWrapper();
        filter.sbuFilter = 'Test SBU';
        String filterJson = JSON.serialize(filter);
        
        Test.startTest();
        List<FullfillmentPlanningController.OrderMaster> results = 
            FullfillmentPlanningController.getFilteredOrderData('B2B', filterJson);
        Test.stopTest();
        

    }
    
    @isTest
    static void testGetCustomerSchedules() {
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        OrderItem testOrderProduct = [SELECT Id FROM OrderItem WHERE OrderId = :testOrder.Id LIMIT 1];
        Order_Scheduling_Line_Item_wise__c schedulingLine = 
            [SELECT Id FROM Order_Scheduling_Line_Item_wise__c WHERE Order__c = :testOrder.Id LIMIT 1];
        
        Test.startTest();
        List<FullfillmentPlanningController.CustomerOrderSchedulingLine> schedules = 
            FullfillmentPlanningController.getCustomerSchedules(
                testOrder.Id, 
                testOrderProduct.Id, 
                schedulingLine.Id
            );
        Test.stopTest();
        

    }
    
    @isTest
    static void testSaveCustomerSchedules() {
        Order_Scheduling_Line_Item_wise__c schedulingLine = 
            [SELECT Id, Order__c, Order_Product__c FROM Order_Scheduling_Line_Item_wise__c LIMIT 1];
            
        FullfillmentPlanningController.CustomerOrderSchedulingLine schedule = 
            new FullfillmentPlanningController.CustomerOrderSchedulingLine();
        schedule.orderSchedulingLineItemId = schedulingLine.Id;
        schedule.orderId = schedulingLine.Order__c;
        schedule.orderProductId = schedulingLine.Order_Product__c;
        schedule.customerScheduledQuantity = 30;
        schedule.customerScheduledDate = System.today().addDays(10);
        schedule.productionScheduledDate = System.today().addDays(8);
        schedule.remarksForProductionPlanner = 'New Schedule';
        
        String scheduleJson = JSON.serialize(new List<FullfillmentPlanningController.CustomerOrderSchedulingLine>{schedule});
        
        Test.startTest();
        String result = FullfillmentPlanningController.saveCustomerSchedules(scheduleJson);
        Test.stopTest();
        

    }
    
    @isTest
    static void testRemoveRowScheduleData() {
        Customer_Order_Schedule_Line_Item__c schedule = 
            [SELECT Id FROM Customer_Order_Schedule_Line_Item__c LIMIT 1];
            
        Test.startTest();
        String result = FullfillmentPlanningController.removeRowScheduleData(schedule.Id);
        Test.stopTest();
        

    }
    
    @isTest
    static void testRemoveAllCustomerSchedules() {
        Order_Scheduling_Line_Item_wise__c schedulingLine = 
            [SELECT Id, Order__c, Order_Product__c FROM Order_Scheduling_Line_Item_wise__c LIMIT 1];
            
        Test.startTest();
        String result = FullfillmentPlanningController.removeAllCustomerSchedules(
            schedulingLine.Order__c,
            schedulingLine.Order_Product__c,
            schedulingLine.Id
        );
        Test.stopTest();
        

    }
    
    @isTest
    static void testSaveHeader() {
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        
        FullfillmentPlanningController.HeaderWrapper header = new FullfillmentPlanningController.HeaderWrapper();
        header.id = testOrder.Id;
        header.pricingStatus = 'Block';
        header.cogsStatus = 'Block';
        header.creditStatus = 'Block';
        
        String headerJson = JSON.serialize(new List<FullfillmentPlanningController.HeaderWrapper>{header});
        
        Test.startTest();
        String result = FullfillmentPlanningController.saveHeader(headerJson);
        Test.stopTest();
        

    }
    
    @isTest
    static void testGetOrderPicklistOptions() {
        Test.startTest();
        FullfillmentPlanningController.OptionWrapper options = 
            FullfillmentPlanningController.getOrderPicklistOptions('B2B');
        Test.stopTest();
        

    }
    
    @isTest
    static void testRemoveRowCustomerSchedule() {
        Customer_Order_Schedule_Line_Item__c schedule = 
            [SELECT Id FROM Customer_Order_Schedule_Line_Item__c LIMIT 1];
            
        Test.startTest();
        Boolean result = FullfillmentPlanningController.removeRowCustomerSchedule(schedule.Id);
        Test.stopTest();
        

    }
}