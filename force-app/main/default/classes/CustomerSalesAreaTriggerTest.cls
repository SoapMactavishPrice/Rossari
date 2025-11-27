@isTest
public class CustomerSalesAreaTriggerTest {
    
    
    @testSetup
    static void setupData() {
        // Create related lookup records
        Distribution_Channel__c dist = new Distribution_Channel__c(Name = 'DIST01');
        Division__c div = new Division__c(Name = 'DIV01');
        Sales_Organisation__c org = new Sales_Organisation__c(Name = 'ORG01');
        Company__c com = new Company__c(Name = 'RBL');
        Account code =new Account(Name = 'Test');
        insert new List<SObject>{dist, div, org, com, code};
            
            // Existing CSA record
            Customer_Sales_Area__c existingCSA = new Customer_Sales_Area__c(
                Customer_Code__c = 'CUST001',
                Company__c = com.id,
                Distribution_Channel__c = dist.Id,
                Division__c = div.Id,
                Sales_Organisation__c = org.Id,
                Comapany_Code__c = code.id
            );
        insert existingCSA;
    }
    
    
    @isTest
    static void testValidInsert() {
        Distribution_Channel__c dist = [SELECT Id FROM Distribution_Channel__c LIMIT 1];
        Division__c div = [SELECT Id FROM Division__c LIMIT 1];
        Sales_Organisation__c org = [SELECT Id FROM Sales_Organisation__c LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Customer_Sales_Area__c csa = new Customer_Sales_Area__c(
            Customer_Code__c = 'CUST002',
            Distribution_Channel__c = dist.Id,
            Division__c = div.Id,
            Sales_Organisation__c = org.Id,
            Comapany_Code__c = acc.id
        );
        
        Test.startTest();
        insert csa;
        Test.stopTest();
        
        System.assertNotEquals(null, csa.Id, 'Record should be inserted successfully');
    }
    
    @isTest
    static void testDuplicateAgainstExistingRecord() {
        Distribution_Channel__c dist = [SELECT Id FROM Distribution_Channel__c LIMIT 1];
        Division__c div = [SELECT Id FROM Division__c LIMIT 1];
        Sales_Organisation__c org = [SELECT Id FROM Sales_Organisation__c LIMIT 1];
        
        Customer_Sales_Area__c csa = new Customer_Sales_Area__c(
            Customer_Code__c = 'CUST001', // Same as existing
            Distribution_Channel__c = dist.Id,
            Division__c = div.Id,
            Sales_Organisation__c = org.Id
        );
        
        Test.startTest();
        try {
            insert csa;
            System.assert(false, 'Expected duplicate error');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('already exists'), 'Error should indicate duplicate');
        }
        Test.stopTest();
    }
}