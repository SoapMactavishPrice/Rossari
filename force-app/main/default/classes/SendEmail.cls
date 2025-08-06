public class SendEmail {
    @AuraEnabled
    public static void sendEmailNotification(Id oppId) {
        // Ensure oppId is not null
        if (oppId == null) {
            System.debug('Opportunity ID is null');
            return; // Exit if oppId is null
        }
        
        Opportunity opp = [
            SELECT Id, Name, OwnerId, Owner.Email, Owner.Name, 
            Owner.Manager.Email, Link__c, Owner.Id,
            (SELECT Product2.Name, UnitPrice, ListPrice, Quantity, Quality__c 
             FROM OpportunityLineItems) 
            FROM Opportunity 
            WHERE Id = :oppId LIMIT 1
        ];
        
        // Create the email message
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        
        // Check if the Who_will_attend__r object and email are valid
        if (opp.OwnerId == null || opp.Owner.Email == null) {
            System.debug('No valid email for OwnerId');
            return; // If no valid email, don't send
        }
        
        // Flag to track if email should be sent
        Boolean sendEmail = false;
        
        // Loop through the Opportunity Line Items and check the conditions on ListPrice and UnitPrice
        for (OpportunityLineItem item : opp.OpportunityLineItems) {
            // Check if both ListPrice and UnitPrice are 0 or null
            if ((item.UnitPrice == 0 || item.UnitPrice == null) && (item.ListPrice == 0 || item.ListPrice == null)) {
                sendEmail = true;
              
            }
        }
        
        
        // If no items with ListPrice and UnitPrice 0, don't send the email
        if (!sendEmail) {
            System.debug('No items with UnitPrice and ListPrice 0. Email will not be sent.');
            return; // Exit if no items meet the criteria
        }
        
        // Set the recipient and CC
        email.setToAddresses(new String[]{opp.Owner.Email}); // Send to Owner's email
        email.setCCAddresses(new String[]{'sahil@finessedirect.com'}); // CC another email
        
        // Associate the email with the Enquiry record for activity tracking
        email.setWhatId(opp.Id); // This line enables activity tracking on the enquiry
        
        // Subject line
        email.setSubject('Request for Purchase Price - ' + opp.Name);
        
        // Build the email body using the provided template
        String body = 'Dear ' + (opp.OwnerId != null ? opp.Owner.Name : 'Customer') + ',<br/><br/>';
        body += 'A new enquiry has been created, and we would require the purchase price details for the following Enquiry.<br/><br/>';
        
        body += 'Enquiry Name: ' + opp.Name + '<br/>';
        body += 'Enquiry Link: ' + opp.Link__c + '<br/><br/>';
        
        body += 'Below are the product details for your reference:<br/><br/>';
        body += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse; width: 100%;">';
        body += '<thead><tr style="background-color: #f2f2f2;"><th>Product Name</th><th>Quantity</th><th>Quality</th></tr></thead><tbody>';
        
        // Loop through the Opportunity Line Items and add them to the table
        for (OpportunityLineItem item : opp.OpportunityLineItems) {
            if (item.UnitPrice == 0 && item.ListPrice == 0) {
                body += '<tr>';
                body += '<td>' + item.Product2.Name + '</td>';
                body += '<td>' + (item.Quantity != null ? String.valueOf(item.Quantity) : '') + '</td>';
                body += '<td>' + (item.Quality__c != null ? item.Quality__c : '') + '</td>';
                body += '</tr>';
            }
        }
        
        body += '</tbody></table><br/><br/>';
        
        // Add closing remarks
        body += 'Kindly provide the necessary information at your earliest convenience.<br/><br/>';
        body += 'Looking forward to your response.<br/><br/>';
        body += 'Regards,<br/>';
        body += (opp.Owner != null ? opp.Owner.Name : 'System Notification'); // Opportunity Owner's Name
        
        // Set the HTML body of the email
        email.setHtmlBody(body);
        
        try {
            // Send the email
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
            System.debug('Email Sent Successfully');
        } catch (Exception e) {
            System.debug('Email Sending Failed: ' + e.getMessage());
        }
        
        // After sending the email, update the Request_Purchase_Price__c field on the OpportunityLineItems
        try {
            update opp.OpportunityLineItems; // Update the OpportunityLineItems with the updated checkbox field
           
        } catch (Exception e) {
            System.debug('Error updating OpportunityLineItems: ' + e.getMessage());
        }
        
        // Send custom notifications
        sendCustomNotification(opp);
        
        
        // Send email to Opportunity Owner's Manager if UnitPrice is less than ListPrice
        Boolean sendManagerEmail = false; // Flag for sending email to manager
        
        for (OpportunityLineItem item : opp.OpportunityLineItems) {
            if (item.UnitPrice < item.ListPrice) {
                sendManagerEmail = true; // Mark flag to send email to manager
                break; // No need to continue looping if we already found one such item
            }
        }
        
        // If there's an item where UnitPrice is less than ListPrice, send email to the manager
        if (sendManagerEmail && opp.Owner.Manager != null && opp.Owner.Manager.Email != null) {
            Messaging.SingleEmailMessage managerEmail = new Messaging.SingleEmailMessage();
            managerEmail.setToAddresses(new String[]{opp.Owner.Manager.Email}); // Send email to the manager's email
            managerEmail.setCCAddresses(new String[]{'sahil@finessedirect.com'}); // CC another email
            
            // Associate the email with the Enquiry record for activity tracking
        	managerEmail.setWhatId(opp.Id); // This line enables activity tracking on the enquiry
            
            managerEmail.setSubject('Enquiry Price Alert - ' + opp.Name);
            
            String managerBody = 'Dear Manager,<br/><br/>';
            managerBody += 'Please note that an opportunity has been identified where the Sales Price is less than the List Price.<br/><br/>';
            managerBody += 'Enquiry Name: ' + opp.Name + '<br/>';
            managerBody += 'Enquiry Link: ' + opp.Link__c + '<br/><br/>';
            
            managerBody += 'Below are the product details:<br/><br/>';
            managerBody += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse; width: 100%;">';
            managerBody += '<thead><tr style="background-color: #f2f2f2;"><th>Product Name</th><th>List Price</th><th>Sales Price</th></tr></thead><tbody>';
            
            // Loop through the Opportunity Line Items and add them to the manager's email body
            for (OpportunityLineItem item : opp.OpportunityLineItems) {
                managerBody += '<tr>';
                managerBody += '<td>' + item.Product2.Name + '</td>';
                managerBody += '<td>' + (item.ListPrice != null ? String.valueOf(item.ListPrice) : 'Not Available') + '</td>';
                managerBody += '<td>' + (item.UnitPrice != null ? String.valueOf(item.UnitPrice) : 'Not Available') + '</td>';
                managerBody += '</tr>';
            }
            
            managerBody += '</tbody></table><br/>';
            managerBody += 'Kindly review the details at your earliest convenience.<br/><br/>';
            
            managerBody += 'Regards,<br/>';
            managerBody += (opp.Owner != null ? opp.Owner.Name : 'System Notification'); // Opportunity Owner's Name
            
            managerEmail.setHtmlBody(managerBody);
            
            try {
                // Send the email to the manager
                Messaging.sendEmail(new Messaging.SingleEmailMessage[]{managerEmail});
                System.debug('Manager Email Sent Successfully');
            } catch (Exception e) {
                System.debug('Manager Email Sending Failed: ' + e.getMessage());
            }
            // Send Salesforce notification to users
            sendNotificationToUsers(opp);
        }
    }
    
    private static void sendNotificationToUsers(Opportunity opp) {
        try {
            // Fetch custom notification type ID
            Id notificationTypeId = [
                SELECT Id
                FROM CustomNotificationType
                WHERE DeveloperName = 'Notification_to_Owner'
                LIMIT 1
            ].Id;
            
            // Create the notification object
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle('Enquiry Price Alert');
            notification.setBody('Sales Price is less than List Price for Enquiry: ' + opp.Name);
            notification.setTargetId(opp.Id); // Opportunity record
            notification.setNotificationTypeId(notificationTypeId);
            // Create a set of recipient IDs
            Set<String> recipientIds = new Set<String>{opp.OwnerId};
            if (opp.Owner.ManagerId != null) {
                recipientIds.add(opp.Owner.ManagerId);
            }
            
            // Send the notification
            notification.send(recipientIds);
            
            System.debug('Custom notification sent successfully.');
        } catch (Exception e) {
            System.debug('Error sending custom notification: ' + e.getMessage());
        }
    }
    
    
    private static void sendCustomNotification(Opportunity opp) {
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
            notification.setTitle('Enquiry Price Alert');
            notification.setBody('Products has been added with List Price 0: ' + opp.Name);
            notification.setTargetId(opp.Id); // Opportunity record
            notification.setNotificationTypeId(notificationTypeId);
            
            Set<String> recipientIds = new Set<String>{opp.OwnerId};
                if (opp.Owner != null && opp.OwnerId != null) {
                    recipientIds.add(opp.Owner.Id);
                }
            
            notification.send(recipientIds);
                        
            
            System.debug('Custom notification for Purchase Price sent successfully.');
        } catch (Exception e) {
            System.debug('Error sending custom notification: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void sendEmailNotificationQuote(Id quoteId) {
        if (quoteId == null) {
            System.debug('Quote ID is null');
            return; // Exit if quoteId is null
        }
        
        // Query the Quote record by ID and its QuoteLineItems, and the OwnerId email
        Quote quote = [SELECT Id, Name, OwnerId, Owner.Name, Link__c, Owner.Email, 
                       (SELECT Product2.Name, UnitPrice, ListPrice, Quantity, Quality__c FROM QuoteLineItems) 
                       FROM Quote WHERE Id = :quoteId LIMIT 1];
        
        System.debug('Quote found: ' + quote.Name);
        
        // Create the email message
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        
        // Check if the Who_will_attend__c field on the Quote has a valid email
        if (quote.OwnerId == null) {
            System.debug('No valid email for OwnerId');
            return; // If no valid email, don't send
        }
        
        // Flag to track if email should be sent
        Boolean sendEmail = false;
        System.debug('Checking Quote Line Items for conditions...');
        
        // Loop through the Quote Line Items and check the conditions on ListPrice and UnitPrice
        for (QuoteLineItem item : quote.QuoteLineItems) {
            if ((item.UnitPrice == 0 || item.UnitPrice == null) && (item.ListPrice == 0 || item.ListPrice == null)) {
                System.debug('Item ' + item.Product2.Name + ' has UnitPrice and ListPrice set to 0 or null');
                sendEmail = true;
              //  item.Request_Purchase_Price__c = true; // Set Request_Purchase_Price__c to true on QuoteLineItem
            } else {
                System.debug('Item ' + item.Product2.Name + ' does not require email: UnitPrice = ' + item.UnitPrice + ', ListPrice = ' + item.ListPrice);
            }
        }
        
        // If no items with ListPrice and UnitPrice 0, don't send the email
        if (!sendEmail) {
            System.debug('No items with UnitPrice and ListPrice 0. Email will not be sent.');
            return; // Exit if no items meet the criteria
        }
        
        // Set the recipient and CC
        email.setToAddresses(new String[]{quote.Owner.Email}); // Send to OwnerId's email
        email.setCCAddresses(new String[]{'sahil@finessedirect.com'}); // CC another email
                
        // Associate the email with the Quote record for activity tracking
        email.setWhatId(quote.Id); // ✅ This line enables activity tracking on the Quote

        // Subject line
        email.setSubject('Request for Purchase Price - ' + quote.Name);
        
        String body = 'Dear ' + (quote.OwnerId != null ? quote.Owner.Name : 'Customer') + ',<br/><br/>';
        body += 'A new quote has been created, and we would require the purchase price details for the following quote.<br/><br/>';
        
        body += 'Quote Name: ' + quote.Name + '<br/><br/>';
        body += 'Quote Link: ' + quote.Link__c + '<br/><br/>';
        
        body += 'Below are the product details for your reference:<br/><br/>';
        body += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse; width: 100%;">';
        body += '<thead><tr style="background-color: #f2f2f2;"><th>Product Name</th><th>Quantity</th><th>Quality</th></tr></thead><tbody>';
        
        // Loop through the Quote Line Items and add them to the table
        for (QuoteLineItem item : quote.QuoteLineItems) {
            if (item.UnitPrice == 0 && item.ListPrice == 0) {
                body += '<tr>';
                body += '<td>' + item.Product2.Name + '</td>';
                body += '<td>' + (item.Quantity != null ? String.valueOf(item.Quantity) : '') + '</td>';
                body += '<td>' + (item.Quality__c != null ? item.Quality__c : '') + '</td>';
                body += '</tr>';
            }
        }
        
        body += '</tbody></table><br/><br/>';
        
        body += 'Kindly provide the necessary information at your earliest convenience.<br/><br/>';
        body += 'Looking forward to your response.<br/><br/>';
        body += 'Regards,<br/>';
        body += 'System Notification'; // Quote Owner's Name
        
        email.setHtmlBody(body);
        
        try {
            // Send the email
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
            System.debug('Email Sent Successfully');
        } catch (Exception e) {
            System.debug('Email Sending Failed: ' + e.getMessage());
        }
        
        // After sending the email, update the Request_Purchase_Price__c field on the QuoteLineItems
        try {
            update quote.QuoteLineItems; // Update the QuoteLineItems with the updated checkbox field
         
        } catch (Exception e) {
            System.debug('Error updating QuoteLineItems: ' + e.getMessage());
        }
        // Send custom notifications
        sendCustomNotification1(quote);
    }
    
    private static void sendCustomNotification1(Quote quote) {
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
            notification.setBody('Products has been added with List Price 0: ' + quote.Name);
            notification.setTargetId(quote.Id); // Opportunity record
            notification.setNotificationTypeId(notificationTypeId);
            
            Set<String> recipientIds = new Set<String>{quote.OwnerId};
                if (quote.Owner != null && quote.OwnerId != null) {
                    recipientIds.add(quote.OwnerId);
                }
            
            notification.send(recipientIds);
            
                        
            
            System.debug('Custom notification for Quote Purchase Price sent successfully.');
        } catch (Exception e) {
            System.debug('Error sending custom notification: ' + e.getMessage());
        }
    }
    
}