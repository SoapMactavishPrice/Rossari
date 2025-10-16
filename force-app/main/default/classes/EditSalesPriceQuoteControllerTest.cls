@isTest
public class EditSalesPriceQuoteControllerTest {

    @testSetup
    static void setup() {
        Id standardPricebookId = Test.getStandardPricebookId();

        // Create test users
        User manager = new User(
            FirstName = 'Manager',
            LastName = 'Test',
            Email = 'manager@test.com',
            Username = 'managerpriceupdate564@test.com',
            Alias = 'mgrtest',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert manager;

        User owner = new User(
            FirstName = 'Owner',
            LastName = 'Test',
            Email = 'owner@test.com',
            Username = 'ownerpriceupdate564@test.com',
            Alias = 'owntest',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US',
            ManagerId = manager.Id
        );
        insert owner;

        // Create test product
        Product2 product = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP001',
            IsActive = true
        );
        insert product;

        // Create standard pricebook entry
        PricebookEntry standardPbe = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = product.Id,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false
        );
        insert standardPbe;

        // Create custom pricebook
        Pricebook2 customPb = new Pricebook2(
            Name = 'Test Pricebook',
            IsActive = true
        );
        insert customPb;

        // Create custom pricebook entry
        PricebookEntry customPbe = new PricebookEntry(
            Pricebook2Id = customPb.Id,
            Product2Id = product.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert customPbe;

        // Create opportunity with pricebook
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Pricebook2Id = customPb.Id,
            OwnerId = owner.Id
        );
        insert opp;

        // Create quote
        Quote quote = new Quote(
            Name = 'Test Quote',
            Pricebook2Id = customPb.Id,
            OpportunityId = opp.Id,
            OwnerId = owner.Id
        );
        insert quote;

        // Create quote line item
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            PricebookEntryId = customPbe.Id,
            Quantity = 1,
            UnitPrice = 90,
            Approval_Status__c = 'Pending'
        );
        insert qli;
    }

    @isTest
    static void testControllerInitialization() {
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        PageReference pageRef = Page.EditSalesPriceQuote;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', quote.Id);

        EditSalesPriceQuoteController controller = new EditSalesPriceQuoteController();
        System.assertNotEquals(null, controller);
    }

    @isTest
    static void testSaveApproved() {
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        PageReference pageRef = Page.EditSalesPriceQuote;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', quote.Id);

        EditSalesPriceQuoteController controller = new EditSalesPriceQuoteController();
        controller.quoteLineItemsList[0].Approval_Status__c = 'Approved';
        controller.Save();
    }

    @isTest
    static void testSaveRejected() {
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        PageReference pageRef = Page.EditSalesPriceQuote;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', quote.Id);

        EditSalesPriceQuoteController controller = new EditSalesPriceQuoteController();
        controller.quoteLineItemsList[0].Approval_Status__c = 'Rejected';
        controller.Save();
    }

    @isTest
    static void testSaveNoChanges() {
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        PageReference pageRef = Page.EditSalesPriceQuote;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', quote.Id);

        EditSalesPriceQuoteController controller = new EditSalesPriceQuoteController();
        controller.Save();
    }

    @isTest
    static void testCancel() {
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        PageReference pageRef = Page.EditSalesPriceQuote;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', quote.Id);

        EditSalesPriceQuoteController controller = new EditSalesPriceQuoteController();
        controller.Cancel();
    }

    @isTest
    static void testNoIdParameter() {
        PageReference pageRef = Page.EditSalesPriceQuote;
        Test.setCurrentPage(pageRef);

        EditSalesPriceQuoteController controller = new EditSalesPriceQuoteController();
        System.assertNotEquals(null, controller);
    }
}