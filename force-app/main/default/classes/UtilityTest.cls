@isTest
private class UtilityTest {
    @isTest
    static void testAllMethods() {
        // Get standard pricebook ID without updating (fix for UNABLE_TO_LOCK_ROW)
        Id standardPricebookId = Test.getStandardPricebookId();

        Account acc = new Account(Name = 'Test Account', Business_Type__c = 'Domestic');
        insert acc;

        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = acc.Id);
        insert con;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = acc.Id,
            Pricebook2Id = standardPricebookId
        );
        insert opp;

        Quote qt = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Pricebook2Id = standardPricebookId
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

        Division__c division = new Division__c(Name = '10');
        insert division;

        Product2 prod = new Product2(
            Name = 'Test Product',
            ProductCode = 'TEST001',
            Plant_Name__c = plant.Id,
            Division__c = division.Id,
            IsActive = true
        );
        insert prod;

        User testUser = new User(
            Username = 'divisionuser@example.com',
            Email = 'divisionuser@example.com',
            Alias = 'divuser',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_IN',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            Division_Code__c = '10',
            LastName = 'DivisionUser'
        );
        insert testUser;

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

        List<String> divisionProductList = Utility.getUserDivisionProductList(testUser.Id);

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

        Lead rossariLead = new Lead(FirstName = 'Rossari', LastName = 'Company', Company = 'Rossari Ltd', MobilePhone = '8978765676');
        insert rossariLead;

        Company__c com = new Company__c(Name = 'Tristar Intermediates Private Limited');
        insert com;

        Account customerAccount = new Account(
            Name = 'Customer Account',
            Rossari_Company__c = com.Id,
            Business_Type__c = 'Domestic'
        );
        insert customerAccount;

        Sample_Request__c sampleRequest = new Sample_Request__c(
            Sample_Request_Date__c = Date.today(),
            Sample_Expected_Date__c = Date.today().addDays(5),
            Lead__c = rossariLead.Id,
            Opportunity__c = opp.Id,
            Customer_Name__c = customerAccount.Id,
            Additional_Email__c = 'test1@example.com,test2@example.com',
            Sales_HOD__c = testUser.Id
        );
        insert sampleRequest;

        Sample_Request_Line_Item__c lineItem = new Sample_Request_Line_Item__c(
            Sample_Request__c = sampleRequest.Id,
            Product__c = prod.Id,
            Sample_Qty_in_Kgs__c = 15,
            Sales_Price__c = 100,
            Approval_Status__c = 'Pending'
        );
        insert lineItem;

        Test.startTest();
        Utility.sendSampleRequestEmail(sampleRequest.Id);
        Utility.sendSampleRequestApprovalEmail(sampleRequest.Id);
        Test.stopTest();
    }
}