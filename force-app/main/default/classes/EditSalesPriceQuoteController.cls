public class EditSalesPriceQuoteController {

    public String currentRecID { get; set; }
    public List<QuoteLineItem> quoteLineItemsList { get; set; }
    public Quote quote { get; set; }
    public Id ownerManagerId { get; set; }

    public EditSalesPriceQuoteController() {

        currentRecID = ApexPages.CurrentPage().getparameters().get('id');

        if (currentRecID != null) {
            fetchQuote();
            List<QuoteLineItem> allQuoteItems = [SELECT Id,Product2Id, Product2.Name,QuoteId, ListPrice, Quantity,
                                                      Reject_Reason__c, Approver__c, Approval_Status__c, Approval_Comments__c, UnitPrice
                                                     FROM QuoteLineItem 
                                                     WHERE QuoteId = :currentRecID];

            quoteLineItemsList = new List<QuoteLineItem>();
            for (QuoteLineItem item : allQuoteItems) {
                if (item.UnitPrice < item.ListPrice && item.Approval_Status__c != 'Approved') {
                    item.Approver__c = ownerManagerId; // Set Approver__c to Owner.ManagerId
                    quoteLineItemsList.add(item);
                }
            }
        }
    }


    public EditSalesPriceQuoteController(String quoteId) {

        currentRecID = quoteId;

        if (currentRecID != null) {
            fetchQuote();
            List<QuoteLineItem> allQuoteItems = [SELECT Id,Product2Id, Product2.Name,QuoteId, ListPrice, Quantity,
                                                      Reject_Reason__c, Approver__c, Approval_Status__c, Approval_Comments__c, UnitPrice
                                                     FROM QuoteLineItem 
                                                     WHERE QuoteId = :currentRecID];

            quoteLineItemsList = new List<QuoteLineItem>();
            for (QuoteLineItem item : allQuoteItems) {
                if (item.UnitPrice < item.ListPrice && item.Approval_Status__c != 'Approved') {
                    item.Approver__c = ownerManagerId; // Set Approver__c to Owner.ManagerId
                    quoteLineItemsList.add(item);
                }
            }
        }
    }

    // Fetch Quote Details with OwnerId field and Owner's Manager Email
    private void fetchQuote() {
        quote = [SELECT Id, Name, Owner.Email, Owner.Name, OwnerId,Link__c  
                 FROM Quote 
                 WHERE Id = :currentRecID LIMIT 1];
       // ownerManagerId = quote.Owner.ManagerId;
    }

    // Save Method
    public PageReference Save() {

        List<QuoteLineItem> updatedQuoteItems = new List<QuoteLineItem>();

        if (!quoteLineItemsList.isEmpty()) {

            for (QuoteLineItem quoteItem : quoteLineItemsList) {
                if (quoteItem.UnitPrice != null) {
                    // Perform any necessary checks here if needed
                }
            }

            update quoteLineItemsList; // Update the QuoteLineItems with the modified values
            sendEmailNotification();  // Send Email Notification
        }

        // Redirect to the Quote Record Page
        PageReference pg = new PageReference('/' + currentRecID);
        pg.setRedirect(true);
        return pg;
    }

    Public PageReference Cancel() {
        PageReference pg = new PageReference('/' + currentRecID);
        pg.setRedirect(true);
        return pg;        
    }

    // Email Notification Method
    public void sendEmailNotification() {

        System.debug('Inside sendEmailNotification');
        // Check if any QuoteLineItem has Approval_Status__c set to 'Approved' or 'Rejected'
        Boolean isApproved = false;
        Boolean isRejected = false;
        for (QuoteLineItem item : quoteLineItemsList) {
            if (item.Approval_Status__c == 'Approved') {
                isApproved = true;
            } else if (item.Approval_Status__c == 'Rejected') {
                isRejected = true;
            }
        }

        // Send email if the status is 'Approved'
        if (isApproved) {
            System.debug('Inside sendEmailNotification isApproved');
            sendEmail('Approved');
        }

        // Send email if the status is 'Rejected'
        if (isRejected) {
            System.debug('Inside sendEmailNotification isRejected');
            sendEmail('Rejected');
        }
    }

    private void sendEmail(String status) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[]{quote.Owner.Email});
        email.setCCAddresses(new String[]{'sahil@finessedirect.com', 'praveen@finessedirect.com'});
        email.setSubject('Sales Price ' + status + ' - ' + quote.Name);

        String body = 'Dear ' + quote.Owner.Name + ',<br/><br/>';
        body += 'The Sales Price has been ' + status.toLowerCase() + ' for the following Quote:<br/><br/>';
        body += 'Quote Name: ' + quote.Name + '<br/>';
        body += 'Quote Link: ' + quote.Link__c + '</a><br/><br/>';
        body += 'Below are the product details:<br/><br/>';

        body += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse; width: 100%;">';
        body += '<thead><tr style="background-color: #f2f2f2;"><th>Product Name</th><th>List Price</th><th>Sales Price</th><th>Approval Status</th></tr></thead><tbody>';

        for (QuoteLineItem item : quoteLineItemsList) {
            if (item.Approval_Status__c == status) {
                body += '<tr>';
                body += '<td>' + item.Product2.Name + '</td>';
                body += '<td>' + (item.ListPrice != null ? String.valueOf(item.ListPrice) : 'Not Available') + '</td>';
                body += '<td>' + (item.UnitPrice != null ? String.valueOf(item.UnitPrice) : 'Not Available') + '</td>';
                body += '<td>' + (item.Approval_Status__c != null ? String.valueOf(item.Approval_Status__c) : '') + '</td>';
                body += '</tr>';
            }
        }

        body += '</tbody></table><br/>';
        body += 'Sales Price has been ' + status.toLowerCase() + ', kindly review the details at your earliest convenience.<br/><br/>';
        body += 'Regards,<br/>';
        body += (quote.OwnerId != null ? quote.Owner.Name : 'System Notification');

        email.setHtmlBody(body);

        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
        } catch (Exception e) {
            System.debug('Email Sending Failed: ' + e.getMessage());
        }
    }
}