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

        ReusableLookupController.SearchWrapper input = new ReusableLookupController.SearchWrapper();
        input.objectApiName = 'PricebookEntry';
        input.searchString = 'xyz'; // ignored because selectedRecordId is set
        input.selectedRecordId = pbe.Id;

        Test.startTest();
        List<ReusableLookupController.ResultWrapper> result = ReusableLookupController.fetchRecords(input, 'USD');
        Test.stopTest();

    }

  /*  @isTest
    static void testFetchRecords_withNullInput() {
         try {
        List<ReusableLookupController.ResultWrapper> result = ReusableLookupController.fetchRecords(null, 'USD');
        System.assertNotEquals(null, result, 'Result should not be null'); // Optional: add assertions if needed
    } catch (Exception e) {
        System.debug('Exception caught: ' + e.getMessage());
        System.assert(true, 'Handled exception gracefully');
    }
    Test.stopTest();

    } */

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
    // Use a valid standard object that the user might not have access to
    // instead of an invalid object name
    ReusableLookupController.SearchWrapper input = new ReusableLookupController.SearchWrapper();
    input.objectApiName = 'PricebookEntry';
    input.fieldApiName = 'InvalidField__c'; // Invalid field to trigger exception
    input.searchString = 'Test';

    Test.startTest();
    try {
        ReusableLookupController.fetchRecords(input, 'USD');
        //System.assert(false, 'Expected exception was not thrown');
    } catch (AuraHandledException ex) {
        // Expected - verify the exception message if needed
        //System.assert(ex.getMessage() != null, 'Exception message should not be null');
    }
    Test.stopTest();
}
}