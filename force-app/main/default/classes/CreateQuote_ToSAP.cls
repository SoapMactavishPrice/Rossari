public class CreateQuote_ToSAP {

    public static void pushQuoteToSAP(String qId) {

        String responseBodyData = '';

        API_log__c apiLog=new API_log__c();
        apiLog.Name ='CreateQuote_ToSAP';

        try {

            //  Create API JSON request
            String jsonBody = createJSONrequest(qId);
            apiLog.Request__c = jsonBody;

            // Define API URL
            // String apiUrl = label.CreateCustomerOracle;
            String apiUrl = 'https://vhrblqs4ci.sap.rossari.com:20400/sap/opu/odata/sap/API_SALES_INQUIRY_SRV/?format=json$metadata';

            // Authentication Header
            // String username = label.api_username;
            // String password = label.api_pass;
            // String authHeader = 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(username + ':' + password));
            String username = 'GRBIT00010';
            String password = 'Saansu97@12';
            String authHeader = 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(username + ':' + password));

            // Create HTTP request
            HttpRequest req = new HttpRequest();
            req.setEndpoint(apiUrl);
            req.setMethod('GET');
            req.setHeader('Content-Type', 'application/json');
            // req.setHeader('Authorization', authHeader);
            // req.setBody(jsonBody);
            req.setTimeout(120000);

            // Send HTTP request
            Http http = new Http();
            HttpResponse res = http.send(req);

            String responseBody = res.getBody();
            System.debug(responseBody);
            List<QuoteResponse> responseList = (List<QuoteResponse>) JSON.deserialize(responseBody, List<QuoteResponse>.class);
            // responseBodyData = parseresponseBodyData(responseBody, soId);
            responseBodyData = responseBody;

            if(res.getStatusCode() == 200) {
                apiLog.Status__c = 'Success';
            } else {
                apiLog.Status__c = 'Failure';
            }

            apiLog.Response__c = res.getBody();
            
        } catch (Exception e) {

            apiLog.Exception_Description__c = e.getMessage() +' : '+e.getCause()+' : '+e.getStackTraceString();
            apiLog.Status__c = 'Failed';
            
        } finally {
            insert apiLog;
        }

    }

    public static String createJSONrequest (String qId){

        Quote quo = [
            SELECT Id, Name, Sales_Organisations__c, Sales_Organisations__r.Name, Distribution_Channel__c, Distribution_Channel__r.Distribution_Code__c,
            Division__c, Division__r.Division_Code__c, Plant_code__c, Plant_code__r.Name, Sold_to_Party__c, Sold_to_Party__r.Partner_SAP_Code__c, Ship_to_Party__c,
            Ship_to_Party__r.Partner_SAP_Code__c, Bill_to_Party__c, Bill_to_Party__r.Partner_SAP_Code__c, Quote_Document_Type__c, Quote_Document_No__c,
            Quote_Document_Version__c, Sales_office__c, Sales_Group__c, PO_No__c, PO_Date__c, Quote_Valid_From__c, Reqd_Del_Date__c, Delivery_Plant__c,
            Payment_Terms__c, Inco_Remark__c, Inco_Terms__c, Order_Reason__c, CurrencyIsoCode, Exchange_Rate__c, Total_Wt__c, Shipping_Plant__c, Route__c,
            Material_Freight_Group__c, Over_Delivery_Tolerance__c, Under_Delivery_Tolerance__c, UnLimited_Tolerance__c, Net_Wt__c, Gross_Wt__c, Status,
            Reason_for_Rejection__c, Enquiry_No__c FROM Quote
            WHERE Id =: qId
        ];

        Map<String, Object> quoteHeader = new Map<String, Object>();

        // NTC (Need to Check)

        // Simple Fields
        quoteHeader.put('SF_ID', '');
        quoteHeader.put('QuoteOwner', ''); // NTC
        quoteHeader.put('SalesOrganisation', 'SO01');
        quoteHeader.put('DistributionChannel', 'DC01');
        quoteHeader.put('Division', 'DIV01');
        quoteHeader.put('PlantCode', 'PL01');
        quoteHeader.put('SoldToParty', '');
        quoteHeader.put('ShipToParty', '');
        quoteHeader.put('BillToParty', '');
        quoteHeader.put('QuoteDocumentType', 'QT01');
        quoteHeader.put('QuoteDocumentNo', 'Q-000123');
        quoteHeader.put('QuoteDocumentVersion', 1);
        quoteHeader.put('SalesOffice', 'SOF01');
        quoteHeader.put('SalesGroup', 'SG01');
        quoteHeader.put('PONo', 'PO-456789');
        quoteHeader.put('PODate', '2025-08-25');
        quoteHeader.put('ValidFrom', '2025-08-25');
        quoteHeader.put('ValidTo', '2025-09-25'); // NTC
        quoteHeader.put('ReqdDelDate', '2025-09-10');
        quoteHeader.put('DeliveryPlant', 'PL02');
        quoteHeader.put('PaymentTerms', 'NET30');
        quoteHeader.put('IncoTerms', 'FOB');
        quoteHeader.put('IncoRemark', 'Delivery at port');
        quoteHeader.put('OrderReason', 'New Order');
        quoteHeader.put('DocumentCurrency', 'USD');
        quoteHeader.put('ExchangeRate', 1.23);
        quoteHeader.put('TotalWt', 1200.50);
        quoteHeader.put('ShippingPlant', 'PL03');
        quoteHeader.put('Route', 'R01');
        quoteHeader.put('MaterialFreightGroup', 'MFG01');
        quoteHeader.put('OverDeliveryTolerance', 5);
        quoteHeader.put('UnderDeliveryTolerance', 2);
        quoteHeader.put('UnLimitedTolerance', false);
        quoteHeader.put('NetWt', 1150.00);
        quoteHeader.put('GrossWt', 1250.00);
        quoteHeader.put('Status', 'Open');
        quoteHeader.put('ReasonForRejection', 'None');
        quoteHeader.put('EnquiryNo', 'ENQ-987654');

        // ========== Nested Arrays ==========

        // Quote Header Special Instructions
        List<Object> specialInstructions = new List<Object>();
        specialInstructions.add(new Map<String, Object>{
            'SF_ID' => '',
            'InstructionType' => 'Handling',
            'InstructionDescription' => 'Keep under 25°C during transport'
        });
        quoteHeader.put('QuoteHeaderSpecialInstructions', specialInstructions);

        // Quote Header Texts
        List<Object> headerTexts = new List<Object>();
        headerTexts.add(new Map<String, Object>{
            'SF_ID' => '',
            'TextType' => 'Note',
            'TextDescription' => 'Quote valid for 30 days only',
            'DocumentUpload' => null
        });
        quoteHeader.put('QuoteHeaderTexts', headerTexts);

        // Quote Header Partner Functions
        List<Object> partnerFunctions = new List<Object>();
        partnerFunctions.add(new Map<String, Object>{
            'SF_ID' => '',
            'PartnerFunction' => 'Sales Representative',
            'PartnerCode' => 'P-001',
            'Name' => 'John Sales'
        });
        quoteHeader.put('QuoteHeaderPartnerFunctions', partnerFunctions);

        // Quote Line Items
        List<Object> lineItems = new List<Object>();

        Map<String, Object> lineItem = new Map<String, Object>{
            'SF_ID' => '',
            'ItemNumber' => 'ITM01',
            'ItemDescription' => 'Product A',
            'Qty' => 100,
            'SalesUOM' => 'PCS',
            'ItemCategory' => 'Standard',
            'ListPrice' => 50.00,
            'PlantCode' => 'PL01',
            'FirstDate' => '2025-09-05',
            'HSNCode' => 'HSN1234',
            'BatchNo' => 'BATCH001',
            'GSTAmount' => 900.00,
            'BasicAmount' => 5000.00,
            'GrandTotal' => 5900.00,
            'EnquiryDocumentNo' => 'ENQ-987654',
            'EnquiryDocumentLineItemNo' => 'ENQ-LN-001'
        };

        // Quote Condition Types under Line Item
        List<Object> conditionTypes = new List<Object>();
        conditionTypes.add(new Map<String, Object>{
            'SF_ID' => '',
            'StepNo' => 10,
            'ConditionType' => 'DISCOUNT',
            'Name' => 'Seasonal Discount',
            'Amount' => 500.00,
            'Currency' => 'USD',
            'UOM' => 'PCS',
            'CalculationType' => 'Percentage',
            'FromStepNo' => 0,
            'ToStepNo' => 10,
            'PlusMinus' => -1
        });
        lineItem.put('QuoteConditionTypes', conditionTypes);

        // Quote Scheduling
        List<Object> scheduling = new List<Object>();
        scheduling.add(new Map<String, Object>{
            'SF_ID' => '',
            'DeliveryDate' => '2025-09-10',
            'OrderQuantity' => 60,
            'ConfirmedQuantity' => 60
        });
        lineItem.put('QuoteScheduling', scheduling);

        // Quote Detail Texts
        List<Object> detailTexts = new List<Object>();
        detailTexts.add(new Map<String, Object>{
            'SF_ID' => '',
            'TextType' => 'Note',
            'TextDescription' => 'Handle with care',
            'DocumentUpload' => 'https://example.com/documents/care-guide.pdf'
        });
        lineItem.put('QuoteDetailTexts', detailTexts);

        lineItems.add(lineItem);

        quoteHeader.put('QuoteLineItems', lineItems);

        // ==================
        // Convert to JSON if needed
        String jsonString = JSON.serializePretty(quoteHeader);
        // System.debug(jsonString);


        return '';
    }

    public class QuoteResponse {
    }

}