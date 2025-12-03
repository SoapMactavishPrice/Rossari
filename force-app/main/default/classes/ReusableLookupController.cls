public with sharing class ReusableLookupController {
    @AuraEnabled
    public static List<ResultWrapper> fetchRecords(SearchWrapper inputWrapper, string currencyCode) {
        try {
            // Validate input parameters
            if (inputWrapper == null) {
                throw new AuraHandledException('Input parameters cannot be null');
            }
            
            if (String.isBlank(inputWrapper.objectApiName)) {
                throw new AuraHandledException('Object API name is required');
            }
            
            System.debug('inputWrapper --> ' + inputWrapper);
            System.debug('currencyCode --> ' + currencyCode);
            System.debug('leadRecordType --> ' + inputWrapper.leadRecordType);
            System.debug('businessType --> ' + inputWrapper.businessType);
            
            Boolean isPricebookEntry = inputWrapper.objectApiName == 'PricebookEntry';
            Boolean isProduct = inputWrapper.objectApiName == 'Product2';
            
            List<String> productIds = new List<String>();

            // Get product IDs with both parameters
            if (inputWrapper.leadRecordType != null) {
                // Use businessType if provided, otherwise default to 'Domestic'
                String businessTypeToUse = String.isNotBlank(inputWrapper.businessType) ? inputWrapper.businessType : 'Domestic';
                System.debug('Calling Utility.getUserAllowedProductIds with leadRecordType: ' + inputWrapper.leadRecordType + ', businessType: ' + businessTypeToUse);
                
                productIds = Utility.getUserAllowedProductIds(inputWrapper.leadRecordType, businessTypeToUse);
                System.debug('Retrieved ' + productIds.size() + ' product IDs');
            }
            
            // Step 1: Compose the SELECT clause
            String fieldsToQuery;
            if (isPricebookEntry) {
                // Fields for PricebookEntry
                fieldsToQuery = 'SELECT Id, Product2Id, UnitPrice, Product2.Name, Product2.ProductCode, ' +
                               'Product2.Family, Product2.Plant_Name__c, Product2.Description, ' +
                               'CurrencyIsoCode ' +
                               'FROM PricebookEntry';
            } else if (isProduct) {
                // Fields for Product2
                fieldsToQuery = 'SELECT Id, Name, ProductCode, Description, ' +
                               'Plant_Name__c, Family ' +
                               'FROM Product2';
            } else {
                // Generic object handling
                fieldsToQuery = 'SELECT Id';
                if (String.isNotBlank(inputWrapper.fieldApiName)) {
                    fieldsToQuery += ', ' + inputWrapper.fieldApiName;
                }
                if (String.isNotBlank(inputWrapper.otherFieldApiName)) {
                    fieldsToQuery += ', ' + inputWrapper.otherFieldApiName;
                }
                fieldsToQuery += ' FROM ' + inputWrapper.objectApiName;
            }
            
            String filterCriteria = '';
            List<String> conditions = new List<String>();
            
            // Step 2: Build WHERE filter for PricebookEntry
            if (isPricebookEntry) {
                // Currency filter for PricebookEntry
                if (String.isNotBlank(currencyCode)) {
                    conditions.add('CurrencyIsoCode = \'' + String.escapeSingleQuotes(currencyCode) + '\'');
                }
                
                // IsActive filter for PricebookEntry
                conditions.add('IsActive = true');
                
                // Product filter based on leadRecordType
                if (String.isNotBlank(inputWrapper.leadRecordType) && !productIds.isEmpty()) {
                    conditions.add('Product2Id IN :productIds');
                }
            }
            
            // Step 2a: Build WHERE filter for Product2
            else if (isProduct) {
                // Product filter based on leadRecordType
                if (String.isBlank(inputWrapper.selectedRecordId) && 
                    String.isNotBlank(inputWrapper.leadRecordType) && 
                    !productIds.isEmpty()) {
                    conditions.add('Id IN :productIds');
                }
            }
            
            // Handle selected record ID
            if (String.isNotBlank(inputWrapper.selectedRecordId)) {
                conditions.add('Id = \'' + String.escapeSingleQuotes(inputWrapper.selectedRecordId) + '\'');
            } 
            // Handle search string
            else if (String.isNotBlank(inputWrapper.searchString)) {
                String searchStr = String.escapeSingleQuotes(inputWrapper.searchString.trim());
                
                if (isPricebookEntry) {
                    // Search by both Product Name and Product Code
                    conditions.add('(Product2.Name LIKE \'%' + searchStr + '%\' OR Product2.ProductCode LIKE \'%' + searchStr + '%\')');
                } 
                else if (isProduct) {
                    // Search by both Product Name and Product Code
                    conditions.add('(Name LIKE \'%' + searchStr + '%\' OR ProductCode LIKE \'%' + searchStr + '%\')');
                }
                else if (String.isNotBlank(inputWrapper.fieldApiName)) {
                    conditions.add(inputWrapper.fieldApiName + ' LIKE \'%' + searchStr + '%\'');
                }
            }
            
            // Combine all conditions
            if (!conditions.isEmpty()) {
                filterCriteria = String.join(conditions, ' AND ');
            }
            
            // Step 3: Add WHERE, ORDER BY and LIMIT clauses
            String query = fieldsToQuery;
            if (String.isNotBlank(filterCriteria)) {
                query += ' WHERE ' + filterCriteria;
            }
            
            // Add ORDER BY clause to sort alphabetically by product name
            if (isPricebookEntry) {
                query += ' ORDER BY Product2.Name ASC'; // Sort by Product Name alphabetically
            } else if (isProduct) {
                query += ' ORDER BY Name ASC'; // Sort by Product Name alphabetically
            } else if (String.isNotBlank(inputWrapper.fieldApiName)) {
                query += ' ORDER BY ' + inputWrapper.fieldApiName + ' ASC'; // Sort by main field alphabetically
            }
            
            query += ' LIMIT 100'; // Increased limit to ensure better results
            
            System.debug('Final Query --> ' + query);
            
            // Step 4: Execute and wrap results
            List<ResultWrapper> returnWrapperList = new List<ResultWrapper>();
            
            if (isPricebookEntry) {
                // Use dynamic query with binding variables for better performance and security
                List<PricebookEntry> pbeList;
                
                if (!conditions.isEmpty()) {
                    // Build dynamic query with binding variables
                    String dynamicQuery = 'SELECT Id, Product2Id, UnitPrice, Product2.Name, Product2.ProductCode, ' +
                                        'Product2.Family, Product2.Plant_Name__c, Product2.Description, ' +
                                        'CurrencyIsoCode ' +
                                        'FROM PricebookEntry ' +
                                        'WHERE IsActive = true ';
                    
                    if (String.isNotBlank(currencyCode)) {
                        dynamicQuery += 'AND CurrencyIsoCode = \'' + String.escapeSingleQuotes(currencyCode) + '\' ';
                    }
                    
                    if (String.isNotBlank(inputWrapper.leadRecordType) && !productIds.isEmpty()) {
                        dynamicQuery += 'AND Product2Id IN :productIds ';
                    }
                    
                    if (String.isNotBlank(inputWrapper.selectedRecordId)) {
                        dynamicQuery += 'AND Id = \'' + String.escapeSingleQuotes(inputWrapper.selectedRecordId) + '\' ';
                    }
                    
                    if (String.isNotBlank(inputWrapper.searchString)) {
                        String searchStr = '%' + String.escapeSingleQuotes(inputWrapper.searchString.trim()) + '%';
                        dynamicQuery += 'AND (Product2.Name LIKE \'' + searchStr + '\' OR Product2.ProductCode LIKE \'' + searchStr + '\') ';
                    }
                    
                    dynamicQuery += 'ORDER BY Product2.Name ASC LIMIT 100';
                    
                    System.debug('Dynamic Query: ' + dynamicQuery);
                    pbeList = Database.query(dynamicQuery);
                } else {
                    pbeList = Database.query(query);
                }
                
                List<string> prodCodeList = new List<string>();
                for (PricebookEntry entry : pbeList) {
                    if (entry.Product2 != null && !prodCodeList.contains(entry.Product2.ProductCode)) {
                        ResultWrapper wrap = new ResultWrapper();
                        wrap.mainField = entry.Product2.Name;
                        wrap.subField = entry.Product2.ProductCode;
                        wrap.familyField = entry.Product2.Family;
                        wrap.unitPrice = entry.UnitPrice;
                        wrap.productPlant = entry.Product2.Plant_Name__c;
                        wrap.Description = entry.Product2.Description;
                        wrap.proId = entry.Product2Id;
                        wrap.id = entry.Id;
                        prodCodeList.add(entry.Product2.ProductCode);
                        returnWrapperList.add(wrap);
                    }
                }
            } 
            else if (isProduct) {
                List<Product2> productList = Database.query(query);
                for (Product2 product : productList) {
                    ResultWrapper wrap = new ResultWrapper();
                    wrap.mainField = product.Name;
                    wrap.subField = product.ProductCode;
                    wrap.familyField = product.Family;
                    wrap.productPlant = product.Plant_Name__c;
                    wrap.Description = product.Description;
                    wrap.id = product.Id;
                    returnWrapperList.add(wrap);
                }
            } 
            else {
                // Generic object handling
                List<SObject> objList = Database.query(query);
                for (SObject obj : objList) {
                    ResultWrapper wrap = new ResultWrapper();
                    wrap.id = (String)obj.get('Id');
                    if (String.isNotBlank(inputWrapper.fieldApiName)) {
                        wrap.mainField = (String)obj.get(inputWrapper.fieldApiName);
                    }
                    if (String.isNotBlank(inputWrapper.otherFieldApiName)) {
                        String[] otherFields = inputWrapper.otherFieldApiName.split(',');
                        if (otherFields.size() > 0) {
                            wrap.subField = (String)obj.get(otherFields[0].trim());
                        }
                    }
                    returnWrapperList.add(wrap);
                }
            }
            
            system.debug('returnWrapperList size ==>' + returnWrapperList.size());
            return returnWrapperList;
        } catch (Exception err) {
            System.debug('Error at line: ' + err.getLineNumber() + ' - ' + err.getMessage());
            System.debug('Stack trace: ' + err.getStackTraceString());
            throw new AuraHandledException('Error fetching records: ' + err.getMessage());
        }
    }
    
    public class ResultWrapper {
        @AuraEnabled public String mainField {get; set;}
        @AuraEnabled public String subField {get; set;}
        @AuraEnabled public String familyField {get; set;}
        @AuraEnabled public Decimal unitPrice {get; set;}
        @AuraEnabled public String proId {get; set;}
        @AuraEnabled public String uom {get; set;}
        @AuraEnabled public String productPlant {get; set;}
        @AuraEnabled public String Description {get; set;}
        @AuraEnabled public String id {get; set;}
    }
    
    public class SearchWrapper {
        @AuraEnabled public String objectApiName {get; set;}
        @AuraEnabled public String fieldApiName {get; set;}
        @AuraEnabled public String otherFieldApiName {get; set;}
        @AuraEnabled public String searchString {get; set;}
        @AuraEnabled public String selectedRecordId {get; set;}
        @AuraEnabled public String parentRecordId {get; set;}
        @AuraEnabled public String parentFieldApiName {get; set;}
        @AuraEnabled public String leadRecordType {get; set;}
        @AuraEnabled public String businessType {get; set;}
    }
}