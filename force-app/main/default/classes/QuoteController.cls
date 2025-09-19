public with sharing class QuoteController {
    
    @AuraEnabled(cacheable=true)
    public static List<OpportunityLineItem> getOppLineItems(String opportunityId) {
        return [
            SELECT Id, Product2Id, Product2.Name, UnitPrice, Quantity,Product2.Description,
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
        Opportunity opp = [SELECT Id, AccountId, Name, CurrencyIsoCode, Pricebook2Id 
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
        
        // Get currency picklist values - return ISO codes directly
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
        
        // Get related contacts
        List<Contact> contacts = [
            SELECT Id, Name 
            FROM Contact 
            WHERE AccountId = :opp.AccountId
            ORDER BY Name
        ];
        
        result.put('opportunityName', opp.Name);
        result.put('defaultCurrency', opp.CurrencyIsoCode);
        result.put('pricebookId', opp.Pricebook2Id);
        result.put('statusOptions', statusOptions);
        result.put('currencyOptions', currencyOptions);
        result.put('contacts', contacts);
        
        return result;
    }
    
    @AuraEnabled
    public static Id createQuoteFromOpportunity(
        String opportunityId, 
        List<OpportunityLineItem> lineItems, 
        String quoteName,
        String status,
        Date expirationDate,
        String currencyCode,
        String contactId,
        String pricebookId
    ) {
        // Validate required parameters
        if (String.isBlank(opportunityId)) {
            throw new AuraHandledException('Opportunity ID is required');
        }
        
        // Get opportunity
        Opportunity opp = [SELECT Id,Pricebook2Id,CurrencyIsoCode, AccountId, Name FROM Opportunity WHERE Id = :opportunityId];
        
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
            Terms_and_Conditions__c =
            'All bank charges outside India will be borne by the customer and such charges should not be deducted from our payment.\n' +
            'We should receive full invoice amount in our bank account and you are liable to pay the bank charges which are applicable in India only.\n' +
            'After finalization of order if there is any change in Statutory Govt. levies than it will be in your scope.',
            Declaration__c = 'We declare that this quotation shows the actual price of goods and that all particulars are true and correct'
        );
        insert quote;
        
        // Create quote line items with discount and total price calculations
        List<QuoteLineItem> qliList = new List<QuoteLineItem>();
        for (OpportunityLineItem oli : lineItems) {
            if (oli.Product2Id == null || oli.PricebookEntryId == null) {
                continue; // Skip invalid line items
            }
            
            // Calculate total price with discount
            Decimal unitPrice = oli.UnitPrice != null ? oli.UnitPrice : 0;
            Decimal quantity = oli.Quantity != null ? oli.Quantity : 1;
            Decimal discountPercent = oli.Discount != null ? oli.Discount : 0;
            
            qliList.add(new QuoteLineItem(
                QuoteId = quote.Id,
                Product2Id = oli.Product2Id,
                PricebookEntryId = oli.PricebookEntryId,
                UnitPrice = unitPrice,
                Quantity = quantity,
                Discount = discountPercent,
                Description = oli.Description
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
}