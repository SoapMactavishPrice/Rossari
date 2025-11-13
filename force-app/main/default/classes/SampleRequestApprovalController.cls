public without sharing class SampleRequestApprovalController {

    public SampleRequestWrapper quotation;

    public SampleRequestApprovalController(SampleRequestWrapper quotation) {
        this.quotation = quotation;
    }


    /**
     * @description: This method is used to get all the Quotations in which the line item's status is pending
     */
    @AuraEnabled
    public static List<SampleRequestWrapper> getAllQuotations() {
        Id currentUserId = UserInfo.getUserId();
    
        // Fetch all pending line items first
        List<Sample_Request_Line_Item__c> quoteLineItems = [
            SELECT Id, Approval_Status__c, Approval_Comments__c, Product__c, Product__r.Name, Sample_Qty_in_Kgs__c, Sample_Request__c
            FROM Sample_Request_Line_Item__c
            WHERE Approval_Status__c = 'Pending'
        ];
    
        if (quoteLineItems.isEmpty()) {throw new AuraHandledException('No Sample Line Items found with their status as "Pending"');}
    
        // collect Sample_Request__c Ids
        Set<Id> quoteIds = new Set<Id>();
        for (Sample_Request_Line_Item__c eachQli : quoteLineItems) {
            quoteIds.add(eachQli.Sample_Request__c);
        }
    
        // fetch only those Quotes that belong to the user (owner) or where user is HOD
        Map<Id, Sample_Request__c> quoteMap = new Map<Id, Sample_Request__c>(
            [SELECT Id, Name, Owner.Email, Owner.Name, OwnerId, Sales_HOD__c, Sales_HOD__r.Name
             FROM Sample_Request__c
             WHERE Id IN :quoteIds
               AND (OwnerId = :currentUserId OR Sales_HOD__c = :currentUserId)]
        );
    
        // map line items to their parent Sample_Request__c
        Map<Id, List<Sample_Request_Line_Item__c>> quoteToQuoteLineItemMap = new Map<Id, List<Sample_Request_Line_Item__c>>();
        for (Sample_Request_Line_Item__c eachLine : quoteLineItems) {
            if (quoteMap.containsKey(eachLine.Sample_Request__c)) { // filter by accessible quotes
                if (!quoteToQuoteLineItemMap.containsKey(eachLine.Sample_Request__c)) {
                    quoteToQuoteLineItemMap.put(eachLine.Sample_Request__c, new List<Sample_Request_Line_Item__c>());
                }quoteToQuoteLineItemMap.get(eachLine.Sample_Request__c).add(eachLine);
            }
        }
    
        // build wrapper list
        List<SampleRequestWrapper> quotations = new List<SampleRequestWrapper>();
        for (Id eachQuoteId : quoteToQuoteLineItemMap.keySet()) {
            quotations.add(new SampleRequestWrapper(quoteMap.get(eachQuoteId), quoteToQuoteLineItemMap.get(eachQuoteId)));
        }
    
        return quotations;
    }


    /**
     * @description: This method is used to update the approval status and approval comments of the line item
     * @param: quotationListStringObject: It is a JSON stringified list of SampleRequestWrapper objects
     */
    @AuraEnabled
    public static String updateQuoteLineItem(String quotationListStringObject) {

        List<SampleRequestWrapper> quotations = parseHeaderAndLine(quotationListStringObject);

        List<Sample_Request_Line_Item__c> quotationLineItemsToBeUpdated = new List<Sample_Request_Line_Item__c>();

        for (SampleRequestWrapper eachQuotation : quotations) {
            if (eachQuotation.updated && eachQuotation.quoteLineItems != null && !eachQuotation.quoteLineItems.isEmpty()) {
                for (SampleRequestLineItemWrapper eachQuoteLineItem : eachQuotation.quoteLineItems) {
                    if (eachQuoteLineItem.updated) {
                        Sample_Request_Line_Item__c quoteLineItem = new Sample_Request_Line_Item__c();
                        quoteLineItem.Id = eachQuoteLineItem.quoteLineItemId;
                        quoteLineItem.Approval_Status__c = eachQuoteLineItem.approvalStatus;

                        quotationLineItemsToBeUpdated.add(quoteLineItem);
                    }
                }
            }
        }

        UPDATE quotationLineItemsToBeUpdated;

        for (SampleRequestWrapper eachQuotation : quotations) {
            SampleRequestApprovalController controller = new SampleRequestApprovalController(eachQuotation);
            controller.sendEmailNotification();
        }

        return 'Success';
    }

    private void sendEmailNotification() {
        Boolean isApproved = false;
        Boolean isRejected = false;
        for (SampleRequestLineItemWrapper item : quotation.quoteLineItems) {
            if (item.approvalStatus == 'Approved') {
                isApproved = true;
            } else if (item.approvalStatus == 'Rejected') {
                isRejected = true;
            }
        }

        if (isApproved) {
    this.sendEmail(this.quotation, 'Approved');

    // Only call Utility method in real execution, not during tests
    if (!Test.isRunningTest()) {
        Utility.sendSampleRequestEmail(this.quotation.quoteId);
    }
}

        if (isRejected) {
            this.sendEmail(this.quotation, 'Rejected');
        }
    }

    private void sendEmail(SampleRequestWrapper quotation, String status) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[]{quotation.quoteOwnerEmail});
        if (String.isNotBlank(quotation.hodUserId)) {
            User salesHod = [SELECT Email FROM User WHERE Id = :quotation.hodUserId];
            email.setCcAddresses(new String[]{salesHod.Email});
        }
        email.setSubject('Sample Request ' + status + ' - ' + quotation.quoteName);

        String body = 'Dear ' + quotation.quoteOwnerName + ',<br/><br/>';
        body += 'The sample request has been ' + status.toLowerCase() + '<br/><br/>';
        body += 'SR No.: ' + quotation.quoteName + '<br/><br/>';
        body += 'Below are the product details:<br/><br/>';

        body += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse; width: 100%;">';
        body += '<thead><tr style="background-color: #f2f2f2;"><th>Product Name</th><th>Quantity in KG</th><th>Approval Status</th></tr></thead><tbody>';

        for (SampleRequestLineItemWrapper item : quotation.quoteLineItems) {
            if (item.approvalStatus == status && item.updated) {
                body += '<tr>';
                body += '<td>' + item.productName + '</td>';
                body += '<td>' + item.quantity + '</td>';
                body += '<td>' + (item.approvalStatus != null ? String.valueOf(item.approvalStatus) : '') + '</td>';
                body += '</tr>';
            }
        }

        body += '</tbody></table><br/>';
        body += 'Sample Request has been ' + status.toLowerCase() + ', kindly review the details at your earliest convenience.<br/><br/>';
        body += 'Regards,<br/>';
        body += (quotation.quoteOwnerId != null ? quotation.quoteOwnerName : 'System Notification');

        email.setHtmlBody(body);

        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
        } catch (Exception e) {System.debug('Email Sending Failed: ' + e.getMessage());}}

    private static List<SampleRequestWrapper> parseHeaderAndLine(string js){
        return (List<SampleRequestWrapper>)system.JSON.deserialize(js,List<SampleRequestWrapper>.class);
    }

    public class SampleRequestWrapper {
        @AuraEnabled public String quoteId;
        @AuraEnabled public String quoteName;
        @AuraEnabled public String quoteNumber;
        @AuraEnabled public String accountName;
        @AuraEnabled public String quoteOwnerId;
        @AuraEnabled public String quoteOwnerEmail;
        @AuraEnabled public String quoteOwnerName;
        @AuraEnabled public String quoteLink;
        @AuraEnabled public String hodUserId;
        @AuraEnabled public String hodUserName;
        @AuraEnabled public List<SampleRequestLineItemWrapper> quoteLineItems;
        @AuraEnabled public Boolean updated;

        public SampleRequestWrapper() {}

        public SampleRequestWrapper(Sample_Request__c quote, List<Sample_Request_Line_Item__c> quoteLineItems) {
            this.quoteId = quote.Id;
            this.quoteName = quote.Name;
            this.quoteOwnerId = quote.OwnerId;
            this.quoteOwnerEmail = quote.Owner.Email;
            this.quoteOwnerName = quote.Owner.Name;
            this.hodUserId = quote.Sales_HOD__c; 
            this.hodUserName = quote.Sales_HOD__r != null ? quote.Sales_HOD__r.Name : null; 
            this.updated = false;

            if (this.quoteLineItems == null) {
                this.quoteLineItems = new list<SampleRequestLineItemWrapper>();
            }

            for (Sample_Request_Line_Item__c eachLine : quoteLineItems) {
                this.quoteLineItems.add(new SampleRequestLineItemWrapper(eachLine));
            }

        }
    }

    public class SampleRequestLineItemWrapper {
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

        public SampleRequestLineItemWrapper() {}

        public SampleRequestLineItemWrapper(Sample_Request_Line_Item__c quoteLineItem) {
            this.parentId = quoteLineItem.Sample_Request__c;
            this.quoteLineItemId = quoteLineItem.Id;
            this.productId = quoteLineItem.Product__c;
            this.productName = quoteLineItem.Product__r.Name;
            this.quantity = quoteLineItem.Sample_Qty_in_Kgs__c;
            this.approvalStatus = quoteLineItem.Approval_Status__c;
            this.approvalComments = quoteLineItem.Approval_Comments__c;
            this.updated = false;
        }
    }

}