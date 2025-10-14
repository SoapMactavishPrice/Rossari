@isTest
public class OpportunityLineItemTriggerTest {
    
    @isTest
    static void testOpportunityLineItemTrigger_ZeroPrice() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10)
        );
        insert opp;

        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert testProduct;

        PricebookEntry standardPBE = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert standardPBE;

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Quantity = 1,
            PricebookEntryId = standardPBE.Id,
            UnitPrice = 0 
        );

        insert oli;

        OpportunityLineItem insertedOLI = [
            SELECT Id, OpportunityId, UnitPrice
            FROM OpportunityLineItem
            WHERE Id = :oli.Id
        ];
    }

    @isTest
    static void testOpportunityLineItemTrigger_NonZeroPrice() {
        Account acc = new Account(Name = 'Non Zero Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Non Zero Opportunity',
            AccountId = acc.Id,
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(5)
        );
        insert opp;

        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

        Product2 testProduct = new Product2(
            Name = 'NonZero Product',
            IsActive = true
        );
        insert testProduct;

        PricebookEntry standardPBE = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert standardPBE;

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Quantity = 2,
            PricebookEntryId = standardPBE.Id,
            UnitPrice = 100
        );
        Test.startTest();
        insert oli;
        Test.stopTest();
    }
}