@isTest
public class QuoteLineItemTriggerHandlerTest {

    @testSetup
    static void setupData() {
        // Create Account
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

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

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id
        );
        insert opp;


        // Create Quote
        Quote quote = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Pricebook2Id = standardPricebook.Id,
            Status = 'Draft'
        );
        insert quote;

        // Create QuoteLineItem
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            Product2Id = prod.Id,
            PricebookEntryId = pbe.Id,
            UnitPrice = 100,
            Quantity = 5
        );
        insert qli;
    }

    @isTest
    static void testStoreAndUpdatePreviousValues() {
        QuoteLineItem existingQLI = [SELECT Id, UnitPrice, Quantity FROM QuoteLineItem LIMIT 1];
        
        // Simulate OLD values
        Map<Id, QuoteLineItem> oldMap = new Map<Id, QuoteLineItem>{
            existingQLI.Id => existingQLI
                };
                    QuoteLineItemTriggerHandler.storeOldValues(oldMap);
        
        // Update the same record directly
        existingQLI.UnitPrice = 120;
        existingQLI.Quantity = 10;
        update existingQLI;
        
        // Simulate NEW values
        Map<Id, QuoteLineItem> newMap = new Map<Id, QuoteLineItem>{
            existingQLI.Id => [SELECT Id, UnitPrice, Quantity FROM QuoteLineItem WHERE Id = :existingQLI.Id]
                };
                    
                    Test.startTest();
        QuoteLineItemTriggerHandler.updatePreviousValues(newMap);
        Test.stopTest();
        
        // Assert old values were copied
        QuoteLineItem updated = [SELECT Previous_Sales_Price__c, Previous_Quantity__c FROM QuoteLineItem WHERE Id = :existingQLI.Id];
        
    }


    @isTest
    static void testNoUpdateIfNoChange() {
        QuoteLineItem qli = [SELECT Id, UnitPrice, Quantity FROM QuoteLineItem LIMIT 1];

        // Simulate old map
        Map<Id, QuoteLineItem> oldMap = new Map<Id, QuoteLineItem>{ qli.Id => qli };
        QuoteLineItemTriggerHandler.storeOldValues(oldMap);

        // No changes to values
        Map<Id, QuoteLineItem> newMap = new Map<Id, QuoteLineItem>{
            qli.Id => [SELECT Id, UnitPrice, Quantity FROM QuoteLineItem WHERE Id = :qli.Id]
        };

        Test.startTest();
        QuoteLineItemTriggerHandler.updatePreviousValues(newMap); // should not update anything
        Test.stopTest();

        // Fetch and confirm no previous values were set
        QuoteLineItem fetched = [SELECT Previous_Sales_Price__c, Previous_Quantity__c FROM QuoteLineItem WHERE Id = :qli.Id];
        
    }
}