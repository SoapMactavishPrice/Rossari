@RestResource(urlMapping = '/InvoiceMaster')
global class InvoiceMaster_API {
    @HttpPost
    global static void doPost() {

        map < string, object > result = new map < string, object > ();
        API_Log__c api_log = new API_Log__c();
        api_log.Name = 'InvoiceMastert_API';
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        try {

            String jSONRequestBody = request.requestBody.toString().replace('\n', '');
            api_log.Request__c = jSONRequestBody;

            wrapper inv = parse(jSONRequestBody);

            map < string, string > soMap = new map < string, string > ();
            for (Sales_Organisation__c so: [SELECT Id, Name FROM Sales_Organisation__c WHERE Name !=: null]) {
                soMap.put(so.Name, so.Id);
            }

            map < string, string > disChanelMap = new map < string, string > ();
            for (Distribution_Channel__c so: [SELECT Id, Name, Distribution_Code__c FROM Distribution_Channel__c WHERE Distribution_Code__c !=: null]) {
                disChanelMap.put(so.Distribution_Code__c, so.Id);
            }

            map < string, string > divCodeMap = new map < string, string > ();
            for (Division__c so: [SELECT Id, Name, Division_Code__c FROM Division__c WHERE Division_Code__c !=: null]) {
                divCodeMap.put(so.Division_Code__c, so.Id);
            }

            map < string, string > paymentCodeMap = new map < string, string > ();
            for (Payment_Term__c so: [SELECT Id, Name, Payment_Term_Code__c FROM Payment_Term__c WHERE Payment_Term_Code__c !=: null]) {
                paymentCodeMap.put(so.Payment_Term_Code__c, so.Id);
            }

            map < string, string > payerMap = new map < string, string > ();
            List<Account> accList = [SELECT Id, SAP_Customer_Code__c FROM Account WHERE SAP_Customer_Code__c =: inv.payer LIMIT 1];
            if (accList.size() > 0) {
                Account acc = accList[0];
                payerMap.put(acc.SAP_Customer_Code__c, acc.Id);
            }

            map < string, string > orderCodeMap = new map < string, string > ();
            for (order so: [SELECT Id, SAP_Order_Number__c FROM order WHERE SAP_Order_Number__c =: inv.salesOrderNo]) {
                orderCodeMap.put(so.SAP_Order_Number__c, so.Id);
            }

            map < string, string > companyMap = new map < string, string > ();
            for (Company__c so: [SELECT Id, SAP_Code__c FROM Company__c WHERE SAP_Code__c =: inv.companyCode]) {
                companyMap.put(so.SAP_Code__c, so.Id);
            }

            map < string, string > fyCodeMap = new map < string, string > ();
            for (FY__c so: [SELECT Id, Name FROM FY__c]) {
                fyCodeMap.put(so.Name, so.Id);
            }

            map < string, string > sdCodeMap = new map < string, string > ();
            for (Sales_District__c so: [SELECT Id, Name, Sales_District_Code__c FROM Sales_District__c WHERE Sales_District_Code__c != null]) {
                sdCodeMap.put(so.Sales_District_Code__c, so.Id);
            }

            map < string, string > countCodeMap = new map < string, string > ();
            for (Country__c so: [SELECT Id, Name, Country_Code__c FROM Country__c WHERE Country_Code__c != null]) {
                countCodeMap.put(so.Country_Code__c, so.Id);
            }

            map < string, string > plantCodeMap = new map < string, string > ();
            for (plant__c so: [SELECT Id, Name FROM plant__c WHERE Name != null]) {
                plantCodeMap.put(so.Name, so.Id);
            }

            map < string, string > profitCodeMap = new map < string, string > ();
            for (Profit_Center__c so: [SELECT Id, Name FROM Profit_Center__c WHERE Name != null]) {
                profitCodeMap.put(so.Name, so.Id);
            }

            map < string, string > userCodeMap = new map < string, string > ();
            for (user so: [SELECT Id, Name, SAP_User_Id__c, Employee_Code__c FROM user WHERE SAP_User_Id__c != null]) {
                userCodeMap.put(so.SAP_User_Id__c, so.Id);
            }

            map < string, string > baseCodeMap = new map < string, string > ();
            for (Base_UoM_Master__c so: [SELECT Id, Name, Base_Code__c FROM Base_UoM_Master__c WHERE Base_Code__c != null]) {
                baseCodeMap.put(so.Base_Code__c, so.Id);
            }

            List < Invoice__c > invoiceToInsert = new List < Invoice__c > ();
            List < Invoice_Line_Item__c > lineToInsert = new List < Invoice_Line_Item__c > ();
            //List<wrapper> invoices = parse(jSONRequestBody);

            //for (wrapper inv : invoices) {
            if (String.isBlank(inv.invoiceNo)) {
                throw new CustomException('InvoiceNo is mandatory');
            }

            set < string > prodCode = new set < string > ();
            for (WrapperLine line: inv.invline) {
                prodCode.add(line.productCode);
            }

            map < string, string > prodCodeMap = new map < string, string > ();
            if (prodCode.size() > 0) {
                for (Product2 pr2: [SELECT Id, ProductCode FROM Product2 WHERE ProductCode IN: prodCode]) {
                    prodCodeMap.put(pr2.ProductCode, pr2.Id);
                }
            }

            Invoice__c invRec = new Invoice__c();
            List<Invoice__c> exInv = [SELECT Id, Name FROM Invoice__c WHERE Name =: inv.invoiceNo LIMIT 1];
            if (exInv.size() > 0) {
                invRec.Id = exInv[0].Id;
            }
            invRec.Name = inv.invoiceNo;
            invRec.GST_Invoice_Number__c = String.isNotBlank(inv.gstInvoiceNumber) ? inv.gstInvoiceNumber : null;
            invRec.Billing_Date__c = inv.billingDate;
            invRec.Billing_Type_Description__c = inv.billingTypeDescription;
            invRec.Net_Value__c = inv.netValue != null ? inv.netValue : 0;
            invRec.Billed_Qty__c = inv.billedQty != null ? inv.billedQty : 0;
            invRec.CurrencyIsoCode = String.isNotBlank(inv.documentCurrency) ? inv.documentCurrency : null;
            invRec.SD_Document_Category__c = String.isNotBlank(inv.sdDocumentCategory) ? inv.sdDocumentCategory : null;
            invRec.Sales_Org__c = String.isNotBlank(inv.salesOrg) ? (Id) soMap.get(inv.salesOrg) : null;
            invRec.Distribution_Channel__c = String.isNotBlank(inv.distributionChannel) ? (Id) disChanelMap.get(inv.distributionChannel) : null;
            invRec.Division__c = String.isNotBlank(inv.division) ? (Id) divCodeMap.get(inv.division) : null;
            invRec.Sales_Order_No__c = String.isNotBlank(inv.salesOrderNo) ? inv.salesOrderNo : null;
            invRec.Sold_To_Party__c = String.isNotBlank(inv.soldToParty) ? inv.soldToParty : null;
            invRec.Bill_To_Party_Code__c = String.isNotBlank(inv.billToPartyCode) ? inv.billToPartyCode : null;
            invRec.Payer__c = String.isNotBlank(inv.payer) ? inv.payer : null;
            invRec.Customer_Name__c = String.isNotBlank(inv.payer) ? payerMap.get(inv.payer) : null;
            invRec.Ship_To_Party__c = String.isNotBlank(inv.shipToParty) ? inv.shipToParty : null;
            invRec.Payment_Term__c = String.isNotBlank(inv.paymentTerm) ? paymentCodeMap.get(inv.paymentTerm) : null;
            if (String.isNotBlank(inv.salesOrderNo) && orderCodeMap.containsKey(inv.salesOrderNo)) {
                invRec.SF_Sales_Order_No__c = (Id) orderCodeMap.get(inv.salesOrderNo); //String.isNotBlank(inv.sfSalesOrderNo) ? inv.sfSalesOrderNo : null;
            } else {
                // throw new CustomException('Sales Order No is invalid');
            }
            invRec.Exchange_Rate__c = inv.exchangeRate != null ? inv.exchangeRate : 0;
            invRec.Company_Code__c = String.isNotBlank(inv.companyCode) ? inv.companyCode : null;
            if (companyMap.containsKey(inv.companyCode)) {
                invRec.Company__c = (Id) companyMap.get(inv.companyCode);
            }
            invRec.Inco_Terms__c = String.isNotBlank(inv.incoTerm) ? inv.incoTerm : null;
            invRec.Fiscal_Year__c = String.isNotBlank(inv.fiscalYear) ? (Id) fyCodeMap.get(inv.fiscalYear) : null;
            invRec.Sales_District__c = String.isNotBlank(inv.salesDistrict) ? (Id) sdCodeMap.get(inv.salesDistrict) : null;
            invRec.Country__c = String.isNotBlank(inv.country) ? (Id) countCodeMap.get(inv.country) : null;
            invRec.Credit_Control_Area__c = String.isNotBlank(inv.creditControlArea) ? inv.creditControlArea : null;
            invRec.CCA_Currency__c = String.isNotBlank(inv.ccaCurrency) ? inv.ccaCurrency : null;
            invRec.Customer_Zone__c = String.isNotBlank(inv.customerZone) ? inv.customerZone : null;
            invRec.Total_Tax_Value__c = inv.totalTaxValue != null ? inv.totalTaxValue : 0;
            invRec.Total_Gross_Value__c = inv.totalGrossValue != null ? inv.totalGrossValue : 0;

            invRec.InvoiceStatus__c = String.isNotBlank(inv.invoiceStatus) ? inv.invoiceStatus : '';
            invRec.OwnerId = String.isNotBlank(inv.salesPerson) ? (Id) userCodeMap.get(inv.salesPerson) : null;
            invRec.Sales_Person__c = String.isNotBlank(inv.salesPerson) ? (Id) userCodeMap.get(inv.salesPerson) : null;
            invRec.Sales_Person_Code__c = String.isNotBlank(inv.salesPerson) ? inv.salesPerson : null;
            invRec.Commision_agent__c = String.isNotBlank(inv.Commision_agent) ? inv.Commision_agent : '';
            invRec.LR_Name__c = String.isNotBlank(inv.LR_Name) ? inv.LR_Name : '';
            invRec.LR_Number__c = String.isNotBlank(inv.LR_Number) ? inv.LR_Number : '';
            invRec.LR_Shipping_No__c = String.isNotBlank(inv.LR_Shipping_No) ? inv.LR_Shipping_No : '';
            invRec.LR_Shipping_Date__c = inv.LR_Shipping_Date;

            //invoiceToInsert.add(invRec);
            //}

            upsert invRec;
            if (!invoiceToInsert.isEmpty()) {
                //insert invoiceToInsert;
            }

            //for (wrapper invs : invoices) {

            map<String, String> invLIMap = new map<String, String>();
            if (exInv.size() > 0) {
                List<Invoice_Line_Item__c> invLIlist = [
                    SELECT Id, Name, Invoice__c, Sales_Item_No__c
                    FROM Invoice_Line_Item__c
                    WHERE Invoice__c =: exInv[0].Id
                ];

                for (Invoice_Line_Item__c ili : invLIlist) {
                    invLIMap.put(ili.Sales_Item_No__c, ili.Id);
                }
            }

            for (WrapperLine line: inv.invline) {
                Invoice_Line_Item__c lineRec = new Invoice_Line_Item__c();
                if (invLIMap.containsKey(line.salesItemNo)) {
                    lineRec.Id = invLIMap.get(line.salesItemNo);
                } else {
                    lineRec.Invoice__c = invRec.Id; //
                }
                lineRec.Name = line.salesItemNo;
                lineRec.Base_UOM__c = String.isNotBlank(line.baseUOM) ? (Id) baseCodeMap.get(line.baseUOM) : null;
                lineRec.CGST_Rate__c = line.cgstRate != null ? line.cgstRate : null;
                lineRec.CGST_Value__c = line.cgstValue != null ? line.cgstValue : null;
                lineRec.CurrencyIsoCode = String.isNotBlank(inv.documentCurrency) ? inv.documentCurrency : null;
                lineRec.IGST_Rate__c = line.igstRate != null ? line.igstRate : null;
                lineRec.IGST_Value__c = line.igstValue != null ? line.igstValue : null;
                lineRec.Item_Description__c = String.isNotBlank(line.itemDescription) ? line.itemDescription : null;
                lineRec.Item_Qty__c = line.itemQty != null ? line.itemQty : null;
                lineRec.Item_Taxable_Value__c = line.itemTaxableValue != null ? line.itemTaxableValue : null;
                lineRec.Name = String.isNotBlank(line.name) ? line.name : null;
                lineRec.Pack_Size__c = String.isNotBlank(line.packSize) ? line.packSize : null;
                lineRec.Product_Code__c = line.productCode;
                if (String.isNotBlank(line.productCode) && prodCodeMap.containsKey(line.productCode)) {
                    lineRec.Product__c = (Id) prodCodeMap.get(line.productCode);
                } else {
                    throw new CustomException('Product Code '+line.productCode+' is invalid'); 
                }
                lineRec.Sales_Item_No__c = String.isNotBlank(line.salesItemNo) ? line.salesItemNo : null;
                lineRec.Sales_UOM__c = String.isNotBlank(line.salesUOM) ? (Id) baseCodeMap.get(line.salesUOM) : null;
                lineRec.SGST_Rate__c = line.sgstRate != null ? line.sgstRate : null;
                lineRec.SGST_Value__c = line.sgstValue != null ? line.sgstValue : null;

                lineRec.Plant__c = String.isNotBlank(line.plant) ? (Id) plantCodeMap.get(line.plant) : null;
                lineRec.Plant_GSTIN_No__c = String.isNotBlank(line.plantGstinNo) ? line.plantGstinNo : null;
                lineRec.Sales_Value_In_Doc_Currency__c = line.salesValueInDocCurrency != null ? line.salesValueInDocCurrency : 0;
                lineRec.Sales_Value_In_Local_Currency__c = line.salesValueInLocalCurrency != null ? line.salesValueInLocalCurrency : 0;
                lineRec.Profit_Center__c = String.isNotBlank(line.profitCentre) ? (Id) profitCodeMap.get(line.profitCentre) : null;

                lineToInsert.add(lineRec);
            }
            //}

            if (lineToInsert.size() > 0)
                upsert lineToInsert;

            result.put('StatusCode', '200');
            result.put('Message', 'Invoice Created/Updated Successfully');

            response.responseBody = Blob.valueOf(JSON.serialize(result));
            api_log.Status__c = 'Success';
            
            api_log.Response__c = JSON.serialize(result);

        } catch (exception e) {
            api_log.Exception_Description__c = e.getMessage() + ' : ' + e.getCause() + ' : ' + e.getStackTraceString();

            result.put('StatusCode', '400');
            result.put('Message', e.getMessage());

            api_log.Status__c = 'Failed';
            response.statusCode = 400;
            response.responseBody = Blob.valueOf('{"ERR_MSG":"' + api_log.Exception_Description__c + '","Status":"Failed"}');
        }

        api_log.Response__c = JSON.serialize(result);
        insert api_log;
    }

    public class wrapper {

        String invoiceNo;
        String gstInvoiceNumber;
        Date billingDate;
        String billingTypeDescription;
        Decimal netValue;
        Decimal billedQty;
        String documentCurrency; // Currency picklist (stored as String)
        String sdDocumentCategory;
        string salesOrg; // Lookup
        string distributionChannel; // Lookup
        string division; // Lookup
        String salesOrderNo;
        String soldToParty;
        String billToPartyCode;
        String payer;
        String shipToParty;
        string paymentTerm; // Lookup
        string sfSalesOrderNo; // Lookup
        Decimal exchangeRate;
        String companyCode;
        String incoTerm; // Picklist
        string fiscalYear; // Lookup
        string salesDistrict; // Lookup
        string country; // Lookup
        String creditControlArea;
        String ccaCurrency; // Picklist
        String customerZone;
        Decimal totalTaxValue;
        Decimal totalGrossValue;
        String invoiceStatus; // Picklist
        string salesPerson; // Lookup
        String Commision_agent;
        String LR_Name;
        String LR_Number;
        String LR_Shipping_No;
        Date LR_Shipping_Date;
        List < WrapperLine > invline;
    }

    public class WrapperLine {
        public String baseUOM;
        public Decimal cgstRate;
        public Decimal cgstValue;
        string plant; // Lookup
        String plantGstinNo;
        Decimal salesValueInDocCurrency;
        Decimal salesValueInLocalCurrency;
        string profitCentre;
        //public String currencyIsoCode ;
        public Decimal igstRate;
        public Decimal igstValue;
        public String invoice;
        public String itemDescription;
        public Decimal itemQty;
        public Decimal itemTaxableValue;
        public String name;
        public String packSize;
        public String productName;
        public string productCode;
        public String salesItemNo;
        public String salesUOM;
        public Decimal sgstRate;
        public Decimal sgstValue;
    }

    public static wrapper parse(String json) {
        return (wrapper) System.JSON.deserialize(json, wrapper.class);
    }

    /*public static List < wrapper > parse(String json) {
        return (List < wrapper > ) System.JSON.deserialize(json, List < wrapper > .class);
    }*/

}