@IsTest
private class CreateOrderFromAccountTest {
    
    @TestSetup
    static void setupTestData() {
        Account testAccount = new Account(
            Name = 'Test Account', 
            BillingStreet = '123 Test St',
            BillingCity = 'Test City',
            BillingState = 'TS',
            BillingPostalCode = '12345',
            BillingCountry = 'Test Country',
            ShippingStreet = '123 Test St',
            ShippingCity = 'Test City',
            ShippingState = 'TS',
            ShippingPostalCode = '12345',
            ShippingCountry = 'Test Country',
            CurrencyIsoCode = 'USD'
        );
        insert testAccount;

        Contact testContact = new Contact(
            LastName = 'Test Contact', 
            AccountId = testAccount.Id,
            CurrencyIsoCode = 'USD'
        );
        insert testContact;

        Pricebook2 standardPb = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPb;

        Product2 prod = new Product2(
            Name = 'Test Product',
            IsActive = true,
            ProductCode = 'TP001',
            CurrencyIsoCode = 'USD'
        );
        insert prod;

        PricebookEntry standardPbe = new PricebookEntry(
            Pricebook2Id = standardPb.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true,
            CurrencyIsoCode = 'USD'
        );
        insert standardPbe;

        Pricebook2 customPb = new Pricebook2(
            Name = 'Custom Pricebook',
            IsActive = true
        );
        insert customPb;

        PricebookEntry customPbe = new PricebookEntry(
            Pricebook2Id = customPb.Id,
            Product2Id = prod.Id,
            UnitPrice = 120,
            IsActive = true,
            CurrencyIsoCode = 'USD'
        );
        insert customPbe;

        Order testOrder = new Order(
            AccountId = testAccount.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            Pricebook2Id = customPb.Id,
            CurrencyIsoCode = 'USD',
            Name = 'Test Order'
        );
        insert testOrder;

        OrderItem item = new OrderItem(
            OrderId = testOrder.Id,
            PricebookEntryId = customPbe.Id,
            Product2Id = prod.Id,
            Quantity = 2,
            UnitPrice = 120,
            Description = 'Initial OrderItem'
        );
        insert item;
    }

    @IsTest
    static void testAllMethodsInOne() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Order ord = [SELECT Id FROM Order LIMIT 1];
        PricebookEntry pbe = [SELECT Id, Product2Id, Pricebook2Id FROM PricebookEntry WHERE IsActive = true LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];

        List<Map<String, Object>> orderItems = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Product2Id' => pbe.Product2Id,
                'PricebookEntryId' => pbe.Id,
                'UnitPrice' => 110,
                'Quantity' => 3,
                'Discount' => 5,
                'Description' => 'Merged Test Item'
            }
        };

        Test.startTest();

        CreateOrderFromAccount.getInitialData(acc.Id, ord.Id);
        CreateOrderFromAccount.getInitialData(acc.Id, null);

        try {
            CreateOrderFromAccount.getInitialData(null, null);
        } catch (Exception e) {}

        CreateOrderFromAccount.getExistingOrdersForAccount(acc.Id);

        Account emptyAcc = new Account(Name = 'No Order Account');
        insert emptyAcc;
        CreateOrderFromAccount.getExistingOrdersForAccount(emptyAcc.Id);

        CreateOrderFromAccount.getOrderHeader(ord.Id);

        try {
            CreateOrderFromAccount.getOrderHeader(null);
        } catch (Exception e) {}

        CreateOrderFromAccount.getOrderItems(ord.Id);

        CreateOrderFromAccount.getDefaultPricebookForOrder();

        CreateOrderFromAccount.validatePricebookEntries(pbe.Pricebook2Id, 'USD', new List<Id>{pbe.Product2Id});

        CreateOrderFromAccount.createOrderFromExisting(
            ord.Id,
            orderItems,
            'Draft',
            Date.today(),
            null,
            'USD',
            pbe.Pricebook2Id,
            null
        );

        CreateOrderFromAccount.createOrderFromExisting(
            null,
            orderItems,
            'Draft',
            Date.today(),
            null,
            'USD',
            pbe.Pricebook2Id,
            acc.Id
        );

        Test.stopTest();
    }
}