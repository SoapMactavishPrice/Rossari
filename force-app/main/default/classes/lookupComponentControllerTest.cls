@isTest
public class lookupComponentControllerTest {

    @testSetup
    static void setupData() {
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
        
        try {
            String result5 = lookupComponentController.findRecords(
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
        
        Test.stopTest();
    }
}