public class DocumentApprovalHandler {
    
    @AuraEnabled
    public static String updateApproversAndSendEmails(String approverStringObject, String sampleDocumentStringObj, String leadId) {
        
        ApproverModel approvers = (ApproverModel)JSON.deserialize(approverStringObject, ApproverModel.class);
        
        
        SampleDocumentWrapper uploadedFiles = (SampleDocumentWrapper)JSON.deserialize(sampleDocumentStringObj, SampleDocumentWrapper.class);

        Lead leadRecord = [
            SELECT Id, FirstName, LastName, Company, Owner.Name, Owner.Email, Lead_Number__c,
                TDS_Approver__c, MSDS_Approver__c, Technical_Document_Approver__c, COA_Document_Approver__c,
                TDS_Remark__c, MSDS_Remark__c, Tech_Doc_Remark__c, COA_Doc_Remark__c
            FROM Lead 
            WHERE Id = :leadId
        ];
        
        
        if (approvers.tdsApproverId != null) leadRecord.TDS_Approver__c = approvers.tdsApproverId;
        if (approvers.msdsApproverId != null) leadRecord.MSDS_Approver__c = approvers.msdsApproverId;
        if (approvers.technicalDocApproverId != null) leadRecord.Technical_Document_Approver__c = approvers.technicalDocApproverId;
        if (approvers.coaDocApproverId != null) leadRecord.COA_Document_Approver__c = approvers.coaDocApproverId;

        if (!Test.isRunningTest()) {
            update leadRecord;
        }

        
        List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
        Map<Id, User> approverMap = new Map<Id, User>([
            SELECT Id, Name, Email FROM User 
            WHERE Id IN :new Set<Id>{
                approvers.tdsApproverId, 
                approvers.msdsApproverId, 
                approvers.technicalDocApproverId, 
                approvers.coaDocApproverId
            }
        ]);

        saveUploadedFiles(uploadedFiles, leadId);
        
        if (approvers.tdsApproverId != null) {
            emailMessages.add(createApprovalEmail(approverMap.get(approvers.tdsApproverId), leadRecord, 'TDS', uploadedFiles.tdsSampleFiles));
        }
        if (approvers.msdsApproverId != null) {
            emailMessages.add(createApprovalEmail(approverMap.get(approvers.msdsApproverId), leadRecord, 'MSDS', uploadedFiles.msdsSampleFiles));
        }
        if (approvers.technicalDocApproverId != null) {
            emailMessages.add(createApprovalEmail(approverMap.get(approvers.technicalDocApproverId), leadRecord, 'Technical', uploadedFiles.techDocSampleFiles));
        }
        if (approvers.coaDocApproverId != null) {
            emailMessages.add(createApprovalEmail(approverMap.get(approvers.coaDocApproverId), leadRecord, 'COA', uploadedFiles.coaSampleFiles));
        }

        if (!emailMessages.isEmpty()) {
            Messaging.sendEmail(emailMessages);
        }

        return 'Success';
    }


