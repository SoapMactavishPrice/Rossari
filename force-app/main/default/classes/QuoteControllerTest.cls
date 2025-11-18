@isTest
public class QuoteControllerTest {

    // Utility: Create Standard Pricebook
    private static Pricebook2 createStandardPricebook() {
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        try {
            update standardPricebook;
        } catch (Exception e) {}
        return standardPricebook;
    }

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
            Name = 'Test Opportunity',
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
        Payment_Term__c pt = new Payment_Term__c(Name = 'Test Payment Term');
        insert pt;
        return pt;
    }

    private static Company__c createCompany() {
        Company__c comp = new Company__c(Name = 'Rossari Biotech Limited');
        insert comp;
        return comp;
    }

    private static Sales_Organisation__c createSalesOrg() {
        Sales_Organisation__c so = new Sales_Organisation__c(Name = 'Test Sales Org');
        insert so;
        return so;
    }

    private static Distribution_Channel__c createDistributionChannel() {
        Distribution_Channel__c dc = new Distribution_Channel__c(Name = 'Test DC', Distribution_Code__c = 'DC123');
        insert dc;
        return dc;
    }

    private static Division__c createDivision() {
        Division__c div = new Division__c(Name = 'Test Division', Division_Code__c = 'DIV123');
        insert div;
        return div;
    }

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

    // Utility: Create supporting lookup records for Address_Information__c
    private static Map<String, Id> createAddressLookups() {
        Country__c country = new Country__c(Name = 'India');
        insert country;

        State__c state = new State__c(Name = 'Maharashtra', Country__c = country.Id);
        insert state;

        City__c city = new City__c(Name = 'Mumbai', State__c = state.Id);
        insert city;

        Pin_Code__c pin = new Pin_Code__c(Name = '400001', City__c = city.Id);
        insert pin;

        return new Map<String, Id>{
            'Country' => country.Id,
            'State' => state.Id,
            'City' => city.Id,
            'Pin' => pin.Id
        };
    }

    // Utility: Create Address Information Records (Bill_To and Ship_To)
    private static List<Address_Information__c> createAddressInformation(Account acc) {
        Map<String, Id> lookups = createAddressLookups();

        Id billToRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Address_Information__c' AND DeveloperName = 'Bill_To' LIMIT 1].Id;
        Id shipToRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Address_Information__c' AND DeveloperName = 'Ship_To' LIMIT 1].Id;

        Address_Information__c billTo = new Address_Information__c(
            Name = 'Billing Address',
            Account__c = acc.Id,
            RecordTypeId = billToRT,
            Street_1__c = 'Billing Street 1',
            Street_2__c = 'Billing Street 2',
            Street_3__c = 'Billing Street 3',
            City__c = lookups.get('City'),
            State__c = lookups.get('State'),
            Country__c = lookups.get('Country'),
            Pin_Code__c = lookups.get('Pin')
        );

        Address_Information__c shipTo = new Address_Information__c(
            Name = 'Shipping Address',
            Account__c = acc.Id,
            RecordTypeId = shipToRT,
            Street_1__c = 'Shipping Street 1',
            Street_2__c = 'Shipping Street 2',
            Street_3__c = 'Shipping Street 3',
            City__c = lookups.get('City'),
            State__c = lookups.get('State'),
            Country__c = lookups.get('Country'),
            Pin_Code__c = lookups.get('Pin')
        );

        insert new List<Address_Information__c>{ billTo, shipTo };
        return new List<Address_Information__c>{ billTo, shipTo };
    }

    @isTest
    static void testQuoteControllerMethods() {
        Test.startTest();

        Pricebook2 pb = createStandardPricebook();
        Product2 prod = createProduct();
        PricebookEntry pbe = createPricebookEntry(prod, pb);
        Account acc = createAccount();
        Contact c = createContact(acc);
        Opportunity opp = createOpportunity(acc, pb, c);
        Payment_Term__c pt = createPaymentTerm();
        Company__c comp = createCompany();
        createCustomerSalesArea(acc);
        List<Address_Information__c> addresses = createAddressInformation(acc);

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Quantity = 5,
            UnitPrice = 200,
            PricebookEntryId = pbe.Id
        );
        insert oli;

        QuoteController.getOppLineItems(opp.Id);
        QuoteController.getQuoteInitialData(opp.Id);

        List<QuoteController.QuoteLineItemWrapper> wrappers = new List<QuoteController.QuoteLineItemWrapper>();
        QuoteController.QuoteLineItemWrapper wrapper = new QuoteController.QuoteLineItemWrapper();
        wrapper.Product2Id = prod.Id;
        wrapper.PricebookEntryId = pbe.Id;
        wrapper.UnitPrice = 100;
        wrapper.Quantity = 2;
        wrapper.Discount = 5;
        wrapper.Description = 'Sample Product';
        wrappers.add(wrapper);

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
            15,
            'Plastic Drum',
            'Delivered Price',
            addresses[0].Id, // Bill_To
            addresses[1].Id  // Ship_To
        );

        QuoteController.deleteProductInterested(oli.Id);

        Quote q = [SELECT Id FROM Quote WHERE Id = :quoteId];
        q.Status = 'Accepted';
        update q;
        QuoteController.validateQuoteApprovalStatus(new List<Quote>{ q }, new Map<Id, Quote>{});

        QuoteController.getSalesOrg(opp.Id);

        Sales_Organisation__c so = [SELECT Id FROM Sales_Organisation__c LIMIT 1];
        QuoteController.getDistributionChannel(opp.Id, so.Id);

        Distribution_Channel__c dc = [SELECT Id FROM Distribution_Channel__c LIMIT 1];
        QuoteController.getDivision(opp.Id, so.Id, dc.Id);

        Division__c div = [SELECT Id FROM Division__c LIMIT 1];
        QuoteController.getSalesArea(opp.Id, so.Id, dc.Id, div.Id);

        Test.stopTest();
    }
}