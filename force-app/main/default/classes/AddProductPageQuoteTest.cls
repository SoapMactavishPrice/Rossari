@IsTest
public class AddProductPageQuoteTest {

    @testSetup
    static void setupData() {
        List<SObject> recordsToInsert = new List<SObject>();
        
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
        recordsToInsert.add(u);
        
        insert recordsToInsert;
        recordsToInsert.clear();

        System.runAs(u) {
            Pricebook2 stdPb = new Pricebook2(
                Id = Test.getStandardPricebookId(),
                IsActive = true
            );
            try{
                update stdPb;
            }Catch(Exception e){}

            Account acc = new Account(Name = 'Test Account');
            recordsToInsert.add(acc);
            
            insert recordsToInsert;
            recordsToInsert.clear();

            Product2 prod1 = new Product2(
                Name = 'Test Product 1',
                Family = 'Category1',
                ProductCode = 'P001',
                IsActive = true
            );
            recordsToInsert.add(prod1);

            Product2 prod2 = new Product2(
                Name = 'Test Product 2',
                Family = 'Category2',
                ProductCode = 'P002',
                IsActive = true
            );
            recordsToInsert.add(prod2);
            
            insert recordsToInsert;
            recordsToInsert.clear();

            PricebookEntry pbe1 = new PricebookEntry(
                Pricebook2Id = stdPb.Id,
                Product2Id = prod1.Id,
                UnitPrice = 100,
                IsActive = true,
                UseStandardPrice = false
            );
            PricebookEntry pbe2 = new PricebookEntry(
                Pricebook2Id = stdPb.Id,
                Product2Id = prod2.Id,
                UnitPrice = 200,
                IsActive = true,
                UseStandardPrice = false
            );
            recordsToInsert.add(pbe1);
            recordsToInsert.add(pbe2);
            
            insert recordsToInsert;
            recordsToInsert.clear();

            Opportunity opp = new Opportunity(
                Name = 'Test Opportunity',
                AccountId = acc.Id,
                StageName = 'Prospecting',
                CloseDate = Date.today(),
                Pricebook2Id = stdPb.Id
            );
            recordsToInsert.add(opp);
            
            insert recordsToInsert;
            recordsToInsert.clear();

            Quote q = new Quote(
                Name = 'Test Quote',
                Pricebook2Id = stdPb.Id,
                CurrencyIsoCode = 'USD',
                Status = 'Draft',
                OpportunityId = opp.Id
            );
            recordsToInsert.add(q);
            
            insert recordsToInsert;
            recordsToInsert.clear();

            QuoteLineItem qli = new QuoteLineItem(
                QuoteId = q.Id,
                Quantity = 1,
                UnitPrice = 100,
                Product2Id = prod1.Id,
                PricebookEntryId = pbe1.Id
            );
            recordsToInsert.add(qli);
            
            insert recordsToInsert;
            recordsToInsert.clear();

            Customer_Material_Pricelist__c cmp = new Customer_Material_Pricelist__c(
                Material_Price__c = 150,
                Customer__c = acc.Id,
                Material__c = prod1.Id
            );
            recordsToInsert.add(cmp);
            
            insert recordsToInsert;
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

            Object searchResults = AddProductPageQuote.findProduct(q.Id, families);

            Object familyResults = AddProductPageQuote.getproductfamily();

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

            try {
                Object emptyFamilyResults = AddProductPageQuote.findProduct(q.Id, new List<String>());
            } catch (Exception e) {
            }

            try {
                Object nullFamilyResults = AddProductPageQuote.findProduct(q.Id, null);
            } catch (Exception e) {
            }

            try {
                List<AddProductPageQuote.ProductWrapper> emptyList = new List<AddProductPageQuote.ProductWrapper>();
                String emptyJson = JSON.serialize(emptyList);
                String emptySave = AddProductPageQuote.saveProducts(emptyJson, q.Id);
            } catch (Exception e) {
            }

            try {
                AddProductPageQuote.ProductWrapper invalidPw = new AddProductPageQuote.ProductWrapper();
                invalidPw.Id = String.valueOf(Math.abs(Crypto.getRandomInteger()));  
                invalidPw.Product2Id = String.valueOf(Math.abs(Crypto.getRandomInteger()));
                invalidPw.Price = 100;
                invalidPw.Quantity = 1;
                invalidPw.Discount = 0;

                List<AddProductPageQuote.ProductWrapper> invalidList = new List<AddProductPageQuote.ProductWrapper>{invalidPw};
                String invalidJson = JSON.serialize(invalidList);
                String invalidSave = AddProductPageQuote.saveProducts(invalidJson, q.Id);
            } catch (Exception e) {
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

            AddProductPageQuote.ProductWrapper pw = new AddProductPageQuote.ProductWrapper();
            pw.Id = allPbes[0].Id;
            pw.Product2Id = allPbes[0].Product2Id;
            pw.Price = 100.00;
            pw.Quantity = 5;
            pw.Description = 'Test Description';
            pw.LineDescription = 'Test Line Description';
            pw.Family = 'Test Family';
            pw.Discount = 15.0;

            if (allPbes.size() > 1) {
                List<AddProductPageQuote.ProductWrapper> multiList = new List<AddProductPageQuote.ProductWrapper>();

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

                String multiJson = JSON.serialize(multiList);
                String multiSave = AddProductPageQuote.saveProducts(multiJson, q.Id);
            }

            Test.stopTest();
        }
    }

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