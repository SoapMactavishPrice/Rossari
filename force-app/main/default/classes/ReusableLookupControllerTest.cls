@isTest
public class ReusableLookupControllerTest {

    // Utility to create a Product2 and PricebookEntry
    private static PricebookEntry createTestPricebookEntry(String name, String code, String family, String currencyIso) {
        Id stdPBId = Test.getStandardPricebookId();
        
        Product2 prod = new Product2(
            Name = name,
            ProductCode = code,
            Family = family,
            IsActive = true
        );
        insert prod;
        
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = stdPBId,
            Product2Id = prod.Id,
            UnitPrice = 99.99,
            IsActive = true,
            CurrencyIsoCode = currencyIso
        );
        insert pbe;
        
        return pbe;
    }

    @isTest
    static void testFetchRecords_withSearch() {
        PricebookEntry pbe = createTestPricebookEntry('Test Product', 'TP001', 'Tools', 'USD');

        ReusableLookupController.SearchWrapper input = new ReusableLookupController.SearchWrapper();
        input.objectApiName = 'PricebookEntry';
        input.searchString = 'Test';
        input.selectedRecordId = null;

        Test.startTest();
        List<ReusableLookupController.ResultWrapper> result = ReusableLookupController.fetchRecords(input, 'USD');
        Test.stopTest();

    }

    @isTest
    static void testFetchRecords_withSelectedRecordId() {
        PricebookEntry pbe = createTestPricebookEntry('Unique Product', 'UP002', 'Medical', 'USD');

        ReusableLookupController.SearchWrapper input = new ReusableLookupController.SearchWrapper();
        input.objectApiName = 'PricebookEntry';
        input.searchString = 'xyz'; // ignored because selectedRecordId is set
        input.selectedRecordId = pbe.Id;

        Test.startTest();
        List<ReusableLookupController.ResultWrapper> result = ReusableLookupController.fetchRecords(input, 'USD');
        Test.stopTest();

    }

    @isTest
    static void testFetchRecords_withNullInput() {
        Test.startTest();
        List<ReusableLookupController.ResultWrapper> result = ReusableLookupController.fetchRecords(null, 'USD');
        Test.stopTest();

    }

    @isTest
    static void testFetchRecords_withNonPricebookEntryObject() {
        // Create dummy Account record to test dynamic object handling
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        ReusableLookupController.SearchWrapper input = new ReusableLookupController.SearchWrapper();
        input.objectApiName = 'Account';
        input.fieldApiName = 'Name';
        input.otherFieldApiName = null;
        input.searchString = 'Test';
        input.selectedRecordId = acc.Id;

        Test.startTest();
        List<ReusableLookupController.ResultWrapper> result = ReusableLookupController.fetchRecords(input, 'USD');
        Test.stopTest();

    }

    @isTest
    static void testFetchRecords_withException() {
        // Invalid object name to trigger exception
        ReusableLookupController.SearchWrapper input = new ReusableLookupController.SearchWrapper();
        input.objectApiName = 'InvalidObject__c';
        input.fieldApiName = 'Name';
        input.searchString = 'Test';

        Test.startTest();
        try {
            ReusableLookupController.fetchRecords(input, 'USD');
        } catch (AuraHandledException ex) {
        }
        Test.stopTest();
    }
}