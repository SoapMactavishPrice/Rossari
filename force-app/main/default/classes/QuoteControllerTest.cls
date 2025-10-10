@isTest
public class QuoteControllerTest {

    // Utility method to create Pricebook and Product
    private static Pricebook2 createPricebook() {
        Pricebook2 pb = new Pricebook2(Name = 'Standard Pricebook', IsActive = true);
        insert pb;
        return pb;
    }

    private static Product2 createProduct() {
        Product2 p = new Product2(Name = 'Test Product', IsActive = true);
        insert p;
        return p;
    }

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

    private static void createCustomerSalesArea(Account acc) {
        Customer_Sales_Area__c csa = new Customer_Sales_Area__c(
            Comapany_Code__c = acc.Id,
            Sales_Organisation__c = 'SO123',
            Distribution_Channel__c = 'DC123',
            Division__c = 'DIV123'
        );
        insert csa;
    }

    @isTest
    static void testQuoteControllerMethods() {
        Test.startTest();

        // Setup test data
        Pricebook2 pb = createPricebook();
        Product2 prod = createProduct();
        PricebookEntry pbe = createPricebookEntry(prod, pb);
        Account acc = createAccount();
        Contact c = createContact(acc);
        Opportunity opp = createOpportunity(acc, pb, c);
        Payment_Term__c pt = createPaymentTerm();
        Company__c comp = createCompany();
        createCustomerSalesArea(acc);

        // Insert an Opportunity Line Item
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Quantity = 2,
            UnitPrice = 100,
            PricebookEntryId = pbe.Id
        );
        insert oli;

        // 1️⃣ Test getOppLineItems
        List<OpportunityLineItem> olis = QuoteController.getOppLineItems(opp.Id);

        // 2️⃣ Test getQuoteInitialData
        Map<String, Object> data = QuoteController.getQuoteInitialData(opp.Id);

        // 3️⃣ Prepare line item wrapper
        List<QuoteController.QuoteLineItemWrapper> wrappers = new List<QuoteController.QuoteLineItemWrapper>();
        QuoteController.QuoteLineItemWrapper w = new QuoteController.QuoteLineItemWrapper();
        w.Product2Id = prod.Id;
        w.PricebookEntryId = pbe.Id;
        w.UnitPrice = 100;
        w.Quantity = 2;
        w.Discount = 5;
        w.Description = 'Sample Item';
        wrappers.add(w);

        // 4️⃣ Test createQuoteFromOpportunity
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
        System.assertNotEquals(null, quoteId, 'Quote should be created');

        // 5️⃣ Test deleteProductInterested
        String deleteMsg = QuoteController.deleteProductInterested(oli.Id);
        System.assert(deleteMsg.contains('deleted'), 'Delete message should mention deletion');

        // 6️⃣ Test validateQuoteApprovalStatus
        Quote q = [SELECT Id FROM Quote WHERE Id = :quoteId];
        QuoteLineItem qli = [SELECT Id, QuoteId, ListPrice, UnitPrice, Product2.Name FROM QuoteLineItem WHERE QuoteId = :quoteId LIMIT 1];
        q.Status = 'Accepted';
        update q;

        QuoteController.validateQuoteApprovalStatus(new List<Quote>{q}, new Map<Id, Quote>{});

        // 7️⃣ Test getSalesOrg
        String soJson = QuoteController.getSalesOrg(opp.Id);

        // 8️⃣ Test getDistributionChannel
        String dcJson = QuoteController.getDistributionChannel(opp.Id, 'SO123');

        // 9️⃣ Test getDivision
        String divJson = QuoteController.getDivision(opp.Id, 'SO123', 'DC123');

        // 🔟 Test getSalesArea
        String saJson = QuoteController.getSalesArea(opp.Id, 'SO123', 'DC123', 'DIV123');

        Test.stopTest();
    }
}