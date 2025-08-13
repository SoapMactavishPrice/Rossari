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
            Region__c
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
            MobilePhone = '9999999999', 
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
        
        Country__c country = new Country__c(
            Name = 'India'
        );
        insert country;
        
        State__c state = new State__c(
            Name = 'Maharashtra',
            Country__c = country.Id
        );
        insert state;
        
        City__c testCity = new City__c(
            Name = 'Test City',
            State__c = state.id,
            Country__c = country.id
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
            Next_Follow_Up_in_Days__c = 3
        );
        insert l;
        
        Map<Id, Lead> oldMap = new Map<Id, Lead>{ l.Id => new Lead(Id = l.Id, Next_Follow_Up_in_Days__c = null) };
            
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
            IsConverted = false
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
        Lead l = new Lead(FirstName = 'Updt', LastName = 'Lead', Company = 'Lead Ltd');
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
}