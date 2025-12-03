public class QuoteTriggerHandler {
    
    // Existing method for term change notifications
    public static void sendPaymentTermChangeEmails(List<Quote> quotes) {
        // Your existing implementation for term change notifications
        Set<Id> accountIds = new Set<Id>();
        Set<Id> userIds = new Set<Id>();
        Set<Id> ownerIds = new Set<Id>();
        Set<Id> paymentTermIds = new Set<Id>();
        Set<Id> opportunityIds = new Set<Id>();
        Set<Id> distributionChannelIds = new Set<Id>();
        
        for (Quote q : quotes) {
            if (q.AccountId != null) accountIds.add(q.AccountId);
            if (q.HOD_of_Sales_Department__c != null) userIds.add(q.HOD_of_Sales_Department__c);
            if (q.OwnerId != null) ownerIds.add(q.OwnerId);
            if (q.Payment_Term__c != null) paymentTermIds.add(q.Payment_Term__c);
            if (q.Previous_Payment_Terms__c != null) paymentTermIds.add(q.Previous_Payment_Terms__c);
            if (q.OpportunityId != null) opportunityIds.add(q.OpportunityId);
            if (q.Distribution_Channel__c != null) distributionChannelIds.add(q.Distribution_Channel__c);
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
        
        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>([
            SELECT Id, Payment_Term__c, Inco_Terms__c, Payment_Term__r.Name
            FROM Opportunity 
            WHERE Id IN :opportunityIds
        ]);
        
        Map<Id, Distribution_Channel__c> distributionChannelMap = new Map<Id, Distribution_Channel__c>([
            SELECT Id, Distribution_Code__c, Name 
            FROM Distribution_Channel__c 
            WHERE Id IN :distributionChannelIds
        ]);
        
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        for (Quote q : quotes) {
            Account acc = accountMap.get(q.AccountId);
            User hod = userMap.get(q.HOD_of_Sales_Department__c);
            User owner = ownerMap.get(q.OwnerId);
            
            String previousPaymentTerm = '';
            String newPaymentTerm = '';
            String previousIncoTerm = '';
            String newIncoTerm = '';
            
            if (q.Previous_Payment_Terms__c != null) {
                previousPaymentTerm = paymentTermMap.get(q.Previous_Payment_Terms__c)?.Name;
            } else if (q.OpportunityId != null) {
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
                Opportunity opp = opportunityMap.get(q.OpportunityId);
                if (opp != null && opp.Inco_Terms__c != null) {
                    previousIncoTerm = opp.Inco_Terms__c;
                }
            }
            
            newIncoTerm = q.Inco_Terms__c != null ? q.Inco_Terms__c : '';
            
            String approvalStatus = q.Credit_Approval_Status__c != null ? q.Credit_Approval_Status__c : 'Pending';
            
            String emailBody = 
                'Hello ' + (hod != null && hod.Name != null ? hod.Name : '') + ',<br/><br/>' +
                '<p>Payment Term has been updated for Quote: <b>' + q.Name + '</b></p>' +
                '<p><b>Status:</b> The updated payment term has been <span style="color:' + 
                (approvalStatus == 'Approved' ? 'green' : 'red') + ';">' + approvalStatus + '</span>.</p>' +
                '<table border="1" style="border-collapse: collapse; width: 100%;">' +
                '<tr><th style="text-align: left;">SO No</th><td>' + (q.QuoteNumber != null ? q.QuoteNumber : '') + '</td></tr>' +
                '<tr><th style="text-align: left;">Customer Code</th><td>' + (acc != null && acc.SAP_Customer_Code__c != null ? acc.SAP_Customer_Code__c : '') + '</td></tr>' +
                '<tr><th style="text-align: left;">Customer Name</th><td>' + (acc != null ? acc.Name : '') + '</td></tr>' +
                '<tr><th style="text-align: left;">Credit Limit</th><td>' + 'N/A' + '</td></tr>' +
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
            
            List<String> ccAddresses = new List<String>();
            
            if (owner != null && owner.Email != null) {
                ccAddresses.add(owner.Email);
            }
            
            if (q.Distribution_Channel__c != null) {
                Distribution_Channel__c dc = distributionChannelMap.get(q.Distribution_Channel__c);
                if (dc != null) {
                    if (dc.Distribution_Code__c == '10') {
                        ccAddresses.add('ankit@finessedirect.com');
                    } else if (dc.Distribution_Code__c == '20') {
                        ccAddresses.add('sahil@finessedirect.com');
                    }
                }
            }
            
            // Set CC addresses if any
            if (!ccAddresses.isEmpty()) {
                mail.setCcAddresses(ccAddresses);
            }
            
            mail.setWhatId(q.Id);
            
            String subject = 'Quote Terms Updated: ' + q.Name;
            if (q.Payment_Term__c != q.Previous_Payment_Terms__c && q.Inco_Terms__c != q.Previous_Inco_Terms__c) {
                subject = 'Quote Payment/Inco Terms Updated: ' + q.Name;
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
    
    // New method for Payment Terms approval/rejection notifications
    public static void sendPaymentTermsApprovalEmails(List<Quote> quotes, Map<Id, Quote> oldMap) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        // Get distribution channel information
        Set<Id> distributionChannelIds = new Set<Id>();
        for (Quote newQuote : quotes) {
            distributionChannelIds.add(newQuote.Distribution_Channel__c);
        }
        
        Map<Id, Distribution_Channel__c> distributionChannelMap = new Map<Id, Distribution_Channel__c>([
            SELECT Id, Distribution_Code__c, Name 
            FROM Distribution_Channel__c 
            WHERE Id IN :distributionChannelIds
        ]);
        
        for (Quote newQuote : quotes) {
            Quote oldQuote = oldMap.get(newQuote.Id);
            
            // Check if Payment Terms approval status changed to Approved or Rejected
            if (newQuote.Credit_Approval_Status__c != oldQuote.Credit_Approval_Status__c &&
                (newQuote.Credit_Approval_Status__c == 'Approved' || newQuote.Credit_Approval_Status__c == 'Rejected')) {
                    
                    // Get quote details with related records
                    Quote q = [
                        SELECT Id, Name, QuoteNumber, Account.Name, Account.SAP_Customer_Code__c,
                        Payment_Term__r.Name, Previous_Payment_Terms__r.Name,
                        Payment_Remark__c, Credit_Approval_Status__c,
                        Owner.Name, Owner.Email, HOD_of_Sales_Department__r.Name, 
                        HOD_of_Sales_Department__r.Email, Distribution_Channel__c
                        FROM Quote 
                        WHERE Id = :newQuote.Id
                    ];
                    
                    String statusColor = q.Credit_Approval_Status__c == 'Approved' ? 'green' : 'red';
                    String statusText = q.Credit_Approval_Status__c == 'Approved' ? 'Approved' : 'Rejected';
                    
                    String emailBody = 
                        'Hello ' + q.Owner.Name + ',<br/><br/>' +
                        '<p>Your Payment Terms change request for Quote: <b>' + q.Name + '</b> has been <span style="color:' + statusColor + '; font-weight: bold;">' + statusText + '</span>.</p>' +
                        '<table border="1" style="border-collapse: collapse; width: 100%;">' +
                        '<tr><th style="text-align: left; width: 30%;">Quote Number</th><td style="width: 70%;">' + q.QuoteNumber + '</td></tr>' +
                        '<tr><th style="text-align: left;">Customer Name</th><td>' + q.Account.Name + '</td></tr>' +
                        '<tr><th style="text-align: left;">Customer Code</th><td>' + (q.Account.SAP_Customer_Code__c != null ? q.Account.SAP_Customer_Code__c : 'N/A') + '</td></tr>' +
                        '<tr><th style="text-align: left;">Previous Payment Term</th><td>' + q.Previous_Payment_Terms__r.Name + '</td></tr>' +
                        '<tr><th style="text-align: left;">Requested Payment Term</th><td>' + q.Payment_Term__r.Name + '</td></tr>' +
                        '<tr><th style="text-align: left;">Approval Status</th><td><span style="color:' + statusColor + '; font-weight: bold;">' + statusText + '</span></td></tr>' +
                        '<tr><th style="text-align: left;">Remarks</th><td>' + (q.Payment_Remark__c != null ? q.Payment_Remark__c : 'No remarks provided') + '</td></tr>' +
                        '<tr><th style="text-align: left;">Approved By</th><td>' + q.HOD_of_Sales_Department__r.Name + '</td></tr>' +
                        '</table><br/><br/>' +
                        'Regards,<br/>Salesforce Automation';
                    
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setToAddresses(new String[] { q.Owner.Email });
                    
                    // NEW: Add distribution channel specific CC
                    List<String> ccAddresses = new List<String>();
                    if (q.Distribution_Channel__c != null) {
                        Distribution_Channel__c dc = distributionChannelMap.get(q.Distribution_Channel__c);
                        if (dc != null) {
                            if (dc.Distribution_Code__c == '10') {
                                ccAddresses.add('ankit@finessedirect.com');
                            } else if (dc.Distribution_Code__c == '20') {
                                ccAddresses.add('sahil@finessedirect.com');
                            }
                        }
                    }
                    
                    if (!ccAddresses.isEmpty()) {
                        mail.setCcAddresses(ccAddresses);
                    }
                    
                    mail.setSubject('Payment Terms ' + statusText + ' for Quote: ' + q.Name);
                    mail.setHtmlBody(emailBody);
                    mail.setWhatId(q.Id);
                    
                    emails.add(mail);
                }
        }
        
        if (!emails.isEmpty()) {
            try {
                Messaging.sendEmail(emails);
            } catch (Exception e) {
                System.debug('Error sending payment terms approval emails: ' + e.getMessage());
            }
        }
    }
    
    // New method for Inco Terms approval/rejection notifications
    public static void sendIncoTermsApprovalEmails(List<Quote> quotes, Map<Id, Quote> oldMap) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        Set<Id> distributionChannelIds = new Set<Id>();
        for (Quote newQuote : quotes) {
            distributionChannelIds.add(newQuote.Distribution_Channel__c);
        }
        
        Map<Id, Distribution_Channel__c> distributionChannelMap = new Map<Id, Distribution_Channel__c>([
            SELECT Id, Distribution_Code__c, Name 
            FROM Distribution_Channel__c 
            WHERE Id IN :distributionChannelIds
        ]);
        
        for (Quote newQuote : quotes) {
            Quote oldQuote = oldMap.get(newQuote.Id);
            
            // Check if Inco Terms approval status changed to Approved or Rejected
            if (newQuote.Inco_Terms_Approval_Status__c != oldQuote.Inco_Terms_Approval_Status__c &&
                (newQuote.Inco_Terms_Approval_Status__c == 'Approved' || newQuote.Inco_Terms_Approval_Status__c == 'Rejected')) {
                    
                    // Get quote details with related records
                    Quote q = [
                        SELECT Id, Name, QuoteNumber, Account.Name, Account.SAP_Customer_Code__c,
                        Inco_Terms__c, Previous_Inco_Terms__c,
                        Inco_Remark__c, Inco_Terms_Approval_Status__c,
                        Owner.Name, Owner.Email, HOD_of_Sales_Department__r.Name, 
                        HOD_of_Sales_Department__r.Email, Distribution_Channel__c
                        FROM Quote 
                        WHERE Id = :newQuote.Id
                    ];
                    
                    String statusColor = q.Inco_Terms_Approval_Status__c == 'Approved' ? 'green' : 'red';
                    String statusText = q.Inco_Terms_Approval_Status__c == 'Approved' ? 'Approved' : 'Rejected';
                    
                    String emailBody = 
                        'Hello ' + q.Owner.Name + ',<br/><br/>' +
                        '<p>Your Inco Terms change request for Quote: <b>' + q.Name + '</b> has been <span style="color:' + statusColor + '; font-weight: bold;">' + statusText + '</span>.</p>' +
                        '<table border="1" style="border-collapse: collapse; width: 100%;">' +
                        '<tr><th style="text-align: left; width: 30%;">Quote Number</th><td style="width: 70%;">' + q.QuoteNumber + '</td></tr>' +
                        '<tr><th style="text-align: left;">Customer Name</th><td>' + q.Account.Name + '</td></tr>' +
                        '<tr><th style="text-align: left;">Customer Code</th><td>' + (q.Account.SAP_Customer_Code__c != null ? q.Account.SAP_Customer_Code__c : 'N/A') + '</td></tr>' +
                        '<tr><th style="text-align: left;">Previous Inco Term</th><td>' + q.Previous_Inco_Terms__c + '</td></tr>' +
                        '<tr><th style="text-align: left;">Requested Inco Term</th><td>' + q.Inco_Terms__c + '</td></tr>' +
                        '<tr><th style="text-align: left;">Approval Status</th><td><span style="color:' + statusColor + '; font-weight: bold;">' + statusText + '</span></td></tr>' +
                        '<tr><th style="text-align: left;">Remarks</th><td>' + (q.Inco_Remark__c != null ? q.Inco_Remark__c : 'No remarks provided') + '</td></tr>' +
                        '<tr><th style="text-align: left;">Approved By</th><td>' + q.HOD_of_Sales_Department__r.Name + '</td></tr>' +
                        '</table><br/><br/>' +
                        'Regards,<br/>Salesforce Automation';
                    
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setToAddresses(new String[] { q.Owner.Email });
                    
                    List<String> ccAddresses = new List<String>();
                    if (q.Distribution_Channel__c != null) {
                        Distribution_Channel__c dc = distributionChannelMap.get(q.Distribution_Channel__c);
                        if (dc != null) {
                            if (dc.Distribution_Code__c == '10') {
                                ccAddresses.add('ankit@finessedirect.com');
                            } else if (dc.Distribution_Code__c == '20') {
                                ccAddresses.add('sahil@finessedirect.com');
                            }
                        }
                    }
                    
                    if (!ccAddresses.isEmpty()) {
                        mail.setCcAddresses(ccAddresses);
                    }
                    
                    mail.setSubject('Inco Terms ' + statusText + ' for Quote: ' + q.Name);
                    mail.setHtmlBody(emailBody);
                    mail.setWhatId(q.Id);
                    
                    emails.add(mail);
                }
        }
        
        if (!emails.isEmpty()) {
            try {
                Messaging.sendEmail(emails);
            } catch (Exception e) {
                System.debug('Error sending inco terms approval emails: ' + e.getMessage());
            }
        }
    }
}