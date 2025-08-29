@isTest
public class SnopTest {

    static Account createAccount(String businessType) {
        Account acc = new Account(Name = 'Test Account', Business_Type__c = businessType);
        insert acc;
        return acc;
    }

    static Order createOrder(Account acc) {
        Order ord = new Order(
            AccountId = acc.Id,
            EffectiveDate = System.today(),
            Status = 'Draft',
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert ord;
        return ord;
    }

    static OrderItem createOrderItem(Order ord, Product2 prod, PricebookEntry pbe) {
        OrderItem oi = new OrderItem(
            OrderId = ord.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert oi;
        return oi;
    }

    static Product2 createProduct() {
        Product2 prod = new Product2(Name = 'Test Product', ProductCode = 'TP1', isActive = true);
        insert prod;
        return prod;
    }

    static PricebookEntry createPricebookEntry(Product2 prod) {
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;
        return pbe;
    }

    static Partial_Disptach_Qty__c createPartialDispatch(Order ord, OrderItem oi) {
        Partial_Disptach_Qty__c pd = new Partial_Disptach_Qty__c(
            Order__c = ord.Id,
            Order_Product__c = oi.Id,
            Disptach_Qty__c = 10,
            Planning_Dispatch_Remark__c = 'Remark',
            Planning_Ready_by_Date__c = System.today(),
            Deviation_Reason__c = 'Reason'
        );
        insert pd;
        return pd;
    }

    @isTest
    static void testSnopMethods() {
        Account acc = createAccount('Export');


        Order ord = createOrder(acc);

        Product2 prod = createProduct();
        PricebookEntry pbe = createPricebookEntry(prod);
        OrderItem oi = createOrderItem(ord, prod, pbe);

        Partial_Disptach_Qty__c pd = createPartialDispatch(ord, oi);

        // getSOData
        Snop.getSOData(acc.Business_Type__c);

        // getSOLineItem
        Snop.getSOLineItem(new List<String>{ord.Id});

        // saveHeader
        String headerJson = '[{"id":"' + ord.Id + '","pricingStatus":"Block","cogsStatus":"Block","creditStatus":"Block"}]';
        Snop.saveHeader(headerJson);

        // getOrderPicklistOptions
        Snop.getOrderPicklistOptions(acc.Business_Type__c);

        // getFilteredOrders
        String filterJson = '{"sbuFilter":"","statusFilter":"Draft","orderNumberFilter":"ORD-001","plantFilter":"","customerFilter":"' + acc.Id + '","billToFilter":"","shipToFilter":""}';
        Snop.getFilteredOrders(filterJson, acc.Business_Type__c);

        // saveline
        String lineJson = '[{"Id":"' + oi.Id + '","OrderId":"' + ord.Id + '","Lead_time__c":"5"}]';
        Snop.saveline(lineJson);

        // savePartialDisptach
        String partJson = '[{"Id":"create1","Planning_Ready_by_Date__c":"' + String.valueOf(System.today()) + '","Disptach_Qty__c":"10","Planning_Dispatch_Remark__c":"Remark","Deviation_Reason__c":"Reason"}]';
        Snop.savePartialDisptach(ord.Id, oi.Id, partJson);

        // getPartialData
        Snop.getPartialData(ord.Id, oi.Id);

        // getDisptachList
        Snop.getDisptachList(lineJson);

        // removeALlPartialData
        Snop.removeALlPartialData(ord.Id, oi.Id);

        // removeRowPartialData
        Snop.removeRowPartialData(pd.Id);

        // replacer
        Snop.replacer(null);
        Snop.replacer('test');
    }
}