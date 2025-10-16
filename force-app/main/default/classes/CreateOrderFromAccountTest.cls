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

        Id standardPricebookId = Test.getStandardPricebookId();

        Product2 prod = new Product2(
            Name = 'Test Product',
            IsActive = true,
            ProductCode = 'TP001',
            CurrencyIsoCode = 'USD'
        );
        insert prod;

        PricebookEntry standardPbe = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true,
            CurrencyIsoCode = 'USD',
            UseStandardPrice = false
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
            CurrencyIsoCode = 'USD',
            UseStandardPrice = false
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
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        
        PricebookEntry pbe = [SELECT Id, Product2Id, Pricebook2Id, UnitPrice FROM PricebookEntry 
                             WHERE Product2Id = :prod.Id AND IsActive = true 
                             AND CurrencyIsoCode = 'USD' LIMIT 1];

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

        Map<String, Object> initialDataWithOrder = CreateOrderFromAccount.getInitialData(acc.Id, ord.Id);
        Map<String, Object> initialDataWithoutOrder = CreateOrderFromAccount.getInitialData(acc.Id, null);
        try {
            Map<String, Object> initialDataNull = CreateOrderFromAccount.getInitialData(null, null);
        } catch (Exception e) {}

        List<Map<String, String>> existingOrders = CreateOrderFromAccount.getExistingOrdersForAccount(acc.Id);

        Account emptyAcc = new Account(Name = 'No Order Account');
        insert emptyAcc;
        List<Map<String, String>> emptyOrders = CreateOrderFromAccount.getExistingOrdersForAccount(emptyAcc.Id);

        Order orderHeader = CreateOrderFromAccount.getOrderHeader(ord.Id);
        try {
            Order nullOrderHeader = CreateOrderFromAccount.getOrderHeader(null);
        } catch (Exception e) {}

        List<Map<String, Object>> orderItemsResult = CreateOrderFromAccount.getOrderItems(ord.Id);

        try {
            Id defaultPricebook = CreateOrderFromAccount.getDefaultPricebookForOrder();
        } catch (Exception e) {
            System.debug('No active standard pricebook found: ' + e.getMessage());
        }

        Map<String, String> pricebookValidation = CreateOrderFromAccount.validatePricebookEntries(
            pbe.Pricebook2Id, 'USD', new List<Id>{pbe.Product2Id});

        Id createFromExisting = CreateOrderFromAccount.createOrderFromExisting(
            ord.Id, orderItems, 'Draft', Date.today(), null, 'USD', pbe.Pricebook2Id, null
        );

        Id createNewOrder = CreateOrderFromAccount.createOrderFromExisting(
            null, orderItems, 'Draft', Date.today(), null, 'USD', pbe.Pricebook2Id, acc.Id
        );

        Test.stopTest();
    }

    @IsTest
    static void testErrorScenariosAndEdgeCases() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        PricebookEntry pbe = [SELECT Id, Product2Id, Pricebook2Id FROM PricebookEntry 
                             WHERE Product2Id = :prod.Id AND IsActive = true LIMIT 1];

        Test.startTest();

        try {
            Id invalidOrderResult = CreateOrderFromAccount.createOrderFromExisting(
                'invalidOrderId',
                new List<Map<String, Object>>{
                    new Map<String, Object>{
                        'Product2Id' => pbe.Product2Id,
                        'PricebookEntryId' => pbe.Id,
                        'UnitPrice' => 100,
                        'Quantity' => 1,
                        'Discount' => 0,
                        'Description' => 'Test Item'
                    }
                },
                'Draft',
                Date.today(),
                null,
                'USD',
                pbe.Pricebook2Id,
                acc.Id
            );
        } catch (Exception e) {}

        try {
            Id invalidAccountResult = CreateOrderFromAccount.createOrderFromExisting(
                null,
                new List<Map<String, Object>>{
                    new Map<String, Object>{
                        'Product2Id' => pbe.Product2Id,
                        'PricebookEntryId' => pbe.Id,
                        'UnitPrice' => 100,
                        'Quantity' => 1,
                        'Discount' => 0,
                        'Description' => 'Test Item'
                    }
                },
                'Draft',
                Date.today(),
                null,
                'USD',
                pbe.Pricebook2Id,
                'invalidAccountId'
            );
        } catch (Exception e) {}

        try {
            Id emptyItemsResult = CreateOrderFromAccount.createOrderFromExisting(
                null,
                new List<Map<String, Object>>(),
                'Draft',
                Date.today(),
                null,
                'USD',
                pbe.Pricebook2Id,
                acc.Id
            );
        } catch (Exception e) {}

        try {
            Map<String, String> invalidPricebookValidation = CreateOrderFromAccount.validatePricebookEntries(
                'invalidPricebookId',
                'USD',
                new List<Id>{pbe.Product2Id}
            );
        } catch (Exception e) {}

        Map<String, String> emptyProductsValidation = CreateOrderFromAccount.validatePricebookEntries(
            pbe.Pricebook2Id,
            'USD',
            new List<Id>()
        );

        Test.stopTest();
    }

    @IsTest
    static void testAdditionalMethods() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();

        List<Contact> contacts = CreateOrderFromAccount.getContactsForAccount(acc.Id);
        String accountCurrency = CreateOrderFromAccount.getAccountCurrency(acc.Id);
        List<Map<String, String>> statusOptions = CreateOrderFromAccount.getPicklistValues('Order', 'Status');
        List<Map<String, String>> currencyOptions = CreateOrderFromAccount.getPicklistValues('Order', 'CurrencyIsoCode');

        Test.stopTest();
    }
}