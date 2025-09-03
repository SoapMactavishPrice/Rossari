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
            String apiUrl = '';

            // Authentication Header
            // String username = label.api_username;
            // String password = label.api_pass;
            // String authHeader = 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(username + ':' + password));

            // Create HTTP request
            HttpRequest req = new HttpRequest();
            req.setEndpoint(apiUrl);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            // req.setHeader('Authorization', authHeader);
            req.setBody(jsonBody);
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
        return '';
    }

    public class QuoteResponse {
    }

}