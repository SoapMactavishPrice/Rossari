@isTest
public class LeadTriggerHandlerTest {
    
    @testSetup
    static void setupData() {
        Country__c country = new Country__c(
            Name = 'India'
        );
        insert country;
        
        State__c state = new State__c(
            Name = 'Gujarat',
            Country__c = country.Id
        );
        insert state;
        
        City__c city = new City__c(
            Name = 'Ahmedabad',
            State__c = state.Id
        );
        insert city;
        
        Pin_Code__c pinCode = new Pin_Code__c(
            Name = '380015',
            City__c = city.Id
        );
        insert pinCode;
        
        Company__c rossari = new Company__c(
            Name = 'Rossari Biotech Limited'
        );
        insert rossari;
    }
    
    @isTest
    static void testUpdateLeadAddresses_usingPinCode() {
        Pin_Code__c pin = [SELECT Id FROM Pin_Code__c LIMIT 1];
        
        Lead l = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'TestCo',
            MobilePhone = '9876564320',
            Pin_Code__c = pin.Id
        );
        insert l;
        
        Test.startTest();
        List<Lead> leads = [
            SELECT Id,
            Pin_Code__c,
            City__c,
            State__c,
            Country__c,
            Zone__c, 
            Region__c,
            Shipping_Pin_Code__c,
            Shipping_City__c,
            Shipping_State__c
            FROM Lead
            WHERE Id = :l.Id
        ];
        LeadTriggerHandler.updateLeadAddresses(leads);
        Test.stopTest();
    }
    
    @isTest
    static void testSetRossariCompany() {
        Lead l = new Lead(
            FirstName = 'Rossari', 
            LastName = 'Test',
            MobilePhone = '9876532170',
            Company = 'Test'
        );
        insert l;
        
        List<Lead> leads = [SELECT Id,
                            Rossari_Company__c 
                            FROM Lead WHERE Id = :l.Id];
        Test.startTest();
        LeadTriggerHandler.setRossariCompany(leads);
        Test.stopTest();
        
    }
    
    @isTest
    static void testCreateContactInformation() {
        Lead l = new Lead(
            FirstName = 'John', 
            LastName = 'Doe',
            Company = 'Company',
            Email = 'john@x.com', 
            MobilePhone = '9876598123', 
            Title = 'Manager'
        );
        insert l;
        
        List<Lead> leads = [SELECT Id, FirstName, LastName, Email, MobilePhone, Title FROM Lead WHERE Id = :l.Id];
        Test.startTest();
        LeadTriggerHandler.createContactInformation(leads);
        Test.stopTest();
        
        List<Contact_Information__c> infos = [SELECT Id FROM Contact_Information__c WHERE Lead__c = :l.Id];
    }
    
    @isTest
    static void testHandleAfterLeadConvert() {
        
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert testProduct;
        
        PricebookEntry standardPbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false
        );
        insert standardPbe;
        
        Country__c country1 = new Country__c(
            Name = 'India'
        );
        insert country1;
        
        State__c state = new State__c(
            Name = 'Maharashtra',
            Country__c = country1.Id
        );
        insert state;
        
        City__c testCity = new City__c(
            Name = 'Test City',
            State__c = state.id,
            Country__c = country1.id
        );
        insert testCity;
        
        Product2 pro = New Product2();
        pro.Name = 'UNITOX - KRN-HD200T80';
        pro.Family = 'ZFG';
        
        insert pro;
        
        
        
        Lead l = new Lead(
            FirstName = 'Convert', 
            LastName = 'Me',
            Company = 'Comp',
            Department__c = 'Sales',
            MobilePhone = '9098766851',
            City__c = testCity.Id    
        );
        insert l;
        
        Contact_Information__c primaryCi = new Contact_Information__c(
            Lead__c = l.Id, 
            Name = 'Primary',
            Last_Name__c = 'Contact', 
            Is_Primary__c = true,
            Email__c = 'primary@test.com'
        );
        insert primaryCi;
        
        Contact_Information__c secondaryCi = new Contact_Information__c(
            Lead__c = l.Id, 
            Name = 'Secondary',
            Last_Name__c = 'Contact', 
            Is_Primary__c = false,
            Email__c = 'secondary@test.com',
            Department__c = 'Secondary Dept'
        );
        insert secondaryCi;
        
        Product_Interested__c pi = New Product_Interested__c();
        pi.product__c = pro.id;
        pi.Quantity_in_Kgs__c = 10;
        pi.Expected_Price__c = 12;
        pi.Lead__c = l.Id;
        
        insert pi;
        
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(l.Id);
        lc.setDoNotCreateOpportunity(false); 
        lc.setConvertedStatus('Qualified');
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        
        Lead convertedLead = [SELECT Id, IsConverted, ConvertedAccountId, ConvertedContactId, 
                              ConvertedOpportunityId, City__c, Department__c 
                              FROM Lead WHERE Id = :l.Id];
        
        Map<Id, Lead> oldMap = new Map<Id, Lead>{ l.Id => new Lead(Id = l.Id, IsConverted = false) };
            
            Test.startTest();
        LeadTriggerHandler.handleAfterLeadConvert(new List<Lead>{convertedLead}, oldMap);
        Test.stopTest();
        
        List<Contact> secondaryContacts = [SELECT Id, Email FROM Contact 
                                           WHERE Email = 'secondary@test.com' 
                                           AND AccountId = :convertedLead.ConvertedAccountId];
        
        Contact primaryContact = [SELECT Id, Department FROM Contact WHERE Id = :convertedLead.ConvertedContactId];
    }
    
    @isTest
    static void testHandleFollowUpTask() {
        Lead l = new Lead(
            FirstName = 'Follow',
            LastName = 'Up', 
            Company = 'Test Co',
            MobilePhone = '9876554389'
            
        );
        insert l;
        
        Map<Id, Lead> oldMap = new Map<Id, Lead>{ l.Id => new Lead(Id = l.Id) };
            
            Test.startTest();
        LeadTriggerHandler.handleFollowUpTask(new List<Lead>{l}, oldMap);
        Test.stopTest();
        
        List<Task> tasks = [SELECT Id FROM Task WHERE WhatId = :l.Id];
    }
    
    @isTest
    static void testCreateAddressInfoFromConvertedLead() {
        Lead l = new Lead(
            FirstName = 'Addr',
            LastName = 'Test', 
            Company = 'Addr Inc', 
            IsConverted = false,
            MobilePhone = '9876587842'
        );
        insert l;
        
        Account a = new Account(
            Name = 'Addr Account'
        );
        insert a;
        
        update l;
        
        Map<Id, Lead> oldMap = new Map<Id, Lead>{ l.Id => new Lead(Id = l.Id, IsConverted = false) };
            
            Test.startTest();
        LeadTriggerHandler.createAddressInfoFromConvertedLead(new List<Lead>{l}, oldMap);
        Test.stopTest();
        
        List<Address_Information__c> addrList = [SELECT Id FROM Address_Information__c WHERE Account__c = :a.Id];
    }
    
    @isTest
    static void testHandleAfterUpdate() {
        Lead l = new Lead(FirstName = 'Updt', LastName = 'Lead', Company = 'Lead Ltd',MobilePhone = '7787546916');
        insert l;
        
        Account a = new Account(Name = 'Acct');
        insert a;
        
        l.Description = 'Updated Desc';
        update l;
        
        Map<Id, Lead> oldMap = new Map<Id, Lead>{ l.Id => new Lead(Id = l.Id, IsConverted = false) };
            
            Test.startTest();
        LeadTriggerHandler.handleAfterUpdate(new List<Lead>{l}, oldMap);
        Test.stopTest();
        
    }
    
    @isTest
    static void testCreateQuotesForConvertedLeads() {
        Pricebook2 standardPb = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        update standardPb;
        
        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;
        
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPb.Id,
            Product2Id = prod.Id,
            UnitPrice = 200,
            IsActive = true,
            UseStandardPrice = false
        );
        insert pbe;
        
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Contact con = new Contact(LastName = 'Test Contact', AccountId = acc.Id);
        insert con;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id,
            Pricebook2Id = standardPb.Id
        );
        insert opp;
        
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Quantity = 5,
            UnitPrice = 180,
            PricebookEntryId = pbe.Id
        );
        insert oli;
        
        Country__c country = [SELECT Id FROM Country__c LIMIT 1];
        State__c state = [SELECT Id FROM State__c WHERE Country__c = :country.Id LIMIT 1];
        City__c city = [SELECT Id FROM City__c WHERE State__c = :state.Id LIMIT 1];
        Pin_Code__c pin = [SELECT Id FROM Pin_Code__c WHERE City__c = :city.Id LIMIT 1];
        Company__c comp = [SELECT Id FROM Company__c LIMIT 1];
        
        Lead lead = new Lead(
            FirstName = 'Converted',
            LastName = 'Lead',
            Company = 'Lead Co',
            MobilePhone = '1234567890',
            Email = 'lead@test.com',   
            Create_Quote_upon_Conversion__c = true,
            Inco_Terms__c = 'FOB',
        //    Payment_Term__c = 'Advance',
            Bill_to__c = 'BillTo',
            Ship_to__c = 'ShipTo',
            Loading_Port__c = 'Mumbai',
            Destination_Port__c = 'Dubai',
            Quote_Valid_From__c = Date.today(),
            Quote_Valid_To__c = Date.today().addDays(10),
            Destination__c = 'Dubai',
            Country_of_Origin__c = country.Id,
            Country_of_Destination__c = country.Id,
            Pre_Carriage_Mode__c = 'Sea',
            Place_of_Supplier__c = 'Mumbai',
            Vessel_Flight_No__c = 'VF123',
            Street_1__c = 'Addr 1',
            Street_2__c = 'Addr 2',
            Street_3__c = 'Addr 3',
            Pin_Code__c = pin.Id,
            City__c = city.Id,
            State__c = state.Id,
            Country__c = country.Id,
            Shipping_Street_1__c = 'Ship 1',
            Shipping_Street_2__c = 'Ship 2',
            Shipping_Street_3__c = 'Ship 3',
            Shipping_Pin_Code__c = pin.Id,
            Shipping_City__c = city.Id,
            Shipping_State__c = state.Id,
            Shipping_Country__c = country.Id
        );
        insert lead;
        
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(lead.Id);
        lc.setDoNotCreateOpportunity(false);
        lc.setConvertedStatus('Qualified');
        lc.setAccountId(acc.Id);
        lc.setOpportunityId(opp.Id);
        Database.convertLead(lc);
        
        Test.startTest();
        LeadTriggerHandler.createQuotesForConvertedLeads(new List<Id>{lead.Id});
        Test.stopTest();
    }
 	
    @isTest
