@IsTest
public class AddProductPageOppTest {

    @TestSetup
    static void setupTestData() {
        Base_UoM_Master__c baseUom = new Base_UoM_Master__c(Name = 'Kilogram');
        insert baseUom;

        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        try{
        update standardPricebook;
        }Catch(Exception e){}
    
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = System.today(),
            Pricebook2Id = standardPricebook.Id,
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

        Company__c company = new Company__c(Name = 'Test Company', SAP_Code__c = so1.Name);
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
            Division__c = div1.Id,
            Base_UOM__c = baseUom.Id,
            Pack_Size__c = '10kg'
        );
        insert testProduct;

        PricebookEntry standardPbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true,
            CurrencyIsoCode = 'USD',
            UseStandardPrice = false
        );
        insert standardPbe;

        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        u.Division_Code__c = '11';
        u.Division_Code_2__c = '11';
        u.Division_Code_3__c = '24';
        update u;
    }

    @IsTest
    static void testAllCoreFunctionality() {
        Opportunity opp = [SELECT Id, Pricebook2Id, AccountId FROM Opportunity LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 WHERE ProductCode = 'TEST001'];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :testProduct.Id];

        Test.startTest();

        AddProductPageOpp.getCustomerSalesArea(opp.Id);
        AddProductPageOpp.getDistributionChannel(opp.Id, 'SO1');
        AddProductPageOpp.getDivision(opp.Id, 'SO1', 'DC01');
        AddProductPageOpp.getproductfamily();

        try {
            AddProductPageOpp.getCustomerSalesArea('006000000000000AAA');
        } catch (AuraHandledException e) {
        }

        AddProductPageOpp.findProduct(opp.Id, new List<String>());

        AddProductPageOpp.ProductWrapper pw = new AddProductPageOpp.ProductWrapper();
        pw.Id = pbe.Id;
        pw.Product2Id = testProduct.Id;
        pw.Quantity = 2;
        pw.Price = 200;
        pw.LineDescription = 'Test Line Item';
        pw.Discount = 10;
        String recordData = JSON.serialize(new List<AddProductPageOpp.ProductWrapper>{pw});
        AddProductPageOpp.saveProducts(recordData, opp.Id);

        Test.stopTest();
    }

    @IsTest
    static void testEdgeCasesAndDataScenarios() {
        Opportunity opp = [SELECT Id, Pricebook2Id, AccountId FROM Opportunity LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 WHERE ProductCode = 'TEST001'];

        Test.startTest();

        delete [SELECT Id FROM Company_User__c];
        AddProductPageOpp.getCustomerSalesArea(opp.Id);

        delete [SELECT Id FROM Customer_Sales_Area__c];
        AddProductPageOpp.getDistributionChannel(opp.Id, 'SO1');
        AddProductPageOpp.getDivision(opp.Id, 'SO1', 'DC01');

        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        u.Division_Code__c = '10';
        u.Division_Code_2__c = '20';
        u.Division_Code_3__c = '22';
        update u;
        AddProductPageOpp.getDivision(opp.Id, 'SO1', 'DC01');

        PricebookEntry pbeExisting = [SELECT Id FROM PricebookEntry WHERE Product2Id = :testProduct.Id];
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbeExisting.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert oli;
        AddProductPageOpp.findProduct(opp.Id, new List<String>());

        Product2 testProductCMPL = new Product2(
            Name = 'Test Product CMPL',
            ProductCode = 'TEST003',
            IsActive = true,
            Division__c = [SELECT Id FROM Division__c LIMIT 1].Id,
            Base_UOM__c = [SELECT Id FROM Base_UoM_Master__c LIMIT 1].Id,
            Pack_Size__c = '10kg'
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

        AddProductPageOpp.saveProducts(JSON.serialize(new List<AddProductPageOpp.ProductWrapper>()), opp.Id);

        Product2 validProduct = new Product2(
            Name = 'Test Product Valid',
            ProductCode = 'TEST004',
            IsActive = true,
            Division__c = [SELECT Id FROM Division__c LIMIT 1].Id,
            Base_UOM__c = [SELECT Id FROM Base_UoM_Master__c LIMIT 1].Id,
            Pack_Size__c = '10kg'
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

        AddProductPageOpp.saveProducts(JSON.serialize(new List<AddProductPageOpp.ProductWrapper>{validPw}), opp.Id);

        Test.stopTest();
    }
}