@isTest
public class lookupComponentControllerTest {

    @testSetup
    static void setupData() {
        Pricebook2 pb = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive=true);
        
        try{
            update pb;
        }Catch(Exception e){}
        
        Company__c companyRBL = new Company__c(Name='Rossari Biotech Limited', SAP_Code__c='1000');
        insert companyRBL;
        Company__c companyTristar = new Company__c(Name='Tristar Intermediates Private Limited', SAP_Code__c='4000');
        insert companyTristar;
        Company__c companyUnitop = new Company__c(Name='Unitop Chemicals Private Limited', SAP_Code__c='3000');
        insert companyUnitop;

        Division__c division = new Division__c(Name='TestDivision');
        insert division;
        Product_Group__c prodGroup = new Product_Group__c(Name='TestProductGroup');
        insert prodGroup;

        Product2 p1 = new Product2(Name='Prod1', ProductCode='PCODE1', Family='FamilyA', Division__c=division.Id, Item_Group__c=prodGroup.Id, Description='Description 1');
        Product2 p2 = new Product2(Name='Prod2', ProductCode='PCODE2', Family='FamilyB', Division__c=division.Id, Item_Group__c=prodGroup.Id, Description='Description 2');
        insert p1;
        insert p2;

        insert new Company_User__c(
            User__c = UserInfo.getUserId(),
            Division__c = division.Id,
            Product_Group__c = prodGroup.Id,
            Company__c = companyRBL.Id
        );

        insert new Company_User__c(
            User__c = UserInfo.getUserId(),
            Division__c = division.Id,
            Product_Group__c = prodGroup.Id,
            Company__c = companyTristar.Id
        );

        Sales_Organisation__c salesOrg1000 = new Sales_Organisation__c(Name='1000');
        insert salesOrg1000;
        Sales_Organisation__c salesOrg3000 = new Sales_Organisation__c(Name='3000');
        insert salesOrg3000;
        Sales_Organisation__c salesOrg4000 = new Sales_Organisation__c(Name='4000');
        insert salesOrg4000;

        insert new Sales_Area__c(
            Sales_Organisation__c = salesOrg1000.Id,
            Item_Master__c = p1.Id
        );

        insert new Sales_Area__c(
            Sales_Organisation__c = salesOrg4000.Id,
            Item_Master__c = p2.Id
        );

        PricebookEntry pbe1 = new PricebookEntry(Pricebook2Id=pb.Id, Product2Id=p1.Id, UnitPrice=101, IsActive=true, CurrencyIsoCode='USD');
        PricebookEntry pbe2 = new PricebookEntry(Pricebook2Id=pb.Id, Product2Id=p2.Id, UnitPrice=102, IsActive=true, CurrencyIsoCode='USD');
        insert pbe1;
        insert pbe2;
    }

    @isTest
    static void testAllMethods() {
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
        String divisionId = null;
        String businessType = 'Domestic';

        String result1 = lookupComponentController.findRecords(
            searchKey, 
            objectName, 
            returnFields, 
            queryFields, 
            filter, 
            sortColumn, 
            maxResults, 
            family,
            currencyCode,
            leadRecordType,
            divisionId,
            businessType
        );

        String result2 = lookupComponentController.findRecords(
            searchKey, 
            objectName, 
            returnFields, 
            queryFields, 
            filter, 
            sortColumn, 
            maxResults, 
            family,
            currencyCode,
            'Unitop/Tristar',
            divisionId,
            'Export'
        );

        String result3 = lookupComponentController.findRecords(
            'Prod', 
            'PricebookEntry',
            '', 
            new List<String>{'Name', 'ProductCode'}, 
            '', 
            '', 
            '10', 
            'FamilyA',
            'USD',
            'RBL',
            divisionId,
            'Domestic'
        );

        Division__c division = [SELECT Id FROM Division__c LIMIT 1];
        String divisionIdActual = division.Id;
        
        String result4 = lookupComponentController.findRecords(
            'Prod', 
            'PricebookEntry',
            '', 
            new List<String>{'Name', 'ProductCode'}, 
            '', 
            '', 
            '10', 
            '', 
            'USD',
            'RBL',
            divisionIdActual,
            'Domestic'
        );

        try {
            lookupComponentController.findRecords(
                'Prod', 
                'Account',
                '', 
                new List<String>{'Name'}, 
                '', 
                '', 
                '10', 
                '', 
                '',
                'RBL',
                divisionId,
                'Domestic'
            );
        } catch (AuraHandledException e) {}

        String result5 = lookupComponentController.findRecords(
            '', 
            'PricebookEntry',
            '', 
            new List<String>{'Name', 'ProductCode'}, 
            '', 
            '', 
            '10', 
            '', 
            'USD',
            'RBL',
            divisionId,
            'Domestic'
        );

        PricebookEntry entry = [SELECT Id FROM PricebookEntry LIMIT 1];
        String result6 = lookupComponentController.fetchDefaultRecord(entry.Id);

        String result7 = lookupComponentController.fetchDefaultRecord('001000000000001AAA');

        String result8 = lookupComponentController.findRecords(
            searchKey, 
            objectName, 
            returnFields, 
            queryFields, 
            filter, 
            sortColumn, 
            maxResults, 
            family,
            currencyCode,
            leadRecordType,
            divisionId,
            null
        );

        String result9 = lookupComponentController.findRecords(
            searchKey, 
            objectName, 
            returnFields, 
            queryFields, 
            filter, 
            sortColumn, 
            maxResults, 
            family,
            currencyCode,
            leadRecordType,
            divisionId,
            ''
        );

        String result10 = lookupComponentController.findRecords(
            searchKey, 
            objectName, 
            returnFields, 
            queryFields, 
            filter, 
            sortColumn, 
            maxResults, 
            null,
            currencyCode,
            leadRecordType,
            null,
            businessType
        );

        String result11 = lookupComponentController.findRecords(
            null, 
            objectName, 
            returnFields, 
            queryFields, 
            filter, 
            sortColumn, 
            maxResults, 
            family,
            null,
            leadRecordType,
            divisionId,
            businessType
        );
    }
}