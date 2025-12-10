public class CaseTriggerHandler {
    
    // Send Sample IN email after Sample_IN_Sent__c = true
    public static void sendSampleEmail(List<Case> newCases, Map<Id, Case> oldCaseMap) {
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();

        for (Case c : newCases) {
            Case oldCase = oldCaseMap.get(c.Id);

            Boolean isSampleSentNow = c.Sample_IN_Sent__c == true && oldCase.Sample_IN_Sent__c != true;
            Boolean isUserSelected = c.RND_User__c != null;

            if (isSampleSentNow && isUserSelected) {
                User rndUser = [SELECT Id, Email, Name FROM User WHERE Id = :c.RND_User__c LIMIT 1];

                String emailBody = 'Hi ' + rndUser.Name + ',\n\n'
                    + 'The Sample IN for Case ' + c.CaseNumber + ' has been received.\n\n'
                    + 'Below are the Details:-\n\n'
                    + 'Nature of Complaint: ' + c.Nature_of_Complaint__c + '\n'
                    + 'Rejection (%): ' + String.valueOf(c.Rejection__c) + '\n'
                    + 'Subject: ' + c.Subject + '\n'
                    + 'Description: ' + c.Description + '\n\n'
                    + 'Regards,\nSalesforce Automation';

                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[] { rndUser.Email });
                mail.setSubject('Sample In Sent - Case Number: ' + c.CaseNumber);
                mail.setWhatId(c.Id);
                mail.setPlainTextBody(emailBody);
                emailsToSend.add(mail);
            }
        }

        if (!emailsToSend.isEmpty()) {
            Messaging.sendEmail(emailsToSend);
        }
    }

    // Set CAPA Date before insert/update
    public static void setCAPADate(List<Case> newCases, Map<Id, Case> oldCaseMap) {
        for (Case c : newCases) {
            if (c.Nature_of_Complaint__c == 'Quality') {
                if (Trigger.isInsert) {
                    c.CAPA_Date__c = System.today();
                }
                if (Trigger.isUpdate) {
                    Case oldC = oldCaseMap.get(c.Id);
                    if (oldC.Nature_of_Complaint__c != 'Quality') {
                        c.CAPA_Date__c = System.today();
                    }
                }
            }
        }
    }

    public static void sendCAPAEmail(List<Case> newCases) {
    List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();

    Set<Id> userIds = new Set<Id>();
    Set<Id> accountIds = new Set<Id>();
    Set<Id> invoiceLineIds = new Set<Id>();

    for (Case c : newCases) {
        if (c.Nature_of_Complaint__c == 'Quality' && c.RND_User__c != null) {
            userIds.add(c.RND_User__c);
            if (c.AccountId != null) accountIds.add(c.AccountId);
            if (c.Product__c != null) invoiceLineIds.add(c.Product__c);
        }
    }

    if (userIds.isEmpty()) return;

    Map<Id, User> usersMap = new Map<Id, User>([SELECT Id, Name, Email FROM User WHERE Id IN :userIds]);
    Map<Id, Account> accountsMap = new Map<Id, Account>([SELECT Id, Name FROM Account WHERE Id IN :accountIds]);
    Map<Id, Invoice_Line_Item__c> invoiceMap = new Map<Id, Invoice_Line_Item__c>(
        [SELECT Id, Name, Product__r.Name FROM Invoice_Line_Item__c WHERE Id IN :invoiceLineIds]
    );

    for (Case c : newCases) {
        if (c.Nature_of_Complaint__c == 'Quality' && c.RND_User__c != null) {
            User rndUser = usersMap.get(c.RND_User__c);
            String accountName = c.AccountId != null ? accountsMap.get(c.AccountId).Name : 'Not Available';

            String productName = 'Not Available';
            if (c.Product__c != null && invoiceMap.containsKey(c.Product__c)) {
                Invoice_Line_Item__c inv = invoiceMap.get(c.Product__c);
                productName = inv.Product__r != null ? inv.Product__r.Name : 'Not Available';
            }

            String emailBody = 'Hi ' + rndUser.Name + ',\n\n' +
                'A case has been created for this Account with the following Product details.\n' +
                'Please complete the CAPA details related to this case.\n\n' +
                'Batch Number: ' + c.Batch_Number__c + '\n' +
                'Account: ' + accountName + '\n' +
                'Product: ' + productName + '\n' +
                'Quantity: ' + c.Quantity__c + '\n\n' +
                'Regards,\nSalesforce Automation';

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { rndUser.Email });
            mail.setSubject('New CAPA Case Created - Case Number: ' + c.CaseNumber);
            mail.setWhatId(c.Id);
            mail.setPlainTextBody(emailBody);
            emailsToSend.add(mail);
        }
    }

    if (!emailsToSend.isEmpty()) {
        Messaging.sendEmail(emailsToSend);
    }
}

}