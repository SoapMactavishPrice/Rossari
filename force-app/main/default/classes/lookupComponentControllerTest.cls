@isTest
public class lookupComponentControllerTest {

    @testSetup
    static void setupData() {
        Id standardPricebookId = Test.getStandardPricebookId();
        
        Base_UoM_Master__c baseUom = new Base_UoM_Master__c(Name = 'Kilogram');
        insert baseUom;
    
        Product2 prod = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP001',
            Pack_Size__c = '10kg',
            Base_UOM__c = baseUom.Id,
            Family = 'Test Family',
            IsActive = true
        );
        insert prod;
    
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        Company__c company = new Company__c(
            Name = 'Rossari Biotech Limited',
            SAP_Code__c = '1000'
        );
        insert company;

        Division__c division = new Division__c(Name = 'Test Division');
        insert division;

        Product_Group__c productGroup = new Product_Group__c(Name = 'Test Group');
        insert productGroup;

        Company_User__c cu = new Company_User__c(
            User__c = UserInfo.getUserId(),
            Company__c = company.Id,
            Division__c = division.Id,
            Product_Group__c = productGroup.Id
        );
        insert cu;

        Sales_Organisation__c salesOrg = new Sales_Organisation__c(Name = '1000');
        insert salesOrg;

        Distribution_Channel__c distChannel = new Distribution_Channel__c(Name = '10');
        insert distChannel;

        Sales_Area__c salesArea = new Sales_Area__c(
            Sales_Organisation__c = salesOrg.Id,
            Item_Master__c = prod.Id,
            Division__c = division.Id,
            Distribution_Channel__c = distChannel.Id
        );
        insert salesArea;
    }

    @isTest
    static void testAllFindRecordsScenarios() {
        Test.startTest();
        
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
        insert duplicateProduct;
        
        PricebookEntry duplicatePbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = duplicateProduct.Id,
            UnitPrice = 150,
            IsActive = true,
            CurrencyIsoCode = 'USD'
        );
        insert duplicatePbe;
        
        Sales_Area__c duplicateSalesArea = new Sales_Area__c(
            Sales_Organisation__c = [SELECT Id FROM Sales_Organisation__c LIMIT 1].Id,
            Item_Master__c = duplicateProduct.Id,
            Division__c = [SELECT Id FROM Division__c LIMIT 1].Id,
            Distribution_Channel__c = [SELECT Id FROM Distribution_Channel__c LIMIT 1].Id
        );
        insert duplicateSalesArea;
        
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