public class ManagerEmailSender {
    private static void sendNotificationToUsers(Opportunity opp) {
        try {
            Id notificationTypeId = [
                SELECT Id
                FROM CustomNotificationType
                WHERE DeveloperName = 'Notification_to_Owner'
                LIMIT 1
            ].Id;

            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle('Enquiry Price Alert');
            notification.setBody('Sales Price is less than List Price for Enquiry: ' + opp.Name);
            notification.setTargetId(opp.Id);
            notification.setNotificationTypeId(notificationTypeId);

            Set<String> recipientIds = new Set<String>{opp.OwnerId};
            if (opp.Owner.ManagerId != null) {
                recipientIds.add(opp.Owner.ManagerId);
            }

            notification.send(recipientIds);
            System.debug('Custom notification sent successfully.');
        } catch (Exception e) {
            System.debug('Error sending custom notification: ' + e.getMessage());
        }
    }

    
    
    
    @AuraEnabled
    public static void sendEmailToManagerForQuote(Id quoteId) {
        // Ensure quoteId is not null
        if (quoteId == null) {
            System.debug('Quote ID is null');
            return; // Exit if quoteId is null
        }
        
        // Query the Quote record by ID and its QuoteLineItems
        Quote quote = [SELECT Id, Name, Opportunity.Name, OwnerId, Owner.Name,Link__c, 
                       (SELECT Product2.Name, UnitPrice, ListPrice, Quantity FROM QuoteLineItems) 
                       FROM Quote WHERE Id = :quoteId LIMIT 1];
        
        // Get the Owner of the Quote and fetch the Manager's Email
        User quoteOwner = [SELECT Manager.Email FROM User WHERE Id = :quote.OwnerId LIMIT 1];
        
        // Create the email message
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        
        // Send email to Quote Owner's Manager if UnitPrice is less than ListPrice
        Boolean sendManagerEmail = false; // Flag for sending email to manager
        
        for (QuoteLineItem item : quote.QuoteLineItems) {
            if (item.UnitPrice < item.ListPrice) {
                sendManagerEmail = true; // Mark flag to send email to manager
                break; // No need to continue looping if we already found one such item
            }
        }
        
        // If there's an item where UnitPrice is less than ListPrice, send email to the manager
        if (sendManagerEmail && quoteOwner.Manager != null && quoteOwner.Manager.Email != null) {
            Messaging.SingleEmailMessage managerEmail = new Messaging.SingleEmailMessage();
        //    managerEmail.setToAddresses(new String[]{quoteOwner.Manager.Email}); // Send email to the manager's email
            managerEmail.setCCAddresses(new String[]{'ankit@finessedirect.com'}); // CC another email
            managerEmail.setToAddresses(new String[]{'sahil@finessedirect.com'});
            
            // Associate the email with the Quote record for activity tracking
        	managerEmail.setWhatId(quote.Id); // ✅ This line enables activity tracking on the Quote
            
            managerEmail.setSubject('Quote Price Alert - ' + quote.Name);
            
            String managerBody = 'Dear Sir,<br/><br/>';
            managerBody += 'Please note that a quote has been identified where the Sales Price is less than the List Price.<br/><br/>';
            managerBody += 'Please provide your approval to proceed with the Sales Price.<br/><br/>';
            managerBody += 'Quote Name: ' + quote.Name + '<br/>';
            managerBody += 'Quote Link: ' + quote.Link__c + '<br/><br/>';
            
            managerBody += 'Below are the product details:<br/><br/>';
            managerBody += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse; width: 100%;">';
            managerBody += '<thead><tr style="background-color: #f2f2f2;"><th>Product Name</th><th>List Price</th><th>Sales Price</th></tr></thead><tbody>';
            
            // Loop through the Quote Line Items and add them to the manager's email body
            for (QuoteLineItem item : quote.QuoteLineItems) {
                managerBody += '<tr>';
                managerBody += '<td>' + item.Product2.Name + '</td>';
                managerBody += '<td>' + (item.ListPrice != null ? String.valueOf(item.ListPrice) : 'Not Available') + '</td>';
                managerBody += '<td>' + (item.UnitPrice != null ? String.valueOf(item.UnitPrice) : 'Not Available') + '</td>';
                managerBody += '</tr>';
            }
            
            managerBody += '</tbody></table><br/>';
            managerBody += 'Kindly review the details at your earliest convenience.<br/><br/>';
            
            managerBody += 'Regards,<br/>';
            managerBody += (quote.Owner != null ? quote.Owner.Name : 'System Notification'); // Quote Owner's Name
            
            managerEmail.setHtmlBody(managerBody);
            
            try {
                // Send the email to the manager
                Messaging.sendEmail(new Messaging.SingleEmailMessage[]{managerEmail});
                System.debug('Manager Email Sent Successfully for Quote');
            } catch (Exception e) {
                System.debug('Manager Email Sending Failed for Quote: ' + e.getMessage());
            }
            
            // Send Salesforce notification to users
            sendNotificationToUsers(quote);
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
                
                // Get the Owner's Manager ID
            User quoteOwner = [SELECT ManagerId FROM User WHERE Id = :quote.OwnerId LIMIT 1];
            if (quoteOwner.ManagerId != null) {
                recipientIds.add(quoteOwner.ManagerId);
            }
            
            
            // Send the notification
            notification.send(recipientIds);
            
            System.debug('Quote Custom notification sent successfully.');
        } catch (Exception e) {
            System.debug('Error sending custom notification: ' + e.getMessage());
        }
    }

    
}