@isTest
private class TargetNewControllerTest {

    @testSetup
    static void setup() {
        FY__c fy = new FY__c(
            Name = '2025',
            FY_Start_Date__c = Date.today().addDays(-30),
            FY_End_Date__c = Date.today().addDays(30)
        );
        insert fy;

        User usr = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'targetuser@test.com',
            Username = 'targetuser123456@test.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id
        );
        insert usr;

        Id standardPricebookId = Test.getStandardPricebookId();

        Product_Group__c productGroup = new Product_Group__c(Name = 'Electronics');
        insert productGroup;

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


        Target__c target = new Target__c(
            FY__c = fy.Id,
            Product__c = prod.Id,
            Sales_Employee__c = usr.Id,
            Month__c = 'January',
            Year__c = '2025',
            Quantity__c = 100,
            Budgeted_COGS__c = 50,
            Budgeted_GM_KG__c = 25,
            Amount__c = 200,
            Product_Description__c = 'Sample Description',
            Product_Code__c = 'PROD001'
        );
        insert target;
    }

    @isTest
    static void testMethods() {
        User usr = [SELECT Id FROM User WHERE Username = 'targetuser123456@test.com' LIMIT 1];
        FY__c fy = [SELECT Id FROM FY__c WHERE FY_Start_Date__c <= :Date.today() AND FY_End_Date__c >= :Date.today() LIMIT 1];
        Product2 prod = [SELECT Id, ProductCode, Item_Group__c FROM Product2 LIMIT 1];
        Target__c tgt = [SELECT Id FROM Target__c LIMIT 1];

        FY__c resultFy = TargetNewController.getDefualtFiscId();
        System.assertNotEquals(null, resultFy, 'Fiscal Year should not be null');

        List<Target__c> dataList = TargetNewController.getExistingData(usr.Id, fy.Id);
        System.assert(dataList.size() > 0, 'Existing Target records should be returned');

        List<Product2> productList = TargetNewController.getProductList(prod.Item_Group__c);
        System.assert(productList.size() > 0, 'Product list should return products in the given Product_Group__c');

        Map<String, Object> mapData = new Map<String, Object>{
            'Description' => 'Test Desc',
            'MonthName' => 'January-2025',
            'Sales_Qauntity__c' => '150',
            'COGS_Kg__c' => '55',
            'GM_Kg__c' => '30',
            'Price__c' => '210',
            'ProductId' => prod.Id,
            'ProductCode' => prod.ProductCode
        };
        List<Object> inputList = new List<Object>{mapData};
        String jsonInput = JSON.serialize(inputList);

        String result = TargetNewController.saveToServer(jsonInput, usr.Id, fy.Id);

        TargetNewController.updateOnDemand(tgt.Id, 'Sales_Qauntity__c', '160');
        TargetNewController.updateOnDemand(tgt.Id, 'COGS_Kg__c', '60');
        TargetNewController.updateOnDemand(tgt.Id, 'GM_Kg__c', '35');
        TargetNewController.updateOnDemand(tgt.Id, 'Price__c', '220');

        Target__c updatedTarget = [SELECT Quantity__c, Budgeted_COGS__c, Budgeted_GM_KG__c, Amount__c FROM Target__c WHERE Id = :tgt.Id];
    }
}