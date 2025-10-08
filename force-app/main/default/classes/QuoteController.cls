public with sharing class QuoteController {
    
    @AuraEnabled(cacheable=true)
    public static List<OpportunityLineItem> getOppLineItems(String opportunityId) {
        return [
            SELECT Id, Product2Id, Product2.Name, UnitPrice, Quantity, Product2.Description,
            PricebookEntryId, PricebookEntry.UnitPrice, Description, Discount
            FROM OpportunityLineItem
            WHERE OpportunityId = :opportunityId
            ORDER BY SortOrder
        ];
    }		
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getQuoteInitialData(String opportunityId) {
        Map<String, Object> result = new Map<String, Object>();
        
        // Get opportunity details
        Opportunity opp = [SELECT Id, AccountId, Name, CurrencyIsoCode, Pricebook2Id, Contact__c, Contact__r.Name, Contact__r.Id 
                           FROM Opportunity 
                           WHERE Id = :opportunityId LIMIT 1];
        
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
        result.put('paymentTerms', paymentTermOptions);
        result.put('contacts', contacts);
        
        if (opp.Contact__c != null && opp.Contact__r != null) {
            result.put('defaultContact', new Map<String, String>{
                'label' => opp.Contact__r.Name,
                'value' => opp.Contact__r.Id
            });
        }
        
        return result;
    }
    
    @AuraEnabled
    public static Id createQuoteFromOpportunity(
        String opportunityId, 
        List<QuoteLineItemWrapper> lineItems, // Changed to wrapper class
        String quoteName,
        String status,
        Date expirationDate,
        String currencyCode,
        String contactId,
        String pricebookId,
        String incoTerms,
        String paymentTermId,
        Decimal transportationCost,
         String containerType
    ) {
        // Validate required parameters
        if (String.isBlank(opportunityId)) {
            throw new AuraHandledException('Opportunity ID is required');
        }
        
        // Get opportunity
        Opportunity opp = [SELECT Id, Pricebook2Id, CurrencyIsoCode, AccountId, Name FROM Opportunity WHERE Id = :opportunityId];
        
        // Get current user
        User currentUser = [SELECT Id, Entity_Code_1__c, Entity_Code_2__c, Entity_Code_3__c FROM User WHERE Id = :UserInfo.getUserId()];
        
        // Collect all non-null entity codes
        Set<String> entityCodes = new Set<String>();
        if (currentUser.Entity_Code_1__c != null) entityCodes.add(currentUser.Entity_Code_1__c);
        if (currentUser.Entity_Code_2__c != null) entityCodes.add(currentUser.Entity_Code_2__c);
        if (currentUser.Entity_Code_3__c != null) entityCodes.add(currentUser.Entity_Code_3__c);
        
        // Find matching Sales HOD user
        User hodUser = null;
        if (!entityCodes.isEmpty()) {
            List<User> hodUsers = [
                SELECT Id FROM User 
                WHERE Is_Sales_HOD__c = true AND (
                    Entity_Code_1__c IN :entityCodes OR 
                    Entity_Code_2__c IN :entityCodes OR 
                    Entity_Code_3__c IN :entityCodes
                )
                LIMIT 1
            ];
            if (!hodUsers.isEmpty()) {
                hodUser = hodUsers[0];
            }
        }
        
        // Query the Company__c record for 'Rossari Biotech Limited'
        Company__c rossariCompany = [SELECT Id FROM Company__c WHERE Name = 'Rossari Biotech Limited' LIMIT 1];
        
        // Create the quote with all fields
        Quote quote = new Quote(
            Name = quoteName,
            OpportunityId = opp.Id,
            Status = status,
            Letter_Company_Name__c = rossariCompany.Id,
            ExpirationDate = expirationDate,
            Quote_Valid_From__c = Date.today(),
            Pricebook2Id = String.isNotBlank(pricebookId) ? pricebookId : opp.Pricebook2Id,
            CurrencyIsoCode = String.isNotBlank(currencyCode) ? currencyCode : opp.CurrencyIsoCode,
            ContactId = String.isNotBlank(contactId) ? contactId : null,
            HOD_of_Sales_Department__c = hodUser != null ? hodUser.Id : null,
            Inco_Terms__c = incoTerms,
            Payment_Term__c = paymentTermId,
            Transportation_Cost__c = transportationCost != null ? transportationCost : 0.0, 
            Container_Type__c = containerType,
            Terms_and_Conditions__c =
            'All bank charges outside India will be borne by the customer and such charges should not be deducted from our payment.\n' +
            'We should receive full invoice amount in our bank account and you are liable to pay the bank charges which are applicable in India only.\n' +
            'After finalization of order if there is any change in Statutory Govt. levies than it will be in your scope.',
            Declaration__c = 'We declare that this quotation shows the actual price of goods and that all particulars are true and correct'
        );
        insert quote;
        
        // Create quote line items with discount and total price calculations
        List<QuoteLineItem> qliList = new List<QuoteLineItem>();
        for (QuoteLineItemWrapper itemWrapper : lineItems) {
            if (itemWrapper.Product2Id == null || itemWrapper.PricebookEntryId == null) {
                continue; // Skip invalid line items
            }
            
            // Calculate total price with discount
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
           //     Container_Type__c = itemWrapper.ContainerType != null ? itemWrapper.ContainerType : '',
                Customer_Product_Name__c = itemWrapper.CustomerProductName != null ? itemWrapper.CustomerProductName : '',
                Customer_HS_Code__c = itemWrapper.CustomerHsCode != null ? itemWrapper.CustomerHsCode : ''
           //    Transportation_Cost__c = itemWrapper.TransportationCost != null ? Decimal.valueOf(itemWrapper.TransportationCost) : 0.0
            ));
        }
        
        if (!qliList.isEmpty()) {
            insert qliList;
        }
        
        opp.StageName = 'Quotation';
        update opp;
        
        return quote.Id;
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
    }
}