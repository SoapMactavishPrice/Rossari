@isTest
private class CustomSalesAreaLookupControllerTest {
    
    @TestSetup
    static void setupTestData() {
        User activeUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'iuytdxc@gmail.com',
            Username = 'iuytdxc97520@gmail.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = UserInfo.getProfileId(),
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        insert activeUser;
        
        Division__c testDivision = new Division__c(Name = 'Test Division');
        insert testDivision;
        
        Product_Group__c testProductGroup = new Product_Group__c(Name = 'Test Product Group');
        insert testProductGroup;
        
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            Item_Group__c = testProductGroup.Id
        );
        insert testProduct;
        
        Plant__c testPlant = new Plant__c(Name = 'Test Plant');
        insert testPlant;
        
        Sales_Area__c testSalesArea = new Sales_Area__c(
            Plant_Code__c = testPlant.Id,
            Division__c = testDivision.Id,
            Item_Master__c = testProduct.Id
        );
        insert testSalesArea;
    }
    
    @isTest
    static void testAllMethods() {
        Division__c testDivision = [SELECT Id FROM Division__c LIMIT 1];
        Plant__c testPlant = [SELECT Id FROM Plant__c LIMIT 1];
        
        Test.startTest();
        
        List<SObject> result1 = CustomSalesAreaLookupController.searchRecords('', 'Division__c', '{}', testDivision.Id);
        List<SObject> result2 = CustomSalesAreaLookupController.searchRecords('Test', 'Division__c', '{}', null);
        List<SObject> result3 = CustomSalesAreaLookupController.searchRecords('Test', 'User', '{}', null);
        
        Map<String, Object> filters1 = new Map<String, Object>{'plantId' => testPlant.Id};
        String filterParams1 = JSON.serialize(filters1);
        List<SObject> result4 = CustomSalesAreaLookupController.searchRecords('', 'Division__c', filterParams1, null);
        
        Map<String, Object> filters2 = new Map<String, Object>{
            'plantId' => testPlant.Id,
            'divisionId' => testDivision.Id
        };
        String filterParams2 = JSON.serialize(filters2);
        List<SObject> result5 = CustomSalesAreaLookupController.searchRecords('', 'Product_Group__c', filterParams2, null);
        
        Map<String, Object> filters3 = new Map<String, Object>{
            'plantId' => testPlant.Id,
            'divisionId' => testDivision.Id
        };
        String filterParams3 = JSON.serialize(filters3);
        List<SObject> result6 = CustomSalesAreaLookupController.searchRecords('Test', 'Product_Group__c', filterParams3, null);
        
        try {
            List<SObject> result7 = CustomSalesAreaLookupController.searchRecords('Test', 'InvalidObject', '{}', null);
        } catch (Exception e) {
        }
        
        List<SObject> result8 = CustomSalesAreaLookupController.getAllRecords('Division__c', '{}');
        
        Map<String, Object> filters4 = new Map<String, Object>{'Id' => testDivision.Id};
        String filterParams4 = JSON.serialize(filters4);
        List<SObject> result9 = CustomSalesAreaLookupController.getAllRecords('Division__c', filterParams4);
        
        try {
            List<SObject> result10 = CustomSalesAreaLookupController.getAllRecords('InvalidObject', '{}');
        } catch (Exception e) {
        }
        
        Test.stopTest();
    }
}