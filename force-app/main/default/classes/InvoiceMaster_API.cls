@RestResource(urlMapping = '/InvoiceMaster')
global class InvoiceMaster_API {
    @HttpPost
    global static void doPost() {
        
        map<string, object> result =new map<string, object> ();
        API_Log__c api_log = new API_Log__c();
        api_log.Name = 'InvoiceMastert_API';
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        try{
            
            
            String jSONRequestBody = request.requestBody.toString().replace('\n', '');
            
            result.put('StatusCode','200');
            result.put('Message','Invoice Created/Updated Successfully');
            
            response.responseBody = Blob.valueOf(JSON.serialize(result));
            api_log.Status__c = 'Success';
            api_log.Request__c = jSONRequestBody;
           	api_log.Response__c = JSON.serialize(result);
            
        }catch(exception e){
            api_log.Exception_Description__c = e.getMessage() + ' : ' + e.getCause() + ' : ' + e.getStackTraceString();
            
            result.put('StatusCode','400');
            result.put('Message',e.getMessage());
            
            
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
        string plant; // Lookup
        String plantGstinNo;
        Decimal salesValueInDocCurrency;
        Decimal salesValueInLocalCurrency;
        Decimal totalTaxValue;
        Decimal totalGrossValue;
        string profitCentre; // Lookup
        String invoiceStatus; // Picklist
        string salesPerson; // Lookup
        
        List<WrapperLine>invline;
    }
    
    
    public class WrapperLine {
        public String baseUOM { get; set; }
        public String cgstRate { get; set; }
        public String cgstValue { get; set; }
        public String currencyIsoCode { get; set; }
        public String igstRate { get; set; }
        public String igstValue { get; set; }
        public String invoice { get; set; }
        public String itemDescription { get; set; }
        public String itemQty { get; set; }
        public String itemTaxableValue { get; set; }
        public String name { get; set; }
        public String packSize { get; set; }
        public String product { get; set; }
        public String salesItemNo { get; set; }
        public String salesUOM { get; set; }
        public String sgstRate { get; set; }
        public String sgstValue { get; set; }
        
        public WrapperLine() {}
    }
    
    
    public static List < wrapper > parse(String json) {
        return (List < wrapper > ) System.JSON.deserialize(json, List < wrapper > .class);
    }
    
}