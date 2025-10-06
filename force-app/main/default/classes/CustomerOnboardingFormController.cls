public class CustomerOnboardingFormController {
    
    @auraEnabled
    public static Account getCustomerDetail(string Id){
        //Search_term__c,Name_2__c,Street3__c,language__c
        Account acc= [select Id,Name,Cust_Acct_Group__c,Account_Group__c,SE_Name__c,Title__c,SAP_Customer_Code__c,Pan_No__c,Street1__c,Postal_Code__c,Post_Code__c,City1__c,Sales_Organisation__r.Name,
                      City__c, Country_Text__c , State__c, State1__c,Street2__c,Phone,Email_Id__c from Account where Id =:Id limit 1];
        return acc;
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
}