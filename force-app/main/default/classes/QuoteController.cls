public with sharing class QuoteController {
    
    @AuraEnabled(cacheable=true)
    public static List<OpportunityLineItem> getOppLineItems(String opportunityId) {
        return [
            SELECT Id, Product2Id, Product2.Name, UnitPrice, Quantity, 
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
        Opportunity opp = [SELECT Id, AccountId, Name FROM Opportunity WHERE Id = :opportunityId];
        
        // Create the quote with all fields
        Quote quote = new Quote(
            Name = quoteName,
            OpportunityId = opp.Id,
            Status = status,
            ExpirationDate = expirationDate,
            Pricebook2Id = String.isNotBlank(pricebookId) ? pricebookId : opp.Pricebook2Id,
            CurrencyIsoCode = String.isNotBlank(currencyCode) ? currencyCode : opp.CurrencyIsoCode,
            ContactId = String.isNotBlank(contactId) ? contactId : null
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
}