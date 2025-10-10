@isTest
private class CompanyUserControllerTest {
    
    @TestSetup
    static void setupTestData() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@test.com',
            Username = 'testuseranjb87@test.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        insert testUser;
        
        Company__c testCompany = new Company__c(
            Name = 'Test Company',
            SAP_Code__c = '1000',
            Email__c = 'company@test.com',
            Phone__c = '1234567890',
            Company_Code__c = 'COMP001'
        );
        insert testCompany;
        
        Division__c testDivision = new Division__c(
            Name = 'Test Division'
        );
        insert testDivision;
        
        Product_Group__c allProductGroup = new Product_Group__c(
            Item_Group_Description__c = 'All Product Group'
        );
        insert allProductGroup;
        
        Product_Group__c testProductGroup = new Product_Group__c(
            Item_Group_Description__c = 'Test Product Group'
        );
        insert testProductGroup;
        
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            Division__c = testDivision.Id,
            Item_Group__c = testProductGroup.Id,
            IsActive = true,
            ProductCode = 'TEST001',
            Create_PricebookEntry__c = false
        );
        insert testProduct;
        
        Sales_Organisation__c testSalesOrg1 = new Sales_Organisation__c(
            Name = '1000'
        );
        insert testSalesOrg1;
        
        Sales_Organisation__c testSalesOrg2 = new Sales_Organisation__c(
            Name = '2000'
        );
        insert testSalesOrg2;
        
        Distribution_Channel__c testDistChannel1 = new Distribution_Channel__c(
            Name = '10'
        );
        insert testDistChannel1;
        
        Distribution_Channel__c testDistChannel2 = new Distribution_Channel__c(
            Name = '20'
        );
        insert testDistChannel2;
        
        Sales_Area__c testSalesArea1 = new Sales_Area__c(
            Item_Master__c = testProduct.Id,
            Sales_Organisation__c = testSalesOrg1.Id,
            Distribution_Channel__c = testDistChannel1.Id
        );
        insert testSalesArea1;
        
        Sales_Area__c testSalesArea2 = new Sales_Area__c(
            Item_Master__c = testProduct.Id,
            Sales_Organisation__c = testSalesOrg2.Id,
            Distribution_Channel__c = testDistChannel2.Id
        );
        insert testSalesArea2;
        
        Company_User__c testCompanyUser = new Company_User__c(
            Company__c = testCompany.Id,
            User__c = testUser.Id,
            Division__c = testDivision.Id,
            Product_Group__c = testProductGroup.Id
        );
        insert testCompanyUser;
    }
    
    @isTest
    static void testAllMethods() {
        Company__c company = [SELECT Id FROM Company__c LIMIT 1];
        User user = [SELECT Id FROM User WHERE Username = 'testuseranjb87@test.com' LIMIT 1];
        Division__c division = [SELECT Id FROM Division__c LIMIT 1];
        Product_Group__c productGroup = [SELECT Id FROM Product_Group__c WHERE Item_Group_Description__c = 'Test Product Group' LIMIT 1];
        Company_User__c existingUser = [SELECT Id FROM Company_User__c LIMIT 1];
        
        Test.startTest();
        
        List<User> users = CompanyUserController.getUsers();
        List<String> sapCodes = CompanyUserController.getCompanySAPCodes(company.Id);
        List<String> invalidSapCodes = CompanyUserController.getCompanySAPCodes('invalidId');
        List<Division__c> divisions = CompanyUserController.getDivisions(new List<String>{'1000'});
        List<Division__c> emptyDivisions = CompanyUserController.getDivisions(new List<String>());
        List<Division__c> nullDivisions = CompanyUserController.getDivisions(null);
        List<Product_Group__c> productGroups = CompanyUserController.getProductGroups(new List<String>{'1000'}, division.Id);
        List<Product_Group__c> emptyProductGroups = CompanyUserController.getProductGroups(new List<String>(), division.Id);
        List<Product_Group__c> nullProductGroups = CompanyUserController.getProductGroups(new List<String>{'1000'}, null);
        List<Company_User__c> companyUsers = CompanyUserController.getCompanyUsers(company.Id);
        Company__c companyInfo = CompanyUserController.getCompanyInfo(company.Id);
        
        List<Company_User__c> newCompanyUsers = new List<Company_User__c>{
            new Company_User__c(
                User__c = user.Id,
                Division__c = division.Id,
                Product_Group__c = productGroup.Id
            )
        };
        CompanyUserController.saveCompanyUsers(company.Id, newCompanyUsers, null);
        
        List<String> deletedRecordIds = new List<String>{existingUser.Id};
        CompanyUserController.saveCompanyUsers(company.Id, newCompanyUsers, deletedRecordIds);
        
        CompanyUserController.saveCompanyUsers(company.Id, null, null);
        
        try {
            List<Company_User__c> invalidUsers = new List<Company_User__c>{new Company_User__c()};
            CompanyUserController.saveCompanyUsers(company.Id, invalidUsers, null);
        } catch (Exception e) {}
        
        Test.stopTest();
    }
    
    @isTest
    static void testSortProductGroupsScenarios() {
        Product_Group__c pg1 = new Product_Group__c(Item_Group_Description__c = 'Test Group 1');
        Product_Group__c pg2 = new Product_Group__c(Item_Group_Description__c = 'All Product Group');
        Product_Group__c pg3 = new Product_Group__c(Item_Group_Description__c = 'Test Group 2');
        insert new List<Product_Group__c>{pg1, pg2, pg3};
        
        Company__c noSapCompany = new Company__c(Name = 'No SAP Company');
        insert noSapCompany;
        
        Test.startTest();
        
        List<String> sapCodes = CompanyUserController.getCompanySAPCodes(noSapCompany.Id);
        List<String> validSapCodes = new List<String>{'1000'};
        Division__c division = [SELECT Id FROM Division__c LIMIT 1];
        
        List<Product_Group__c> mixedGroups = CompanyUserController.getProductGroups(validSapCodes, division.Id);
        
        Product_Group__c onlyAllGroup = new Product_Group__c(Item_Group_Description__c = 'All Product Group');
        insert onlyAllGroup;
        List<Product_Group__c> onlyAllGroups = CompanyUserController.getProductGroups(validSapCodes, division.Id);
        
        Product_Group__c noAllGroup1 = new Product_Group__c(Item_Group_Description__c = 'Test Group A');
        Product_Group__c noAllGroup2 = new Product_Group__c(Item_Group_Description__c = 'Test Group B');
        insert new List<Product_Group__c>{noAllGroup1, noAllGroup2};
        List<Product_Group__c> noAllGroups = CompanyUserController.getProductGroups(validSapCodes, division.Id);
        
        Test.stopTest();
    }
}