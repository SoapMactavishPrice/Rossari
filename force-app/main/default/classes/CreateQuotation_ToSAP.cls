public class CreateQuotation_ToSAP {
    
    // STEP 1: Create Inquiry (Header)
    public static String createInquiry(String quoteId) {

        Quote quote = [SELECT Id, Name, AccountId, Account.SAP_Customer_Code__c, Account.CurrencyIsoCode
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
        Map<String, Object> bodyMap = new Map<String, Object>();

        Map<String, Object> salesInquirySet = new Map<String, Object>();
        Map<String, Object> salesInquiry = new Map<String, Object>();

        salesInquiry.put('DocType', 'ZINQ');
        salesInquiry.put('SalesOrg', '1000');
        salesInquiry.put('DistrChan', '10');
        salesInquiry.put('Division', '10');
        salesInquiry.put('SoldToParty_buyer', '100010');
        salesInquiry.put('ShipToParty', '100010');
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

        req.setBody(body);
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        
        if (res.getStatusCode() == 200) {
            // Response is XML
            Dom.Document doc = res.getBodyDocument();
            Dom.XMLNode root = doc.getRootElement(); // <Sales_InquirySet>
            Dom.XMLNode inquiry = root.getChildElement('Sales_Inquiry', null);
            String salesDoc = inquiry.getChildElement('SalesDocument', null).getText();
            
            System.debug('Extracted SalesDocument: ' + salesDoc);
            return salesDoc;
        } else {
            System.debug('Error creating INQ: ' + res.getBody());
            throw new CalloutException('Failed to create INQ, status: ' + res.getStatus());
        }
    }
    
    // STEP 2: Add Items
    // public static void addItems(String salesDocument, List<ItemWrapper> items) {
    //     for (ItemWrapper item : items) {
    //         HttpRequest req = new HttpRequest();
    //         req.setEndpoint('callout:SAP_ITEM'); // Setup Named Credential for Item Update
    //         req.setMethod('POST');
    //         req.setHeader('Content-Type', 'application/json');
    //         req.setHeader('Accept', 'application/json');
            
    //         // Build JSON dynamically
    //         String body = JSON.serialize(new Map<String, Object>{
    //             'Sales_Inquiry_ItemSet' => new Map<String, Object>{
    //                 'Sales_Inquiry_Item' => new Map<String, Object>{
    //                     'SalesDocument' => salesDocument,
    //                     'Material' => item.material,
    //                     'Req_Qty' => item.quantity,
    //                     'LR_Details_Text' => item.lrDetails,
    //                     'Production_Instructions_Text' => item.instructions
    //                 }
    //             }
    //         });
            
    //         req.setBody(body);
            
    //         Http http = new Http();
    //         HttpResponse res = http.send(req);
            
    //         if (res.getStatusCode() == 200) {
    //             System.debug('Item added successfully: ' + res.getBody());
    //         } else {
    //             System.debug('Failed to add item: ' + res.getBody());
    //             throw new CalloutException('Error adding item: ' + res.getStatus());
    //         }
    //     }
    // }
    
    // Wrapper for items
    public class ItemWrapper {
        public String material;
        public String quantity;
        public String lrDetails;
        public String instructions;
        
        public ItemWrapper(String mat, String qty, String lr, String instr) {
            material = mat;
            quantity = qty;
            lrDetails = lr;
            instructions = instr;
        }
    }
}