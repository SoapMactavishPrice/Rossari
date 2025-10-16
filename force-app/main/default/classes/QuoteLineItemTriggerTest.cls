@IsTest
public class QuoteLineItemTriggerTest {

    @TestSetup
    static void setupTestData() {
        // Get standard pricebook ID without updating (fix for UNABLE_TO_LOCK_ROW)
        Id standardPricebookId = Test.getStandardPricebookId();

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
            Pricebook2Id = standardPricebookId,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false
        );
        insert pbe;

        // Step 4: Create Account
        Account acc = new Account(Name='Test Account');
        insert acc;

        // Step 5: Create Opportunity
        Opportunity opp = new Opportunity(
            Name='Test Opp',
            StageName='Prospecting',
            CloseDate=Date.today(),
            AccountId=acc.Id,
            Pricebook2Id=standardPricebookId
        );
        insert opp;

        // Step 6: Create Quote
        Quote quote = new Quote(
            Name='Test Quote',
            OpportunityId = opp.Id,
            Pricebook2Id = standardPricebookId
            //AccountId = acc.Id
        );
        insert quote;
    }

    @IsTest
    static void testQuoteLineItemTrigger() {
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];

        // Insert QuoteLineItem with zero ListPrice and UnitPrice to trigger your logic
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            //ListPrice = 0,
            UnitPrice = 0
        );

        Test.startTest();
        insert qli; // triggers QuoteLineItem trigger
        Test.stopTest();
    }
}