public class QuoteTriggerHandler {
    public static void sendPaymentTermChangeEmails(List<Quote> quotes) {
        Set<Id> accountIds = new Set<Id>();
        Set<Id> userIds = new Set<Id>();
        Set<Id> ownerIds = new Set<Id>();
        Set<Id> paymentTermIds = new Set<Id>();
        
        for (Quote q : quotes) {
            if (q.AccountId != null) accountIds.add(q.AccountId);
            if (q.HOD_of_Sales_Department__c != null) userIds.add(q.HOD_of_Sales_Department__c);
            if (q.OwnerId != null) ownerIds.add(q.OwnerId);
            if (q.Payment_Term__c != null) paymentTermIds.add(q.Payment_Term__c);
            if (q.Previous_Payment_Terms__c != null) paymentTermIds.add(q.Previous_Payment_Terms__c);
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
        
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        for (Quote q : quotes) {
            Account acc = accountMap.get(q.AccountId);
            User hod = userMap.get(q.HOD_of_Sales_Department__c);
            User owner = ownerMap.get(q.OwnerId);
            String previousTerm = q.Previous_Payment_Terms__c != null ? paymentTermMap.get(q.Previous_Payment_Terms__c).Name : '';
            String newTerm = q.Payment_Term__c != null ? paymentTermMap.get(q.Payment_Term__c).Name : '';
            
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
                '<tr><th style="text-align: left;">Credit Limit</th><td>' + 'N/A' + '</td></tr>' + // Replace if actual field exists
                '<tr><th style="text-align: left;">Previous Payment Term</th><td>' + previousTerm + '</td></tr>' +
                '<tr><th style="text-align: left;">New Payment Term</th><td>' + newTerm + '</td></tr>' +
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
            if (owner != null) {
                mail.setCcAddresses(new String[] { owner.Email });
            }
            mail.setSubject('Quote Payment Term Updated: ' + q.Name);
            mail.setHtmlBody(emailBody);
            
            emails.add(mail);
        }
        
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }
}