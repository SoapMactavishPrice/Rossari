@RestResource(urlMapping='/Test_UpsertCustomer')
global class KT_UpsertCustomerAPI {
    
    @HttpPost
    global static void doPost() {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        
        Map<String, Object> responseMap = new Map<String, Object>();
        try {

            String jSONRequestBody = request.requestBody.toString().replace('\n', '');
            System.debug('jSONRequestBody=' + jSONRequestBody);
    
            customerWrapper customerWrapperData = parse(jSONRequestBody);
    
            System.debug('customerWrapperData=' + customerWrapperData);

            if (String.isBlank(customerWrapperData.CustomerCode)) {
                throw new CustomException('Customer Code is required');
            }

            List<Account> existingAcc = [
                SELECT Id
                FROM Account
                WHERE SAP_Customer_Code__c = :customerWrapperData.CustomerCode
            ];

            Account acc = new Account();
            if (existingAcc.size() > 0) {
                acc.Id = existingAcc[0].Id;
            } else {
                acc = new Account();
            }
            acc.Name = customerWrapperData.CustomerName;
            acc.SAP_Customer_Code__c = customerWrapperData.CustomerCode;
            acc.Phone = customerWrapperData.CustomerPhone;
            acc.Email_Id__c = customerWrapperData.CustomerEmail;
            acc.Credit_Limit__c = Decimal.valueOf(customerWrapperData.CustomerCreditLimit);
            
            update acc;
            
            responseMap.put('status', 'success');
            responseMap.put('message', 'Customer Inserted Successfully');
            responseMap.put('customerId', acc.Id);
            response.statusCode = 200;
            response.responseBody = Blob.valueOf(JSON.serialize(responseMap));
            
        } catch (Exception e) {
            responseMap.put('status', 'error');
            responseMap.put('message', e.getMessage());
            response.statusCode = 400;
            response.responseBody = Blob.valueOf(JSON.serialize(responseMap));
        }


        
    }

    public class customerWrapper {
        public String CustomerCode;
        public String CustomerPhone;
        public String CustomerEmail;
        public String CustomerName;
        public String CustomerCreditLimit;
    }

    public static customerWrapper parse(String json) {
        return (customerWrapper) System.JSON.deserialize(json, customerWrapper.class);
    }

}