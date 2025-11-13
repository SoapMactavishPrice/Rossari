public class ExpenseApprovalEmailHandler {
    
    public static void sendSubmissionEmail(Expense__c exp, String comments) {
        List<Expense_Line_Item__c> lineItems = [
            SELECT Id, Name, Type_of_Expense__r.Name, Amount_Claimed__c, Amount_Passed__c
            FROM Expense_Line_Item__c
            WHERE Expense__c = :exp.Id
        ];
        
        String headerDetails = getExpenseHeaderDetails(exp);
        String lineItemTable = getLineItemTable(lineItems);
        
        // Determine Level 1 approver based on record type
        String level1ApproverName = '';
        String level1ApproverEmail = '';
        String recordType = exp.RecordType.DeveloperName;
        
        if (recordType == 'RBL') {
            level1ApproverName = exp.Zonal_Head__r?.Name;
            level1ApproverEmail = exp.Zonal_Head__r?.Email;
        } else if (recordType == 'Unitop_Tristar') {
            level1ApproverName = exp.Customer_Success_Incharge__r?.Name;
            level1ApproverEmail = exp.Customer_Success_Incharge__r?.Email;
        }
        
        String body = 
            '<p>Dear ' + level1ApproverName + ',</p>' +
            '<p>An expense has been submitted by ' + exp.Owner.Name + '. Please review and take action.</p>' +
            headerDetails + 
            lineItemTable +
            '<p><b>Comments:</b> ' + (String.isNotBlank(comments) ? comments : 'No comments provided.') + '</p>' +
            '<p>Regards,<br/>' + exp.Owner.Name + '</p>';
        
        if (String.isNotBlank(level1ApproverEmail)) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] { level1ApproverEmail });
            email.setCcAddresses(new String[] { exp.Owner.Email });
            email.setWhatId(exp.Id);
            email.setSubject('Expense Submitted for Approval: ' + exp.Name);
            email.setHtmlBody(body);
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        }
    }
    
    // When approval/rejection is done
    public static void sendDecisionEmail(Expense__c exp, String action, String toAddress, String ccAddress, String comments) {
        List<Expense_Line_Item__c> lineItems = [
            SELECT Id, Name, Type_of_Expense__r.Name, Amount_Claimed__c, Amount_Passed__c
            FROM Expense_Line_Item__c
            WHERE Expense__c = :exp.Id
        ];
        
        String headerDetails = getExpenseHeaderDetails(exp);
        String lineItemTable = getLineItemTable(lineItems);
        
        String body = 
            '<p>Dear ' + exp.Owner.Name + ',</p>' +
            '<p>Expense "' + exp.Name + '" has been ' + action.toLowerCase() + ' by ' + UserInfo.getName() + '.</p>' +
            headerDetails +
            lineItemTable +
            '<p><b>Comments:</b> ' + (String.isNotBlank(comments) ? comments : 'No comments provided.') + '</p>' +
            '<p>Regards,<br/>' + UserInfo.getName() + '</p>';
        
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[] { toAddress });
        if (String.isNotBlank(ccAddress)) {
            email.setCcAddresses(new String[] { ccAddress });
        }
        email.setWhatId(exp.Id);
        email.setSubject('Expense ' + exp.Name + ' has been ' + action);
        email.setHtmlBody(body);
        
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }
    
    // Escalation to HOD after Level 1 approver approves
    public static void sendEscalationToHOD(Expense__c exp) {
        if (String.isNotBlank(exp.Business_HOD__r?.Email)) {
            List<Expense_Line_Item__c> lineItems = [
                SELECT Id, Name, Type_of_Expense__r.Name, Amount_Claimed__c, Amount_Passed__c
                FROM Expense_Line_Item__c
                WHERE Expense__c = :exp.Id
            ];
            
            String headerDetails = getExpenseHeaderDetails(exp);
            String lineItemTable = getLineItemTable(lineItems);
            
            // Determine who approved at Level 1 based on record type
            String level1ApproverName = '';
            String level1ApproverEmail = '';
            String recordType = exp.RecordType.DeveloperName;
            
            if (recordType == 'RBL') {
                level1ApproverName = exp.Zonal_Head__r?.Name;
                level1ApproverEmail = exp.Zonal_Head__r?.Email;
            } else if (recordType == 'Unitop_Tristar') {
                level1ApproverName = exp.Customer_Success_Incharge__r?.Name;
                level1ApproverEmail = exp.Customer_Success_Incharge__r?.Email;
            }
            
            String body = 
                '<p>Dear ' + exp.Business_HOD__r.Name + ',</p>' +
                '<p>The ' + getLevel1ApproverTitle(recordType) + ' has approved the expense "' + exp.Name + '". It is now pending for your approval.</p>' +
                headerDetails +
                lineItemTable +
                '<p><b>Comments:</b> No comments provided.</p>' +
                '<p>Regards,<br/>' + level1ApproverName + '</p>';
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] { exp.Business_HOD__r.Email });
            
            // CC the Level 1 approver and expense owner
            List<String> ccAddresses = new List<String> { exp.Owner.Email };
            if (String.isNotBlank(level1ApproverEmail)) {
                ccAddresses.add(level1ApproverEmail);
            }
            email.setCcAddresses(ccAddresses);
            
            email.setWhatId(exp.Id);
            email.setSubject('Expense Awaiting For Your Approval: ' + exp.Name);
            email.setHtmlBody(body);
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        }
    }
    
    // New method to send escalation email from Customer Success Incharge to Business HOD
    public static void sendEscalationFromCSIToHOD(Expense__c exp) {
        if (String.isNotBlank(exp.Business_HOD__r?.Email) && String.isNotBlank(exp.Customer_Success_Incharge__r?.Email)) {
            List<Expense_Line_Item__c> lineItems = [
                SELECT Id, Name, Type_of_Expense__r.Name, Amount_Claimed__c, Amount_Passed__c
                FROM Expense_Line_Item__c
                WHERE Expense__c = :exp.Id
            ];
            
            String headerDetails = getExpenseHeaderDetails(exp);
            String lineItemTable = getLineItemTable(lineItems);
            
            String body = 
                '<p>Dear ' + exp.Business_HOD__r.Name + ',</p>' +
                '<p>The Customer Success Incharge has approved the expense "' + exp.Name + '". It is now pending for your approval.</p>' +
                headerDetails +
                lineItemTable +
                '<p><b>Comments:</b> No comments provided.</p>' +
                '<p>Regards,<br/>' + exp.Customer_Success_Incharge__r.Name + '</p>';
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] { exp.Business_HOD__r.Email });
            email.setCcAddresses(new String[] { exp.Owner.Email, exp.Customer_Success_Incharge__r.Email });
            email.setWhatId(exp.Id);
            email.setSubject('Expense Awaiting For Your Approval: ' + exp.Name);
            email.setHtmlBody(body);
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        }
    }
    
    // Helper method to get Level 1 approver title based on record type
    private static String getLevel1ApproverTitle(String recordType) {
        if (recordType == 'RBL') {
            return 'Zonal Head';
        } else if (recordType == 'Unitop_Tristar') {
            return 'Customer Success Incharge';
        }
        return 'Approver';
    }
    
    // Helper method to get expense header details
    private static String getExpenseHeaderDetails(Expense__c exp) {
        return 
            '<p><b>Expense Details:</b></p>' +
            '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse:collapse;">' +
            '<tr><th>Expense Name</th><th>Date</th><th>Type of Voucher</th><th>Tour</th>' +
            '<th>Employee</th><th>Division</th><th>Zone</th><th>Record Type</th></tr>' +
            '<tr>' +
            '<td>' + exp.Name + '</td>' +
            '<td>' + (exp.Date__c != null ? String.valueOf(exp.Date__c) : '') + '</td>' +
            '<td>' + (exp.Type_of_Voucher__c != null ? exp.Type_of_Voucher__c : '') + '</td>' +
            '<td>' + (exp.Tour__r != null ? exp.Tour__r.Name : '') + '</td>' +
            '<td>' + (exp.Employee_Name__r != null ? exp.Employee_Name__r.Name : '') + '</td>' +
            '<td>' + (exp.Division__c != null ? exp.Division__c : '') + '</td>' +
            '<td>' + (exp.Zone__c != null ? exp.Zone__c : '') + '</td>' +
            '<td>' + (exp.RecordType?.DeveloperName != null ? exp.RecordType.DeveloperName : '') + '</td>' +
            '</tr>' +
            '</table>';
    }
    
    // Helper method to get line item table
    private static String getLineItemTable(List<Expense_Line_Item__c> lineItems) {
        String lineItemTable = '<p><b>Expense Line Items:</b></p>' +
            '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse:collapse;">' +
            '<tr><th>Name</th><th>Type of Expense</th><th>Amount Claimed</th></tr>';
        
        for (Expense_Line_Item__c li : lineItems) {
            lineItemTable += '<tr>' +
                '<td>' + li.Name + '</td>' +
                '<td>' + (li.Type_of_Expense__r != null ? li.Type_of_Expense__r.Name : '') + '</td>' +
                '<td>' + (li.Amount_Claimed__c != null ? String.valueOf(li.Amount_Claimed__c) : '') + '</td>' +
                '<td>' + (li.Amount_Passed__c != null ? String.valueOf(li.Amount_Passed__c) : '') + '</td>' +
                '</tr>';
        }
        lineItemTable += '</table>';
        return lineItemTable;
    }
    
    // New method to send notification to Customer Success Incharge
    public static void sendSubmissionToCSI(Expense__c exp, String comments) {
        List<Expense_Line_Item__c> lineItems = [
            SELECT Id, Name, Type_of_Expense__r.Name, Amount_Claimed__c, Amount_Passed__c
            FROM Expense_Line_Item__c
            WHERE Expense__c = :exp.Id
        ];
        
        String headerDetails = getExpenseHeaderDetails(exp);
        String lineItemTable = getLineItemTable(lineItems);
        
        String body = 
            '<p>Dear ' + exp.Customer_Success_Incharge__r.Name + ',</p>' +
            '<p>An expense has been submitted by ' + exp.Owner.Name + '. Please review and take action.</p>' +
            headerDetails + 
            lineItemTable +
            '<p><b>Comments:</b> ' + (String.isNotBlank(comments) ? comments : 'No comments provided.') + '</p>' +
            '<p>Regards,<br/>' + exp.Owner.Name + '</p>';
        
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[] { exp.Customer_Success_Incharge__r.Email });
        email.setCcAddresses(new String[] { exp.Owner.Email });
        email.setWhatId(exp.Id);
        email.setSubject('Expense Submitted for Approval: ' + exp.Name);
        email.setHtmlBody(body);
        
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }
}