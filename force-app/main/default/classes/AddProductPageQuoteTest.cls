@IsTest
public class AddProductPageQuoteTest {

    @testSetup
    static void setupData() {
        List<SObject> recordsToInsert = new List<SObject>();
        
        // Create Sales Organisation
        Sales_Organisation__c salesOrg = new Sales_Organisation__c(
            Name = '1000'
           
        );
        recordsToInsert.add(salesOrg);
        
        // Create Distribution Channel
        Distribution_Channel__c distChannel = new Distribution_Channel__c(
            Name = 'DC1',
            Distribution_Code__c = 'DC1'
        );
        recordsToInsert.add(distChannel);
        
        // Create Division
        Division__c division = new Division__c(
            Name = '10',
            Division_Code__c = '10'
        );
        recordsToInsert.add(division);
        
        insert recordsToInsert;
        recordsToInsert.clear();
        
        // Get the inserted records with IDs
        salesOrg = [SELECT Id, Name FROM Sales_Organisation__c WHERE Name = '1000' LIMIT 1];
        distChannel = [SELECT Id, Name, Distribution_Code__c FROM Distribution_Channel__c WHERE Name = 'DC1' LIMIT 1];
        division = [SELECT Id, Name, Division_Code__c FROM Division__c WHERE Name = '10' LIMIT 1];

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
            try {
                update stdPb;
            } catch(Exception e) {
                // Handle exception if any
            }

            Account acc = new Account(
                Name = 'Test Account',
                Sales_Organisation__c = salesOrg.Id,
                Distribution_Channel__c = distChannel.Id,
                Division__c = division.Id
            );
            recordsToInsert.add(acc);
            
            insert recordsToInsert;
            recordsToInsert.clear();

            Product2 prod1 = new Product2(
                Name = 'Test Product 1',
                Family = 'Category1',
                ProductCode = 'P001',
                IsActive = true,
                Division__c = division.Id
            );
            recordsToInsert.add(prod1);

            Product2 prod2 = new Product2(
                Name = 'Test Product 2',
                Family = 'Category2',
                ProductCode = 'P002',
                IsActive = true,
                Division__c = division.Id
            );
            recordsToInsert.add(prod2);
            
            insert recordsToInsert;
            recordsToInsert.clear();

            PricebookEntry pbe1 = new PricebookEntry(
                Pricebook2Id = stdPb.Id,
                Product2Id = prod1.Id,
                UnitPrice = 100,
                IsActive = true,
                UseStandardPrice = false,
                CurrencyIsoCode = 'USD'
            );
            PricebookEntry pbe2 = new PricebookEntry(
                Pricebook2Id = stdPb.Id,
                Product2Id = prod2.Id,
                UnitPrice = 200,
                IsActive = true,
                UseStandardPrice = false,
                CurrencyIsoCode = 'USD'
            );
            recordsToInsert.add(pbe1);
            recordsToInsert.add(pbe2);
            
            insert recordsToInsert;
            recordsToInsert.clear();

            // Create Sales Area records - CRITICAL for findProduct method
            Sales_Area__c salesArea1 = new Sales_Area__c(
                Item_Master__c = prod1.Id,
                Sales_Organisation__c = salesOrg.Id,
                Distribution_Channel__c = distChannel.Id
            );
            Sales_Area__c salesArea2 = new Sales_Area__c(
                Item_Master__c = prod2.Id,
                Sales_Organisation__c = salesOrg.Id,
                Distribution_Channel__c = distChannel.Id
            );
            recordsToInsert.add(salesArea1);
            recordsToInsert.add(salesArea2);
            
            insert recordsToInsert;
            recordsToInsert.clear();

            Opportunity opp = new Opportunity(
                Name = 'Test Opportunity',
                AccountId = acc.Id,
                StageName = 'Prospecting',
                CloseDate = Date.today(),
                Pricebook2Id = stdPb.Id,
                Sales_Organisations__c = salesOrg.Id,
                Distribution_Channel__c = distChannel.Id,
                Division__c = division.Id,
                CurrencyIsoCode = 'USD'
            );
            recordsToInsert.add(opp);
            
            insert recordsToInsert;
            recordsToInsert.clear();

            Quote q = new Quote(
                Name = 'Test Quote',
                Pricebook2Id = stdPb.Id,
                CurrencyIsoCode = 'USD',
                Status = 'Draft',
                OpportunityId = opp.Id,
                
                Sales_Organisations__c = salesOrg.Id,
                Distribution_Channel__c = distChannel.Id,
                Division__c = division.Id
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
    static void testFindProduct() {
        // Get the test data
        Sales_Organisation__c so = [SELECT Id, Name FROM Sales_Organisation__c WHERE Name = '1000' LIMIT 1];
        Distribution_Channel__c dc = [SELECT Id, Distribution_Code__c FROM Distribution_Channel__c WHERE Name = 'DC1' LIMIT 1];
        Division__c div = [SELECT Id, Division_Code__c FROM Division__c WHERE Name = '10' LIMIT 1];
        
        User testUser = [SELECT Id FROM User WHERE Username LIKE 'testuser%@example.com' LIMIT 1];
        System.runAs(testUser) {
            Quote q = [SELECT Id FROM Quote LIMIT 1];
            List<String> families = new List<String>{'Category1', 'Category2'};
            
            Test.startTest();
            
            // First test getQuotationDetails
            String quotationDetails = AddProductPageQuote.getQuotationDetails(q.Id);
            System.assertNotEquals(null, quotationDetails, 'Quotation details should not be null');
            
            // Parse and verify the JSON response
            Map<String, Object> resultMap = (Map<String, Object>)JSON.deserializeUntyped(quotationDetails);
            System.assert(resultMap.containsKey('salesOrg'), 'Should contain salesOrg');
            System.assert(resultMap.containsKey('distributionChannel'), 'Should contain distributionChannel');
            System.assert(resultMap.containsKey('division'), 'Should contain division');
            
            // Then test findProduct with the actual values from the quote
            String salesOrgName = so.Name;
            String distChannelCode = dc.Distribution_Code__c;
            String divisionCode = div.Division_Code__c;
            
            String findProductResult = AddProductPageQuote.findProduct(
                q.Id, 
                families,
                salesOrgName,
                distChannelCode,
                divisionCode
            );
            
            System.assertNotEquals(null, findProductResult, 'Find product result should not be null');
            
            // Parse the findProduct result
            AddProductPageQuote.wrapperClass wc = (AddProductPageQuote.wrapperClass)
                JSON.deserialize(findProductResult, AddProductPageQuote.wrapperClass.class);
            
            System.assertNotEquals(null, wc.priceBook, 'Pricebook should not be null');
            System.assertNotEquals(null, wc.productList, 'Product list should not be null');
            
            Test.stopTest();
        }
    }

   

    // Keep your other test methods as they are, but ensure they use the correct parameter values
    @isTest
    static void testAllCoreFunctionality() {
        Sales_Organisation__c so = [SELECT Id, Name FROM Sales_Organisation__c WHERE Name = '1000' LIMIT 1];
        Distribution_Channel__c dc = [SELECT Id, Distribution_Code__c FROM Distribution_Channel__c WHERE Name = 'DC1' LIMIT 1];
        Division__c div = [SELECT Id, Division_Code__c FROM Division__c WHERE Name = '10' LIMIT 1];
        
        User testUser = [SELECT Id FROM User WHERE Username LIKE 'testuser%@example.com' LIMIT 1];
        System.runAs(testUser) {
            Quote q = [SELECT Id FROM Quote LIMIT 1];
            PricebookEntry pbe = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Name = 'Test Product 2' LIMIT 1];
            List<String> families = new List<String>{'Category1', 'Category2'};

            Test.startTest();

            // Use actual values from test data
            Object searchResults = AddProductPageQuote.findProduct(
                q.Id, 
                families,
                so.Name,
                dc.Distribution_Code__c,
                div.Division_Code__c
            );

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

    // Update other test methods similarly to use actual test data values
    @isTest
    static void testEdgeCasesAndErrorScenarios() {
        Sales_Organisation__c so = [SELECT Id, Name FROM Sales_Organisation__c WHERE Name = '1000' LIMIT 1];
        Distribution_Channel__c dc = [SELECT Id, Distribution_Code__c FROM Distribution_Channel__c WHERE Name = 'DC1' LIMIT 1];
        Division__c div = [SELECT Id, Division_Code__c FROM Division__c WHERE Name = '10' LIMIT 1];
        
        User testUser = [SELECT Id FROM User WHERE Username LIKE 'testuser%@example.com' LIMIT 1];
        System.runAs(testUser) {
            Quote q = [SELECT Id FROM Quote LIMIT 1];
            PricebookEntry pbe = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Name = 'Test Product 1' LIMIT 1];

            Test.startTest();

            try {
                Object emptyFamilyResults = AddProductPageQuote.findProduct(
                    q.Id, 
                    new List<String>(),
                    so.Name,
                    dc.Distribution_Code__c,
                    div.Division_Code__c
                );
            } catch (Exception e) {
                System.debug('Expected error: ' + e.getMessage());
            }

            try {
                Object nullFamilyResults = AddProductPageQuote.findProduct(
                    q.Id, 
                    null,
                    so.Name,
                    dc.Distribution_Code__c,
                    div.Division_Code__c
                );
            } catch (Exception e) {
                System.debug('Expected error: ' + e.getMessage());
            }

            try {
                List<AddProductPageQuote.ProductWrapper> emptyList = new List<AddProductPageQuote.ProductWrapper>();
                String emptyJson = JSON.serialize(emptyList);
                String emptySave = AddProductPageQuote.saveProducts(emptyJson, q.Id);
            } catch (Exception e) {
                System.debug('Expected error: ' + e.getMessage());
            }

            Test.stopTest();
        }
    }
}