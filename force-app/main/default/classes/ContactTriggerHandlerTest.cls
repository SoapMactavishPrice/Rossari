@isTest
public class ContactTriggerHandlerTest {
    @isTest
    static void testUpdateContactAddresses() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Country__c country = new Country__c(Name = 'Test Country', Region__c = 'Asia');
        insert country;
        
        State__c state = new State__c(Name = 'Test State', Country__c = country.Id, Zone__c = 'West');
        insert state;
        
        City__c city = new City__c(Name = 'Test City', State__c = state.Id);
        insert city;
        
        Pin_Code__c pinCode = new Pin_Code__c(Name = '123456', City__c = city.Id);
        insert pinCode;
        
        Contact contact = new Contact(LastName = 'Test User', Pin_Code__c = pinCode.Id);
        insert contact;
        
        Contact insertedContact = [SELECT Id, Pin_Code__c FROM Contact WHERE Id = :contact.Id];
        
        List<Contact> contactList = new List<Contact>{ insertedContact };
            Test.startTest();
        ContactTriggerHandler.updateContactAddresses(contactList);
        Test.stopTest();
        
        Contact updated = contactList[0];
        
    }
    
    @isTest
    static void testWithNullPinCode() {
        Contact contact = new Contact(LastName = 'No Pin');
        insert contact;
        
        Contact inserted = [SELECT Id, Pin_Code__c FROM Contact WHERE Id = :contact.Id];
        List<Contact> contactList = new List<Contact>{ inserted };
            
            Test.startTest();
        ContactTriggerHandler.updateContactAddresses(contactList);
        Test.stopTest();
        
        
    }
}