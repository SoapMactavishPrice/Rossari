@isTest
public class lookupComponentControllerTest {

    @testSetup
    static void setupData() {
        List<SObject> recordsToInsert = new List<SObject>();
        
        Profile sysAdminProfile = [
            SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1
        ];

        User userPersonnel = new User(
            FirstName = 'Test',
            LastName = 'Admin',
            Email = 'testadmin@example.com',
            Username = 'testadmin@example.com.system',
            Alias = 'tadm',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = sysAdminProfile.Id,
            Division_Code__c = '10',
            CommunityNickname = 'tadminnick'
        );
        recordsToInsert.add(userPersonnel);
        
        insert recordsToInsert;
        recordsToInsert.clear();

        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        try{
        update standardPricebook;
        }Catch(Exception e){}
        Base_UoM_Master__c baseUom = new Base_UoM_Master__c(Name = 'Kilogram');
        recordsToInsert.add(baseUom);
        
        insert recordsToInsert;
        recordsToInsert.clear();

        Division__c division = new Division__c(Name = '10');
        recordsToInsert.add(division);
        
        insert recordsToInsert;
        recordsToInsert.clear();
 
        Product2 prod = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP001',
            Pack_Size__c = '10kg',
            Base_UOM__c = baseUom.Id,
            IsActive = true,
            Division__c = division.Id
        );
        recordsToInsert.add(prod);
        
        insert recordsToInsert;
        recordsToInsert.clear();
 
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        recordsToInsert.add(pbe);
        
        insert recordsToInsert;
        recordsToInsert.clear();

        Company__c company = new Company__c(
            Name = 'Rossari Biotech Limited',
            SAP_Code__c = '1000'
        );
        recordsToInsert.add(company);
        
        insert recordsToInsert;
        recordsToInsert.clear();

        Product_Group__c productGroup = new Product_Group__c(Name = 'Test Group');
        recordsToInsert.add(productGroup);
        
        insert recordsToInsert;
        recordsToInsert.clear();

        Company_User__c cu = new Company_User__c(
            User__c = UserInfo.getUserId(),
            Company__c = company.Id,
            Division__c = division.Id,
            Product_Group__c = productGroup.Id
        );
        recordsToInsert.add(cu);
        
        insert recordsToInsert;
        recordsToInsert.clear();

        Sales_Organisation__c salesOrg = new Sales_Organisation__c(Name = '1000');
        recordsToInsert.add(salesOrg);
        
        insert recordsToInsert;
        recordsToInsert.clear();

        Distribution_Channel__c distChannel = new Distribution_Channel__c(Name = '10');
        recordsToInsert.add(distChannel);
        
        insert recordsToInsert;
        recordsToInsert.clear();

        Sales_Area__c salesArea = new Sales_Area__c(
            Sales_Organisation__c = salesOrg.Id,
            Item_Master__c = prod.Id,
            Division__c = division.Id,
            Distribution_Channel__c = distChannel.Id
        );
        recordsToInsert.add(salesArea);
        
