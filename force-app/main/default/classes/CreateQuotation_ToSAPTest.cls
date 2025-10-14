@isTest
public class CreateQuotation_ToSAPTest {

    @isTest
    static void testQuoteValidation() {
        Account acc = new Account(Name = 'Test Account', SAP_Customer_Code__c = '1001017');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        Quote q = new Quote(Name = 'Test Quote', OpportunityId = opp.Id, Status = 'Accepted');
        insert q;

        CreateQuotation_ToSAP.quoteValidation(q.Id);
    }

    @isTest
    static void testGetLineItem() {
        Account acc = new Account(Name = 'Test Account', SAP_Customer_Code__c = '1001017');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        Quote q = new Quote(Name = 'Test Quote', OpportunityId = opp.Id, Status = 'Accepted');
        insert q;

        Pricebook2 pb = [SELECT Id, IsActive FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
        if (!pb.IsActive) {
            pb.IsActive = true;
            update pb;
        }

        Product2 prod = new Product2(Name = 'Test Product', ProductCode = 'TP001', IsActive = true, Create_PricebookEntry__c = true);
        insert prod;

        PricebookEntry pbe = new PricebookEntry(Pricebook2Id = pb.Id, Product2Id = prod.Id, UnitPrice = 100, IsActive = true);
        insert pbe;

        QuoteLineItem qli = new QuoteLineItem(QuoteId = q.Id, Product2Id = prod.Id, Quantity = 1, UnitPrice = 100, PricebookEntryId = pbe.Id);
        insert qli;

        CreateQuotation_ToSAP.getLineItem(q.Id);
    }

    @isTest
    static void testCreateQuotation() {
        Account acc = new Account(Name = 'Test Account', SAP_Customer_Code__c = '1001017');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        Sales_Organisation__c so = new Sales_Organisation__c(Name = '1000');
        insert so;

        Distribution_Channel__c dc = new Distribution_Channel__c(Name = 'DC1', Distribution_Code__c = '10');
        insert dc;

        Division__c div = new Division__c(Name = 'DIV1', Division_Code__c = '10');
        insert div;

        Quote q = new Quote(Name = 'Test Quote', OpportunityId = opp.Id, Status = 'Accepted',
                            Sales_Organisations__c = so.Id,
                            Distribution_Channel__c = dc.Id,
                            Division__c = div.Id);
        insert q;

        CreateQuotation_ToSAP.createQuotation(q.Id);
    }

    @isTest
    static void testAddItem() {
        Account acc = new Account(Name = 'Test Account', SAP_Customer_Code__c = '1001017');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        Quote q = new Quote(Name = 'Test Quote', OpportunityId = opp.Id, Status = 'Accepted', SAP_Order_No__c = 'SO123');
        insert q;

        Pricebook2 pb = [SELECT Id, IsActive FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
        if (!pb.IsActive) {
            pb.IsActive = true;
            update pb;
        }

        Product2 prod = new Product2(Name = 'Test Product', ProductCode = 'TP001', IsActive = true, Create_PricebookEntry__c = true);
        insert prod;

        PricebookEntry pbe = new PricebookEntry(Pricebook2Id = pb.Id, Product2Id = prod.Id, UnitPrice = 100, IsActive = true);
        insert pbe;

        QuoteLineItem qli = new QuoteLineItem(QuoteId = q.Id, Product2Id = prod.Id, Quantity = 1, UnitPrice = 100, PricebookEntryId = pbe.Id);
        insert qli;

        qli = [SELECT Id, Product2Id, Product2.ProductCode, QuoteId, Quantity, Quote.SAP_Order_No__c FROM QuoteLineItem WHERE Id = :qli.Id];
        CreateQuotation_ToSAP.addItem(qli);
    }
}