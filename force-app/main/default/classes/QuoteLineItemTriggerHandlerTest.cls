@isTest
public class QuoteLineItemTriggerHandlerTest {

    @testSetup
    static void setupData() {

        Id standardPricebookId = Test.getStandardPricebookId();

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

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id,
            Pricebook2Id = standardPricebookId
        );
        insert opp;

        Quote quote = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Pricebook2Id = standardPricebookId,
            Status = 'Draft'
        );
        insert quote;

        // Create initial QuoteLineItem
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
        
        // Update the same record directly - include UnitPrice
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
        QuoteLineItemTriggerHandler.updatePreviousValues(newMap);
        Test.stopTest();
    }

    @isTest
    static void testMultipleQuoteLineItems() {
        // Create additional quote line items for multiple testing
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];
        
        List<QuoteLineItem> additionalQlis = new List<QuoteLineItem>();
        for(Integer i = 1; i <= 2; i++) {
            additionalQlis.add(new QuoteLineItem(
                QuoteId = quote.Id,
                Product2Id = prod.Id,
                PricebookEntryId = pbe.Id,
                UnitPrice = 100 + (i * 50),
                Quantity = 5 + i
            ));
        }
        insert additionalQlis;
        
        List<QuoteLineItem> qlis = [SELECT Id, UnitPrice, Quantity FROM QuoteLineItem];
        
        // Simulate OLD values for multiple items
        Map<Id, QuoteLineItem> oldMap = new Map<Id, QuoteLineItem>();
        for(QuoteLineItem qli : qlis) {
            oldMap.put(qli.Id, qli);
        }
        QuoteLineItemTriggerHandler.storeOldValues(oldMap);
        
        // Update multiple records - ensure UnitPrice is included
        for(QuoteLineItem qli : qlis) {
            qli.UnitPrice = qli.UnitPrice + 50;
            qli.Quantity = qli.Quantity + 5;
        }
        update qlis;
        
        // Simulate NEW values
        Map<Id, QuoteLineItem> newMap = new Map<Id, QuoteLineItem>([
            SELECT Id, UnitPrice, Quantity 
            FROM QuoteLineItem 
            WHERE Id IN :oldMap.keySet()
        ]);

        Test.startTest();
        QuoteLineItemTriggerHandler.updatePreviousValues(newMap);
        Test.stopTest();
    }

    @isTest
    static void testPartialUpdates() {
        QuoteLineItem qli = [SELECT Id, UnitPrice, Quantity FROM QuoteLineItem LIMIT 1];
        
        // Store old values
        Map<Id, QuoteLineItem> oldMap = new Map<Id, QuoteLineItem>{ qli.Id => qli };
        QuoteLineItemTriggerHandler.storeOldValues(oldMap);
        
        // Update only UnitPrice - Quantity remains the same
        qli.UnitPrice = 150;
        update qli;
        
        // Simulate NEW values
        Map<Id, QuoteLineItem> newMap = new Map<Id, QuoteLineItem>{
            qli.Id => [SELECT Id, UnitPrice, Quantity FROM QuoteLineItem WHERE Id = :qli.Id]
        };

        Test.startTest();
        QuoteLineItemTriggerHandler.updatePreviousValues(newMap);
        Test.stopTest();
    }

    @isTest
    static void testEmptyOldMap() {
        QuoteLineItem qli = [SELECT Id, UnitPrice, Quantity FROM QuoteLineItem LIMIT 1];
        
        // Empty old map scenario
        Map<Id, QuoteLineItem> oldMap = new Map<Id, QuoteLineItem>();
        QuoteLineItemTriggerHandler.storeOldValues(oldMap);
        
        // Update the record - include UnitPrice
        qli.UnitPrice = 200;
        qli.Quantity = 15;
        update qli;
        
        Map<Id, QuoteLineItem> newMap = new Map<Id, QuoteLineItem>{
            qli.Id => [SELECT Id, UnitPrice, Quantity FROM QuoteLineItem WHERE Id = :qli.Id]
        };

        Test.startTest();
        QuoteLineItemTriggerHandler.updatePreviousValues(newMap);
        Test.stopTest();
    }

    @isTest
    static void testZeroValuesHandling() {
        QuoteLineItem qli = [SELECT Id, UnitPrice, Quantity FROM QuoteLineItem LIMIT 1];
        
        // Store old values
        Map<Id, QuoteLineItem> oldMap = new Map<Id, QuoteLineItem>{ qli.Id => qli };
        QuoteLineItemTriggerHandler.storeOldValues(oldMap);
        
        // Update with zero values instead of null
        qli.UnitPrice = 0;
        qli.Quantity = 1;
        update qli;
        
        Map<Id, QuoteLineItem> newMap = new Map<Id, QuoteLineItem>{
            qli.Id => [SELECT Id, UnitPrice, Quantity FROM QuoteLineItem WHERE Id = :qli.Id]
        };

        Test.startTest();
        QuoteLineItemTriggerHandler.updatePreviousValues(newMap);
        Test.stopTest();
    }

    @isTest
    static void testBulkOperations() {
        // Create additional quote line items for bulk testing
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];
        
        List<QuoteLineItem> bulkQlis = new List<QuoteLineItem>();
        for(Integer i = 0; i < 10; i++) {
            bulkQlis.add(new QuoteLineItem(
                QuoteId = quote.Id,
                Product2Id = prod.Id,
                PricebookEntryId = pbe.Id,
                UnitPrice = 100 + (i * 10),
                Quantity = 5 + i
            ));
        }
        insert bulkQlis;
        
        List<QuoteLineItem> allQlis = [SELECT Id, UnitPrice, Quantity FROM QuoteLineItem];
        
        // Store old values for all items
        Map<Id, QuoteLineItem> oldMap = new Map<Id, QuoteLineItem>();
        for(QuoteLineItem qli : allQlis) {
            oldMap.put(qli.Id, qli);
        }
        QuoteLineItemTriggerHandler.storeOldValues(oldMap);
        
        // Bulk update all items - ensure UnitPrice is always set
        for(QuoteLineItem qli : allQlis) {
            qli.UnitPrice = qli.UnitPrice * 1.1; // 10% increase
            qli.Quantity = qli.Quantity + 2;
        }
        update allQlis;
        
        Map<Id, QuoteLineItem> newMap = new Map<Id, QuoteLineItem>([
            SELECT Id, UnitPrice, Quantity 
            FROM QuoteLineItem 
            WHERE Id IN :oldMap.keySet()
        ]);

        Test.startTest();
        QuoteLineItemTriggerHandler.updatePreviousValues(newMap);
        Test.stopTest();
    }

    @isTest
    static void testConsecutiveUpdates() {
        QuoteLineItem qli = [SELECT Id, UnitPrice, Quantity FROM QuoteLineItem LIMIT 1];
        
        // First update
        Map<Id, QuoteLineItem> oldMap1 = new Map<Id, QuoteLineItem>{ qli.Id => qli };
        QuoteLineItemTriggerHandler.storeOldValues(oldMap1);
        
        qli.UnitPrice = 120;
        qli.Quantity = 8;
        update qli;
        
        Map<Id, QuoteLineItem> newMap1 = new Map<Id, QuoteLineItem>{
            qli.Id => [SELECT Id, UnitPrice, Quantity FROM QuoteLineItem WHERE Id = :qli.Id]
        };
        QuoteLineItemTriggerHandler.updatePreviousValues(newMap1);
        
        // Second update
        QuoteLineItem qliAfterFirstUpdate = [SELECT Id, UnitPrice, Quantity FROM QuoteLineItem WHERE Id = :qli.Id];
        Map<Id, QuoteLineItem> oldMap2 = new Map<Id, QuoteLineItem>{ qliAfterFirstUpdate.Id => qliAfterFirstUpdate };
        QuoteLineItemTriggerHandler.storeOldValues(oldMap2);
        
        qliAfterFirstUpdate.UnitPrice = 140;
        qliAfterFirstUpdate.Quantity = 12;
        update qliAfterFirstUpdate;
        
        Map<Id, QuoteLineItem> newMap2 = new Map<Id, QuoteLineItem>{
            qliAfterFirstUpdate.Id => [SELECT Id, UnitPrice, Quantity FROM QuoteLineItem WHERE Id = :qliAfterFirstUpdate.Id]
        };

        Test.startTest();
        QuoteLineItemTriggerHandler.updatePreviousValues(newMap2);
        Test.stopTest();
    }

    @isTest
    static void testOnlyQuantityUpdate() {
        QuoteLineItem qli = [SELECT Id, UnitPrice, Quantity FROM QuoteLineItem LIMIT 1];
        
        // Store old values
        Map<Id, QuoteLineItem> oldMap = new Map<Id, QuoteLineItem>{ qli.Id => qli };
        QuoteLineItemTriggerHandler.storeOldValues(oldMap);
        
        // Update only Quantity - UnitPrice remains the same
        qli.Quantity = 20;
        update qli;
        
        Map<Id, QuoteLineItem> newMap = new Map<Id, QuoteLineItem>{
            qli.Id => [SELECT Id, UnitPrice, Quantity FROM QuoteLineItem WHERE Id = :qli.Id]
        };

        Test.startTest();
        QuoteLineItemTriggerHandler.updatePreviousValues(newMap);
        Test.stopTest();
    }

    @isTest
    static void testOnlyUnitPriceUpdate() {
        QuoteLineItem qli = [SELECT Id, UnitPrice, Quantity FROM QuoteLineItem LIMIT 1];
        
        // Store old values
        Map<Id, QuoteLineItem> oldMap = new Map<Id, QuoteLineItem>{ qli.Id => qli };
        QuoteLineItemTriggerHandler.storeOldValues(oldMap);
        
        // Update only UnitPrice - Quantity remains the same
        qli.UnitPrice = 250;
        update qli;
        
        Map<Id, QuoteLineItem> newMap = new Map<Id, QuoteLineItem>{
            qli.Id => [SELECT Id, UnitPrice, Quantity FROM QuoteLineItem WHERE Id = :qli.Id]
        };

        Test.startTest();
        QuoteLineItemTriggerHandler.updatePreviousValues(newMap);
        Test.stopTest();
    }
}