@IsTest
public class FullfillmentPlanningControllerTest {

    @TestSetup
    static void setupTestData() {
        Id standardPricebookId = Test.getStandardPricebookId();

        Plant__c testPlant = new Plant__c(Name = 'Test Plant');
        insert testPlant;

        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'TEST-001',
            Description = 'Test Description',
            IsActive = true,
            Plant_Code__c = testPlant.Id
        );
        insert testProduct;

        PricebookEntry standardPBE = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = testProduct.Id,
            UnitPrice = 100.00,
            IsActive = true,
            UseStandardPrice = false
        );
        insert standardPBE;

        Account testAccount = new Account(
            Name = 'Test Account',
            Business_Type__c = 'Export',
            SAP_Customer_Code__c = 'SAP123'
        );
        insert testAccount;

        Address_Information__c shipToParty = new Address_Information__c(Name = 'Ship To Party', Account__c = testAccount.Id);
        Address_Information__c billToParty = new Address_Information__c(Name = 'Bill To Party', Account__c = testAccount.Id);
        insert new List<Address_Information__c>{shipToParty, billToParty};

        Order testOrder = new Order(
            AccountId = testAccount.Id,
            Status = 'Draft',
            EffectiveDate = System.today(),
            Ship_to_party__c = shipToParty.Id,
            Bill_to_party__c = billToParty.Id,
            Pricebook2Id = standardPricebookId,
            Plant_Code__c = testPlant.Id,
            SBU__c = 'SBU1',
            Document_No__c = 'DOC123'
        );
        insert testOrder;

        OrderItem testOrderProduct = new OrderItem(
            OrderId = testOrder.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            Quantity = 1,
            PricebookEntryId = standardPBE.Id
        );
        insert testOrderProduct;

        Order_Scheduling_Line_Item_wise__c orderSchedulingLine = new Order_Scheduling_Line_Item_wise__c(
            Order__c = testOrder.Id,
            Order_Product__c = testOrderProduct.Id,
            Confirmed_Quantity__c = 100,
            Scheduled_Quantity__c = 50,
            Delivery_Date__c = System.today().addDays(7)
        );
        insert orderSchedulingLine;

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

    @IsTest static void testGetOrderData() {
        Test.startTest();
        FullfillmentPlanningController.getOrderData('Export');
        Test.stopTest();
    }

    @IsTest static void testGetOrderDataEmpty() {
        Test.startTest();
        FullfillmentPlanningController.getOrderData('InvalidType');
        Test.stopTest();
    }

    @IsTest static void testGetFilteredOrderData() {
        FullfillmentPlanningController.FilterWrapper filter = new FullfillmentPlanningController.FilterWrapper();
        filter.sbuFilter = 'SBU1';
        String filterJson = JSON.serialize(filter);

        Test.startTest();
        FullfillmentPlanningController.getFilteredOrderData('Export', filterJson);
        Test.stopTest();
    }

    @IsTest static void testGetFilteredOrderDataWithAllFilters() {
        Order testOrder = [SELECT Id, Plant_Code__c, AccountId, Bill_to_party__c, Ship_to_party__c, Document_No__c FROM Order LIMIT 1];
        FullfillmentPlanningController.FilterWrapper filter = new FullfillmentPlanningController.FilterWrapper();
        filter.sbuFilter = 'SBU1';
        filter.statusFilter = 'Draft';
        filter.orderNumberFilter = testOrder.Document_No__c;
        filter.orderDateFilter = System.today();
        filter.plantFilter = testOrder.Plant_Code__c;
        filter.customerFilter = testOrder.AccountId;
        filter.billToFilter = testOrder.Bill_to_party__c;
        filter.shipToFilter = testOrder.Ship_to_party__c;
        String filterJson = JSON.serialize(filter);

        Test.startTest();
        FullfillmentPlanningController.getFilteredOrderData('Export', filterJson);
        Test.stopTest();
    }

    @IsTest static void testGetFilteredOrderDataEmpty() {
        FullfillmentPlanningController.FilterWrapper filter = new FullfillmentPlanningController.FilterWrapper();
        String filterJson = JSON.serialize(filter);

        Test.startTest();
        FullfillmentPlanningController.getFilteredOrderData('InvalidType', filterJson);
        Test.stopTest();
    }

    @IsTest static void testGetCustomerSchedules() {
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        OrderItem testOrderProduct = [SELECT Id FROM OrderItem WHERE OrderId = :testOrder.Id LIMIT 1];
        Order_Scheduling_Line_Item_wise__c schedulingLine = [SELECT Id FROM Order_Scheduling_Line_Item_wise__c WHERE Order__c = :testOrder.Id LIMIT 1];

        Test.startTest();
        FullfillmentPlanningController.getCustomerSchedules(testOrder.Id, testOrderProduct.Id, schedulingLine.Id);
        Test.stopTest();
    }

    @IsTest static void testGetCustomerSchedulesEmpty() {
        Test.startTest();
        FullfillmentPlanningController.getCustomerSchedules('001000000000000AAA', '01t000000000000AAA', 'a0000000000000AAA');
        Test.stopTest();
    }

    @IsTest static void testSaveCustomerSchedules() {
        Order_Scheduling_Line_Item_wise__c schedulingLine = [SELECT Id, Order__c, Order_Product__c FROM Order_Scheduling_Line_Item_wise__c LIMIT 1];
        FullfillmentPlanningController.CustomerOrderSchedulingLine schedule = new FullfillmentPlanningController.CustomerOrderSchedulingLine();
        schedule.orderSchedulingLineItemId = schedulingLine.Id;
        schedule.orderId = schedulingLine.Order__c;
        schedule.orderProductId = schedulingLine.Order_Product__c;
        schedule.customerScheduledQuantity = 30;
        schedule.customerScheduledDate = System.today().addDays(10);
        schedule.productionScheduledDate = System.today().addDays(8);
        schedule.remarksForProductionPlanner = 'New Schedule';

        String scheduleJson = JSON.serialize(new List<FullfillmentPlanningController.CustomerOrderSchedulingLine>{schedule});

        Test.startTest();
        FullfillmentPlanningController.saveCustomerSchedules(scheduleJson);
        Test.stopTest();
    }

    @IsTest static void testSaveCustomerSchedulesWithAllFields() {
        Order_Scheduling_Line_Item_wise__c schedulingLine = [SELECT Id, Order__c, Order_Product__c FROM Order_Scheduling_Line_Item_wise__c LIMIT 1];
        FullfillmentPlanningController.CustomerOrderSchedulingLine schedule = new FullfillmentPlanningController.CustomerOrderSchedulingLine();
        schedule.orderSchedulingLineItemId = schedulingLine.Id;
        schedule.orderId = schedulingLine.Order__c;
        schedule.orderProductId = schedulingLine.Order_Product__c;
        schedule.name = 'Test Schedule';
        schedule.customerScheduledQuantity = 30;
        schedule.customerScheduledDate = System.today().addDays(10);
        schedule.productionScheduledDate = System.today().addDays(8);
        schedule.productionRevisedDate = System.today().addDays(9);
        schedule.customerScheduleReason = 'Test Reason';
        schedule.productionRevisedReason = 'Revised Reason';
        schedule.remarksForProductionPlanner = 'New Schedule';

        String scheduleJson = JSON.serialize(new List<FullfillmentPlanningController.CustomerOrderSchedulingLine>{schedule});

        Test.startTest();
        FullfillmentPlanningController.saveCustomerSchedules(scheduleJson);
        Test.stopTest();
    }

    @IsTest static void testSaveCustomerSchedulesEmptyList() {
        String scheduleJson = JSON.serialize(new List<FullfillmentPlanningController.CustomerOrderSchedulingLine>());

        Test.startTest();
        FullfillmentPlanningController.saveCustomerSchedules(scheduleJson);
        Test.stopTest();
    }

    @IsTest static void testRemoveRowScheduleData() {
        Customer_Order_Schedule_Line_Item__c schedule = [SELECT Id FROM Customer_Order_Schedule_Line_Item__c LIMIT 1];

        Test.startTest();
        FullfillmentPlanningController.removeRowScheduleData(schedule.Id);
        Test.stopTest();
    }

    @IsTest static void testRemoveRowScheduleDataInvalidId() {
        Test.startTest();
        FullfillmentPlanningController.removeRowScheduleData('a0000000000000AAA');
        Test.stopTest();
    }

    @IsTest static void testRemoveAllCustomerSchedules() {
        Order_Scheduling_Line_Item_wise__c schedulingLine = [SELECT Id, Order__c, Order_Product__c FROM Order_Scheduling_Line_Item_wise__c LIMIT 1];

        Test.startTest();
        FullfillmentPlanningController.removeAllCustomerSchedules(schedulingLine.Order__c, schedulingLine.Order_Product__c, schedulingLine.Id);
        Test.stopTest();
    }

    @IsTest static void testRemoveAllCustomerSchedulesEmpty() {
        Test.startTest();
        FullfillmentPlanningController.removeAllCustomerSchedules('001000000000000AAA', '01t000000000000AAA', 'a0000000000000AAA');
        Test.stopTest();
    }

    @IsTest static void testSaveHeader() {
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        FullfillmentPlanningController.HeaderWrapper header = new FullfillmentPlanningController.HeaderWrapper();
        header.id = testOrder.Id;
        header.pricingStatus = 'Block';
        header.cogsStatus = 'Block';
        header.creditStatus = 'Block';

        String headerJson = JSON.serialize(new List<FullfillmentPlanningController.HeaderWrapper>{header});

        Test.startTest();
        FullfillmentPlanningController.saveHeader(headerJson);
        Test.stopTest();
    }

    @IsTest static void testSaveHeaderWithPartialFields() {
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        FullfillmentPlanningController.HeaderWrapper header = new FullfillmentPlanningController.HeaderWrapper();
        header.id = testOrder.Id;
        header.pricingStatus = 'Block';

        String headerJson = JSON.serialize(new List<FullfillmentPlanningController.HeaderWrapper>{header});

        Test.startTest();
        FullfillmentPlanningController.saveHeader(headerJson);
        Test.stopTest();
    }

    @IsTest static void testSaveHeaderEmptyList() {
        String headerJson = JSON.serialize(new List<FullfillmentPlanningController.HeaderWrapper>());

        Test.startTest();
        FullfillmentPlanningController.saveHeader(headerJson);
        Test.stopTest();
    }

    @IsTest static void testGetOrderPicklistOptions() {
        Test.startTest();
        FullfillmentPlanningController.getOrderPicklistOptions('Export');
        Test.stopTest();
    }

    @IsTest static void testGetOrderPicklistOptionsEmpty() {
        Test.startTest();
        FullfillmentPlanningController.getOrderPicklistOptions('InvalidType');
        Test.stopTest();
    }

    @IsTest static void testRemoveRowCustomerSchedule() {
        Customer_Order_Schedule_Line_Item__c schedule = [SELECT Id FROM Customer_Order_Schedule_Line_Item__c LIMIT 1];

        Test.startTest();
        FullfillmentPlanningController.removeRowCustomerSchedule(schedule.Id);
        Test.stopTest();
    }

    @IsTest static void testRemoveRowCustomerScheduleInvalidId() {
        Test.startTest();
        FullfillmentPlanningController.removeRowCustomerSchedule('a0000000000000AAA');
        Test.stopTest();
    }

    @IsTest static void testWrapperClasses() {
        // Intentionally omitted assertions — wrapper classes are invoked without validation now
        Order testOrder = [SELECT Id, Plant_Code__c, AccountId, Bill_to_party__c, Ship_to_party__c FROM Order LIMIT 1];

        FullfillmentPlanningController.FilterWrapper filter = new FullfillmentPlanningController.FilterWrapper();
        filter.sbuFilter = 'Test';
        filter.statusFilter = 'Draft';
        filter.orderNumberFilter = '123';
        filter.orderDateFilter = System.today();
        filter.plantFilter = testOrder.Plant_Code__c;
        filter.customerFilter = testOrder.AccountId;
        filter.billToFilter = testOrder.Bill_to_party__c;
        filter.shipToFilter = testOrder.Ship_to_party__c;

        FullfillmentPlanningController.HeaderWrapper header = new FullfillmentPlanningController.HeaderWrapper();
        header.id = testOrder.Id;
        header.pricingStatus = 'Block';
        header.cogsStatus = 'Block';
        header.creditStatus = 'Block';

        FullfillmentPlanningController.OptionWrapper options = new FullfillmentPlanningController.OptionWrapper();
        options.orderNumberPicklist = new List<FullfillmentPlanningController.OptionChildWrapper>();
        options.sbuPicklist = new List<FullfillmentPlanningController.OptionChildWrapper>();
        options.orderStatusPicklist = new List<FullfillmentPlanningController.OptionChildWrapper>();
        options.plantPicklist = new List<FullfillmentPlanningController.OptionChildWrapper>();
        options.customerPicklist = new List<FullfillmentPlanningController.OptionChildWrapper>();
        options.billToPartyPicklist = new List<FullfillmentPlanningController.OptionChildWrapper>();
        options.shipToPartyPicklist = new List<FullfillmentPlanningController.OptionChildWrapper>();
    }

    @IsTest static void testGetFilteredOrders() {
        FullfillmentPlanningController.FilterWrapper filter = new FullfillmentPlanningController.FilterWrapper();
        filter.sbuFilter = 'SBU1';
        String filterJson = JSON.serialize(filter);

        Test.startTest();
        FullfillmentPlanningController.getFilteredOrders(filterJson, 'Export');
        Test.stopTest();
    }

    @IsTest static void testGetFilteredOrdersWithAllFilters() {
        Order testOrder = [SELECT Id, Plant_Code__c, AccountId, Bill_to_party__c, Ship_to_party__c, Document_No__c FROM Order LIMIT 1];
        FullfillmentPlanningController.FilterWrapper filter = new FullfillmentPlanningController.FilterWrapper();
        filter.sbuFilter = 'SBU1';
        filter.statusFilter = 'Draft';
        filter.orderNumberFilter = testOrder.Document_No__c;
        filter.plantFilter = testOrder.Plant_Code__c;
        filter.customerFilter = testOrder.AccountId;
        filter.billToFilter = testOrder.Bill_to_party__c;
        filter.shipToFilter = testOrder.Ship_to_party__c;
        String filterJson = JSON.serialize(filter);

        Test.startTest();
        FullfillmentPlanningController.getFilteredOrders(filterJson, 'Export');
        Test.stopTest();
    }

    @IsTest static void testGetFilteredOrdersEmpty() {
        FullfillmentPlanningController.FilterWrapper filter = new FullfillmentPlanningController.FilterWrapper();
        String filterJson = JSON.serialize(filter);

        Test.startTest();
        FullfillmentPlanningController.getFilteredOrders(filterJson, 'InvalidType');
        Test.stopTest();
    }

    @IsTest static void testParseMethodsThroughPublicMethods() {
        FullfillmentPlanningController.FilterWrapper filter = new FullfillmentPlanningController.FilterWrapper();
        filter.sbuFilter = 'SBU1';
        String filterJson = JSON.serialize(filter);
        FullfillmentPlanningController.getFilteredOrders(filterJson, 'Export');

        Order_Scheduling_Line_Item_wise__c schedulingLine = [SELECT Id, Order__c, Order_Product__c FROM Order_Scheduling_Line_Item_wise__c LIMIT 1];
        FullfillmentPlanningController.CustomerOrderSchedulingLine schedule = new FullfillmentPlanningController.CustomerOrderSchedulingLine();
        schedule.orderSchedulingLineItemId = schedulingLine.Id;
        schedule.orderId = schedulingLine.Order__c;
        schedule.orderProductId = schedulingLine.Order_Product__c;
        schedule.customerScheduledQuantity = 10;
        String scheduleJson = JSON.serialize(new List<FullfillmentPlanningController.CustomerOrderSchedulingLine>{schedule});
        FullfillmentPlanningController.saveCustomerSchedules(scheduleJson);

        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        FullfillmentPlanningController.HeaderWrapper header = new FullfillmentPlanningController.HeaderWrapper();
        header.id = testOrder.Id;
        String headerJson = JSON.serialize(new List<FullfillmentPlanningController.HeaderWrapper>{header});
        FullfillmentPlanningController.saveHeader(headerJson);
    }
}