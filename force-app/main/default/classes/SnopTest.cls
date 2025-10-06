@isTest
public class SnopTest {

    @isTest
    static void testGetOrdersWithLineItems() {
        // Create Account with Business_Type__c = 'Domestic'
        Account acc = new Account(Name = 'Test Account', Business_Type__c = 'Domestic');
        insert acc;

        // Create Ship To and Bill To Address
        Address_Information__c shipToAddress = new Address_Information__c(
            Name = 'Ship To Address',
            Account__c = acc.Id,
            Address_Type__c = 'Payer'
        );
        insert shipToAddress;

        Address_Information__c billToAddress = new Address_Information__c(
            Name = 'Bill To Address',
            Account__c = acc.Id,
            Address_Type__c = 'Payer'
        );
        insert billToAddress;

        // Get Standard Pricebook ID
        Id stdPBId = Test.getStandardPricebookId();

        // Insert active Product2
        Product2 p = new Product2(Name = 'Test Product', ProductCode = 'TP001', IsActive = true);
        insert p;

        // Insert PricebookEntry in Standard Pricebook with CurrencyIsoCode (optional if multicurrency)
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = stdPBId,
            Product2Id = p.Id,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false
            // Optionally add CurrencyIsoCode = 'USD' if multicurrency enabled
        );
        insert pbe;

        // Create Order
        Order ord = new Order(
            AccountId = acc.Id,
            SBU__c = 'SBU1',
            Ship_to_party__c = shipToAddress.Id,
            Bill_to_party__c = billToAddress.Id,
            Pricing_Status__c = 'Block',
            COGS_Status__c = 'Block',
            Credit_Status__c = 'Block',
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Document_No__c = 'DOC001',
            Name = 'Test Order',
            Pricebook2Id = stdPBId
        );
        insert ord;

        // Create OrderItem — must have PricebookEntryId, Product2Id is optional here
        OrderItem oi = new OrderItem(
            OrderId = ord.Id, 
            Quantity = 5, 
            UnitPrice = 100, 
            PricebookEntryId = pbe.Id
        );
        insert oi;

        // Create Order Scheduling Line Item Wise record
        Order_Scheduling_Line_Item_wise__c li = new Order_Scheduling_Line_Item_wise__c(
            Order__c = ord.Id,
            Order_Product__c = oi.Id,
            Confirmed_Quantity__c = 3,
            Scheduled_Quantity__c = 2,
            Delivery_Date__c = Date.today().addDays(5)
        );
        insert li;

        Test.startTest();
        Snop.getOrdersWithLineItems('Domestic');
        Test.stopTest();
    }

    @isTest
    static void testSaveHeader() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Address_Information__c shipToAddress = new Address_Information__c(
            Name = 'Ship To Address',
            Account__c = acc.Id,
            Address_Type__c = 'Payer'
        );
        insert shipToAddress;

        Address_Information__c billToAddress = new Address_Information__c(
            Name = 'Bill To Address',
            Account__c = acc.Id,
            Address_Type__c = 'Payer'
        );
        insert billToAddress;

        Order ord = new Order(
            AccountId = acc.Id,
            Ship_to_party__c = shipToAddress.Id,
            Bill_to_party__c = billToAddress.Id,
            Pricing_Status__c = 'Block',
            COGS_Status__c = 'Block',
            Credit_Status__c = 'Block',
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Name = 'Test Order'
        );
        insert ord;

        String jsonString = '[{"id":"' + ord.Id + '","pricingStatus":"Block","cogsStatus":"Block","creditStatus":"Block"}]';

        Test.startTest();
        Snop.saveHeader(jsonString);
        Test.stopTest();
    }

    @isTest
    static void testGetOrderPicklistOptions() {
        Account acc = new Account(Name = 'Test Account', Business_Type__c = 'Domestic');
        insert acc;

        Address_Information__c shipToAddress = new Address_Information__c(
            Name = 'Ship To Address',
            Account__c = acc.Id,
            Address_Type__c = 'Payer'
        );
        insert shipToAddress;

        Address_Information__c billToAddress = new Address_Information__c(
            Name = 'Bill To Address',
            Account__c = acc.Id,
            Address_Type__c = 'Payer'
        );
        insert billToAddress;

        Order ord = new Order(
            AccountId = acc.Id,
            Bill_to_party__c = billToAddress.Id,
            Ship_to_party__c = shipToAddress.Id,
            SBU__c = 'SBU1',
            Status = 'Draft',
            EffectiveDate = Date.today(),
            Name = 'Test Order'
        );
        insert ord;

        Test.startTest();
        Snop.getOrderPicklistOptions('Domestic');
        Test.stopTest();
    }
}