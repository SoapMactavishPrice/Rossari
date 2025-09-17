public with sharing class AccountSampleRequestController {
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getAccountInfo(String accountId) {
        Map<String, Object> result = new Map<String, Object>();
        
        Account acc = [SELECT Id, Name, CurrencyIsoCode FROM Account WHERE Id = :accountId LIMIT 1];
        result.put('account', new Map<String, Object>{
            'Name' => acc.Name,
                'CurrencyIsoCode' => acc.CurrencyIsoCode
                });
        
        return result;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Plant__c> getPlantOptions() {
        return [SELECT Id, Name, Plant_Name__c FROM Plant__c ORDER BY Name];
    }
    
    @AuraEnabled
    public static String saveSample(String accountId, String sampleJs, 
                                    List<Map<String, Object>> attachmentsFromUploadFile, 
                                    String sampleLine) {
                                        // try {
                                        // Deserialize the sample data
                                        Map<String, Object> sampleData = (Map<String, Object>)JSON.deserializeUntyped(sampleJs);
                                        
                                        // Create the Sample_Request__c record
                                        Sample_Request__c sampleRequest = new Sample_Request__c(
                                            Customer_Name__c = accountId,
                                            Sample_Request_Date__c = Date.valueOf((String)sampleData.get('Request_Date')),
                                            Sample_Expected_Date__c = Date.valueOf((String)sampleData.get('Sample_Expected_Date')),
                                            Consignee_Name__c = (String)sampleData.get('Consignee_Name'),
                                            Remark__c = (String)sampleData.get('Remark'),
                                            Customer_Code__c = String.valueOf(sampleData.get('Customer_Code__c'))

										//	Zone__c = (String)sampleData.get('Zone__c')
                                            
                                        );
                                        
                                        if (sampleData.containsKey('Sample_Follow_Up_Date') && sampleData.get('Sample_Follow_Up_Date') != null && (String)sampleData.get('Sample_Follow_Up_Date') != '') {
                                            sampleRequest.Sample_Follow_Up_Date__c = Date.valueOf((String)sampleData.get('Sample_Follow_Up_Date'));
                                        }
                                        
                                         if (sampleData.containsKey('Sample_Category')) {
                                                sampleRequest.Sample_Category__c = (String)sampleData.get('Sample_Category');
                                            }
                                            if (sampleData.containsKey('SAP_Doc_Type')) {
                                                sampleRequest.SAP_Sample_Document_Type__c = (String)sampleData.get('SAP_Doc_Type');
                                            }
                                        
                                        insert sampleRequest;
                                        
                                        // Process line items
                                        List<Object> lineItems = (List<Object>)JSON.deserializeUntyped(sampleLine);
                                        List<Sample_Request_Line_Item__c> srlItems = new List<Sample_Request_Line_Item__c>();
                                        
                                        for (Object itemObj : lineItems) {
                                            Map<String, Object> item = (Map<String, Object>)itemObj;
                                            
                                            // Handle decimal conversion safely
                                            Decimal sampleQty = null;
                                            if (item.get('Sample_Qty_in_Kgs') != null) {
                                                if (item.get('Sample_Qty_in_Kgs') instanceof Decimal) {
                                                    sampleQty = (Decimal)item.get('Sample_Qty_in_Kgs');
                                                } else if (item.get('Sample_Qty_in_Kgs') instanceof String) {
                                                    sampleQty = Decimal.valueOf((String)item.get('Sample_Qty_in_Kgs'));
                                                } else if (item.get('Sample_Qty_in_Kgs') instanceof Integer) {
                                                    sampleQty = Decimal.valueOf((Integer)item.get('Sample_Qty_in_Kgs'));
                                                }
                                            }
                                            
                                            srlItems.add(new Sample_Request_Line_Item__c(
                                                Sample_Request__c = sampleRequest.Id,
                                                Product__c = (String)item.get('prodId'),
                                                Sample_Qty_in_Kgs__c = sampleQty,
                                                CurrencyIsoCode = (String)sampleData.get('CurrencyIsoCode'),
                                                 Sales_Price__c = item.containsKey('Sales_Price') && String.isNotEmpty(String.valueOf(item.get('Sales_Price')))
                                                            ? Decimal.valueOf(String.valueOf(item.get('Sales_Price')))
                                                            : null
                                            ));
                                        }
                                        
                                        if (!srlItems.isEmpty()) {
                                            insert srlItems;
                                        }
                                        
                                        // Process file attachments - optimized version using FirstPublishLocationId
                                        if (attachmentsFromUploadFile != null && !attachmentsFromUploadFile.isEmpty()) {
                                            List<ContentVersion> contentVersions = new List<ContentVersion>();
                                            
                                            for (Map<String, Object> file : attachmentsFromUploadFile) {
                                                // Validate required file fields
                                                if (file.get('filename') == null || file.get('base64') == null) {
                                                    continue; // Skip invalid files
                                                }
                                                
                                                contentVersions.add(new ContentVersion(
                                                    Title = (String)file.get('filename'),
                                                    PathOnClient = (String)file.get('filename'),
                                                    VersionData = EncodingUtil.base64Decode((String)file.get('base64')),
                                                    FirstPublishLocationId = sampleRequest.Id // This automatically creates the link
                                                ));
                                            }
                                            
                                            if (!contentVersions.isEmpty()) {
                                                insert contentVersions;
                                            }
                                        }
                                        
                                        return sampleRequest.Id;
                                        
                                        // } catch(Exception e) {
                                        //     throw new AuraHandledException('Error creating sample request: ' + e.getMessage() + 
                                        //                                   ' [Line: ' + e.getLineNumber() + ']');
                                        // }
                                    }
    
    // Additional method to handle file uploads separately if needed
    @AuraEnabled
    public static void uploadFiles(String parentId, List<Map<String, Object>> files) {
        try {
            if (files == null || files.isEmpty()) return;
            
            List<ContentVersion> contentVersions = new List<ContentVersion>();
            
            for (Map<String, Object> file : files) {
                contentVersions.add(new ContentVersion(
                    Title = (String)file.get('filename'),
                    PathOnClient = (String)file.get('filename'),
                    VersionData = EncodingUtil.base64Decode((String)file.get('base64')),
                    FirstPublishLocationId = parentId
                ));
            }
            
            insert contentVersions;
        } catch(Exception e) {
            throw new AuraHandledException('Error uploading files: ' + e.getMessage());
        }
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
    
    @AuraEnabled(cacheable=true)
public static String getCurrentUserZone() {
    return [SELECT Zone__c FROM User WHERE Id = :UserInfo.getUserId()].Zone__c;
}

}