public with sharing class NPDCostingController {
    
    @AuraEnabled(cacheable=true)
    public static List<NPD_Costing__c> getExistingCostingItems(String recordId) {
        return [
            SELECT Id, Name, Mol_wt__c, Used_in_Batch_Kgs__c, Recoverd__c, 
                   Consumed_Kgs__c, Kg_RM_Kg_Product__c, Unit_Cost_Per_Kg__c, 
                   Cost_in_Batch__c, Cost_Per_Kg__c, Gmoles__c
            FROM NPD_Costing__c
            WHERE New_Product_Development__c = :recordId
            ORDER BY CreatedDate
        ];
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
    public static void saveCostingItems(String recordId, String costingItems) {
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
      //      item.Consumed_Kgs__c = parseDecimal(itemData.get('consumed'));
            item.Unit_Cost_Per_Kg__c = parseDecimal(itemData.get('unitCostPerKg'));
      //      item.Cost_in_Batch__c = parseDecimal(itemData.get('costInBatch'));
      //      item.Cost_Per_Kg__c = parseDecimal(itemData.get('costPerKg'));
       //     item.Gmoles__c = parseDecimal(itemData.get('gmoles'));
            
            // DO NOT include Kg_RM_Kg_Product__c as it's a formula field
            // The formula will automatically calculate: Consumed_Kgs__c / New_Product_Development__r.Yield_and_RMC_change__c
            
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