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

    @isTest
    static void testAfterInsertCreateProductInterestedForLead() {
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company'
        );
        insert testLead;

        New_Product_Development__c npd = new New_Product_Development__c(
            Name = 'Test Product',
            Lead__c = testLead.Id,
            Product_Quantity__c = 100,
            Expected_Price_per_Kg__c = 50
        );

        Test.startTest();
        insert npd;
        Test.stopTest();

        List<Product_Interested__c> productInterestedList = [
            SELECT Id, Lead__c, New_Product__c, New_Product_Name__c, 
                   Quantity_in_Kgs__c, Expected_Price__c
            FROM Product_Interested__c
        ];
    }

    @isTest
    static void testAfterInsertCreateProductInterestedForAccount() {
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;

        New_Product_Development__c npd = new New_Product_Development__c(
            Name = 'Test Product',
            Name_of_the_Customer__c = testAccount.Id,
            Product_Quantity__c = 200,
            Expected_Price_per_Kg__c = 75
        );

        Test.startTest();
        insert npd;
        Test.stopTest();

        List<Product_Interested__c> productInterestedList = [
            SELECT Id, Account__c, New_Product__c, New_Product_Name__c, 
                   Quantity_in_Kgs__c, Expected_Price__c
            FROM Product_Interested__c
        ];
    }

    @isTest
    static void testAfterInsertCreateProductInterestedForOpportunity() {
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;

        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpp;

        New_Product_Development__c npd = new New_Product_Development__c(
            Name = 'Test Product',
            Opportunity__c = testOpp.Id,
            Product_Quantity__c = 300,
            Expected_Price_per_Kg__c = 100
        );

        Test.startTest();
        insert npd;
        Test.stopTest();

        List<Product_Interested__c> productInterestedList = [
            SELECT Id, Opportunity__c, New_Product__c, New_Product_Name__c, 
                   Quantity_in_Kgs__c, Expected_Price__c
            FROM Product_Interested__c
        ];
    }

    @isTest
    static void testAfterInsertCreateProductInterestedForAll() {
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company'
        );
        insert testLead;

        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;

        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpp;

        New_Product_Development__c npd = new New_Product_Development__c(
            Name = 'Test Product',
            Lead__c = testLead.Id,
            Name_of_the_Customer__c = testAccount.Id,
            Opportunity__c = testOpp.Id,
            Product_Quantity__c = 400,
            Expected_Price_per_Kg__c = 125
        );

        Test.startTest();
        insert npd;
        Test.stopTest();

        List<Product_Interested__c> productInterestedList = [
            SELECT Id, Lead__c, Account__c, Opportunity__c, New_Product__c, 
                   New_Product_Name__c, Quantity_in_Kgs__c, Expected_Price__c
            FROM Product_Interested__c
        ];
    }

    @isTest
    static void testAfterUpdateLeadChange() {
        Lead testLead1 = new Lead(
            FirstName = 'Test',
            LastName = 'Lead1',
            Company = 'Test Company 1'
        );
        insert testLead1;

        Lead testLead2 = new Lead(
            FirstName = 'Test',
            LastName = 'Lead2',
            Company = 'Test Company 2'
        );
        insert testLead2;

        New_Product_Development__c npd = new New_Product_Development__c(
            Name = 'Test Product',
            Lead__c = testLead1.Id,
            Product_Quantity__c = 100,
            Expected_Price_per_Kg__c = 50
        );
        insert npd;

        List<Product_Interested__c> initialProductInterested = [
            SELECT Id FROM Product_Interested__c
        ];

        npd.Lead__c = testLead2.Id;

        Test.startTest();
        update npd;
        Test.stopTest();

        List<Product_Interested__c> finalProductInterested = [
            SELECT Id, Lead__c FROM Product_Interested__c
        ];
    }

    @isTest
    static void testAfterUpdateAccountChange() {
        Account testAccount1 = new Account(
            Name = 'Test Account 1'
        );
        insert testAccount1;

        Account testAccount2 = new Account(
            Name = 'Test Account 2'
        );
        insert testAccount2;

        New_Product_Development__c npd = new New_Product_Development__c(
            Name = 'Test Product',
            Name_of_the_Customer__c = testAccount1.Id,
            Product_Quantity__c = 200,
            Expected_Price_per_Kg__c = 75
        );
        insert npd;

        List<Product_Interested__c> initialProductInterested = [
            SELECT Id FROM Product_Interested__c
        ];

        npd.Name_of_the_Customer__c = testAccount2.Id;

        Test.startTest();
        update npd;
        Test.stopTest();

        List<Product_Interested__c> finalProductInterested = [
            SELECT Id, Account__c FROM Product_Interested__c
        ];
    }

    @isTest
    static void testAfterUpdateOpportunityChange() {
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;

        Opportunity testOpp1 = new Opportunity(
            Name = 'Test Opportunity 1',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpp1;

        Opportunity testOpp2 = new Opportunity(
            Name = 'Test Opportunity 2',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpp2;

        New_Product_Development__c npd = new New_Product_Development__c(
            Name = 'Test Product',
            Opportunity__c = testOpp1.Id,
            Product_Quantity__c = 300,
            Expected_Price_per_Kg__c = 100
        );
        insert npd;

        List<Product_Interested__c> initialProductInterested = [
            SELECT Id FROM Product_Interested__c
        ];

        npd.Opportunity__c = testOpp2.Id;

        Test.startTest();
        update npd;
        Test.stopTest();

        List<Product_Interested__c> finalProductInterested = [
            SELECT Id, Opportunity__c FROM Product_Interested__c
        ];
    }

    @isTest
    static void testAfterUpdateMultipleChanges() {
        Lead testLead1 = new Lead(
            FirstName = 'Test',
            LastName = 'Lead1',
            Company = 'Test Company 1'
        );
        insert testLead1;

        Lead testLead2 = new Lead(
            FirstName = 'Test',
            LastName = 'Lead2',
            Company = 'Test Company 2'
        );
        insert testLead2;

        Account testAccount1 = new Account(
            Name = 'Test Account 1'
        );
        insert testAccount1;

        Account testAccount2 = new Account(
            Name = 'Test Account 2'
        );
        insert testAccount2;

        New_Product_Development__c npd = new New_Product_Development__c(
            Name = 'Test Product',
            Lead__c = testLead1.Id,
            Name_of_the_Customer__c = testAccount1.Id,
            Product_Quantity__c = 400,
            Expected_Price_per_Kg__c = 150
        );
        insert npd;

        List<Product_Interested__c> initialProductInterested = [
            SELECT Id FROM Product_Interested__c
        ];

        npd.Lead__c = testLead2.Id;
        npd.Name_of_the_Customer__c = testAccount2.Id;

        Test.startTest();
        update npd;
        Test.stopTest();

        List<Product_Interested__c> finalProductInterested = [
            SELECT Id, Lead__c, Account__c FROM Product_Interested__c
        ];
    }

    @isTest
    static void testAfterUpdateNoChanges() {
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company'
        );
        insert testLead;

        New_Product_Development__c npd = new New_Product_Development__c(
            Name = 'Test Product',
            Lead__c = testLead.Id,
            Product_Quantity__c = 100,
            Expected_Price_per_Kg__c = 50
        );
        insert npd;

        List<Product_Interested__c> initialProductInterested = [
            SELECT Id FROM Product_Interested__c
        ];

        npd.Name = 'Updated Product Name';

        Test.startTest();
        update npd;
        Test.stopTest();

        List<Product_Interested__c> finalProductInterested = [
            SELECT Id FROM Product_Interested__c
        ];
    }

    @isTest
    static void testBulkInsert() {
        List<New_Product_Development__c> npdList = new List<New_Product_Development__c>();
        
        for(Integer i = 0; i < 200; i++) {
            New_Product_Development__c npd = new New_Product_Development__c(
                Name = 'Test NPD ' + i
            );
            npdList.add(npd);
        }

        Test.startTest();
        insert npdList;
        Test.stopTest();

        List<New_Product_Development__c> insertedRecords = [
            SELECT Id, Name, Is_New_NPD__c, Stage__c
            FROM New_Product_Development__c
        ];
    }

    @isTest
    static void testBulkUpdate() {
        List<Lead> leadList = new List<Lead>();
        List<New_Product_Development__c> npdList = new List<New_Product_Development__c>();
        
        for(Integer i = 0; i < 100; i++) {
            Lead l = new Lead(
                FirstName = 'Test',
                LastName = 'Lead' + i,
                Company = 'Company ' + i
            );
            leadList.add(l);
        }
        insert leadList;

        for(Integer i = 0; i < 100; i++) {
            New_Product_Development__c npd = new New_Product_Development__c(
                Name = 'Test NPD ' + i,
                Lead__c = leadList[i].Id,
                Product_Quantity__c = i * 10,
                Expected_Price_per_Kg__c = i * 5
            );
            npdList.add(npd);
        }
        insert npdList;

        List<New_Product_Development__c> npdsToUpdate = new List<New_Product_Development__c>();
        for(Integer i = 0; i < 100; i++) {
            New_Product_Development__c npd = npdList[i];
            npd.Lead__c = (i < 99) ? leadList[i + 1].Id : leadList[0].Id;
            npdsToUpdate.add(npd);
        }

        Test.startTest();
        update npdsToUpdate;
        Test.stopTest();

        List<Product_Interested__c> productInterestedList = [
            SELECT Id FROM Product_Interested__c
        ];
    }

    @isTest
    static void testEmptyList() {
        List<New_Product_Development__c> npdList = new List<New_Product_Development__c>();

        Test.startTest();
        NewProductDevelopmentTriggerHandler.handleBeforeInsert(npdList);
        NewProductDevelopmentTriggerHandler.handleAfterInsert(npdList);
        Test.stopTest();
    }
}