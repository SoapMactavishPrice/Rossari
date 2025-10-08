public with sharing class Utility {
    
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

    public static void sendSampleRequestEmail(Id sampleRequestId) {

        Sample_Request__c sampleRequest = [
            SELECT Id, Name, Additional_Email__c, Sales_HOD__r.Email, Sample_Request_Date__c, Sample_Expected_Date__c
            FROM Sample_Request__c
            WHERE Id = :sampleRequestId
        ];

        List<Sample_Request_Line_Item__c> sampleRequestLineItems = [
            SELECT Id, Name, Product__c, Product__r.Name, Product__r.ProductCode, Product__r.Description,
                Sample_Qty_in_Kgs__c, Sales_Price__c
            FROM Sample_Request_Line_Item__c
            WHERE Sample_Request__c = :sampleRequestId
        ];

        List<String> recipientEmails = new List<String>();
        if (!String.isBlank(sampleRequest.Additional_Email__c)) {
            List<String> temp = sampleRequest.Additional_Email__c.split('[,;]');
            for (String e : temp) {
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

        String emailBody =
            '<b>Sample Request No:</b> ' + sampleRequest.Name + '<br/>' +
            '<b>Requested Date:</b> ' + sampleRequest.Sample_Request_Date__c.format() + '<br/>' +
            '<b>Expected Date:</b> ' + sampleRequest.Sample_Expected_Date__c.format() + '<br/><br/>' +
            '<b>Requested Product Records:</b><br/>' +
            'Below are the product details for your reference:<br/><br/>' +
            productTable;

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

            // Get actual file content
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

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(recipientEmails);
        mail.setSubject('Sample Request Details - ' + sampleRequest.Name);
        mail.setHtmlBody(emailBody);
        mail.setWhatId(sampleRequest.Id);
        mail.setFileAttachments(attachments);

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
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