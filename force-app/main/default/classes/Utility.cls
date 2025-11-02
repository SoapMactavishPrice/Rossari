public with sharing class Utility {

    public static String baseUrl = System.Url.getOrgDomainUrl().toExternalForm();
    
    @AuraEnabled
    public static List<Map<String, String>> getContactName(String recordId, String objectType) {
        List<Map<String, String>> contactOptions = new List<Map<String, String>>();

        Id accountId;

        if (objectType == 'Account') {
            accountId = recordId;
        } else if (objectType == 'Opportunity') {
            Opportunity opp = [SELECT AccountId FROM Opportunity WHERE Id = :recordId LIMIT 1];
            accountId = opp.AccountId;
        } else if (objectType == 'Quote') {
            Quote quote = [SELECT AccountId FROM Quote WHERE Id = :recordId LIMIT 1];
            accountId = quote.AccountId;
        }

        if (accountId != null) {
            List<Contact> contacts = [SELECT Id, Name FROM Contact WHERE AccountId = :accountId];
            for (Contact c : contacts) {
                contactOptions.add(new Map<String, String>{'label' => c.Name, 'value' => c.Id});
            }
        }
        if (contactOptions.size() > 0) {
            return contactOptions;
        } else {
            throw new AuraHandledException('No contacts found for this customer');
        }
    }

/*    @AuraEnabled
    public static List<Contact_Email__c> getContactEmail(String recordId) {
        List<Map<String, String>> contactOptions = new List<Map<String, String>>();

        Id accountId;
        List<Contact_Email__c> conEmailist = new List<Contact_Email__c>();
        conEmailist = [Select Id , Email_Id__c,Contact__c from Contact_Email__c where Contact__c=:recordId and Email_Id__c!=null];
        return conEmailist;
    
    }		*/

    @AuraEnabled
    public static List<Map<String, String>> getBillTo(String recordId, String objectType) {
        List<Map<String, String>> billToOptions = new List<Map<String, String>>();
        Id accountId;

        if (objectType == 'Account') {
            accountId = recordId;
        } else if (objectType == 'Opportunity') {
            Opportunity opp = [SELECT AccountId FROM Opportunity WHERE Id = :recordId LIMIT 1];
            accountId = opp.AccountId;
        } else if (objectType == 'Quote') {
            Quote quote = [SELECT AccountId FROM Quote WHERE Id = :recordId LIMIT 1];
            accountId = quote.AccountId;
        }

        if (accountId != null) {
            List<Address_Information__c> addressInformation = [SELECT Id, Name FROM Address_Information__c WHERE Account__c = :accountId AND Name LIKE 'Bill To%'];
            for (Address_Information__c a : addressInformation) {
                billToOptions.add(new Map<String, String>{'label' => a.Name, 'value' => a.Id});
            }
        }
        if (billToOptions.size() > 0) {
            return billToOptions;
        } else {
            throw new AuraHandledException('No Bill To address found for this customer');
        }
    }

    @AuraEnabled
    public static List<Map<String, String>> getShipTo(String recordId, String objectType) {
        system.debug('objectType-->'+objectType);
        List<Map<String, String>> shipToOptions = new List<Map<String, String>>();
        Id accountId;

        if (objectType == 'Account') {
            accountId = recordId;
        } else if (objectType == 'Opportunity') {
            Opportunity opp = [SELECT AccountId FROM Opportunity WHERE Id = :recordId LIMIT 1];
            accountId = opp.AccountId;
        }/* else if (objectType == 'Quote') {
            Quote quote = [SELECT Ship_to_Party__r.Account__c FROM Quote WHERE Id = :recordId LIMIT 1];
            accountId = quote.Ship_to_Party__r.Account__c;
        } else if (objectType == 'Sample_Request__c') {
            Sample_Request__c sampleRequest = [SELECT Account__c FROM Sample_Request__c WHERE Id = :recordId LIMIT 1];
            accountId = sampleRequest.Account__c;
        }  */
        
        if (accountId != null) {
            List<Address_Information__c> addressInformation = [SELECT Id, Name FROM Address_Information__c WHERE Account__c = :accountId AND Name LIKE 'Ship To%'];
            for (Address_Information__c a : addressInformation) {
                shipToOptions.add(new Map<String, String>{'label' => a.Name, 'value' => a.Id});
            }
        }
        if (shipToOptions.size() > 0) {
            return shipToOptions;
        } else {
            throw new AuraHandledException('No Ship To address found for this customer');
        }
    }

    @AuraEnabled
    public static Address_Information__c getShipToAddressInformation(String addressInformationId){
        Address_Information__c shipToAddress = [SELECT Street_1__c, Street_2__c, Street_3__c, Country__c, State__c, City__c, Pin_Code__c FROM Address_Information__c WHERE Id = :addressInformationId LIMIT 1];
        return shipToAddress;
    }

    @AuraEnabled
    public static List<Map<String, String>> getPlant(){
        List<Plant__c> plants = [SELECT Id, Name FROM Plant__c];

        List<Map<String, String>> plantOptions = new List<Map<String, String>>();

        for (Plant__c eachPlant : plants) {
            plantOptions.add(new Map<String, String>{'label' => eachPlant.Name, 'value' => eachPlant.Id});
        }

        return plantOptions;
    }

  /*  @AuraEnabled
    public static List<Map<String, String>> getUOM(){
        List<UOM_Master__c> uomMasters = [SELECT Id, Name FROM UOM_Master__c];

        List<Map<String, String>> uomOptions = new List<Map<String, String>>();

        for (UOM_Master__c eachUOM : uomMasters) {
            uomOptions.add(new Map<String, String>{'label' => eachUOM.Name, 'value' => eachUOM.Id});
        }

        return uomOptions;
    }		*/

    @AuraEnabled
    public static String toTitleCase(String input) {
        System.debug('Title ==>' + input);
        if (String.isBlank(input)) return input;
        
        List<String> words = input.toLowerCase().split((' |<br/>'));
        for (Integer i = 0; i < words.size(); i++) {
            if (words[i].length() > 0) {
                words[i] = words[i].substring(0, 1).toUpperCase() + words[i].substring(1);
            }
        }

        System.debug('Final ==>' + String.join(words, ' '));
        return String.join(words, ' ');
    }

    @AuraEnabled
    public static List<String> getProductsPlant(String productCode){
        try {
            List<Product2> products = [SELECT Id, ProductCode, Plant_Name__c FROM Product2 WHERE ProductCode = :productCode];
            Set<String> plantIds = new Set<String>();
            for (Product2 eachProduct:products) {
                plantIds.add(eachProduct.Plant_Name__c);
            }
            return new List<String>(plantIds);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static String getContactSalutation(String salutationApiName) {
        Schema.DescribeFieldResult fieldResult = Contact.Salutation.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        
        Map<String, String> picklistMap = new Map<String, String>();
        
        for (Schema.PicklistEntry entry : picklistValues) {
            if (entry.getValue() == salutationApiName) {
                return entry.getLabel();
            }
        }

        return null;
    }

    public static List<String> getUserDivisionProductList(String userId) {
        List<String> productIds = new List<String>();
        if (userId != null) {
            List<String> divisionList = new List<String>();
            User user = [SELECT Id, Division_Code__c, Division_Code_2__c, Division_Code_3__c FROM User WHERE Id = :userId];
            
            if(string.isNotBlank(user.Division_Code__c)){
                List<String> divisionList1 = user.Division_Code__c.split(';');
                divisionList.addAll(divisionList1);
            }
            
            if(string.isNotBlank(user.Division_Code_2__c)){
                List<String> divisionList2 = user.Division_Code_2__c.split(';');
                divisionList.addAll(divisionList2);
            }
            
            if(string.isNotBlank(user.Division_Code_3__c)){
                List<String> divisionList3 = user.Division_Code_3__c.split(';');
                divisionList.addAll(divisionList3);
            }
            

            List<Product2> productList = [SELECT Id FROM Product2 WHERE Division__r.Name IN :divisionList];
            for (Product2 eachProduct:productList) {
                productIds.add(eachProduct.Id);
            }
        }

        return productIds;
    }

    public static String ns(Object val) {
        return val == null ? '' : String.valueOf(val);
    }

    /**
     * Sample Request Code -----------------------------------------------------
     */

    public static void sendSampleRequestEmail(Id sampleRequestId) {

        Sample_Request__c sampleRequest = [
            SELECT Id, Name, Additional_Email__c, Sales_HOD__r.Email,
                Sample_Request_Date__c, Sample_Expected_Date__c, Lead__r.Company,
                Lead__r.Name, Lead__r.Rossari_Company__r.Name, Lead__r.Lead_Number__c,
                Opportunity__r.Enquiry_Document_No__c, Opportunity__r.Account.Name,
                Customer_Name__r.Name
            FROM Sample_Request__c
            WHERE Id = :sampleRequestId
        ];

        List<Sample_Request_Line_Item__c> sampleRequestLineItems = [
            SELECT Id, Name, Product__c, Product__r.Name, Product__r.ProductCode, Product__r.Description,
                Sample_Qty_in_Kgs__c, Sales_Price__c
            FROM Sample_Request_Line_Item__c
            WHERE Sample_Request__c = :sampleRequestId AND Approval_Status__c = 'Approved'
        ];

        if (sampleRequestLineItems.isEmpty()) {
            System.debug('No Email sent cause sample request line item is empty');
            return;
        }

        
        List<String> recipientEmails = new List<String>();
        if (!String.isBlank(sampleRequest.Additional_Email__c)) {
            for (String e : sampleRequest.Additional_Email__c.split('[,;]')) {
                if (!String.isBlank(e)) recipientEmails.add(e.trim());
            }
        }
        if (sampleRequest.Sales_HOD__r != null && !String.isBlank(sampleRequest.Sales_HOD__r.Email)) {
            recipientEmails.add(sampleRequest.Sales_HOD__r.Email);
        }

        
        String productTable = 
            '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse;">' +
            '<tr style="background-color: #f2f2f2;">' +
            '<th>Name</th><th>Product Name</th><th>Product Code</th><th>Rate</th><th>Quantity</th></tr>';

        for (Sample_Request_Line_Item__c each : sampleRequestLineItems) {
            productTable += '<tr>' +
                            '<td>' + ns(each.Name) + '</td>' +
                            '<td>' + ns(each.Product__r.Name) + '</td>' +
                            '<td>' + ns(each.Product__r.ProductCode) + '</td>' +
                            '<td>' + ns(each.Sales_Price__c) + '</td>' +
                            '<td>' + ns(each.Sample_Qty_in_Kgs__c) + '</td>' +
                            '</tr>';
        }
        
        productTable += '</table>';

        
        String emailBody = ''
            + 'Dear Sir/Madam,<br/>'
            + 'Sample Request has been created. Please find details below for your reference.<br/><br/>'
            + '<b>Sample Request No:</b> ' + ns(sampleRequest.Name) + '<br/>';

        if (sampleRequest.Lead__r != null && !String.isBlank(sampleRequest.Lead__r.Lead_Number__c)) {
            emailBody += '<b>Lead Number:</b> ' + ns(sampleRequest.Lead__r.Lead_Number__c) + '<br/>';
        }
        if (sampleRequest.Lead__r != null && sampleRequest.Lead__r.Rossari_Company__r != null && !String.isBlank(sampleRequest.Lead__r.Rossari_Company__r.Name)) {
            emailBody += '<b>Customer Name:</b> ' + ns(sampleRequest.Lead__r.Company) + '<br/>';
        }
        if (sampleRequest.Opportunity__r != null && !String.isBlank(sampleRequest.Opportunity__r.Enquiry_Document_No__c)) {
            emailBody += '<b>Opportunity Number:</b> ' + ns(sampleRequest.Opportunity__r.Enquiry_Document_No__c) + '<br/>';
        }
        if (sampleRequest.Opportunity__r != null && sampleRequest.Opportunity__r.Account != null && !String.isBlank(sampleRequest.Opportunity__r.Account.Name)) {
            emailBody += '<b>Account Name:</b> ' + ns(sampleRequest.Opportunity__r.Account.Name) + '<br/>';
        }
        if (sampleRequest.Customer_Name__r != null && !String.isBlank(sampleRequest.Customer_Name__r.Name)) {
            emailBody += '<b>Customer Name:</b> ' + ns(sampleRequest.Customer_Name__r.Name) + '<br/>';
        }

        emailBody += '<br/><b>Requested Date:</b> ' + sampleRequest.Sample_Request_Date__c.format() + '<br/>';
        emailBody += '<b>Expected Date:</b> ' + sampleRequest.Sample_Expected_Date__c.format() + '<br/><br/>';
        emailBody += 'Below are the product details for your reference:<br/><br/>' + productTable;

        
        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
        List<ContentDocumentLink> docLinks = [
            SELECT ContentDocument.LatestPublishedVersionId, ContentDocument.Title
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :sampleRequestId
        ];

        if (!docLinks.isEmpty()) {
            List<Id> versionIds = new List<Id>();
            for (ContentDocumentLink link : docLinks) {
                versionIds.add(link.ContentDocument.LatestPublishedVersionId);
            }

            List<ContentVersion> versions = [
                SELECT Title, VersionData, FileExtension
                FROM ContentVersion
                WHERE Id IN :versionIds
            ];

            for (ContentVersion v : versions) {
                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                efa.setFileName(v.Title + '.' + v.FileExtension);
                efa.setBody(v.VersionData);
                attachments.add(efa);
            }
        }

        // Send email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(recipientEmails);
        mail.setSubject('Sample Request Created');
        mail.setHtmlBody(emailBody);
        mail.setWhatId(sampleRequest.Id);
        mail.setFileAttachments(attachments);

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }

    public static Boolean sendSampleRequestApprovalEmail(String sampleRequestId) {
    
        if (String.isBlank(sampleRequestId)) {
            System.debug('Sample Request Id is blank');
            return false;
        }
        
        
        Sample_Request__c sr = [
            SELECT Id, Name, Sales_HOD__r.Email, Lead__r.RecordType.Name,
                Lead__r.Business_Type__c, Lead__r.Rossari_Company__r.Name,
                Opportunity__r.Account.Business_Type__c, Opportunity__r.Account.Rossari_Company__r.Name,
                Customer_Name__r.Business_Type__c, Customer_Name__r.Rossari_Company__r.Name, Lead__r.Company,
                Lead__r.Name, Lead__r.Lead_Number__c,
                Opportunity__r.Enquiry_Document_No__c, Opportunity__r.Account.Name,
                Customer_Name__r.Name
            FROM Sample_Request__c
            WHERE Id = :sampleRequestId
            LIMIT 1
        ];

        
        List<Sample_Request_Line_Item__c> allLineItems = [
            SELECT Id, Name, Product__r.Name, Product__r.ProductCode, Sales_Price__c, Sample_Qty_in_Kgs__c
            FROM Sample_Request_Line_Item__c
            WHERE Sample_Request__c = :sr.Id
        ];

        
        if (sr.Sales_HOD__r == null || String.isBlank(sr.Sales_HOD__r.Email)){
            System.debug('Sales HOD is null or email is blank');
            return false;
        }

        
        Boolean isTargetCompany = (
            (sr.Lead__r != null && sr.Lead__r.RecordType != null && 
                (sr.Lead__r.RecordType.Name == 'Unitop/Tristar')) ||

            (sr.Opportunity__r != null && sr.Opportunity__r.Account != null && sr.Opportunity__r.Account.Rossari_Company__r != null &&
                (sr.Opportunity__r.Account.Rossari_Company__r.Name == 'Tristar Intermediates Private Limited' || 
                sr.Opportunity__r.Account.Rossari_Company__r.Name == 'Unitop Chemicals Private Limited')) ||

            (sr.Customer_Name__r != null && sr.Customer_Name__r.Rossari_Company__r != null &&
                (sr.Customer_Name__r.Rossari_Company__r.Name == 'Tristar Intermediates Private Limited' || 
                sr.Customer_Name__r.Rossari_Company__r.Name == 'Unitop Chemicals Private Limited'))
        );

        if (!isTargetCompany) {
            List<Sample_Request_Line_Item__c> toBeUpdated = new List<Sample_Request_Line_Item__c>(); 

            for (Sample_Request_Line_Item__c li : allLineItems) {
                li.Approval_Status__c = 'Approved';
                toBeUpdated.add(li);
            }

            UPDATE toBeUpdated;
            return false;
        }

        
        List<Sample_Request_Line_Item__c> matchedItems = new List<Sample_Request_Line_Item__c>();
        List<Sample_Request_Line_Item__c> approvedItems = new List<Sample_Request_Line_Item__c>();

        Boolean isDomestic = false;
        Boolean isExport = false;

        for (Sample_Request_Line_Item__c li : allLineItems) {
            Decimal qty = li.Sample_Qty_in_Kgs__c == null ? 0 : li.Sample_Qty_in_Kgs__c;

            isDomestic = (
                (sr.Lead__r != null && sr.Lead__r.Business_Type__c == 'Domestic') ||
                (sr.Opportunity__r != null && sr.Opportunity__r.Account != null && sr.Opportunity__r.Account.Business_Type__c == 'Domestic') ||
                (sr.Customer_Name__r != null && sr.Customer_Name__r.Business_Type__c == 'Domestic')
            );

            isExport = (
                (sr.Lead__r != null && sr.Lead__r.Business_Type__c == 'Export') ||
                (sr.Opportunity__r != null && sr.Opportunity__r.Account != null && sr.Opportunity__r.Account.Business_Type__c == 'Export') ||
                (sr.Customer_Name__r != null && sr.Customer_Name__r.Business_Type__c == 'Export')
            );

            if ((isDomestic && qty > 1) || (isExport && qty > 1)) {
                matchedItems.add(li);
            } else {
                approvedItems.add(li);
            }
        }

        List<Sample_Request_Line_Item__c> toBeUpdated = new List<Sample_Request_Line_Item__c>(); 

        for (Sample_Request_Line_Item__c li : matchedItems) {
            li.Approval_Status__c = 'Pending';
            toBeUpdated.add(li);
        }

        for (Sample_Request_Line_Item__c li : approvedItems) {
            li.Approval_Status__c = 'Approved';
            toBeUpdated.add(li);
        }

        UPDATE toBeUpdated;
        
        if (matchedItems.isEmpty()) {
            System.debug('No matched items found');
            return false;
        }

        
        String productTable =
            '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse;">' +
            '<tr style="background-color: #f2f2f2;">' +
            '<th>Name</th><th>Product Name</th><th>Product Code</th><th>Rate</th><th>Quantity</th></tr>';

        for (Sample_Request_Line_Item__c li : allLineItems) {
            productTable += '<tr>' +
                            '<td>' + ns(li.Name) + '</td>' +
                            '<td>' + ns(li.Product__r.Name) + '</td>' +
                            '<td>' + ns(li.Product__r.ProductCode) + '</td>' +
                            '<td>' + ns(li.Sales_Price__c) + '</td>' +
                            '<td>' + ns(li.Sample_Qty_in_Kgs__c) + '</td>' +
                            '</tr>';
        }

        productTable += '</table>';

        
        String emailBody = ''
            + 'Dear Sir/Madam,<br/>'
            + 'A new Sample Request has been created and needs your approval. Some products have higher quantities than usual.<br/><br/>'
            + '<b>Sample Request:</b> ' + ns(sr.Name) + '<br/><br/>';

        if (sr.Lead__r != null && !String.isBlank(sr.Lead__r.Lead_Number__c)) {
            emailBody += '<b>Lead Number:</b> ' + ns(sr.Lead__r.Lead_Number__c) + '<br/>';
        }
        if (sr.Lead__r != null && sr.Lead__r.Rossari_Company__r != null && !String.isBlank(sr.Lead__r.Rossari_Company__r.Name)) {
            emailBody += '<b>Customer Name:</b> ' + ns(sr.Lead__r.Company) + '<br/>';
        }
        if (sr.Opportunity__r != null && !String.isBlank(sr.Opportunity__r.Enquiry_Document_No__c)) {
            emailBody += '<b>Opportunity Number:</b> ' + ns(sr.Opportunity__r.Enquiry_Document_No__c) + '<br/>';
        }
        if (sr.Opportunity__r != null && sr.Opportunity__r.Account != null && !String.isBlank(sr.Opportunity__r.Account.Name)) {
            emailBody += '<b>Account Name:</b> ' + ns(sr.Opportunity__r.Account.Name) + '<br/>';
        }
        if (sr.Customer_Name__r != null && !String.isBlank(sr.Customer_Name__r.Name)) {
            emailBody += '<b>Customer Name:</b> ' + ns(sr.Customer_Name__r.Name) + '<br/>';
        }

        emailBody += '<br/><b>Buisness Type:</b> ' + (isDomestic ? 'Domestic' : 'Export') + '<br/><br/>';

        emailBody += '<b>URL:</b> <a href="' + Utility.baseUrl + '/lightning/n/Sample_Request_Approval" target="_blank">Click here</a><br/><br/>';
        
        emailBody += productTable;

            
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new List<String>{ sr.Sales_HOD__r.Email });
        mail.setSubject('Sample Request Requires Approval - ' + sr.Name);
        mail.setHtmlBody(emailBody);
        mail.setWhatId(sr.Id);

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

        return true;
    }



    /**
     * End of Sample Request Code ----------------------------------------
     */


    @AuraEnabled(Cacheable=true)
    public static List<Id> getUserAllowedProductIds(String leadRecordType) {
        System.debug('Getting allowed product IDs for leadRecordType: ' + leadRecordType);
        Id currentUserId = UserInfo.getUserId();
        List<Company_User__c> userCompanyList = null;
        List<String> salesOrgs = new List<String>();
        if (leadRecordType == 'RBL') {
            salesOrgs.add('1000');
            userCompanyList = [
                SELECT Division__c, Product_Group__c
                FROM Company_User__c
                WHERE User__c = :currentUserId AND (Company__r.Name = 'Rossari Biotech Limited' OR Company__r.SAP_Code__c = '1000')
            ];
        } else if (leadRecordType == 'Unitop/Tristar') {
            salesOrgs.add('3000');
            salesOrgs.add('4000');
            userCompanyList = [
                SELECT Division__c, Product_Group__c
                FROM Company_User__c
                WHERE User__c = :currentUserId AND (Company__r.Name = 'Tristar Intermediates Private Limited' OR Company__r.SAP_Code__c = '4000' OR Company__r.Name = 'Unitop Chemicals Private Limited' OR Company__r.SAP_Code__c = '3000')
            ];
        }

        if (userCompanyList == null) {
            if (!Test.isRunningTest()) {
                throw new AuraHandledException('User is not associated with any company');
            }
        }

        Set<Id> allowedDivisions = new Set<Id>();
        Set<Id> allowedProductGroups = new Set<Id>();

        for (Company_User__c userCompany : userCompanyList) {
            if (userCompany.Division__c != null) allowedDivisions.add(userCompany.Division__c);
            if (userCompany.Product_Group__c != null) allowedProductGroups.add(userCompany.Product_Group__c);
        }

        if (allowedDivisions.isEmpty()) return new List<Id>();

        List<Sales_Area__c> salesAreas = new List<Sales_Area__c>();

        if (!allowedProductGroups.isEmpty()) {
            salesAreas = [
                SELECT Item_Master__c
                FROM Sales_Area__c
                WHERE Sales_Organisation__r.Name IN :salesOrgs
                  AND Item_Master__r.Division__c IN :allowedDivisions
                  AND Item_Master__r.Item_Group__c IN :allowedProductGroups
            ];
        } else {
            salesAreas = [
                SELECT Item_Master__c
                FROM Sales_Area__c
                WHERE Sales_Organisation__r.Name IN :salesOrgs
                  AND Item_Master__r.Division__c IN :allowedDivisions
            ];
        }

        Set<Id> matchingProductIds = new Set<Id>();
        for (Sales_Area__c sa : salesAreas) {
            if (sa.Item_Master__c != null) {
                matchingProductIds.add(sa.Item_Master__c);
            }
        }

        return new List<Id>(matchingProductIds);
    }

    @AuraEnabled
    public static String getRecordTypeFromLead(String leadId) {
        if (String.isBlank(leadId)) return null;
            Lead ld = [SELECT RecordType.Name FROM Lead WHERE Id = :leadId LIMIT 1];
            if (ld != null && ld.RecordType != null && !String.isBlank(ld.RecordType.Name)) {
                return ld.RecordType.Name;
            }
            return null;
    }

    @AuraEnabled
    public static String getRecordTypeFromCustomerAccount(String accountId) {
        if (String.isBlank(accountId)) return null;
        Account acc = [SELECT Rossari_Company__r.Name FROM Account WHERE Id = :accountId LIMIT 1];

        String companyName = null;
        if (acc != null && acc.Rossari_Company__r != null) {
            companyName = acc.Rossari_Company__r.Name;
        }

        if (!String.isBlank(companyName)) {
            if (companyName == 'Rossari Biotech Limited') return 'RBL';
            if (companyName == 'Tristar Intermediates Private Limited' || companyName == 'Unitop Chemicals Private Limited') return 'Unitop/Tristar';
        }

        return null;
    }

    @AuraEnabled
    public static String getRecordTypeFromOpportunity(String opportunityId) {
        if (String.isBlank(opportunityId)) return null;
        Opportunity opp = [SELECT Account.Rossari_Company__r.Name FROM Opportunity WHERE Id = :opportunityId LIMIT 1];

        String companyName = null;
        if (opp != null && opp.Account != null && opp.Account.Rossari_Company__r != null) {
            companyName = opp.Account.Rossari_Company__r.Name;
        }

        if (!String.isBlank(companyName)) {
            if (companyName == 'Rossari Biotech Limited') return 'RBL';
            if (companyName == 'Tristar Intermediates Private Limited' || companyName == 'Unitop Chemicals Private Limited') return 'Unitop/Tristar';
        }

        return null;
    }

    @AuraEnabled
    public static String getRecordTypeFromQuote(String quoteId) {
        if (String.isBlank(quoteId)) return null;
        Quote opp = [SELECT Account.Rossari_Company__r.Name FROM Quote WHERE Id = :quoteId LIMIT 1];

        String companyName = null;
        if (opp != null && opp.Account != null && opp.Account.Rossari_Company__r != null) {
            companyName = opp.Account.Rossari_Company__r.Name;
        }

        if (!String.isBlank(companyName)) {
            if (companyName == 'Rossari Biotech Limited') return 'RBL';
            if (companyName == 'Tristar Intermediates Private Limited' || companyName == 'Unitop Chemicals Private Limited') return 'Unitop/Tristar';
        }

        return null;
    }

    @AuraEnabled
    public static String getRecordType(String sampleRequestId) {
        if (String.isBlank(sampleRequestId)) return null;
        try {
            Sample_Request__c sr = [
                SELECT Id,
                       Lead__c, Lead__r.RecordType.Name,
                       Customer_Name__c, Customer_Name__r.Rossari_Company__r.Name,
                       Opportunity__c, Opportunity__r.Account.Rossari_Company__r.Name
                FROM Sample_Request__c
                WHERE Id = :sampleRequestId
                LIMIT 1
            ];

            // 1) If Lead present and its RecordType.Name is available, return it
            if (sr.Lead__c != null && sr.Lead__r != null && sr.Lead__r.RecordType != null &&
                !String.isBlank(sr.Lead__r.RecordType.Name)) {
                return sr.Lead__r.RecordType.Name;
            }

            // 2) If Customer_Name__r present, check its Rossari company name
            String companyName = null;
            if (sr.Customer_Name__c != null && sr.Customer_Name__r != null &&
                sr.Customer_Name__r.Rossari_Company__r != null) {
                companyName = sr.Customer_Name__r.Rossari_Company__r.Name;
            }

            // 3) If no customer, try Opportunity -> Account -> Rossari_Company__r
            if (companyName == null && sr.Opportunity__c != null && sr.Opportunity__r != null &&
                sr.Opportunity__r.Account != null && sr.Opportunity__r.Account.Rossari_Company__r != null) {
                companyName = sr.Opportunity__r.Account.Rossari_Company__r.Name;
            }

            if (!String.isBlank(companyName)) {
                if (companyName == 'Rossari Biotech Limited') return 'RBL';
                if (companyName == 'Tristar Intermediates Private Limited' ||
                    companyName == 'Unitop Chemicals Private Limited') return 'Unitop/Tristar';
            }

            // Fallback: no matching information found
            return null;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    public class OpportunityHeaderWrapper {
        @AuraEnabled public String plantLocation;
        @AuraEnabled public String yashoCompany;
        @AuraEnabled public String paymentTerms;
        @AuraEnabled public String deliveryTerms;
        @AuraEnabled public String shipmentLeadTime;
        @AuraEnabled public String contact;
        @AuraEnabled public String accountId;
        @AuraEnabled public String billToParty;
        @AuraEnabled public String shipToParty;
        @AuraEnabled public String referenceNo;
        @AuraEnabled public Date referenceDate;
        @AuraEnabled public Date validFrom;
        @AuraEnabled public Date validTo;
        @AuraEnabled public String incoTerms;
        @AuraEnabled public String status;
        @AuraEnabled public Date createdDate;
        @AuraEnabled public String currencyCode;

        public OpportunityHeaderWrapper(Opportunity opp) {
  /*          this.plantLocation = opp.Dispatch_Plant_Location__c;
            this.yashoCompany = opp.Yasho_Company__c;
            this.accountId = opp.AccountId;
            this.paymentTerms = opp.Account.Payment_Terms__c;
            this.contact = opp.Contact__c;
            this.billToParty = opp.Bill_to_Party__c;
            this.shipToParty = opp.Ship_to_Party__c;
            this.incoTerms = opp.Inco_Terms__c;
            this.currencyCode = opp.CurrencyIsoCode;
        }		*/
        
    }
    
    }
}