        insert recordsToInsert;
    }

    @isTest
    static void testAllFindRecordsScenarios() {
        Test.startTest();

        User userPersonnel = [SELECT Id FROM User WHERE Email = 'testadmin@example.com' LIMIT 1];
        
        System.runAs(userPersonnel) {

            String result1 = lookupComponentController.findRecords(
                'Test',
                'PricebookEntry',
                'Name',
                new List<String>{'Name'},
                '',
                '',
                '10',
                '',
                '',
                'RBL'
            );
            
            String result2 = lookupComponentController.findRecords(
                '',
                'PricebookEntry',
                'Name',
                new List<String>{'Name'},
                '',
                '',
                '10',
                '',
                '',
                'RBL'
            );
            
            String result3 = lookupComponentController.findRecords(
                'Test',
                'PricebookEntry',
                'Name',
                new List<String>{'Name'},
                '',
                '',
                '10',
                '',
                'USD',
                'RBL'
            );
            
            String result4 = lookupComponentController.findRecords(
                'Test',
                'PricebookEntry',
                'Name',
                new List<String>{'Name'},
                'UnitPrice > 50',
                'Product2.Name',
                '10',
                'Test Family',
                '',
                'RBL'
            );
            
            String result5 = lookupComponentController.findRecords(
                'Test',
                'PricebookEntry',
                'Name',
                new List<String>{'Name'},
                '',
                '',
                '',
                '',
                '',
                'RBL'
            );
            
            String result6 = lookupComponentController.findRecords(
                'Test',
                'PricebookEntry',
                'Name',
                new List<String>{'Name'},
                'UnitPrice > 1000',
                '',
                '10',
                '',
                '',
                'RBL'
            );
            
            String result7 = lookupComponentController.findRecords(
                'Test',
                'PricebookEntry',
                'Name',
                new List<String>{'Name'},
                '',
                '',
                '10',
                'NonExistent Family',
                '',
                'RBL'
            );
            
            try {
                String result8 = lookupComponentController.findRecords(
                    'Test',
                    'Account',
                    'Name',
                    new List<String>{'Name'},
                    '',
                    '',
                    '10',
                    '',
                    '',
                    'RBL'
                );
            } catch (Exception e) {
            }
        }
        
        Test.stopTest();
    }

    @isTest
    static void testAllOtherMethods() {
        Id pbeId = [SELECT Id FROM PricebookEntry LIMIT 1].Id;
        
        Test.startTest();
        
        String result1 = lookupComponentController.fetchDefaultRecord(pbeId);
        
        String result2 = lookupComponentController.fetchDefaultRecord('invalidId');
        
        List<Id> ids1 = lookupComponentController.getUserAllowedProductIds('RBL');
        
        try {
            List<Id> ids2 = lookupComponentController.getUserAllowedProductIds('Tristar');
        } catch (Exception e) {
        }
        
        try {
            List<Id> ids3 = lookupComponentController.getUserAllowedProductIds('Unitop');
        } catch (Exception e) {
        }
        
        try {
            List<Id> ids4 = lookupComponentController.getUserAllowedProductIds('Invalid');
        } catch (Exception e) {
        }
        
        delete [SELECT Id FROM Company_User__c LIMIT 1];
        String result3 = lookupComponentController.findRecords(
            'Test',
            'PricebookEntry',
            'Name',
            new List<String>{'Name'},
            '',
            '',
            '10',
            '',
            '',
            'RBL'
        );
        
        Test.stopTest();
    }

    @isTest
    static void testAdditionalScenarios() {
        List<SObject> recordsToInsert = new List<SObject>();
        
        Test.startTest();
        
        String result1 = lookupComponentController.findRecords(
            'TP001',
            'PricebookEntry',
            'Name',
            new List<String>{'Name'},
            '',
            '',
            '10',
            '',
            '',
            'RBL'
        );
        
        String result2 = lookupComponentController.findRecords(
            'Test',
            'PricebookEntry',
            'Name',
            new List<String>{'Name'},
            '',
            '',
            '10',
            '',
            'EUR',
            'RBL'
        );
        
        Product2 duplicateProduct = new Product2(
            Name = 'Duplicate Product',
            ProductCode = 'TP0067',
            Pack_Size__c = '5kg',
            Base_UOM__c = [SELECT Id FROM Base_UoM_Master__c LIMIT 1].Id,
            Family = 'Test Family',
            IsActive = true
        );
        recordsToInsert.add(duplicateProduct);
        
        insert recordsToInsert;
        recordsToInsert.clear();
        
        PricebookEntry duplicatePbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = duplicateProduct.Id,
            UnitPrice = 150,
            IsActive = true,
            CurrencyIsoCode = 'USD'
        );
        recordsToInsert.add(duplicatePbe);
        
        insert recordsToInsert;
        recordsToInsert.clear();
        
        Sales_Area__c duplicateSalesArea = new Sales_Area__c(
            Sales_Organisation__c = [SELECT Id FROM Sales_Organisation__c LIMIT 1].Id,
            Item_Master__c = duplicateProduct.Id,
            Division__c = [SELECT Id FROM Division__c LIMIT 1].Id,
            Distribution_Channel__c = [SELECT Id FROM Distribution_Channel__c LIMIT 1].Id
        );
        recordsToInsert.add(duplicateSalesArea);
        
        insert recordsToInsert;
        recordsToInsert.clear();
        
        String result3 = lookupComponentController.findRecords(
            'TP001',
            'PricebookEntry',
            'Name',
            new List<String>{'Name'},
            '',
            '',
            '10',
            '',
            '',
            'RBL'
        );
        
        Test.stopTest();
    }
}