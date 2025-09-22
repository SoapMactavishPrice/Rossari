public class CreateQuotation_ToSAP {

    @AuraEnabled
    public static string getLineItem(String qId){
        try {

            Map<String, Object> respMap = new Map<String, Object>();

            List < QuoteLineItem > quoteLineItemList = new List < QuoteLineItem > ();
            quoteLineItemList = [
                SELECT Id, Product2Id, Product2.ProductCode, QuoteId, ListPrice, UnitPrice, Quantity, Product2.Name,Discount,
                TotalPrice, Quote.AccountId
                FROM QuoteLineItem
                WHERE QuoteId = :qId
            ];

            respMap.put('quoteLineItemList', quoteLineItemList);

            return JSON.serialize(respMap);

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    // STEP 1: Create Inquiry (Header)
    @AuraEnabled
    public static String createQuotation(String quoteId) {

        API_log__c apiLog = new API_log__c();
        apiLog.Name = 'Create_Quotation_Header : ' +quoteId;

        Quote quote = [SELECT Id, Name, AccountId, Account.SAP_Customer_Code__c, Account.CurrencyIsoCode,
            Sales_Organisations__c, Distribution_Channel__c, Division__c,
            Sales_Organisations__r.Name, Distribution_Channel__r.Distribution_Code__c, Division__r.Division_Code__c
            FROM Quote WHERE Id = :quoteId
        ];

        // Define API URL
        String apiUrl = label.CreateQuotation_ToSAP;

        // Authentication Header
        String username = label.CreateQuotation_ToSAP_Username;
        String password = label.CreateQuotation_ToSAP_Pass;
        String authHeader = 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(username + ':' + password));

        HttpRequest req = new HttpRequest();
        req.setEndpoint(apiUrl); // Setup Named Credential for Create INQ
        req.setMethod('POST');
        req.setHeader('Authorization', authHeader);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setTimeout(120000);

        // Build body using Map
        Map<String, Object> responseMap = new Map<String, Object>();
        Map<String, Object> bodyMap = new Map<String, Object>();

        Map<String, Object> salesInquirySet = new Map<String, Object>();
        Map<String, Object> salesInquiry = new Map<String, Object>();

        salesInquiry.put('DocType', 'ZINQ');
        salesInquiry.put('SalesOrg', '1000');
        salesInquiry.put('DistrChan', '10');
        salesInquiry.put('Division', '10');
        salesInquiry.put('SoldToParty_buyer', '100010');
        salesInquiry.put('ShipToParty', '100010');
        // salesInquiry.put('SalesOrg', quote.Sales_Organisations__r.Name);
        // salesInquiry.put('DistrChan', quote.Distribution_Channel__r.Distribution_Code__c);
        // salesInquiry.put('Division', quote.Division__r.Division_Code__c);
        // salesInquiry.put('SoldToParty_buyer', quote.Account.SAP_Customer_Code__c);
        // salesInquiry.put('ShipToParty', quote.Account.SAP_Customer_Code__c);
        salesInquiry.put('SalesDocument', '');
        salesInquiry.put('Inco_term', '');
        salesInquiry.put('Payment_terms', '');
        salesInquiry.put('PurchNoC', '');
        salesInquiry.put('SalesPerson', '');
        salesInquiry.put('BillTo', '');
        salesInquiry.put('payer', '');
        salesInquiry.put('Date', '');
        salesInquiry.put('Destination_Text', '');
        salesInquiry.put('Sales_Note_Text', '');
        salesInquiry.put('Transpoter', '');

        salesInquirySet.put('Sales_Inquiry', salesInquiry);
        bodyMap.put('Sales_InquirySet', salesInquirySet);

        // Convert Map to JSON
        String body = JSON.serialize(bodyMap);
        System.debug('Request Body: ' + body);
        apiLog.Request__c = body;
        req.setBody(body);
        
        Http http = new Http();
        HTTPResponse res = http.send(req);

        apiLog.Response__c = res.getBody();
        
        if (res.getStatusCode() == 201) {
            // Response is XML
            Dom.Document doc = res.getBodyDocument();
            Dom.XMLNode root = doc.getRootElement(); // <Sales_InquirySet>
            Dom.XMLNode inquiry = root.getChildElement('Sales_Inquiry', null);
            String salesDoc = inquiry.getChildElement('SalesDocument', null).getText();
            
            quote.SAP_Order_No__c = salesDoc;
            update quote;

            System.debug('Extracted SalesDocument: ' + salesDoc);

            apiLog.Status__c = 'Success';
            insert apiLog;

            responseMap.put('SalesDocument', salesDoc);
            responseMap.put('StatusCode', res.getStatusCode());
            responseMap.put('message', '');

            return JSON.serialize(responseMap);
        } else {
            apiLog.Status__c = 'Failed';
            apiLog.Exception_Description__c = res.getBody();
            insert apiLog;

            System.debug('Error creating INQ: ' + res.getBody());

            responseMap.put('SalesDocument', '');
            responseMap.put('StatusCode', res.getStatusCode());
            responseMap.put('message', res.getBody());

            return res.getBody();
            // throw new CalloutException('Failed to create INQ, status: ' + res.getBody());
        }
    }
    
    // STEP 2: Add Items
    @future(callout=true)
    public static void addItems(String qLineId) {

        QuoteLineItem item = [
            SELECT Id, LineNumber, Product2Id, QuoteId, Product2.ProductCode,
            Quantity, Quote.SAP_Order_No__c
            FROM QuoteLineItem
            WHERE Id = :qLineId
        ];

        API_log__c apiLog = new API_log__c();
        apiLog.Name = 'Create_Quotation_Line : ' +item.Id;
        // Define API URL
        String apiUrl = label.CreateQuotationItem_ToSAP;

        // Authentication Header
        String username = label.CreateQuotation_ToSAP_Username;
        String password = label.CreateQuotation_ToSAP_Pass;
        String authHeader = 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(username + ':' + password));

        HttpRequest req = new HttpRequest();
        req.setEndpoint(apiUrl); // Setup Named Credential for Create INQ
        req.setMethod('POST');
        req.setHeader('Authorization', authHeader);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setTimeout(120000);
        
        // Build JSON dynamically
        String body = JSON.serialize(new Map<String, Object>{
            'Sales_Inquiry_ItemSet' => new Map<String, Object>{
                'Sales_Inquiry_Item' => new Map<String, Object>{
                    'SalesDocument' => item.Quote.SAP_Order_No__c,
                    'Material' => item.Product2.ProductCode,
                    'Req_Qty' => item.Quantity,
                    'LR_Details_Text' => 'Test',
                    'Production_Instructions_Text' => 'Test'
                }
            }
        });
        
        req.setBody(body);
        
        Http http = new Http();
        HttpResponse res = http.send(req);

        apiLog.Request__c = body;
        apiLog.Response__c = res.getBody();
        
        if (res.getStatusCode() == 201) {
            apiLog.Status__c = 'Success';
            insert apiLog;
            System.debug('Item added successfully: ' + res.getBody());
        } else {
            apiLog.Status__c = 'Failed';
            apiLog.Exception_Description__c = res.getBody();
            insert apiLog;
            System.debug('Failed to add item: ' + res.getBody());
            throw new CalloutException('Error adding item: ' + res.getBody());
        }
    }

    @AuraEnabled
    public static void syncQuoteLineItems(String quoteId) {
        // String salesDoc = createQuotation(quoteId);
        List<QuoteLineItem> quoteItems = [
            SELECT Id, LineNumber, Product2Id, QuoteId, Product2.ProductCode,
            Quantity, Quote.SAP_Order_No__c
            FROM QuoteLineItem
            WHERE QuoteId = :quoteId
        ];

        for (QuoteLineItem item : quoteItems) {
            addItems(item.Id);
        }
    }

}