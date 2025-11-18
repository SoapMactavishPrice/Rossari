@isTest
public class AddressInformationTriggerTest {

    @isTest
    static void testInsertAndUpdateTrigger() {
        
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        City__c testCity = new City__c(
            Name = 'Mumbai'
        );
        insert testCity;

        Address_Information__c addressRecord = new Address_Information__c(
            Name = 'Test Address',
            Account__c = acc.id,
            City__c = testCity.Id 
        );

        Test.startTest();
        insert addressRecord; 

        Address_Information__c insertedRec = [
            SELECT Id, Name, City__c 
            FROM Address_Information__c 
            WHERE Id = :addressRecord.Id
        ];

        City__c newCity = new City__c(Name = 'Pune');
        insert newCity;

        insertedRec.City__c = newCity.Id;

        update insertedRec;
        Test.stopTest();

        Address_Information__c updatedRec = [
            SELECT Id, City__r.Name 
            FROM Address_Information__c 
            WHERE Id = :insertedRec.Id
        ];
    }
}