trigger ConversionFactorSalesTrigger on Conversion_factor_for_Sales__c (before insert) {
    if(Trigger.isBefore && Trigger.isInsert) {
        
        // Collect values for query
        Set<Id> itemMasterIds = new Set<Id>();
        Set<String> altUOMs = new Set<String>();
        Set<String> baseUOMs = new Set<String>();
        Set<Decimal> altQtys = new Set<Decimal>();
        Set<Decimal> baseQtys = new Set<Decimal>();

        for(Conversion_factor_for_Sales__c rec : Trigger.new) {
            if(rec.Item_Master__c != null && rec.Alt_Quantity__c != null && 
               rec.Alt_UOM__c != null && rec.Base_Qty__c != null && rec.Base_UOM__c != null) {
                
                itemMasterIds.add(rec.Item_Master__c);
                altUOMs.add(rec.Alt_UOM__c);
                baseUOMs.add(rec.Base_UOM__c);
                altQtys.add(rec.Alt_Quantity__c);
                baseQtys.add(rec.Base_Qty__c);
            }
        }

        // Query existing records
        List<Conversion_factor_for_Sales__c> existingRecords = [
            SELECT Id, Item_Master__c, Alt_Quantity__c, Alt_UOM__c, Base_Qty__c, Base_UOM__c
            FROM Conversion_factor_for_Sales__c
            WHERE Item_Master__c IN :itemMasterIds
              AND Alt_UOM__c IN :altUOMs
              AND Base_UOM__c IN :baseUOMs
              AND Alt_Quantity__c IN :altQtys
              AND Base_Qty__c IN :baseQtys
        ];

        // Build set of existing unique combinations
        Set<String> existingKeys = new Set<String>();
        for(Conversion_factor_for_Sales__c rec : existingRecords) {
            String key = rec.Item_Master__c + '-' + rec.Alt_Quantity__c + '-' + 
                         rec.Alt_UOM__c + '-' + rec.Base_Qty__c + '-' + rec.Base_UOM__c;
            existingKeys.add(key);
        }

        // Validate inserted records
        Set<String> seenKeys = new Set<String>(); // prevent duplicates within same transaction
        for(Conversion_factor_for_Sales__c rec : Trigger.new) {
            if(rec.Item_Master__c != null && rec.Alt_Quantity__c != null && 
               rec.Alt_UOM__c != null && rec.Base_Qty__c != null && rec.Base_UOM__c != null) {
                
                String key = rec.Item_Master__c + '-' + rec.Alt_Quantity__c + '-' + 
                             rec.Alt_UOM__c + '-' + rec.Base_Qty__c + '-' + rec.Base_UOM__c;
                
                if(existingKeys.contains(key) || seenKeys.contains(key)) {
                    rec.addError('Duplicate record found with same Item Master, Alt Qty, Alt UOM, Base Qty, and Base UOM.');
                } else {
                    seenKeys.add(key);
                }
            }
        }
    }
}