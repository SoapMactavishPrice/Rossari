public with sharing class NPDCostingController {
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getExistingCostingItems(String recordId) {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            // Get parent NPD record fields including the new formula fields
            New_Product_Development__c npd = [
                SELECT Id, Name, 
                       Molecular_wt_of_the_Product__c, 
                       Yield_and_RMC_change__c,
                       Yield__c,                    // Formula field
                       Manufacturing_Cost__c,       // Formula field
                       Profit_Expected_Per_Kg__c,   // Currency field
                       Selling_Price__c             // Formula field
                FROM New_Product_Development__c 
                WHERE Id = :recordId 
                LIMIT 1
            ];
            
            // Add parent fields to result
            result.put('parentMolecularWeight', npd.Molecular_wt_of_the_Product__c);
            result.put('yieldAndRMCChange', npd.Yield_and_RMC_change__c);
            
            // Add new formula fields
            result.put('yieldField', npd.Yield__c);
            result.put('manufacturingCost', npd.Manufacturing_Cost__c);
            result.put('profitExpectedPerKg', npd.Profit_Expected_Per_Kg__c);
            result.put('sellingPrice', npd.Selling_Price__c);
            
            // Get existing costing items
            List<NPD_Costing__c> costingItems = [
                SELECT Id, Name, Mol_wt__c, Used_in_Batch_Kgs__c, Recoverd__c, 
                       Consumed_Kgs__c, Kg_RM_Kg_Product__c, Unit_Cost_Per_Kg__c, 
                       Cost_in_Batch__c, Cost_Per_Kg__c, Gmoles__c,Use_for_Yield_Calc__c
                FROM NPD_Costing__c
                WHERE New_Product_Development__c = :recordId
                ORDER BY CreatedDate
            ];
            
            result.put('costingItems', costingItems);
            return result;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching data: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Decimal getYieldAndRMCChange(String recordId) {
        try {
            New_Product_Development__c npd = [SELECT Yield_and_RMC_change__c 
                                             FROM New_Product_Development__c 
                                             WHERE Id = :recordId LIMIT 1];
            return npd.Yield_and_RMC_change__c;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching Yield and RMC change: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void saveCostingItems(String recordId, String costingItems, Decimal molecularWeight, Decimal yieldAndRMCChange, Decimal profitExpectedPerKg) {
        // Update parent NPD record fields
        New_Product_Development__c npdToUpdate = new New_Product_Development__c(
            Id = recordId,
            Molecular_wt_of_the_Product__c = molecularWeight,
            Yield_and_RMC_change__c = yieldAndRMCChange,
            Profit_Expected_Per_Kg__c = profitExpectedPerKg
        );
        
        update npdToUpdate;
        
        // Save costing items
        List<NPD_Costing__c> itemsToUpsert = new List<NPD_Costing__c>();
        
        List<Object> costingItemsData = (List<Object>) JSON.deserializeUntyped(costingItems);
        
        for (Object itemObj : costingItemsData) {
            Map<String, Object> itemData = (Map<String, Object>) itemObj;
            
            NPD_Costing__c item = new NPD_Costing__c();
            item.New_Product_Development__c = recordId;
            item.Name = (String) itemData.get('name');
            
            item.Mol_wt__c = parseDecimal(itemData.get('molWeight'));
            item.Used_in_Batch_Kgs__c = parseDecimal(itemData.get('usedInBatch'));
            item.Recoverd__c = parseDecimal(itemData.get('recovered'));
            item.Unit_Cost_Per_Kg__c = parseDecimal(itemData.get('unitCostPerKg'));
            item.Use_for_Yield_Calc__c = (Boolean) itemData.get('useForYieldCalc');
            if (itemData.get('id') != null) {
                item.Id = (String) itemData.get('id');
            }
            
            itemsToUpsert.add(item);
        }
        
        if (!itemsToUpsert.isEmpty()) {
            try {
                upsert itemsToUpsert;
            } catch(DmlException e) {
                throw new AuraHandledException('Error saving costing items: ' + e.getMessage());
            }
        }
    }
    
    @AuraEnabled
    public static void deleteCostingItem(String costingItemId) {
        try {
            NPD_Costing__c itemToDelete = [SELECT Id FROM NPD_Costing__c WHERE Id = :costingItemId LIMIT 1];
            delete itemToDelete;
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting costing item: ' + e.getMessage());
        }
    }

    // Helper method to safely parse decimals
    private static Decimal parseDecimal(Object val) {
        if (val == null) return null;

        try {
            if (val instanceof Decimal) {
                return (Decimal) val;
            } else if (val instanceof Integer) {
                return Decimal.valueOf(((Integer) val).format());
            } else if (val instanceof Double) {
                return Decimal.valueOf(String.valueOf(val));
            } else if (val instanceof String) {
                return Decimal.valueOf((String) val);
            }
        } catch (Exception e) {
            throw new AuraHandledException('Invalid decimal value: ' + val);
        }

        return null;
    }
}