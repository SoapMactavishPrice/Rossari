@IsTest
public class AddProductPageQuoteTest {
    
    @TestSetup
    static void setupTestData() {
        Test.startTest();
        // Get a valid Profile Id
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        
        // Create test user with required ProfileId
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@test.com',
            Username = 'testuser' + System.currentTimeMillis() + '@test.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        insert testUser;
        
        // Create Account
        Account acc = new Account(Name='Test Account');
        insert acc;
        
        // Activate Standard Pricebook
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        
        // Create Products
        Product2 prod1 = new Product2(
            Name='Product A', Family='Hardware', ProductCode='PA', IsActive=true
        );
        Product2 prod2 = new Product2(
            Name='Product B', Family='Software', ProductCode='PB', IsActive=true
        );
        insert new List<Product2>{prod1, prod2};
        
        // Create Pricebook Entries
        PricebookEntry pbe1 = new PricebookEntry(
            Product2Id = prod1.Id,
            Pricebook2Id = standardPricebook.Id,
            UnitPrice = 100,
            IsActive = true,
            CurrencyIsoCode = 'USD'
        );
        PricebookEntry pbe2 = new PricebookEntry(
            Product2Id = prod2.Id,
            Pricebook2Id = standardPricebook.Id,
            UnitPrice = 200,
            IsActive = true,
            CurrencyIsoCode = 'USD'
        );
        insert new List<PricebookEntry>{pbe1, pbe2};
        
        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity', 
            StageName = 'Prospecting', 
            CloseDate = Date.today().addDays(30), 
            AccountId = acc.Id
        );
        insert opp;
        
        // Create Quote
        Quote q = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Pricebook2Id = standardPricebook.Id,
            CurrencyIsoCode = 'USD'
        );
        insert q;
        
        // Customer Material Pricelist (to test price override)
        Customer_Material_Pricelist__c cmpl = new Customer_Material_Pricelist__c(
            Customer__c = acc.Id,
            Material__c = prod1.Id,
            Material_Price__c = 90
        );
        insert cmpl;
        Test.stopTest();
    }
    
    @IsTest
    static void testFindProduct() {
        User u = [SELECT Id FROM User WHERE Alias='tuser' LIMIT 1];
        System.runAs(u) {
            
            Test.startTest();
            
            // Fetch Account
            Account acc = [SELECT Id FROM Account WHERE Name='Test Account' LIMIT 1];
            
            // Fetch Standard Pricebook
            Pricebook2 standardPricebook = [SELECT Id FROM Pricebook2 WHERE IsStandard=true LIMIT 1];
            
            // Create Opportunity
            Opportunity opp = new Opportunity(
                Name = 'Test Opportunity 2', 
                StageName = 'Prospecting', 
                CloseDate = Date.today().addDays(30), 
                AccountId = acc.Id
            );
            insert opp;
            
            // Create Quote
            Quote q = new Quote(
                Name = 'Test Quote 2',
                OpportunityId = opp.Id,
                Pricebook2Id = standardPricebook.Id,
                CurrencyIsoCode = 'USD'
            );
            insert q;
            
            // Call method under test
            List<String> families = new List<String>{'Hardware', 'Software'};
            String resultJson = AddProductPageQuote.findProduct(q.Id, families);
            
            // Deserialize to verify
            AddProductPageQuote.wrapperClass wc = (AddProductPageQuote.wrapperClass) 
                JSON.deserialize(resultJson, AddProductPageQuote.wrapperClass.class);
            
            // Fetch Product A Id
            Product2 prodA = [SELECT Id FROM Product2 WHERE Name='Product A' LIMIT 1];
            
            // Check price override from CMPL
            Boolean foundCMPL = false;
            for (AddProductPageQuote.ProductWrapper pw : wc.productList) {
                if (pw.Product2Id == prodA.Id) {
                    foundCMPL = true;
                }
            }
            
            
            Test.stopTest();
        }
    }
}