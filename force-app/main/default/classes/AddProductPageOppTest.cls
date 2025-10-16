@IsTest
public class AddProductPageOppTest {

    @TestSetup
    static void setupTestData() {
        // Create test data without updating Standard Pricebook
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Use Standard Pricebook without updating it
        Id standardPricebookId = Test.getStandardPricebookId();

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = System.today(),
            Pricebook2Id = standardPricebookId,
            CurrencyIsoCode = 'USD'
        );
        insert opp;

        Division__c div1 = new Division__c(Name = 'Test Division', Division_Code__c = '11');
        insert div1;

        Sales_Organisation__c so1 = new Sales_Organisation__c(Name = 'SO1');
        insert so1;

        Distribution_Channel__c dc1 = new Distribution_Channel__c(Name = 'DC1', Distribution_Code__c = 'DC01');
        insert dc1;

        Customer_Sales_Area__c csa = new Customer_Sales_Area__c(
            Comapany_Code__c = acc.Id,
            Sales_Organisation__c = so1.Id,
            Distribution_Channel__c = dc1.Id,
            Division__c = div1.Id
        );
        insert csa;

        Company__c company = new Company__c(Name = 'Test Company', SAP_Code__c = 'SO1');
        insert company;

        Company_User__c cu = new Company_User__c(
            User__c = UserInfo.getUserId(),
            Company__c = company.Id
        );
        insert cu;

        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'TEST001',
            IsActive = true,
            Division__c = div1.Id
        );
        insert testProduct;

        // Create PricebookEntry without updating Standard Pricebook
        PricebookEntry standardPbe = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true,
            CurrencyIsoCode = 'USD',
            UseStandardPrice = false
        );
        insert standardPbe;

        // Update user division codes
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        u.Division_Code__c = '11';
        u.Division_Code_2__c = '11';
        u.Division_Code_3__c = '24';
        update u;
    }

    @IsTest
    static void testAllCoreFunctionality() {
        Opportunity opp = [SELECT Id, Pricebook2Id, AccountId FROM Opportunity LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 WHERE ProductCode = 'TEST001' LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :testProduct.Id LIMIT 1];

        Test.startTest();

        // Test 1: Basic functionality methods
        AddProductPageOpp.getCustomerSalesArea(opp.Id);
        AddProductPageOpp.getDistributionChannel(opp.Id, 'SO1');
        AddProductPageOpp.getDivision(opp.Id, 'SO1', 'DC01');
        AddProductPageOpp.getproductfamily();

        // Test 2: Exception handling for invalid IDs
        try {
            AddProductPageOpp.getCustomerSalesArea('006000000000000AAA');
        } catch (AuraHandledException e) {
            // Expected exception
        }

        // Test 3: Product search functionality
        AddProductPageOpp.findProduct(opp.Id, new List<String>());

        // Test 4: Save products with valid data
        AddProductPageOpp.ProductWrapper pw = new AddProductPageOpp.ProductWrapper();
        pw.Id = pbe.Id;
        pw.Product2Id = testProduct.Id;
        pw.Quantity = 2;
        pw.Price = 200;
        pw.LineDescription = 'Test Line Item';
        pw.Discount = 10;
        List<AddProductPageOpp.ProductWrapper> pwList = new List<AddProductPageOpp.ProductWrapper>{pw};
        String recordData = JSON.serialize(pwList);
        AddProductPageOpp.saveProducts(recordData, opp.Id);

        // Test 5: Save products with invalid data (exception path)
        AddProductPageOpp.ProductWrapper pw2 = new AddProductPageOpp.ProductWrapper();
        pw2.Id = '01u000000000001AAA';
        pw2.Product2Id = '01t000000000001AAA';
        pw2.Quantity = 1;
        pw2.Price = 100;
        List<AddProductPageOpp.ProductWrapper> pwList2 = new List<AddProductPageOpp.ProductWrapper>{pw2};
        String recordData2 = JSON.serialize(pwList2);
        AddProductPageOpp.saveProducts(recordData2, opp.Id);

        Test.stopTest();
    }

    @IsTest
    static void testEdgeCasesAndDataScenarios() {
        Opportunity opp = [SELECT Id, Pricebook2Id, AccountId FROM Opportunity LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 WHERE ProductCode = 'TEST001' LIMIT 1];

        Test.startTest();

        // Test 1: No Company_User__c scenario
        delete [SELECT Id FROM Company_User__c LIMIT 1];
        AddProductPageOpp.getCustomerSalesArea(opp.Id);

        // Test 2: No Customer_Sales_Area__c scenario
        delete [SELECT Id FROM Customer_Sales_Area__c LIMIT 1];
        AddProductPageOpp.getDistributionChannel(opp.Id, 'SO1');
        AddProductPageOpp.getDivision(opp.Id, 'SO1', 'DC01');

        // Test 3: User with different division codes
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        u.Division_Code__c = '10';
        u.Division_Code_2__c = '20';
        u.Division_Code_3__c = '22';
        update u;
        AddProductPageOpp.getDivision(opp.Id, 'SO1', 'DC01');

        // Test 4: Product search with existing line items
        PricebookEntry pbeExisting = [SELECT Id FROM PricebookEntry WHERE Product2Id = :testProduct.Id LIMIT 1];
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbeExisting.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert oli;
        AddProductPageOpp.findProduct(opp.Id, new List<String>());

        // Test 5: Product search with Customer Material Pricelist
        Product2 testProductCMPL = new Product2(
            Name = 'Test Product CMPL',
            ProductCode = 'TEST003',
            IsActive = true,
            Division__c = [SELECT Id FROM Division__c LIMIT 1].Id
        );
        insert testProductCMPL;
        
        PricebookEntry pbeCMPL = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProductCMPL.Id,
            UnitPrice = 100,
            IsActive = true,
            CurrencyIsoCode = 'USD',
            UseStandardPrice = false
        );
        insert pbeCMPL;

        Customer_Material_Pricelist__c cmpl = new Customer_Material_Pricelist__c(
            Customer__c = opp.AccountId,
            Material__c = testProductCMPL.Id,
            Material_Price__c = 150
        );
        insert cmpl;

        AddProductPageOpp.findProduct(opp.Id, new List<String>());

        // Test 6: Save products with empty list
        List<AddProductPageOpp.ProductWrapper> emptyList = new List<AddProductPageOpp.ProductWrapper>();
        String emptyData = JSON.serialize(emptyList);
        AddProductPageOpp.saveProducts(emptyData, opp.Id);

        // Test 7: Save products with valid new product
        Product2 validProduct = new Product2(
            Name = 'Test Product Valid',
            ProductCode = 'TEST004',
            IsActive = true,
            Division__c = [SELECT Id FROM Division__c LIMIT 1].Id
        );
        insert validProduct;
        
        PricebookEntry validPbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = validProduct.Id,
            UnitPrice = 100,
            IsActive = true,
            CurrencyIsoCode = 'USD',
            UseStandardPrice = false
        );
        insert validPbe;

        AddProductPageOpp.ProductWrapper validPw = new AddProductPageOpp.ProductWrapper();
        validPw.Id = validPbe.Id;
        validPw.Product2Id = validProduct.Id;
        validPw.Quantity = 5;
        validPw.Price = 150;
        validPw.LineDescription = 'Valid Test Item';
        validPw.Discount = 5;

        List<AddProductPageOpp.ProductWrapper> validPwList = new List<AddProductPageOpp.ProductWrapper>{validPw};
        String validRecordData = JSON.serialize(validPwList);
        AddProductPageOpp.saveProducts(validRecordData, opp.Id);

        Test.stopTest();
    }

    @IsTest
    static void testWrapperClassesAndUtilities() {
        Test.startTest();

        // Test wrapperClass
        AddProductPageOpp.wrapperClass wc = new AddProductPageOpp.wrapperClass();
        wc.priceBook = 'Test Pricebook';
        wc.productList = new List<AddProductPageOpp.ProductWrapper>();

        // Test ProductWrapper with safe, minimal properties
        AddProductPageOpp.ProductWrapper pw = new AddProductPageOpp.ProductWrapper();
        
        // Basic properties that typically exist in product wrappers
        pw.Name = 'Test Product';
        pw.Id = Test.getStandardPricebookId(); // Use a real ID format
        pw.Product2Id = '01t000000000001AAA';
        pw.Quantity = 10;
        pw.Price = 100.00;
        pw.Discount = 5.0;
        pw.LineDescription = 'Test Description';

        // Test PicklistValue class
        AddProductPageOpp.PicklistValue pv = new AddProductPageOpp.PicklistValue('testValue', 'Test Label');
        
        // Verify the picklist values
        System.assertEquals('testValue', pv.value, 'Picklist value should match constructor parameter');
        System.assertEquals('Test Label', pv.label, 'Picklist label should match constructor parameter');

        Test.stopTest();
    }
}