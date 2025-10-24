public with sharing class SampleOutController {
    
    @AuraEnabled(cacheable=true)
    public static ResponseWrapper getSampleRequestData(Id sampleRequestId) {
        ResponseWrapper response = new ResponseWrapper();

        try {
            Sample_Request__c request = [
                SELECT Id, Name, CurrencyIsoCode, Lead__c, Customer_Name__c,
                    Lead__r.Street_1__c,
                    Lead__r.Street_2__c,
                    Lead__r.Street_3__c,
                    Lead__r.Pin_Code__c,
                    Lead__r.City__c,
                    Lead__r.State__c,
                    Lead__r.Country__c,
                    Lead__r.Shipping_Street_1__c,
                    Lead__r.Shipping_Street_2__c,
                    Lead__r.Shipping_Street_3__c,
                    Lead__r.Shipping_Pin_Code__c,
                    Lead__r.Shipping_City__c,
                    Lead__r.Shipping_State__c,
                    Lead__r.Shipping_Country__c,
                    Customer_Name__r.Name
                FROM Sample_Request__c
                WHERE Id = :sampleRequestId
                LIMIT 1
            ];

            response.requestNumber = request.Name;
            response.currencyCode = request.CurrencyIsoCode;

            
            if (request.Lead__c != null) {
                response.address = new Map<String, String>{
                    
                    'Street1' => request.Lead__r.Street_1__c,
                    'Street2' => request.Lead__r.Street_2__c,
                    'Street3' => request.Lead__r.Street_3__c,
                    'PinCodeId' => request.Lead__r.Pin_Code__c,
                    'CityId' => request.Lead__r.City__c,
                    'StateId' => request.Lead__r.State__c,
                    'CountryId' => request.Lead__r.Country__c,

                    
                    'ShippingStreet1' => request.Lead__r.Shipping_Street_1__c,
                    'ShippingStreet2' => request.Lead__r.Shipping_Street_2__c,
                    'ShippingStreet3' => request.Lead__r.Shipping_Street_3__c,
                    'ShippingPinCodeId' => request.Lead__r.Shipping_Pin_Code__c,
                    'ShippingCityId' => request.Lead__r.Shipping_City__c,
                    'ShippingStateId' => request.Lead__r.Shipping_State__c,
                    'ShippingCountryId' => request.Lead__r.Shipping_Country__c,

                    'Source' => 'Lead'
                };
            } else if (request.Customer_Name__c != null) {
                
                List<Address_Information__c> billingAddresses = [
                    SELECT Id, Name, Street_1__c, Street_2__c, Street_3__c,
                        Pin_Code__c, City__c, State__c, Country__c
                    FROM Address_Information__c
                    WHERE Account__c = :request.Customer_Name__c
                    AND RecordType.Name = 'Bill To'
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];

                List<Address_Information__c> shippingAddresses = [
                    SELECT Id, Name, Street_1__c, Street_2__c, Street_3__c,
                        Pin_Code__c, City__c, State__c, Country__c
                    FROM Address_Information__c
                    WHERE Account__c = :request.Customer_Name__c
                    AND RecordType.Name = 'Ship To'
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];

                Map<String, String> accountAddressMap = new Map<String, String>();

                if (!billingAddresses.isEmpty()) {
                    Address_Information__c billTo = billingAddresses[0];
                    accountAddressMap.put('Street1', billTo.Street_1__c);
                    accountAddressMap.put('Street2', billTo.Street_2__c);
                    accountAddressMap.put('Street3', billTo.Street_3__c);
                    accountAddressMap.put('PinCodeId', billTo.Pin_Code__c);
                    accountAddressMap.put('CityId', billTo.City__c);
                    accountAddressMap.put('StateId', billTo.State__c);
                    accountAddressMap.put('CountryId', billTo.Country__c);
                }

                if (!shippingAddresses.isEmpty()) {
                    Address_Information__c shipTo = shippingAddresses[0];
                    accountAddressMap.put('ShippingStreet1', shipTo.Street_1__c);
                    accountAddressMap.put('ShippingStreet2', shipTo.Street_2__c);
                    accountAddressMap.put('ShippingStreet3', shipTo.Street_3__c);
                    accountAddressMap.put('ShippingPinCodeId', shipTo.Pin_Code__c);
                    accountAddressMap.put('ShippingCityId', shipTo.City__c);
                    accountAddressMap.put('ShippingStateId', shipTo.State__c);
                    accountAddressMap.put('ShippingCountryId', shipTo.Country__c);
                }

                if (!accountAddressMap.isEmpty()) {
                    accountAddressMap.put('Source', 'Account');
                    response.address = accountAddressMap;
                }
            }

            response.lineItems = [
                SELECT 
                    Id, 
                    Product__c, 
                    Product__r.Name, 
                    Product__r.ProductCode,
                    Sample_Request_To_Plant__c,
                    Sample_Qty_in_Kgs__c,
                    Description__c,
                    Sales_Price__c
                FROM Sample_Request_Line_Item__c
                WHERE Sample_Request__c = :sampleRequestId
                AND Status__c = 'Ready' 
                ORDER BY CreatedDate
            ];

            response.plants = [
                SELECT Id, Name, Plant_Name__c 
                FROM Plant__c 
                ORDER BY Name
            ];

        } catch (Exception e) {
            throw new AuraHandledException('Error fetching data: ' + e.getMessage());
        }

        return response;
    }

    
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getAddressDataByPin(Id pinCodeId) {
        Map<String, String> result = new Map<String, String>();
        
        Pin_Code__c pin = [
            SELECT Id, Name, City__c, City__r.Name, 
            City__r.State__c, City__r.State__r.Name,
            City__r.State__r.Country__c, City__r.State__r.Country__r.Name,
            City__r.State__r.Zone__c, City__r.State__r.Country__r.Region__c
            FROM Pin_Code__c
            WHERE Id = :pinCodeId
            LIMIT 1
        ];
        
        if (pin != null) {
            result.put('cityId', pin.City__c);
            result.put('stateId', pin.City__r.State__c);
            result.put('countryId', pin.City__r.State__r.Country__c);
            result.put('zone', pin.City__r.State__r.Zone__c);
            result.put('region', pin.City__r.State__r.Country__r.Region__c);
        }
        
        return result;
    }
    
    @AuraEnabled(cacheable=true)
    public static String getCurrencyFromRequest(Id sampleRequestId) {
        try {
            Sample_Request__c request = [
                SELECT CurrencyIsoCode 
                FROM Sample_Request__c 
                WHERE Id = :sampleRequestId 
                LIMIT 1
            ];
            return request.CurrencyIsoCode;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching currency: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, List<Map<String, String>>> getPicklistValues() {
        Map<String, List<Map<String, String>>> result = new Map<String, List<Map<String, String>>>();
        
        // Get SAP Sample Document Type picklist values
        List<Map<String, String>> sapOptions = new List<Map<String, String>>();
        List<Schema.PicklistEntry> sapEntries = Sample_Out__c.SAP_Sample_Document_Type__c.getDescribe().getPicklistValues();
        for (Schema.PicklistEntry entry : sapEntries) {
            sapOptions.add(new Map<String, String>{
                'label' => entry.getLabel(),
                'value' => entry.getValue()
            });
        }
        result.put('sapSampleDocOptions', sapOptions);
        
        // Get Inco Terms picklist values
        List<Map<String, String>> incoOptions = new List<Map<String, String>>();
        List<Schema.PicklistEntry> incoEntries = Sample_Out__c.Inco_Terms__c.getDescribe().getPicklistValues();
        for (Schema.PicklistEntry entry : incoEntries) {
            incoOptions.add(new Map<String, String>{
                'label' => entry.getLabel(),
                'value' => entry.getValue()
            });
        }
        result.put('incoTermsOptions', incoOptions);
        
        return result;
    }
    
    
    public class SampleOutData {
        @AuraEnabled public Id SampleRequest;
        @AuraEnabled public Date SampleSentByFactoryToHO;
        @AuraEnabled public Date DeliveryDate;
        @AuraEnabled public Id Country;
        @AuraEnabled public Id State;
        @AuraEnabled public Id City;
        @AuraEnabled public Id PinCode;
        @AuraEnabled public String Street1;
        @AuraEnabled public String Street2;
        @AuraEnabled public String Street3;
        @AuraEnabled public String SAPSampleDocumentType;
        @AuraEnabled public String IncoTerms;
        @AuraEnabled public String CurrencyIsoCode;
        @AuraEnabled public String SampleReceivedByEndPerson;

        // Shipping Address Fields
        @AuraEnabled public String ShippingStreet1;
        @AuraEnabled public String ShippingStreet2;
        @AuraEnabled public String ShippingStreet3;
        @AuraEnabled public Id ShippingPinCodeId;
        @AuraEnabled public Id ShippingCityId;
        @AuraEnabled public Id ShippingStateId;
        @AuraEnabled public Id ShippingCountryId;
    }

    
    public class SampleOutLineData {
        @AuraEnabled public Id Product;
        @AuraEnabled public Id SampleRequestLine;
        @AuraEnabled public Decimal SampleQtyInKgs;
        @AuraEnabled public Id SampleOutPlant;
        @AuraEnabled public Decimal Price;
        @AuraEnabled public String Description;
    }
    
    @AuraEnabled
    public static Id saveSampleOut(String sampleOutJson, String sampleOutLinesJson) {
        try {
            // Validate input
            if (String.isBlank(sampleOutJson) || String.isBlank(sampleOutLinesJson)) {
                throw new AuraHandledException('Sample Out data and line items are required');
            }
            
            // Deserialize with strict typing
            SampleOutData outData = (SampleOutData)JSON.deserialize(sampleOutJson, SampleOutData.class);
            List<SampleOutLineData> lineData = (List<SampleOutLineData>)JSON.deserialize(sampleOutLinesJson, List<SampleOutLineData>.class);
            
            // Convert to SObjects
            Sample_Out__c sampleOut = new Sample_Out__c();
            sampleOut.Sample_Request__c = outData.SampleRequest;
            sampleOut.Sample_Sent_By_Factory_To_HO__c = outData.SampleSentByFactoryToHO;
            sampleOut.Delivery_Date__c = outData.DeliveryDate;
            sampleOut.Country__c = outData.Country;
            sampleOut.State__c = outData.State;
            sampleOut.City__c = outData.City;
            sampleOut.Pin_Code__c = outData.PinCode;
            sampleOut.Street_1__c = outData.Street1;
            sampleOut.Street_2__c = outData.Street2;
            sampleOut.Street_3__c = outData.Street3;
            sampleOut.SAP_Sample_Document_Type__c = outData.SAPSampleDocumentType;
            sampleOut.Inco_Terms__c = outData.IncoTerms;
            sampleOut.CurrencyIsoCode = outData.CurrencyIsoCode;
            sampleOut.Sample_Received_By_End_Person__c = outData.SampleReceivedByEndPerson;

            // Shipping fields
            sampleOut.Shipping_Street_1__c = outData.ShippingStreet1;
            sampleOut.Shipping_Street_2__c = outData.ShippingStreet2;
            sampleOut.Shipping_Street_3__c = outData.ShippingStreet3;
            sampleOut.Shipping_Pin_Code__c = outData.ShippingPinCodeId;
            sampleOut.Shipping_City__c = outData.ShippingCityId;
            sampleOut.Shipping_State__c = outData.ShippingStateId;
            sampleOut.Shipping_Country__c = outData.ShippingCountryId;

            insert sampleOut;
            
            // Create line items
            List<Sample_Out_Line__c> lines = new List<Sample_Out_Line__c>();
            for (SampleOutLineData line : lineData) {
                lines.add(new Sample_Out_Line__c(
                    Sample_Out__c = sampleOut.Id,
                    Product__c = line.Product,
                    Sample_Request_Line__c = line.SampleRequestLine,
                    Sample_Qty_in_Kgs__c = line.SampleQtyInKgs,
                    Price__c = line.Price,
                    Description__c = line.Description
                ));
            }
            
            if (!lines.isEmpty()) {
                insert lines;
            }
            
            return sampleOut.Id;
            
        } catch (Exception e) {
            System.debug('Error saving sample out: ' + e.getMessage() + ' Stack: ' + e.getStackTraceString());
            throw new AuraHandledException('Error saving record: ' + e.getMessage());
        }
    }

    
    public class ResponseWrapper {
        @AuraEnabled public String requestNumber;
        @AuraEnabled public List<Sample_Request_Line_Item__c> lineItems;
        @AuraEnabled public List<Plant__c> plants;
        @AuraEnabled public String currencyCode;
        @AuraEnabled public Map<String, String> address; // NEW
    }
    
    public static void updateSampleOutAddresses(List<Sample_Out__c> newSampleOuts) {
        Set<Id> pinCodeIds = new Set<Id>();
        for (Sample_Out__c sampleOut : newSampleOuts) {
            if (sampleOut.Pin_Code__c != null) {
                pinCodeIds.add(sampleOut.Pin_Code__c);
            }
        }
        
        if (pinCodeIds.isEmpty()) return;
        
        Map<Id, Pin_Code__c> pinMap = new Map<Id, Pin_Code__c>([
            SELECT Id, City__c, 
            City__r.State__c,
            City__r.State__r.Country__c,
            City__r.State__r.Zone__c,
            City__r.State__r.Country__r.Region__c
            FROM Pin_Code__c
            WHERE Id IN :pinCodeIds
        ]);
        
        for (Sample_Out__c sampleOut : newSampleOuts) {
            if (sampleOut.Pin_Code__c != null && pinMap.containsKey(sampleOut.Pin_Code__c)) {
                Pin_Code__c pin = pinMap.get(sampleOut.Pin_Code__c);
                sampleOut.City__c = pin.City__c;
                sampleOut.State__c = pin.City__r.State__c;
                sampleOut.Country__c = pin.City__r.State__r.Country__c;
                // sampleOut.Zone__c = pin.City__r.State__r.Zone__c;
                // sampleOut.Region__c = pin.City__r.State__r.Country__r.Region__c;
            }
        }
    }
    
    
    public static void markRequestsCompleted(List<Sample_Out__c> sampleOuts) {
        Set<Id> sampleRequestIds = new Set<Id>();
        for (Sample_Out__c so : sampleOuts) {
            if (so.Sample_Request__c != null) {
                sampleRequestIds.add(so.Sample_Request__c);
            }
        }
        
        if (!sampleRequestIds.isEmpty()) {
            List<Sample_Request__c> requestsToUpdate = [
                SELECT Id, Status__c
                FROM Sample_Request__c
                WHERE Id IN :sampleRequestIds
            ];
            
            for (Sample_Request__c sr : requestsToUpdate) {
                sr.Status__c = 'Completed';
            }
            
            if (!requestsToUpdate.isEmpty()) {
                update requestsToUpdate;
            }
        }
    }
    
}