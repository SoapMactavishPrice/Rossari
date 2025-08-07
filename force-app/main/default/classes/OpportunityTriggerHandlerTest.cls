@isTest
private class OpportunityTriggerHandlerTest {
    
    @testSetup
    static void setupTestData() {
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        
        List<Product2> products = new List<Product2>{
            new Product2(Name = 'Test Product 1', IsActive = true),
            new Product2(Name = 'Test Product 2', IsActive = true)
        };
        insert products;
        
        List<PricebookEntry> pbes = new List<PricebookEntry>();
        for(Product2 p : products) {
            pbes.add(new PricebookEntry(
                Pricebook2Id = standardPricebook.Id,
                Product2Id = p.Id,
                UnitPrice = 100,
                IsActive = true
            ));
        }
        insert pbes;
        
        List<Lead> leads = new List<Lead>{
            new Lead(FirstName = 'Test', LastName = 'Lead 1', Company = 'Test Company 1'),
            new Lead(FirstName = 'Test', LastName = 'Lead 2', Company = 'Test Company 2')
        };
        insert leads;
        
        List<Product_Interested__c> productInterests = new List<Product_Interested__c>();
        for(Integer i = 0; i < leads.size(); i++) {
            productInterests.add(new Product_Interested__c(
                Lead__c = leads[i].Id,
                Product__c = products[i].Id,
                Quantity_in_Kgs__c = 10,
                Expected_Price__c = 100,
                Quantity_Frequency__c = 'Per/Month',
                Add_in_Opportunity__c = true
            ));
        }
        insert productInterests;
    }
    
    @isTest
    static void testConvertHandlerWithProductsToOpportunity() {

        Lead testLead = [SELECT Id FROM Lead WHERE LastName = 'Lead 1' LIMIT 1];
        Product_Interested__c pi = [SELECT Id FROM Product_Interested__c WHERE Lead__c = :testLead.Id LIMIT 1];
        
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(testLead.Id);
        lc.setDoNotCreateOpportunity(false);
        lc.setConvertedStatus('Qualified');
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        
        Lead convertedLead = [SELECT Id, IsConverted, ConvertedAccountId, ConvertedOpportunityId FROM Lead WHERE Id = :testLead.Id];

        Map<Id, Lead> oldLeadMap = new Map<Id, Lead>();
        oldLeadMap.put(testLead.Id, new Lead(Id = testLead.Id, IsConverted = false));
        
        Test.startTest();
        OpportunityTriggerHandler.convertHandler(new List<Lead>{convertedLead}, oldLeadMap);
        Test.stopTest();

        List<OpportunityLineItem> olis = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :convertedLead.ConvertedOpportunityId];

