public with sharing class CreateOrderFromAccount {
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getInitialData(Id accountId, Id orderId) {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            // Get account details
            Account acct = [SELECT Id, Name, BillingStreet, BillingCity, 
                            BillingState, BillingPostalCode, BillingCountry,
                            ShippingStreet, ShippingCity, ShippingState, 
                            ShippingPostalCode, ShippingCountry, CurrencyIsoCode
                            FROM Account WHERE Id = :accountId LIMIT 1];
            
            // Get picklist values
            result.put('statusOptions', getPicklistValues('Order', 'Status'));
            result.put('currencyOptions', getPicklistValues('Order', 'CurrencyIsoCode'));
            
            // Get contacts
            result.put('contacts', [SELECT Id, Name FROM Contact 
                                    WHERE AccountId = :accountId ORDER BY Name]);
            
            // If copying from existing order
            if (orderId != null) {
                Order existing = [SELECT Id, Name, Status, EffectiveDate, 
                                  CustomerAuthorizedById, CurrencyIsoCode, 
                                  Pricebook2Id FROM Order WHERE Id = :orderId LIMIT 1];
                result.put('existingOrder', existing);
                
                List<OrderItem> items = [SELECT Product2Id, Product2.Name, 
                                         Product2.ProductCode, UnitPrice, Quantity, 
                                         PricebookEntryId, Description, Discount__c
                                         FROM OrderItem WHERE OrderId = :orderId];
                result.put('lineItems', items);
            }
            
            result.put('account', acct);
            
        } catch (Exception e) {
            throw new AuraHandledException('Error getting initial data: ' + e.getMessage());
        }
        
        return result;
    }
    
    // Get all orders related to the given account
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getExistingOrdersForAccount(Id accountId) {
        List<Map<String, String>> orderOptions = new List<Map<String, String>>();
        for (Order ord : [
            SELECT Id, Name, Status, EffectiveDate, CurrencyIsoCode, Pricebook2Id, CustomerAuthorizedById
            FROM Order 
            WHERE AccountId = :accountId 
            ORDER BY CreatedDate DESC
        ]) {
            orderOptions.add(new Map<String, String>{
                'label' => ord.Name + ' (' + ord.Status + ')',
                    'value' => ord.Id
                    });
        }
        return orderOptions;
    }
    
    // Get header details for selected order
    @AuraEnabled(cacheable=true)
    public static Order getOrderHeader(Id orderId) {
        return [
            SELECT Id, Name, Status, EffectiveDate, CurrencyIsoCode, Pricebook2Id, CustomerAuthorizedById
            FROM Order
            WHERE Id = :orderId
            LIMIT 1
        ];
    }
    
    // Get order items for selected order
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getOrderItems(Id orderId) {
        List<Map<String, Object>> items = new List<Map<String, Object>>();
        
        for (OrderItem item : [
            SELECT Id, Product2Id, Product2.Name, Product2.ProductCode, 
            UnitPrice, Quantity, PricebookEntryId,
            Description, Discount__c
            FROM OrderItem 
            WHERE OrderId = :orderId
        ]) {
            items.add(new Map<String, Object>{
                'Id' => item.Id,
                    'Product2Id' => item.Product2Id,
                    'Product2' => new Map<String, Object>{
                        'Id' => item.Product2Id,
                            'Name' => item.Product2.Name,
                            'ProductCode' => item.Product2.ProductCode
                            },
                                'prodName' => item.Product2.Name,
                                'prodCode' => item.Product2.ProductCode,
                                'UnitPrice' => item.UnitPrice,
                                'Quantity' => item.Quantity,
                                'PricebookEntryId' => item.PricebookEntryId,
                                'Description' => item.Description,
                                'Discount' => item.Discount__c
                                });
        }
        
        return items;
    }
    
    // Create a new order (from existing or from scratch)
    @AuraEnabled
    public static Id createOrderFromExisting(
        String orderId,
        List<Map<String, Object>> orderItems,
        String status,
        Date effectiveDate,
        String customerAuthorizedById,
        String currencyCode,
        String pricebookId,
        Id accountId
    ) {
        try {
            Order newOrder;
            String namePrefix = 'Order - ' + Date.today().format();
            
            // Default values
            String billingStreet = '';
            String billingCity = '';
            String billingState = '';
            String billingPostalCode = '';
            String billingCountry = '';
            String shippingStreet = '';
            String shippingCity = '';
            String shippingState = '';
            String shippingPostalCode = '';
            String shippingCountry = '';
            Id accId = accountId;
            
            // If an existing Order ID is provided, clone its address fields
            if (orderId != null) {
                Order existing = [
                    SELECT AccountId, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry,
                    ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry
                    FROM Order
                    WHERE Id = :orderId
                    LIMIT 1
                ];
                
                accId = existing.AccountId;
                billingStreet = existing.BillingStreet;
                billingCity = existing.BillingCity;
                billingState = existing.BillingState;
                billingPostalCode = existing.BillingPostalCode;
                billingCountry = existing.BillingCountry;
                shippingStreet = existing.ShippingStreet;
                shippingCity = existing.ShippingCity;
                shippingState = existing.ShippingState;
                shippingPostalCode = existing.ShippingPostalCode;
                shippingCountry = existing.ShippingCountry;
            } else if (accountId != null) {
                // Otherwise, use account fields
                Account acct = [
                    SELECT BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry,
                    ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry
                    FROM Account
                    WHERE Id = :accountId
                    LIMIT 1
                ];
                
                billingStreet = acct.BillingStreet;
                billingCity = acct.BillingCity;
                billingState = acct.BillingState;
                billingPostalCode = acct.BillingPostalCode;
                billingCountry = acct.BillingCountry;
                shippingStreet = acct.ShippingStreet;
                shippingCity = acct.ShippingCity;
                shippingState = acct.ShippingState;
                shippingPostalCode = acct.ShippingPostalCode;
                shippingCountry = acct.ShippingCountry;
            } else {
                throw new AuraHandledException('Account ID or valid existing order ID must be provided.');
            }
            
            // Create new Order regardless of whether an old order was passed
            // Ensure pricebookId is set
            if (pricebookId == null) {
                Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE IsActive = true AND IsStandard = true LIMIT 1];
                pricebookId = pb.Id;
            }
            
            newOrder = new Order(
                Name = namePrefix + (billingCity != null ? ' from ' + billingCity : ''),
                OpportunityId = null,
                AccountId = accId,
                Status = status,
                EffectiveDate = effectiveDate,
				CustomerAuthorizedById = String.isBlank(customerAuthorizedById) ? null : customerAuthorizedById,
                Pricebook2Id = pricebookId,
                CurrencyIsoCode = currencyCode
            );
            System.debug('newOrder: ' + newOrder);
            insert newOrder;
            
            
            // Add order items
            List<OrderItem> itemsToInsert = new List<OrderItem>();
            for (Map<String, Object> item : orderItems) {
                itemsToInsert.add(new OrderItem(
                    OrderId = newOrder.Id,
                    Product2Id = (Id)item.get('Product2Id'),
                    PricebookEntryId = (Id)item.get('PricebookEntryId'),
                    UnitPrice = Decimal.valueOf(String.valueOf(item.get('UnitPrice'))),
                    Quantity = Decimal.valueOf(String.valueOf(item.get('Quantity'))),
                    Discount__c = Decimal.valueOf(String.valueOf(item.get('Discount'))),
                    Description = String.valueOf(item.get('Description'))
                ));
            }
            
            if (!itemsToInsert.isEmpty()) {
                insert itemsToInsert;
            }
            
            return newOrder.Id;
            
        } catch (Exception e) {
            throw new AuraHandledException('Failed to create new order: ' + e.getMessage()+ e.getLineNumber());
        }
    }
    
    
    // Get picklist values
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getPicklistValues(String objectName, String fieldName) {
        List<Map<String, String>> options = new List<Map<String, String>>();
        
        try {
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
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching picklist values: ' + e.getMessage());
        }
        
        return options;
    }
    
    // Get contacts for account
    @AuraEnabled(cacheable=true)
    public static List<Contact> getContactsForAccount(Id accountId) {
        return [
            SELECT Id, Name 
            FROM Contact 
            WHERE AccountId = :accountId
            ORDER BY Name
        ];
    }
    
    // Get account currency
    @AuraEnabled(cacheable=true)
    public static String getAccountCurrency(Id accountId) {
        return [SELECT CurrencyIsoCode FROM Account WHERE Id = :accountId].CurrencyIsoCode;
    }
    
    @AuraEnabled(cacheable=true)
    public static Id getDefaultPricebookForOrder() {
        // You may want to adjust logic based on Account if needed
        Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE IsActive = true AND IsStandard = true LIMIT 1];
        return pb.Id;
    }
    
    @AuraEnabled
