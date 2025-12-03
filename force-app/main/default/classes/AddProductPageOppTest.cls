@IsTest
public class AddProductPageOppTest {

    @TestSetup
    static void setupTestData() {
        // Create Base UoM Master
        Base_UoM_Master__c baseUom = new Base_UoM_Master__c(Name = 'Kilogram');
        insert baseUom;

        // Activate standard pricebook
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

        // Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = System.today(),
            Pricebook2Id = standardPricebook.Id,
            CurrencyIsoCode = 'USD'
        );
        insert opp;

        // Division
        Division__c div1 = new Division__c(Name = 'Test Division', Division_Code__c = '11');
        insert div1;

        // Sales org
        Sales_Organisation__c so1 = new Sales_Organisation__c(Name = 'SO1');
        insert so1;

        // Distribution channel
        Distribution_Channel__c dc1 = new Distribution_Channel__c(Name = 'DC1', Distribution_Code__c = 'DC01');
        insert dc1;
        
        // Payment Term
        Payment_Term__c Pt = New Payment_Term__c(Name = 'Net 30');
        insert Pt;

        // Customer Sales Area
        Customer_Sales_Area__c csa = new Customer_Sales_Area__c(
            Comapany_Code__c = acc.Id,
            Sales_Organisation__c = so1.Id,
            Distribution_Channel__c = dc1.Id,
            Division__c = div1.Id,
            Payment_Term__c = Pt.Id,
            Incoterm_1__c = 'CIF'
        );
        insert csa;

        // Company + company user
        Company__c company = new Company__c(Name = 'Test Company', SAP_Code__c = so1.Name);
        insert company;

        Company_User__c cu = new Company_User__c(
            User__c = UserInfo.getUserId(),
            Company__c = company.Id,
            Division__c = div1.Id
        );
        insert cu;

