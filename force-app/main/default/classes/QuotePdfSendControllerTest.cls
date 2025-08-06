@IsTest
private class QuotePdfSendControllerTest {

    @IsTest
    static void testAllMethodsInOne() {
        Pricebook2 standardPb = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        update standardPb;
        
        Account acc = new Account(Name = 'Test Account', Business_Type__c = 'Domestic');
        insert acc;
        
        Contact con1 = new Contact(LastName = 'Test1', Email = 'Test1@example.com', AccountId = acc.Id);
        Contact con2 = new Contact(LastName = 'Test2', Email = 'Test2@example.com', AccountId = acc.Id);
        insert new List<Contact>{con1, con2};
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id
        );
        insert opp;
        
        Quote quote = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Status = 'Draft'
        );
        insert quote;
        
        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;
        
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPb.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;
        
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert qli;
        
        ContentVersion cv = new ContentVersion(
            Title = 'TestFile_0.pdf',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('Test Content')
        );
        insert cv;
        
        Id contentDocumentId = [
            SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id
        ].ContentDocumentId;
        
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = contentDocumentId,
            LinkedEntityId = quote.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
        
        QuotePdfSendController.getQuoteDetails(quote.Id);
        QuotePdfSendController.getCustomerContactEmails(quote.Id);
        QuotePdfSendController.getPdfUrl(quote.Id);
        QuotePdfSendController.getCurrentUserDetails();
        QuotePdfSendController.deletefile(contentDocumentId);
        QuotePdfSendController.validateQuote(quote.Id);
        QuotePdfSendController.isQuoteLineItemsExist(quote.Id);
        
        String filesJson = '[{"name":"TestFile.pdf","documentId":"' + contentDocumentId + '"}]';
        QuotePdfSendController.save(quote.Name, quote.Id, filesJson);
        
        String emailId = 'testuser@example.com';
        String ccAddresses = 'cc1@example.com;cc2@example.com';
        String subject = 'Test Subject';
        String body = '<p>Test Body</p>';
        String qtName = quote.Name;
        String qId = quote.Id;
        String ownerEmail = UserInfo.getUserEmail();
        String ownerName = UserInfo.getName();
        Boolean isAttachPdf = true;
        
        QuotePdfSendController.saveAndSend(emailId, ccAddresses, subject, body, qtName, qId, ownerEmail, ownerName, filesJson, isAttachPdf);
    }
}