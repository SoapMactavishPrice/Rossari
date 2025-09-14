public class CaseTriggerHandler {
    
    public static void sendSampleEmail(List<Case> newCases, Map<Id, Case> oldCaseMap) {
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();

        for (Case c : newCases) {
            Case oldCase = oldCaseMap.get(c.Id);

            Boolean isSampleSentNow = c.Sample_IN_Sent__c == true && oldCase.Sample_IN_Sent__c != true;
            Boolean isUserSelected = c.RND_User__c != null;

            if (isSampleSentNow && isUserSelected) {
                User rndUser = [SELECT Id, Email, Name FROM User WHERE Id = :c.RND_User__c LIMIT 1];

                String emailBody = 'Hello ' + rndUser.Name + ',\n\n'
                    + 'The Sample IN for Case ' + c.CaseNumber + ' has been received.\n\n'
                    + 'Below are the Details:-\n\n'
                    
                    + 'Nature of Complaint: ' + c.Nature_of_Complaint__c + '\n'
                    + 'Rejection (%): ' + String.valueOf(c.Rejection__c) + '\n\n'
                    + 'Subject: ' + c.Subject + '\n'
                    + 'Description: ' + c.Description + '\n'
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
}