        Product_Interested__c updatedPi = [SELECT Account__c FROM Product_Interested__c WHERE Id = :pi.Id];
    }
    
    @isTest
    static void testConvertHandlerWithoutProductsToOpportunity() {
        
        Lead testLead = [SELECT Id FROM Lead WHERE LastName = 'Lead 2' LIMIT 1];
        Product_Interested__c pi = [SELECT Id FROM Product_Interested__c WHERE Lead__c = :testLead.Id LIMIT 1];
        pi.Add_in_Opportunity__c = false;
        update pi;
        
        // Convert the lead
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(testLead.Id);
        lc.setDoNotCreateOpportunity(false);
        lc.setConvertedStatus('Qualified');
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        
        Lead convertedLead = [SELECT Id, IsConverted, ConvertedAccountId, ConvertedOpportunityId FROM Lead WHERE Id = :testLead.Id];
        
        Map<Id, Lead> oldLeadMap = new Map<Id, Lead>();
        oldLeadMap.put(testLead.Id, new Lead(Id = testLead.Id, IsConverted = false));
        
        Test.startTest();
        OpportunityTriggerHandler.convertHandler(new List<Lead>{convertedLead}, oldLeadMap);
        Test.stopTest();

        List<OpportunityLineItem> olis = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :convertedLead.ConvertedOpportunityId];
        
        Product_Interested__c updatedPi = [SELECT Account__c FROM Product_Interested__c WHERE Id = :pi.Id];
    }
    
    @isTest
    static void testConvertHandlerWithNoConversion() {
       
        Lead testLead = [SELECT Id,IsConverted FROM Lead WHERE LastName = 'Lead 1' LIMIT 1];
        
        Map<Id, Lead> oldLeadMap = new Map<Id, Lead>();
        oldLeadMap.put(testLead.Id, new Lead(Id = testLead.Id, IsConverted = false));
        
        Test.startTest();
        OpportunityTriggerHandler.convertHandler(new List<Lead>{testLead}, oldLeadMap);
        Test.stopTest();
        
        List<OpportunityLineItem> olis = [SELECT Id FROM OpportunityLineItem];
       
        
        List<Product_Interested__c> pis = [SELECT Account__c FROM Product_Interested__c WHERE Lead__c = :testLead.Id];
        for(Product_Interested__c pi : pis) {
           
        }
    }
    

    @isTest
    static void testGetLostReasonPicklist() {
        Test.startTest();
        List<String> picklistValues = OpportunityTriggerHandler.getLostReasonPicklist();
        Test.stopTest();
    }

    @isTest
    static void testUpdateOpportunityStatusBasic() {
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = System.today().addDays(30),
            Loss_Reason__c = null
        );
        insert testOpp;
        
        Map<String, Object> oppData = new Map<String, Object>{
            'opportunityId' => testOpp.Id,
            'lostReason' => 'Price',
            'note' => 'Test note',
            'nextFollowUp' => String.valueOf(System.today().addDays(14))
        };
        
        Test.startTest();
        OpportunityTriggerHandler.updateOpportunityStatus(oppData);
        Test.stopTest();
    }
    
 /*   @isTest
    static void testUpdateOpportunityStatusCompetitor() {
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = System.today().addDays(30),
            Loss_Reason__c = null
        );
        insert testOpp;
        
        Map<String, Object> oppData = new Map<String, Object>{
            'opportunityId' => testOpp.Id,
            'lostReason' => 'Lost to Competitor',
            'note' => 'Competitor won',
            'competitorLostTo' => 'Acme Corp',
            'competitorPrice' => '1000',
            'competitorProduct' => 'Competitor Product X'
        };
        
        Test.startTest();
        OpportunityTriggerHandler.updateOpportunityStatus(oppData);
        Test.stopTest();
    }		*/
    
    @isTest
    static void testUpdateOpportunityStatusOthersWithoutReason() {
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = System.today().addDays(30),
            Loss_Reason__c = null
        );
        insert testOpp;
        
        Map<String, Object> oppData = new Map<String, Object>{
            'opportunityId' => testOpp.Id,
            'lostReason' => 'Others',
            'note' => 'Should fail'
        };
        
        Test.startTest();
        try {
            OpportunityTriggerHandler.updateOpportunityStatus(oppData);
        } catch (AuraHandledException e) {}
        Test.stopTest();
    }
    
    @isTest
    static void testUpdateOpportunityStatusOthersWithReason() {
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = System.today().addDays(30),
            Loss_Reason__c = null
        );
        insert testOpp;
        
        Map<String, Object> oppData = new Map<String, Object>{
            'opportunityId' => testOpp.Id,
            'lostReason' => 'Others',
            'note' => 'Other reason test',
            'otherReasons' => 'Custom reason details',
            'nextFollowUp' => String.valueOf(System.today().addDays(7))
        };
        
        Test.startTest();
        OpportunityTriggerHandler.updateOpportunityStatus(oppData);
        Test.stopTest();
    }
    
    @isTest
    static void testUpdateOpportunityStatusInvalidId() {
        Map<String, Object> oppData = new Map<String, Object>{
            'opportunityId' => '001000000000000',
            'lostReason' => 'Price',
            'note' => 'Should fail'
        };
        
        Test.startTest();
        try {
            OpportunityTriggerHandler.updateOpportunityStatus(oppData);
        } catch (AuraHandledException e) {}
        Test.stopTest();
    }

}