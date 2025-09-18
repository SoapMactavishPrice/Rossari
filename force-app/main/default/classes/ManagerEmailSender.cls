public class ManagerEmailSender {
    
    @AuraEnabled
    public static void sendEmailToManagerForQuote(Id quoteId) {
        if (quoteId == null) {
            System.debug('Quote ID is null');
            return;
        }
        
        try {
            // Query Quote with Line Items including Approval_Status__c
            Quote quote = [SELECT Id, Name, Opportunity.Name, OwnerId, Owner.Name, Link__c, HOD_of_Sales_Department__c, HOD_of_Sales_Department__r.Email,
                           (SELECT Id, Product2.Name, UnitPrice, ListPrice, Quantity, Approval_Status__c 
                            FROM QuoteLineItems ) 
                           FROM Quote WHERE Id = :quoteId LIMIT 1];
            
            // Check if any QLI requires approval
            if (!quote.QuoteLineItems.isEmpty() && quote.HOD_of_Sales_Department__r.Email != null) {
                // Update Approval_Status__c to "Pending" for discounted QLIs
                List<QuoteLineItem> qlisToUpdate = new List<QuoteLineItem>();
                for (QuoteLineItem qli : quote.QuoteLineItems) {
                    if (qli.UnitPrice < qli.ListPrice) {
                        qli.Approval_Status__c = 'Pending';
                        qlisToUpdate.add(qli);
                    }
                }
                
                if (!qlisToUpdate.isEmpty()) {
                    update qlisToUpdate;
                    
                    quote.Status = 'Price Approval';
                    update quote;
                    
                    
                    // Send approval email to manager
                    Messaging.SingleEmailMessage managerEmail = new Messaging.SingleEmailMessage();
                    managerEmail.setToAddresses(new String[]{quote.HOD_of_Sales_Department__r.Email});
                    managerEmail.setCCAddresses(new String[]{'sahil@finessedirect.com'});
                    managerEmail.setWhatId(quote.Id);
                    managerEmail.setSubject('Quote Price Approval Required - ' + quote.Name);
                    
                    // Build email body
                    String managerBody = 'Dear Sir,<br/><br/>';
                    managerBody += 'Please note that a quote has been identified where the Sales Price is less than the List Price:<br/><br/>';
                    managerBody += 'Please provide your approval to proceed with the Sales Price.<br/><br/>';
                    managerBody += '<strong>Quote:</strong> ' + quote.Name + '<br/>';
                    managerBody += '<strong>Link:</strong> ' + quote.Link__c + '<br/><br/>';
                    managerBody += '<table border="1" cellpadding="5" style="border-collapse:collapse;width:100%">';
                    managerBody += '<tr style="background-color:#f2f2f2"><th>Product</th><th>List Price</th><th>Sales Price</th></tr>';
                    
                    for (QuoteLineItem qli : qlisToUpdate) {
                        Decimal discount = ((qli.ListPrice - qli.UnitPrice) / qli.ListPrice) * 100;
                        managerBody += '<tr>';
                        managerBody += '<td>' + qli.Product2.Name + '</td>';
                        managerBody += '<td>' + qli.ListPrice.setScale(2) + '</td>';
                        managerBody += '<td>' + qli.UnitPrice.setScale(2) + '</td>';
                        managerBody += '</tr>';
                    }
                    
                    managerBody += '</table><br/>';
                    managerBody += 'Please review and approve at your earliest convenience.<br/><br/>';
                    managerBody += 'Regards,<br/>' + quote.Owner.Name;
                    
                    managerEmail.setHtmlBody(managerBody);
                    
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[]{managerEmail});
                    System.debug('Approval email sent for Quote: ' + quote.Id);
                    
                    // Send in-app notification
                    sendNotificationToUsers(quote);
                }
            }
        } catch(Exception e) {
            System.debug('Error in sendEmailToManagerForQuote: ' + e.getMessage() + 
                         ' StackTrace: ' + e.getStackTraceString());
            throw new AuraHandledException('Failed to send approval request: ' + e.getMessage());
        }
    }
    
    
    private static void sendNotificationToUsers(Quote quote) {
        try {
            // Fetch custom notification type ID
            List<CustomNotificationType> notificationTypes = [
                SELECT Id
                FROM CustomNotificationType
                WHERE DeveloperName = 'Notification_to_Owner'
                LIMIT 1
            ];
            
            if (notificationTypes.isEmpty()) {
                System.debug('No custom notification type found with DeveloperName: Notification_to_Owner');
                return; // Exit if no custom notification type is found
            }
            
            Id notificationTypeId = notificationTypes[0].Id;
            
            // Create the notification object
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle('Quote Price Alert');
            notification.setBody('Sales Price is less than List Price for Quote: ' + quote.Name);
            notification.setTargetId(quote.Id); // Quote record
            notification.setNotificationTypeId(notificationTypeId);
            
            // Create a set of recipient IDs
            Set<String> recipientIds = new Set<String>{quote.OwnerId};
                
                // Add HOD of Sales Department
                if (quote.HOD_of_Sales_Department__c != null) {
                    recipientIds.add(quote.HOD_of_Sales_Department__c);
                }
            
            // Send the notification
            notification.send(recipientIds);
            
            System.debug('Quote Custom notification sent successfully.');
        } catch (Exception e) {
            System.debug('Error sending custom notification: ' + e.getMessage());
        }
    }
    
    
}