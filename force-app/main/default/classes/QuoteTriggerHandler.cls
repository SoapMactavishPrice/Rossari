public class QuoteTriggerHandler {
    public static void sendPaymentTermChangeEmails(List<Quote> quotes) {
        Set<Id> accountIds = new Set<Id>();
        Set<Id> userIds = new Set<Id>();
        Set<Id> ownerIds = new Set<Id>();
        Set<Id> paymentTermIds = new Set<Id>();
        Set<Id> opportunityIds = new Set<Id>();
        
        for (Quote q : quotes) {
            if (q.AccountId != null) accountIds.add(q.AccountId);
            if (q.HOD_of_Sales_Department__c != null) userIds.add(q.HOD_of_Sales_Department__c);
            if (q.OwnerId != null) ownerIds.add(q.OwnerId);
            if (q.Payment_Term__c != null) paymentTermIds.add(q.Payment_Term__c);
            if (q.Previous_Payment_Terms__c != null) paymentTermIds.add(q.Previous_Payment_Terms__c);
            if (q.OpportunityId != null) opportunityIds.add(q.OpportunityId);
        }
        
        Map<Id, Account> accountMap = new Map<Id, Account>([
            SELECT Id, Name, SAP_Customer_Code__c FROM Account WHERE Id IN :accountIds
        ]);
        
        Map<Id, User> userMap = new Map<Id, User>([
            SELECT Id, Name, Email FROM User WHERE Id IN :userIds
        ]);
        
        Map<Id, User> ownerMap = new Map<Id, User>([
            SELECT Id, Name, Email FROM User WHERE Id IN :ownerIds
        ]);
        
        Map<Id, Payment_Term__c> paymentTermMap = new Map<Id, Payment_Term__c>([
            SELECT Id, Name FROM Payment_Term__c WHERE Id IN :paymentTermIds
        ]);
        
        // Get opportunity details for new quotes to determine original terms
        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>([
            SELECT Id, Payment_Term__c, Inco_Terms__c, Payment_Term__r.Name
            FROM Opportunity 
            WHERE Id IN :opportunityIds
        ]);
        
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        for (Quote q : quotes) {
            Account acc = accountMap.get(q.AccountId);
            User hod = userMap.get(q.HOD_of_Sales_Department__c);
            User owner = ownerMap.get(q.OwnerId);
            
            // Determine previous and new terms
            String previousPaymentTerm = '';
            String newPaymentTerm = '';
            String previousIncoTerm = '';
            String newIncoTerm = '';
            
            if (q.Previous_Payment_Terms__c != null) {
                previousPaymentTerm = paymentTermMap.get(q.Previous_Payment_Terms__c)?.Name;
            } else if (q.OpportunityId != null) {
                // For new quotes, get from opportunity
                Opportunity opp = opportunityMap.get(q.OpportunityId);
                if (opp != null && opp.Payment_Term__c != null) {
                    previousPaymentTerm = opp.Payment_Term__r.Name;
                }
            }
            
            if (q.Payment_Term__c != null) {
                newPaymentTerm = paymentTermMap.get(q.Payment_Term__c)?.Name;
            }
            
            if (q.Previous_Inco_Terms__c != null) {
                previousIncoTerm = q.Previous_Inco_Terms__c;
            } else if (q.OpportunityId != null) {
                // For new quotes, get from opportunity
                Opportunity opp = opportunityMap.get(q.OpportunityId);
                if (opp != null && opp.Inco_Terms__c != null) {
                    previousIncoTerm = opp.Inco_Terms__c;
                }
            }
            
            newIncoTerm = q.Inco_Terms__c != null ? q.Inco_Terms__c : '';
            
            String approvalStatus = q.Credit_Approval_Status__c != null ? q.Credit_Approval_Status__c : 'Pending';
            
            // Build email body with both Payment Terms and Inco Terms
            String emailBody = 
                'Hello ' + (hod != null && hod.Name != null ? hod.Name : '') + ',<br/><br/>' +
                '<p>Payment Term has been updated for Quote: <b>' + q.Name + '</b></p>' +
                '<p><b>Status:</b> The updated payment term has been <span style="color:' + 
                (approvalStatus == 'Approved' ? 'green' : 'red') + ';">' + approvalStatus + '</span>.</p>' +
                '<table border="1" style="border-collapse: collapse; width: 100%;">' +
                '<tr><th style="text-align: left;">SO No</th><td>' + (q.QuoteNumber != null ? q.QuoteNumber : '') + '</td></tr>' +
                '<tr><th style="text-align: left;">Customer Code</th><td>' + (acc != null && acc.SAP_Customer_Code__c != null ? acc.SAP_Customer_Code__c : '') + '</td></tr>' +
                '<tr><th style="text-align: left;">Customer Name</th><td>' + (acc != null ? acc.Name : '') + '</td></tr>' +
                '<tr><th style="text-align: left;">Credit Limit</th><td>' + 'N/A' + '</td></tr>' + // Replace if actual field exists
                '<tr><th style="text-align: left;">Previous Payment Term</th><td>' + previousPaymentTerm + '</td></tr>' +
                '<tr><th style="text-align: left;">New Payment Term</th><td>' + newPaymentTerm + '</td></tr>' +
				'<tr><th style="text-align: left;">Previous Inco Term</th><td>' + previousIncoTerm + '</td></tr>' +
                '<tr><th style="text-align: left;">New Inco Term</th><td>' + newIncoTerm + '</td></tr>' +
                '<tr><th style="text-align: left;">Total OD</th><td>' + 'N/A' + '</td></tr>' +
                '<tr><th style="text-align: left;">OD by Days</th><td>' + 'N/A' + '</td></tr>' +
                '<tr><th style="text-align: left;">Total OS</th><td>' + 'N/A' + '</td></tr>' +
                '<tr><th style="text-align: left;">Payment Remarks</th><td>' + (q.Payment_Remark__c != null ? q.Payment_Remark__c : '') + '</td></tr>' +
                '<tr><th style="text-align: left;">Monthly Sales</th><td>' + 'N/A' + '</td></tr>' +
                '<tr><th style="text-align: left;">Approved Order in System</th><td>' + 'N/A' + '</td></tr>' +
                '<tr><th style="text-align: left;">SO Values</th><td>' + 'N/A' + '</td></tr>' +
                '<tr><th style="text-align: left;">Avg Sales</th><td>' + 'N/A' + '</td></tr>' +
                '</table><br/><br/>' +
                'Regards,<br/>Salesforce Automation';
            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            if (hod != null && hod.Email != null) {
                mail.setToAddresses(new String[] { hod.Email });
            }
            
            mail.setWhatId(q.Id);
            if (owner != null && owner.Email != null) {
                mail.setCcAddresses(new String[] { owner.Email });
            }
            
            // Update subject to include both term types
            String subject = 'Quote Terms Updated: ' + q.Name;
            if (q.Payment_Term__c != q.Previous_Payment_Terms__c && q.Inco_Terms__c != q.Previous_Inco_Terms__c) {
                subject = 'Quote Payment & Inco Terms Updated: ' + q.Name;
            } else if (q.Payment_Term__c != q.Previous_Payment_Terms__c) {
                subject = 'Quote Payment Term Updated: ' + q.Name;
            } else if (q.Inco_Terms__c != q.Previous_Inco_Terms__c) {
                subject = 'Quote Inco Term Updated: ' + q.Name;
            }
            
            mail.setSubject(subject);
            mail.setHtmlBody(emailBody);
            
            emails.add(mail);
        }
        
        if (!emails.isEmpty()) {
            try {
                Messaging.sendEmail(emails);
            } catch (Exception e) {
                System.debug('Error sending email: ' + e.getMessage());
            }
        }
    }
}