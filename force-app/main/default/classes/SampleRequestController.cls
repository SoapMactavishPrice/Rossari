public with sharing class SampleRequestController {
    
    @AuraEnabled(cacheable=true)
    public static String getLeadInfo(String leadId) {
        Map<String, Object> result = new Map<String, Object>();
        
        Lead ld = [SELECT Id, Name, Company, CurrencyIsoCode FROM Lead WHERE Id = :leadId LIMIT 1];
        result.put('lead', new Map<String, Object>{
            'Consignee_Name' => ld.Company,
                'CurrencyIsoCode' => ld.CurrencyIsoCode
                });
        
        List<Product_Interested__c> products = [
            SELECT Id, Product__c, Product__r.Name, 
            Product__r.ProductCode, Product__r.Description,
            Product__r.Plant_Name__c, Product_Code__c,
            Quantity_in_Kgs__c
            FROM Product_Interested__c 
            WHERE Lead__c = :leadId AND New_Product__c = false
            ORDER BY CreatedDate
        ];
        
        List<Map<String, Object>> productLines = new List<Map<String, Object>>();
        for(Product_Interested__c prod : products) {
            productLines.add(new Map<String, Object>{
                'prodId' => prod.Product__c,
                    'Product' => prod.Product__r != null ? prod.Product__r.Name : '',
                        'Product_Code' => prod.Product_Code__c,
                        'Description' => prod.Product__r != null ? prod.Product__r.Description : '',
                            'productPlant' => prod.Product__r != null ? prod.Product__r.Plant_Name__c : '',
                                'Sample_Qty_in_Kgs' => prod.Quantity_in_Kgs__c
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
                                            System.debug('Lead ID: ' + leadId);
                                            
                                            // Process sample request data
                                            Map<String, Object> sampleData = (Map<String, Object>)JSON.deserializeUntyped(sampleJs);
                                            
                                            Lead lead = [SELECT CurrencyIsoCode, Country FROM Lead WHERE Id = :leadId LIMIT 1];
                                            
                                            Sample_Request__c sampleRequest = new Sample_Request__c();
                                            sampleRequest.Lead__c = leadId;
                                            sampleRequest.CurrencyIsoCode = lead.CurrencyIsoCode;
                                            
                                            // Set required fields safely
                                            if (sampleData.containsKey('Request_Date') && sampleData.get('Request_Date') != null) {
                                                sampleRequest.Sample_Request_Date__c = Date.valueOf((String)sampleData.get('Request_Date'));
                                            }
                                            
                                            if (sampleData.containsKey('Sample_Expected_Date') && sampleData.get('Sample_Expected_Date') != null) {
                                                sampleRequest.Sample_Expected_Date__c = Date.valueOf((String)sampleData.get('Sample_Expected_Date'));
                                            }
                                            
                                            // Optional fields
                                            sampleRequest.Consignee_Name__c = (String)sampleData.get('Consignee_Name');
                                            sampleRequest.Send_Email_To_Plant__c = (Boolean)sampleData.get('Send_Email_To_Plant');
                                            sampleRequest.Remark__c = (String)sampleData.get('Remark');
                                            sampleRequest.Status__c = 'Pending';
                                            
                                            String followUpDateStr = (String)sampleData.get('Sample_Follow_Up_Date');
                                            if (sampleData.containsKey('Sample_Follow_Up_Date') && String.isNotBlank(followUpDateStr)) {
                                                sampleRequest.Sample_Follow_Up_Date__c = Date.valueOf(followUpDateStr);
                                            }
                                            
                                            System.debug('Sample Request before insert: ' + sampleRequest);
                                            insert sampleRequest;
                                            System.debug('Sample Request ID after insert: ' + sampleRequest.Id);
                                            
                                            // Process line items
                                            List<Sample_Request_Line_Item__c> lineItems = new List<Sample_Request_Line_Item__c>();
                                            
                                            Object rawLines = JSON.deserializeUntyped(sampleLine);
                                            if(rawLines instanceof List<Object>) {
                                                List<Object> tempList = (List<Object>) rawLines;
                                                for(Object o : tempList) {
                                                    if(o instanceof Map<String, Object>) {
                                                        Map<String, Object> line = (Map<String, Object>) o;
                                                        
                                                        lineItems.add(new Sample_Request_Line_Item__c(
                                                            Sample_Request__c = sampleRequest.Id,
                                                            Product__c = (String)line.get('prodId'),
                                                            Sample_Request_To_Plant__c = (String)line.get('Sample_Request_To_Plant'),
                                                            Sample_Qty_in_Kgs__c = line.containsKey('Sample_Qty_in_Kgs') && String.isNotEmpty(String.valueOf(line.get('Sample_Qty_in_Kgs')))
                                                            ? Decimal.valueOf(String.valueOf(line.get('Sample_Qty_in_Kgs')))
                                                            : 0,
                                                            CurrencyIsoCode = lead.CurrencyIsoCode
                                                        ));
                                                    }
                                                }
                                            }
                                            
                                            if(!lineItems.isEmpty()) {
                                                System.debug('Line items to insert: ' + lineItems.size());
                                                insert lineItems;
                                            }
                                            
                                            // Process file attachments with enhanced logging
                                            if(attachmentsFromUploadFile != null && !attachmentsFromUploadFile.isEmpty()) {
                                                System.debug('Processing ' + attachmentsFromUploadFile.size() + ' attachments');
                                                
                                                List<ContentVersion> contentVersions = new List<ContentVersion>();
                                                
                                                for(Object fileObj : attachmentsFromUploadFile) {
                                                    if(fileObj instanceof Map<String, Object>) {
                                                        Map<String, Object> file = (Map<String, Object>)fileObj;
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
                                                    }
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
    public static void deleteLineItem(String lineItemId) {
        try {
            Sample_Request_Line_Item__c itemToDelete = [SELECT Id FROM Sample_Request_Line_Item__c WHERE Id = :lineItemId LIMIT 1];
            delete itemToDelete;
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting line item: ' + e.getMessage());
        }
    }
    
}