public class ExpenseEmailTemplateBuilder {

    public static String buildExpenseHtmlBody(Expense__c exp, String greetingName, String message, String comments, String closingName) {
        List<Expense_Line_Item__c> lineItems = [
            SELECT Id, Name, Type_of_Expense__r.Name, Amount_Claimed__c
            FROM Expense_Line_Item__c
            WHERE Expense__c = :exp.Id
        ];

        String headerDetails = 
            '<p><b>Expense Details:</b></p>' +
            '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse:collapse;">' +
            '<tr><th>Expense Name</th><th>Date</th><th>Type of Voucher</th><th>Tour</th>' +
            '<th>Employee</th><th>Division</th><th>Zone</th></tr>' +
            '<tr>' +
                '<td>' + exp.Name + '</td>' +
                '<td>' + (exp.Date__c != null ? String.valueOf(exp.Date__c) : '') + '</td>' +
                '<td>' + (exp.Type_of_Voucher__c != null ? exp.Type_of_Voucher__c : '') + '</td>' +
                '<td>' + (exp.Tour__r != null ? exp.Tour__r.Name : '') + '</td>' +
                '<td>' + (exp.Employee_Name__r != null ? exp.Employee_Name__r.Name : '') + '</td>' +
                '<td>' + (exp.Division__c != null ? exp.Division__c : '') + '</td>' +
                '<td>' + (exp.Zone__c != null ? exp.Zone__c : '') + '</td>' +
            '</tr>' +
            '</table>';

        String lineItemTable = '<p><b>Expense Line Items:</b></p>' +
            '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse:collapse;">' +
            '<tr><th>Name</th><th>Type of Expense</th><th>Amount Claimed</th></tr>';

        for (Expense_Line_Item__c li : lineItems) {
            lineItemTable += '<tr>' +
                '<td>' + li.Name + '</td>' +
                '<td>' + (li.Type_of_Expense__r != null ? li.Type_of_Expense__r.Name : '') + '</td>' +
                '<td>' + (li.Amount_Claimed__c != null ? String.valueOf(li.Amount_Claimed__c) : '') + '</td>' +
            '</tr>';
        }
        lineItemTable += '</table>';

        String body = 
            '<p>Dear ' + greetingName + ',</p>' +
            '<p>' + message + '</p>' +
            headerDetails +
            lineItemTable +
            '<p><b>Comments:</b> ' + (String.isNotBlank(comments) ? comments : 'No comments provided.') + '</p>' +
            '<p>Regards,<br/>' + closingName + '</p>';

        return body;
    }
}