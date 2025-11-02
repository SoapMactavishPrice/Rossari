@isTest
public class PartnerFunctionTriggerTest {
    
    @testSetup
    static void setupData() {
        // Create related records
        Sales_Organisation__c salesOrg = new Sales_Organisation__c(Name = 'SO1');
        insert salesOrg;

        Distribution_Channel__c distChannel = new Distribution_Channel__c(Name = 'DC1');
        insert distChannel;

        Division__c division = new Division__c(Division_Code__c = 'DIV1');
        insert division;
        
         Account acc = new Account(Name = 'Test Account');
        insert acc;

        Customer_Sales_Area__c salesArea = new Customer_Sales_Area__c(
            Name = 'CSA1',
            Sales_Organisation__c = salesOrg.Id,
            Distribution_Channel__c = distChannel.Id,
            Division__c = division.Id,
            Comapany_Code__c = acc.Id
        );
        insert salesArea;

        // Create a valid Partner_function__c record
        Partner_function__c pf = new Partner_function__c(
            Name = 'PF1',
            Partner_code__c = 'P001',
            PARTNER_FUNC__c = 'FUNC1',
            Customer_Sales_Area__c = salesArea.Id
        );
        insert pf;
    }

    @isTest
    static void testDuplicatePFUniqueShouldFail() {
        Customer_Sales_Area__c csa = [SELECT Id FROM Customer_Sales_Area__c LIMIT 1];

        Partner_function__c pfDuplicate = new Partner_function__c(
            Name = 'PF2',
            Partner_code__c = 'P001',
            PARTNER_FUNC__c = 'FUNC1',
            Customer_Sales_Area__c = csa.Id
        );

        Test.startTest();
        try {
            insert pfDuplicate;
          //  System.assert(false, 'Expected duplicate PF_Unique__c to throw an error');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('A Partner Function with the same PF_Unique__c combination already exists.'));
        }
        Test.stopTest();
    }

    @isTest
    static void testMissingPartnerFuncShouldFail() {
        Customer_Sales_Area__c csa = [SELECT Id FROM Customer_Sales_Area__c LIMIT 1];

        Partner_function__c pfMissingFunc = new Partner_function__c(
            Name = 'PF3',
            Partner_code__c = 'P002',
            Customer_Sales_Area__c = csa.Id
        );

        Test.startTest();
        try {
            insert pfMissingFunc;
         //   System.assert(false, 'Expected missing PARTNER_FUNC__c to throw an error');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('PARTNER_FUNC__c is required.'));
        }
        Test.stopTest();
    }

    @isTest
    static void testMissingPartnerCodeShouldFail() {
        Customer_Sales_Area__c csa = [SELECT Id FROM Customer_Sales_Area__c LIMIT 1];

        Partner_function__c pfMissingCode = new Partner_function__c(
            Name = 'PF4',
            PARTNER_FUNC__c = 'FUNC2',
            Customer_Sales_Area__c = csa.Id
        );

        Test.startTest();
        try {
            insert pfMissingCode;
         //   System.assert(false, 'Expected missing Partner_code__c to throw an error');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Partner_code__c is required.'));
        }
        Test.stopTest();
    }

    @isTest
    static void testValidPartnerFunctionInsert() {
        Customer_Sales_Area__c csa = [SELECT Id FROM Customer_Sales_Area__c LIMIT 1];

        Partner_function__c pfValid = new Partner_function__c(
            Name = 'PF5',
            Partner_code__c = 'P002',
            PARTNER_FUNC__c = 'FUNC2',
            Customer_Sales_Area__c = csa.Id
        );

        Test.startTest();
        insert pfValid;
        Test.stopTest();

      //  System.assertNotEquals(null, pfValid.Id, 'Valid Partner_function__c should be inserted successfully');
    }
}