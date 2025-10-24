@isTest
private class SalesPriceApprovalForQuotationTest {
    
    @testSetup
    static void setupData() {
        // Get standard pricebook ID without updating (fix for UNABLE_TO_LOCK_ROW)
        Id standardPricebookId = Test.getStandardPricebookId();

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', Email = 'test@example.com', AccountId = acc.Id);
        insert con;

        Opportunity opp = new Opportunity(Name = 'Test Opp', StageName = 'Qualification', CloseDate = Date.today(), AccountId = acc.Id);
        insert opp;

        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        try{
        update standardPricebook;
        }Catch(Exception e){}
    
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


        Quote qt = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Pricebook2Id = standardPricebookId,
            ContactId = con.Id
        );
        insert qt;

        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = qt.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 80,
            Product2Id = prod.Id,
            Approval_Status__c = 'Pending',
            Is_SP_less_than_LP__c = true
        );
        insert qli;
    }

    @isTest
    static void testGetAllQuotations() {
        List<SalesPriceApprovalForQuotation.QuotationWrapper> results = SalesPriceApprovalForQuotation.getAllQuotations();
    }

    @isTest
    static void testUpdateQuoteLineItem() {
        Quote qt = [SELECT Id, Name, OwnerId, Owner.Name, Owner.Email FROM Quote LIMIT 1];
        QuoteLineItem item = [SELECT Id, QuoteId, Product2Id, Product2.Name, Quantity, UnitPrice FROM QuoteLineItem LIMIT 1];

        SalesPriceApprovalForQuotation.QuotationLineItemWrapper lineItem = new SalesPriceApprovalForQuotation.QuotationLineItemWrapper();
        lineItem.quoteLineItemId = item.Id;
        lineItem.productId = item.Product2Id;
        lineItem.productName = item.Product2.Name;
        lineItem.quantity = item.Quantity;
        lineItem.salesPrice = item.UnitPrice;
        lineItem.approvalStatus = 'Approved';
        lineItem.approvalComments = 'Approved for discount';
        lineItem.updated = true;

        SalesPriceApprovalForQuotation.QuotationWrapper wrapper = new SalesPriceApprovalForQuotation.QuotationWrapper();
        wrapper.quoteId = qt.Id;
        wrapper.quoteName = qt.Name;
        wrapper.quoteOwnerId = qt.OwnerId;
        wrapper.quoteOwnerName = qt.Owner.Name;
        wrapper.quoteOwnerEmail = qt.Owner.Email;
        wrapper.quoteLink = 'https://example.com/' + qt.Id;
        wrapper.updated = true;
        wrapper.quoteLineItems = new List<SalesPriceApprovalForQuotation.QuotationLineItemWrapper>{lineItem};

        String jsonInput = JSON.serialize(new List<SalesPriceApprovalForQuotation.QuotationWrapper>{wrapper});
        String result = SalesPriceApprovalForQuotation.updateQuoteLineItem(jsonInput);
    }
}