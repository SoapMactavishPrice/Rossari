public with sharing class QuoteController {
    
    @AuraEnabled(cacheable=true)
    public static List<OpportunityLineItem> getOppLineItems(String opportunityId) {
        return [
            SELECT Id, Product2Id, Product2.Name, UnitPrice, Quantity, Product2.Description,
            PricebookEntryId, PricebookEntry.UnitPrice, Description, Discount,
            Customer_Material_Price__c, Last_Selling_Price__c  // Add these fields
            FROM OpportunityLineItem
            WHERE OpportunityId = :opportunityId
            ORDER BY SortOrder
        ];
    }		
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getQuoteInitialData(String opportunityId) {
        Map<String, Object> result = new Map<String, Object>();
        
        // Get opportunity details including Inco Terms and Payment Terms
        Opportunity opp = [SELECT Id, AccountId, Name, CurrencyIsoCode, Pricebook2Id, 
                           Contact__c, Contact__r.Name, Contact__r.Id,
                           Inco_Terms__c, Payment_Term__c, Payment_Term__r.Name,
                           Sales_Organisations__c, Division__c, Distribution_Channel__c,
                           Sales_Organisations__r.Name, Division__r.Division_Code__c, // Add these
                           Account.Name
                           FROM Opportunity 
                           WHERE Id = :opportunityId LIMIT 1];
        
        // Get Bill To and Ship To addresses for the Account
        List<Address_Information__c> accountAddresses = [
            SELECT Id, Name, RecordType.DeveloperName, Street_1__c, Street_2__c, Street_3__c,
            Pin_Code__c, City__c, City__r.Name, State__c, Country__c, Region__c, Zone__c
            FROM Address_Information__c 
            WHERE Account__c = :opp.AccountId
            AND RecordType.DeveloperName IN ('Bill_To', 'Ship_To')
            ORDER BY CreatedDate DESC
        ];
        
        // Separate Bill To and Ship To addresses
        List<Map<String, Object>> billToAddresses = new List<Map<String, Object>>();
        List<Map<String, Object>> shipToAddresses = new List<Map<String, Object>>();
        
        for (Address_Information__c addr : accountAddresses) {
            Map<String, Object> addressMap = new Map<String, Object>{
                'id' => addr.Id,
                'name' => addr.Name,
                'street1' => addr.Street_1__c,
                'street2' => addr.Street_2__c,
                'street3' => addr.Street_3__c,
                'pinCode' => addr.Pin_Code__c,
                'city' => addr.City__c,
                'cityName' => addr.City__r?.Name,
                'state' => addr.State__c,
                'country' => addr.Country__c,
                'region' => addr.Region__c,
                'zone' => addr.Zone__c
            };
            
            if (addr.RecordType.DeveloperName == 'Bill_To') {
                billToAddresses.add(addressMap);
            } else if (addr.RecordType.DeveloperName == 'Ship_To') {
                shipToAddresses.add(addressMap);
            }
        }
        
        // Get status picklist values
        Schema.DescribeFieldResult statusField = Quote.Status.getDescribe();
        List<Map<String, String>> statusOptions = new List<Map<String, String>>();
        for (Schema.PicklistEntry pe : statusField.getPicklistValues()) {
            if (pe.isActive()) {
                statusOptions.add(new Map<String, String>{
                    'label' => pe.getLabel(),
                        'value' => pe.getValue()
                        });
            }
        }
        
        // Get currency picklist values
        Schema.DescribeFieldResult currencyField = Opportunity.CurrencyIsoCode.getDescribe();
        List<Map<String, String>> currencyOptions = new List<Map<String, String>>();
        for (Schema.PicklistEntry pe : currencyField.getPicklistValues()) {
            if (pe.isActive()) {
                currencyOptions.add(new Map<String, String>{
                    'label' => pe.getValue(),
                        'value' => pe.getValue()
                        });
            }
        }
        
        // Get Inco Terms picklist values
        Schema.DescribeFieldResult incoTermsField = Quote.Inco_Terms__c.getDescribe();
        List<Map<String, String>> incoTermsOptions = new List<Map<String, String>>();
        for (Schema.PicklistEntry pe : incoTermsField.getPicklistValues()) {
            if (pe.isActive()) {
                incoTermsOptions.add(new Map<String, String>{
                    'label' => pe.getLabel(),
                        'value' => pe.getValue()
                        });
            }
        }
        
         Schema.DescribeFieldResult domesticDeliveryTermsField = Quote.Domestic_Delivery_Terms__c.getDescribe();
    List<Map<String, String>> domesticDeliveryTermsOptions = new List<Map<String, String>>();
    for (Schema.PicklistEntry pe : domesticDeliveryTermsField.getPicklistValues()) {
        if (pe.isActive()) {
            domesticDeliveryTermsOptions.add(new Map<String, String>{
                'label' => pe.getLabel(),
                    'value' => pe.getValue()
                    });
        }
    }
        
        // Get related contacts
        List<Contact> contacts = [
            SELECT Id, Name 
            FROM Contact 
            WHERE AccountId = :opp.AccountId
            ORDER BY Name
        ];
        
        // Get payment terms
        List<Payment_Term__c> paymentTerms = [
            SELECT Id, Name 
            FROM Payment_Term__c 
            ORDER BY Name
        ];
        List<Map<String, String>> paymentTermOptions = new List<Map<String, String>>();
        for (Payment_Term__c pt : paymentTerms) {
            paymentTermOptions.add(new Map<String, String>{
                'label' => pt.Name,
                    'value' => pt.Id
                    });
        }
        
        result.put('opportunityName', opp.Name);
        result.put('defaultCurrency', opp.CurrencyIsoCode);
        result.put('pricebookId', opp.Pricebook2Id);
        result.put('statusOptions', statusOptions);
        result.put('currencyOptions', currencyOptions);
        result.put('incoTermsOptions', incoTermsOptions);
        result.put('domesticDeliveryTermsOptions', domesticDeliveryTermsOptions);
        result.put('paymentTerms', paymentTermOptions);
        result.put('contacts', contacts);
        
        // Add address information
        result.put('billToAddresses', billToAddresses);
        result.put('shipToAddresses', shipToAddresses);
        result.put('accountName', opp.Account.Name);
        
        // Add Opportunity's Inco Terms and Payment Terms
        result.put('opportunityIncoTerms', opp.Inco_Terms__c);
        result.put('opportunityPaymentTermId', opp.Payment_Term__c);
        result.put('opportunityPaymentTermName', opp.Payment_Term__r?.Name);
        result.put('opportunityDomesticDeliveryTerms', '');
        
        // Add visibility flags for Customer Material Price and Last Selling Price columns
        String salesOrg = opp.Sales_Organisations__r?.Name;
        String division = opp.Division__r?.Division_Code__c;
        Set<String> allowedDivisions = new Set<String>{'10','11','22'};
        
        result.put('showCustomerMaterialPriceColumn', salesOrg == '1000' && allowedDivisions.contains(division));
        result.put('showLastSellingPriceColumn', salesOrg == '3000' || salesOrg == '4000');
        
        if (opp.Contact__c != null && opp.Contact__r != null) {
            result.put('defaultContact', new Map<String, String>{
                'label' => opp.Contact__r.Name,
                    'value' => opp.Contact__r.Id
                    });
        }
        
        return result;
    }
    
    // Add this method to get Customer Material Price and Last Selling Price
    @AuraEnabled(cacheable=true)
    public static Map<String, Map<String, Decimal>> getProductPricingData(String opportunityId, List<String> productIds) {
        Map<String, Map<String, Decimal>> result = new Map<String, Map<String, Decimal>>();
        
        try {
            // Get opportunity details including Sales Org and Division
            Opportunity opp = [
                SELECT Id, AccountId, Sales_Organisations__r.Name, Division__r.Division_Code__c
                FROM Opportunity 
                WHERE Id = :opportunityId 
                LIMIT 1
            ];
            
            if (opp == null || opp.AccountId == null) {
                return result;
            }
            
            String salesOrg = opp.Sales_Organisations__r?.Name;
            String division = opp.Division__r?.Division_Code__c;
            
            // Prepare Customer Material Price map
            Map<String, Decimal> customerMaterialPriceMap = new Map<String, Decimal>();
            Map<String, Decimal> lastSellingPriceMap = new Map<String, Decimal>();
            
            // 1. Get Customer Material Price (only for Sales Org '1000' and Division in {'10','11','22'})
            Set<String> allowedDivisions = new Set<String>{'10','11','22'};
            
            if (salesOrg == '1000' && allowedDivisions.contains(division)) {
                List<Customer_Material_Pricelist__c> cmpl = [
                    SELECT Id, Material__c, Material_Price__c
                    FROM Customer_Material_Pricelist__c
                    WHERE Customer__c = :opp.AccountId 
                    AND Material__c IN :productIds
                ];
                
                for (Customer_Material_Pricelist__c cm : cmpl) {
                    customerMaterialPriceMap.put(cm.Material__c, cm.Material_Price__c);
                }
            }
            
            // 2. Get Last Selling Price (only for Sales Org '3000' or '4000')
            if (salesOrg == '3000' || salesOrg == '4000') {
                List<Invoice_Line_Item__c> invItems = [
                    SELECT Id, Item_Taxable_Value__c, Product__c
                    FROM Invoice_Line_Item__c
                    WHERE Product__c IN :productIds 
                    AND Invoice__r.Customer_Name__c = :opp.AccountId
                    ORDER BY Invoice__r.CreatedDate DESC
                ];
                
                for (Invoice_Line_Item__c ili : invItems) {
                    if (!lastSellingPriceMap.containsKey(ili.Product__c)) {
                        lastSellingPriceMap.put(ili.Product__c, ili.Item_Taxable_Value__c);
                    }
                }
            }
            
            // Combine into result map
            for (String productId : productIds) {
                Map<String, Decimal> priceMap = new Map<String, Decimal>();
                priceMap.put('customerMaterialPrice', customerMaterialPriceMap.get(productId));
                priceMap.put('lastSellingPrice', lastSellingPriceMap.get(productId));
                result.put(productId, priceMap);
            }
            
            return result;
            
        } catch (Exception e) {
            System.debug('Error in getProductPricingData: ' + e.getMessage());
            return result;
        }
    }
    
    @AuraEnabled
    public static Id createQuoteFromOpportunity(
        String opportunityId, 
        List<QuoteLineItemWrapper> lineItems,
        String quoteName,
        String status,
        Date expirationDate,
        String currencyCode,
        String contactId,
        String pricebookId,
        String incoTerms,
        String paymentTermId,
        Decimal transportationCost,
        String containerType,
        String domesticDeliveryTerms,
        String selectedBillToAddressId,
        String selectedShipToAddressId
    ) {
        // Validate required parameters
        if (String.isBlank(opportunityId)) {
            throw new AuraHandledException('Opportunity ID is required');
        }
        
        // Check if quote already exists for this opportunity
        List<Quote> existingQuotes = [
            SELECT Id, Name, Status 
            FROM Quote 
            WHERE OpportunityId = :opportunityId 
            LIMIT 1
        ];
        
        if (!existingQuotes.isEmpty()) {
            throw new AuraHandledException('Quote already exists for this Opportunity.');
        }
        
        // Get opportunity with all required fields including current Payment Term and Inco Terms
        Opportunity opp = [
            SELECT Id, Pricebook2Id, CurrencyIsoCode, AccountId, Sales_Organisations__c, 
            Division__c, Distribution_Channel__c, Name, Distribution_Channel__r.Distribution_Code__c,
            Payment_Term__c, Payment_Term__r.Name, Inco_Terms__c, Account.Name
            FROM Opportunity 
            WHERE Id = :opportunityId
        ];
        
        // Get Bill To and Ship To addresses for the Account
        List<Address_Information__c> accountAddresses = [
            SELECT Id, RecordType.DeveloperName, Street_1__c, Street_2__c, Street_3__c,
            Pin_Code__c, City__c, City__r.Name, State__c,State__r.Name, Country__c,Country__r.Name,
            Pin_Code__r.Name
            FROM Address_Information__c 
            WHERE Account__c = :opp.AccountId
            AND RecordType.DeveloperName IN ('Bill_To', 'Ship_To')
            ORDER BY CreatedDate DESC
        ];
        
        // Get current user with User Type
        User currentUser = [
            SELECT Id, User_Type__c 
            FROM User 
            WHERE Id = :UserInfo.getUserId()
        ];
        
        // Get HOD User based on Distribution Channel and User Type from Custom Metadata
        User hodUser = getHODUserFromMetadata(opp.Distribution_Channel__r.Distribution_Code__c, currentUser.User_Type__c);
        
        // Determine if Payment Term or Inco Terms were changed from opportunity values
        Boolean isPaymentTermChanged = opp.Payment_Term__c != paymentTermId;
        Boolean isIncoTermsChanged = opp.Inco_Terms__c != incoTerms;
        
        // Determine final status - if terms changed, set to 'Payment/Incoterms Approval', otherwise use the provided status
        String finalStatus = status;
        if (isPaymentTermChanged || isIncoTermsChanged) {
            finalStatus = 'Payment/Incoterms Approval';
        } else if (String.isBlank(finalStatus)) {
        finalStatus = 'Working'; // Default if not provided
    }
        
        // Query the Company__c record for 'Rossari Biotech Limited'
        Company__c rossariCompany = [SELECT Id FROM Company__c WHERE Name = 'Rossari Biotech Limited' LIMIT 1];
        
        // Create the quote with all fields including previous terms logic
        Quote quote = new Quote(
            Name = quoteName,
            OpportunityId = opp.Id,
            Status = finalStatus, // Use the determined status
            Letter_Company_Name__c = rossariCompany.Id,
            ExpirationDate = expirationDate,
            Quote_Valid_From__c = Date.today(),
            Pricebook2Id = String.isNotBlank(pricebookId) ? pricebookId : opp.Pricebook2Id,
            CurrencyIsoCode = String.isNotBlank(currencyCode) ? currencyCode : opp.CurrencyIsoCode,
            ContactId = String.isNotBlank(contactId) ? contactId : null,
            HOD_of_Sales_Department__c = hodUser != null ? hodUser.Id : null,
            
            // Current terms (can be same as opportunity or changed by user)
            Inco_Terms__c = incoTerms,
            Payment_Term__c = String.isBlank(paymentTermId) ? null : paymentTermId,
             Domestic_Delivery_Terms__c = domesticDeliveryTerms,
            
            // Previous terms (store original opportunity values ONLY if changed)
            Previous_Inco_Terms__c = isIncoTermsChanged ? opp.Inco_Terms__c : null,
            Previous_Payment_Terms__c = isPaymentTermChanged ? opp.Payment_Term__c : null,
            
            Transportation_Cost__c = transportationCost != null ? transportationCost : 0.0, 
            Container_Type__c = containerType,
            Sales_Organisations__c = opp.Sales_Organisations__c,
            Division__c = opp.Division__c,
            Distribution_Channel__c = opp.Distribution_Channel__c,
            Terms_and_Conditions__c =
            'All bank charges outside India will be borne by the customer and such charges should not be deducted from our payment.\n' +
            'We should receive full invoice amount in our bank account and you are liable to pay the bank charges which are applicable in India only.\n' +
            'After finalization of order if there is any change in Statutory Govt. levies than it will be in your scope.',
            Declaration__c = 'We declare that this quotation shows the actual price of goods and that all particulars are true and correct'
        );
        
        // Auto-map Bill To address (first Bill_To record found)
        Address_Information__c billToAddress = getAddressByRecordType(accountAddresses, 'Bill_To');
        if (billToAddress != null) {
            quote.BillingName = opp.Account.Name;
            quote.BillingStreet = formatAddressLines(billToAddress.Street_1__c, billToAddress.Street_2__c, billToAddress.Street_3__c);
            quote.BillingCity = billToAddress.City__r?.Name;
            quote.BillingState = billToAddress.State__r?.Name;
            quote.BillingCountry = billToAddress.Country__r?.Name;
            quote.BillingPostalCode = billToAddress.Pin_Code__r?.Name;
        }
        
        // Auto-map Ship To address (first Ship_To record found)
        Address_Information__c shipToAddress = getAddressByRecordType(accountAddresses, 'Ship_To');
        if (shipToAddress != null) {
            quote.ShippingName = opp.Account.Name;
            quote.ShippingStreet = formatAddressLines(shipToAddress.Street_1__c, shipToAddress.Street_2__c, shipToAddress.Street_3__c);
            quote.ShippingCity = shipToAddress.City__r?.Name;
            quote.ShippingState = shipToAddress.State__r?.Name;
            quote.ShippingCountry = shipToAddress.Country__r?.Name;
            quote.ShippingPostalCode = shipToAddress.Pin_Code__r?.Name;
        }
        
        // If specific addresses are selected, use them instead
        if (String.isNotBlank(selectedBillToAddressId)) {
            Address_Information__c selectedBillToAddr = getAddressById(accountAddresses, selectedBillToAddressId);
            if (selectedBillToAddr != null && selectedBillToAddr.RecordType.DeveloperName == 'Bill_To') {
                quote.BillingName = opp.Account.Name;
                quote.BillingStreet = formatAddressLines(selectedBillToAddr.Street_1__c, selectedBillToAddr.Street_2__c, selectedBillToAddr.Street_3__c);
                quote.BillingCity = selectedBillToAddr.City__r?.Name;
                quote.BillingState = selectedBillToAddr.State__c;
                quote.BillingCountry = selectedBillToAddr.Country__c;
                quote.BillingPostalCode = selectedBillToAddr.Pin_Code__c;
            }
        }
        
        if (String.isNotBlank(selectedShipToAddressId)) {
            Address_Information__c selectedShipToAddr = getAddressById(accountAddresses, selectedShipToAddressId);
            if (selectedShipToAddr != null && selectedShipToAddr.RecordType.DeveloperName == 'Ship_To') {
                quote.ShippingName = opp.Account.Name;
                quote.ShippingStreet = formatAddressLines(selectedShipToAddr.Street_1__c, selectedShipToAddr.Street_2__c, selectedShipToAddr.Street_3__c);
                quote.ShippingCity = selectedShipToAddr.City__r?.Name;
                quote.ShippingState = selectedShipToAddr.State__c;
                quote.ShippingCountry = selectedShipToAddr.Country__c;
                quote.ShippingPostalCode = selectedShipToAddr.Pin_Code__c;
            }
        }
        
        insert quote;
        
        // Create quote line items
        List<QuoteLineItem> qliList = new List<QuoteLineItem>();
        for (QuoteLineItemWrapper itemWrapper : lineItems) {
            if (itemWrapper.Product2Id == null || itemWrapper.PricebookEntryId == null) {
                continue;
            }
            
            Decimal unitPrice = itemWrapper.UnitPrice != null ? itemWrapper.UnitPrice : 0;
            Decimal quantity = itemWrapper.Quantity != null ? itemWrapper.Quantity : 1;
            Decimal discountPercent = itemWrapper.Discount != null ? itemWrapper.Discount : 0;
            
            qliList.add(new QuoteLineItem(
                QuoteId = quote.Id,
                Product2Id = itemWrapper.Product2Id,
                PricebookEntryId = itemWrapper.PricebookEntryId,
                UnitPrice = unitPrice,
                Quantity = quantity,
                Discount = discountPercent,
                Description = itemWrapper.Description,
                Customer_Target_Price__c = itemWrapper.CustomerTargetPrice != null ? itemWrapper.CustomerTargetPrice : 0,
                Customer_Product_Name__c = itemWrapper.CustomerProductName != null ? itemWrapper.CustomerProductName : '',
                Customer_HS_Code__c = itemWrapper.CustomerHsCode != null ? itemWrapper.CustomerHsCode : '',
                // Add these new fields
                Customer_Material_Price__c = itemWrapper.CustomerMaterialPrice != null ? itemWrapper.CustomerMaterialPrice : 0,
                Last_Selling_Price__c = itemWrapper.LastSellingPrice != null ? itemWrapper.LastSellingPrice : 0
            ));
        }
        
        if (!qliList.isEmpty()) {
            insert qliList;
        }
        
        opp.StageName = 'Quotation';
        update opp;
        
        return quote.Id;
    }
    
    // Helper method to get address by record type
    private static Address_Information__c getAddressByRecordType(List<Address_Information__c> addresses, String recordTypeName) {
        for (Address_Information__c addr : addresses) {
            if (addr.RecordType.DeveloperName == recordTypeName) {
                return addr;
            }
        }
        return null;
    }
    
    // Helper method to get address by ID
    private static Address_Information__c getAddressById(List<Address_Information__c> addresses, String addressId) {
        for (Address_Information__c addr : addresses) {
            if (addr.Id == addressId) {
                return addr;
            }
        }
        return null;
    }
    
    // Helper method to format address lines
    private static String formatAddressLines(String street1, String street2, String street3) {
        List<String> addressLines = new List<String>();
        
        if (String.isNotBlank(street1)) addressLines.add(street1.trim());
        if (String.isNotBlank(street2)) addressLines.add(street2.trim());
        if (String.isNotBlank(street3)) addressLines.add(street3.trim());
        
        return String.join(addressLines, '\n');
    }
    
    // Method to get HOD User from Custom Metadata
    private static User getHODUserFromMetadata(String distributionChannelCode, String userType) {
        if (String.isBlank(distributionChannelCode) || String.isBlank(userType)) {
            return null;
        }
        
        try {
            // Query Custom Metadata for HOD mapping
            List<HOD_Mapping__mdt> hodMappings = [
                SELECT Id, DeveloperName, Distribution_Channel_Code__c, User_Type__c, HOD_User_Email__c
                FROM HOD_Mapping__mdt
                WHERE Distribution_Channel_Code__c = :distributionChannelCode
                AND User_Type__c = :userType
                LIMIT 1
            ];
            
            if (!hodMappings.isEmpty()) {
                String hodUserEmail = hodMappings[0].HOD_User_Email__c;
                
                if (String.isNotBlank(hodUserEmail)) {
                    // Query the active user by email
                    List<User> hodUsers = [
                        SELECT Id, Name, Email, User_Type__c
                        FROM User 
                        WHERE Email = :hodUserEmail 
                        AND IsActive = true 
                        LIMIT 1
                    ];
                    
                    if (!hodUsers.isEmpty()) {
                        return hodUsers[0];
                    } else {
                        System.debug('HOD User not found or inactive for email: ' + hodUserEmail);
                    }
                }
            } else {
                System.debug('No HOD Mapping found for Distribution Channel: ' + distributionChannelCode + ' and User Type: ' + userType);
            }
        } catch (Exception e) {
            System.debug('Error retrieving HOD User from Custom Metadata: ' + e.getMessage());
        }
        
        return null;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<HOD_Mapping__mdt> getHODMappings() {
        return [
            SELECT Id, DeveloperName, Distribution_Channel_Code__c, User_Type__c, HOD_User_Email__c
            FROM HOD_Mapping__mdt
            ORDER BY Distribution_Channel_Code__c, User_Type__c
        ];
    }
    
    @AuraEnabled
    public static String deleteProductInterested(String Id) {
        if (String.isBlank(Id)) {
            throw new AuraHandledException('ID is required');
        }
        
        List<OpportunityLineItem> piList = [
            SELECT Id, Name 
            FROM OpportunityLineItem 
            WHERE Id = :Id 
            LIMIT 1
        ];
        
        if (piList.isEmpty()) {
            return 'Opportunity Line Item not found for deletion.';
        }
        
        String pInName = piList[0].Name;
        delete piList[0]; 
        return 'Opportunity Line Item record deleted: ' + pInName;
    }
    
    public static void validateQuoteApprovalStatus(List<Quote> quotes, Map<Id, Quote> oldMap) {
        Set<Id> quoteIdsToCheck = new Set<Id>();
        
        // Identify quotes changing to 'Accepted'
        for (Quote q : quotes) {
            Quote oldQ = oldMap != null ? oldMap.get(q.Id) : null;
            if (q.Status == 'Accepted' && (oldQ == null || oldQ.Status != 'Accepted')) {
                quoteIdsToCheck.add(q.Id);
            }
        }
        if (quoteIdsToCheck.isEmpty()) return;
        
        // Query QuoteLineItems with needed fields
        List<QuoteLineItem> qliList = [
            SELECT Id, QuoteId, ListPrice, UnitPrice, Product2.Name, Approval_Status__c
            FROM QuoteLineItem
            WHERE QuoteId IN :quoteIdsToCheck
        ];
        
        Map<Id, Set<String>> quoteToProblemProducts = new Map<Id, Set<String>>();
        
        for (QuoteLineItem qli : qliList) {
            // Check both conditions: price below list price AND not approved
            if (qli.ListPrice != null && 
                qli.UnitPrice != null && 
                qli.UnitPrice < qli.ListPrice && 
                qli.Approval_Status__c != 'Approved' && qli.Approval_Status__c != 'Rejected' ) {
                    
                    if (!quoteToProblemProducts.containsKey(qli.QuoteId)) {
                        quoteToProblemProducts.put(qli.QuoteId, new Set<String>());
                    }
                    quoteToProblemProducts.get(qli.QuoteId).add(qli.Product2.Name);
                }
        }
        
        // Add errors to quotes with problematic products
        for (Quote q : quotes) {
            if (quoteToProblemProducts.containsKey(q.Id)) {
                List<String> productNames = new List<String>(quoteToProblemProducts.get(q.Id));
                q.addError(
                    'Quote cannot be set to Accepted. The following products have a Sales Price less than List Price ' +
                    'and Approval Status "Pending":' +
                    String.join(productNames, ', ')
                );
            }
        }
    }
    
    @AuraEnabled
    public static string getSalesOrg(String oppId){
        try {
            String retData = '';
            
            Opportunity opp = [
                SELECT Id, AccountId, Name, CurrencyIsoCode, Pricebook2Id, Contact__c, Contact__r.Name, Contact__r.Id 
                FROM Opportunity 
                WHERE Id = :oppId LIMIT 1
            ];
            
            List<Customer_Sales_Area__c> csaList = [
                SELECT Id, Comapany_Code__c, Sales_Organisation__c, Sales_Organisation__r.Name 
                FROM Customer_Sales_Area__c 
                WHERE Comapany_Code__c = :opp.AccountId
            ];
            
            List<Map<String, String>> salesOrgMapList = new List<Map<String, String>>();
            Set<String> uniqueSalesOrgSet = new Set<String>();
            
            for (Customer_Sales_Area__c csa : csaList) {
                if (!uniqueSalesOrgSet.contains(csa.Sales_Organisation__c)) {
                    uniqueSalesOrgSet.add(csa.Sales_Organisation__c);
                    
                    Map<String, String> salesOrgMap = new Map<String, String>();
                    salesOrgMap.put('label', csa.Sales_Organisation__r.Name);
                    salesOrgMap.put('value', csa.Sales_Organisation__c);
                    salesOrgMapList.add(salesOrgMap);
                }
            }
            
            if (!salesOrgMapList.isEmpty()) {
                retData = JSON.serialize(salesOrgMapList);
            }
            return retData;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static string getDistributionChannel(String oppId, String soId){
        try {
            String retData = '';
            
            Opportunity opp = [
                SELECT Id, AccountId, Name, CurrencyIsoCode, Pricebook2Id, Contact__c, Contact__r.Name, Contact__r.Id 
                FROM Opportunity 
                WHERE Id = :oppId LIMIT 1
            ];
            
            List<Customer_Sales_Area__c> csaList = [
                SELECT Id, Comapany_Code__c, Sales_Organisation__c, Sales_Organisation__r.Name, Distribution_Channel__c,
                Distribution_Channel__r.Distribution_Code__c
                FROM Customer_Sales_Area__c 
                WHERE Comapany_Code__c = :opp.AccountId
                AND Sales_Organisation__c = :soId
            ];
            
            List<Map<String, String>> distChMapList = new List<Map<String, String>>();
            Set<String> uniquedistChSet = new Set<String>();
            
            for (Customer_Sales_Area__c csa : csaList) {
                if (!uniquedistChSet.contains(csa.Distribution_Channel__c)) {
                    uniquedistChSet.add(csa.Distribution_Channel__c);
                    
                    Map<String, String> distChMap = new Map<String, String>();
                    distChMap.put('value', csa.Distribution_Channel__c);
                    distChMap.put('label', csa.Distribution_Channel__r.Distribution_Code__c);
                    distChMapList.add(distChMap);
                }
            }
            
            if (!distChMapList.isEmpty()) {
                retData = JSON.serialize(distChMapList);
            }
            return retData;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static string getDivision(String oppId, String soId, String dcId){
        try {
            String retData = '';
            
            Opportunity opp = [
                SELECT Id, AccountId, Name, CurrencyIsoCode, Pricebook2Id, Contact__c, Contact__r.Name, Contact__r.Id 
                FROM Opportunity 
                WHERE Id = :oppId LIMIT 1
            ];
            
            List<Customer_Sales_Area__c> csaList = [
                SELECT Id, Comapany_Code__c, Sales_Organisation__c, Sales_Organisation__r.Name, Distribution_Channel__c,
                Distribution_Channel__r.Distribution_Code__c, Division__c, Division__r.Division_Code__c
                FROM Customer_Sales_Area__c 
                WHERE Comapany_Code__c = :opp.AccountId
                AND Sales_Organisation__c = :soId
                AND Distribution_Channel__c = :dcId
            ];
            
            List<Map<String, String>> divisionMapList = new List<Map<String, String>>();
            Set<String> uniquedivisionSet = new Set<String>();
            
            for (Customer_Sales_Area__c csa : csaList) {
                if (!uniquedivisionSet.contains(csa.Division__c)) {
                    uniquedivisionSet.add(csa.Division__c);
                    
                    Map<String, String> divisionMap = new Map<String, String>();
                    divisionMap.put('value', csa.Division__c);
                    divisionMap.put('label', csa.Division__r.Division_Code__c);
                    divisionMapList.add(divisionMap);
                }
            }
            
            if (!divisionMapList.isEmpty()) {
                retData = JSON.serialize(divisionMapList);
            }
            return retData;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static string getSalesArea(String oppId, String soId, String dcId, String divId){
        try {
            String retData = '';
            
            Opportunity opp = [
                SELECT Id, AccountId, Name, CurrencyIsoCode, Pricebook2Id, Contact__c, Contact__r.Name, Contact__r.Id 
                FROM Opportunity 
                WHERE Id = :oppId LIMIT 1
            ];
            
            List<Customer_Sales_Area__c> csaList = [
                SELECT Id, Comapany_Code__c, Sales_Organisation__c, Sales_Organisation__r.Name, Distribution_Channel__c,
                Distribution_Channel__r.Distribution_Code__c, Division__c, Division__r.Division_Code__c, Payment_Term__c,
                Payment_Term_Code__c, Incoterm_1__c, Incoterm_2__c
                FROM Customer_Sales_Area__c 
                WHERE Comapany_Code__c = :opp.AccountId
                AND Sales_Organisation__c = :soId
                AND Distribution_Channel__c = :dcId
                AND Division__c = :divId
                LIMIT 1
            ];
            
            if (!csaList.isEmpty()) {
                retData = JSON.serialize(csaList);
            }
            return retData;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
public static Boolean hasExistingQuote(Id opportunityId) {
    if (String.isBlank(opportunityId)) return false;
    return [SELECT COUNT() FROM Quote WHERE OpportunityId = :opportunityId] > 0;
}

    
    // Wrapper class for quote line items
    public class QuoteLineItemWrapper {
        @AuraEnabled
        public String Id { get; set; }
        @AuraEnabled
        public String Product2Id { get; set; }
        @AuraEnabled
        public String Product2Name { get; set; }
        @AuraEnabled
        public String PricebookEntryId { get; set; }
        @AuraEnabled
        public Decimal UnitPrice { get; set; }
        @AuraEnabled
        public Decimal Quantity { get; set; }
        @AuraEnabled
        public Decimal Discount { get; set; }
        @AuraEnabled
        public String Description { get; set; }
        @AuraEnabled
        public Decimal CustomerTargetPrice { get; set; }
        @AuraEnabled
        public String ContainerType { get; set; }
        @AuraEnabled
        public String CustomerProductName { get; set; }
        @AuraEnabled
        public String CustomerHsCode { get; set; }
        @AuraEnabled
        public String TransportationCost { get; set; }
        // Add these new fields
        @AuraEnabled
        public Decimal CustomerMaterialPrice { get; set; }
        @AuraEnabled
        public Decimal LastSellingPrice { get; set; }
    }
}