        // Product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'TEST001',
            IsActive = true,
            Division__c = div1.Id,
            Base_UOM__c = baseUom.Id,
            Pack_Size__c = '10kg',
            Family = 'Test Family'
        );
        insert testProduct;

        // Standard PBE
        PricebookEntry standardPbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true,
            CurrencyIsoCode = 'USD'
        );
        insert standardPbe;

        // Sales Area
        Sales_Area__c salesArea = new Sales_Area__c(
            Item_Master__c = testProduct.Id,
            Sales_Organisation__c = so1.Id,
            Distribution_Channel__c = dc1.Id,
            Pack_Size__c = '10'
        );
        insert salesArea;

        // Update User
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        u.Division_Code__c = '11';
        u.Division_Code_2__c = '11';
        u.Division_Code_3__c = '24';
        u.Sales_Type_Code1__c = '10';
        update u;
    }


    // ------------------------------------------------------------
    //     SINGLE COMBINED TEST METHOD
    // ------------------------------------------------------------
    @IsTest
    static void testEverythingInOne() {

        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 WHERE ProductCode = 'TEST001'];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :testProduct.Id];
        Sales_Organisation__c so1 = [SELECT Id, Name FROM Sales_Organisation__c LIMIT 1];
        Distribution_Channel__c dc1 = [SELECT Id, Distribution_Code__c FROM Distribution_Channel__c LIMIT 1];
        Division__c div1 = [SELECT Id, Division_Code__c FROM Division__c LIMIT 1];

        Test.startTest();

        // -------------------------
        // getDetail
        // -------------------------
        AddProductPageOpp.getDetail(opp.Id);
        try { AddProductPageOpp.getDetail('001000000000000AAA'); } catch(Exception e) {}

        // -------------------------
        // Customer Sales Area
        // -------------------------
        AddProductPageOpp.getCustomerSalesArea(opp.Id);
        try { AddProductPageOpp.getCustomerSalesArea('001000000000000AAA'); } catch(Exception e) {}

        // -------------------------
        // Distribution Channel
        // -------------------------
        AddProductPageOpp.getDistributionChannel(opp.Id, so1.Name);
        AddProductPageOpp.getDistributionChannel(opp.Id, 'NonExistentSO');
        try { AddProductPageOpp.getDistributionChannel('001000000000000AAA', so1.Name); } catch(Exception e) {}

        // -------------------------
        // Division
        // -------------------------
        AddProductPageOpp.getDivision(opp.Id, so1.Name, dc1.Distribution_Code__c);
        AddProductPageOpp.getDivision(opp.Id, 'NonSO', 'NonDC');
        try { AddProductPageOpp.getDivision('001000000000000AAA', so1.Name, dc1.Distribution_Code__c); } catch(Exception e) {}

        // -------------------------
        // findProduct
        // -------------------------
        AddProductPageOpp.findProduct(opp.Id, new List<String>(), so1.Name, dc1.Distribution_Code__c, div1.Division_Code__c);
        AddProductPageOpp.findProduct(opp.Id, new List<String>{ 'Test Family' }, so1.Name, dc1.Distribution_Code__c, div1.Division_Code__c);

        // -------------------------
        // getProductFamily
        // -------------------------
        AddProductPageOpp.getproductfamily();

        // -------------------------
        // saveProducts
        // -------------------------
        AddProductPageOpp.ProductWrapper pw = new AddProductPageOpp.ProductWrapper();
        pw.Id = pbe.Id;
        pw.Product2Id = testProduct.Id;
        pw.Quantity = 2;
        pw.Price = 200;

        String wrapperJSON = JSON.serialize(new List<AddProductPageOpp.ProductWrapper>{pw});
        AddProductPageOpp.saveProducts(wrapperJSON, opp.Id);

        AddProductPageOpp.saveProducts(JSON.serialize(new List<AddProductPageOpp.ProductWrapper>()), opp.Id);

        try { AddProductPageOpp.saveProducts('invalid json', opp.Id); } catch(Exception e) {}

        // -------------------------
        // saveOppDetail
        // -------------------------
        Sales_Organisation__c soNew = new Sales_Organisation__c(Name = 'SO-NEW');
        insert soNew;

        Distribution_Channel__c dcNew = new Distribution_Channel__c(Name='DC-NEW', Distribution_Code__c='DCNEW');
        insert dcNew;

        Division__c divNew = new Division__c(Name='DIV-NEW', Division_Code__c='DN1');
        insert divNew;

        AddProductPageOpp.saveOppDetail(opp.Id, soNew.Name, dcNew.Distribution_Code__c, divNew.Name);

        try { AddProductPageOpp.saveOppDetail('001000000000000AAA', soNew.Name, dcNew.Distribution_Code__c, divNew.Name); } catch(Exception e) {}

        // -------------------------
        // getProductPackSize
        // -------------------------
        AddProductPageOpp.getProductPackSize(JSON.serialize(new List<String>{ testProduct.Id }), so1.Name, dc1.Distribution_Code__c);
        AddProductPageOpp.getProductPackSize(JSON.serialize(new List<String>()), so1.Name, dc1.Distribution_Code__c);
        try { AddProductPageOpp.getProductPackSize('invalid json', so1.Name, dc1.Distribution_Code__c); } catch(Exception e) {}

        // -------------------------
        // Wrapper tests
        // -------------------------
        AddProductPageOpp.wrapperClass wc = new AddProductPageOpp.wrapperClass();
        AddProductPageOpp.PicklistValue pv = new AddProductPageOpp.PicklistValue('A','B');

        // -------------------------
        // Bulk test
        // -------------------------
        List<Product2> bulkProducts = new List<Product2>();
        for(Integer i=0;i<20;i++){
            bulkProducts.add(new Product2(
                Name='Bulk'+i,
                ProductCode='B'+i,
                IsActive=true,
                Division__c = div1.Id
            ));
        }
        insert bulkProducts;

        Test.stopTest();
    }

}