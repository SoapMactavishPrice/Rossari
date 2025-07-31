@RestResource(urlMapping='/ItemMasterUpsert')
global class ItemMasterUpsert_API {
    @HttpPost
    global static void doPost() {

        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        String jSONRequestBody = request.requestBody.toString().replace('\n', '');
        
        // ------------------- API LOG to track the request -------------------
        // API_Log__c api_log = new API_Log__c();
        // api_log.API_log_Name__c = 'ItemMasterUpsert_API';
        // api_log.Request__c = jSONRequestBody;
        // api_log.Request_Created_Time__c = Datetime.now();

        List < JSON2ApexSaveWebToLead > jsonDataProductList = JSON2ApexSaveWebToLead.parse(jSONRequestBody);
        System.debug('======----->jsonDataProductList' + jsonDataProductList);

        try {
            Map<String, Object> responseMap = new Map<String, Object>();
            Map<String, String> existingProductMap = new Map<String, String>();
            // Map<String, String> existingHSNCodeMap = new Map<String, String>();

            List<Product2> upsertProductList = new List<Product2>();

            // Get Existing products list
            List < Product2 > existingProductList = [
                SELECT Id, Name, ProductCode
                FROM Product2
                WHERE ProductCode != null
            ];

            // Create key value pair of existing products and get their ID
            for (Product2 product : existingProductList) {
                existingProductMap.put(product.ProductCode, product.Id);
            }

            // Raed List of JSON data
            for (JSON2ApexSaveWebToLead jsonObj : jsonDataProductList) {
                Product2 p = new Product2();
                if (jsonObj.itemCode != null && jsonObj.itemCode != '') {
                    if (existingProductMap.containsKey(jsonObj.itemCode)) {
                        p.Id = existingProductMap.get(jsonObj.itemCode);
                    } else {
                        p.ProductCode = jsonObj.itemCode;
                    }
                    if (jsonObj.Name != null && jsonObj.Name != '') {
                        p.Name = jsonObj.Name;
                    }
                    if (jsonObj.itemDescription != null && jsonObj.itemDescription != '') {
                        p.Description = jsonObj.itemDescription;
                    }

                    upsertProductList.add(p);

                } else {
                    throw new IllegalArgumentException('itemCode required');
                }
            }

            if (upsertProductList.size() > 0) {
                upsert(upsertProductList);
            }

            responseMap.put('status', 'success');
            responseMap.put('message', 'Inserted/Updated Successfully');


            String resp = JSON.serialize(responseMap);
            response.responseBody = Blob.valueOf(resp);
            response.addHeader('Content-Type', 'application/json');
            response.statusCode = 200;

            // api_log.Status__c = 'Success';
            // api_log.Response_Code__c = '200';
            // api_log.Response__c = String.valueOf(resp);
            // api_log.response_time__c = Datetime.now();

        } catch (Exception e) {
            System.debug('Catch Error' + e.getStackTraceString());
            System.debug('Catch Error' + e.getMessage());
            System.debug('Catch Error' + e.getlineNumber());

            // ------------------- Create Response Map -------------------
            Map < string, string > errorResMap = new Map < string, string > ();
            // errorResMap.put('Message', 'Something went wrong');
            // errorResMap.put('Error1', e.getMessage());
            // errorResMap.put('Error2', '' + e.getlineNumber());
            // errorResMap.put('Error3', '' + String.valueOf(e));
            
            errorResMap.put('status', 'fail');
            errorResMap.put('message', e.getlineNumber() +' || '+e.getMessage());

            // ------------------- Send Response Map -------------------
            String resp = JSON.serialize(errorResMap);
            response.responseBody = Blob.valueOf(resp);
            response.addHeader('Content-Type', 'application/json');
            response.statusCode = 400;
            
            // api_log.Status__c = 'Failure';
            // api_log.Response_Code__c = '400';
            // api_log.Exception_Description__c = 'Line Number : ' + e.getLineNumber() + ' \n\n ' + e.getMessage() + '\n\n' + e.getStackTraceString();
            // api_log.response_time__c = Datetime.now();
            
        }
        
        // insert api_log;
    }

    public class JSON2ApexSaveWebToLead {
        public String Name;
        public String itemCode;
        public String itemDescription;
    }

    public static List < JSON2ApexSaveWebToLead > parse(String json) {
        return (List < JSON2ApexSaveWebToLead >) System.JSON.deserialize(json, List < JSON2ApexSaveWebToLead >.class);
    }

}