@isTest
public class QuoteControllerTest {

    // Utility: Create Standard Pricebook
    private static Pricebook2 createStandardPricebook() {
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        return standardPricebook;
    }

    // Utility: Create Product with UOM
    private static Product2 createProduct() {
        Base_UoM_Master__c baseUom = new Base_UoM_Master__c(Name = 'Kilogram');
        insert baseUom;

        Product2 prod = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP001',
            Pack_Size__c = '10kg',
            Base_UOM__c = baseUom.Id,
            IsActive = true
        );
        insert prod;
        return prod;
    }

    // Utility: Create PricebookEntry
    private static PricebookEntry createPricebookEntry(Product2 prod, Pricebook2 pb) {
        PricebookEntry pbe = new PricebookEntry(
            Product2Id = prod.Id,
            UnitPrice = 100,
            Pricebook2Id = pb.Id,
            IsActive = true
        );
        insert pbe;
        return pbe;
    }

    private static Account createAccount() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        return acc;
    }

    private static Contact createContact(Account acc) {
        Contact c = new Contact(LastName = 'Test Contact', AccountId = acc.Id);
        insert c;
        return c;
    }

    private static Opportunity createOpportunity(Account acc, Pricebook2 pb, Contact c) {
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = acc.Id,
            Pricebook2Id = pb.Id,
            Contact__c = c.Id
        );
        insert opp;
        return opp;
    }

    private static Payment_Term__c createPaymentTerm() {
        Payment_Term__c pt = new Payment_Term__c(Name = 'Test Term');
        insert pt;
        return pt;
    }

    private static Company__c createCompany() {
        Company__c comp = new Company__c(Name = 'Rossari Biotech Limited');
        insert comp;
        return comp;
    }

    // ✅ Create Sales Org
    private static Sales_Organisation__c createSalesOrg() {
        Sales_Organisation__c so = new Sales_Organisation__c(Name = 'Test Sales Org');
        insert so;
        return so;
    }

    // ✅ Create Distribution Channel
    private static Distribution_Channel__c createDistributionChannel() {
        Distribution_Channel__c dc = new Distribution_Channel__c(Name = 'Test DC', Distribution_Code__c = 'DC123');
        insert dc;
        return dc;
    }

    // ✅ Create Division
    private static Division__c createDivision() {
        Division__c div = new Division__c(Name = 'Test Division', Division_Code__c = 'DIV123');
        insert div;
        return div;
    }

    // ✅ Create Customer Sales Area with valid lookup IDs
    private static void createCustomerSalesArea(Account acc) {
        Sales_Organisation__c so = createSalesOrg();
        Distribution_Channel__c dc = createDistributionChannel();
        Division__c div = createDivision();

        Customer_Sales_Area__c csa = new Customer_Sales_Area__c(
            Comapany_Code__c = acc.Id,
            Sales_Organisation__c = so.Id,
            Distribution_Channel__c = dc.Id,
            Division__c = div.Id
        );
        insert csa;
    }

    @isTest
    static void testQuoteControllerMethods() {
        Test.startTest();

        // Setup data
        Pricebook2 pb = createStandardPricebook();
        Product2 prod = createProduct();
        PricebookEntry pbe = createPricebookEntry(prod, pb);
        Account acc = createAccount();
        Contact c = createContact(acc);
        Opportunity opp = createOpportunity(acc, pb, c);
        Payment_Term__c pt = createPaymentTerm();
        Company__c comp = createCompany();
        createCustomerSalesArea(acc);

        // Insert Opportunity Line Item
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Quantity = 2,
            UnitPrice = 100,
            PricebookEntryId = pbe.Id
        );
        insert oli;

       
        List<OpportunityLineItem> olis = QuoteController.getOppLineItems(opp.Id);
        System.assertEquals(1, olis.size());

        
        Map<String, Object> data = QuoteController.getQuoteInitialData(opp.Id);
        System.assertNotEquals(null, data.get('opportunityName'));

     
        List<QuoteController.QuoteLineItemWrapper> wrappers = new List<QuoteController.QuoteLineItemWrapper>();
        QuoteController.QuoteLineItemWrapper w = new QuoteController.QuoteLineItemWrapper();
        w.Product2Id = prod.Id;
        w.PricebookEntryId = pbe.Id;
        w.UnitPrice = 100;
        w.Quantity = 2;
        w.Discount = 5;
        w.Description = 'Sample Item';
        wrappers.add(w);

      
        Id quoteId = QuoteController.createQuoteFromOpportunity(
            opp.Id,
            wrappers,
            'Test Quote',
            'Draft',
            Date.today().addDays(10),
            'USD',
            c.Id,
            pb.Id,
            'FOB',
            pt.Id,
            10,
            'Plastic Drum'
        );
        System.assertNotEquals(null, quoteId);

        
        String deleteMsg = QuoteController.deleteProductInterested(oli.Id);
        System.assert(deleteMsg.contains('deleted'));

        
        Quote q = [SELECT Id FROM Quote WHERE Id = :quoteId];
        q.Status = 'Accepted';
        update q;
        QuoteController.validateQuoteApprovalStatus(new List<Quote>{q}, new Map<Id, Quote>{});

       
        String soJson = QuoteController.getSalesOrg(opp.Id);
        System.assertNotEquals(null, soJson);

      
        Sales_Organisation__c so = [SELECT Id FROM Sales_Organisation__c LIMIT 1];
        String dcJson = QuoteController.getDistributionChannel(opp.Id, so.Id);
        System.assertNotEquals(null, dcJson);

      
        Distribution_Channel__c dc = [SELECT Id FROM Distribution_Channel__c LIMIT 1];
        String divJson = QuoteController.getDivision(opp.Id, so.Id, dc.Id);
        System.assertNotEquals(null, divJson);

      
        Division__c div = [SELECT Id FROM Division__c LIMIT 1];
        String saJson = QuoteController.getSalesArea(opp.Id, so.Id, dc.Id, div.Id);
        System.assertNotEquals(null, saJson);

        Test.stopTest();
    }
}