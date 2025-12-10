public with sharing class AddProductPageQuote {

    @AuraEnabled
    public static string getQuotationDetails(string recordId){
        // try {
            // Get Quote with its direct fields instead of Opportunity fields
            Quote qt = [
                SELECT Id, Pricebook2Id, Pricebook2.Name, AccountId, CurrencyIsoCode,
                Sales_Organisations__c, Sales_Organisations__r.Name,
                Distribution_Channel__c, Distribution_Channel__r.Distribution_Code__c,
                Division__c, Division__r.Name
                FROM Quote 
                WHERE Id =: recordId
            ];
            
            Map<String, Object> mapName = new Map<String, Object>();
            
            // Check if Quote has the fields populated, fallback to Opportunity if needed
            if (qt.Sales_Organisations__c != null) {
                mapName.put('salesOrg', qt.Sales_Organisations__r.Name);
            } else {
                // Fallback to Opportunity if Quote doesn't have the value
                qt = [
                    SELECT Id, Pricebook2Id, Pricebook2.Name, AccountId, CurrencyIsoCode,
                    Sales_Organisations__c, Sales_Organisations__r.Name,
                    Distribution_Channel__c, Distribution_Channel__r.Distribution_Code__c,
                    Division__c, Division__r.Name,
                    Opportunity.Sales_Organisations__c, Opportunity.Sales_Organisations__r.Name,
                    Opportunity.Distribution_Channel__c, Opportunity.Distribution_Channel__r.Distribution_Code__c,
                    Opportunity.Division__c, Opportunity.Division__r.Name
                    FROM Quote WHERE Id =: recordId
                ];
                mapName.put('salesOrg', qt.Opportunity.Sales_Organisations__r.Name);
            }
            
            if (qt.Distribution_Channel__c != null) {
                mapName.put('distributionChannel', qt.Distribution_Channel__r.Distribution_Code__c);
            } else if (qt.Opportunity != null && qt.Opportunity.Distribution_Channel__c != null) {
                mapName.put('distributionChannel', qt.Opportunity.Distribution_Channel__r.Distribution_Code__c);
            }
            
            if (qt.Division__c != null) {
                mapName.put('division', qt.Division__r.Name);
            } else if (qt.Opportunity != null && qt.Opportunity.Division__c != null) {
                mapName.put('division', qt.Opportunity.Division__r.Name);
            }
            
            return JSON.serialize(mapName);
        // } catch (Exception e) {
        //     throw new AuraHandledException(e.getMessage());
        // }
    }

    @AuraEnabled
    public static String findProduct(string recordId, List<String> productFamily, string salesOrg, string distributionChannel, string division) {
        try {
            // Get User info
            User currentUser = [
                SELECT Id, Division_Code__c, Division_Code_2__c, Division_Code_3__c
                FROM User
                WHERE Id = :UserInfo.getUserId()
            ];

            // Get Sales Area products
            Set<String> salesAreaProductSet = new Set<String>();
            for (Sales_Area__c salesArea : [
                SELECT Item_Master__c 
                FROM Sales_Area__c
                WHERE Distribution_Channel__r.Distribution_Code__c = :distributionChannel
                AND Sales_Organisation__r.Name = :salesOrg
                AND Item_Master__c != null
                LIMIT 10000
            ]) {
                salesAreaProductSet.add(salesArea.Item_Master__c);
            }

            // Get Quote details
            Quote op = [SELECT Id, Pricebook2Id, Pricebook2.Name, AccountId, CurrencyIsoCode FROM Quote WHERE Id =: recordId];

            // Get existing product IDs
            Set<Id> existingProdId = new Set<Id>();
            for (QuoteLineItem qli : [
                SELECT Product2Id 
                FROM QuoteLineItem 
                WHERE QuoteId =: recordId
                LIMIT 1000
            ]) {
                existingProdId.add(qli.Product2Id);
            }

            // Build product query
            String productQuery = 'SELECT Id FROM Product2 WHERE Id NOT IN :existingProdId';
            if (productFamily != null && !productFamily.isEmpty()) {
                productQuery += ' AND Family IN :productFamily';
            }
            productQuery += ' LIMIT 1000';

            // Get product IDs
            Set<Id> prodId = new Set<Id>();
            for (Product2 pd : Database.query(productQuery)) {
                prodId.add(pd.Id);
            }

            // Query PricebookEntries
            String query = 'SELECT Id, CurrencyIsoCode, UnitPrice, Product2Id, ' +
                          'Product2.Name, Product2.Family, Product2.ProductCode, Product2.Description ' +
                          'FROM PricebookEntry ' +
                          'WHERE Pricebook2Id = \'' + op.Pricebook2Id + '\' ' +
                          'AND Product2.Division__r.Division_Code__c = :division ' +
                          'AND Product2Id IN :prodId ' +
                          'AND CurrencyIsoCode = \'' + op.currencyISOcode + '\' ' +
                          'ORDER BY Product2.Name ASC ' +
                          'LIMIT 1000';
            
            List<PricebookEntry> lstPBE = Database.query(query);

            // Get Customer Material Price List
            Map<Id, Customer_Material_Pricelist__c> cmplMap = new Map<Id, Customer_Material_Pricelist__c>();
            if (!prodId.isEmpty() && op.AccountId != null) {
                for (Customer_Material_Pricelist__c cm : [
                    SELECT Id, Material_Price__c, Material__c
                    FROM Customer_Material_Pricelist__c
                    WHERE Customer__c =: op.AccountId 
                    AND Material__c IN :prodId
                    LIMIT 1000
                ]) {
                    cmplMap.put(cm.Material__c, cm);
                }
            }

            // Prepare Invoice last selling price map only for Sales Org 3000/4000
            Map<Id, Decimal> lastSellingPriceMap = new Map<Id, Decimal>();
            if (op.AccountId != null && (salesOrg == '3000' || salesOrg == '4000') && !prodId.isEmpty()) {
                // Get latest invoice prices per product
                for (Invoice_Line_Item__c ili : [
                    SELECT Item_Taxable_Value__c, Product__c
                    FROM Invoice_Line_Item__c
                    WHERE Product__c IN :prodId 
                    AND Invoice__r.Customer_Name__c = :op.AccountId
                    ORDER BY CreatedDate DESC
                    LIMIT 5000
                ]) {
                    // Only add if not already in map (first one is latest due to ORDER BY DESC)
                    if (!lastSellingPriceMap.containsKey(ili.Product__c)) {
                        lastSellingPriceMap.put(ili.Product__c, ili.Item_Taxable_Value__c);
                    }
                }
            }

            // Build product list
            wrapperClass wc = new wrapperClass();
            wc.priceBook = op.Pricebook2.Name;
            List<ProductWrapper> lstProduct = new List<ProductWrapper>();
            
            Integer i = 0;
            for (PricebookEntry pbe : lstPBE) {
                if (salesAreaProductSet.contains(pbe.Product2Id)) {
                    ProductWrapper pw = new ProductWrapper();
                    pw.Id = pbe.Id;
                    pw.purl = '/lightning/r/' + pbe.Id + '/view';
                    pw.Product2Id = pbe.Product2Id;
                    pw.Name = pbe.Product2.Name;
                    pw.ProductCode = pbe.Product2.ProductCode;
                    pw.Description = pbe.Product2.Description;
                    pw.ListPrice = pbe.UnitPrice;
                    
                    // Set price based on Customer Material Price or Pricebook
                    if (cmplMap.containsKey(pbe.Product2Id)) {
                        pw.Price = cmplMap.get(pbe.Product2Id).Material_Price__c;
                    } else {
                        pw.Price = pbe.UnitPrice;
                    }
                    
                    pw.Family = pbe.Product2.Family;
                    pw.index = i++;
                    pw.showError = false;

                    // Set Customer Material Price based on conditions:
                    // Show value only if Sales Org == '1000' and Division in {'10','11','22'}
                    Set<String> allowedDivisions = new Set<String>{'10','11','22'};
                    if (salesOrg == '1000') {
                        if (allowedDivisions.contains(division)) {
                            if (cmplMap.containsKey(pbe.Product2Id)) {
                                pw.customerMaterialPrice = cmplMap.get(pbe.Product2Id).Material_Price__c;
                            } else {
                                pw.customerMaterialPrice = 0;
                            }
                        } else {
                            pw.customerMaterialPrice = 0; // show column but blank values
                        }
                    } else {
                        pw.customerMaterialPrice = 0; // column will be hidden in UI
                    }

                    // Set Last Selling Price if Sales Org in {'3000','4000'}
                    if (salesOrg == '3000' || salesOrg == '4000') {
                        if (lastSellingPriceMap.containsKey(pbe.Product2Id)) {
                            pw.lastSellingPrice = lastSellingPriceMap.get(pbe.Product2Id);
                        } else {
                            pw.lastSellingPrice = 0;
                        }
                    } else {
                        pw.lastSellingPrice = 0; // column will be hidden in UI
                    }

                    lstProduct.add(pw);
                }
            }

            wc.productList = lstProduct;
            return JSON.serialize(wc);

        } catch (Exception e) {
            throw new AuraHandledException('Error finding products: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static List<PicklistValue> getproductfamily() {
        String strObjectName = 'Product2';
        String strPicklistField = 'Family';
        Schema.SObjectType objSobjectType = Schema.getGlobalDescribe().get(strObjectName);
        Schema.DescribeSObjectResult objDescribeSobject = objSobjectType.getDescribe();
        Map<String, Schema.SObjectField> mapFields = objDescribeSobject.fields.getMap();
        List<Schema.PicklistEntry> lstPickListValues = mapFields.get(strPicklistField).getDescribe().getPickListValues();
        List<PicklistValue> pvList = new List<PicklistValue>();
        for (Schema.PicklistEntry objPickList : lstPickListValues) {
            PicklistValue pv = new PicklistValue(objPickList.getValue(), objPickList.getLabel());
            pvList.add(pv);
        }
        return pvList;
    }
@AuraEnabled
public static String saveProducts(String recordData, String recId) {
    List<ProductWrapper> wc = (List<ProductWrapper>) JSON.deserialize(recordData, List<ProductWrapper>.class);
    List<QuoteLineItem> lstQuoteItems = new List<QuoteLineItem>();
    
    for (ProductWrapper pw : wc) {
        QuoteLineItem qli = new QuoteLineItem();
        qli.Quantity = pw.Quantity;
        
        // Use Price as Sales Price - handle null/empty values
        if (pw.Price != null) {
            qli.UnitPrice = pw.Price;
        } else {
            // If price is null/empty, use ListPrice as fallback
            qli.UnitPrice = pw.ListPrice;
        }

        // Set service and discount/description data
        qli.ServiceDate = System.today();
        qli.Discount = pw.Discount;
        qli.Description = pw.LineDescription;

        // Parent and product refs
        qli.QuoteId = recId;
        qli.Product2Id = pw.Product2Id;
        qli.PricebookEntryId = pw.Id;

        // Persist Customer Material Price and Last Selling Price to custom fields
        qli.Customer_Material_Price__c = pw.customerMaterialPrice;
        qli.Last_Selling_Price__c = pw.lastSellingPrice;
        
        lstQuoteItems.add(qli);
    }
    
    try {
        insert lstQuoteItems;
        return 'success';
    } catch (Exception e) {
        System.debug(e.getMessage());
        return 'error: ' + e.getMessage();
    }
}
    public with sharing class wrapperClass {
        public String priceBook;
        public List<ProductWrapper> productList;
    }

    public with sharing class ProductWrapper {
        public String Name;
        public String Id;
        public String purl;
        public String Product2Id;
        public String ProductCode;
        public String PackSize;
        public String hsnMasterId;
        public String hsnMasterCode;
        public Integer index;
        public Decimal Price;
        public Decimal ListPrice;
        public Decimal SalesPrice;
        public Decimal Quantity = 0;
        public String Family;
        public Date PDate;
        public String Description;
        public String LineDescription;
        public Decimal CGSTRATE;
        public Decimal IGSTRATE;
        public Decimal SGSTRATE;
        public Boolean showError;
        public Decimal Discount = 0;
        
        // New read-only display fields
        public Decimal customerMaterialPrice;
        public Decimal lastSellingPrice;
    }

    public class PicklistValue {
        @AuraEnabled
        public String label { get; set; }
        
        @AuraEnabled
        public String value { get; set; }

        public PicklistValue(String value, String label) {
            this.value = value;
            this.label = label;
        }
    }
}