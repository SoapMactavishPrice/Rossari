public class GetInventory_FromSAP {
    
    // Wrapper class to hold inventory data
    public class InventoryData {
        @AuraEnabled public String materialNumber {get; set;}
        @AuraEnabled public String materialDescription {get; set;}
        @AuraEnabled public String batchNumber {get; set;}
        @AuraEnabled public String plant {get; set;}
        @AuraEnabled public String storageLocation {get; set;}
        @AuraEnabled public String storageLocationDescription {get; set;}
        @AuraEnabled public Decimal unrestrictedUseStock {get; set;}
        @AuraEnabled public String baseUnitOfMeasure {get; set;}
        @AuraEnabled public Date dateOfManufacture {get; set;}
        @AuraEnabled public Date shelfLifeExpirationDate {get; set;}
        @AuraEnabled public String materialType {get; set;}
        @AuraEnabled public String materialGroup {get; set;}
        @AuraEnabled public String productHierarchy {get; set;}
        @AuraEnabled public String productHierarchyText {get; set;}
        @AuraEnabled public Decimal valueOfUnrestrictedStock {get; set;}
        @AuraEnabled public String currencyKey {get; set;}
    }
    
    // @future(callout=true)
    @auraEnabled
    public static List<InventoryData> fetchInventoryData(String materialNumber) {
        try {
            Http http = new Http();
            HttpRequest req = new HttpRequest();

            // Build the endpoint with filter
            String baseUrl = System.Label.SAP_Inventory_API; 
            // String filter = 'MaterialNumber eq \'170000000003\' and Plant eq \' \' and MaterialType eq \'ZFG\'';
            String filter = 'MaterialNumber eq \''+materialNumber+'\' and Plant eq \' \' and MaterialType eq \'ZFG\'';
            String endpoint = baseUrl + EncodingUtil.urlEncode(filter, 'UTF-8');

            System.debug('Final SAP URL: ' + endpoint);

            // Get credentials from Custom Labels
            String username = label.CreateQuotation_ToSAP_Username;
            String password = label.CreateQuotation_ToSAP_Pass;
            
            // Basic Authentication
            Blob headerValue = Blob.valueOf(username + ':' + password);
            String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
            
            // Set up the request
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setHeader('Authorization', authorizationHeader);
            req.setHeader('Accept', 'application/xml');
            req.setHeader('Content-Type', 'application/xml');
            req.setTimeout(120000);
            
            // Debug the request for troubleshooting
            System.debug('Request Headers: ' + req.toString());
            
            HttpResponse res = http.send(req);
            
            if(res.getStatusCode() == 200) {
                String xmlResponse = res.getBody();
                // System.debug('XML Response: ' + xmlResponse);
                
                // Parse the XML response
                List<InventoryData> inventoryList = parseInventoryXML(xmlResponse);
                
                // Process the inventory data as needed
                for(InventoryData inv : inventoryList) {
                    // System.debug('Material: ' + inv.materialNumber + ', Batch: ' + inv.batchNumber + ', Stock: ' + inv.unrestrictedUseStock + ' ' + inv.baseUnitOfMeasure);
                    // Add your processing logic here
                }

                System.debug('Inventory List: ' + inventoryList);
                
                return inventoryList;
            } else {
                System.debug('Error: ' + res.getStatus() + ' Body: ' + res.getBody());
                return null;
            }
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage() + ' Stack Trace: ' + e.getStackTraceString());
            return null;
        }
    }
    
    private static List<InventoryData> parseInventoryXML(String xmlString) {
        List<InventoryData> inventoryList = new List<InventoryData>();
        
        try {
            // Parse the XML string
            Dom.Document doc = new Dom.Document();
            doc.load(xmlString);
            
            // Get the root element (InventorySet)
            Dom.XmlNode root = doc.getRootElement();
            
            // Get all Inventory nodes
            for(Dom.XmlNode invNode : root.getChildElements()) {
                if(invNode.getName() == 'Inventory') {
                    InventoryData inv = new InventoryData();
                    
                    // Read all child elements of Inventory
                    for(Dom.XmlNode field : invNode.getChildElements()) {
                        String fieldName = field.getName();
                        String fieldValue = field.getText();
                        
                        // Map XML fields to wrapper class fields
                        if(fieldName == 'MaterialNumber') inv.materialNumber = fieldValue;
                        else if(fieldName == 'MaterialDescription') inv.materialDescription = fieldValue;
                        else if(fieldName == 'BatchNumber') inv.batchNumber = fieldValue;
                        else if(fieldName == 'Plant') inv.plant = fieldValue;
                        else if(fieldName == 'StorageLocation') inv.storageLocation = fieldValue;
                        else if(fieldName == 'StorageLocationDescription') inv.storageLocationDescription = fieldValue;
                        else if(fieldName == 'UnrestrictedUseStock') inv.unrestrictedUseStock = String.isNotBlank(fieldValue) ? Decimal.valueOf(fieldValue) : 0;
                        else if(fieldName == 'BaseUnitofMeasure') inv.baseUnitOfMeasure = fieldValue;
                        else if(fieldName == 'DateofManufacture') inv.dateOfManufacture = String.isNotBlank(fieldValue) ? Date.valueOf(fieldValue) : null;
                        else if(fieldName == 'ShelfLifeExpirationDate') inv.shelfLifeExpirationDate = String.isNotBlank(fieldValue) ? Date.valueOf(fieldValue) : null;
                        else if(fieldName == 'MaterialType') inv.materialType = fieldValue;
                        else if(fieldName == 'MaterialGroup') inv.materialGroup = fieldValue;
                        else if(fieldName == 'ProductHierarchy') inv.productHierarchy = fieldValue;
                        else if(fieldName == 'ProductHierarchyText') inv.productHierarchyText = fieldValue;
                        else if(fieldName == 'ValueofUnrestrictedStock') inv.valueOfUnrestrictedStock = String.isNotBlank(fieldValue) ? Decimal.valueOf(fieldValue) : 0;
                        else if(fieldName == 'CurrencyKey') inv.currencyKey = fieldValue;
                    }
                    
                    inventoryList.add(inv);

                    System.debug('Inventory Data: ' + inv);
                }
            }
        } catch(Exception e) {
            System.debug('Error parsing XML: ' + e.getMessage() + ' Stack Trace: ' + e.getStackTraceString());
        }
        
        return inventoryList;
    }
}