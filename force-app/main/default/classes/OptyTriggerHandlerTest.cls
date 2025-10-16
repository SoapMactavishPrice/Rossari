@isTest
public class OptyTriggerHandlerTest {

    @TestSetup
    static void setupTestData() {
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert testProduct;

        Id standardPriceBookId = Test.getStandardPricebookId();

        PricebookEntry standardPBE = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true,
            CurrencyIsoCode = 'INR'
        );
        insert standardPBE;
    }

    @isTest
    static void testConvertHandler() {
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];

        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Country__c country = new Country__c(Name = 'India');
        insert country;

        State__c state = new State__c(Name = 'Karnataka', Country__c = country.Id, Zone__c = 'South');
        insert state;

        City__c city = new City__c(Name = 'Bangalore', State__c = state.Id);
        insert city;

        Pin_Code__c postal = new Pin_Code__c(Name = '560001', City__c = city.Id);
        insert postal;

        Lead testLead = new Lead(
            FirstName = 'Jane',
            LastName = 'Doe',
            Company = 'Test Inc',
            Street = '123 Lane',
            City__c = city.Id,
            State__c = state.Id,
            Country__c = country.Id,
            Pin_Code__c = postal.Id,
            Status = 'Open - Not Contacted',
            Zone__c = 'South',
            CurrencyIsoCode = 'INR',
            MobilePhone = '8987453243'
        );
        insert testLead;

        Product_Interested__c pi = new Product_Interested__c(
            Lead__c = testLead.Id,
            Product__c = product.Id,
            Quantity_in_Kgs__c = 50,
            Expected_Price__c = 250,
            Add_in_Opportunity__c = true
        );
        insert pi;

        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(testLead.Id);
        lc.setConvertedStatus(getConvertedStatus());
        lc.setOpportunityName('Converted Opp');
        lc.setDoNotCreateOpportunity(false);

        Database.LeadConvertResult lcr = Database.convertLead(lc);

        testLead = [SELECT Id, IsConverted, ConvertedOpportunityId, ConvertedAccountId FROM Lead WHERE Id = :testLead.Id];
        Opportunity opp = [SELECT Id, CurrencyIsoCode FROM Opportunity WHERE Id = :testLead.ConvertedOpportunityId];

        opp.Pricebook2Id = Test.getStandardPricebookId();
        update opp;

        Map<Id, Lead> oldLeadMap = new Map<Id, Lead>{
            testLead.Id => new Lead(Id = testLead.Id, IsConverted = false)
        };

        Test.startTest();
        OpportunityTriggerHandler.convertHandler(new List<Lead>{testLead}, oldLeadMap);
        Test.stopTest();

        List<OpportunityLineItem> oliList = [
            SELECT OpportunityId, Quantity, UnitPrice, PricebookEntryId
            FROM OpportunityLineItem 
            WHERE OpportunityId = :opp.Id
        ];
    }

    public static String getConvertedStatus() {
        return [SELECT MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1].MasterLabel;
    }
}