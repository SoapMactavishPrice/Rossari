public with sharing class DocumentApprovalHandlerForOpp {
    @AuraEnabled
    public static String updateApproversAndSendEmails(String approverStringObject, String leadId) {
        try {
            
            ApproverModel approvers = (ApproverModel)JSON.deserialize(approverStringObject, ApproverModel.class);
            
            
            Opportunity leadRecord = [SELECT Id, Company__c, Owner.Name, Owner.Email,
                             TDS_Approver__c, MSDS_Approver__c, Technical_Document_Approver__c 
                             FROM Opportunity WHERE Id = :leadId];
            
            if (approvers.tdsApproverId != null) {
                leadRecord.TDS_Approver__c = approvers.tdsApproverId;
            }
            if (approvers.msdsApproverId != null) {
                leadRecord.MSDS_Approver__c = approvers.msdsApproverId;
            }
            if (approvers.technicalDocApproverId != null) {
                leadRecord.Technical_Document_Approver__c = approvers.technicalDocApproverId;
            }
            
            update leadRecord;
            
            
            List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
            
            
            Set<Id> approverIds = new Set<Id>();
            if (approvers.tdsApproverId != null) approverIds.add(approvers.tdsApproverId);
            if (approvers.msdsApproverId != null) approverIds.add(approvers.msdsApproverId);
            if (approvers.technicalDocApproverId != null) approverIds.add(approvers.technicalDocApproverId);
            
            Map<Id, User> approverMap = new Map<Id, User>([
                SELECT Id, Name, Email 
                FROM User 
                WHERE Id IN :approverIds
            ]);
            
            
            if (approvers.tdsApproverId != null) {
                Messaging.SingleEmailMessage tdsEmail = createApprovalEmail(
                    approverMap.get(approvers.tdsApproverId),
                leadRecord,
                'TDS'
                    );
                emailMessages.add(tdsEmail);
            }
            
            
            if (approvers.msdsApproverId != null) {
                Messaging.SingleEmailMessage msdsEmail = createApprovalEmail(
                    approverMap.get(approvers.msdsApproverId),
                leadRecord,
                'MSDS'
                    );
                emailMessages.add(msdsEmail);
            }
            
            
            if (approvers.technicalDocApproverId != null) {
                Messaging.SingleEmailMessage techEmail = createApprovalEmail(
                    approverMap.get(approvers.technicalDocApproverId),
                leadRecord,
                'Technical'
                    );
                emailMessages.add(techEmail);
            }
            
            
            if (!emailMessages.isEmpty()) {
                Messaging.sendEmail(emailMessages);
            }
            
            return 'Success';
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }
    
    private static Messaging.SingleEmailMessage createApprovalEmail(User approver, Opportunity leadRecord, String documentType) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

        email.setToAddresses(new List<String>{approver.Email});
        email.setCcAddresses(new List<String>{leadRecord.Owner.Email});
        email.setWhatId(leadRecord.Id);
        email.setSaveAsActivity(true);
        email.setSubject('Request for ' + documentType + ' Document - ' + leadRecord.Company__c);

        String htmlBody = 'Dear ' + approver.Name + ',<br/><br/>';
        htmlBody += 'There is a request for a ' + documentType + ' document for the below Opportunity:<br/><br/>';
        // htmlBody += '<b>Opportunity First Name:</b> ' + leadRecord.FirstName + '<br/>';
        // htmlBody += '<b>Opportunity Last Name:</b> ' + leadRecord.LastName + '<br/>';
        htmlBody += '<b>Company:</b> ' + leadRecord.Company__c + '<br/>';
        htmlBody += '<b>URL:</b> <a href="https://rossari--devorg.sandbox.lightning.force.com/lightning/cmp/c__AttachTdsMsdsOnOpportunityCaller?c__recordId=' 
                    + leadRecord.Id + '" target="_blank">Click here</a><br/><br/>';
        htmlBody += 'Kindly review and provide the required document.<br/><br/>';
        htmlBody += 'Regards,<br/>';
        htmlBody += leadRecord.Owner.Name;

        email.setHtmlBody(htmlBody);

        return email;
    }
    
    @AuraEnabled
    public static String uploadDocuments(List<Object> tdsFiles, List<Object> msdsFiles, List<Object> technicalDocumentFiles, String leadId) {
        
        Opportunity leadToUpdate = [SELECT Id, TDS_Upload_Status__c, MSDS_Upload_Status__c, Technical_Doc_Upload_Status__c 
                               FROM Opportunity WHERE Id = :leadId];
        
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        
        
        if (tdsFiles != null && !tdsFiles.isEmpty()) {
            for (Object fileData : tdsFiles) {
                Map<Object, Object> fileMap = (Map<Object, Object>)fileData;
                
                Boolean isReadOnly = (Boolean)fileMap.get('isReadOnly');
                if (isReadOnly != null && isReadOnly) {
                    continue;
                }
                
                ContentVersion cv = createContentVersion(
                    'TDS_' + (String)fileMap.get('fileName'),
                (String)fileMap.get('base64'),
                (String)fileMap.get('contentType')
                    );
                contentVersions.add(cv);
            }
            leadToUpdate.TDS_Upload_Status__c = 'Uploaded';
        }
        
        
        if (msdsFiles != null && !msdsFiles.isEmpty()) {
            for (Object fileData : msdsFiles) {
                Map<Object, Object> fileMap = (Map<Object, Object>)fileData;
                
                Boolean isReadOnly = (Boolean)fileMap.get('isReadOnly');
                if (isReadOnly != null && isReadOnly) {
                    continue;
                }
                
                ContentVersion cv = createContentVersion(
                    'MSDS_' + (String)fileMap.get('fileName'),
                (String)fileMap.get('base64'),
                (String)fileMap.get('contentType')
                    );
                contentVersions.add(cv);
            }
            leadToUpdate.MSDS_Upload_Status__c = 'Uploaded';
        }
        
        
        if (technicalDocumentFiles != null && !technicalDocumentFiles.isEmpty()) {
            for (Object fileData : technicalDocumentFiles) {
                Map<Object, Object> fileMap = (Map<Object, Object>)fileData;
                
                Boolean isReadOnly = (Boolean)fileMap.get('isReadOnly');
                if (isReadOnly != null && isReadOnly) {
                    continue;
                }
                
                ContentVersion cv = createContentVersion(
                    'TechDoc_' + (String)fileMap.get('fileName'),
                (String)fileMap.get('base64'),
                (String)fileMap.get('contentType')
                    );
                contentVersions.add(cv);
            }
            leadToUpdate.Technical_Doc_Upload_Status__c = 'Uploaded';
        }
        
        
        if (!contentVersions.isEmpty()) {
            insert contentVersions;
            
            
            List<ContentVersion> insertedCVs = [
                    SELECT Id, ContentDocumentId 
                    FROM ContentVersion 
                    WHERE Id IN :contentVersions
                ];
            
            
            List<ContentDocumentLink> cdls = new List<ContentDocumentLink>();
            for (ContentVersion cv : insertedCVs) {
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.LinkedEntityId = leadId;
                cdl.ContentDocumentId = cv.ContentDocumentId;
                cdl.ShareType = 'V';
                cdl.Visibility = 'AllUsers';
                cdls.add(cdl);
            }
            
            insert cdls;
        }
        
        
        update leadToUpdate;
        
        // Query lead details for email
        Opportunity lead = [SELECT Id, Company__c, Owner.Name, Owner.Email,
                        TDS_Approver__r.Name, MSDS_Approver__r.Name, Technical_Document_Approver__r.Name
                        FROM Opportunity WHERE Id = :leadId];
        
        // Send email notifications
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        Boolean toSendTdsEmail = false;
        Boolean toSendMsdsEmail = false;
        Boolean toSendTechEmail = false;

        for (Object each : tdsFiles) {
            Map<Object, Object> fileMap = (Map<Object, Object>)each;
                
            Boolean isReadOnly = (Boolean)fileMap.get('isReadOnly');
            String base64 = (String)fileMap.get('base64');
            if (isReadOnly == null && base64 != null) {
                toSendTdsEmail = true;
                break;
            }
        }

        for (Object each : msdsFiles) {
            Map<Object, Object> fileMap = (Map<Object, Object>)each;
                
            Boolean isReadOnly = (Boolean)fileMap.get('isReadOnly');
            String base64 = (String)fileMap.get('base64');
            if (isReadOnly == null && base64 != null) {
                toSendMsdsEmail = true;
                break;
            }
        }

        for (Object each : technicalDocumentFiles) {
            Map<Object, Object> fileMap = (Map<Object, Object>)each;
                
            Boolean isReadOnly = (Boolean)fileMap.get('isReadOnly');
            String base64 = (String)fileMap.get('base64');
            if (isReadOnly == null && base64 != null) {
                toSendTechEmail = true;
                break;
            }
        }
        
        if (toSendTdsEmail) {
            emails.add(createUploadNotificationEmail(lead, 'TDS', lead.TDS_Approver__r.Name));
        }
        if (toSendMsdsEmail) {
            emails.add(createUploadNotificationEmail(lead, 'MSDS', lead.MSDS_Approver__r.Name));
        }
        if (toSendTechEmail) {
            emails.add(createUploadNotificationEmail(lead, 'Technical', lead.Technical_Document_Approver__r.Name));
        }
        
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
        
        return 'Success';
    }
    
    private static Messaging.SingleEmailMessage createUploadNotificationEmail(Opportunity lead, String documentType, String approverName) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{lead.Owner.Email});
        email.setSubject(documentType + ' Document Uploaded - ' + lead.Company__c);
        email.setWhatId(lead.Id);
        email.setSaveAsActivity(true);

        String htmlBody = 'Dear ' + lead.Owner.Name + ',<br/><br/>';
        htmlBody += 'The requested ' + documentType + ' document for the below Opportunity has been successfully uploaded:<br/><br/>';
        // htmlBody += '<b>Opportunity First Name:</b> ' + lead.FirstName + '<br/>';
        // htmlBody += '<b>Opportunity Last Name:</b> ' + lead.LastName + '<br/>';
        htmlBody += '<b>Company:</b> ' + lead.Company__c + '<br/>';
        htmlBody += '<b>URL:</b> <a href="https://rossari--devorg.sandbox.lightning.force.com/lightning/cmp/c__AttachTdsMsdsOnOpportunityCaller?c__recordId=' 
                    + lead.Id + '" target="_blank">Click here</a><br/><br/>';
        htmlBody += 'Please confirm if any further action is required.<br/><br/>';
        htmlBody += 'Regards,<br/>';
        htmlBody += approverName;

        email.setHtmlBody(htmlBody);
        return email;
    }

    
    private static ContentVersion createContentVersion(String title, String base64Content, String contentType) {
        ContentVersion cv = new ContentVersion();
        cv.VersionData = EncodingUtil.base64Decode(base64Content);
        cv.Title = title;
        cv.PathOnClient = title;
        cv.FirstPublishLocationId = null;
        cv.IsMajorVersion = true;
        return cv;
    }
    
    @AuraEnabled
    public static DocumentModel getDocumentModel(String leadId) {
        return new DocumentModel(leadId);
    }
    
    @AuraEnabled
    public static Boolean isRequestDocumentSubmitted(String leadId){
        return [SELECT Is_request_for_document_submitted__c FROM Opportunity WHERE Id = :leadId].Is_request_for_document_submitted__c;
    }
    
    @AuraEnabled
    public static String sendLeadDocumentEmail(String leadId, List<String> toAddresses, List<String> ccAddresses, String subject, String body) {
        // Fetch Opportunity info
        Opportunity leadRecord = [
                SELECT Id, Company__c, Owner.Email
                FROM Opportunity
                WHERE Id = :leadId
            ];
        
        // Get all files attached to the Opportunity
        List<ContentDocumentLink> links = [
                SELECT ContentDocument.LatestPublishedVersionId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :leadId
            ];
        
        if (links.isEmpty()) return 'No files to send.';
        
        Set<Id> contentVersionIds = new Set<Id>();
        for (ContentDocumentLink link : links) {
            contentVersionIds.add(link.ContentDocument.LatestPublishedVersionId);
        }
        
        List<ContentVersion> versions = [
                SELECT Id, Title, VersionData
                FROM ContentVersion
                WHERE Id IN :contentVersionIds AND (Title LIKE 'TDS_%' OR Title LIKE 'MSDS_%' OR Title LIKE 'TechDoc_%')
            ];
        
        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
        
        for (ContentVersion cv : versions) {
            String title = cv.Title;
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName(title);
            attachment.setBody(cv.VersionData);
            attachments.add(attachment);
            
        }
        
        if (attachments.isEmpty()) return 'No relevant documents to send.';
        
        // Prepare email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(toAddresses);
        mail.setCcAddresses(ccAddresses);
        mail.setSubject(subject);
        mail.setHtmlBody(body);
        mail.setFileAttachments(attachments);
        mail.setWhatId(leadId);
        mail.setSaveAsActivity(true);
        
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
        
        return 'Email sent successfully.';
    }

    @AuraEnabled
    public static string savePreviousViewType(String leadId, String viewType){
        Opportunity lead = new Opportunity();
        lead.Id = leadId;
        lead.Previous_View_Type__c = viewType;
        update lead;
        return 'success';
    }

    @AuraEnabled
    public static string getPreviousViewType(String leadId){
        System.debug('leadId ==>'+ leadId);
        Opportunity lead = [SELECT Previous_View_Type__c FROM Opportunity WHERE Id = :leadId];

        if (lead.Previous_View_Type__c != null) {
            return lead.Previous_View_Type__c;
        }

        return null;
    }
    
    public class ApproverModel {
        @AuraEnabled public String tdsApproverId { get; set; }
        @AuraEnabled public String msdsApproverId { get; set; }
        @AuraEnabled public String technicalDocApproverId { get; set; }
    }
    
    public class DocumentModel {
        
        @Auraenabled public List<Object> tdsFiles { get; set; }
        @Auraenabled public List<Object> msdsFiles { get; set; }
        @Auraenabled public List<Object> technicalDocumentFiles { get; set; }
        @AuraEnabled public Boolean isTdsUploaded { get; set; }
        @AuraEnabled public Boolean isMsdsUploaded { get; set; }
        @AuraEnabled public Boolean isTechnicalDocUploaded { get; set; }
        @AuraEnabled public Boolean isTdsDisabled { get; set; }
        @AuraEnabled public Boolean isMsdsDisabled { get; set; }
        @AuraEnabled public Boolean isTechnicalDocDisabled { get; set; }
        @AuraEnabled public String tdsApproverName { get; set; }
        @AuraEnabled public String msdsApproverName { get; set; }
        @AuraEnabled public String technicalDocApproverName { get; set; }
        @AuraEnabled public Boolean isAccessEnabled { get; set; }
        @AuraEnabled public Boolean isSaveDisabled { get; set; }
        
        
        public DocumentModel() {
            this.tdsFiles = new List<Object>();
            this.msdsFiles = new List<Object>();
            this.technicalDocumentFiles = new List<Object>();
            this.isTdsUploaded = false;
            this.isMsdsUploaded = false;
            this.isTechnicalDocUploaded = false;
            this.isTdsDisabled = true;
            this.isMsdsDisabled = true;
            this.isTechnicalDocDisabled = true;
            this.isAccessEnabled = false;
            this.isSaveDisabled = true;
        }
        
        public DocumentModel(String leadId) {
            this();
            
            
            Id currentUserId = UserInfo.getUserId();
            
            
            Opportunity leadRecord = [SELECT Id, 
                                  TDS_Upload_Status__c, 
                                  MSDS_Upload_Status__c, 
                                  Technical_Doc_Upload_Status__c,
                                  TDS_Approver__c, 
                                  MSDS_Approver__c, 
                                  Technical_Document_Approver__c,
                                  TDS_Approver__r.Name,
                                  MSDS_Approver__r.Name,
                                  Technical_Document_Approver__r.Name
                             FROM Opportunity 
                             WHERE Id = :leadId];
            
            
            List<ContentDocumentLink> contentLinks = [
                SELECT ContentDocument.LatestPublishedVersionId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId = :leadId
            ];
            
            Set<Id> contentVersionIds = new Set<Id>();
            for(ContentDocumentLink cdl : contentLinks) {
                contentVersionIds.add(cdl.ContentDocument.LatestPublishedVersionId);
            }
            
            
            List<ContentVersion> contentVersions = [
                SELECT Id, Title 
                FROM ContentVersion 
                WHERE Id IN :contentVersionIds
            ];
            
            
            for(ContentVersion cv : contentVersions) {
                String title = cv.Title;
                if(title.startsWith('TDS_')) {
                    String fileName = title.substringAfter('TDS_');
                    // Add to tdsFiles list for LWC
                    this.tdsFiles.add(new Map<String, Object>{
                        'fileName' => fileName,
                        'base64' => null,      // base64 will only be set for new uploads
                        'isReadOnly' => true    // mark as Apex file
                    });
                } else if(title.startsWith('MSDS_')) {
                    String fileName = title.substringAfter('MSDS_');
                    this.msdsFiles.add(new Map<String, Object>{
                        'fileName' => fileName,
                        'base64' => null,
                        'isReadOnly' => true
                    });
                } else if(title.startsWith('TechDoc_')) {
                    String fileName = title.substringAfter('TechDoc_');
                    this.technicalDocumentFiles.add(new Map<String, Object>{
                        'fileName' => fileName,
                        'base64' => null,
                        'isReadOnly' => true
                    });
                }
            }
            
            
            this.isTdsUploaded = leadRecord.TDS_Upload_Status__c == 'Uploaded';
            this.isMsdsUploaded = leadRecord.MSDS_Upload_Status__c == 'Uploaded';
            this.isTechnicalDocUploaded = leadRecord.Technical_Doc_Upload_Status__c == 'Uploaded';
            
            
            this.isTdsDisabled = !(leadRecord.TDS_Approver__c == currentUserId);
            this.isMsdsDisabled = !(leadRecord.MSDS_Approver__c == currentUserId);
            this.isTechnicalDocDisabled = !(leadRecord.Technical_Document_Approver__c == currentUserId);
            
            
            this.tdsApproverName = leadRecord.TDS_Approver__r != null ? leadRecord.TDS_Approver__r.Name : null;
            this.msdsApproverName = leadRecord.MSDS_Approver__r != null ? leadRecord.MSDS_Approver__r.Name : null;
            this.technicalDocApproverName = leadRecord.Technical_Document_Approver__r != null 
                ? leadRecord.Technical_Document_Approver__r.Name 
                : null;

            Boolean tdsOk = String.isBlank(this.tdsApproverName) || this.isTdsUploaded;
            Boolean msdsOk = String.isBlank(this.msdsApproverName) || this.isMsdsUploaded;
            Boolean techOk = String.isBlank(this.technicalDocApproverName) || this.isTechnicalDocUploaded;

            this.isAccessEnabled = tdsOk && msdsOk && techOk;
            
            this.isSaveDisabled = this.isTdsDisabled && this.isMsdsDisabled && this.isTechnicalDocDisabled;
        }
    }
}