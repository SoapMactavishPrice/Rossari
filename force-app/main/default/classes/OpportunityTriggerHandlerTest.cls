@isTest
public class OpportunityTriggerHandlerTest {
    
    @isTest
    static void testOpportunityLineItemsCreation() {

        // Query the Standard Pricebook
        Id standardPricebookId = Test.getStandardPricebookId();

        Pricebook2 priceBook = new Pricebook2(Id = standardPricebookId, IsActive = true);
        try{
        update priceBook;
        }Catch(Exception e){}
        
        Product2 prod = new Product2(Name='Test Product', IsActive=true);
        insert prod;

        // Create Lead
        Lead lead = new Lead(FirstName='TestFirstName', LastName='TestLead', Company='Test Company', MobilePhone='1234567890');
        insert lead;

        // Create Product_Interested__c record linked to Lead with Add_in_Opportunity__c = true
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

        Database.LeadConvert leadConvert = new Database.LeadConvert();
        leadConvert.setLeadId(lead.Id);
        leadConvert.setConvertedStatus(convertedStatus);
        leadConvert.setDoNotCreateOpportunity(false);

        Database.LeadConvertResult lcr = Database.convertLead(leadConvert);

        // Query Lead again as newLead, oldLead for convertHandler
        Lead oldLead = [SELECT Id, IsConverted FROM Lead WHERE Id = :lead.Id];
        Id oppId = lcr.getOpportunityId();
        Lead newLead = [SELECT Id, IsConverted FROM Lead WHERE Id = :lead.Id];

        Map<Id, Lead> oldMap = new Map<Id, Lead>{ oldLead.Id => oldLead };
        List<Lead> newList = new List<Lead>{ newLead };

        // Create maps needed by convertHandler
        Map<Id, Id> leadToOppMap = new Map<Id, Id>{ lead.Id => oppId };
        Map<Id, Id> leadToAccountMap = new Map<Id, Id>{ lead.Id => lcr.getAccountId() };

        // You need to setup your convertHandler inputs correctly
        // Since your method is static and takes (List<Lead>, Map<Id, Lead>) you call it directly
        
        Test.startTest();
        OpportunityTriggerHandler.convertHandler(newList, oldMap);
        Test.stopTest();

        // This runs the code creating OpportunityLineItems from Product_Interested__c for the converted opportunity.
    }


    @isTest static void testMarkConvertedOpportunitiesFuture() {
        Set<Id> oppIds = new Set<Id>{'006000000000000000'};
        Test.startTest();
        OpportunityTriggerHandler.markConvertedOpportunitiesFuture(oppIds);
        Test.stopTest();
    }

    @isTest static void testSetStandardPricebookAndName() {
        Account acc = new Account(Name='Test Account');
        insert acc;

        Opportunity opp = new Opportunity(Name='Old Name', CloseDate=Date.today().addDays(10), StageName='Prospecting', AccountId = acc.Id);
        insert opp;

        List<Opportunity> oppList = [SELECT Id, Pricebook2Id, AccountId FROM Opportunity WHERE Id = :opp.Id];

        Test.startTest();
        OpportunityTriggerHandler.setStandardPricebook(oppList);
        OpportunityTriggerHandler.setConvertedOpportunityName(oppList);
        Test.stopTest();
    }

    @isTest static void testGetLostReasonPicklist() {
        Test.startTest();
        List<String> picklist = OpportunityTriggerHandler.getLostReasonPicklist();
        Test.stopTest();
    }

    @isTest static void testUpdateOpportunityStatus() {
        Opportunity opp = new Opportunity(Name='Test Opp', CloseDate=Date.today().addDays(10), StageName='Prospecting');
        insert opp;

        Map<String, Object> data = new Map<String, Object>();
        data.put('opportunityId', opp.Id);
        data.put('lostReason', 'Others');
        data.put('note', 'Some note');
        data.put('nextFollowUp', String.valueOf(Date.today().addDays(5)));
        data.put('otherReasons', 'Reason detail here');

        Test.startTest();
        OpportunityTriggerHandler.updateOpportunityStatus(data);
        Test.stopTest();
    }

    @isTest static void testHandleFollowUpTask() {
        User u = [SELECT Id FROM User LIMIT 1];
        u.IsActive = true;
        update u;
        System.runAs(u) {
            Account acc = new Account(Name='Test Account');
            insert acc;
        

        Opportunity opp = new Opportunity(Name='Test Opp', CloseDate=Date.today().addDays(1), StageName='Prospecting', AccountId=acc.Id, OwnerId=u.Id);
        insert opp;

        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>{ opp.Id => opp };
        Opportunity newOpp = opp;
        newOpp.Next_Follow_Up__c = Date.today().addDays(2);

        List<Opportunity> newOpps = new List<Opportunity>{newOpp};

        Test.startTest();
        OpportunityTriggerHandler.handleFollowUpTask(newOpps, oldMap);
        Test.stopTest();
        }
    }
}