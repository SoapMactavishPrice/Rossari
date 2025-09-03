@isTest
public class CompanyUserControllerTest {

    @isTest
    static void testAllMethods() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'user384test@example.com.test',
            Alias = 'tuser',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert u;

        Plant__c plant = new Plant__c(Name = 'Test Plant');
        insert plant;

        Division__c division = new Division__c(Name = 'Test Division');
        insert division;

        Product_Group__c productGroup = new Product_Group__c(Name = 'Test Product Group');
        insert productGroup;

        Product2 prod = new Product2(Name = 'Test Product', Item_Group__c = productGroup.Id);
        insert prod;

        Sales_Area__c salesArea = new Sales_Area__c(
            Plant_Code__c = plant.Id,
            Division__c = division.Id,
            Item_Master__c = prod.Id
        );
        insert salesArea;

        Company__c company = new Company__c(Name = 'Test Company');
        insert company;

        Company_User__c cu = new Company_User__c(
            User__c = u.Id,
            Business_Unit__c = plant.Id,
            Division__c = division.Id,
            Product_Group__c = productGroup.Id,
            Company__c = company.Id
        );
        insert cu;

        List<User> users = CompanyUserController.getUsers();
        List<Plant__c> plants = CompanyUserController.getPlants();
        List<Division__c> divisions = CompanyUserController.getDivisions(plant.Id);
        List<Product_Group__c> groups = CompanyUserController.getProductGroups(plant.Id, division.Id);

        Company_User__c newCU = new Company_User__c(
            User__c = u.Id,
            Business_Unit__c = plant.Id,
            Division__c = division.Id,
            Product_Group__c = productGroup.Id
        );

        Test.startTest();
        CompanyUserController.saveCompanyUsers(company.Id, new List<Company_User__c>{ newCU }, new List<Id>());
        List<Company_User__c> companyUsers = CompanyUserController.getCompanyUsers(company.Id);
        CompanyUserController.saveCompanyUsers(company.Id, null, null);
        CompanyUserController.saveCompanyUsers(company.Id, new List<Company_User__c>(), new List<String>{cu.Id});
        Test.stopTest();
    }
}