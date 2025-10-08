public class CustomerOnboardingFormController {
    
    // @auraEnabled
    // public static Account getCustomerDetail(string Id){
    //     //Search_term__c,Name_2__c,Street3__c,language__c
    //     Account acc= [select Id,Name,Cust_Acct_Group__c,Account_Group__c,SE_Name__c,Title__c,SAP_Customer_Code__c,Pan_No__c,Street1__c,Postal_Code__c,Post_Code__c,City1__c,Sales_Organisation__r.Name,
    //                   City__c, Country_Text__c , State__c, State1__c,Street2__c,Phone,Email_Id__c from Account where Id =:Id limit 1];
    //     return acc;
    // }

        @auraEnabled
    public static Quote getCustomerDetail(string Id){
        Quote quo= [select Id,Name,Account.Cust_Acct_Group__c,Account.Account_Group__c,Account.SE_Name__c,Account.Title__c,Account.SAP_Customer_Code__c,Account.Pan_No__c,Account.Street1__c,Account.Postal_Code__c,Account.Post_Code__c,Account.City1__c,Account.Sales_Organisation__r.Name,
                      Account.City__c,Account.Country_Text__c , Account.State__c, Account.State1__c,Account.Street2__c,Account.Phone,Account.Email_Id__c from Quote where Id =:Id limit 1];
        return quo;
    }
    
    @auraEnabled
   public static Map<String, Object> getSalesData() {
    // Query lists
    List<Sales_Organisation__c> slOrgList = [
        SELECT Id, Name 
        FROM Sales_Organisation__c 
        WHERE Name != null
    ];

    List<Division__c> divList = [
        SELECT Id, Name 
        FROM Division__c 
        WHERE Name != null
    ];

    List<Distribution_Channel__c> distriList = [
        SELECT Id, Name 
        FROM Distribution_Channel__c 
        WHERE Name != null
    ];

    // Prepare result map
    Map<String, Object> result = new Map<String, Object>();
    result.put('SalesOrg', slOrgList.isEmpty() ? null : slOrgList);
    result.put('Division', divList.isEmpty() ? null : divList);
    result.put('DistributionChannel', distriList.isEmpty() ? null : distriList);

    return result;
}
    
     @AuraEnabled
    public static void sendEmailWithAttachment(String toAddresses, String ccAddresses, String subject, String body, String fileName, String base64Content) {
        // Create email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        // Split multiple emails by comma
        List<String> toList = new List<String>();
        if (toAddresses != null) toList = toAddresses.split(',');
        mail.setToAddresses(toList);

        if (ccAddresses != null && ccAddresses != '') {
            List<String> ccList = ccAddresses.split(',');
            mail.setCcAddresses(ccList);
        }

        mail.setSubject(subject);
        mail.setPlainTextBody(body);

        // Create attachment
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName(fileName);
        attachment.setBody(EncodingUtil.base64Decode(base64Content));
        mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });

        // Send email
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    
    @AuraEnabled
    public static void sendXlsxEmail(String fileName, String base64Data, String recipientEmail) {
        if (String.isBlank(fileName) || String.isBlank(base64Data) || String.isBlank(recipientEmail)) {
            throw new AuraHandledException('Missing required parameters.');
        }

        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName(fileName);
        attachment.setBody(EncodingUtil.base64Decode(base64Data));
        attachment.setContentType('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { recipientEmail });
        mail.setSubject('📎 XLSX File Attached');
        mail.setPlainTextBody('Hello,\n\nPlease find the attached Excel file.\n\nRegards,\nSalesforce Bot');
        mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });

        Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        if (!results[0].isSuccess()) {
            throw new AuraHandledException('Failed to send email: ' + results[0].getErrors()[0].getMessage());
        }
    }
}