@isTest
public class PartialDispatchQtyTriggerHandlerTest {

    @TestSetup
    static void setupStaticData() {
        Base_UoM_Master__c baseUom = new Base_UoM_Master__c(Name = 'Kilogram');
        insert baseUom;
    }

    static void createDynamicTestData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Id standardPricebookId = Test.getStandardPricebookId();

        Base_UoM_Master__c baseUom = [SELECT Id FROM Base_UoM_Master__c WHERE Name = 'Kilogram' LIMIT 1];

        Product2 prod = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP001',
            Pack_Size__c = '10kg',
            Base_UOM__c = baseUom.Id,
            IsActive = true
        );
        insert prod;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        Order ord = new Order(
            Name = 'Test Order',
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            ContractId = null,
            Pricebook2Id = standardPricebookId
        );
        insert ord;

        OrderItem oi = new OrderItem(
            OrderId = ord.Id,
            Quantity = 10,
            UnitPrice = 10,
            PricebookEntryId = pbe.Id
        );
        insert oi;
    }

    @isTest
    static void testAfterInsert() {
        createDynamicTestData();
        
        OrderItem oi = [SELECT Id FROM OrderItem LIMIT 1];
        
        Partial_Disptach_Qty__c pdq = new Partial_Disptach_Qty__c(
            Name = 'Insert PDQ',
            Order_Product__c = oi.Id,
            Disptach_Qty__c = 5
        );
        
        Test.startTest();
        insert pdq;
        Test.stopTest();
    }

    @isTest
    static void testAfterUpdate() {
        createDynamicTestData();
        
        OrderItem oi = [SELECT Id FROM OrderItem LIMIT 1];
        
        Partial_Disptach_Qty__c pdq = new Partial_Disptach_Qty__c(
            Name = 'Update PDQ',
            Order_Product__c = oi.Id,
            Disptach_Qty__c = 5
        );
        insert pdq;

        Test.startTest();
        pdq.Disptach_Qty__c = 8;
        update pdq;
        Test.stopTest();
    }

    @isTest
    static void testAfterDelete() {
        createDynamicTestData();
        
        OrderItem oi = [SELECT Id FROM OrderItem LIMIT 1];
        
        Partial_Disptach_Qty__c pdq = new Partial_Disptach_Qty__c(
            Name = 'Delete PDQ',
            Order_Product__c = oi.Id,
            Disptach_Qty__c = 5
        );
        insert pdq;

        Test.startTest();
        delete pdq;
        Test.stopTest();
    }

    @isTest
    static void testMultiplePartialDispatches() {
        createDynamicTestData();
        
        OrderItem oi = [SELECT Id FROM OrderItem LIMIT 1];
        
        List<Partial_Disptach_Qty__c> pdqList = new List<Partial_Disptach_Qty__c>();
        for(Integer i = 0; i < 5; i++) {
            pdqList.add(new Partial_Disptach_Qty__c(
                Name = 'PDQ ' + i,
                Order_Product__c = oi.Id,
                Disptach_Qty__c = i + 1
            ));
        }

        Test.startTest();
        insert pdqList;
        Test.stopTest();
    }

    @isTest
    static void testBulkUpdate() {
        createDynamicTestData();
        
        OrderItem oi = [SELECT Id FROM OrderItem LIMIT 1];
        
        List<Partial_Disptach_Qty__c> pdqList = new List<Partial_Disptach_Qty__c>();
        for(Integer i = 0; i < 10; i++) {
            pdqList.add(new Partial_Disptach_Qty__c(
                Name = 'Bulk PDQ ' + i,
                Order_Product__c = oi.Id,
                Disptach_Qty__c = i + 1
            ));
        }
        insert pdqList;

        Test.startTest();
        for(Partial_Disptach_Qty__c pdq : pdqList) {
            pdq.Disptach_Qty__c = pdq.Disptach_Qty__c * 2;
        }
        update pdqList;
        Test.stopTest();
    }

    @isTest
    static void testBulkDelete() {
        createDynamicTestData();
        
        OrderItem oi = [SELECT Id FROM OrderItem LIMIT 1];
        
        List<Partial_Disptach_Qty__c> pdqList = new List<Partial_Disptach_Qty__c>();
        for(Integer i = 0; i < 8; i++) {
            pdqList.add(new Partial_Disptach_Qty__c(
                Name = 'Delete PDQ ' + i,
                Order_Product__c = oi.Id,
                Disptach_Qty__c = i + 1
            ));
        }
        insert pdqList;

        Test.startTest();
        delete pdqList;
        Test.stopTest();
    }

    @isTest
    static void testZeroDispatchQty() {
        createDynamicTestData();
        
        OrderItem oi = [SELECT Id FROM OrderItem LIMIT 1];
        
        Partial_Disptach_Qty__c pdq = new Partial_Disptach_Qty__c(
            Name = 'Zero PDQ',
            Order_Product__c = oi.Id,
            Disptach_Qty__c = 0
        );

        Test.startTest();
        insert pdq;
        Test.stopTest();
    }

    @isTest
    static void testWithDispatchQty() {
        createDynamicTestData();
        
        OrderItem oi = [SELECT Id FROM OrderItem LIMIT 1];
        
        Partial_Disptach_Qty__c pdq = new Partial_Disptach_Qty__c(
            Name = 'With Qty PDQ',
            Order_Product__c = oi.Id,
            Disptach_Qty__c = 10
        );

        Test.startTest();
        insert pdq;
        Test.stopTest();
    }

    @isTest
    static void testMultipleOrderItems() {
        createDynamicTestData();
        
        Order ord = [SELECT Id FROM Order LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];
        
        OrderItem oi2 = new OrderItem(
            OrderId = ord.Id,
            Quantity = 15,
            UnitPrice = 20,
            PricebookEntryId = pbe.Id
        );
        insert oi2;
        
        List<OrderItem> orderItems = [SELECT Id FROM OrderItem];
        
        List<Partial_Disptach_Qty__c> pdqList = new List<Partial_Disptach_Qty__c>();
        for(OrderItem oi : orderItems) {
            pdqList.add(new Partial_Disptach_Qty__c(
                Name = 'Multi PDQ',
                Order_Product__c = oi.Id,
                Disptach_Qty__c = 3
            ));
        }

        Test.startTest();
        insert pdqList;
        Test.stopTest();
    }

    @isTest
    static void testWithAdditionalFields() {
        createDynamicTestData();
        
        OrderItem oi = [SELECT Id FROM OrderItem LIMIT 1];
        
        Partial_Disptach_Qty__c pdq = new Partial_Disptach_Qty__c(
            Name = 'Additional Fields PDQ',
            Order_Product__c = oi.Id,
            Disptach_Qty__c = 7,
            Planning_Ready_by_Date__c = Date.today(),
            Planning_Dispatch_Remark__c = 'Test Remark',
            Deviation_Reason__c = 'Test Reason'
        );

        Test.startTest();
        insert pdq;
        Test.stopTest();
    }

    @isTest
    static void testUpdateWithNullFields() {
        createDynamicTestData();
        
        OrderItem oi = [SELECT Id FROM OrderItem LIMIT 1];
        
        Partial_Disptach_Qty__c pdq = new Partial_Disptach_Qty__c(
            Name = 'Update Null PDQ',
            Order_Product__c = oi.Id,
            Disptach_Qty__c = 5
        );
        insert pdq;

        Test.startTest();
        pdq.Planning_Dispatch_Remark__c = null;
        pdq.Deviation_Reason__c = null;
        update pdq;
        Test.stopTest();
    }
}