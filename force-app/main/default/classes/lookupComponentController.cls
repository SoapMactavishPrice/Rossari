public without sharing class lookupComponentController {

    @AuraEnabled(cacheable=true)  
    public static String findRecords(
        String searchKey,
        String objectName,
        String returnFields,
        List<String> queryFields,
        String filter,
        String sortColumn,
        String maxResults,
        String family,
        String currencyCode,
        String leadRecordType,
        String divisionId
    ) {
        String searchText = '\'%' + String.escapeSingleQuotes(searchKey) + '%\'';
        String vQuery = '';
        
        //List<String> productIds = Utility.getUserDivisionProductList(UserInfo.getUserId());
        
        // Updated to use the new method with better filtering
        System.debug('leadRecordType: ' + leadRecordType);
        //List<Id> productIds = Utility.getUserDivisionProductList(UserInfo.getUserId(), leadRecordType);')
   	    List<Id> productIds = Utility.getUserAllowedProductIds(leadRecordType);

        System.debug('Allowed Product IDs: ' + productIds);

        if (objectName == 'PricebookEntry') {
            vQuery = 'SELECT Id, Product2Id, UnitPrice, Product2.Name, Product2.Family, ProductCode,Product2.Division__c '
                   + 'FROM PricebookEntry WHERE IsActive = true';

            if (!productIds.isEmpty()) {
                vQuery += ' AND Product2Id IN :productIds';
            } else {
                // No allowed products – return empty result
                return JSON.serialize(new List<Wrapper>());
            }

            if (String.isNotBlank(currencyCode)) {
                vQuery += ' AND CurrencyIsoCode = \'' + String.escapeSingleQuotes(currencyCode) + '\'';
            }
            if (String.isNotBlank(searchKey)) {
                vQuery += ' AND (Product2.Name LIKE ' + searchText + ' OR Product2.ProductCode LIKE ' + searchText + ')';
            }
            if (String.isNotBlank(family)) {
                vQuery += ' AND Product2.Family = \'' + String.escapeSingleQuotes(family) + '\'';
            }
            if (String.isNotBlank(filter)) {
                vQuery += ' AND (' + filter + ')';
            }
            if (String.isNotBlank(divisionId)) {
                vQuery += ' AND Product2.Division__c = \'' + String.escapeSingleQuotes(divisionId) + '\'';
            }

            
            vQuery += ' ORDER BY Product2.Name ASC';
            
        /*    if (String.isNotBlank(sortColumn)) {
                vQuery += ' ORDER BY ' + sortColumn;
            }	*/
            // if (String.isBlank(maxResults)) {
            //     maxResults = '15';
            // }
            // vQuery += ' LIMIT ' + maxResults;
        } else {
            throw new AuraHandledException('Unsupported object: ' + objectName);
        }

        System.debug('findRecords query: ' + vQuery);

        List<Wrapper> results = new List<Wrapper>();
        Set<String> seenCodes = new Set<String>();

        try {
            for (PricebookEntry p : Database.query(vQuery)) {
                if (!seenCodes.contains(p.ProductCode)) {
                    Wrapper w = new Wrapper();
                    w.Id = p.Id;
                    w.Name = p.Product2.Name;
                    w.productCode = p.ProductCode;
                    w.familyField = p.Product2.Family;
                    w.unitPrice = p.UnitPrice;
                    w.proId = p.Product2Id;
                    results.add(w);
                    seenCodes.add(p.ProductCode);
                }
            }
        } catch (Exception e) {throw new AuraHandledException('Error searching products: ' + e.getMessage());}

        return JSON.serialize(results);
    }

    @AuraEnabled(cacheable=true)
    public static String fetchDefaultRecord(String recordId) {
        String vQuery = 'SELECT Id, Product2Id, UnitPrice, Product2.Name, Product2.Family, ProductCode '
                      + 'FROM PricebookEntry WHERE Id = :recordId LIMIT 1';
        Wrapper w;

        try {
            PricebookEntry p = Database.query(vQuery);
            w = new Wrapper();
            w.Id = p.Id;
            w.proId = p.Product2Id;
            w.Name = p.Product2.Name;
            w.productCode = p.ProductCode;
            w.familyField = p.Product2.Family;
            w.unitPrice = p.UnitPrice;
        } catch (Exception e) {return null;}

        return JSON.serialize(w);
    }

    // Wrapper class for response
    public class Wrapper {
        @AuraEnabled public String Id;
        @AuraEnabled public String proId;
        @AuraEnabled public String Name;
        @AuraEnabled public String productCode;
        @AuraEnabled public String familyField;
        @AuraEnabled public Decimal unitPrice;
    }
}