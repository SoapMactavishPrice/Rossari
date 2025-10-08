public with sharing class SendTdsFileFromAccount {
    @AuraEnabled
    public static Account getEmailDetails(String leadId) {
        Account leadRecord = [SELECT Owner.Email FROM Account WHERE Id = :leadId LIMIT 1];
        
        return leadRecord;
    }

    @AuraEnabled
    public static LeadWrapper getLead(String leadId) {
        Account lead = [SELECT Id, Name FROM Account WHERE Id = :leadId];
        
        return new LeadWrapper(lead);
    }

    @AuraEnabled
    public static String getProductData(String leadId) {
        List<Product_Interested__c> productList = [
            SELECT Id, Product__c 
            FROM Product_Interested__c 
            WHERE Account__c = :leadId
        ];

        if (productList.isEmpty()) {
            return null;
        }

        Set<Id> productIds = new Set<Id>();
        for (Product_Interested__c product : productList) {
            if (String.isNotBlank(product.Product__c)) {
                productIds.add(product.Product__c);
            }
        }

        List<dataWrapper> dataList = new List<dataWrapper>();
        if (!productIds.isEmpty()) {
            List<Product2> products = [
                SELECT Id, Name, ProductCode, Description 
                FROM Product2 
                WHERE Id IN :productIds
            ];

            List<Product_Document__c> productDocuments = [
                SELECT Id, Name, Product__c 
                FROM Product_Document__c 
                WHERE Product__c IN :productIds
                ORDER BY Product__c, Name
            ];

            Map<Id, List<Product_Document__c>> productToDocsMap = new Map<Id, List<Product_Document__c>>();
            for (Product_Document__c doc : productDocuments) {
                if (!productToDocsMap.containsKey(doc.Product__c)) {
                    productToDocsMap.put(doc.Product__c, new List<Product_Document__c>());
                }
                productToDocsMap.get(doc.Product__c).add(doc);
            }

            Integer index = 1;
            for (Product2 product : products) {
                dataWrapper data = new dataWrapper();
                data.Id = product.Id;
                data.index = index++;
                data.Name = product.Name;
                data.ProductCode = product.ProductCode;
                data.Description = product.Description;
                data.openFiles = true;
                data.closeFiles = false;
                data.showChildData = false;
                data.dataChildFiles = new List<dataChildWrapper>();
                
                if (productToDocsMap.containsKey(product.Id)) {
                    for (Product_Document__c doc : productToDocsMap.get(product.Id)) {
                        dataChildWrapper docWrapper = new dataChildWrapper();
                        docWrapper.Id = doc.Id;
                        docWrapper.Name = doc.Name;
                        docWrapper.isParent = true;
                        docWrapper.hasChildren = true;
                        docWrapper.openFiles = true;
                        docWrapper.closeFiles = false;
                        docWrapper.showChildData = false;
                        docWrapper.dataChildFiles = new List<dataChildWrapper>();
                        data.dataChildFiles.add(docWrapper);
                    }
                }
                
                dataList.add(data);
            }
        }

        return (dataList.size() > 0) ? JSON.serialize(dataList) : null;
    }

    @AuraEnabled
    public static String getFiledDisplay(String docId) {
        List<ContentDocumentLink> cdList = [
            SELECT ContentDocument.Id, Id, ContentDocument.Title, 
                   ContentDocument.FileExtension, LinkedEntityId
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :docId
        ];

        List<dataChildWrapper> fileList = new List<dataChildWrapper>();
        
        for (ContentDocumentLink cdl : cdList) {
            dataChildWrapper file = new dataChildWrapper();
            file.Id = cdl.Id;
            file.Name = cdl.ContentDocument.Title;
            file.selectFile = false;
            file.isParent = false;
            file.hasChildren = false;
            fileList.add(file);
        }
        
        return (fileList.size() > 0) ? JSON.serialize(fileList) : null;
    }

    @AuraEnabled
    public static String getDocumentUrl(String Id) {
        ContentDocumentLink cdl = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE Id = :Id LIMIT 1
        ];

        ContentVersion attach = [
            SELECT Id, Title, VersionData, FileExtension, ContentDocumentId, 
                   ContentDocument.Title, ContentDocument.CreatedDate
            FROM ContentVersion
            WHERE ContentDocumentId = :cdl.ContentDocumentId
            AND ContentDocument.filetype != 'mp4'
            ORDER BY CreatedDate DESC LIMIT 1];
        
        return attach.ContentDocumentId;
    }

    @AuraEnabled
    public static string sendMailToCustomer(string toAdd, List<String> cc, string subject, string body, string fileId, List<Object> attachmentsFromUploadFile) {
        map<string,string> result = new map<string,string>();
        try {
            List<String> sObj = (List<String>) JSON.deserialize(fileId, List<String>.class);
            
            if(sObj.size() > 0 || attachmentsFromUploadFile.size() > 0) {
                List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();

                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                List<String> toEmails = toAdd.split(',');
                mail.setToAddresses(toEmails);
                
                if(cc != null && !cc.isEmpty()) {
                    mail.setCcAddresses(cc);
                }
                
                mail.setSubject(subject);
                mail.setHtmlBody(body);
                
                if (sObj.size() > 0) {
                    List<ContentDocumentLink> cdlList = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE Id IN :sObj];
                    set<Id> cDoc_id = new set<Id>();
                    for(ContentDocumentLink cdl: cdlList) {
                        cDoc_id.add(cdl.ContentDocumentId);
                    }
                    
                    if(cDoc_id.size() > 0) {
                        List<ContentVersion> contentVersions = [SELECT Id, Title, VersionData, FileExtension, ContentDocumentId 
                                                              FROM ContentVersion WHERE ContentDocumentId IN :cDoc_id];

                        for(ContentVersion contentVersion : contentVersions) {
                            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                            attachment.setFileName(contentVersion.Title + '.' + contentVersion.FileExtension);
                            attachment.setBody(contentVersion.VersionData);
                            attachments.add(attachment);
                        }
                    }
                }
                
                if (attachmentsFromUploadFile.size() > 0) {
                    for (Object attObj : attachmentsFromUploadFile) {
                        Map<Object, Object> att = (Map<Object, Object>) attObj;
                        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                        efa.setFileName((String) att.get('filename'));
                        efa.setBody(EncodingUtil.base64Decode((String) att.get('base64')));
                        attachments.add(efa);
                    }
                }
                
                mail.setFileAttachments(attachments);
                Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                
                if (results[0].isSuccess()) {
                    result.put('Success','success');
                } else {
                    result.put('Error', JSON.serialize(results[0].getErrors()));
                }
            } else {
                throw new AuraHandledException('No Files found to attach.');
            }
        } catch(Exception e) {
            result.put('error', String.valueOf(e.getLineNumber()) + ' ' + e.getMessage());
        }
        
        return JSON.serialize(result);
    }

    @AuraEnabled
    public static String requestApproval(String leadStringObject) {
        // LeadWrapper leadWrapper = parseHeader(leadStringObject);

        // Opportunity lead = new Opportunity();
        // lead.Id = leadWrapper.leadId;
        // lead.COA_Approval_Level_1__c = leadWrapper.level1User;
        // lead.COA_Approval_Level_2__c = leadWrapper.level2User;
        // if (lead.COA_Approval_Level_1__c != null || lead.COA_Approval_Level_2__c != null) {
        //     lead.COA_Approval_Level_1_Status__c = 'Submitted';
        // }
        // UPDATE lead;

        return 'Success';
    }
    
    @AuraEnabled
    public static UserDetailWrapper getCurrentUserDetails() {
        User currentUser = [SELECT Name, Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        return new UserDetailWrapper(currentUser.Name, currentUser.Email);
    }

    private static LeadWrapper parseHeader(string js){
        return (LeadWrapper)system.JSON.deserialize(js,LeadWrapper.class);
    }
    
    public class UserDetailWrapper {
        @AuraEnabled public String ownerName;
        @AuraEnabled public String ownerEmail;
        
        public UserDetailWrapper(String ownerName, String ownerEmail) {
            this.ownerName = ownerName;
            this.ownerEmail = ownerEmail;
        }
    }

    public class dataWrapper {
        @AuraEnabled public String Id;
        @AuraEnabled public Integer index;
        @AuraEnabled public String Name;
        @AuraEnabled public String ProductCode;
        @AuraEnabled public String Description;
        @AuraEnabled public Boolean openFiles;
        @AuraEnabled public Boolean closeFiles;
        @AuraEnabled public Boolean showChildData;
        @AuraEnabled public List<dataChildWrapper> dataChildFiles;
    }

    public class dataChildWrapper {
        @AuraEnabled public String Id;
        @AuraEnabled public String Name;
        @AuraEnabled public Boolean selectFile;
        @AuraEnabled public Boolean isParent;
        @AuraEnabled public Boolean hasChildren;
        @AuraEnabled public Boolean openFiles;
        @AuraEnabled public Boolean closeFiles;
        @AuraEnabled public Boolean showChildData;
        @AuraEnabled public List<dataChildWrapper> dataChildFiles;
    }

    public class LeadWrapper {
        @AuraEnabled public Boolean isTristarOrUnitop;
        @AuraEnabled public String leadId;
        @AuraEnabled public String leadName;
        @AuraEnabled public String level1User;
        @AuraEnabled public String level2User;
        @AuraEnabled public String level1ApprovalStatus;
        @AuraEnabled public String level2ApprovalStatus;
        @AuraEnabled public Boolean enableSendEmail;

        public LeadWrapper(Account lead) {
            this.leadId = lead.Id;
            this.leadName = lead.Name;

            // if (lead.RecordType.Name == 'Tristar' || lead.RecordType.Name == 'Unitop') {
            //     this.isTristarOrUnitop = true;
            // }

            // if (!this.isTristarOrUnitop) {
            //     this.enableSendEmail = true;
            // } else {
            //     if (level1User != null && level2User != null) {
            //         if (level1ApprovalStatus == 'Approved' && level2ApprovalStatus == 'Approved') {
            //             this.enableSendEmail = true;
            //         } 
            //     } else if (level1User != null) {
            //         if (level1ApprovalStatus == 'Approved') {
            //             this.enableSendEmail = true;
            //         }
            //     } else if (level2User != null) {
            //         if (level2ApprovalStatus == 'Approved') {
            //             this.enableSendEmail = true;
            //         }
            //     }
            // }

        }
    }
}