public static Map<String, String> validatePricebookEntries(Id pricebookId, String currencyCode, List<Id> productIds) {
    Map<String, String> result = new Map<String, String>();
    
    try {
        // Check if pricebook has entries for these products in this currency
        List<PricebookEntry> entries = [
            SELECT Id, Product2Id, Product2.Name 
            FROM PricebookEntry 
            WHERE Pricebook2Id = :pricebookId 
            AND CurrencyIsoCode = :currencyCode
            AND Product2Id IN :productIds
            AND IsActive = true
        ];
        
        // Get all product IDs that have valid entries
        Set<Id> validProductIds = new Set<Id>();
        for (PricebookEntry pe : entries) {
            validProductIds.add(pe.Product2Id);
        }
        
        // Find which products are missing entries
        List<String> missingProducts = new List<String>();
        for (Id productId : productIds) {
            if (!validProductIds.contains(productId)) {
                missingProducts.add(productId);
            }
        }
        
        if (!missingProducts.isEmpty()) {
            // Get product names for error message
            Map<Id, Product2> products = new Map<Id, Product2>([
                SELECT Name FROM Product2 WHERE Id IN :missingProducts
            ]);
            
            List<String> productNames = new List<String>();
            for (Product2 p : products.values()) {
                productNames.add(p.Name);
            }
            
            result.put('isValid', 'false');
            result.put('message', 'The following products are not available in the selected currency (' + currencyCode + '): ' + String.join(productNames, ', '));
        } else {
            result.put('isValid', 'true');
        }
    } catch (Exception e) {
        result.put('isValid', 'false');
        result.put('message', 'Error validating products: ' + e.getMessage());
    }
    
    return result;
}
}