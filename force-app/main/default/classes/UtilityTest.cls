@isTest
private class UtilityTest {
    @isTest
    static void testAllMethods() {
        // Setup standard pricebook first
        Pricebook2 standardPb = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPb;
        
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = acc.Id);
        insert con;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opp', 
            StageName = 'Prospecting', 
            CloseDate = Date.today(), 
            AccountId = acc.Id,
            Pricebook2Id = standardPb.Id
        );
        insert opp;
        
        Quote qt = new Quote(
            Name = 'Test Quote', 
            OpportunityId = opp.Id,
            Pricebook2Id = standardPb.Id
        );
        insert qt;
        
        Address_Information__c billTo = new Address_Information__c(
            Name = 'Bill To Test', 
            Account__c = acc.Id
        );
        insert billTo;
        
        Address_Information__c shipTo = new Address_Information__c(
            Name = 'Ship To Test', 
            Account__c = acc.Id
        );
        insert shipTo;
        
        Plant__c plant = new Plant__c(Name = 'Test Plant');
        insert plant;
        
        Product2 prod = new Product2(
            Name = 'Test Product', 
            ProductCode = 'TEST001', 
            Plant_Name__c = plant.Id
        );
        insert prod;

        List<Map<String, String>> contactResult = Utility.getContactName(acc.Id, 'Account');
        List<Map<String, String>> contactResult2 = Utility.getContactName(opp.Id, 'Opportunity');
        List<Map<String, String>> contactResult3 = Utility.getContactName(qt.Id, 'Quote');
        
        List<Map<String, String>> billToResult = Utility.getBillTo(acc.Id, 'Account');
        List<Map<String, String>> billToResult2 = Utility.getBillTo(opp.Id, 'Opportunity');
        List<Map<String, String>> billToResult3 = Utility.getBillTo(qt.Id, 'Quote');
        
        List<Map<String, String>> shipToResult = Utility.getShipTo(acc.Id, 'Account');
        List<Map<String, String>> shipToResult2 = Utility.getShipTo(opp.Id, 'Opportunity');
        
        Address_Information__c shipToAddress = Utility.getShipToAddressInformation(shipTo.Id);
        
        List<Map<String, String>> plantResult = Utility.getPlant();
        
        String titleCaseResult = Utility.toTitleCase('test title case');
        
        List<String> plantProductsResult = Utility.getProductsPlant('TEST001');
        
        String salutationResult = Utility.getContactSalutation('Mr.');
        
        try {
            List<Map<String, String>> invalidContact = Utility.getContactName('invalidId', 'Account');
        } catch (Exception e) {
        }
        
        try {
            List<Map<String, String>> invalidBillTo = Utility.getBillTo('invalidId', 'Account');
        } catch (Exception e) {
        }
        
        try {
            List<Map<String, String>> invalidShipTo = Utility.getShipTo('invalidId', 'Account');
        } catch (Exception e) {
        }
        
        try {
            Address_Information__c invalidAddress = Utility.getShipToAddressInformation('invalidId');
        } catch (Exception e) {
        }
        
        try {
            List<String> invalidProduct = Utility.getProductsPlant('INVALID');
        } catch (Exception e) {
        }
        
        try {
            String invalidSalutation = Utility.getContactSalutation('Invalid');
        } catch (Exception e) {
        }
    }
}