static void testLeadScoreRatingWithFormulaField() {
    // Cold: Total Score = 10 (GateKeeper) + 10 (AdHoc) + 5 (No Interest) + 10 (6 to 12 months) = 35
    Lead coldLead = new Lead(
        FirstName = 'Cold',
        LastName = 'Lead',
        Company = 'Cold Co',
        MobilePhone = '9991111111',
        Authority__c = 'GateKeeper',
        Budget__c = 'Alternative / AdHoc Budget Source',
        Need__c = 'No Interest',
        Timeline__c = '6 to 12 months'
    );

    // Warm: Total Score = 20 (Influencer) + 15 (Half Year) + 20 (Evaluating Competitor) + 15 (3 to 6 months) = 70
    Lead warmLead = new Lead(
        FirstName = 'Warm',
        LastName = 'Lead',
        Company = 'Warm Co',
        MobilePhone = '9992222222',
        Authority__c = 'Influencer',
        Budget__c = 'Forecast for Next Half Year',
        Need__c = 'Evaluating Competitor Product',
        Timeline__c = '3 to 6 months'
    );

    // Hot: Total Score = 25 + 25 + 25 + 25 = 100
    Lead hotLead = new Lead(
        FirstName = 'Hot',
        LastName = 'Lead',
        Company = 'Hot Co',
        MobilePhone = '9993333333',
        Authority__c = 'Right Person Contact',
        Budget__c = 'Forecast for Next Quarter',
        Need__c = 'Yes',
        Timeline__c = 'Immediate'
    );

    insert new List<Lead>{ coldLead, warmLead, hotLead };

    List<Lead> insertedLeads = [SELECT Id, Rating, Lead_Score__c FROM Lead WHERE Id IN :new List<Id>{coldLead.Id, warmLead.Id, hotLead.Id}];

    for (Lead l : insertedLeads) {
        
        if (l.Lead_Score__c <= 50) {
            
        } else if (l.Lead_Score__c <= 75) {
           
        } else {
            
        }
    }
}

    
}