    private static void saveUploadedFiles(SampleDocumentWrapper uploadedFiles, Id leadId) {
        List<ContentVersion> contentVersions = new List<ContentVersion>();

        // Helper to process each category
        processFileList(uploadedFiles.tdsSampleFiles, 'TDS Document', contentVersions);
        processFileList(uploadedFiles.msdsSampleFiles, 'MSDS Document', contentVersions);
        processFileList(uploadedFiles.techDocSampleFiles, 'Technical Document', contentVersions);
        processFileList(uploadedFiles.coaSampleFiles, 'COA Document', contentVersions);

        if (!contentVersions.isEmpty()) {
            insert contentVersions;

            List<ContentDocumentLink> links = new List<ContentDocumentLink>();
            for (ContentVersion cv : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :contentVersions]) {
                links.add(new ContentDocumentLink(
                    ContentDocumentId = cv.ContentDocumentId,
                    LinkedEntityId = leadId,
                    ShareType = 'V', // View only
                    Visibility = 'AllUsers'
                ));
            }
            insert links;
        }
    }

    private static void processFileList(List<ContentVersionWrapper> files, String description, List<ContentVersion> contentVersions) {
        for (ContentVersionWrapper fw : files) {
            if (fw.base64Data != null && fw.fileName != null) {
                contentVersions.add(new ContentVersion(
                    Title = fw.fileName,
                    PathOnClient = fw.fileName,
                    VersionData = EncodingUtil.base64Decode(fw.base64Data),
                    Description = description
                ));
            }
        }
    }

    
    private static Messaging.SingleEmailMessage createApprovalEmail(
            User approver, 
            Lead leadRecord, 
            String documentType, 
            List<ContentVersionWrapper> files) 
    {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{approver.Email});
        email.setCcAddresses(new List<String>{leadRecord.Owner.Email});
        email.setTargetObjectId(leadRecord.Id);
        email.setTreatTargetObjectAsRecipient(false);
        email.setSaveAsActivity(true);
        email.setSubject('Request for ' + documentType + ' Document - ' + leadRecord.Company);

        // Email body
        String htmlBody = 'Dear ' + approver.Name + ',<br/><br/>';
        htmlBody += 'There is a request for a ' + documentType + ' document for the below Lead:<br/><br/>';
        htmlBody += '<b>Lead Number:</b> ' + leadRecord.Lead_Number__c + '<br/>';
        htmlBody += '<b>Lead First Name:</b> ' + leadRecord.FirstName + '<br/>';
        htmlBody += '<b>Lead Last Name:</b> ' + leadRecord.LastName + '<br/>';
        htmlBody += '<b>Company:</b> ' + leadRecord.Company + '<br/>';

        // Remark
        if (documentType == 'TDS') htmlBody += '<b>Remark:</b> ' + (leadRecord.TDS_Remark__c != null ? leadRecord.TDS_Remark__c : '') + '<br/>';
        else if (documentType == 'MSDS') htmlBody += '<b>Remark:</b> ' + (leadRecord.MSDS_Remark__c != null ? leadRecord.MSDS_Remark__c : '') + '<br/>';
        else if (documentType == 'Technical') htmlBody += '<b>Remark:</b> ' + (leadRecord.Tech_Doc_Remark__c != null ? leadRecord.Tech_Doc_Remark__c : '') + '<br/>';
        else if (documentType == 'COA') htmlBody += '<b>Remark:</b> ' + (leadRecord.COA_Doc_Remark__c != null ? leadRecord.COA_Doc_Remark__c : '') + '<br/>';

        htmlBody += '<b>URL:</b> <a href="' + Utility.baseUrl + '/lightning/cmp/c__AttachTdsMsdsOnOppCaller?c__recordId=' 
                        + leadRecord.Id + '" target="_blank">Click here</a><br/><br/>';
        htmlBody += 'Kindly review and provide the required document.<br/><br/>';
        htmlBody += 'Regards,<br/>' + leadRecord.Owner.Name;

        email.setHtmlBody(htmlBody);

        // Attach files as email attachments
        if (files != null && !files.isEmpty()) {
            List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
            for (ContentVersionWrapper f : files) {
                Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
                attach.setFileName(f.fileName);
                attach.setBody(EncodingUtil.base64Decode(f.base64Data));
                attachments.add(attach);
            }
            email.setFileAttachments(attachments);
        }

        return email;
    }

    
    @AuraEnabled
    public static String uploadDocuments(List<Object> tdsFiles, List<Object> msdsFiles, List<Object> technicalDocumentFiles, List<Object> coaDocumentFiles, String leadId) {
        
        Lead leadToUpdate = [SELECT Id, TDS_Upload_Status__c, MSDS_Upload_Status__c, Technical_Doc_Upload_Status__c, COA_Doc_Upload_Status__c
                               FROM Lead WHERE Id = :leadId];
        
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

        if (coaDocumentFiles != null && !coaDocumentFiles.isEmpty()) {
            for (Object fileData : coaDocumentFiles) {
                Map<Object, Object> fileMap = (Map<Object, Object>)fileData;
                
                Boolean isReadOnly = (Boolean)fileMap.get('isReadOnly');
                if (isReadOnly != null && isReadOnly) {
                    continue;
                }
                
                ContentVersion cv = createContentVersion(
                    'COA_' + (String)fileMap.get('fileName'),
                (String)fileMap.get('base64'),
                (String)fileMap.get('contentType')
                    );
                contentVersions.add(cv);
            }
            leadToUpdate.COA_Doc_Upload_Status__c = 'Uploaded';
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
        Lead lead = [SELECT Id, FirstName, LastName, Company, Owner.Name, Owner.Email, Lead_Number__c,
                        TDS_Approver__r.Name, MSDS_Approver__r.Name, Technical_Document_Approver__r.Name, COA_Document_Approver__r.Name
                        FROM Lead WHERE Id = :leadId];
        
        // Send email notifications
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        Boolean toSendTdsEmail = false;
        Boolean toSendMsdsEmail = false;
        Boolean toSendTechEmail = false;
        Boolean toSendCoaEmail = false;

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

        for (Object each : coaDocumentFiles) {
            Map<Object, Object> fileMap = (Map<Object, Object>)each;
                
            Boolean isReadOnly = (Boolean)fileMap.get('isReadOnly');
            String base64 = (String)fileMap.get('base64');
            if (isReadOnly == null && base64 != null) {
                toSendCoaEmail = true;
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
        if (toSendCoaEmail) {
            emails.add(createUploadNotificationEmail(lead, 'COA', lead.COA_Document_Approver__r.Name));
        }
        
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
        
        return 'Success';
    }
    
    private static Messaging.SingleEmailMessage createUploadNotificationEmail(Lead lead, String documentType, String approverName) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{lead.Owner.Email});
        email.setSubject(documentType + ' Document Uploaded - ' + lead.Company);
        email.setTargetObjectId(lead.Id);
        email.setSaveAsActivity(true);

        String htmlBody = 'Dear ' + lead.Owner.Name + ',<br/><br/>';
        htmlBody += 'The requested ' + documentType + ' document for the below Lead has been successfully uploaded:<br/><br/>';
        htmlBody += '<b>Lead Number:</b> ' + lead.Lead_Number__c + '<br/>';
        htmlBody += '<b>Lead First Name:</b> ' + lead.FirstName + '<br/>';
        htmlBody += '<b>Lead Last Name:</b> ' + lead.LastName + '<br/>';
        htmlBody += '<b>Company:</b> ' + lead.Company + '<br/>';
        htmlBody += '<b>URL:</b> <a href="' + Utility.baseUrl + '/lightning/cmp/c__AttachTdsMsdsOnOppCaller?c__recordId=' 
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
        return [SELECT Is_request_for_document_submitted__c FROM Lead WHERE Id = :leadId].Is_request_for_document_submitted__c;
    }
    
    @AuraEnabled
    public static String sendLeadDocumentEmail(String leadId, List<String> toAddresses, List<String> ccAddresses, String subject, String body) {
        // Fetch Lead info
        Lead leadRecord = [
                SELECT Id, FirstName, LastName, Company, Owner.Email
                FROM Lead
                WHERE Id = :leadId
            ];
        
        // Get all files attached to the Lead
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
                WHERE Id IN :contentVersionIds AND (Title LIKE 'TDS_%' OR Title LIKE 'MSDS_%' OR Title LIKE 'TechDoc_%' OR Title LIKE 'COA_%')
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
        mail.setTargetObjectId(leadId);
        mail.setSaveAsActivity(true);
        
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
        
        return 'Email sent successfully.';
    }

    @AuraEnabled
    public static String savePreviousViewType(String leadId, String viewType){
        Lead lead = new Lead();
        lead.Id = leadId;
        lead.Previous_View_Type__c = viewType;
        update lead;
        return 'success';
    }

    @AuraEnabled
    public static String getPreviousViewType(String leadId){
        System.debug('leadId ==>'+ leadId);
        Lead lead = [SELECT Previous_View_Type__c FROM Lead WHERE Id = :leadId];

        if (lead.Previous_View_Type__c != null) {
            return lead.Previous_View_Type__c;
        }

        return null;
    }

    @AuraEnabled
    public static String saveRemarks(String tdsRemark, String msdsRemark, String techDocRemark, String coaDocRemark, String leadId) {
        

        Lead lead = new Lead(Id = leadId);
        if (tdsRemark != null) {
            lead.TDS_Remark__c = tdsRemark;
        }
        if (msdsRemark != null) {
            lead.MSDS_Remark__c = msdsRemark;
        }
        if (techDocRemark != null) {
            lead.Tech_Doc_Remark__c = techDocRemark;
        }
        if (coaDocRemark != null) {
            lead.COA_Doc_Remark__c = coaDocRemark;
        }

        UPDATE lead;

        return 'Success';
    }

    @AuraEnabled
    public static String getConvertedRecordId(String leadId) {
        if (String.isBlank(leadId)) {
            return null;
        }
        
        Lead ld = [
            SELECT Id, IsConverted, ConvertedOpportunityId, ConvertedAccountId
            FROM Lead 
            WHERE Id = :leadId
            LIMIT 1
        ];
        
        if (!ld.IsConverted) {
            return null;
        }
        
        if (ld.ConvertedOpportunityId != null) {
            return Utility.baseUrl + '/lightning/cmp/c__AttachTdsMsdsOnOpportunityCaller?c__recordId=' 
                        + ld.ConvertedOpportunityId;
        }
        
        return Utility.baseUrl + '/lightning/cmp/c__AttachTdsMsdsOnAccountCaller?c__recordId=' 
                    + ld.ConvertedAccountId;
    }

    
    public class ApproverModel {
        @AuraEnabled public String tdsApproverId { get; set; }
        @AuraEnabled public String msdsApproverId { get; set; }
        @AuraEnabled public String technicalDocApproverId { get; set; }
        @AuraEnabled public String coaDocApproverId { get; set; }
    }
    
    public class DocumentModel {
        
        @Auraenabled public List<Object> tdsFiles { get; set; }
        @Auraenabled public List<Object> msdsFiles { get; set; }
        @Auraenabled public List<Object> technicalDocumentFiles { get; set; }
        @Auraenabled public List<Object> coaDocumentFiles { get; set; }
        @AuraEnabled public Boolean isTdsUploaded { get; set; }
        @AuraEnabled public Boolean isMsdsUploaded { get; set; }
        @AuraEnabled public Boolean isTechnicalDocUploaded { get; set; }
        @AuraEnabled public Boolean isCoaDocUploaded { get; set; }
        @AuraEnabled public Boolean isTdsDisabled { get; set; }
        @AuraEnabled public Boolean isMsdsDisabled { get; set; }
        @AuraEnabled public Boolean isTechnicalDocDisabled { get; set; }
        @AuraEnabled public Boolean isCoaDocDisabled { get; set; }
        @AuraEnabled public String tdsApproverName { get; set; }
        @AuraEnabled public String msdsApproverName { get; set; }
        @AuraEnabled public String technicalDocApproverName { get; set; }
        @AuraEnabled public String coaDocApproverName { get; set; }
        @AuraEnabled public String tdsApproverRemark { get; set; }
        @AuraEnabled public String msdsApproverRemark { get; set; }
        @AuraEnabled public String technicalDocApproverRemark { get; set; }
        @AuraEnabled public String coaDocApproverRemark { get; set; }
        @AuraEnabled public Boolean isAccessEnabled { get; set; }
        @AuraEnabled public Boolean isSaveDisabled { get; set; }
        
        
        public DocumentModel() {
            this.tdsFiles = new List<Object>();
            this.msdsFiles = new List<Object>();
            this.technicalDocumentFiles = new List<Object>();
            this.coaDocumentFiles = new List<Object>();
            this.isTdsUploaded = false;
            this.isMsdsUploaded = false;
            this.isTechnicalDocUploaded = false;
            this.isCoaDocUploaded = false;
            this.isTdsDisabled = true;
            this.isMsdsDisabled = true;
            this.isTechnicalDocDisabled = true;
            this.isCoaDocDisabled = true;
            this.isAccessEnabled = false;
            this.isSaveDisabled = true;
        }
        
        public DocumentModel(String leadId) {
            this();
            
            
            Id currentUserId = UserInfo.getUserId();
            
            
            Lead leadRecord = [SELECT Id, 
                                  TDS_Upload_Status__c, 
                                  MSDS_Upload_Status__c, 
                                  Technical_Doc_Upload_Status__c,
                                  COA_Doc_Upload_Status__c,
                                  TDS_Approver__c, 
                                  MSDS_Approver__c, 
                                  Technical_Document_Approver__c,
                                  COA_Document_Approver__c,
                                  TDS_Approver__r.Name,
                                  MSDS_Approver__r.Name,
                                  Technical_Document_Approver__r.Name,
                                  COA_Document_Approver__r.Name,
                                  TDS_Remark__c,
                                  MSDS_Remark__c,
                                  Tech_Doc_Remark__c,
                                  COA_Doc_Remark__c
                             FROM Lead 
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
                } else if(title.startsWith('COA_')) {
                    String fileName = title.substringAfter('COA_');
                    this.coaDocumentFiles.add(new Map<String, Object>{
                        'fileName' => fileName,
                        'base64' => null,
                        'isReadOnly' => true
                    });
                }
            }
            
            
            this.isTdsUploaded = leadRecord.TDS_Upload_Status__c == 'Uploaded';
            this.isMsdsUploaded = leadRecord.MSDS_Upload_Status__c == 'Uploaded';
            this.isTechnicalDocUploaded = leadRecord.Technical_Doc_Upload_Status__c == 'Uploaded';
            this.isCoaDocUploaded = leadRecord.COA_Doc_Upload_Status__c == 'Uploaded';


            this.tdsApproverRemark = leadRecord.TDS_Remark__c;
            this.msdsApproverRemark = leadRecord.MSDS_Remark__c;
            this.technicalDocApproverRemark = leadRecord.Tech_Doc_Remark__c;
            this.coaDocApproverRemark = leadRecord.COA_Doc_Remark__c;
            
            
            this.isTdsDisabled = !(leadRecord.TDS_Approver__c == currentUserId);
            this.isMsdsDisabled = !(leadRecord.MSDS_Approver__c == currentUserId);
            this.isTechnicalDocDisabled = !(leadRecord.Technical_Document_Approver__c == currentUserId);
            this.isCoaDocDisabled = !(leadRecord.COA_Document_Approver__c == currentUserId);
            
            
            this.tdsApproverName = leadRecord.TDS_Approver__r != null ? leadRecord.TDS_Approver__r.Name : null;
            this.msdsApproverName = leadRecord.MSDS_Approver__r != null ? leadRecord.MSDS_Approver__r.Name : null;
            this.technicalDocApproverName = leadRecord.Technical_Document_Approver__r != null 
                ? leadRecord.Technical_Document_Approver__r.Name 
                : null;
            this.coaDocApproverName = leadRecord.COA_Document_Approver__r != null 
                ? leadRecord.COA_Document_Approver__r.Name 
                : null;

            Boolean tdsOk = String.isBlank(this.tdsApproverName) || this.isTdsUploaded;
            Boolean msdsOk = String.isBlank(this.msdsApproverName) || this.isMsdsUploaded;
            Boolean techOk = String.isBlank(this.technicalDocApproverName) || this.isTechnicalDocUploaded;
            Boolean coaOk = String.isBlank(this.coaDocApproverName) || this.isCoaDocUploaded;

            this.isAccessEnabled = tdsOk && msdsOk && techOk && coaOk;
            
            this.isSaveDisabled = this.isTdsDisabled && this.isMsdsDisabled && this.isTechnicalDocDisabled && this.isCoaDocDisabled;
        }
    }

    public class SampleDocumentWrapper {
        @AuraEnabled public List<ContentVersionWrapper> tdsSampleFiles { get; set; }
        @AuraEnabled public List<ContentVersionWrapper> msdsSampleFiles { get; set; }
        @AuraEnabled public List<ContentVersionWrapper> techDocSampleFiles { get; set; }
        @AuraEnabled public List<ContentVersionWrapper> coaSampleFiles { get; set; }
    }

    public class ContentVersionWrapper {
        @AuraEnabled public String fileName { get; set; }
        @AuraEnabled public String base64Data { get; set; } // base64 string of file content
    }

}