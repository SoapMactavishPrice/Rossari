public with sharing class AddProductPageQuote {
    @AuraEnabled
    public static String findProduct(string recordId, List < String > productFamily) {

        // Example multipicklist field on User: User.Division_Code__c 
        User currentUser = [
            SELECT Id, Division_Code__c, Division_Code_2__c, Division_Code_3__c
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];

        // Multipicklist values come as a semicolon-separated string, e.g. "East;West;North"
        Set<String> divSet = new Set<String>();

        if (String.isNotBlank(currentUser.Division_Code__c)) {
            divSet.addAll(currentUser.Division_Code__c.split(';'));
        }
        if (String.isNotBlank(currentUser.Division_Code_2__c)) {
            divSet.addAll(currentUser.Division_Code_2__c.split(';'));
        }
        if (String.isNotBlank(currentUser.Division_Code_3__c)) {
            divSet.addAll(currentUser.Division_Code_3__c.split(';'));
        }

        // Debug to check values
        System.debug('Region Set => ' + divSet);


        system.debug('recordId ' + recordId);
        Quote op = [SELECT Id, Pricebook2Id, Pricebook2.Name, AccountId, CurrencyIsoCode FROM Quote WHERE Id =: recordId];

        List < QuoteLineItem > oplIst = [
            SELECT Id, Product2Id
            FROM QuoteLineItem
            WHERE QuoteId =: recordId
        ];

        set < Id > existingProdId = new set < Id > ();
        if (oplIst.size() > 0) {
            for (QuoteLineItem opr: oplIst) {
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

        String query = 'SELECT Id,CurrencyIsoCode,UnitPrice,Product2Id,Product2.Name,Product2.Family,Product2.ProductCode,Product2.Description FROM PricebookEntry WHERE Pricebook2Id = \'' + op.Pricebook2Id + '\'  AND Product2.Division__r.Division_Code__c IN :divSet AND Product2Id IN :prodId AND CurrencyIsoCode =\''+op.currencyISOcode+'\'';
        List < PricebookEntry > lstPBE = (List < PricebookEntry > ) Database.query(query);
        // return lstPBE;

        List<Customer_Material_Pricelist__c> cmpl = [
            SELECT Id, Name, Material_Price__c, Customer__c, Material__c, Material_Code__c
            FROM Customer_Material_Pricelist__c
            WHERE Customer__c =: op.AccountId AND Material__c IN :prodId
        ];

        Map<String, Customer_Material_Pricelist__c> cmplMap = new Map<String, Customer_Material_Pricelist__c>();
        for (Customer_Material_Pricelist__c cm: cmpl) {
            cmplMap.put(cm.Material__c, cm);
        }

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

            if (cmplMap.containsKey(pbe.Product2Id)) {
                pw.Price = cmplMap.get(pbe.Product2Id).Material_Price__c;
            } else {
                pw.Price = pbe.UnitPrice;
            }
            pw.Family = pbe.Product2.Family;
            pw.index = i++;
            pw.showError = false;
            lstProduct.add(pw);
        }

        wc.productList = lstProduct;
        return JSON.serialize(wc);

    }

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
        List < QuoteLineItem > lstOpp = new List < QuoteLineItem > ();
        for (ProductWrapper pw: wc) {
            QuoteLineItem oli = new QuoteLineItem();
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
            oli.QuoteId = recId; //'0065j00000N2RXiAAN';
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