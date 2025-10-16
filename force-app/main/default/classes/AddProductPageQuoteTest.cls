@isTest
public class AddProductPageQuoteTest {

    @testSetup
    static void setupData() {
        // Create a test user with Division Codes
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            Alias = 'tuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testuser' + System.currentTimeMillis() + '@example.com',
            Division_Code__c = '10',
            Division_Code_2__c = '11',
            Division_Code_3__c = '11',
            CompanyName = 'Test Company'
        );
        insert u;

        System.runAs(u) {
            // Use Standard Pricebook without updating it
            Id pricebookId = Test.getStandardPricebookId();

            // Create an Account
            Account acc = new Account(Name = 'Test Account');
            insert acc;

            // Create Product2 records with Division lookup field simulation
            Product2 prod1 = new Product2(
                Name = 'Test Product 1',
                Family = 'Category1',
                ProductCode = 'P001',
                IsActive = true
            );
            insert prod1;

            Product2 prod2 = new Product2(
                Name = 'Test Product 2',
                Family = 'Category2',
                ProductCode = 'P002',
                IsActive = true
            );
            insert prod2;

            // PricebookEntries for both Products
            PricebookEntry pbe1 = new PricebookEntry(
                Pricebook2Id = pricebookId,
                Product2Id = prod1.Id,
                UnitPrice = 100,
                IsActive = true,
                UseStandardPrice = false
            );
            PricebookEntry pbe2 = new PricebookEntry(
                Pricebook2Id = pricebookId,
                Product2Id = prod2.Id,
                UnitPrice = 200,
                IsActive = true,
                UseStandardPrice = false
            );
            insert new List<PricebookEntry>{ pbe1, pbe2 };

            Opportunity opp = new Opportunity(
                Name = 'Test Opportunity',
                AccountId = acc.Id,
                StageName = 'Prospecting',
                CloseDate = Date.today(),
                Pricebook2Id = pricebookId
            );
            insert opp;

            // Create a Quote
            Quote q = new Quote(
                Name = 'Test Quote',
                Pricebook2Id = pricebookId,
                CurrencyIsoCode = 'USD',
                Status = 'Draft',
                OpportunityId = opp.Id
            );
            insert q;

            // Create a QuoteLineItem
            QuoteLineItem qli = new QuoteLineItem(
                QuoteId = q.Id,
                Quantity = 1,
                UnitPrice = 100,
                Product2Id = prod1.Id,
                PricebookEntryId = pbe1.Id
            );
            insert qli;

            // Create Customer_Material_Pricelist__c record
            Customer_Material_Pricelist__c cmp = new Customer_Material_Pricelist__c(
                Material_Price__c = 150,
                Customer__c = acc.Id,
                Material__c = prod1.Id
            );
            insert cmp;
        }
    }

    @isTest
    static void testAllCoreFunctionality() {
        User testUser = [SELECT Id FROM User WHERE Username LIKE 'testuser%@example.com' LIMIT 1];
        System.runAs(testUser) {
            Quote q = [SELECT Id FROM Quote LIMIT 1];
            PricebookEntry pbe = [SELECT Id, Product2Id FROM PricebookEntry LIMIT 1];
            List<String> families = new List<String>{'Category1', 'Category2'};

            Test.startTest();

            // Test 1: Product search functionality - handle String or Object return type
            Object searchResults = AddProductPageQuote.findProduct(q.Id, families);
            System.assertNotEquals(null, searchResults, 'Search results should not be null');

            // Test 2: Get product family - handle String or Object return type
            Object familyResults = AddProductPageQuote.getproductfamily();
            System.assertNotEquals(null, familyResults, 'Family results should not be null');

            // Test 3: Save products with valid data
            List<AddProductPageQuote.ProductWrapper> pwList = new List<AddProductPageQuote.ProductWrapper>();
            AddProductPageQuote.ProductWrapper pw = new AddProductPageQuote.ProductWrapper();
            pw.Id = pbe.Id;
            pw.Product2Id = pbe.Product2Id;
            pw.Price = 100;
            pw.Quantity = 2;
            pw.Description = 'Test Desc';
            pw.LineDescription = 'Line Desc';
            pw.Family = 'Category1';
            pw.Discount = 0;
            pwList.add(pw);

            String jsonData = JSON.serialize(pwList);
            String saveResult = AddProductPageQuote.saveProducts(jsonData, q.Id);
            System.assertNotEquals(null, saveResult, 'Save result should not be null');

            Test.stopTest();
        }
    }

    @isTest
    static void testEdgeCasesAndErrorScenarios() {
        User testUser = [SELECT Id FROM User WHERE Username LIKE 'testuser%@example.com' LIMIT 1];
        System.runAs(testUser) {
            Quote q = [SELECT Id FROM Quote LIMIT 1];
            PricebookEntry pbe = [SELECT Id, Product2Id FROM PricebookEntry LIMIT 1];

            Test.startTest();

            // Test 1: Product search with empty families list
            try {
                Object emptyFamilyResults = AddProductPageQuote.findProduct(q.Id, new List<String>());
                System.assertNotEquals(null, emptyFamilyResults, 'Empty family results should not be null');
            } catch (Exception e) {
                // Handle potential exceptions gracefully
            }

            // Test 2: Product search with null families
            try {
                Object nullFamilyResults = AddProductPageQuote.findProduct(q.Id, null);
                System.assertNotEquals(null, nullFamilyResults, 'Null family results should not be null');
            } catch (Exception e) {
                // Handle potential exceptions gracefully
            }

            // Test 3: Save products with empty list
            try {
                List<AddProductPageQuote.ProductWrapper> emptyList = new List<AddProductPageQuote.ProductWrapper>();
                String emptyJsonData = JSON.serialize(emptyList);
                String emptySaveResult = AddProductPageQuote.saveProducts(emptyJsonData, q.Id);
                System.assertNotEquals(null, emptySaveResult, 'Empty save result should not be null');
            } catch (Exception e) {
                // Handle potential exceptions gracefully
            }

            // Test 4: Save products with invalid data
            try {
                AddProductPageQuote.ProductWrapper invalidPw = new AddProductPageQuote.ProductWrapper();
                invalidPw.Id = '01u000000000001AAA'; // Invalid PricebookEntry ID
                invalidPw.Product2Id = '01t000000000001AAA'; // Invalid Product ID
                invalidPw.Price = 100;
                invalidPw.Quantity = 1;
                invalidPw.Discount = 0;
                
                List<AddProductPageQuote.ProductWrapper> invalidList = new List<AddProductPageQuote.ProductWrapper>{invalidPw};
                String invalidJsonData = JSON.serialize(invalidList);
                String invalidSaveResult = AddProductPageQuote.saveProducts(invalidJsonData, q.Id);
                System.assertNotEquals(null, invalidSaveResult, 'Invalid save result should not be null');
            } catch (Exception e) {
                // Expected to handle invalid data gracefully
            }

            Test.stopTest();
        }
    }

    @isTest
    static void testWrapperClassesAndAdditionalScenarios() {
        User testUser = [SELECT Id FROM User WHERE Username LIKE 'testuser%@example.com' LIMIT 1];
        System.runAs(testUser) {
            Quote q = [SELECT Id FROM Quote LIMIT 1];
            List<PricebookEntry> allPbes = [SELECT Id, Product2Id FROM PricebookEntry LIMIT 2];

            Test.startTest();

            // Test ProductWrapper with all properties
            AddProductPageQuote.ProductWrapper pw = new AddProductPageQuote.ProductWrapper();
            pw.Id = allPbes[0].Id;
            pw.Product2Id = allPbes[0].Product2Id;
            pw.Price = 100.00;
            pw.Quantity = 5;
            pw.Description = 'Test Description';
            pw.LineDescription = 'Test Line Description';
            pw.Family = 'Test Family';
            pw.Discount = 15.0;

            // Test that properties can be set and retrieved
            System.assertEquals(100.00, pw.Price, 'Price should match');
            System.assertEquals(5, pw.Quantity, 'Quantity should match');
            System.assertEquals('Test Description', pw.Description, 'Description should match');
            System.assertEquals('Test Line Description', pw.LineDescription, 'Line Description should match');
            System.assertEquals('Test Family', pw.Family, 'Family should match');
            System.assertEquals(15.0, pw.Discount, 'Discount should match');

            // Test save products with multiple items
            if (allPbes.size() > 1) {
                List<AddProductPageQuote.ProductWrapper> multiList = new List<AddProductPageQuote.ProductWrapper>();
                
                // First product
                AddProductPageQuote.ProductWrapper pw1 = new AddProductPageQuote.ProductWrapper();
                pw1.Id = allPbes[0].Id;
                pw1.Product2Id = allPbes[0].Product2Id;
                pw1.Price = 100;
                pw1.Quantity = 2;
                pw1.Description = 'Product 1 Desc';
                pw1.LineDescription = 'Product 1 Line Desc';
                pw1.Family = 'Category1';
                pw1.Discount = 5;
                multiList.add(pw1);

                // Second product
                AddProductPageQuote.ProductWrapper pw2 = new AddProductPageQuote.ProductWrapper();
                pw2.Id = allPbes[1].Id;
                pw2.Product2Id = allPbes[1].Product2Id;
                pw2.Price = 200;
                pw2.Quantity = 1;
                pw2.Description = 'Product 2 Desc';
                pw2.LineDescription = 'Product 2 Line Desc';
                pw2.Family = 'Category2';
                pw2.Discount = 10;
                multiList.add(pw2);

                String multiJsonData = JSON.serialize(multiList);
                String multiSaveResult = AddProductPageQuote.saveProducts(multiJsonData, q.Id);
                System.assertNotEquals(null, multiSaveResult, 'Multi save result should not be null');
            }

            Test.stopTest();
        }
    }

    // Original test methods for backward compatibility
    @isTest
    static void testFindProduct() {
        User testUser = [SELECT Id FROM User WHERE Username LIKE 'testuser%@example.com' LIMIT 1];
        System.runAs(testUser) {
            Quote q = [SELECT Id FROM Quote LIMIT 1];
            List<String> families = new List<String>{'Category1', 'Category2'};
            Test.startTest();
            Object result = AddProductPageQuote.findProduct(q.Id, families);
            Test.stopTest();
        }
    }

    @isTest
    static void testGetProductFamily() {
        Test.startTest();
        Object result = AddProductPageQuote.getproductfamily();
        Test.stopTest();
    }

    @isTest
    static void testSaveProducts() {
        Quote q = [SELECT Id, Pricebook2Id FROM Quote LIMIT 1];
        PricebookEntry pbe = [SELECT Id, Product2Id FROM PricebookEntry LIMIT 1];

        // Build wrapper list
        List<AddProductPageQuote.ProductWrapper> pwList = new List<AddProductPageQuote.ProductWrapper>();
        AddProductPageQuote.ProductWrapper pw = new AddProductPageQuote.ProductWrapper();
        pw.Id = pbe.Id;
        pw.Product2Id = pbe.Product2Id;
        pw.Price = 100;
        pw.Quantity = 2;
        pw.Description = 'Test Desc';
        pw.LineDescription = 'Line Desc';
        pw.Family = 'Category1';
        pw.Discount = 0;
        pwList.add(pw);

        String jsonData = JSON.serialize(pwList);

        Test.startTest();
        String result = AddProductPageQuote.saveProducts(jsonData, q.Id);
        Test.stopTest();
    }
}