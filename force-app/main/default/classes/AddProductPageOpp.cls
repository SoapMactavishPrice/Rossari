public without sharing class AddProductPageOpp {

    @AuraEnabled
    public static String findProduct(string recordId, List < String > productFamily) {
        system.debug('recordId ' + recordId);
        Opportunity op = [SELECT Id, Pricebook2Id, Pricebook2.Name, AccountId FROM Opportunity WHERE Id =: recordId];

        List<Customer_Sales_Area__c> csaList = [
            SELECT Id, Name, Sales_Organisation__c, Distribution_Channel__c, Sales_Organisation__r.Name, Distribution_Channel__r.Distribution_Code__c
            FROM Customer_Sales_Area__c
            WHERE Comapany_Code__c =: op.AccountId
        ];

        if (csaList.size() > 0) {
            List < OpportunityLineItem > oplIst = [
                SELECT Id, Product2Id
                FROM OpportunityLineItem
                WHERE OpportunityId =: recordId
            ];

            set < Id > existingProdId = new set < Id > ();
            if (oplIst.size() > 0) {
                for (OpportunityLineItem opr: oplIst) {
                    existingProdId.add(opr.Product2Id);
                }
            }
            wrapperClass wc = new wrapperClass();
            wc.priceBook = op.Pricebook2.Name;

            string productQuery = 'select Id,Name,Family  from Product2 where Id NOT IN :existingProdId';

            if (productFamily.size() > 0) {
                productQuery += ' where Family IN : productFamily';
            }

            set < Id > prodId = new set < Id > ();
            for (Product2 pd: database.query(productQuery)) {
                prodId.add(pd.Id);
            }

            Set<String> salesOrgSet = new Set<String>();
            Set<String> distChanSet = new Set<String>();
            for (Customer_Sales_Area__c csa : csaList) {
                salesOrgSet.add(csa.Sales_Organisation__r.Name);
                distChanSet.add(csa.Distribution_Channel__r.Distribution_Code__c);
            }

            System.debug(salesOrgSet);
            System.debug(distChanSet);

            List<Sales_Area__c> saList = [
                SELECT Id, Name, Item_Master__c, Item_Master__r.ProductCode, Sales_Organisation__c, Sales_Organisation__r.Name,
                Distribution_Channel__c, Distribution_Channel__r.Distribution_Code__c
                FROM Sales_Area__c
                WHERE Sales_Organisation__r.Name IN :salesOrgSet AND Distribution_Channel__r.Distribution_Code__c IN :distChanSet
                AND Item_Master__c NOT IN :existingProdId
                AND Item_Master__c != null
                LIMIT 49000
            ];

            System.debug(saList.size());

            Set<Id> itemMasterIds = new Set<Id>();

            for (Sales_Area__c sa : saList) {
                itemMasterIds.add(sa.Item_Master__c);
            }

            String query = 'SELECT Id ,UnitPrice,Product2Id,Product2.Name,Product2.Family,Product2.ProductCode,Product2.Description FROM PricebookEntry WHERE Pricebook2Id = \'' + op.Pricebook2Id + '\'  AND Product2Id IN :itemMasterIds';
            List < PricebookEntry > lstPBE = (List < PricebookEntry > ) Database.query(query);
            // return lstPBE;

            List < ProductWrapper > lstProduct = new List < ProductWrapper > ();
            integer i = 0;
            for (PricebookEntry pbe: lstPBE) {
                ProductWrapper pw = new ProductWrapper();
                pw.Id = pbe.Id;
                pw.purl = '/lightning/r/' + pbe.Id + '/view';
                pw.Product2Id = pbe.Product2Id;
                pw.Name = pbe.Product2.Name;
                pw.ProductCode = pbe.Product2.ProductCode;
                pw.Description = pbe.Product2.Description;
                pw.Price = pbe.UnitPrice;
                pw.Family = pbe.Product2.Family;
                pw.index = i++;
                pw.showError = false;
                lstProduct.add(pw);
            }

            wc.productList = lstProduct;
            return JSON.serialize(wc);
        } else {
            return 'No Customer Sales Area Found';
        }

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
            oli.UnitPrice = pw.Price;
            oli.UnitPrice = pw.Price;
            oli.UnitPrice = pw.Price;

            //oli.Product_Category__c = pw.Family;
            oli.UnitPrice = pw.Price;
            system.debug(oli.UnitPrice);
            oli.ServiceDate = system.today();
            oli.Discount = pw.Discount;
            oli.Description = pw.LineDescription;
            oli.OpportunityId = recId; //'0065j00000N2RXiAAN';
            oli.Product2Id = pw.Product2Id;
            // oli.HSN_Master__c = pw.hsnMasterId;
            //oli.CGST_RATE__c = pw.CGSTRATE;
            //oli.SGST_RATE__c = pw.SGSTRATE;
            //oli.IGST_RATE__c = pw.IGSTRATE;
            //oli.Pack_Size__c = pw.PackSize;
            oli.PricebookEntryId = pw.Id; //'01u5j000003Pq51AAC';
            lstOpp.add(oli);
            //  System.debug(' pw' + lstOpp);

        }
        try {
            insert lstOpp;
            return 'success';
        } catch (Exception e) {
            System.debug(e.getMessage());
            return 'error';
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