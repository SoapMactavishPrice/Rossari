public with sharing class QuotePdfSendController {

    @AuraEnabled
    public static Quote getQuoteDetails(string recordId) {
        Quote quote = [SELECT Id, Name FROM Quote WHERE Id = :recordId];
        
        if (quote != null) {
            return quote;
        } else {
            return null;
        }
    }
    
    @AuraEnabled
    public static String getCustomerContactEmails(String recordId) {
        Quote quote = [SELECT AccountId FROM Quote WHERE Id = :recordId LIMIT 1];
        
        Set<String> contactEmailStrings = new Set<String>();
        
        List<Contact> contacts = [SELECT Email FROM Contact WHERE AccountId = :quote.AccountId];
        
        for (Contact eachContact : contacts) {
            if (eachContact.Email != null) {
                contactEmailStrings.add(eachContact.Email.toLowerCase());
            }
        }
        
        if (contactEmailStrings.isEmpty()) {
            throw new AuraHandledException('No contact emails available for the Account');
        }
        
        return String.join(contactEmailStrings, ', ');
    }
    
    @AuraEnabled(cacheable=true)
    public static String getPdfUrl(String quoteId) {
        PageReference pdfPage = Page.QuotationPdf;
        pdfPage.getParameters().put('id', quoteId);
        String pdfUrl = '/apex/QuotationPdf?id=' + quoteId + '#toolbar=0';
        return pdfUrl;
    }
    
    @AuraEnabled
    public static User getCurrentUserDetails(){
        User us = [SELECT Name, Email FROM User WHERE Id =:userInfo.getuserId()];
        return us;
    }
    
    @AuraEnabled
    public static string deletefile(String prodId) {
        try {
            System.debug('prodId ==> ' + prodId);
            
            // Query ContentDocumentLinks
            List<ContentDocumentLink> cdlList = [SELECT ContentDocumentId, Id FROM ContentDocumentLink WHERE ContentDocumentId = :prodId];
            System.debug('Number of ContentDocumentLinks found: ' + cdlList.size());
            
            // If no links found, return early
            if (cdlList.isEmpty()) {
                return 'No ContentDocumentLinks found for the given prodId.';
            }
            
            Set<Id> contentDocumentIds = new Set<Id>();
            for (ContentDocumentLink cdl : cdlList) {
                contentDocumentIds.add(cdl.ContentDocumentId);
            }
            
            // Delete the ContentDocumentLink records
            delete cdlList;
            
            // Delete the ContentDocument records
            delete [SELECT Id FROM ContentDocument WHERE Id IN :contentDocumentIds];
            
            return 'Files deleted successfully';
        } catch (Exception e) {
            // Log the error and return an appropriate message
            System.debug('Error: ' + e.getMessage());
            return 'An error occurred while deleting files: ' + e.getMessage();
        }
    }

    @AuraEnabled
    public static string validateQuote(String quoteId){
        Quote quote = [SELECT Id, Account.Business_Type__c FROM Quote WHERE Id = :quoteId];
        return quote.Account.Business_Type__c;
    }

    @AuraEnabled
    public static Boolean isQuoteLineItemsExist(String quoteId) {
        List<QuoteLineItem> quoteLineItems = [SELECT Id FROM QuoteLineItem WHERE QuoteId = :quoteId];

        if (!quoteLineItems.isEmpty()) {
            return true;
        } else {
            return false;
        }
    }
    
    @AuraEnabled
    public static String save(String qtName, String qId, String files) {
        try {
            PageReference pdfPage = null;
            String pdfUrl = null;
            pdfPage = Page.QuotationPdf; // Name of your Visualforce page
            pdfPage.getParameters().put('id', qId); // Pass the qId to the page
            pdfUrl = '/apex/QuotationPdf?id='+qId+'#toolbar=0';
            
            List<Object> jsonList = (List<Object>) System.JSON.deserializeUntyped(files);
            system.debug('jsonList-->'+jsonList.size());
            String finalString = '%' + qtName + '%';
            List<ContentDocument> contentDocs = [SELECT Id, Title FROM ContentDocument WHERE Title LIKE :finalString ORDER BY CreatedDate DESC LIMIT 1];
            
            String version = '0';
            if (contentDocs.size() > 0)
                version = contentDocs[0].Title.substringAfterLast('_').substringBeforeLast('.');
            
            // If there's an existing document, delete it
            //if (contentDocs.size() > 0)
            //Database.delete(contentDocs, false);
            
            // Create a new ContentVersion for the Quote
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.ContentLocation = 'S';
            Integer newVersion = Integer.valueOf(version) + 1;
            contentVersion.PathOnClient = qtName + '_' + newVersion + '.pdf';
            contentVersion.Title = qtName + '_' + newVersion + '.pdf';
            contentVersion.IsMajorVersion = false;
            
            if (Test.isRunningTest()) {
                contentVersion.VersionData = Blob.toPdf('test');
            } else {
                contentVersion.VersionData = pdfPage.getContentAsPDF();  // Ensure `pdf` is defined or replaced by actual PDF generation logic
            }
            
            upsert contentVersion;
            
            // Retrieve the ContentDocumentId of the newly created ContentVersion
            contentVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];
            
            // Link the ContentDocument to the Quote record
            ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
            contentDocumentLink.ContentDocumentId = contentVersion.ContentDocumentId;
            contentDocumentLink.LinkedEntityId = qId;
            contentDocumentLink.ShareType = 'V';
            upsert contentDocumentLink;
            
            set<Id> documentId = new set<Id>();
            List<FileWrapper> fileWrapperlist = new List<FileWrapper>();
            List<ContentVersion> contentVersions = new List<ContentVersion>();
            List<ContentDocumentLink> contentDocLinks = new List<ContentDocumentLink>();
            for (object fl : jsonList) {
                Map<String, Object> file = ( Map<String, Object>)fl;
                String fileName = (String) file.get('name');
                String contentDocumentId = (String) file.get('documentId'); // Optional: Use if passed by LWC
                documentId.add(contentDocumentId);
            }
            
            if(documentId.size () > 0){
                List<ContentVersion> contentVersionsList = [SELECT Id, VersionData,ContentDocumentId , Title FROM ContentVersion WHERE ContentDocumentId IN:documentId ];
                
                
                // Create ContentDocumentLink to associate files with a record (e.g., Quote)
                for (ContentVersion cv : contentVersionsList) {
                    ContentDocumentLink contentDocLink = new ContentDocumentLink();
                    contentDocLink.ContentDocumentId = cv.ContentDocumentId;
                    contentDocLink.LinkedEntityId = qId; // Replace with actual Quote Id
                    contentDocLink.ShareType = 'V';  // 'V' for View permission
                    contentDocLinks.add(contentDocLink);
                }
                
                // Insert ContentDocumentLink records
                if(contentDocLinks.size() > 0) {
                    insert contentDocLinks;
                }
            }
            return 'Success';
            
            
        } catch (Exception e) {
            return e.getMessage() + ' - ' + e.getLineNumber();
        }
    }
    
    @AuraEnabled
    public static String saveAndSend(String emailId, String CC_Addresses, String subject, String body, String qtName, String qId, String OwnerEmail, String OwnerName, String files, Boolean isAttachPdf) {
        try {
            if (String.isNotBlank(emailId) && String.isNotBlank(subject)) {
                // Create PDF for the quotation
                
                PageReference pdfPage = null;
                String pdfUrl = null;
                pdfPage = Page.QuotationPdf; // Name of your Visualforce page
                pdfPage.getParameters().put('id', qId); // Pass the qId to the page
                pdfUrl = '/apex/QuotationPdf?id=' + qId + '#toolbar=0';
                
                String finalString = '%' + qtName + '%';
                List<ContentDocument> contentDocs = [SELECT Id, Title FROM ContentDocument WHERE Title LIKE :finalString ORDER BY CreatedDate DESC LIMIT 1];
                
                String version = '0';
                if (!contentDocs.isEmpty()) {
                    version = contentDocs[0].Title.substringAfterLast('_').substringBeforeLast('.');
                }
                
                // Delete any previous content
                Database.delete(contentDocs, false);
                
                List<ContentDocumentLink> cdls = new List<ContentDocumentLink>();
                if (qId != null) {
                    cdls = [SELECT Id, ContentDocument.LatestPublishedVersionId FROM ContentDocumentLink WHERE LinkedEntityId = :qId];
                }
                
                Set<String> LatestPublishedVersionIds = new Set<String>();
                
                // Create new ContentVersion for the PDF file
                ContentVersion contentVersion = new ContentVersion();
                contentVersion.ContentLocation = 'S';
                Integer newVersion = Integer.valueOf(version) + 1;
                contentVersion.PathOnClient = qtName + '_' + newVersion + '.pdf';
                contentVersion.Title = qtName + '_' + newVersion + '.pdf';
                contentVersion.isMajorVersion = false;
                contentVersion.VersionData = Test.isRunningTest() ? Blob.toPdf('test') : pdfPage.getContentAsPDF();
                upsert contentVersion;
                
                // Retrieve the inserted ContentVersion
                contentVersion = [SELECT Id, ContentDocumentId, ContentDocument.LatestPublishedVersionId, Title, VersionData 
                              FROM ContentVersion WHERE Id = :contentVersion.Id];
                
                ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
                contentDocumentLink.ContentDocumentId = contentVersion.ContentDocumentId;
                contentDocumentLink.LinkedEntityId = qId;
                contentDocumentLink.ShareType = 'V'; // 'V' for View permission
                upsert contentDocumentLink;
                
                // Sending the email
                String fromEmail = OwnerEmail;
                String senderName = OwnerName;
                
                List<OrgWideEmailAddress> orgWideEmails = [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address = :fromEmail LIMIT 1];
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                
                if (!orgWideEmails.isEmpty()) {
                    email.setOrgWideEmailAddressId(orgWideEmails[0].Id);
                } else {
                    email.setReplyTo(fromEmail);
                }
                email.setSenderDisplayName(senderName);
                
                // Handling To and CC email addresses
                Set<String> toEmails = new Set<String>();
                emailId = emailId.replaceAll('[;:]', ',');
                for (String str : emailId.split(',')) {
                    str = str.trim();
                    if (String.isNotBlank(str)) {
                        toEmails.add(str);
                    }
                }
                if (!toEmails.isEmpty()) {
                    System.debug('To Emails ==>' + toEmails);
                    email.setToAddresses(new List<String>(toEmails));
                }
                
                if (String.isNotBlank(CC_Addresses)) {
                    CC_Addresses = CC_Addresses.replaceAll('[;:]', ',');
                    Set<String> ccEmails = new Set<String>();
                    for (String str : CC_Addresses.split(',')) {
                        str = str.trim();
                        if (String.isNotBlank(str)) {
                            ccEmails.add(str);
                        }
                    }
                    email.setCcAddresses(new List<String>(ccEmails));
                    email.setSaveAsActivity(true);
                }
                
                // Attach the created PDF content version to the email
                List<String> contentVersionIds = null;
                if (isAttachPdf) {
                    contentVersionIds = new List<String>{ contentVersion.Id };
                } else {
                    contentVersionIds = new List<String>();
                }
                
                // Now, handle additional files passed from LWC (if any)
                List<Object> jsonList = (List<Object>) System.JSON.deserializeUntyped(files);
                List<ContentDocumentLink> contentDocLinks = new List<ContentDocumentLink>();
                List<string> documentId = new List<string>();
                for (object fl : jsonList) {
                    Map<String, Object> file = ( Map<String, Object>)fl;
                    String fileName = (String) file.get('name');
                    system.debug('fileName-->'+fileName);
                    //system.debug('base64Content-->'+(String) file.get('base64Content'));
                    //String base64Content = (String) file.get('base64Content');
                    system.debug('documentId-->'+(String) file.get('documentId'));
                    String contentDocumentId = (String) file.get('documentId'); // Optional: Use if passed by LWC
                    // Decode the base64 content
                    documentId.add(contentDocumentId);
                    //Blob decodedContent = EncodingUtil.base64Decode(base64Content);
                    
                    
                }
                
                if(documentId.size () > 0){
                    List<ContentVersion> contentVersionsList = [SELECT Id, VersionData,ContentDocumentId , Title FROM ContentVersion WHERE ContentDocumentId IN:documentId ];
                    
                    
                    // Create ContentDocumentLink to associate files with a record (e.g., Quote)
                    for (ContentVersion cv : contentVersionsList) {
                        ContentDocumentLink contentDocLink = new ContentDocumentLink();
                        contentDocLink.ContentDocumentId = cv.ContentDocumentId;
                        contentDocLink.LinkedEntityId = qId; // Replace with actual Quote Id
                        contentDocLink.ShareType = 'V';  // 'V' for View permission
                        contentDocLinks.add(contentDocLink);
                        contentVersionIds.add(cv.Id);
                    }
                    
                    // Insert ContentDocumentLink records
                    if(contentDocLinks.size() > 0) {
                        insert contentDocLinks;
                    }
                }
                // Attach the files to the email
                email.setEntityAttachments(contentVersionIds);
                
                // Set email details
                email.setReplyTo(OwnerEmail);
                email.setSubject(subject);
                email.setWhatId(qId);
                email.setSaveAsActivity(true);
                email.setHtmlBody(body);
                
                // Send the email
                Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
                
            }
            return 'Success';
        }catch (Exception e) {
            return 'Error: ' + e.getMessage();
        }
    }

    public class FileWrapper {
        public String name { get; set; }
        public Long size { get; set; }
        public String type { get; set; }
        public String content { get; set; }
        
        public FileWrapper() {
        }
    }
}