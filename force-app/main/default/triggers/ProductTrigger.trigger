trigger productTrigger on Product2 (before insert, before update) {
    
    if (Trigger.isAfter && Trigger.isUpdate) {
        ProductTriggerHandler.updateQuoteLineItem(Trigger.new, Trigger.oldMap);
        ProductTriggerHandler.updateProformaInvoiceLineItem(Trigger.new, Trigger.oldMap);
    }
    
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        Set<String> productCodes = new Set<String>();
        
        // Collect all ProductCodes from incoming records
        for (Product2 prod : Trigger.new) {
            if (String.isNotBlank(prod.ProductCode)) {
                productCodes.add(prod.ProductCode.trim());
            }
        }
        
        if (!productCodes.isEmpty()) {
            // Query existing products with the same ProductCodes
            Map<String, Id> existingProducts = new Map<String, Id>();
            for (Product2 p : [
                SELECT Id, ProductCode 
                FROM Product2 
                WHERE ProductCode IN :productCodes
            ]) {
                existingProducts.put(p.ProductCode, p.Id);
            }
            
            // Compare against Trigger.new
            for (Product2 prod : Trigger.new) {
                if (String.isNotBlank(prod.ProductCode)) {
                    Id existingId = existingProducts.get(prod.ProductCode.trim());
                    
                    // Duplicate check (skip self-update)
                    if (existingId != null && existingId != prod.Id) {
                        prod.addError('Duplicate Item Number not allowed: ' + prod.ProductCode);
                    }
                }
            }
        }
    }
}