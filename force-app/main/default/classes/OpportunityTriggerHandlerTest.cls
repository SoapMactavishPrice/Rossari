@isTest
public class OpportunityTriggerHandlerTest {
    
    // Utility method to create an Active User
    private static User createActiveUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];

        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser' + System.currentTimeMillis() + '@example.com',
            Username = 'testuser' + System.currentTimeMillis() + '@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert u;
        return u;
    }


    @isTest
    static void testOpportunityLineItemsCreation() {

        Id standardPricebookId = Test.getStandardPricebookId();
        Pricebook2 pb = new Pricebook2(Id = standardPricebookId, IsActive = true);
        try { update pb; } catch (Exception e) {}

        Product2 prod = new Product2(Name='Test Product', IsActive=true);
        insert prod;

        Lead lead = new Lead(
            FirstName='TestFirstName',
            LastName='TestLead',
            Company='Test Company',
            MobilePhone='9876543210'
        );
        insert lead;

        Product_Interested__c pi = new Product_Interested__c(
            Lead__c = lead.Id,
            Product__c = prod.Id,
            Quantity_in_Kgs__c = 10,
            Expected_Price__c = 120,
            Quantity_Frequency__c = 'Per/Month',
            Add_in_Opportunity__c = true
        );
        insert pi;

        String convertedStatus = [SELECT MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1].MasterLabel;

        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(lead.Id);
        lc.setConvertedStatus(convertedStatus);
        lc.setDoNotCreateOpportunity(false);

        Database.LeadConvertResult lcr = Database.convertLead(lc);

        Lead oldLead = [SELECT Id, IsConverted FROM Lead WHERE Id = :lead.Id];
        Lead newLead = [SELECT Id, IsConverted FROM Lead WHERE Id = :lead.Id];

        Map<Id, Lead> oldMap = new Map<Id, Lead>{ oldLead.Id => oldLead };
        List<Lead> newList = new List<Lead>{ newLead };

        Test.startTest();
        OpportunityTriggerHandler.convertHandler(newList, oldMap);
        Test.stopTest();
    }


    @isTest
    static void testMarkConvertedOpportunitiesFuture() {
        Set<Id> oppIds = new Set<Id>{ '006000000000000000' };
        Test.startTest();
        OpportunityTriggerHandler.markConvertedOpportunitiesFuture(oppIds);
        Test.stopTest();
    }


    @isTest
    static void testSetStandardPricebookAndName() {

        Account acc = new Account(Name='Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name='Old Name',
            CloseDate=Date.today().addDays(10),
            StageName='Prospecting',
            AccountId = acc.Id
        );
        insert opp;

        List<Opportunity> oppList = [
            SELECT Id, Pricebook2Id, AccountId
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        Test.startTest();
        OpportunityTriggerHandler.setStandardPricebook(oppList);
        OpportunityTriggerHandler.setConvertedOpportunityName(oppList);
        Test.stopTest();
    }


    @isTest
    static void testGetLostReasonPicklist() {
        Test.startTest();
        OpportunityTriggerHandler.getLostReasonPicklist();
        Test.stopTest();
    }


    @isTest
    static void testUpdateOpportunityStatus() {

        Opportunity opp = new Opportunity(
            Name='Test Opp',
            CloseDate=Date.today().addDays(10),
            StageName='Prospecting'
        );
        insert opp;

        Map<String, Object> data = new Map<String, Object>();
        data.put('opportunityId', opp.Id);
        data.put('lostReason', 'Others');
        data.put('note', 'Some note');
        data.put('nextFollowUp', String.valueOf(Date.today().addDays(5)));
        data.put('otherReasons', 'Other detail');

        Test.startTest();
        OpportunityTriggerHandler.updateOpportunityStatus(data);
        Test.stopTest();
    }


    @isTest
    static void testUpdateOpportunityStatusCompetitor() {

        Opportunity opp = new Opportunity(
            Name='Test Opp 2',
            CloseDate=Date.today().addDays(10),
            StageName='Prospecting'
        );
        insert opp;

        Map<String, Object> data = new Map<String, Object>();
        data.put('opportunityId', opp.Id);
        data.put('lostReason', 'Lost to Competitor');
        data.put('note', 'Lost due to competitor');
        data.put('nextFollowUp', String.valueOf(Date.today().addDays(2)));
        data.put('competitorLostTo', null);
        data.put('competitorPrice', '150');
        data.put('competitorProduct', 'Product X');

        Test.startTest();
        OpportunityTriggerHandler.updateOpportunityStatus(data);
        Test.stopTest();
    }


    @isTest
    static void testHandleFollowUpTask() {

        User u = createActiveUser();

        System.runAs(u) {

            Account acc = new Account(Name='Test Account');
            insert acc;

            Opportunity opp = new Opportunity(
                Name='FollowUp Opp',
                CloseDate=Date.today().addDays(1),
                StageName='Prospecting',
                AccountId = acc.Id,
                OwnerId = u.Id
            );
            insert opp;

            Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>{ opp.Id => opp };

            Opportunity newOpp = new Opportunity(
                Id = opp.Id,
                Next_Follow_Up__c = Date.today().addDays(4)
            );

            List<Opportunity> newOpps = new List<Opportunity>{ newOpp };

            Test.startTest();
            OpportunityTriggerHandler.handleFollowUpTask(newOpps, oldMap);
            Test.stopTest();
        }
    }
}