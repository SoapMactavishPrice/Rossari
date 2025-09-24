//--- not in used====
@RestResource(urlMapping = '/CustomerPriceListUpsert')
global class CustomerPriceList_API {
    @HttpPost
    global static void doPost() {

        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        String jSONRequestBody = request.requestBody.toString().replace('\n', '');

        // ------------------- API LOG to track the request -------------------
         API_Log__c api_log = new API_Log__c();
        api_log.Name = 'CustomerPriceList_API';
        api_log.Request__c = jSONRequestBody;
         

        List < JSON2ApexSaveWebToLead > jsonDataProductList = JSON2ApexSaveWebToLead.parse(jSONRequestBody);
        System.debug('======----->jsonDataProductList' + jsonDataProductList);

        try {
            Map < String, Object > responseMap = new Map < String, Object > ();
            Map < String, String > existingProductMap = new Map < String, String > ();
            // Map<String, String> existingHSNCodeMap = new Map<String, String>();

            Set < String > materialSet = new Set < String > ();
            Set < String > accountSet = new Set < String > ();
            Set < String > salesorgSet = new Set < String > ();
            Set < String > uomSet = new Set < String > ();
            Set < String > distributionchannelSet = new Set < String > ();

            for (JSON2ApexSaveWebToLead jsonObj: jsonDataProductList) {
                if (String.isBlank(jsonObj.CUSTOMER_NUMBER)) {
                    throw new IllegalArgumentException('CUSTOMER_NUMBER cannot be blank');
                } else {
                    accountSet.add(jsonObj.CUSTOMER_NUMBER);
                }

                if (String.isBlank(jsonObj.MATERIAL)){
                    throw new IllegalArgumentException('MATERIAL cannot be blank');
                } else{
                    materialSet.add(jsonObj.MATERIAL);
                }
                
                 if (jsonObj.SALES_ORGANIZATION != null) {
                    salesorgSet.add(jsonObj.SALES_ORGANIZATION);
                }
                
                if (jsonObj.UOM != null) {
                    uomSet.add(jsonObj.UOM);
                }
                
                if (jsonObj.DISTRIBUTION_CHANNEL != null) {
                    distributionchannelSet.add(jsonObj.DISTRIBUTION_CHANNEL);
                }
            }

            List < Account > Accountlist = new List < Account > ();

            List < Account > existingAccountList = [
                SELECT Id, Name, SAP_Customer_Code__c
                FROM Account
                WHERE SAP_Customer_Code__c IN: accountSet
            ];

            Map < String, Id > accountMap = new Map < String, Id > ();
            for (Account account: existingAccountList) {
                accountMap.put(account.SAP_Customer_Code__c, account.Id);
            }

            List < Product2 > Productlist = new List < Product2 > ();

            List < Product2 > existingProductList = [
                SELECT Id, Name, ProductCode
                FROM Product2
                WHERE ProductCode IN: materialSet
            ];

            Map < String, Id > materialMap = new Map < String, Id > ();
            for (Product2 product: existingProductList) {
                materialMap.put(product.ProductCode, product.Id);
            }
            
            List < Sales_Organisation__c > SalesOrglist = new List < Sales_Organisation__c > ();

            List < Sales_Organisation__c > existingSalesOrglist = [
                SELECT Id, Name
                FROM Sales_Organisation__c
                WHERE Name IN: salesorgSet
            ];

            Map < String,String > salesorgMap = new Map < String,String > ();
            for (Sales_Organisation__c salesorg: existingSalesOrglist) {
                salesorgMap.put(salesorg.Name, salesorg.Id);
            }
            
            
             List < Base_UoM_Master__c > uomlist = new List < Base_UoM_Master__c > ();

            List < Base_UoM_Master__c > existinguomlist = [
                SELECT Id, Name
                FROM Base_UoM_Master__c
                WHERE Name IN: uomSet
            ];

            Map < String, String > uomMap = new Map < String, String > ();
            for (Base_UoM_Master__c uom: existinguomlist) {
                uomMap.put(uom.Name, uom.Id);
            }
            
            
            
             List < Distribution_Channel__c > existingdistchannel = [
                SELECT Id, Name
                FROM Distribution_Channel__c
                WHERE Name IN: distributionchannelSet
            ];

            Map < String, String > distchannelmap = new Map < String, String > ();
            for (Distribution_Channel__c distch: existingdistchannel) {
                distchannelmap.put(distch.Name, distch.Id);
            }

            List < Customer_Material_Pricelist__c > upsertProductList = new List < Customer_Material_Pricelist__c > ();

            // Get Existing Customer_Material_Pricelist__c
            List < Customer_Material_Pricelist__c > existingCustomerMaterialPricelist = [
                SELECT Id, Name, Customer__c, Material__c,
                Customer__r.SAP_Customer_Code__c, Material__r.ProductCode, Sales_Organization__r.Name,UOM__r.Name,Distribution_Channel__r.Name
                FROM Customer_Material_Pricelist__c
                WHERE Customer__c IN: accountMap.values() And Material__c IN: materialMap.values()
            ];

            Map < String, String > exCustMaterialPlistMap = new Map < String, String > ();

            for (Customer_Material_Pricelist__c customerMaterialPricelist: existingCustomerMaterialPricelist) {
                exCustMaterialPlistMap.put(customerMaterialPricelist.Customer__r.SAP_Customer_Code__c + customerMaterialPricelist.Material__r.ProductCode, customerMaterialPricelist.Id);
            }

            for (JSON2ApexSaveWebToLead jsonObj: jsonDataProductList) {
                Customer_Material_Pricelist__c p = new Customer_Material_Pricelist__c();

                if (exCustMaterialPlistMap.containsKey(jsonObj.CUSTOMER_NUMBER + jsonObj.MATERIAL)) {
                    p.Id = exCustMaterialPlistMap.get(jsonObj.CUSTOMER_NUMBER + jsonObj.MATERIAL);
                } else {
                    p.Customer__c = accountMap.get(jsonObj.CUSTOMER_NUMBER);
                    p.Material__c = materialMap.get(jsonObj.MATERIAL);
                 //   p.Sales_Organization__c = jsonObj.SALES_ORGANIZATION;
                 //   p.UOM__c = jsonObj.UOM;
                }

                if (jsonObj.MATERIAL_PRICE != null && jsonObj.MATERIAL_PRICE != '') {
                    String mpStr = jsonObj.MATERIAL_PRICE.replaceAll('\\s+', '');
                    p.Material_Price__c = Decimal.valueOf(mpStr);
                }

               
                if(salesorgMap.containsKey(jsonObj.SALES_ORGANIZATION)){
                     p.Sales_Organization__c  = salesorgMap.get(jsonObj.SALES_ORGANIZATION);
                }
                
                if(uomMap.containsKey(jsonObj.UOM)){
                     p.UOM__c= uomMap.get(jsonObj.UOM);
                }

              	if(distchannelmap.containsKey(jsonObj.DISTRIBUTION_CHANNEL)){
                     p.Distribution_Channel__c= distchannelmap.get(jsonObj.DISTRIBUTION_CHANNEL);
                }

                if (jsonObj.PER != null) {
                    String perStr = jsonObj.PER.replaceAll('\\s+', '');
                    p.PER__c = Decimal.valueOf(perStr);
                }
                
                if (jsonObj.VALID_FROM != null && jsonObj.VALID_FROM != '') {
                    p.Valid_From__c = Date.valueOf(jsonObj.VALID_FROM);
                }
                
                if (jsonObj.VALID_TO != null && jsonObj.VALID_TO != '') {
                    String validtoStr = jsonObj.VALID_TO.replace('9999', '2030');
                    p.Valid_To__c = Date.valueOf(validtoStr);
                }

                upsertProductList.add(p);

            }

            if (upsertProductList.size() > 0) {
                upsert upsertProductList;
            }
            
            responseMap.put('status', 'success');
            responseMap.put('message', 'Inserted/Updated Successfully');
            
            String resp = JSON.serialize(responseMap);
            response.responseBody = Blob.valueOf(resp);
            response.addHeader('Content-Type', 'application/json');
            response.statusCode = 200;
            
             api_log.Status__c = 'Success';
             api_log.Response__c = '200';
             api_log.Response__c = String.valueOf(resp);

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
            errorResMap.put('message', e.getlineNumber() + ' || ' + e.getMessage());

            // ------------------- Send Response Map -------------------
            String resp = JSON.serialize(errorResMap);
            response.responseBody = Blob.valueOf(resp);
            response.addHeader('Content-Type', 'application/json');
            response.statusCode = 400;

             api_log.Status__c = 'Failed';
             api_log.Response__c = '400';
             api_log.Exception_Description__c = 'Line Number : ' + e.getLineNumber() + ' \n\n ' + e.getMessage() + '\n\n' + e.getStackTraceString();
             

        }

         insert api_log;
    }
    public class JSON2ApexSaveWebToLead {
        public String CUSTOMER_NUMBER;// SAP Customer Code
        public String MATERIAL;// Product Code
        public String MATERIAL_PRICE;
        public String SALES_ORGANIZATION;
        public String UOM;
        public String DISTRIBUTION_CHANNEL;
        public String PER;
        public String VALID_FROM;
        public String VALID_TO;
    }

    public static List < JSON2ApexSaveWebToLead > parse(String json) {
        return (List < JSON2ApexSaveWebToLead > ) System.JSON.deserialize(json, List < JSON2ApexSaveWebToLead > .class);
    }

}