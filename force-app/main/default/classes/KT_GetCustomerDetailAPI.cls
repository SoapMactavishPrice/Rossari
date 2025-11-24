@RestResource(urlMapping='/Test_GetCustomerDetail')
global class KT_GetCustomerDetailAPI {
    
    @HttpGet
    global static void doGet() {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;

        String customerCode = request.params.get('customerCode');
        String customerEmail = request.params.get('customerEmail');
        String customerPhone = request.params.get('customerPhone');

        Map<String, Object> responseMap = new Map<String, Object>();

        try {

            if (String.isBlank(customerCode) && String.isBlank(customerEmail) && String.isBlank(customerPhone)) {
                throw new CustomException('Customer Code, Email or Phone is required');
            }

            List<Account> getCustomerList = new List<Account>();

            if (!String.isBlank(customerCode)) {
                getCustomerList = [
                    SELECT Id, Name, Landline_No_1__c, Email_Id__c, SAP_Customer_Code__c, Street1__c
                    FROM Account
                    WHERE SAP_Customer_Code__c = :customerCode
                ];
            } else if (!String.isBlank(customerEmail)) {
                getCustomerList = [
                    SELECT Id, Name, Landline_No_1__c, Email_Id__c, SAP_Customer_Code__c, Street1__c
                    FROM Account
                    WHERE Email_Id__c = :customerEmail
                ];
            } else if (!String.isBlank(customerPhone)) {
                getCustomerList = [
                    SELECT Id, Name, Landline_No_1__c, Email_Id__c, SAP_Customer_Code__c, Street1__c
                    FROM Account
                    WHERE Landline_No_1__c = :customerPhone
                ];
            }
            
            if (getCustomerList.isEmpty()) {
                throw new CustomException('Customer not found');
            }

            List<Map<String, Object>> customerList = new List<Map<String, Object>>();
            for (Account acc : getCustomerList) {
                Map<String, Object> customer = new Map<String, Object>();
                customer.put('customerCode', acc.SAP_Customer_Code__c);
                customer.put('customerName', acc.Name);
                customer.put('customerEmail', acc.Email_Id__c);
                customer.put('customerPhone', acc.Landline_No_1__c);
                customer.put('customerAddress', acc.Street1__c);
                customerList.add(customer);
            }

            responseMap.put('status', 'success');
            responseMap.put('customerData', customerList);
            response.statusCode = 200;
            response.responseBody = Blob.valueOf(JSON.serialize(responseMap));
            
        } catch (Exception e) {
            responseMap.put('status', 'error');
            responseMap.put('message', e.getMessage());
            response.statusCode = 400;
            response.responseBody = Blob.valueOf(JSON.serialize(responseMap));
        }

    }

}