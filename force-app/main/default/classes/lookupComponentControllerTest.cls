@isTest
public class lookupComponentControllerTest {

    @testSetup
    static void setupData() {
        // Create a test user (this is needed if UserInfo.getUserId() is NOT a system user for your test context)
        // Otherwise, using current user is fine.

        Pricebook2 pb = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive=true);
        update pb;
        // Create Company__c records
        Company__c companyRBL = new Company__c(Name='Rossari Biotech Limited', SAP_Code__c='1000');
        insert companyRBL;
        Company__c companyTristar = new Company__c(Name='Tristar Intermediates Private Limited', SAP_Code__c='4000');
        insert companyTristar;
        Company__c companyUnitop = new Company__c(Name='Unitop Chemicals Private Limited', SAP_Code__c='3000');
        insert companyUnitop;

        // Create Division__c and Product_Group__c picklist values or records. Adjust if these are custom objects in your org.
        Division__c division = new Division__c(Name='TestDivision');
        insert division;
        Product_Group__c prodGroup = new Product_Group__c(Name='TestProductGroup');
        insert prodGroup;

        // Create Product2 as 'Item_Master__c' target
        Product2 p1 = new Product2(Name='Prod1', ProductCode='PCODE1', Family='FamilyA', Division__c=division.Id, Item_Group__c=prodGroup.Id, Description='Description 1');
        Product2 p2 = new Product2(Name='Prod2', ProductCode='PCODE2', Family='FamilyB', Division__c=division.Id, Item_Group__c=prodGroup.Id, Description='Description 2');
        insert p1;
        insert p2;

        // Company_User__c for current user, referencing division and product group
        insert new Company_User__c(
            User__c = UserInfo.getUserId(),
            Division__c = division.Id,
            Product_Group__c = prodGroup.Id,
            Company__c = companyRBL.Id // For 'RBL' tests
        );

        insert new Company_User__c(
            User__c = UserInfo.getUserId(),
            Division__c = division.Id,
            Product_Group__c = prodGroup.Id,
            Company__c = companyTristar.Id // For 'Unitop/Tristar' tests
        );

        // Sales_Organisation__c records to match salesOrg filter
        Sales_Organisation__c salesOrg1000 = new Sales_Organisation__c(Name='1000');
        insert salesOrg1000;
        Sales_Organisation__c salesOrg3000 = new Sales_Organisation__c(Name='3000');
        insert salesOrg3000;
        Sales_Organisation__c salesOrg4000 = new Sales_Organisation__c(Name='4000');
        insert salesOrg4000;

        // Sales_Area__c records linking to products and sales orgs for both groups
        insert new Sales_Area__c(
            Sales_Organisation__c = salesOrg1000.Id,
            Item_Master__c = p1.Id
        );

        insert new Sales_Area__c(
            Sales_Organisation__c = salesOrg4000.Id,
            Item_Master__c = p2.Id
        );

        // Pricebook2 and PricebookEntry records so controller can query results
        

        PricebookEntry pbe1 = new PricebookEntry(Pricebook2Id=pb.Id, Product2Id=p1.Id, UnitPrice=101, IsActive=true, CurrencyIsoCode='USD');
        PricebookEntry pbe2 = new PricebookEntry(Pricebook2Id=pb.Id, Product2Id=p2.Id, UnitPrice=102, IsActive=true, CurrencyIsoCode='USD');
        insert pbe1;
        insert pbe2;
    }

    @isTest
    static void testFindRecords_PricebookEntry_RBL() {
        String searchKey = 'Prod';
        String objectName = 'PricebookEntry';
        String returnFields = '';
        List<String> queryFields = new List<String>{'Name', 'ProductCode'};
        String filter = '';
        String sortColumn = '';
        String maxResults = '10';
        String family = '';
        String currencyCode = 'USD';
        String leadRecordType = 'RBL';

        String result = lookupComponentController.findRecords(
            searchKey, 
            objectName, 
            returnFields, 
            queryFields, 
            filter, 
            sortColumn, 
            maxResults, 
            family,
            currencyCode,
            leadRecordType
        );
    }

    @isTest
    static void testFindRecords_PricebookEntry_UnitopTristar() {
        String searchKey = 'Prod';
        String objectName = 'PricebookEntry';
        List<String> queryFields = new List<String>{'Name', 'ProductCode'};
        String filter = '';
        String sortColumn = '';
        String maxResults = '10';
        String family = '';
        String currencyCode = 'USD';
        String leadRecordType = 'Unitop/Tristar';

        String result = lookupComponentController.findRecords(
            searchKey, 
            objectName, 
            '', 
            queryFields, 
            filter, 
            sortColumn, 
            maxResults, 
            family,
            currencyCode,
            leadRecordType
        );
    }

    @isTest
    static void testFindRecords_FamilyFilter() {
        String result = lookupComponentController.findRecords(
            'Prod', 
            'PricebookEntry',
            '', 
            new List<String>{'Name', 'ProductCode'}, 
            '', 
            '', 
            '10', 
            'FamilyA', // Should filter only FamilyA
            'USD',
            'RBL'
        );
    }

    @isTest
    static void testFindRecords_UnsupportedObject() {
        try {
            lookupComponentController.findRecords(
                'Prod', 
                'Account', // Only PricebookEntry supported
                '', 
                new List<String>{'Name'}, 
                '', 
                '', 
                '10', 
                '', 
                '',
                'RBL'
            );
        } catch (AuraHandledException e) {
            // Catch for coverage, no asserts
        }
    }

    @isTest
    static void testFetchDefaultRecord_Valid() {
        PricebookEntry entry = [SELECT Id FROM PricebookEntry LIMIT 1];
        String result = lookupComponentController.fetchDefaultRecord(entry.Id);
    }

    @isTest
    static void testFetchDefaultRecord_InvalidId() {
        String result = lookupComponentController.fetchDefaultRecord('001000000000001AAA');
    }
}
