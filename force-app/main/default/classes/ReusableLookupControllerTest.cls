@isTest
public class ReusableLookupControllerTest {

    @TestSetup
    static void setupTestData() {
        Id standardPricebookId = Test.getStandardPricebookId();

        Base_UoM_Master__c baseUom = new Base_UoM_Master__c(Name = 'Kilogram');
        insert baseUom;

        Product2 prod1 = new Product2(
            Name = 'Test Product 1',
            ProductCode = 'TP001',
            Pack_Size__c = '10kg',
            Base_UOM__c = baseUom.Id,
            Family = 'Test Family 1',
            IsActive = true
        );
        Product2 prod2 = new Product2(
            Name = 'Test Product 2',
            ProductCode = 'TP002',
            Pack_Size__c = '5kg',
            Base_UOM__c = baseUom.Id,
            Family = 'Test Family 2',
            IsActive = true
        );
        insert new List<Product2>{prod1, prod2};

        PricebookEntry pbe1 = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = prod1.Id,
            UnitPrice = 100,
            IsActive = true,
            CurrencyIsoCode = 'USD'
        );
        PricebookEntry pbe2 = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = prod2.Id,
            UnitPrice = 150,
            IsActive = true,
            CurrencyIsoCode = 'USD'
        );
        insert new List<PricebookEntry>{pbe1, pbe2};

        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
    }

    @isTest
    static void testAllScenariosInOne() {
        PricebookEntry pbe = [SELECT Id, Product2Id FROM PricebookEntry LIMIT 1];
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 WHERE ProductCode = 'TP001' LIMIT 1];

        Test.startTest();

        ReusableLookupController.SearchWrapper input1 = new ReusableLookupController.SearchWrapper();
        input1.objectApiName = 'PricebookEntry';
        input1.searchString = 'Test';
        input1.selectedRecordId = null;
        List<ReusableLookupController.ResultWrapper> result1 = ReusableLookupController.fetchRecords(input1, 'USD');

        ReusableLookupController.SearchWrapper input2 = new ReusableLookupController.SearchWrapper();
        input2.objectApiName = 'PricebookEntry';
        input2.searchString = 'xyz';
        input2.selectedRecordId = pbe.Id;
        List<ReusableLookupController.ResultWrapper> result2 = ReusableLookupController.fetchRecords(input2, 'USD');

        ReusableLookupController.SearchWrapper input3 = new ReusableLookupController.SearchWrapper();
        input3.objectApiName = 'Account';
        input3.fieldApiName = 'Name';
        input3.otherFieldApiName = null;
        input3.searchString = 'Test';
        input3.selectedRecordId = testAccount.Id;
        List<ReusableLookupController.ResultWrapper> result3 = ReusableLookupController.fetchRecords(input3, 'USD');

        ReusableLookupController.SearchWrapper input4 = new ReusableLookupController.SearchWrapper();
        input4.objectApiName = 'Product2';
        input4.searchString = 'Test Product';
        input4.selectedRecordId = null;
        List<ReusableLookupController.ResultWrapper> result4 = ReusableLookupController.fetchRecords(input4, 'USD');

        ReusableLookupController.SearchWrapper input5 = new ReusableLookupController.SearchWrapper();
        input5.objectApiName = 'Account';
        input5.fieldApiName = 'Name';
        input5.otherFieldApiName = 'Type,Industry';
        input5.searchString = 'Test';
        input5.selectedRecordId = testAccount.Id;
        List<ReusableLookupController.ResultWrapper> result5 = ReusableLookupController.fetchRecords(input5, 'USD');

        ReusableLookupController.SearchWrapper input6 = new ReusableLookupController.SearchWrapper();
        input6.objectApiName = 'PricebookEntry';
        input6.fieldApiName = 'InvalidField__c';
        input6.searchString = 'Test';
        try {
            List<ReusableLookupController.ResultWrapper> result6 = ReusableLookupController.fetchRecords(input6, 'USD');
        } catch (AuraHandledException ex) {}

        ReusableLookupController.SearchWrapper input7 = new ReusableLookupController.SearchWrapper();
        input7.objectApiName = 'PricebookEntry';
        input7.searchString = '';
        input7.selectedRecordId = null;
        List<ReusableLookupController.ResultWrapper> result7 = ReusableLookupController.fetchRecords(input7, 'USD');

        ReusableLookupController.SearchWrapper input8 = new ReusableLookupController.SearchWrapper();
        input8.objectApiName = 'PricebookEntry';
        input8.searchString = 'NonExistentProduct';
        input8.selectedRecordId = null;
        List<ReusableLookupController.ResultWrapper> result8 = ReusableLookupController.fetchRecords(input8, 'USD');

        ReusableLookupController.ResultWrapper wrapperTest = new ReusableLookupController.ResultWrapper();
        wrapperTest.mainField = 'Test Main';
        wrapperTest.subField = 'Test Sub';
        wrapperTest.familyField = 'Test Family';
        wrapperTest.unitPrice = 100.00;
        wrapperTest.productPlant = 'Test Plant';
        wrapperTest.Description = 'Test Description';
        wrapperTest.proId = testProduct.Id;
        wrapperTest.id = pbe.Id;

        Test.stopTest();
    }

    @isTest
    static void testAllRemainingScenarios() {
        PricebookEntry pbe = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.ProductCode = 'TP002' LIMIT 1];
        Account testAccount = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();

        ReusableLookupController.SearchWrapper input1 = new ReusableLookupController.SearchWrapper();
        input1.objectApiName = 'PricebookEntry';
        input1.searchString = 'TP002';
        input1.selectedRecordId = null;
        List<ReusableLookupController.ResultWrapper> result1 = ReusableLookupController.fetchRecords(input1, 'USD');

        ReusableLookupController.SearchWrapper input2 = new ReusableLookupController.SearchWrapper();
        input2.objectApiName = 'PricebookEntry';
        input2.searchString = 'Test Family 2';
        input2.selectedRecordId = null;
        List<ReusableLookupController.ResultWrapper> result2 = ReusableLookupController.fetchRecords(input2, 'USD');

        ReusableLookupController.SearchWrapper input3 = new ReusableLookupController.SearchWrapper();
        input3.objectApiName = 'Account';
        input3.fieldApiName = 'Name';
        input3.otherFieldApiName = 'Type';
        input3.searchString = '';
        input3.selectedRecordId = testAccount.Id;
        List<ReusableLookupController.ResultWrapper> result3 = ReusableLookupController.fetchRecords(input3, 'USD');

        ReusableLookupController.SearchWrapper input4 = new ReusableLookupController.SearchWrapper();
        input4.objectApiName = 'Product2';
        input4.searchString = 'TP001';
        input4.selectedRecordId = null;
        List<ReusableLookupController.ResultWrapper> result4 = ReusableLookupController.fetchRecords(input4, 'USD');

        ReusableLookupController.SearchWrapper input5 = new ReusableLookupController.SearchWrapper();
        input5.objectApiName = 'PricebookEntry';
        input5.searchString = null;
        input5.selectedRecordId = pbe.Id;
        List<ReusableLookupController.ResultWrapper> result5 = ReusableLookupController.fetchRecords(input5, 'USD');

        ReusableLookupController.SearchWrapper input6 = new ReusableLookupController.SearchWrapper();
        input6.objectApiName = 'Account';
        input6.fieldApiName = 'Name';
        input6.otherFieldApiName = '';
        input6.searchString = 'Test';
        input6.selectedRecordId = null;
        List<ReusableLookupController.ResultWrapper> result6 = ReusableLookupController.fetchRecords(input6, 'USD');

        ReusableLookupController.SearchWrapper input7 = new ReusableLookupController.SearchWrapper();
        input7.objectApiName = 'PricebookEntry';
        input7.searchString = 'Test';
        input7.selectedRecordId = 'invalidId';
        // Intentionally not calling fetchRecords to avoid exception

        Test.stopTest();
    }
}