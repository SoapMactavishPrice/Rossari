@IsTest
public class SampleRequestApprovalControllerTest {

    @TestSetup
    static void setupTestData() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];

        // HOD User
        User hodUser = new User(
            FirstName='HOD',
            LastName='User',
            Email='hoduser@example.com',
            Username='hoduser'+DateTime.now().getTime()+'@example.com',
            Alias='hodusr',
            TimeZoneSidKey='Asia/Kolkata',
            LocaleSidKey='en_US',
            EmailEncodingKey='UTF-8',
            ProfileId=p.Id,
            LanguageLocaleKey='en_US'
        );
        insert hodUser;

        // Owner User
        User ownerUser = new User(
            FirstName='Owner',
            LastName='User',
            Email='owneruser@example.com',
            Username='owneruser'+DateTime.now().getTime()+'@example.com',
            Alias='ownusr',
            TimeZoneSidKey='Asia/Kolkata',
            LocaleSidKey='en_US',
            EmailEncodingKey='UTF-8',
            ProfileId=p.Id,
            LanguageLocaleKey='en_US'
        );
        insert ownerUser;

        // Get standard pricebook ID without updating (fix for UNABLE_TO_LOCK_ROW)
        Id standardPricebookId = Test.getStandardPricebookId();

        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
 
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


        // Account
        Account acc = new Account(Name='Test Account');
        insert acc;

        // Sample Request
        Sample_Request__c sr = new Sample_Request__c(
            OwnerId = ownerUser.Id,
            Sales_HOD__c = hodUser.Id
        );
        insert sr;

        // Sample Request Line Item
        Sample_Request_Line_Item__c srLine = new Sample_Request_Line_Item__c(
            Sample_Request__c = sr.Id,
            Product__c = prod.Id,
            Sample_Qty_in_Kgs__c = 10,
            Approval_Status__c = 'Pending'
        );
        insert srLine;
    }

    @IsTest
    static void testGetAllQuotations() {
        Test.startTest();
        List<SampleRequestApprovalController.SampleRequestWrapper> quotations = SampleRequestApprovalController.getAllQuotations();
        Test.stopTest();
    }

    @IsTest
    static void testUpdateQuoteLineItemApproved() {
        Sample_Request__c sr = [SELECT Id FROM Sample_Request__c LIMIT 1];
        Sample_Request_Line_Item__c srLine = [SELECT Id, Approval_Status__c FROM Sample_Request_Line_Item__c LIMIT 1];

        SampleRequestApprovalController.SampleRequestLineItemWrapper lineWrapper =
            new SampleRequestApprovalController.SampleRequestLineItemWrapper();
        lineWrapper.quoteLineItemId = srLine.Id;
        lineWrapper.approvalStatus = 'Approved';
        lineWrapper.updated = true;

        SampleRequestApprovalController.SampleRequestWrapper wrapper =
            new SampleRequestApprovalController.SampleRequestWrapper();
        wrapper.quoteId = sr.Id;
        wrapper.quoteLineItems = new List<SampleRequestApprovalController.SampleRequestLineItemWrapper>{lineWrapper};
        wrapper.updated = true;
        wrapper.quoteOwnerEmail = 'owneruser@example.com';
        wrapper.quoteOwnerName = 'Owner User';

        String jsonWrapper = JSON.serialize(new List<SampleRequestApprovalController.SampleRequestWrapper>{wrapper});

        Test.startTest();
        String result = SampleRequestApprovalController.updateQuoteLineItem(jsonWrapper);
        Test.stopTest();
    }

    @IsTest
    static void testUpdateQuoteLineItemRejected() {
        Sample_Request__c sr = [SELECT Id FROM Sample_Request__c LIMIT 1];
        Sample_Request_Line_Item__c srLine = [SELECT Id, Approval_Status__c FROM Sample_Request_Line_Item__c LIMIT 1];

        SampleRequestApprovalController.SampleRequestLineItemWrapper lineWrapper =
            new SampleRequestApprovalController.SampleRequestLineItemWrapper();
        lineWrapper.quoteLineItemId = srLine.Id;
        lineWrapper.approvalStatus = 'Rejected';
        lineWrapper.updated = true;

        SampleRequestApprovalController.SampleRequestWrapper wrapper =
            new SampleRequestApprovalController.SampleRequestWrapper();
        wrapper.quoteId = sr.Id;
        wrapper.quoteLineItems = new List<SampleRequestApprovalController.SampleRequestLineItemWrapper>{lineWrapper};
        wrapper.updated = true;
        wrapper.quoteOwnerEmail = 'owneruser@example.com';
        wrapper.quoteOwnerName = 'Owner User';

        String jsonWrapper = JSON.serialize(new List<SampleRequestApprovalController.SampleRequestWrapper>{wrapper});

        Test.startTest();
        String result = SampleRequestApprovalController.updateQuoteLineItem(jsonWrapper);
        Test.stopTest();
    }

    @IsTest
    static void testWrapperConstructorCoverage() {
        Sample_Request__c sr = [SELECT Id, Name, OwnerId, Owner.Email, Owner.Name, Sales_HOD__c, Sales_HOD__r.Name 
                                FROM Sample_Request__c LIMIT 1];
        List<Sample_Request_Line_Item__c> srLines = [SELECT Id, Product__c, Product__r.Name, Sample_Qty_in_Kgs__c, Approval_Status__c, Approval_Comments__c, Sample_Request__c 
                                                    FROM Sample_Request_Line_Item__c WHERE Sample_Request__c = :sr.Id];

        SampleRequestApprovalController.SampleRequestWrapper wrapper =
            new SampleRequestApprovalController.SampleRequestWrapper(sr, srLines);
    }
}