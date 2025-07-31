@isTest
public class CompanyTriggerTest {

    @isTest
    static void testBeforeInsert() {
        // Create a test Company__c record
        Company__c company = new Company__c(
            Name = 'Test Company'
           // Billing_Street__c = '123 Main St',
           // Billing_City__c = 'Metropolis',
           // Billing_State__c = 'CA',
          //  Billing_Postal_Code__c = '90001'
        );

        Test.startTest();
        insert company;
        Test.stopTest();

      //  Company__c inserted = [SELECT Id, Name, Billing_Street__c FROM Company__c WHERE Id = :company.Id];
      
    }

    @isTest
    static void testBeforeUpdate() {
        // Insert initial Company__c record
        Company__c company = new Company__c(
            Name = 'Initial Company'
           // Billing_Street__c = '456 First Ave'
        );
        insert company;

        // Update record to trigger before update logic
      //  company.Billing_Street__c = '789 New Ave';

        Test.startTest();
        update company;
        Test.stopTest();

     //   Company__c updated = [SELECT Id, Billing_Street__c FROM Company__c WHERE Id = :company.Id];
    }
}