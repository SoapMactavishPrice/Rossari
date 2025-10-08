public with sharing class OpportunitySampleRequestController {
    
    @AuraEnabled(cacheable=true)
    public static String getLeadInfo(String leadId) {
        Map<String, Object> result = new Map<String, Object>();
        
        // Get Opportunity safely
        Opportunity ld = [
            SELECT Id, Name, Account.Name, CurrencyIsoCode 
            FROM Opportunity 
            WHERE Id = :leadId 
            LIMIT 1
        ];
        
        result.put('lead', new Map<String, Object>{
            'Consignee_Name'   => ld.Account.Name,
            'CurrencyIsoCode'  => ld.CurrencyIsoCode
        });
        
        // Fetch related Product Interested records
        List<OpportunityLineItem> products = [
            SELECT Id, Product2Id, Product2.Name, 
                Product2.ProductCode, Product2.Description,
                Product2.Plant_Name__c, ProductCode,
                Quantity
            FROM OpportunityLineItem 
            WHERE OpportunityId = :leadId
            ORDER BY CreatedDate
        ];
        
        List<Map<String, Object>> productLines = new List<Map<String, Object>>();
        
        for (OpportunityLineItem prod : products) {
            // Only keep valid Product Ids
            String prodId = (prod.Product2Id != null) ? String.valueOf(prod.Product2Id) : null;
            if (prodId != null && prodId.length() != 15 && prodId.length() != 18) {
                prodId = null; // sanitize invalid Ids
            }
            
            productLines.add(new Map<String, Object>{
                'prodId'            => prodId,
                'Product'           => (prod.Product2 != null ? prod.Product2.Name : ''),
                'Product_Code'      => prod.ProductCode,
                'Description'       => (prod.Product2 != null ? prod.Product2.Description : ''),
                'Sample_Qty_in_Kgs' => prod.Quantity
            });
        }
        
        result.put('piList', productLines);
        
        return JSON.serialize(result);
    }

    
    @AuraEnabled(cacheable=true)
    public static List<Plant__c> getPlantOptions() {
        return [SELECT Id, Name, Plant_Name__c FROM Plant__c ORDER BY Name];
    }
    
   @AuraEnabled
public static String saveSample(String leadId, String sampleJs, 
                                List<Object> attachmentsFromUploadFile, 
                                String sampleLine) {
    try {
        System.debug('=== APEX SAVE STARTED ===');
        System.debug('Opportunity ID: ' + leadId);
        
        // Process sample request data
        Map<String, Object> sampleData = (Map<String, Object>)JSON.deserializeUntyped(sampleJs);
        
        // Get the sample category
        String sampleCategory = (String)sampleData.get('Sample_Category');
        Boolean isUnpaid = 'Unpaid'.equals(sampleCategory);
        
        Opportunity lead = [SELECT CurrencyIsoCode FROM Opportunity WHERE Id = :leadId LIMIT 1];
        
        Sample_Request__c sampleRequest = new Sample_Request__c();
        sampleRequest.Opportunity__c = leadId;
        sampleRequest.CurrencyIsoCode = lead.CurrencyIsoCode;
        
        // Set required fields safely
        if (sampleData.containsKey('Request_Date') && sampleData.get('Request_Date') != null) {
            sampleRequest.Sample_Request_Date__c = Date.valueOf((String)sampleData.get('Request_Date'));
        }
        
        if (sampleData.containsKey('Sample_Expected_Date') && sampleData.get('Sample_Expected_Date') != null) {
            sampleRequest.Sample_Expected_Date__c = Date.valueOf((String)sampleData.get('Sample_Expected_Date'));
        }

        if (sampleData.containsKey('salesHod') && sampleData.get('salesHod') != null) {
            sampleRequest.Sales_HOD__c = (String) sampleData.get('salesHod');
        }
        
        // Optional fields
        sampleRequest.Consignee_Name__c = (String)sampleData.get('Consignee_Name');
        sampleRequest.Additional_Email__c = (String)sampleData.get('Email');
        sampleRequest.Remark__c = (String)sampleData.get('Remark');
        sampleRequest.Status__c = 'Pending';
        sampleRequest.Customer_Code__c = (String)sampleData.get('Customer_Code__c');
        sampleRequest.Sample_Category__c = sampleCategory;
        
        String followUpDateStr = (String)sampleData.get('Sample_Follow_Up_Date');
        if (sampleData.containsKey('Sample_Follow_Up_Date') && String.isNotBlank(followUpDateStr)) {
            sampleRequest.Sample_Follow_Up_Date__c = Date.valueOf(followUpDateStr);
        }
        
        if (sampleData.containsKey('SAP_Doc_Type')) {
            sampleRequest.SAP_Sample_Document_Type__c = (String)sampleData.get('SAP_Doc_Type');
        }
        
        insert sampleRequest;
        System.debug('Sample_Category: ' + sampleCategory);
        System.debug('SAP_Doc_Type: ' + sampleData.get('SAP_Doc_Type'));
        System.debug('Is Unpaid Sample: ' + isUnpaid);
        
        // Process line items with Sales Price logic for Unpaid samples
        List<Sample_Request_Line_Item__c> lineItems = new List<Sample_Request_Line_Item__c>();
        
        Object rawLines = JSON.deserializeUntyped(sampleLine);
        if(rawLines instanceof List<Object>) {
            List<Object> tempList = (List<Object>) rawLines;
            for(Object o : tempList) {
                if(o instanceof Map<String, Object>) {
                    Map<String, Object> line = (Map<String, Object>) o;
                    
                    // Set Sales Price to 0 if sample category is Unpaid
                    Decimal salesPrice;
                    if(isUnpaid) {
                        salesPrice = 0;
                        System.debug('Setting Sales Price to 0 for Unpaid sample');
                    } else {
                        // For paid samples, use the provided value or null
                        salesPrice = line.containsKey('Sales_Price') && String.isNotEmpty(String.valueOf(line.get('Sales_Price')))
                            ? Decimal.valueOf(String.valueOf(line.get('Sales_Price')))
                            : null;
                        System.debug('Using provided Sales Price: ' + salesPrice);
                    }
                    
                    lineItems.add(new Sample_Request_Line_Item__c(
                        Sample_Request__c = sampleRequest.Id,
                        Product__c = (String)line.get('prodId'),
                        Sample_Qty_in_Kgs__c = line.containsKey('Sample_Qty_in_Kgs') && String.isNotEmpty(String.valueOf(line.get('Sample_Qty_in_Kgs')))
                            ? Decimal.valueOf(String.valueOf(line.get('Sample_Qty_in_Kgs')))
                            : 0,
                        CurrencyIsoCode = lead.CurrencyIsoCode,
                        Sales_Price__c = salesPrice
                    ));
                }
            }
        }
        
        if(!lineItems.isEmpty()) {
            System.debug('Line items to insert: ' + lineItems.size());
            insert lineItems;
            
            // Debug inserted line items
            for(Sample_Request_Line_Item__c item : lineItems) {
                System.debug('Inserted Line Item - Product: ' + item.Product__c + ', Sales Price: ' + item.Sales_Price__c);
            }
        }
        
        // Process file attachments with enhanced logging
        if(attachmentsFromUploadFile != null && !attachmentsFromUploadFile.isEmpty()) {
            System.debug('Processing ' + attachmentsFromUploadFile.size() + ' attachments');
            
            List<ContentVersion> contentVersions = new List<ContentVersion>();
            
            for(Object fileObj : attachmentsFromUploadFile) {
                // if(fileObj instanceof Map<String, Object>) {
                    Map<Object, Object> file = (Map<Object, Object>)fileObj;
                    System.debug('Processing file: ' + file.get('filename'));
                    
                    // Validate base64 data
                    String base64Data = (String)file.get('base64');
                    if(base64Data == null || base64Data.length() < 100) {
                        System.debug('Invalid base64 data for file: ' + file.get('filename'));
                        continue; // Skip this file but continue with others
                    }
                    
                    try {
                        ContentVersion cv = new ContentVersion(
                            Title = (String)file.get('filename'),
                            PathOnClient = (String)file.get('filename'),
                            VersionData = EncodingUtil.base64Decode(base64Data)
                        );
                        contentVersions.add(cv);
                        System.debug('Created ContentVersion for file: ' + file.get('filename'));
                    } catch(Exception e) {
                        System.debug('Error creating ContentVersion for file: ' + file.get('filename') + 
                                     ' Error: ' + e.getMessage());
                    }
                // }
            }
            
            if(!contentVersions.isEmpty()) {
                System.debug('ContentVersions to insert: ' + contentVersions.size());
                insert contentVersions;
                System.debug('ContentVersions inserted successfully');
                
                // Get the ContentDocumentIds
                List<ContentVersion> insertedCVs = [
                    SELECT ContentDocumentId 
                    FROM ContentVersion 
                    WHERE Id IN :contentVersions
                ];
                System.debug('Inserted ContentVersions: ' + insertedCVs.size());
                
                List<ContentDocumentLink> docLinks = new List<ContentDocumentLink>();
                for(ContentVersion cv : insertedCVs) {
                    docLinks.add(new ContentDocumentLink(
                        ContentDocumentId = cv.ContentDocumentId,
                        LinkedEntityId = sampleRequest.Id,
                        ShareType = 'V',
                        Visibility = 'AllUsers'
                    ));
                    System.debug('Created ContentDocumentLink for ContentDocumentId: ' + cv.ContentDocumentId);
                }
                
                if(!docLinks.isEmpty()) {
                    System.debug('ContentDocumentLinks to insert: ' + docLinks.size());
                    insert docLinks;
                    System.debug('ContentDocumentLinks inserted successfully');
                }
            }
        }
        
        System.debug('=== APEX SAVE COMPLETED ===');
        Utility.sendSampleRequestEmail(sampleRequest.Id);
        return sampleRequest.Id;
        
    } catch(Exception e) {
        System.debug('=== APEX SAVE ERROR ===');
        System.debug('Error message: ' + e.getMessage());
        System.debug('Line number: ' + e.getLineNumber());
        System.debug('Stack trace: ' + e.getStackTraceString());
        throw new AuraHandledException('Error creating sample request: ' + e.getMessage() + 
                                       ' [Line: ' + e.getLineNumber() + ']');
    }
}
    
    @AuraEnabled(cacheable=true)
    public static List<Sample_Request_Line_Item__c> getExistingLineItems(String recordId) {
        return [
            SELECT Id, Product__c, Product__r.Name, Product__r.ProductCode, Product__r.Description,
            Sample_Request_To_Plant__c, Sample_Qty_in_Kgs__c,Status__c
            FROM Sample_Request_Line_Item__c
            WHERE Sample_Request__c = :recordId
            ORDER BY CreatedDate
        ];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getStatusPicklistValues() {
        List<String> statusValues = new List<String>();
        Schema.DescribeFieldResult fieldResult = Sample_Request_Line_Item__c.Status__c.getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
        
        for (Schema.PicklistEntry entry : picklistEntries) {
            if (entry.isActive()) {
                statusValues.add(entry.getLabel());
            }
        }
        return statusValues;
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, List<String>> getPicklistDependencies() {
        Map<String, List<String>> result = new Map<String, List<String>>();
        
        // Sample Category Picklist
        Schema.DescribeFieldResult categoryField = Sample_Request__c.Sample_Category__c.getDescribe();
        List<String> categoryOptions = new List<String>();
        for (Schema.PicklistEntry entry : categoryField.getPicklistValues()) {
            if (entry.isActive()) {
                categoryOptions.add(entry.getValue());
            }
        }
        result.put('Sample_Category__c', categoryOptions);
        
        // SAP Sample Document Type Picklist
        Schema.DescribeFieldResult docTypeField = Sample_Request__c.SAP_Sample_Document_Type__c.getDescribe();
        List<String> docTypeOptions = new List<String>();
        for (Schema.PicklistEntry entry : docTypeField.getPicklistValues()) {
            if (entry.isActive()) {
                docTypeOptions.add(entry.getValue());
            }
        }
        result.put('SAP_Sample_Document_Type__c', docTypeOptions);
        
        return result;
    }
    
    
    
    @AuraEnabled
    public static void saveLineItems(String recordId, String lineItems) {
        List<Sample_Request_Line_Item__c> itemsToUpsert = new List<Sample_Request_Line_Item__c>();
        
        // First deserialize into a generic List<Object>
        List<Object> lineItemsData = (List<Object>) JSON.deserializeUntyped(lineItems);
        
        // Then process each item
        for (Object itemObj : lineItemsData) {
            // Convert each item to a Map
            Map<String, Object> itemData = (Map<String, Object>) itemObj;
            
            // Safely handle quantity conversion
            Decimal quantity;
            try {
                // Handle both String and Decimal inputs
                if (itemData.get('quantity') instanceof String) {
                    quantity = Decimal.valueOf((String)itemData.get('quantity'));
                } else {
                    quantity = (Decimal)itemData.get('quantity');
                }
            } catch(Exception e) {
                quantity = 0; // Default value if conversion fails
            }
            
            String status = (String) itemData.get('status');
            
            Sample_Request_Line_Item__c item = new Sample_Request_Line_Item__c(
                Sample_Request__c = recordId,
                Product__c = (String) itemData.get('productId'),
                Sample_Request_To_Plant__c = (String) itemData.get('plantId'),
                Sample_Qty_in_Kgs__c = quantity,
                Status__c = status
            );
            
            
            // Handle existing records
            if (itemData.get('id') != null) {
                item.Id = (String) itemData.get('id');
            }
            
            itemsToUpsert.add(item);
        }
        
        if (!itemsToUpsert.isEmpty()) {
            try {
                upsert itemsToUpsert;
            } catch(DmlException e) {
                throw new AuraHandledException('Error saving line items: ' + e.getMessage());
            }
        }
    }
    
    public static void updateParentStatus(Set<Id> lineItemIds) {
        Set<Id> parentIds = new Set<Id>();
        
        // Query line items to get related parent IDs and Status__c values
        List<Sample_Request_Line_Item__c> lineItems = [
            SELECT Id, Sample_Request__c, Status__c
            FROM Sample_Request_Line_Item__c
            WHERE Id IN :lineItemIds
        ];
        
        // Only collect parentIds where line item Status__c is not null or empty
        for (Sample_Request_Line_Item__c item : lineItems) {
            if (String.isNotBlank(item.Status__c)) {
                parentIds.add(item.Sample_Request__c);
            }
        }
        
        if (!parentIds.isEmpty()) {
            List<Sample_Request__c> requestsToUpdate = [
                SELECT Id, Status__c
                FROM Sample_Request__c
                WHERE Id IN :parentIds AND Status__c != 'Completed'
            ];
            
            for (Sample_Request__c sr : requestsToUpdate) {
                if (sr.Status__c == 'Pending') {
                    sr.Status__c = 'In Progress';
                }
            }
            
            if (!requestsToUpdate.isEmpty()) {
                update requestsToUpdate;
            }
        }
    }
    
    @AuraEnabled
    public static Decimal getUnitPrice(Id productId) {
        List<PricebookEntry> entries = [
            SELECT UnitPrice
            FROM PricebookEntry
            WHERE Product2Id = :productId
            AND IsActive = true
            AND Pricebook2.IsStandard = true
            LIMIT 1
        ];
        
        return entries.isEmpty() ? 0 : entries[0].UnitPrice;
    }
    
    
    @AuraEnabled
    public static void deleteLineItem(String lineItemId) {
        try {
            Sample_Request_Line_Item__c itemToDelete = [SELECT Id FROM Sample_Request_Line_Item__c WHERE Id = :lineItemId LIMIT 1];
            delete itemToDelete;
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting line item: ' + e.getMessage());
        }
    }
    
    
    @AuraEnabled(cacheable=true)
    public static String getCurrentUserZone() {
        return [SELECT Zone__c FROM User WHERE Id = :UserInfo.getUserId()].Zone__c;
    }

    
}