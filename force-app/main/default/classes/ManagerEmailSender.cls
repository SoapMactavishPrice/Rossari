public class ManagerEmailSender {
    
    // Cache for approver mappings
    private static Map<String, Discount_Approver_Mapping__mdt> approverMap {
        get {
            if (approverMap == null) {
                approverMap = new Map<String, Discount_Approver_Mapping__mdt>();
                for (Discount_Approver_Mapping__mdt mapping : [
                    SELECT User_Type__c, L2_Approver_Username__c, L3_Approver_Username__c
                    FROM Discount_Approver_Mapping__mdt
                ]) {
                    approverMap.put(mapping.User_Type__c, mapping);
                }
            }
            return approverMap;
        }
        set;
    }
    
    // Cache for user lookup
    private static Map<String, User> userCache {
        get {
            if (userCache == null) {
                userCache = new Map<String, User>();
                // Query all potential approvers
                for (User u : [
                    SELECT Id, Name, Email, Username 
                    FROM User 
                    WHERE IsActive = true
                ]) {
                    userCache.put(u.Username, u);
                }
            }
            return userCache;
        }
        set;
    }
    
    @AuraEnabled
    public static void sendEmailToManagerForQuote(Id quoteId) {
        if (quoteId == null) {
            System.debug('Quote ID is null');
            return;
        }
        
        try {
            // Query Quote with Line Items and Owner's User Type - FIXED QUERY
            Quote quote = [SELECT Id, Name, Opportunity.Name, OwnerId, Owner.Name, Owner.Email, 
                           Opportunity.Owner.User_Type__c, Link__c, 
                           (SELECT Id, Product2.Name, UnitPrice, ListPrice, Quantity, Discount, 
                            Approval_Status__c
                            FROM QuoteLineItems 
                            WHERE Discount > 5)
                           FROM Quote WHERE Id = :quoteId LIMIT 1];
            
            // Debug to check if User_Type__c is being retrieved
            System.debug('Quote Owner User Type: ' + quote.Opportunity.Owner.User_Type__c);
            System.debug('Quote Owner: ' + quote.Owner.Name);
            
            // Check if User_Type__c is null and handle it
            if (quote.Opportunity.Owner.User_Type__c == null) {
                throw new AuraHandledException('User Type is not defined for the quote owner: ' + quote.Owner.Name);
            }
            
            // Get approver mapping based on quote owner's user type
            Discount_Approver_Mapping__mdt approverMapping = approverMap.get(quote.Opportunity.Owner.User_Type__c);
            
            if (approverMapping == null) {
                throw new AuraHandledException('No approver mapping found for user type: ' + quote.Opportunity.Owner.User_Type__c);
            }
            
            // Lookup users from usernames
            User l2Approver = userCache.get(approverMapping.L2_Approver_Username__c);
            User l3Approver = userCache.get(approverMapping.L3_Approver_Username__c);
            
            // Debug approver lookup
            System.debug('L2 Approver Username from Metadata: ' + approverMapping.L2_Approver_Username__c);
            System.debug('L3 Approver Username from Metadata: ' + approverMapping.L3_Approver_Username__c);
            System.debug('L2 Approver Found: ' + l2Approver);
            System.debug('L3 Approver Found: ' + l3Approver);
            
            if (l2Approver == null && l3Approver == null) {
                throw new AuraHandledException('No valid approvers found for user type: ' + quote.Opportunity.Owner.User_Type__c);
            }
            
            // Check if any QLI requires approval based on discount
            if (!quote.QuoteLineItems.isEmpty()) {
                // Separate line items by approval level
                List<QuoteLineItem> l2ApprovalItems = new List<QuoteLineItem>();
                List<QuoteLineItem> l3ApprovalItems = new List<QuoteLineItem>();
                
                for (QuoteLineItem qli : quote.QuoteLineItems) {
                    if (qli.Discount > 5 && qli.Discount <= 10) {
                        l2ApprovalItems.add(qli);
                    } else if (qli.Discount > 10) {
                        l3ApprovalItems.add(qli);
                    }
                }
                
                // Update QuoteLineItems with approver information
                List<QuoteLineItem> qlisToUpdate = new List<QuoteLineItem>();
                for (QuoteLineItem qli : quote.QuoteLineItems) {
                    if (qli.Discount > 5 && qli.Discount <= 10 && l2Approver != null) {
                        qli.L2_Discount_Approver__c = l2Approver.Id;
                        qli.Approval_Status__c = 'Pending';
                        qlisToUpdate.add(qli);
                    } else if (qli.Discount > 10 && l3Approver != null) {
                        qli.L3_Discount_Approver__c = l3Approver.Id;
                        qli.Approval_Status__c = 'Pending';
                        qlisToUpdate.add(qli);
                    }
                }
                
                if (!qlisToUpdate.isEmpty()) {
                    update qlisToUpdate;
                    
                    // Update quote status
                    quote.Status = 'Price Approval';
                    update quote;
                    
                    // Send emails based on approval levels
                    sendApprovalEmails(quote, l2ApprovalItems, l3ApprovalItems, l2Approver, l3Approver);
                    
                    // Send in-app notification
                    sendNotificationToUsers(quote, l2Approver, l3Approver);
                }
            }
        } catch(Exception e) {
            System.debug('Error in sendEmailToManagerForQuote: ' + e.getMessage() + 
                         ' StackTrace: ' + e.getStackTraceString());
            throw new AuraHandledException('Failed to send approval request: ' + e.getMessage());
        }
    }
    
    private static void sendApprovalEmails(Quote quote, List<QuoteLineItem> l2ApprovalItems, 
                                         List<QuoteLineItem> l3ApprovalItems, 
                                         User l2Approver, User l3Approver) {
        
        // Send L2 Approval Emails (5-10% discount)
        if (!l2ApprovalItems.isEmpty() && l2Approver != null) {
            sendL2ApprovalEmail(quote, l2ApprovalItems, l2Approver);
        }
        
        // Send L3 Approval Emails (>10% discount)
        if (!l3ApprovalItems.isEmpty() && l3Approver != null) {
            sendL3ApprovalEmail(quote, l3ApprovalItems, l3Approver, l2Approver);
        }
    }
    
    private static void sendL2ApprovalEmail(Quote quote, List<QuoteLineItem> approvalItems, User l2Approver) {
        try {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[]{l2Approver.Email});
            email.setCCAddresses(new String[]{'sahil@finessedirect.com', quote.Owner.Email});
            email.setWhatId(quote.Id);
            email.setSubject('L2 Discount Approval Required - ' + quote.Name);
            
            String emailBody = buildEmailBody(quote, approvalItems, 'L2', l2Approver, null);
            email.setHtmlBody(emailBody);
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
            System.debug('L2 Approval email sent for Quote: ' + quote.Id);
        } catch(Exception e) {
            System.debug('Error sending L2 approval email: ' + e.getMessage());
        }
    }
    
    private static void sendL3ApprovalEmail(Quote quote, List<QuoteLineItem> approvalItems, 
                                          User l3Approver, User l2Approver) {
        try {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[]{l3Approver.Email});
            
            // Add L2 approver to CC and include standard CCs
            Set<String> ccAddresses = new Set<String>{
                'sahil@finessedirect.com', 
                quote.Owner.Email
            };
            if (l2Approver != null && l2Approver.Email != null) {
                ccAddresses.add(l2Approver.Email);
            }
            
            email.setCCAddresses(new List<String>(ccAddresses));
            email.setWhatId(quote.Id);
            email.setSubject('L3 Discount Approval Required - ' + quote.Name);
            
            String emailBody = buildEmailBody(quote, approvalItems, 'L3', null, l3Approver);
            email.setHtmlBody(emailBody);
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
            System.debug('L3 Approval email sent for Quote: ' + quote.Id);
        } catch(Exception e) {
            System.debug('Error sending L3 approval email: ' + e.getMessage());
        }
    }
    
    private static String buildEmailBody(Quote quote, List<QuoteLineItem> approvalItems, 
                                       String approvalLevel, User l2Approver, User l3Approver) {
        String approverName = approvalLevel == 'L2' ? 
            l2Approver.Name : l3Approver.Name;
        String greeting = 'Dear ' + approverName + ',';
        String discountRange = approvalLevel == 'L2' ? '5-10%' : 'above 10%';
        
        String body = greeting + '<br/><br/>';
        body += 'Please note that a quote has been identified where the discount exceeds ' + discountRange + ':<br/><br/>';
        body += 'Please provide your approval to proceed with the discount.<br/><br/>';
        body += '<strong>Quote:</strong> ' + quote.Name + '<br/>';
        body += '<strong>Opportunity:</strong> ' + (quote.Opportunity != null ? quote.Opportunity.Name : 'N/A') + '<br/>';
        body += '<strong>Quote Owner:</strong> ' + quote.Owner.Name + ' (' + quote.Opportunity.Owner.User_Type__c + ')<br/>';
        body += '<strong>Link:</strong> ' + quote.Link__c + '<br/><br/>';
        
        body += '<table border="1" cellpadding="5" style="border-collapse:collapse;width:100%">';
        body += '<tr style="background-color:#f2f2f2">';
        body += '<th>Product</th><th>List Price</th><th>Sales Price</th><th>Discount %</th><th>Approval Level</th>';
        body += '</tr>';
        
        for (QuoteLineItem qli : approvalItems) {
            body += '<tr>';
            body += '<td>' + qli.Product2.Name + '</td>';
            body += '<td>' + qli.ListPrice.setScale(2) + '</td>';
            body += '<td>' + qli.UnitPrice.setScale(2) + '</td>';
            body += '<td>' + qli.Discount.setScale(2) + '%</td>';
            body += '<td>' + (qli.Discount > 10 ? 'L3' : 'L2') + '</td>';
            body += '</tr>';
        }
        
        body += '</table><br/>';
        body += 'Please review and approve at your earliest convenience using the Discount Approval Dashboard.<br/><br/>';
        body += 'Regards,<br/>' + quote.Owner.Name;
        
        return body;
    }
    
    private static void sendNotificationToUsers(Quote quote, User l2Approver, User l3Approver) {
        try {
            List<CustomNotificationType> notificationTypes = [
                SELECT Id FROM CustomNotificationType 
                WHERE DeveloperName = 'Notification_to_Owner' LIMIT 1
            ];
            
            if (notificationTypes.isEmpty()) return;
            
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle('Discount Approval Required');
            notification.setBody('Discount approval required for Quote: ' + quote.Name);
            notification.setTargetId(quote.Id);
            notification.setNotificationTypeId(notificationTypes[0].Id);
            
            Set<String> recipientIds = new Set<String>{quote.OwnerId};
            if (l2Approver != null) recipientIds.add(l2Approver.Id);
            if (l3Approver != null) recipientIds.add(l3Approver.Id);
            
            notification.send(recipientIds);
            System.debug('Discount approval notification sent successfully.');
        } catch (Exception e) {
            System.debug('Error sending custom notification: ' + e.getMessage());
        }
    }
}