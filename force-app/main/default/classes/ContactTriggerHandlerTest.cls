@isTest
public class ContactTriggerHandlerTest {
    @isTest
    static void testUpdateContactAddresses() {
        // Create related hierarchy: Region > Country > Zone > State > City > Pincode
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
        
        // Create a Contact with only the Pin_Code__c set
        Contact contact = new Contact(LastName = 'Test User', Pin_Code__c = pinCode.Id);
        insert contact;
        
        // Fetch contact again to simulate Trigger.new
        Contact insertedContact = [SELECT Id, Pin_Code__c FROM Contact WHERE Id = :contact.Id];
        
        // Run the handler logic
        List<Contact> contactList = new List<Contact>{ insertedContact };
            Test.startTest();
        ContactTriggerHandler.updateContactAddresses(contactList);
        Test.stopTest();
        
        // Check if fields were updated correctly
        Contact updated = contactList[0];
        
    }
    
    @isTest
    static void testWithNullPinCode() {
        // Contact without pincode should not cause error
        Contact contact = new Contact(LastName = 'No Pin');
        insert contact;
        
        // Include Pin_Code__c in the query to avoid SObjectException
        Contact inserted = [SELECT Id, Pin_Code__c FROM Contact WHERE Id = :contact.Id];
        List<Contact> contactList = new List<Contact>{ inserted };
            
            Test.startTest();
        ContactTriggerHandler.updateContactAddresses(contactList);
        Test.stopTest();
        
        
    }
}