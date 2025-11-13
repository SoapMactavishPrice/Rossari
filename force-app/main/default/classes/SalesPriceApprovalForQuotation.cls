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
        System.debug('=== Starting getAllQuotations for User: ' + currentUserId + ' ===');
        
        // Fetch pending line items with discount > 5%
        List<QuoteLineItem> quoteLineItems = [
            SELECT Id, QuoteId, Discount, L2_Discount_Approver__c, L3_Discount_Approver__c,
                   Approval_Status__c, Approval_Comments__c, Product2.Name, Quantity,
                   ListPrice, UnitPrice, Product2Id, Quote.OwnerId
            FROM QuoteLineItem
            WHERE Approval_Status__c IN ('Pending', 'Rejected')
            AND Discount > 5
            ORDER BY QuoteId, Product2.Name
        ];
        
        System.debug('Total pending line items with Discount > 5: ' + quoteLineItems.size());
        
        if (quoteLineItems.isEmpty()) {
            throw new AuraHandledException('No Quotation Line Items found requiring discount approval');
        }
        
        // Collect all approver IDs and quote IDs
        Set<Id> approverIds = new Set<Id>();
        Set<Id> quoteIds = new Set<Id>();
        
        for (QuoteLineItem eachQli : quoteLineItems) {
            quoteIds.add(eachQli.QuoteId);
            if (eachQli.L2_Discount_Approver__c != null) approverIds.add(eachQli.L2_Discount_Approver__c);
            if (eachQli.L3_Discount_Approver__c != null) approverIds.add(eachQli.L3_Discount_Approver__c);
        }
        
        // Get approver names in bulk
        Map<Id, User> approverMap = new Map<Id, User>();
        if (!approverIds.isEmpty()) {
            approverMap = new Map<Id, User>([
                SELECT Id, Name FROM User WHERE Id IN :approverIds
            ]);
        }
        
        // Get Quote details with Owner information
        Map<Id, Quote> quoteMap = new Map<Id, Quote>([
            SELECT Id, Name, Owner.Email, Owner.Name, OwnerId, Account.Name, QuoteNumber, Link__c
            FROM Quote
            WHERE Id IN :quoteIds
        ]);
        
        // Filter line items where current user is either:
        // 1. Quote Owner OR
        // 2. L2 Approver (for 5-10% discount) OR  
        // 3. L3 Approver (for >10% discount)
        List<QuoteLineItem> filteredLineItems = new List<QuoteLineItem>();
        Map<Id, List<QuoteLineItem>> quoteToLineItemsMap = new Map<Id, List<QuoteLineItem>>();
        
        for (QuoteLineItem eachQli : quoteLineItems) {
            Quote relatedQuote = quoteMap.get(eachQli.QuoteId);
            if (relatedQuote == null) continue;
            
            Boolean isQuoteOwner = (relatedQuote.OwnerId == currentUserId);
            Boolean isL2Approver = (eachQli.Discount > 5 && eachQli.Discount <= 10 && eachQli.L2_Discount_Approver__c == currentUserId);
            Boolean isL3Approver = (eachQli.Discount > 10 && eachQli.L3_Discount_Approver__c == currentUserId);
            
            System.debug('QLI Id: ' + eachQli.Id + 
                        ', Discount: ' + eachQli.Discount + 
                        ', Quote Owner: ' + relatedQuote.OwnerId +
                        ', L2 Approver: ' + eachQli.L2_Discount_Approver__c +
                        ', L3 Approver: ' + eachQli.L3_Discount_Approver__c +
                        ', Is Quote Owner: ' + isQuoteOwner +
                        ', Is L2 Approver: ' + isL2Approver +
                        ', Is L3 Approver: ' + isL3Approver);
            
            if (isQuoteOwner || isL2Approver || isL3Approver) {
                filteredLineItems.add(eachQli);
                
                if (!quoteToLineItemsMap.containsKey(eachQli.QuoteId)) {
                    quoteToLineItemsMap.put(eachQli.QuoteId, new List<QuoteLineItem>());
                }
                quoteToLineItemsMap.get(eachQli.QuoteId).add(eachQli);
                System.debug('Added QLI to filtered list: ' + eachQli.Id);
            }
        }
        
        System.debug('Filtered line items count for current user: ' + filteredLineItems.size());
        
        if (filteredLineItems.isEmpty()) {
            throw new AuraHandledException(
                'No pending discount approval line items found where you are either:\n' +
                '- Quote Owner\n' + 
                '- L2 Discount Approver (for 5-10% discount)\n' +
                '- L3 Discount Approver (for >10% discount)\n\n' +
                'Your User ID: ' + currentUserId
            );
        }
        
        // Build wrapper list
        List<QuotationWrapper> quotations = new List<QuotationWrapper>();
        for (Id quoteId : quoteToLineItemsMap.keySet()) {
            Quote quote = quoteMap.get(quoteId);
            if (quote != null) {
                quotations.add(new QuotationWrapper(quote, quoteToLineItemsMap.get(quoteId), approverMap, currentUserId));
            }
        }
        
        System.debug('Final quotations count: ' + quotations.size());
        return quotations;
    }

    /**
     * @description: This method is used to update the approval status and approval comments of the line item
     * @param: quotationListStringObject: It is a JSON stringified list of QuotationWrapper objects
     */
    @AuraEnabled
    public static String updateQuoteLineItem(String quotationListStringObject) {
        try {
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

            if (!quotationLineItemsToBeUpdated.isEmpty()) {
                UPDATE quotationLineItemsToBeUpdated;

                for (QuotationWrapper eachQuotation : quotations) {
                    SalesPriceApprovalForQuotation controller = new SalesPriceApprovalForQuotation(eachQuotation);
                    controller.sendEmailNotification();
                }
                return 'Success';
            } else {
                return 'No changes to update';
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error updating quote line items: ' + e.getMessage());
        }
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
        try {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[]{quotation.quoteOwnerEmail});
            email.setSubject('Discount ' + status + ' - ' + quotation.quoteName);
            email.setWhatId(quotation.quoteId);

            String body = 'Dear ' + quotation.quoteOwnerName + ',<br/><br/>';
            body += 'The Discount has been ' + status.toLowerCase() + ' for the following Quote:<br/><br/>';
            body += 'Quote Name: ' + quotation.quoteName + '<br/>';
            body += 'Quote Number: ' + quotation.quoteNumber + '<br/>';
            body += 'Account: ' + quotation.accountName + '<br/><br/>';
            body += 'Below are the product details:<br/><br/>';

            body += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse; width: 100%;">';
            body += '<thead><tr style="background-color: #f2f2f2;">';
            body += '<th>Product Name</th><th>Quantity</th><th>List Price</th><th>Sales Price</th><th>Discount %</th><th>Approval Status</th>';
            body += '</tr></thead><tbody>';

            for (QuotationLineItemWrapper item : quotation.quoteLineItems) {
                if (item.approvalStatus == status && item.updated) {
                    body += '<tr>';
                    body += '<td>' + item.productName + '</td>';
                    body += '<td>' + (item.quantity != null ? String.valueOf(item.quantity) : 'N/A') + '</td>';
                    body += '<td>' + (item.listPrice != null ? String.valueOf(item.listPrice) : 'N/A') + '</td>';
                    body += '<td>' + (item.salesPrice != null ? String.valueOf(item.salesPrice) : 'N/A') + '</td>';
                    body += '<td>' + (item.discount != null ? String.valueOf(item.discount) + '%' : 'N/A') + '</td>';
                    body += '<td>' + (item.approvalStatus != null ? String.valueOf(item.approvalStatus) : '') + '</td>';
                    body += '</tr>';
                }
            }

            body += '</tbody></table><br/>';
            body += 'Discount has been ' + status.toLowerCase() + ', kindly review the details at your earliest convenience.<br/><br/>';
            body += 'Regards,<br/>Sales Team';

            email.setHtmlBody(body);
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
        @AuraEnabled public List<QuotationLineItemWrapper> quoteLineItems;
        @AuraEnabled public Boolean updated;
        @AuraEnabled public Boolean disableFields; // To control UI editing

        public QuotationWrapper() {}

        public QuotationWrapper(Quote quote, List<QuoteLineItem> quoteLineItems, Map<Id, User> approverMap, Id currentUserId) {
            this.quoteId = quote.Id;
            this.quoteName = quote.Name;
            this.accountName = quote.Account.Name;
            this.quoteNumber = quote.QuoteNumber;
            this.quoteOwnerId = quote.OwnerId;
            this.quoteOwnerEmail = quote.Owner.Email;
            this.quoteOwnerName = quote.Owner.Name;
            this.quoteLink = quote.Link__c;
            this.updated = false;
            
            // Quote Owner can approve if they are also the approver for any line item
            Boolean isApprover = false;
            for (QuoteLineItem eachLine : quoteLineItems) {
                if ((eachLine.L2_Discount_Approver__c == currentUserId && eachLine.Discount > 5 && eachLine.Discount <= 10) ||
                    (eachLine.L3_Discount_Approver__c == currentUserId && eachLine.Discount > 10)) {
                        isApprover = true;
                        break;
                    }
            }
            this.disableFields = (quote.OwnerId == currentUserId && !isApprover);
            
            this.quoteLineItems = new List<QuotationLineItemWrapper>();
            for (QuoteLineItem eachLine : quoteLineItems) {
                this.quoteLineItems.add(new QuotationLineItemWrapper(eachLine, approverMap, currentUserId));
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
        @AuraEnabled public Decimal discount;
        @AuraEnabled public String discountApproverName;
        @AuraEnabled public String approvalLevel;
        @AuraEnabled public String approvalStatus;
        @AuraEnabled public String approvalComments;
        @AuraEnabled public Boolean updated;
        @AuraEnabled public Boolean disableFields; // To control UI editing per line item

        public QuotationLineItemWrapper() {}

        public QuotationLineItemWrapper(QuoteLineItem quoteLineItem, Map<Id, User> approverMap, Id currentUserId) {
            this.parentId = quoteLineItem.QuoteId;
            this.quoteLineItemId = quoteLineItem.Id;
            this.productId = quoteLineItem.Product2Id;
            this.productName = quoteLineItem.Product2.Name;
            this.quantity = quoteLineItem.Quantity;
            this.listPrice = quoteLineItem.ListPrice;
            this.salesPrice = quoteLineItem.UnitPrice;
            this.discount = quoteLineItem.Discount;
            this.approvalStatus = quoteLineItem.Approval_Status__c;
            this.approvalComments = quoteLineItem.Approval_Comments__c;
            this.updated = false;
            
            // Determine approval level and approver name
            if (quoteLineItem.Discount > 10) {
                this.approvalLevel = 'L3';
                this.discountApproverName = quoteLineItem.L3_Discount_Approver__c != null && approverMap.containsKey(quoteLineItem.L3_Discount_Approver__c) 
                    ? approverMap.get(quoteLineItem.L3_Discount_Approver__c).Name 
                    : 'Not Assigned';
                // Only L3 Approver can edit L3 items
                this.disableFields = (quoteLineItem.L3_Discount_Approver__c != currentUserId);
            } else if (quoteLineItem.Discount > 5) {
                this.approvalLevel = 'L2';
                this.discountApproverName = quoteLineItem.L2_Discount_Approver__c != null && approverMap.containsKey(quoteLineItem.L2_Discount_Approver__c)
                    ? approverMap.get(quoteLineItem.L2_Discount_Approver__c).Name 
                    : 'Not Assigned';
                // Only L2 Approver can edit L2 items
                this.disableFields = (quoteLineItem.L2_Discount_Approver__c != currentUserId);
            } else {
                this.approvalLevel = 'None';
                this.discountApproverName = 'Not Required';
                this.disableFields = true;
            }
        }
    }
}