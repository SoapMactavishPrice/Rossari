/*@isTest
public class AddProductPageQuoteTest {

    @isTest
    static void testFindProduct() {
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        //u.Division_Code__c = 'DIV1';
        //u.Division_Code_2__c = 'DIV2';
        //u.Division_Code_3__c = 'DIV3';
        update u;

        Pricebook2 stdPB = [SELECT Id, IsActive FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
        stdPB.IsActive = true;
        update stdPB;

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Quote q = new Quote(Name = 'Test Quote', Pricebook2Id = stdPB.Id, CurrencyIsoCode = 'USD');
        insert q;

        Product2 p = new Product2(Name = 'Test Product', ProductCode = 'PRD-' + DateTime.now().getTime(), IsActive = true, Create_PricebookEntry__c = true);
        insert p;

        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :p.Id AND Pricebook2Id = :stdPB.Id LIMIT 1];

        Customer_Material_Pricelist__c cmp = new Customer_Material_Pricelist__c(
            Customer__c = acc.Id,
            Material__c = p.Id
        );
        insert cmp;

        List<String> families = new List<String>{ p.Family };
        AddProductPageQuote.findProduct(q.Id, families);
    }

    @isTest
    static void testGetProductFamily() {
        AddProductPageQuote.getproductfamily();
    }

    @isTest
    static void testSaveProducts() {
        Pricebook2 stdPB = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
        stdPB.IsActive = true;
        update stdPB;

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Quote q = new Quote(Name = 'Test Quote', Pricebook2Id = stdPB.Id, CurrencyIsoCode = 'USD');
        insert q;

        Product2 p = new Product2(Name = 'Test Product', ProductCode = 'PRD-' + DateTime.now().getTime(), IsActive = true, Create_PricebookEntry__c = true);
        insert p;

        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :p.Id AND Pricebook2Id = :stdPB.Id LIMIT 1];

        AddProductPageQuote.ProductWrapper pw = new AddProductPageQuote.ProductWrapper();
        pw.Id = pbe.Id;
        pw.Product2Id = p.Id;
        pw.Price = 100;
        pw.Quantity = 2;
        pw.Discount = 0;
        pw.LineDescription = 'Test Line';

        List<AddProductPageQuote.ProductWrapper> pwList = new List<AddProductPageQuote.ProductWrapper>{ pw };
        String recordData = JSON.serialize(pwList);
        AddProductPageQuote.saveProducts(recordData, q.Id);
    }
}*/
@isTest
public class AddProductPageQuoteTest {

    @testSetup
    static void setupTestData() {
        // Activate Standard Pricebook
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

        System.debug('check ' + [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1]);

        // Create Product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert testProduct;

        // Create PricebookEntry
        PricebookEntry standardPBE = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert standardPBE;

        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id,
            Pricebook2Id = standardPricebook.Id
        );
        insert opp;

        // Create Quote linked to Opportunity
        Quote q = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Pricebook2Id = standardPricebook.Id,
            //AccountId = acc.Id,
            Status = 'Draft'
        );
        insert q;
    }

    @isTest
    static void testFindProductAndSaveProducts() {
        // Fetch Quote
        Quote q = [SELECT Id, Pricebook2Id, AccountId FROM Quote LIMIT 1];

        // Prepare productFamily list
        List<String> productFamily = new List<String>();

        // Call findProduct
        String jsonResult = AddProductPageQuote.findProduct(q.Id, productFamily);
        System.debug('findProduct result: ' + jsonResult);
        System.assert(jsonResult.contains('productList'), 'Product list should be returned');

        // Deserialize result to get a product wrapper
        AddProductPageQuote.wrapperClass wc = (AddProductPageQuote.wrapperClass) JSON.deserialize(jsonResult, AddProductPageQuote.wrapperClass.class);
        System.assert(wc.productList.size() > 0, 'There should be at least one product');

        // Set Quantity and Price for testing saveProducts
        for (AddProductPageQuote.ProductWrapper pw : wc.productList) {
            pw.Quantity = 2;
            pw.Price = 120;
        }

        // Serialize product list
        String recordData = JSON.serialize(wc.productList);

        // Call saveProducts
        String result = AddProductPageQuote.saveProducts(recordData, q.Id);
        System.debug('saveProducts result: ' + result);
        System.assertEquals('success', result, 'Products should be saved successfully');

        // Verify QuoteLineItem created
        List<QuoteLineItem> qliList = [SELECT Id, Product2Id, Quantity, UnitPrice FROM QuoteLineItem WHERE QuoteId = :q.Id];
        System.assert(qliList.size() > 0, 'QuoteLineItem should be inserted');
        System.assertEquals(2, qliList[0].Quantity, 'Quantity should match');
        System.assertEquals(120, qliList[0].UnitPrice, 'Price should match');
    }

    @isTest
    static void testGetProductFamily() {
        List<AddProductPageQuote.PicklistValue> familyList = AddProductPageQuote.getproductfamily();
        System.debug('Product Family Picklist: ' + familyList);
        System.assert(familyList.size() > 0, 'Picklist should return values');
    }
}