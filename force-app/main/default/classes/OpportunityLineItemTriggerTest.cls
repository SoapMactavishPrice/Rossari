@isTest
public class OpportunityLineItemTriggerTest {
    
    @testSetup
    static void setupData() {
        // Activate Standard Pricebook
        Pricebook2 standardPb = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPb;

        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = acc.Id,
            Pricebook2Id = standardPb.Id
        );
        insert opp;
    }
    
    @isTest
    static void testTriggerConditionMet() {
        Opportunity opp = [SELECT Id, Pricebook2Id FROM Opportunity LIMIT 1];

        // Create Product
        Product2 prod = new Product2(Name = 'Zero Price Product', IsActive = true);
        insert prod;

        // PricebookEntry with UnitPrice = 0 (so ListPrice = 0)
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = opp.Pricebook2Id,
            Product2Id = prod.Id,
            UnitPrice = 0,
            IsActive = true
        );
        insert pbe;

        Test.startTest();
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 0
        );
        insert oli; // should satisfy trigger condition and call SendEmail
        Test.stopTest();

        // Assert OLI is inserted
        OpportunityLineItem insertedOli = [
            SELECT Id, UnitPrice, ListPrice 
            FROM OpportunityLineItem 
            WHERE Id = :oli.Id
        ];
        
    }
    
    @isTest
    static void testTriggerConditionNotMet() {
        Opportunity opp = [SELECT Id, Pricebook2Id FROM Opportunity LIMIT 1];

        // Create Product
        Product2 prod = new Product2(Name = 'Non Zero Price Product', IsActive = true);
        insert prod;

        // PricebookEntry with UnitPrice = 200 (so ListPrice = 200)
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = opp.Pricebook2Id,
            Product2Id = prod.Id,
            UnitPrice = 200,
            IsActive = true
        );
        insert pbe;

        Test.startTest();
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 200
        );
        insert oli; // does NOT meet trigger condition
        Test.stopTest();

        // Assert OLI is inserted
        OpportunityLineItem insertedOli = [
            SELECT Id, UnitPrice, ListPrice 
            FROM OpportunityLineItem 
            WHERE Id = :oli.Id
        ];
        
    }
}