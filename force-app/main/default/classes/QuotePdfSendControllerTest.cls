@isTest
public class QuotePdfSendControllerTest {

    @testSetup
    static void setupTestData() {
        Pricebook2 standardPb = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        update standardPb;

        Account acc = new Account(Name = 'Test Account', Business_Type__c = 'Domestic');
        insert acc;

        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', Email = 'test@example.com', AccountId = acc.Id);
        insert con;

        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPb.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id
        );
        insert opp;

        Quote quote = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Pricebook2Id = standardPb.Id
        );
        insert quote;

        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 2,
            UnitPrice = 100
        );
        insert qli;
    }

    @isTest
    static void testAllMethods() {
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        Quote result1 = QuotePdfSendController.getQuoteDetails(quote.Id);
        try {
            Quote result2 = QuotePdfSendController.getQuoteDetails('invalidId');
        } catch (Exception e) {}
        String emails1 = QuotePdfSendController.getCustomerContactEmails(quote.Id);

        Account acc2 = new Account(Name = 'No Contact Account');
        insert acc2;
        Opportunity opp2 = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc2.Id
        );
        insert opp2;
        Quote quote2 = new Quote(
            Name = 'Test Quote 2',
            OpportunityId = opp2.Id
        );
        insert quote2;
        try {
            String emails2 = QuotePdfSendController.getCustomerContactEmails(quote2.Id);
        } catch (Exception e) {}

        String pdfUrl1 = QuotePdfSendController.getPdfUrl(quote.Id, 'quote');
        String pdfUrl2 = QuotePdfSendController.getPdfUrl(quote.Id, 'invoice');
        String pdfUrl3 = QuotePdfSendController.getPdfUrl(quote.Id, 'invalid');
        User user = QuotePdfSendController.getCurrentUserDetails();

        ContentVersion cv = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.jpg',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert cv;
        cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        String result3 = QuotePdfSendController.deletefile(cv.ContentDocumentId);

        String businessType = QuotePdfSendController.validateQuote(quote.Id);
        Boolean result4 = QuotePdfSendController.isQuoteLineItemsExist(quote.Id);

        Account acc3 = new Account(Name = 'Empty Account');
        insert acc3;
        Opportunity opp3 = new Opportunity(
            Name = 'Test Opp Empty',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc3.Id
        );
        insert opp3;
        Quote quote3 = new Quote(
            Name = 'Test Quote Empty',
            OpportunityId = opp3.Id
        );
        insert quote3;
        Boolean result5 = QuotePdfSendController.isQuoteLineItemsExist(quote3.Id);

        String files = '[]';
        String result6 = QuotePdfSendController.save('Test Quote', quote.Id, files, 'quote');
        String result7 = QuotePdfSendController.save('Test Invoice', quote.Id, files, 'invoice');

        ContentVersion cv2 = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'Test.jpg',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert cv2;
        cv2 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv2.Id];
        String filesWithDoc = '[{"name":"Test File", "documentId":"' + cv2.ContentDocumentId + '"}]';
        String result8 = QuotePdfSendController.save('Test Quote', quote.Id, filesWithDoc, 'quote');

        User currentUser = [SELECT Id, Name, Email FROM User WHERE Id = :UserInfo.getUserId()];
        String result9 = QuotePdfSendController.saveAndSend(
            'test@example.com', 'cc@example.com', 'Test Subject', 'Test Body',
            'Test Quote', quote.Id, currentUser.Email, currentUser.Name, files, true, 'quote');

        String result10 = QuotePdfSendController.saveAndSend(
            'test@example.com', 'cc@example.com', 'Test Subject', 'Test Body',
            'Test Invoice', quote.Id, currentUser.Email, currentUser.Name, files, true, 'invoice');

        String result11 = QuotePdfSendController.saveAndSend(
            'test@example.com', 'cc@example.com', 'Test Subject', 'Test Body',
            'Test Quote', quote.Id, currentUser.Email, currentUser.Name, filesWithDoc, true, 'quote');

        String result12 = QuotePdfSendController.saveAndSend(
            'test@example.com', 'cc@example.com', 'Test Subject', 'Test Body',
            'Test Quote', quote.Id, currentUser.Email, currentUser.Name, files, false, 'quote');

        String result13 = QuotePdfSendController.saveAndSend(
            'test1@example.com,test2@example.com', 'cc1@example.com,cc2@example.com', 'Test Subject', 'Test Body',
            'Test Quote', quote.Id, currentUser.Email, currentUser.Name, files, true, 'quote');

        String result14 = QuotePdfSendController.saveAndSend(
            'test@example.com', null, 'Test Subject', 'Test Body',
            'Test Quote', quote.Id, currentUser.Email, currentUser.Name, files, true, 'quote');

        String result15 = QuotePdfSendController.saveAndSend(
            'invalid-email', 'cc@example.com', 'Test Subject', 'Test Body',
            'Test Quote', quote.Id, currentUser.Email, currentUser.Name, files, true, 'quote');
    }
}