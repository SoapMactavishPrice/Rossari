public with sharing class ForecastController {

    // @AuraEnabled
    // public static List<ForecastInput> getExistingForecastData() {
    //     List<ForecastInput> forecastData = new List<ForecastInput>();
    //     for (Forecast__c f : [SELECT Id, Customer_Code__c, Customer_Name__c, Customer_Name__r.Name, Product_Code__c, Product__c, Product__r.Name, SAP_ID_Salesperson__c, Salesperson__c, Salesperson__r.Name, Sales_Quantity__c, Month__c, Year__c FROM Forecast__c]) {
    //         ForecastInput forecastInput = new ForecastInput();
    //         forecastInput.id = f.Id;
    //         forecastInput.customerId = f.Customer_Name__c;
    //         forecastInput.customerCode = f.Customer_Code__c;
    //         forecastInput.customerName = f.Customer_Name__c != null ? f.Customer_Name__r.Name : '';
    //         forecastInput.materialId = f.Product__c;
    //         forecastInput.materialCode = f.Product_Code__c;
    //         forecastInput.materialDescription = f.Product__c != null ? f.Product__r.Name : '';
    //         forecastInput.salespersonCode = f.SAP_ID_Salesperson__c != null ? f.SAP_ID_Salesperson__c : '';
    //         forecastInput.salesperson = f.Salesperson__c != null ? f.Salesperson__r.Name : '';
    //         forecastInput.salesQuantity = String.valueOf(f.Sales_Quantity__c);
    //         forecastInput.iconName = 'utility:chevronright';
    //         forecastData.add(forecastInput);
    //     }
    //     return forecastData;
    // }

    // Wrapper class that matches JavaScript property names
    public class ForecastInput {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String customerId { get; set; }
        @AuraEnabled public String customerCode { get; set; }
        @AuraEnabled public String customerName { get; set; }
        @AuraEnabled public String materialId { get; set; }
        @AuraEnabled public String materialCode { get; set; }
        @AuraEnabled public String materialDescription { get; set; }
        @AuraEnabled public String salespersonCode { get; set; }
        @AuraEnabled public String salesperson { get; set; }
        @AuraEnabled public String salesQuantity { get; set; }
        @AuraEnabled public String iconName { get; set; }
    }

    public class CustomerForecast {
        @AuraEnabled public String customerId { get; set; }
        @AuraEnabled public String customerCode { get; set; }
        @AuraEnabled public String customerName { get; set; }
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String iconName { get; set; }
        @AuraEnabled public List<ProductForecast> products { get; set; }
    }

    public class ProductForecast {
        @AuraEnabled public String materialId { get; set; }
        @AuraEnabled public String materialCode { get; set; }
        @AuraEnabled public String materialDescription { get; set; }
        @AuraEnabled public String salesQuantity { get; set; }
        @AuraEnabled public String salespersonCode { get; set; }
        @AuraEnabled public String salesperson { get; set; }
        @AuraEnabled public String rowId { get; set; }
    }


    @AuraEnabled
    public static List<CustomerForecast> getExistingForecastData() {

        Map<String, CustomerForecast> customerMap = new Map<String, CustomerForecast>();

        for (Forecast__c f : [
            SELECT Id, Customer_Code__c, Customer_Name__c, Customer_Name__r.Name,
                Product_Code__c, Product__c, Product__r.Name,
                SAP_ID_Salesperson__c, Salesperson__c, Salesperson__r.Name,
                Sales_Quantity__c, Month__c, Year__c
            FROM Forecast__c
        ]) {

            // 1️⃣ Create parent key
            String custKey = f.Customer_Name__c;

            // 2️⃣ Add customer if not already added
            if (!customerMap.containsKey(custKey)) {
                CustomerForecast cf = new CustomerForecast();
                cf.customerId = f.Customer_Name__c;
                cf.customerCode = f.Customer_Code__c;
                cf.customerName = f.Customer_Name__r.Name;
                cf.id = f.Id;
                cf.iconName = 'utility:chevronright';
                cf.products = new List<ProductForecast>();
                customerMap.put(custKey, cf);
            }

            // 3️⃣ Add product under this customer
            ProductForecast pf = new ProductForecast();
            pf.materialId = f.Product__c;
            pf.materialCode = f.Product_Code__c;
            pf.materialDescription = f.Product__r != null ? f.Product__r.Name : '';
            pf.salesQuantity = String.valueOf(f.Sales_Quantity__c);
            pf.salespersonCode = f.SAP_ID_Salesperson__c != null ? f.SAP_ID_Salesperson__c : '';
            pf.salesperson = f.Salesperson__c != null ? f.Salesperson__r.Name : '';
            pf.rowId = f.Customer_Name__c + f.Product_Code__c;

            customerMap.get(custKey).products.add(pf);
        }

        // 4️⃣ Return grouped result
        return customerMap.values();
    }


    @AuraEnabled
    public static String saveForecastRecords(List<ForecastInput> forecastData, String month, String year) {
        try {
            if (forecastData == null || forecastData.isEmpty()) {
                return 'No forecast data received.';
            }

            List<Forecast__c> recordsToInsert = new List<Forecast__c>();
            Set<String> customerCodes = new Set<String>();
            Set<String> salespersonCodes = new Set<String>();
            Set<String> materialCodes = new Set<String>();
            
            // Collect all codes for lookups
            for (ForecastInput inRec : forecastData) {
                if (!String.isBlank(inRec.customerCode)) {
                    customerCodes.add(inRec.customerCode.trim());
                }
                if (!String.isBlank(inRec.salespersonCode)) {
                    salespersonCodes.add(inRec.salespersonCode.trim());
                }
                if (!String.isBlank(inRec.materialCode)) {
                    materialCodes.add(inRec.materialCode.trim());
                }
            }

            // Query Accounts for Customer lookup
            Map<String, Id> customerCodeToAccountId = new Map<String, Id>();
            if (!customerCodes.isEmpty()) {
                for (Account acc : [
                    SELECT Id, SAP_Customer_Code__c 
                    FROM Account 
                    WHERE SAP_Customer_Code__c IN :customerCodes
                ]) {
                    customerCodeToAccountId.put(acc.SAP_Customer_Code__c, acc.Id);
                }
            }

            // Query Users for Salesperson lookup
            Map<String, Id> salespersonCodeToUserId = new Map<String, Id>();
            if (!salespersonCodes.isEmpty()) {
                for (User usr : [
                    SELECT Id, SAP_User_Id__c
                    FROM User 
                    WHERE SAP_User_Id__c IN :salespersonCodes
                ]) {
                    salespersonCodeToUserId.put(usr.SAP_User_Id__c, usr.Id);
                }
            }

            // Query Product2 for Material lookup
            Map<String, Id> materialCodeToProductId = new Map<String, Id>();
            if (!materialCodes.isEmpty()) {
                for (Product2 prod : [
                    SELECT Id, ProductCode
                    FROM Product2 
                    WHERE ProductCode IN :materialCodes
                ]) {
                    materialCodeToProductId.put(prod.ProductCode, prod.Id);
                }
            }

            Integer skippedCount = 0;
            Integer customerLookupSuccess = 0;
            Integer salespersonLookupSuccess = 0;
            Integer productLookupSuccess = 0;

            for (ForecastInput inRec : forecastData) {
                // Skip records with blank customer code
                if (String.isBlank(inRec.customerCode)) {
                    skippedCount++;
                    continue;
                }

                Forecast__c f = new Forecast__c();

                // Map basic fields
                f.Customer_Code__c = inRec.customerCode != null ? inRec.customerCode.trim() : '';
                f.Product_Code__c = inRec.materialCode != null ? inRec.materialCode.trim() : '';
                f.SAP_ID_Salesperson__c = inRec.salespersonCode != null ? inRec.salespersonCode.trim() : '';

                // Handle Sales Quantity
                if (inRec.salesQuantity != null && inRec.salesQuantity.trim() != '') {
                    try {
                        f.Sales_Quantity__c = Decimal.valueOf(inRec.salesQuantity.trim());
                    } catch (Exception ex) {
                        f.Sales_Quantity__c = 0;
                    }
                } else {
                    f.Sales_Quantity__c = 0;
                }

                // Set Month and Year
                f.Month__c = month != null ? month.trim() : '';
                f.Year__c = year != null ? year.trim() : '';

                // Customer lookup
                if (customerCodeToAccountId.containsKey(inRec.customerCode.trim())) {
                    f.Customer_Name__c = customerCodeToAccountId.get(inRec.customerCode.trim());
                    customerLookupSuccess++;
                }

                // Salesperson lookup
                if (!String.isBlank(inRec.salespersonCode) && salespersonCodeToUserId.containsKey(inRec.salespersonCode.trim())) {
                    f.Salesperson__c = salespersonCodeToUserId.get(inRec.salespersonCode.trim());
                    salespersonLookupSuccess++;
                }

                // Product lookup
                if (!String.isBlank(inRec.materialCode) && materialCodeToProductId.containsKey(inRec.materialCode.trim())) {
                    f.Product__c = materialCodeToProductId.get(inRec.materialCode.trim());
                    productLookupSuccess++;
                }

                recordsToInsert.add(f);
            }

            if (recordsToInsert.isEmpty()) {
                return 'No valid records to save. All records were skipped due to blank customer codes.';
            }

            Database.SaveResult[] srResults = Database.insert(recordsToInsert, false);
            
            Integer successCount = 0;
            Integer errorCount = 0;

            for (Integer i = 0; i < srResults.size(); i++) {
                Database.SaveResult res = srResults[i];
                if (res.isSuccess()) {
                    successCount++;
                } else {
                    errorCount++;
                }
            }

            // Build result message
            String resultMessage = successCount + ' Forecast records saved successfully. ';
            resultMessage += 'Month: ' + month + ', Year: ' + year + '. ';
            
            // Add lookup statistics
            if (customerLookupSuccess > 0) {
                resultMessage += customerLookupSuccess + ' customer lookups successful. ';
            }
            if (salespersonLookupSuccess > 0) {
                resultMessage += salespersonLookupSuccess + ' salesperson lookups successful. ';
            }
            if (productLookupSuccess > 0) {
                resultMessage += productLookupSuccess + ' product lookups successful. ';
            }
            
            // Add missing lookup information
            Integer customerLookupMissing = recordsToInsert.size() - customerLookupSuccess;
            Integer salespersonLookupMissing = recordsToInsert.size() - salespersonLookupSuccess;
            Integer productLookupMissing = recordsToInsert.size() - productLookupSuccess;
            
            if (customerLookupMissing > 0) {
                resultMessage += customerLookupMissing + ' customer codes not found. ';
            }
            if (salespersonLookupMissing > 0) {
                resultMessage += salespersonLookupMissing + ' salesperson codes not found. ';
            }
            if (productLookupMissing > 0) {
                resultMessage += productLookupMissing + ' material codes not found. ';
            }
            
            // Add error information
            if (errorCount > 0) {
                resultMessage += '(' + errorCount + ' records failed). ';
            }
            
            if (skippedCount > 0) {
                resultMessage += '(' + skippedCount + ' records skipped due to blank customer codes).';
            }

            return resultMessage;

        } catch (Exception ex) {
            throw new AuraHandledException('Error saving records: ' + ex.getMessage());
        }
    }
}