@IsTest
private class QuoteTriggerTest {

    @TestSetup
    static void setupTestData() {
        Id pbId = Test.getStandardPricebookId();

        Pricebook2 customPb = new Pricebook2(Id = pbId, IsActive = true);
        update customPb;

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = acc.Id,
            Pricebook2Id = pbId
        );
        insert opp;

        Quote q = new Quote(
            Name = 'Initial Quote',
            OpportunityId = opp.Id,
            Pricebook2Id = pbId,
            Credit_Approval_Status__c = 'Approved',
            Status = 'Draft'
        );
        insert q;
    }

    @IsTest
    static void testBeforeUpdatePaymentTermChange() {
        Quote q = [SELECT Id, Payment_Term__c, Previous_Payment_Terms__c, Status FROM Quote LIMIT 1];
        Test.startTest();
        update q;
        Test.stopTest();
    }

    @IsTest
    static void testAfterUpdateCreditApprovalApproved() {
        Quote q = [SELECT Id, Credit_Approval_Status__c, Payment_Term__c FROM Quote LIMIT 1];
        q.Credit_Approval_Status__c = 'Approved';
        Test.startTest();
        update q;
        Test.stopTest();
    }

    @IsTest
    static void testAfterUpdateCreditApprovalRejected() {
        Quote q = [SELECT Id, Credit_Approval_Status__c FROM Quote LIMIT 1];
        q.Credit_Approval_Status__c = 'Rejected';
        Test.startTest();
        update q;
        Test.stopTest();
    }

    @IsTest
    static void testAfterUpdateNoChange() {
        Quote q = [SELECT Id, Payment_Term__c, Credit_Approval_Status__c FROM Quote LIMIT 1];
        q.Name = 'No Change Quote';
        Test.startTest();
        update q;
        Test.stopTest();
    }
}
