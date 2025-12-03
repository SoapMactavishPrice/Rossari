public without sharing class AddProductPageOpp {

    @AuraEnabled
    public static string getDetail(String recordId){
        Opportunity opp = [
            SELECT Id, Sales_Organisations__c, Distribution_Channel__c, Division__c, Sales_Organisations__r.Name,
            Distribution_Channel__r.Distribution_Code__c, Division__r.Name
            FROM Opportunity WHERE Id =: recordId
        ];

        Map<String, Object> responseMap = new Map<String, Object> {
            'flag' => true
        };

        if (opp != null) {
            Boolean hasSalesOrg = opp.Sales_Organisations__c != null;
            Boolean hasDistChannel = opp.Distribution_Channel__c != null;
            Boolean hasDivision = opp.Division__c != null;
            
            responseMap.put('flag', hasSalesOrg && hasDistChannel && hasDivision);
            
            if (hasSalesOrg) {
                responseMap.put('salesOrg', opp.Sales_Organisations__r.Name);
            }
            if (hasDistChannel) {
                responseMap.put('distributionChannel', opp.Distribution_Channel__r.Distribution_Code__c);
            }
            if (hasDivision) {
                responseMap.put('division', opp.Division__r.Name);
            }
        }

        return JSON.serialize(responseMap);
    }

    @AuraEnabled
    public static string getCustomerSalesArea(String recordId){
        try {

            Opportunity op = [SELECT Id, Pricebook2Id, Pricebook2.Name, AccountId, CurrencyIsoCode FROM Opportunity WHERE Id =: recordId];

            List<Customer_Sales_Area__c> csaList = [
                SELECT Id, Comapany_Code__c, Sales_Organisation__c, Sales_Organisation__r.Name
                FROM Customer_Sales_Area__c 
                WHERE Comapany_Code__c = :op.AccountId
            ];

            Set<String> salesOrgSet = new Set<String>();
            for (Customer_Sales_Area__c csa : csaList) {
                salesOrgSet.add(csa.Sales_Organisation__r.Name);
            }

            System.debug('salesOrgSet: ' + salesOrgSet);

            List<Map<String, String>> companyMapList = new List<Map<String, String>>();
            // Loop through the salesOrgSet
            for (String orgName : salesOrgSet) {
                System.debug('Processing Sales Organization: ' + orgName);
                // Add any additional processing here if needed
                List<Company_User__c> companyUserList = new List<Company_User__c>();
                companyUserList = [
                    SELECT Id, User__c,
                    Company__c, Company__r.SAP_Code__c
                    FROM Company_User__c
                    WHERE Company__r.SAP_Code__c = :orgName
                    AND User__c = :UserInfo.getUserId()
                    LIMIT 1
                ];
                    
                Map<String, String> companyMap = new Map<String, String>();
                if (companyUserList.size() > 0) {
                    System.debug('YES');
                    companyMap.put('label',orgName);
                    companyMap.put('value',orgName);
                    companyMapList.add(companyMap);
                }
            }

            return JSON.serialize(companyMapList);
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String getDivision(String oppId, String salesOrg, String distributionChannel) {
        try {
            // Query the opportunity to get the account ID
            Opportunity opp = [SELECT Id, AccountId FROM Opportunity WHERE Id = :oppId LIMIT 1];
            
            if (opp == null || opp.AccountId == null) {
                return JSON.serialize(new List<Map<String, String>>());
            }

            // Example multipicklist field on User: User.Division_Code__c 
            User currentUser = [
                SELECT Id, Division_Code__c, Division_Code_2__c, Division_Code_3__c
                FROM User
                WHERE Id = :UserInfo.getUserId()
            ];

            // Multipicklist values come as a semicolon-separated string, e.g. "East;West;North"
            Set<String> divSet = new Set<String>();

            // if (String.isNotBlank(currentUser.Division_Code__c)) {
            //     divSet.addAll(currentUser.Division_Code__c.split(';'));
            // }
            // if (String.isNotBlank(currentUser.Division_Code_2__c)) {
            //     divSet.addAll(currentUser.Division_Code_2__c.split(';'));
            // }
            // if (String.isNotBlank(currentUser.Division_Code_3__c)) {
            //     divSet.addAll(currentUser.Division_Code_3__c.split(';'));
            // }
            
            // Query customer sales areas for the account, matching sales organization and distribution channel
            List<Customer_Sales_Area__c> customerSalesAreaList = [
                SELECT Id, Division__c, Division__r.Name, 
                Division__r.Division_Code__c
                FROM Customer_Sales_Area__c 
                WHERE Comapany_Code__c = :opp.AccountId
                AND Sales_Organisation__r.Name = :salesOrg
                AND Distribution_Channel__r.Distribution_Code__c = :distributionChannel
                // AND Division__r.Division_Code__c IN :divSet
            ];

            for (Customer_Sales_Area__c csa : customerSalesAreaList) {
                divSet.add(csa.Division__r.Division_Code__c);
            }
            System.debug(divSet);

            List<Company_User__c> companyUserList = new List<Company_User__c>();
            companyUserList = [
                SELECT Id, User__c,
                Company__c, Company__r.SAP_Code__c, Division__r.Name, Division__r.Division_Code__c
                FROM Company_User__c
                WHERE Company__r.SAP_Code__c = :salesOrg
                AND User__c = :UserInfo.getUserId()
            ];

            Set<String> divSet2 = new Set<String>();
            for (Company_User__c companyUser : companyUserList) {
                divSet2.add(companyUser.Division__r.Division_Code__c);
            }
            System.debug(divSet2);

            // Find common elements between divSet and divSet2
            Set<String> commonDivSet = new Set<String>(divSet);
            commonDivSet.retainAll(divSet2);

            System.debug(commonDivSet);
            
            // Create a map to store unique divisions
            Map<String, Map<String, String>> divisionMap = new Map<String, Map<String, String>>();
            
            // Add common division codes directly to the map
            for (String divCode : commonDivSet) {
                if (String.isNotBlank(divCode)) {
                    divisionMap.put(divCode, new Map<String, String>{
                        'label' => divCode,  // Using the code as label, modify if you have a different display name
                        'value' => divCode
                    });
                }
            }
            
            // Convert map values to list for the combobox
            List<Map<String, String>> divisions = new List<Map<String, String>>(divisionMap.values());
            
            return JSON.serialize(divisions);
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching divisions: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String getDistributionChannel(String oppId, String salesOrg) {
        try {
            // Query the opportunity to get the account ID
            Opportunity opp = [SELECT Id, AccountId FROM Opportunity WHERE Id = :oppId LIMIT 1];
            
            if (opp == null || opp.AccountId == null) {
                return JSON.serialize(new List<Map<String, String>>());
            }

            User currentUser = [
                SELECT Id, Division_Code__c, Division_Code_2__c, Division_Code_3__c, Sales_Type_Code1__c
                FROM User
                WHERE Id = :UserInfo.getUserId()
            ];
            
            // Get all selected values from Sales_Type_Code1__c multipicklist into a Set
            Set<String> salesTypeCodes = new Set<String>();
            if (currentUser.Sales_Type_Code1__c != null) {
                salesTypeCodes.addAll(currentUser.Sales_Type_Code1__c.split(';'));
            }
            
            // Query customer sales areas for the account and matching sales organization
            List<Customer_Sales_Area__c> salesAreas = [
                SELECT Id, Distribution_Channel__c, Distribution_Channel__r.Distribution_Code__c
                FROM Customer_Sales_Area__c 
                WHERE Comapany_Code__c = :opp.AccountId
                AND Sales_Organisation__r.Name = :salesOrg
                AND Distribution_Channel__c != null
                AND Distribution_Channel__r.Distribution_Code__c IN :salesTypeCodes
            ];
            
            // Create a list to store unique distribution channels
            Map<String, Map<String, String>> distChannelMap = new Map<String, Map<String, String>>();
            
            for (Customer_Sales_Area__c csa : salesAreas) {
                if (!distChannelMap.containsKey(csa.Distribution_Channel__c)) {
                    distChannelMap.put(csa.Distribution_Channel__c, new Map<String, String>{
                        'label' => csa.Distribution_Channel__r.Distribution_Code__c,
                        'value' => csa.Distribution_Channel__r.Distribution_Code__c
                    });
                }
            }
            
            // Convert map values to list for the combobox
            List<Map<String, String>> distChannels = new List<Map<String, String>>(distChannelMap.values());
            
            return JSON.serialize(distChannels);
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching distribution channels: ' + e.getMessage());
        }
    }


    
  @AuraEnabled
public static String findProduct(string recordId, List<String> productFamily, string salesOrg, string distributionChannel, string division) {
    
    // 1. Get opportunity details FIRST
    Opportunity op = [
        SELECT Id, Pricebook2Id, Pricebook2.Name, AccountId, CurrencyIsoCode, 
        Sales_Organisations__r.Name, Division__r.Name 
        FROM Opportunity 
        WHERE Id =: recordId
    ];

    // Store the values in local variables for binding
    Id pricebookId = op.Pricebook2Id;
    String currencyCode = op.CurrencyIsoCode;
    Id accountId = op.AccountId;

    // 2. Get sales area products for this salesOrg/distributionChannel
    List<Sales_Area__c> salesAreaList = [
        SELECT Id, Item_Master__c
        FROM Sales_Area__c
        WHERE Distribution_Channel__r.Distribution_Code__c = :distributionChannel
        AND Sales_Organisation__r.Name = :salesOrg
        AND Item_Master__c != null
    ];

    Set<Id> salesAreaProductSet = new Set<Id>();
    for (Sales_Area__c salesArea : salesAreaList) {
        salesAreaProductSet.add(salesArea.Item_Master__c);
    }

    // If no products in sales area, return empty early
    if (salesAreaProductSet.isEmpty()) {
        wrapperClass wc = new wrapperClass();
        wc.priceBook = op.Pricebook2.Name;
        wc.productList = new List<ProductWrapper>();
        return JSON.serialize(wc);
    }

    // 3. Get existing products in the opportunity
    List<OpportunityLineItem> oplIst = [
        SELECT Id, Product2Id
        FROM OpportunityLineItem
        WHERE OpportunityId =: recordId
    ];

    Set<Id> existingProdId = new Set<Id>();
    for (OpportunityLineItem opr: oplIst) {
        existingProdId.add(opr.Product2Id);
    }

    // 4. Build dynamic query with proper variable binding
    String query = 'SELECT Id, CurrencyIsoCode, UnitPrice, Product2Id, ' +
                  'Product2.Name, Product2.Family, Product2.ProductCode, Product2.Description ' +
                  'FROM PricebookEntry ' +
                  'WHERE Pricebook2Id = :pricebookId ' + // Use local variable
                  'AND Product2Id IN :salesAreaProductSet ' +
                  'AND Product2.Division__r.Division_Code__c = :division ' +
                  'AND Product2Id NOT IN :existingProdId ' +
                  'AND CurrencyIsoCode = :currencyCode ' + // Use local variable
                  'AND IsActive = true ';

    // Add product family filter if provided
    if (productFamily != null && !productFamily.isEmpty()) {
        query += 'AND Product2.Family IN :productFamily ';
    }

    query += 'ORDER BY Product2.Name ASC';

    // Execute the query with all bind variables
    List<PricebookEntry> lstPBE = Database.query(query);

    // 5. Get Customer Material Price list (only for specific sales orgs)
    Map<Id, Customer_Material_Pricelist__c> cmplMap = new Map<Id, Customer_Material_Pricelist__c>();
    
    // Only query Customer Material Price if needed
    Set<String> allowedDivisions = new Set<String>{'10','11','22'};
    if (salesOrg == '1000' && allowedDivisions.contains(division)) {
        List<Customer_Material_Pricelist__c> cmpl = [
            SELECT Id, Material_Price__c, Material__c
            FROM Customer_Material_Pricelist__c
            WHERE Customer__c = :accountId  // Use local variable
            AND Material__c IN :salesAreaProductSet
        ];
        
        for (Customer_Material_Pricelist__c cm: cmpl) {
            cmplMap.put(cm.Material__c, cm);
        }
    }

    // 6. Prepare Invoice last selling price map only for Sales Org 3000/4000
    Map<Id, Decimal> lastSellingPriceMap = new Map<Id, Decimal>();
    if (accountId != null && (salesOrg == '3000' || salesOrg == '4000')) {
        List<Invoice_Line_Item__c> invItems = [
            SELECT Item_Taxable_Value__c, Product__c
            FROM Invoice_Line_Item__c
            WHERE Product__c IN :salesAreaProductSet 
            AND Invoice__r.Customer_Name__c = :accountId  // Use local variable
            ORDER BY Invoice__r.CreatedDate DESC
        ];
        
        // Get only the latest price per product
        for (Invoice_Line_Item__c ili : invItems) {
            if (!lastSellingPriceMap.containsKey(ili.Product__c)) {
                lastSellingPriceMap.put(ili.Product__c, ili.Item_Taxable_Value__c);
            }
        }
    }

    // 7. Create wrapper list
    wrapperClass wc = new wrapperClass();
    wc.priceBook = op.Pricebook2.Name;
    
    List<ProductWrapper> lstProduct = new List<ProductWrapper>();
    integer i = 0;
    
    for (PricebookEntry pbe: lstPBE) {
        ProductWrapper pw = new ProductWrapper();
        pw.Id = pbe.Id;
        pw.purl = '/lightning/r/' + pbe.Id + '/view';
        pw.Product2Id = pbe.Product2Id;
        pw.Name = pbe.Product2.Name;
        pw.ProductCode = pbe.Product2.ProductCode;
        pw.Description = pbe.Product2.Description;
        pw.ListPrice = pbe.UnitPrice;
        pw.Family = pbe.Product2.Family;
        pw.index = i++;
        pw.showError = false;

        // Set price - use Customer Material Price if available, otherwise List Price
        if (cmplMap.containsKey(pbe.Product2Id)) {
            pw.Price = cmplMap.get(pbe.Product2Id).Material_Price__c;
        } else {
            pw.Price = pbe.UnitPrice;
        }

        // Set Customer Material Price
        if (salesOrg == '1000' && allowedDivisions.contains(division)) {
            if (cmplMap.containsKey(pbe.Product2Id)) {
                pw.customerMaterialPrice = cmplMap.get(pbe.Product2Id).Material_Price__c;
            } else {
                pw.customerMaterialPrice = 0;
            }
        } else {
            pw.customerMaterialPrice = 0;
        }

        // Set Last Selling Price
        if ((salesOrg == '3000' || salesOrg == '4000') && lastSellingPriceMap.containsKey(pbe.Product2Id)) {
            pw.lastSellingPrice = lastSellingPriceMap.get(pbe.Product2Id);
        } else {
            pw.lastSellingPrice = 0;
        }

        lstProduct.add(pw);
    }

    wc.productList = lstProduct;
    return JSON.serialize(wc);
}
    /* @AuraEnabled
    public static String findProduct(string recordId, List<String> productFamily){
        system.debug('recordId '+recordId);
        Opportunity op = [SELECT Id, Pricebook2Id, Pricebook2.Name FROM Opportunity WHERE Id =:recordId];
        
        List<OpportunityLineItem>  oplIst = [select Id,Product2Id from OpportunityLineItem where OpportunityId =:recordId ];
        
        set<Id>existingProdId = new set<Id>();
        if(oplIst.size() > 0){
            for(OpportunityLineItem opr : oplIst){
                existingProdId.add(opr.Product2Id);
            }
        }
        wrapperClass wc = new wrapperClass();
        wc.priceBook = op.Pricebook2.Name;
        
        string productQuery = 'select Id,Name,Family  from Product2 where Id NOT IN :existingProdId';
        
        if(productFamily.size() > 0){
            productQuery+=' where Family IN : productFamily';
            // productQuery+=' where Family IN '+productFamily;
        }
        
        set<Id> prodId = new set<Id>();
        //List<Product2> pdList = database.query(productQuery);
        for(Product2 pd : database.query(productQuery)){
            prodId.add(pd.Id);
            // system.debug('prodId'+prodId);
        }
        
        
        //String query = 'SELECT Id ,UnitPrice,Product2Id  FROM PricebookEntry WHERE CurrencyISOCode =\''+op.currencyISOcode +'\'  and Pricebook2Id = \''+ op.Pricebook2Id +'\' AND IsActive = true AND Product2Id IN :prodId';
        // String query = 'SELECT Id ,UnitPrice,Product2Id,Product2.Name,Product2.Pack_Size__c,Product2.HSN_Code__c, Product2.HSN_Code__r.Name,Product2.Family,Product2.ProductCode,Product2.Description,Product2.HSN_Code__r.IGST_Rate__c,Product2.HSN_Code__r.CGST_Rate__c,  Product2.HSN_Code__r.SGST_Rate__c FROM PricebookEntry WHERE Pricebook2Id = \''+ op.Pricebook2Id +'\' AND IsActive = true AND Product2Id IN :prodId';
        String query  ='SELECT Id ,UnitPrice,Product2Id,Product2.Name,Product2.Family,Product2.ProductCode,Product2.Description FROM PricebookEntry WHERE Pricebook2Id = \''+ op.Pricebook2Id +'\' AND IsActive = true AND Product2Id IN :prodId';
        //system.debug('query'+query);
        List<PricebookEntry> lstPBE = (List<PricebookEntry>)Database.query(query);
        //system.debug('lstPBE'+lstPBE);
        List<ProductWrapper> lstProduct= new List<ProductWrapper>();
        integer i = 0;
        for(PricebookEntry pbe : lstPBE){
            ProductWrapper pw = new ProductWrapper();
            pw.Id = pbe.Id;
            pw.purl = '/lightning/r/' +pbe.Id+'/view';
            pw.Product2Id = pbe.Product2Id;
            pw.Name =pbe.Product2.Name;
            pw.ProductCode = pbe.Product2.ProductCode;
            
            //pw.PackSize = pbe.Product2.Pack_Size__c;
            pw.Family = pbe.Product2.Family;
            
            pw.Description= pbe.Product2.Description;
            pw.Price = pbe.UnitPrice;
            pw.SalesPrice = null;
            //pw.hsnMasterId = pbe.Product2.HSN_Code__c;
            //pw.hsnMasterCode =pbe.Product2.HSN_Code__r.Name;
            //pw.CGSTRATE = pbe.Product2.HSN_Code__r.CGST_Rate__c;
            // pw.SGSTRATE = pbe.Product2.HSN_Code__r.SGST_Rate__c;
            //pw.IGSTRATE = pbe.Product2.HSN_Code__r.IGST_Rate__c;
            pw.index = i++;
            pw.showError = false;
            lstProduct.add(pw);
            system.debug(lstProduct);
        }
        wc.productList = lstProduct;
        return JSON.serialize(wc);
    }
     */
    @AuraEnabled
    public static List < PicklistValue > getproductfamily() {
        String strObjectName = 'Product2';
        String strPicklistField = 'Family';
        Map < String, String > mapPickListValues = new Map < String, String > ();
        Schema.SObjectType objSobjectType = Schema.getGlobalDescribe().get(strObjectName);
        Schema.DescribeSObjectResult objDescribeSobject = objSobjectType.getDescribe();
        Map < String, Schema.SObjectField > mapFields = objDescribeSobject.fields.getMap();
        List < Schema.PicklistEntry > lstPickListValues = mapFields.get(strPicklistField).getDescribe().getPickListValues();
        List < PicklistValue > pvList = new List < PicklistValue > ();
        for (Schema.PicklistEntry objPickList: lstPickListValues) {
            PicklistValue pv = new PicklistValue(objPickList.getValue(), objPickList.getLabel());
            pvList.add(pv);
            // system.debug(pvList);
        }
        return pvList;

    }

    @AuraEnabled
    public static String saveProducts(String recordData, String recId) {

        List < ProductWrapper > wc = (List < ProductWrapper > ) json.deserialize(recordData, List < ProductWrapper > .class);
        List < OpportunityLineItem > lstOpp = new List < OpportunityLineItem > ();
        for (ProductWrapper pw: wc) {
            OpportunityLineItem oli = new OpportunityLineItem();
            oli.Quantity = pw.Quantity;

            // Use Price as Sales Price input, List Price remains from Pricebook
            oli.UnitPrice = pw.Price;

            // Set service and discount/description data
            oli.ServiceDate = system.today();
            oli.Discount = pw.Discount;
            oli.Description = pw.LineDescription;

            // Parent and product refs
            oli.OpportunityId = recId;
            oli.Product2Id = pw.Product2Id;
            oli.PricebookEntryId = pw.Id;

            // Persist Customer Material Price and Last Selling Price to custom fields (read-only UI columns)
            // These custom fields must exist on OpportunityLineItem
            oli.Customer_Material_Price__c = pw.customerMaterialPrice;
            oli.Last_Selling_Price__c = pw.lastSellingPrice;

            lstOpp.add(oli);
        }
        try {
            insert lstOpp;
            return 'success';
        } catch (Exception e) {
            System.debug(e.getMessage());
            return 'error';
        }
    }

    @AuraEnabled
    public static String saveOppDetail(String recordId, string salesOrg, string distributionChannel, string division) {
        String retMsg = '';
        Sales_Organisation__c getSalesOrg = [SELECT Id FROM Sales_Organisation__c WHERE Name =: salesOrg];
        Distribution_Channel__c getDistributionChannel = [SELECT Id, Distribution_Code__c FROM Distribution_Channel__c WHERE Distribution_Code__c =: distributionChannel];
        Division__c getDivision = [SELECT Id FROM Division__c WHERE Name =: division];
        
        Opportunity opp = [
            SELECT Id, Sales_Organisations__c, Distribution_Channel__c, Division__c, AccountId, Inco_Terms__c, Payment_Term__c
            FROM Opportunity
            WHERE Id =: recordId
        ];
        opp.Sales_Organisations__c = getSalesOrg.Id;
        opp.Distribution_Channel__c = getDistributionChannel.Id;
        opp.Division__c = getDivision.Id;

        List<Customer_Sales_Area__c> custSalesAreaList = [
            SELECT Id, Name, Payment_Term__c, Incoterm_1__c
            FROM Customer_Sales_Area__c
            WHERE Comapany_Code__c = :opp.AccountId
            AND Sales_Organisation__c = :opp.Sales_Organisations__c
            AND Distribution_Channel__c = :opp.Distribution_Channel__c
            AND Division__c = :opp.Division__c
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        if (custSalesAreaList.size() > 0) {
            opp.Payment_Term__c = custSalesAreaList[0].Payment_Term__c;
            opp.Inco_Terms__c = custSalesAreaList[0].Incoterm_1__c;
            retMsg = 'success';
        } else {
            retMsg = 'Successfully without Payment term and Inco Term';
        }

        update opp;
        return retMsg;
    }

    @AuraEnabled
    public static Map<String, Decimal> getProductPackSize(String pCodeList, String SalesOrg, String DistChan) {
        try {
            // Convert the stringified array of product IDs to a Set
            List<Object> productIds = (List<Object>)JSON.deserializeUntyped(pCodeList);
            Set<String> productIdSet = new Set<String>();
            
            for (Object productId : productIds) {
                if (productId != null) {
                    System.debug('productId' + productId);
                    productIdSet.add((String)productId);
                }
            }
            
            System.debug(productIdSet);
            System.debug(SalesOrg);
            System.debug(DistChan);

            // Query for the products and create a map of product ID to pack size
            Map<String, Decimal> productPackSizeMap = new Map<String, Decimal>();
            List<Sales_Area__c> salesAreaList = [
                SELECT Id, Pack_Size__c, Item_Master__c FROM Sales_Area__c 
                WHERE Item_Master__c IN :productIdSet
                AND Sales_Organisation__r.Name =: SalesOrg
                AND Distribution_Channel__r.Distribution_Code__c =: DistChan
            ];
            for (Sales_Area__c salesArea : salesAreaList) {
                System.debug(salesArea.Pack_Size__c);
                if (salesArea.Pack_Size__c != null) {
                    productPackSizeMap.put(salesArea.Item_Master__c, Decimal.valueOf(salesArea.Pack_Size__c));
                } else {
                    productPackSizeMap.put(salesArea.Item_Master__c, 0);
                }
            }
            
            return productPackSizeMap;
        } catch (Exception e) {
            throw new AuraHandledException('Error getting product pack sizes: ' + e.getMessage());
        }
    }

    public with sharing class wrapperClass {
        public String priceBook;
        public List < ProductWrapper > productList;
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
        public integer index;
        public Decimal Price;
        public Decimal ListPrice;   
        public Decimal SalesPrice;
        public Decimal Quantity = 0;
        public String Family;
        public Date PDate;
        public String Description;
        public String LineDescription;
        public decimal CGSTRATE;
        public decimal IGSTRATE;
        public decimal SGSTRATE;
        public boolean showError;
        public decimal Discount = 0;

        // New read-only display fields
        public Decimal customerMaterialPrice;
        public Decimal lastSellingPrice;
    }

    public class PicklistValue {
        @auraenabled
        public String label {
            get;
            set;
        }
        @auraenabled
        public String value {
            get;
            set;
        }

        public PicklistValue(String value, String label) {
            this.value = value;
            this.label = label;
        }
    }
}