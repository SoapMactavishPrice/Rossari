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
        String leadRecordType
    ) {
        String searchText = '\'%' + String.escapeSingleQuotes(searchKey) + '%\'';
        String vQuery = '';
        
        List<String> productIds = Utility.getUserDivisionProductList(UserInfo.getUserId());
        
        // Updated to use the new method with better filtering
        System.debug('leadRecordType: ' + leadRecordType);
        //List<Id> productIds = Utility.getUserDivisionProductList(UserInfo.getUserId(), leadRecordType);')
    ///    List<Id> productIds = getUserAllowedProductIds(leadRecordType);

        if (objectName == 'PricebookEntry') {
            vQuery = 'SELECT Id, Product2Id, UnitPrice, Product2.Name, Product2.Family, ProductCode '
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
            
            vQuery += ' ORDER BY Product2.Name ASC';
            
        /*    if (String.isNotBlank(sortColumn)) {
                vQuery += ' ORDER BY ' + sortColumn;
            }	*/
            if (String.isBlank(maxResults)) {
                maxResults = '15';
            }
            vQuery += ' LIMIT ' + maxResults;
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

    
    @AuraEnabled(Cacheable=true)
    public static List<Id> getUserAllowedProductIds(String leadRecordType) {
        Id currentUserId = UserInfo.getUserId();
        List<Company_User__c> userCompanyList = null;
        String salesOrg = null;
        if (leadRecordType == 'RBL') {
            salesOrg = '1000';
            userCompanyList = [
                SELECT Division__c, Product_Group__c
                FROM Company_User__c
                WHERE User__c = :currentUserId AND (Company__r.Name = 'Rossari Biotech Limited' OR Company__r.SAP_Code__c = '1000')
            ];
        } else if (leadRecordType == 'Tristar') {
            salesOrg = '4000';
            userCompanyList = [
                SELECT Division__c, Product_Group__c
                FROM Company_User__c
                WHERE User__c = :currentUserId AND (Company__r.Name = 'Tristar Intermediates Private Limited' OR Company__r.SAP_Code__c = '4000')
            ];
        } else if (leadRecordType == 'Unitop') {
            salesOrg = '3000';
            userCompanyList = [
                SELECT Division__c, Product_Group__c
                FROM Company_User__c
                WHERE User__c = :currentUserId AND (Company__r.Name = 'Unitop Chemicals Private Limited' OR Company__r.SAP_Code__c = '3000')
            ];
        }

        if (userCompanyList == null) {
            throw new AuraHandledException('User is not associated with any company');
        }

        Set<Id> allowedDivisions = new Set<Id>();
        Set<Id> allowedProductGroups = new Set<Id>();

        for (Company_User__c userCompany : userCompanyList) {
            if (userCompany.Division__c != null) allowedDivisions.add(userCompany.Division__c);
            if (userCompany.Product_Group__c != null) allowedProductGroups.add(userCompany.Product_Group__c);
        }

        if (allowedDivisions.isEmpty() || allowedProductGroups.isEmpty()) return new List<Id>();

      
        List<Sales_Area__c> salesAreas = [
            SELECT Item_Master__c
            FROM Sales_Area__c
            WHERE Sales_Organisation__r.Name = :salesOrg
              AND Item_Master__r.Division__c IN :allowedDivisions
              AND Item_Master__r.Item_Group__c IN :allowedProductGroups
        ];

        Set<Id> matchingProductIds = new Set<Id>();
        for (Sales_Area__c sa : salesAreas) {
            if (sa.Item_Master__c != null) {
                matchingProductIds.add(sa.Item_Master__c);
            }
        }

        return new List<Id>(matchingProductIds);
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