trigger ProductTrigger on Product2 (before insert, before update, after insert, after update) {
    
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
    
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        
        Pricebook2 standardPB = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
        
        // Get all active currencies in the org
        List<CurrencyType> activeCurrencies = [SELECT IsoCode FROM CurrencyType WHERE IsActive = true];
        
        List<PricebookEntry> entriesToInsert = new List<PricebookEntry>();
        
        for (Product2 prod : Trigger.New) {
            // Get old value on update
            Product2 oldProd = Trigger.isUpdate ? Trigger.oldMap.get(prod.Id) : null;
            
            // Run only if flag is true, and on update only when it changed from false → true
            if (prod.Create_PricebookEntry__c == true &&
            (!Trigger.isUpdate || oldProd.Create_PricebookEntry__c == false)) {
                
                for (CurrencyType curr : activeCurrencies) {
                    entriesToInsert.add(new PricebookEntry(
                        Pricebook2Id = standardPB.Id,
                    Product2Id = prod.Id,
                    UnitPrice = 1, // Customize this value as needed
                    UseStandardPrice = false,
                    CurrencyIsoCode = curr.IsoCode,
                    IsActive = true
                        ));
                }
            }
        }
        
        if (!entriesToInsert.isEmpty()) {
            insert entriesToInsert;
        }
    }
}