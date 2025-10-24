@isTest
public class OptyTriggerHandlerTest {

    @TestSetup
    static void setupTestData() {
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        try{
        update standardPricebook;
        }Catch(Exception e){}

        Base_UoM_Master__c baseUom = new Base_UoM_Master__c(Name = 'Kilogram');
        insert baseUom;
 
        Product2 prod = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP001',
            Pack_Size__c = '10kg',
            Base_UOM__c = baseUom.Id,
            IsActive = true
        );
        insert prod;
 
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

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

        Lead testLead29 = new Lead(
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
        try{
        insert testLead29;
        }Catch(Exception e){}
    
        Product_Interested__c pi = new Product_Interested__c(
            Lead__c = testLead29.Id,
            Product__c = product.Id,
            Quantity_in_Kgs__c = 50,
            Expected_Price__c = 250,
            Add_in_Opportunity__c = true
        );
        insert pi;

        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(testLead29.Id);
        lc.setConvertedStatus(getConvertedStatus());
        lc.setOpportunityName('Converted Opp');
        lc.setDoNotCreateOpportunity(false);

        Database.LeadConvertResult lcr = Database.convertLead(lc);

        testLead29 = [SELECT Id, IsConverted, ConvertedOpportunityId, ConvertedAccountId FROM Lead WHERE Id = :testLead29.Id];
        Opportunity opp = [SELECT Id, CurrencyIsoCode FROM Opportunity WHERE Id = :testLead29.ConvertedOpportunityId];

        opp.Pricebook2Id = Test.getStandardPricebookId();
        update opp;

        Map<Id, Lead> oldLeadMap = new Map<Id, Lead>{
            testLead29.Id => new Lead(Id = testLead29.Id, IsConverted = false)
        };

        Test.startTest();
        OpportunityTriggerHandler.convertHandler(new List<Lead>{testLead29}, oldLeadMap);
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