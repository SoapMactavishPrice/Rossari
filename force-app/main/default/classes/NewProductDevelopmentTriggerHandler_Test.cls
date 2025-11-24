@isTest
public class NewProductDevelopmentTriggerHandler_Test {

    @isTest
    static void testBeforeInsertLogic() {

        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        New_Product_Development__c npd1 = new New_Product_Development__c(
            Name = 'Test NPD 1'
        );

        New_Product_Development__c npd2 = new New_Product_Development__c(
            Name = 'Test NPD 2',
            Sales_Person_Name__c = u.Id
        );

        Test.startTest();
        insert new List<New_Product_Development__c>{ npd1, npd2 };
        Test.stopTest();

        List<New_Product_Development__c> insertedRecords = [
            SELECT Id, Name, Sales_Person_Name__c, Is_New_NPD__c, Stage__c
            FROM New_Product_Development__c
            ORDER BY Name
        ];
    }
}