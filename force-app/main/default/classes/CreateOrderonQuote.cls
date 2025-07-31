public with sharing class CreateOrderonQuote {
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getInitialData(String quoteId) {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            // Get quote and related data with all necessary fields
            Quote qt = [SELECT Id, Name, OpportunityId, Opportunity.AccountId, 
                        CurrencyIsoCode, Pricebook2Id, Pricebook2.Name, ContactId, Contact.Name,
                        BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry,
                        ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry
                        FROM Quote 
                        WHERE Id = :quoteId 
                        LIMIT 1];
            
            // Get status picklist values
            List<Map<String, String>> statusOptions = getPicklistValues('Order', 'Status');
            
            // Get currency picklist values
            List<Map<String, String>> currencyOptions = getPicklistValues('Order', 'CurrencyIsoCode');
            
            // Get related contacts
            List<Contact> contacts = [
                SELECT Id, Name, Email, Phone 
                FROM Contact 
                WHERE AccountId = :qt.Opportunity.AccountId
                ORDER BY Name
            ];
            
            // Get quote line items with all necessary product information
            List<QuoteLineItem> lineItems = [
                SELECT Id, Product2Id, Product2.Name, Product2.ProductCode, Product2.Description,
                UnitPrice, Quantity, PricebookEntryId, PricebookEntry.UnitPrice, 
                PricebookEntry.Pricebook2Id, PricebookEntry.Product2Id,
                Description, Discount, ListPrice, Subtotal, TotalPrice
                FROM QuoteLineItem
                WHERE QuoteId = :quoteId
                ORDER BY SortOrder NULLS LAST, CreatedDate
            ];
            
            result.put('quote', qt);
            result.put('statusOptions', statusOptions);
            result.put('currencyOptions', currencyOptions);
            result.put('contacts', contacts);
            result.put('lineItems', lineItems);
            
        } catch (Exception e) {
            throw new AuraHandledException('Error getting initial data: ' + e.getMessage());
        }
        
        return result;
    }
    
    // Helper method to get picklist values
    private static List<Map<String, String>> getPicklistValues(String objectName, String fieldName) {
        List<Map<String, String>> options = new List<Map<String, String>>();
        Schema.DescribeFieldResult fieldResult = Schema.getGlobalDescribe()
            .get(objectName)
            .getDescribe()
            .fields.getMap()
            .get(fieldName)
            .getDescribe();
        
        for (Schema.PicklistEntry pe : fieldResult.getPicklistValues()) {
            if (pe.isActive()) {
                options.add(new Map<String, String>{
                    'label' => pe.getLabel(),
                        'value' => pe.getValue()
                        });
            }
        }
        return options;
    }
    
    @AuraEnabled
    public static Id createOrderFromQuote(
        String quoteId, 
        List<Map<String, Object>> lineItems, 
        String status,
        Date effectiveDate,
        String customerAuthorizedById,
        String currencyCode,
        String pricebookId
    ) {
        try {
            Quote qt = [SELECT Id, OpportunityId, Opportunity.AccountId, Name,
                        BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry,
                        ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry
                        FROM Quote 
                        WHERE Id = :quoteId];
            
            // Create the order with all necessary fields
            Order ord = new Order(
                Name = 'Order from ' + qt.Name,
                QuoteId = qt.Id,
                OpportunityId = qt.OpportunityId,
                AccountId = qt.Opportunity.AccountId,
                Status = status,
                EffectiveDate = effectiveDate,
                CustomerAuthorizedById = customerAuthorizedById,
                Pricebook2Id = pricebookId,
                CurrencyIsoCode = currencyCode,
                BillingStreet = qt.BillingStreet,
                BillingCity = qt.BillingCity,
                BillingState = qt.BillingState,
                BillingPostalCode = qt.BillingPostalCode,
                BillingCountry = qt.BillingCountry,
                ShippingStreet = qt.ShippingStreet,
                ShippingCity = qt.ShippingCity,
                ShippingState = qt.ShippingState,
                ShippingPostalCode = qt.ShippingPostalCode,
                ShippingCountry = qt.ShippingCountry
            );
            insert ord;
            
            List<OrderItem> orderProducts = new List<OrderItem>();
            for (Map<String, Object> item : lineItems) {
                // Safely convert values with null checks
                Decimal unitPrice = item.get('UnitPrice') != null ? 
                    Decimal.valueOf(String.valueOf(item.get('UnitPrice'))) : 0;
                Decimal quantity = item.get('Quantity') != null ? 
                    Decimal.valueOf(String.valueOf(item.get('Quantity'))) : 1;
                Decimal discountPercent = item.get('Discount') != null ? 
                    Decimal.valueOf(String.valueOf(item.get('Discount'))) : 0;
                
                // Calculate total price with discount
                Decimal totalBeforeDiscount = unitPrice * quantity;
                Decimal discountAmount = totalBeforeDiscount * (discountPercent/100);
                Decimal totalPrice = totalBeforeDiscount - discountAmount;
                
                // Create OrderItem with calculated total
                orderProducts.add(new OrderItem(
                    OrderId = ord.Id,
                    Product2Id = (Id)item.get('Product2Id'),
                    PricebookEntryId = (Id)item.get('PricebookEntryId'),
                    UnitPrice = unitPrice,
                    Quantity = quantity,
                    Discount__c = discountPercent,
                    Total_Price__c = totalPrice.setScale(2), // Rounded to 2 decimal places
                    Description = (String)item.get('Description')
                ));
            }
            
            if (!orderProducts.isEmpty()) {
                insert orderProducts;
            }
            
            return ord.Id;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error creating order: ' + e.getMessage() + 
                                           ' Stack trace: ' + e.getStackTraceString());
        }
    }
    
    @AuraEnabled
    public static void deleteQuoteLineItem(String Id) {
        try {
            QuoteLineItem qli = [SELECT Id FROM QuoteLineItem WHERE Id = :Id LIMIT 1];
            if (qli != null) {
                delete qli;
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting quote line item: ' + e.getMessage());
        }
    }
}