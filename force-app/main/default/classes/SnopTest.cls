@isTest
public class SnopTest {
    
    @testSetup
    static void setupData() {
        Id standardPricebookId = Test.getStandardPricebookId();
        
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
 
        Base_UoM_Master__c baseUom = new Base_UoM_Master__c(Name = 'Kilogram');
        insert baseUom;
 
        Product2 prod = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP001',
            Pack_Size__c = '10kg',
            Base_UOM__c = baseUom.Id,
            IsActive = true
        );
        insert prod;
 
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        
        Account acc = new Account(
            Name = 'Test Account',
            Business_Type__c = 'SEZ'
        );
        insert acc;
        
        Order ord = new Order(
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            SBU__c = 'SBU1',
            Pricing_Status__c = 'Block',
            COGS_Status__c = 'Block',
            Credit_Status__c = 'Block',
            Pricebook2Id = standardPricebookId
        );
        insert ord;
        
        OrderItem oi = new OrderItem(
            OrderId = ord.Id,
            Quantity = 1,
            UnitPrice = 100,
            PricebookEntryId = pbe.Id
        );
        insert oi;
        
        Order_Scheduling_Line_Item_wise__c lineItem = new Order_Scheduling_Line_Item_wise__c(
            Name = 'Test Line Item',
            Confirmed_Quantity__c = 10,
            Scheduled_Quantity__c = 5,
            Delivery_Date__c = Date.today().addDays(7),
            Order__c = ord.Id,
            Order_Product__c = oi.Id
        );
        insert lineItem;
    }
    
    @isTest
    static void testGetOrdersWithLineItems() {
        Test.startTest();
        List<Snop.OrderWrapper> result = Snop.getOrdersWithLineItems('SEZ');
        Test.stopTest();
    }
    
    @isTest
    static void testSaveHeader() {
        Order ord = [SELECT Id FROM Order LIMIT 1];
        List<Snop.HeaderWrapper> headerList = new List<Snop.HeaderWrapper>{ new Snop.HeaderWrapper() };
        headerList[0].id = ord.Id;
        headerList[0].pricingStatus = 'Block';
        headerList[0].cogsStatus = 'Block';
        headerList[0].creditStatus = 'Block';
        
        String jsonStr = JSON.serialize(headerList);
        
        Test.startTest();
        String result = Snop.saveHeader(jsonStr);
        Test.stopTest();
    }
    
    @isTest
    static void testSavePartialDisptach() {
        Order ord = [SELECT Id FROM Order LIMIT 1];
        OrderItem oi = [SELECT Id FROM OrderItem LIMIT 1];
        
        List<Map<String, Object>> listData = new List<Map<String, Object>>();
        listData.add(new Map<String, Object>{
            'Id' => 'create1',
            'Disptach_Qty__c' => 10,
            'Planning_Ready_by_Date__c' => String.valueOf(Date.today()),
            'Planning_Dispatch_Remark__c' => 'Ready',
            'Deviation_Reason__c' => 'Urgent'
        });
        
        String jsonStr = JSON.serialize(listData);
        
        Test.startTest();
        Boolean result = Snop.savePartialDisptach(ord.Id, oi.Id, jsonStr);
        Test.stopTest();
    }
    
    @isTest
    static void testGetPartialData() {
        Order ord = [SELECT Id FROM Order LIMIT 1];
        OrderItem oi = [SELECT Id FROM OrderItem LIMIT 1];
        
        Partial_Disptach_Qty__c pd = new Partial_Disptach_Qty__c(
            Order__c = ord.Id,
            Order_Product__c = oi.Id,
            Disptach_Qty__c = 5,
            Planning_Dispatch_Remark__c = 'Sample'
        );
        insert pd;
        
        Test.startTest();
        List<Partial_Disptach_Qty__c> data = Snop.getPartialData(ord.Id, oi.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testGetDisptachList() {
        Order ord = [SELECT Id FROM Order LIMIT 1];
        OrderItem oi = [SELECT Id FROM OrderItem LIMIT 1];
        
        List<Map<String, Object>> listData = new List<Map<String, Object>>();
        listData.add(new Map<String, Object>{
            'OrderId' => ord.Id,
            'Id' => oi.Id
        });
        
        String jsonStr = JSON.serialize(listData);
        
        Test.startTest();
        List<Partial_Disptach_Qty__c> result = Snop.getDisptachList(jsonStr);
        Test.stopTest();
    }
    
    @isTest
    static void testRemoveALlPartialData() {
        Order ord = [SELECT Id FROM Order LIMIT 1];
        OrderItem oi = [SELECT Id FROM OrderItem LIMIT 1];
        
        Partial_Disptach_Qty__c pd = new Partial_Disptach_Qty__c(
            Order__c = ord.Id,
            Order_Product__c = oi.Id,
            Disptach_Qty__c = 10
        );
        insert pd;
        
        Test.startTest();
        Boolean result = Snop.removeALlPartialData(ord.Id, oi.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testRemoveRowPartialData() {
        Order ord = [SELECT Id FROM Order LIMIT 1];
        OrderItem oi = [SELECT Id FROM OrderItem LIMIT 1];
        
        Partial_Disptach_Qty__c pd = new Partial_Disptach_Qty__c(
            Order__c = ord.Id,
            Order_Product__c = oi.Id,
            Disptach_Qty__c = 5
        );
        insert pd;
        
        Test.startTest();
        Boolean result = Snop.removeRowPartialData(pd.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testSaveline() {
        Order ord = [SELECT Id FROM Order LIMIT 1];
        OrderItem oi = [SELECT Id FROM OrderItem LIMIT 1];
        
        List<Map<String, Object>> listData = new List<Map<String, Object>>();
        listData.add(new Map<String, Object>{
            'OrderId' => ord.Id,
            'Id' => oi.Id,
            'Lead_time__c' => '5 days'
        });
        
        String jsonStr = JSON.serialize(listData);
        
        Test.startTest();
        String result = Snop.saveline(jsonStr);
        Test.stopTest();
    }
    
    @isTest
    static void testGetFilteredOrders() {
        String filterJSON = JSON.serialize(new Map<String, Object>{
            'sbuFilter' => 'SBU1',
            'statusFilter' => 'Draft',
            'orderNumberFilter' => null,
            'plantFilter' => null,
            'customerFilter' => null,
            'billToFilter' => null,
            'shipToFilter' => null
        });

        Test.startTest();
        List<Order> orders = Snop.getFilteredOrders(filterJSON, 'SEZ');
        Test.stopTest();
    }

    @isTest
    static void testGetOrderPicklistOptions() {
        Test.startTest();
        Snop.OptionWrapper picklistOptions = Snop.getOrderPicklistOptions('SEZ');
        Test.stopTest();
    }

    @isTest
    static void testHeaderWrapper() {
        Snop.HeaderWrapper header = new Snop.HeaderWrapper();
        header.id = '001xx000003DGbV';
        header.pricingStatus = 'Block';
        header.cogsStatus = 'Block';
        header.creditStatus = 'Approved';

        String jsonHeader = JSON.serialize(header);
        Snop.HeaderWrapper deserializedHeader = (Snop.HeaderWrapper) JSON.deserialize(jsonHeader, Snop.HeaderWrapper.class);
    }

    @isTest
    static void testOptionWrapperAndChild() {
        Snop.OptionWrapper options = new Snop.OptionWrapper();
        options.orderNumberPicklist = new List<Snop.OptionChildWrapper>();
        options.sbuPicklist = new List<Snop.OptionChildWrapper>();

        options.orderNumberPicklist.add(new Snop.OptionChildWrapper('Order1', '001'));
        options.sbuPicklist.add(new Snop.OptionChildWrapper('SBU1', 'SBU001'));

        String jsonOptions = JSON.serialize(options);
        Snop.OptionWrapper deserializedOptions = (Snop.OptionWrapper) JSON.deserialize(jsonOptions, Snop.OptionWrapper.class);
    }
}