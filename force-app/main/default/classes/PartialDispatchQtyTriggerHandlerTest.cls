@IsTest
private class PartialDispatchQtyTriggerHandlerTest {
    
    @TestSetup
    static void setupData() {
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

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Order ord = new Order(
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            Pricebook2Id = standardPricebook.Id
        );
        insert ord;

        OrderItem oi = new OrderItem(
            OrderId = ord.Id,
            Quantity = 10,
            UnitPrice = 100,
            PricebookEntryId = pbe.Id
        );
        insert oi;
    }

    @IsTest
    static void testAfterInsert() {
        OrderItem oi = [SELECT Id FROM OrderItem LIMIT 1];
        List<Partial_Disptach_Qty__c> dispatchList = new List<Partial_Disptach_Qty__c>();
        dispatchList.add(new Partial_Disptach_Qty__c(
            Order_Product__c = oi.Id,
            Disptach_Qty__c = 3
        ));
        insert dispatchList;
    }

    @IsTest
    static void testAfterUpdate() {
        OrderItem oi = [SELECT Id FROM OrderItem LIMIT 1];
        Partial_Disptach_Qty__c dispatch = new Partial_Disptach_Qty__c(
            Order_Product__c = oi.Id,
            Disptach_Qty__c = 2
        );
        insert dispatch;

        dispatch.Disptach_Qty__c = 5;
        update dispatch;
    }

    @IsTest
    static void testAfterDelete() {
        OrderItem oi = [SELECT Id FROM OrderItem LIMIT 1];
        Partial_Disptach_Qty__c dispatch = new Partial_Disptach_Qty__c(
            Order_Product__c = oi.Id,
            Disptach_Qty__c = 4
        );
        insert dispatch;

        delete dispatch;
    }
}