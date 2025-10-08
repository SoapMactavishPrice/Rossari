@isTest
private class CustomSalesAreaLookupControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create Active User
        User activeUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + System.currentTimeMillis() + '@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert activeUser;
        
        // Create supporting records
        Division__c division = new Division__c(Name = 'Test Division');
        insert division;
        
        Product_Group__c pg1 = new Product_Group__c(Item_Group_Description__c = 'All Product Group');
        Product_Group__c pg2 = new Product_Group__c(Item_Group_Description__c = 'Other Product Group');
        insert new List<Product_Group__c>{pg1, pg2};
            
            // Create related mock records for Sales_Area__c
            Sales_Organisation__c salesOrg10 = new Sales_Organisation__c(Name = '1000');
        Distribution_Channel__c dist10 = new Distribution_Channel__c(Name = '10');
        
        /*Item_Master__c itemMaster = new Item_Master__c(
Name = 'Item1',
IsActive = true,
Division__c = division.Id,
Item_Group__c = pg2.Id
);
insert new List<sObject>{salesOrg10, dist10, itemMaster}; */
        
        Sales_Area__c salesArea = new Sales_Area__c(
            // Name = 'Area1',
            Sales_Organisation__c = salesOrg10.Id,
            Distribution_Channel__c = dist10.Id
            //  Item_Master__c = itemMaster.Id
        );
        insert salesArea;
    }
    
    @isTest
    static void testRecordIdLookup_ProductGroup() {
        Product_Group__c pg = [SELECT Id FROM Product_Group__c LIMIT 1];
        Test.startTest();
        List<sObject> results = CustomSalesAreaLookupController.searchRecords('', 'Product_Group__c', '', pg.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testRecordIdLookup_GenericObject() {
        Division__c div = [SELECT Id FROM Division__c LIMIT 1];
        Test.startTest();
        List<sObject> results = CustomSalesAreaLookupController.searchRecords('', 'Division__c', '', div.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testSearch_ProductGroup_WithFilters() {
        Division__c div = [SELECT Id FROM Division__c LIMIT 1];
        Map<String, Object> filters = new Map<String, Object>{
            'sapCodes' => new List<String>{'1000'},
                'divisionId' => div.Id
                };
                    String filterParams = JSON.serialize(filters);
        Test.startTest();
        List<sObject> results = CustomSalesAreaLookupController.searchRecords('Group', 'Product_Group__c', filterParams, null);
        Test.stopTest();
    }
    
    @isTest
    static void testSearch_Division_WithFilters() {
        Map<String, Object> filters = new Map<String, Object>{
            'sapCodes' => new List<String>{'1000'}
        };
            String filterParams = JSON.serialize(filters);
        Test.startTest();
        List<sObject> results = CustomSalesAreaLookupController.searchRecords('Test', 'Division__c', filterParams, null);
        Test.stopTest();
    }
    
    @isTest
    static void testSearch_User() {
        Test.startTest();
        List<sObject> results = CustomSalesAreaLookupController.searchRecords('Test', 'User', '', null);
        Test.stopTest();
    }
    
    @isTest
    static void testIncludeAndSortAllProductGroup() {
        Boolean exceptionThrown = false;
        List<sObject> result = new List<sObject>();
        try {
            Test.startTest();
            result = CustomSalesAreaLookupController.searchRecords('Other', 'Product_Group__c', '', null);
            Test.stopTest();
        } catch (Exception e) {
            exceptionThrown = true;
            System.debug('Exception occurred: ' + e.getMessage());
        }
        
    }
    
    
    @isTest
    static void testExceptionHandling() {
        Boolean exceptionThrown = false;
        try {
            Test.startTest();
            // Pass invalid object name to cause exception
            CustomSalesAreaLookupController.searchRecords('Test', 'Invalid_Object__c', '', null);
            Test.stopTest();
        } catch (Exception e) {
            exceptionThrown = true;
        }
    }
}