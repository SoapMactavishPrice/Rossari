public without sharing class SalesPriceApprovalForQuotation {

    public QuotationWrapper quotation;

    public SalesPriceApprovalForQuotation(QuotationWrapper quotation) {
        this.quotation = quotation;
    }


    /**
     * @description: This method is used to get all the Quotations in which the line item's status is pending
     */
    @AuraEnabled
    public static List<QuotationWrapper> getAllQuotations() {
        Id currentUserId = UserInfo.getUserId();
    
        // Fetch all pending line items first
        List<QuoteLineItem> quoteLineItems = [
            SELECT Approval_Comments__c, Approval_Status__c, Approver__c, CreatedById, ServiceDate, 
                   Discount, LastModifiedById, Description, LineNumber, ListPrice, Previous_Quantity__c, 
                   Previous_Sales_Price__c, Product2Id, Product2.Name, Quality__c, Quantity, QuoteId, 
                   Reject_Reason__c, UnitPrice, SortOrder, Subtotal, TotalPrice
            FROM QuoteLineItem
            WHERE Approval_Status__c = 'Pending'
              AND Is_SP_less_than_LP__c = true
        ];
    
        if (quoteLineItems.isEmpty()) {
            throw new AuraHandledException('No Quotation Line Items found with their status as "Pending"');
        }
    
        // collect Quote Ids
        Set<Id> quoteIds = new Set<Id>();
        for (QuoteLineItem eachQli : quoteLineItems) {
            quoteIds.add(eachQli.QuoteId);
        }
    
        // fetch only those Quotes that belong to the user (owner) or where user is HOD
        Map<Id, Quote> quoteMap = new Map<Id, Quote>(
            [SELECT Id, Name, Owner.Email, Owner.Name, OwnerId, Account.Name, QuoteNumber, Link__c, HOD_of_Sales_Department__c
             FROM Quote
             WHERE Id IN :quoteIds
               AND (OwnerId = :currentUserId OR HOD_of_Sales_Department__c = :currentUserId)]
        );
    
        // map line items to their parent Quote
        Map<Id, List<QuoteLineItem>> quoteToQuoteLineItemMap = new Map<Id, List<QuoteLineItem>>();
        for (QuoteLineItem eachLine : quoteLineItems) {
            if (quoteMap.containsKey(eachLine.QuoteId)) { // filter by accessible quotes
                if (!quoteToQuoteLineItemMap.containsKey(eachLine.QuoteId)) {
                    quoteToQuoteLineItemMap.put(eachLine.QuoteId, new List<QuoteLineItem>());
                }
                quoteToQuoteLineItemMap.get(eachLine.QuoteId).add(eachLine);
            }
        }
    
        // build wrapper list
        List<QuotationWrapper> quotations = new List<QuotationWrapper>();
        for (Id eachQuoteId : quoteToQuoteLineItemMap.keySet()) {
            quotations.add(new QuotationWrapper(quoteMap.get(eachQuoteId), quoteToQuoteLineItemMap.get(eachQuoteId)));
        }
    
        return quotations;
    }


    /**
     * @description: This method is used to update the approval status and approval comments of the line item
     * @param: quotationListStringObject: It is a JSON stringified list of QuotationWrapper objects
     */
    @AuraEnabled
    public static String updateQuoteLineItem(String quotationListStringObject) {

        List<QuotationWrapper> quotations = parseHeaderAndLine(quotationListStringObject);

        List<QuoteLineItem> quotationLineItemsToBeUpdated = new List<QuoteLineItem>();

        for (QuotationWrapper eachQuotation : quotations) {
            if (eachQuotation.updated && eachQuotation.quoteLineItems != null && !eachQuotation.quoteLineItems.isEmpty()) {
                for (QuotationLineItemWrapper eachQuoteLineItem : eachQuotation.quoteLineItems) {
                    if (eachQuoteLineItem.updated) {
                        QuoteLineItem quoteLineItem = new QuoteLineItem();
                        quoteLineItem.Id = eachQuoteLineItem.quoteLineItemId;
                        quoteLineItem.Approval_Status__c = eachQuoteLineItem.approvalStatus;
                        quoteLineItem.Approval_Comments__c = eachQuoteLineItem.approvalComments;

                        quotationLineItemsToBeUpdated.add(quoteLineItem);
                    }
                }
            }
        }

        UPDATE quotationLineItemsToBeUpdated;

        for (QuotationWrapper eachQuotation : quotations) {
            SalesPriceApprovalForQuotation controller = new SalesPriceApprovalForQuotation(eachQuotation);
            controller.sendEmailNotification();
        }

        return 'Success';
    }

    private void sendEmailNotification() {
        Boolean isApproved = false;
        Boolean isRejected = false;
        for (QuotationLineItemWrapper item : quotation.quoteLineItems) {
            if (item.approvalStatus == 'Approved') {
                isApproved = true;
            } else if (item.approvalStatus == 'Rejected') {
                isRejected = true;
            }
        }

        if (isApproved) {
            this.sendEmail(this.quotation, 'Approved');
        }

        if (isRejected) {
            this.sendEmail(this.quotation, 'Rejected');
        }
    }

    private void sendEmail(QuotationWrapper quotation, String status) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[]{quotation.quoteOwnerEmail});
        email.setSubject('Sales Price ' + status + ' - ' + quotation.quoteName);

        String body = 'Dear ' + quotation.quoteOwnerName + ',<br/><br/>';
        body += 'The Sales Price has been ' + status.toLowerCase() + ' for the following Quote:<br/><br/>';
        body += 'Quote Name: ' + quotation.quoteName + '<br/>';
        body += 'Quote Link: ' + quotation.quoteLink + '</a><br/><br/>';
        body += 'Below are the product details:<br/><br/>';

        body += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse; width: 100%;">';
        body += '<thead><tr style="background-color: #f2f2f2;"><th>Product Name</th><th>List Price</th><th>Sales Price</th><th>Approval Status</th></tr></thead><tbody>';

        for (QuotationLineItemWrapper item : quotation.quoteLineItems) {
            if (item.approvalStatus == status && item.updated) {
                body += '<tr>';
                body += '<td>' + item.productName + '</td>';
                body += '<td>' + (item.listPrice != null ? String.valueOf(item.listPrice) : 'Not Available') + '</td>';
                body += '<td>' + (item.salesPrice != null ? String.valueOf(item.salesPrice) : 'Not Available') + '</td>';
                body += '<td>' + (item.approvalStatus != null ? String.valueOf(item.approvalStatus) : '') + '</td>';
                body += '</tr>';
            }
        }

        body += '</tbody></table><br/>';
        body += 'Sales Price has been ' + status.toLowerCase() + ', kindly review the details at your earliest convenience.<br/><br/>';
        body += 'Regards,<br/>';
        body += (quotation.quoteOwnerId != null ? quotation.quoteOwnerName : 'System Notification');

        email.setHtmlBody(body);

        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
        } catch (Exception e) {
            System.debug('Email Sending Failed: ' + e.getMessage());
        }
    }

    private static List<QuotationWrapper> parseHeaderAndLine(string js){
        return (List<QuotationWrapper>)system.JSON.deserialize(js,List<QuotationWrapper>.class);
    }

    public class QuotationWrapper {
        @AuraEnabled public String quoteId;
        @AuraEnabled public String quoteName;
        @AuraEnabled public String quoteNumber;
        @AuraEnabled public String accountName;
        @AuraEnabled public String quoteOwnerId;
        @AuraEnabled public String quoteOwnerEmail;
        @AuraEnabled public String quoteOwnerName;
        @AuraEnabled public String quoteLink;
        @AuraEnabled public String hodUserId; 
        @AuraEnabled public List<QuotationLineItemWrapper> quoteLineItems;
        @AuraEnabled public Boolean updated;

        public QuotationWrapper() {}

        public QuotationWrapper(Quote quote, List<QuoteLineItem> quoteLineItems) {
            this.quoteId = quote.Id;
            this.quoteName = quote.Name;
            this.accountName = quote.Account.Name;
            this.quoteNumber = quote.QuoteNumber;
            this.quoteOwnerId = quote.OwnerId;
            this.quoteOwnerEmail = quote.Owner.Email;
            this.quoteOwnerName = quote.Owner.Name;
            this.quoteLink = quote.Link__c;
            this.hodUserId = quote.HOD_of_Sales_Department__c; 
            this.updated = false;

            if (this.quoteLineItems == null) {
                this.quoteLineItems = new list<QuotationLineItemWrapper>();
            }

            for (QuoteLineItem eachLine : quoteLineItems) {
                this.quoteLineItems.add(new QuotationLineItemWrapper(eachLine));
            }

        }
    }

    public class QuotationLineItemWrapper {
        @AuraEnabled public String parentId;
        @AuraEnabled public String quoteLineItemId;
        @AuraEnabled public String productId;
        @AuraEnabled public String productName;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public Decimal listPrice;
        @AuraEnabled public Decimal salesPrice;
        @AuraEnabled public String approvalStatus;
        @AuraEnabled public String approvalComments;
        @AuraEnabled public Boolean updated;

        public QuotationLineItemWrapper() {}

        public QuotationLineItemWrapper(QuoteLineItem quoteLineItem) {
            this.parentId = quoteLineItem.QuoteId;
            this.quoteLineItemId = quoteLineItem.Id;
            this.productId = quoteLineItem.Product2Id;
            this.productName = quoteLineItem.Product2.Name;
            this.quantity = quoteLineItem.Quantity;
            this.listPrice = quoteLineItem.ListPrice;
            this.salesPrice = quoteLineItem.UnitPrice;
            this.approvalStatus = quoteLineItem.Approval_Status__c;
            this.approvalComments = quoteLineItem.Approval_Comments__c;
            this.updated = false;
        }
    }

}