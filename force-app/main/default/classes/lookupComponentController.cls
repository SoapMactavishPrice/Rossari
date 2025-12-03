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
    String divisionId,
    String businessType // ADD THIS PARAMETER
) {
    try {
        String searchText = '\'%' + String.escapeSingleQuotes(searchKey) + '%\'';
        String vQuery = '';
        
        // Get product IDs with business type mapping
        List<Id> productIds = Utility.getUserAllowedProductIds(leadRecordType, businessType);
        
        System.debug('Allowed Product IDs count: ' + productIds.size() + ' for businessType: ' + businessType);

        if (objectName == 'PricebookEntry') {
            vQuery = 'SELECT Id, Product2Id, UnitPrice, Product2.Name, Product2.Family, ProductCode, Product2.Division__c '
                   + 'FROM PricebookEntry WHERE IsActive = true';

            // Only add product filter if we have products
            if (!productIds.isEmpty() && productIds.size() <= 1000) {
                vQuery += ' AND Product2Id IN :productIds';
            } else if (productIds.size() > 1000) {
                // If too many products, use division filter instead
                vQuery += ' AND Product2.Division__c != null';
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
            if (String.isNotBlank(divisionId)) {
                vQuery += ' AND Product2.Division__c = \'' + String.escapeSingleQuotes(divisionId) + '\'';
            }

            // Always add limits for safety
            vQuery += ' ORDER BY Product2.Name ASC LIMIT 200';
            
        } else {
            throw new AuraHandledException('Unsupported object: ' + objectName);
        }

        System.debug('findRecords query: ' + vQuery);

        List<Wrapper> results = new List<Wrapper>();
        Set<String> seenCodes = new Set<String>();

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

        return JSON.serialize(results);
    } catch (Exception e) {
        System.debug('Error in findRecords: ' + e.getMessage());
        return JSON.serialize(new List<Wrapper>());
    }
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