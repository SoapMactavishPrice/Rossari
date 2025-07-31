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
            
            Boolean isPricebookEntry = inputWrapper.objectApiName == 'PricebookEntry';
            Boolean isProduct = inputWrapper.objectApiName == 'Product2';
            String fieldsToQuery;
            
            // Step 1: Compose the SELECT clause
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
            
            // Step 2: Build WHERE filter
            String filterCriteria = '';
            
            // Add currency filter only for PricebookEntry
            if (isPricebookEntry && String.isNotBlank(currencyCode)) {
                filterCriteria += ' CurrencyIsoCode = \'' + String.escapeSingleQuotes(currencyCode) + '\'';
            }
            
            // Handle selected record ID
            if (String.isNotBlank(inputWrapper.selectedRecordId)) {
                if (String.isNotBlank(filterCriteria)) filterCriteria += ' AND ';
                filterCriteria += ' Id = \'' + String.escapeSingleQuotes(inputWrapper.selectedRecordId) + '\'';
            } 
            // Handle search string
            else if (String.isNotBlank(inputWrapper.searchString)) {
                String searchStr = String.escapeSingleQuotes(inputWrapper.searchString.trim());
                if (String.isNotBlank(filterCriteria)) filterCriteria += ' AND ';
                
                if (isPricebookEntry) {
                    filterCriteria += '(Product2.Name LIKE \'' + searchStr + '%\' OR Product2.ProductCode LIKE \'' + searchStr + '%\')';
                } 
                else if (isProduct) {
                    filterCriteria += '(Name LIKE \'' + searchStr + '%\' OR ProductCode LIKE \'' + searchStr + '%\')';
                }
                else if (String.isNotBlank(inputWrapper.fieldApiName)) {
                    filterCriteria += inputWrapper.fieldApiName + ' LIKE \'' + searchStr + '%\'';
                }
            }
            
            // Step 3: Add WHERE and LIMIT clauses
            String query = fieldsToQuery;
            if (String.isNotBlank(filterCriteria)) {
                query += ' WHERE ' + filterCriteria;
            }
            query += ' LIMIT 50'; // Increased limit to ensure better results
            
            System.debug('Final Query --> ' + query);
            
            // Step 4: Execute and wrap results
            List<ResultWrapper> returnWrapperList = new List<ResultWrapper>();
            
            if (isPricebookEntry) {
                List<string> prodCodeList = new List<string>();
                for (PricebookEntry entry : Database.query(query)) {
                    if (entry.Product2 != null && !prodCodeList.contains(entry.Product2.ProductCode)) {
                        ResultWrapper wrap = new ResultWrapper();
                        wrap.mainField = entry.Product2.Name;
                        wrap.subField = entry.Product2.ProductCode;
                        wrap.familyField = entry.Product2.Family;
                        wrap.unitPrice = entry.UnitPrice;
                        wrap.productPlant = entry.Product2.Plant_Name__c;
                        wrap.Description = entry.Product2.Description;
                   //     wrap.uom = entry.Product2.UOM_Master__c;
                        wrap.proId = entry.Product2Id;
                        wrap.id = entry.Id;
                        prodCodeList.add(entry.Product2.ProductCode);
                        returnWrapperList.add(wrap);
                    }
                }
            } 
            else if (isProduct) {
                for (Product2 product : Database.query(query)) {
                    ResultWrapper wrap = new ResultWrapper();
                    wrap.mainField = product.Name;
                    wrap.subField = product.ProductCode;
                    wrap.familyField = product.Family;
                    wrap.productPlant = product.Plant_Name__c;
                    wrap.Description = product.Description;
              //      wrap.uom = product.UOM_Master__c;
                    wrap.id = product.Id;
                    returnWrapperList.add(wrap);
                }
            } 
            else {
                // Generic object handling
                for (SObject obj : Database.query(query)) {
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
            
            system.debug('returnWrapperList==>'+returnWrapperList);
            return returnWrapperList;
        } catch (Exception err) {
            System.debug('Error at line: ' + err.getLineNumber() + ' - ' + err.getMessage());
            throw new AuraHandledException(err.getMessage());
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
    }
}