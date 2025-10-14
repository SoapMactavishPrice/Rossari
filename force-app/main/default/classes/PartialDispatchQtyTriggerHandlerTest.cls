@isTest
public class PartialDispatchQtyTriggerHandlerTest {

    private static Order createTestOrder() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Order ord = new Order(
            Name = 'Test Order',
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            ContractId = null
        );
        insert ord;
        return ord;
    }

    private static OrderItem createTestOrderItem(Id orderId) {
        
        Account acc = new Account(Name = 'Test Account');
        insert acc;
    
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
        
        Order ord = new Order(
            Name = 'Test Order',
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            ContractId = null,
             Pricebook2Id = standardPricebook.Id
        );
        insert ord;
        //return ord;

        OrderItem oi = new OrderItem(
            OrderId = orderId,
            Quantity = 10,
            UnitPrice = 10,
            PricebookEntryId = pbe.Id
        );
        insert oi;
        return oi;
    }

    @isTest
    static void testAfterInsert() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
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
        
        Order ord = new Order(
            Name = 'Test Order',
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            ContractId = null,
             Pricebook2Id = standardPricebook.Id
        );
        insert ord;
        //return ord;

        OrderItem oi = new OrderItem(
            OrderId = ord.Id,
            Quantity = 10,
            UnitPrice = 10,
            PricebookEntryId = pbe.Id
        );
        insert oi;
        //return oi;
       // Order ord = createTestOrder();
        //OrderItem oi = createTestOrderItem(ord.Id);

        Partial_Disptach_Qty__c pdq = new Partial_Disptach_Qty__c(
            Name = 'Insert PDQ',
            Order_Product__c = oi.Id,
            Disptach_Qty__c = 5
        );
        insert pdq;
    }

    @isTest
    static void testAfterUpdate() {
      Account acc = new Account(Name = 'Test Account');
        insert acc;
        
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
        
        Order ord = new Order(
            Name = 'Test Order',
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            ContractId = null,
             Pricebook2Id = standardPricebook.Id
        );
        insert ord;
        //return ord;

        OrderItem oi = new OrderItem(
            OrderId = ord.Id,
            Quantity = 10,
            UnitPrice = 10,
            PricebookEntryId = pbe.Id
        );
        insert oi;

        Partial_Disptach_Qty__c pdq = new Partial_Disptach_Qty__c(
            Name = 'Update PDQ',
            Order_Product__c = oi.Id,
            Disptach_Qty__c = 5
        );
        insert pdq;

        pdq.Disptach_Qty__c = 8;
        update pdq;
    }

    @isTest
    static void testAfterDelete() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
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
        
        Order ord = new Order(
            Name = 'Test Order',
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            ContractId = null,
            Pricebook2Id = standardPricebook.Id
        );
        insert ord;
        //return ord;

        OrderItem oi = new OrderItem(
            OrderId = ord.Id,
            Quantity = 10,
            UnitPrice = 10,
            PricebookEntryId = pbe.Id
        );
        insert oi;

        Partial_Disptach_Qty__c pdq = new Partial_Disptach_Qty__c(
            Name = 'Delete PDQ',
            Order_Product__c = oi.Id,
            Disptach_Qty__c = 5
        );
        insert pdq;

        delete pdq;
    }
}