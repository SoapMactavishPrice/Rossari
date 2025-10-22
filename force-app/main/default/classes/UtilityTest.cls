@IsTest
private class UtilityTest {
    @IsTest
    static void testAllMethods() {
        // Get standard pricebook ID without updating (fix for UNABLE_TO_LOCK_ROW)
        Id standardPricebookId = Test.getStandardPricebookId();

        Pricebook2 standardPricebook = new Pricebook2(
            Id = standardPricebookId,
            IsActive = true
        );
        update standardPricebook;

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

        Base_UoM_Master__c baseUom = new Base_UoM_Master__c(Name = 'Kilogram');
        insert baseUom;

        Product2 prod = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP001',
            Pack_Size__c = '10kg',
            Base_UOM__c = baseUom.Id,
            Plant_Name__c = plant.Id,
            IsActive = true
        );
        insert prod;

        User testUser = new User(
            Username = 'divisionuser' + DateTime.now().getTime() + '@example.com',
            Email = 'divisionuser@example.com',
            Alias = 'divuser',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_IN',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            Division_Code__c = '10',
            Division_Code_2__c = '11',
            Division_Code_3__c = '12',
            LastName = 'DivisionUser'
        );
        insert testUser;

        // Call getContactName multiple ways to cover branches
        Utility.getContactName(acc.Id, 'Account');
        Utility.getContactName(opp.Id, 'Opportunity');
        Utility.getContactName(qt.Id, 'Quote');

        // Exception test for getContactName with invalid id
        try {
            Utility.getContactName('001000000000000AAA', 'Account');
        } catch (AuraHandledException e) {
        }

        // Call getBillTo multiple ways
        Utility.getBillTo(acc.Id, 'Account');
        Utility.getBillTo(opp.Id, 'Opportunity');
        Utility.getBillTo(qt.Id, 'Quote');

        // Exception branch for getBillTo
        try {
            Utility.getBillTo('001000000000000AAA', 'Account');
        } catch (AuraHandledException e) {
        }

        // Call getShipTo multiple ways
        Utility.getShipTo(acc.Id, 'Account');
        Utility.getShipTo(opp.Id, 'Opportunity');

        // Exception branch for getShipTo
        try {
            Utility.getShipTo('001000000000000AAA', 'Account');
        } catch (AuraHandledException e) {
        }

        // Test getShipToAddressInformation normal and exception
        Utility.getShipToAddressInformation(shipTo.Id);
        try {
            Utility.getShipToAddressInformation('001000000000000AAA');
        } catch (Exception e) {
        }

        // Test getPlant (returns all plants)
        Utility.getPlant();

        // Test toTitleCase with various strings
        Utility.toTitleCase('hello world');
        Utility.toTitleCase(null);
        Utility.toTitleCase('');
        Utility.toTitleCase('test<br/>string case');

        // Test getProductsPlant with existing Product Code
        Utility.getProductsPlant(prod.ProductCode);
        // Exception test: invalid product code
        try {
            Utility.getProductsPlant('INVALID');
        } catch (AuraHandledException e) {
        }

        // Test getContactSalutation for valid and invalid values
        List<Schema.PicklistEntry> saluts = Contact.Salutation.getDescribe().getPicklistValues();
        if (!saluts.isEmpty()) {
            Utility.getContactSalutation(saluts[0].getValue());
        }
        Utility.getContactSalutation('InvalidValue');

        // Test getUserDivisionProductList for populated and null userId
        Utility.getUserDivisionProductList(testUser.Id);
        Utility.getUserDivisionProductList(null);

        // Create objects for Sample Request email methods
        Company__c company = new Company__c(Name = 'Tristar Intermediates Private Limited');
        insert company;

        Account customerAccount = new Account(
            Name = 'Customer Account',
            Rossari_Company__c = company.Id,
            Business_Type__c = 'Domestic'
        );
        insert customerAccount;

        Lead lead = new Lead(
            FirstName = 'LeadFirst',
            LastName = 'LeadLast',
            Company = 'Lead Company',
            MobilePhone = '1234567890',
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Lead' LIMIT 1].Id,
            Business_Type__c = 'Domestic',
            Rossari_Company__c = company.Id
        );
        insert lead;

        Sample_Request__c sampleRequest = new Sample_Request__c(
            Sample_Request_Date__c = Date.today(),
            Sample_Expected_Date__c = Date.today().addDays(5),
            Lead__c = lead.Id,
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
            Approval_Status__c = 'Approved'
        );
        insert lineItem;

        // Test sending emails methods
        Test.startTest();
        Utility.sendSampleRequestEmail(sampleRequest.Id);
        Utility.sendSampleRequestApprovalEmail(sampleRequest.Id);
        Test.stopTest();

        // More coverage of utility ns() helper
        System.assertEquals('', Utility.ns(null));
        System.assertEquals('abc', Utility.ns('abc'));
    }
}
