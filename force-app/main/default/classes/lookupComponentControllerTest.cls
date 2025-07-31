@isTest
public class lookupComponentControllerTest {

    @isTest
    static void testFindRecords() {
        // Create test Product
        Product2 prod = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP001',
            Family = 'Test Family',
            IsActive = true
        );
        insert prod;

        // Activate Standard Pricebook
        Id stdPricebookId = Test.getStandardPricebookId();

        // Create PricebookEntry
        PricebookEntry pbe = new PricebookEntry(
            Product2Id = prod.Id,
            UnitPrice = 100.00,
            Pricebook2Id = stdPricebookId,
            IsActive = true,
            UseStandardPrice = false,
            CurrencyIsoCode = 'USD'
        );
        insert pbe;

        // Call findRecords
        Test.startTest();
        String resultJson = lookupComponentController.findRecords(
            'Test',
            'PricebookEntry',
            '',
            new List<String>{},
            '',
            'ProductCode',
            '5',
            'Test Family',
            'USD'
        );
        Test.stopTest();

    }

    @isTest
    static void testFetchDefaultRecord() {
        // Create Product
        Product2 prod = new Product2(
            Name = 'Default Product',
            ProductCode = 'DP001',
            Family = 'Default Family',
            IsActive = true
        );
        insert prod;

        // Activate Standard Pricebook
        Id stdPricebookId = Test.getStandardPricebookId();

        // Create PricebookEntry
        PricebookEntry pbe = new PricebookEntry(
            Product2Id = prod.Id,
            UnitPrice = 150.00,
            Pricebook2Id = stdPricebookId,
            IsActive = true,
            UseStandardPrice = false,
            CurrencyIsoCode = 'USD'
        );
        insert pbe;

        // Call fetchDefaultRecord
        Test.startTest();
        String defaultJson = lookupComponentController.fetchDefaultRecord(pbe.Id);
        Test.stopTest();

    }

    @isTest
    static void testFindRecordsUnsupportedObject() {
        Test.startTest();
        try {
            lookupComponentController.findRecords(
                'Test',
                'Account', // Unsupported
                '',
                new List<String>{},
                '',
                '',
                '',
                '',
                ''
            );
        } 
        catch (AuraHandledException e) {
        }
        Test.stopTest();
    }
}