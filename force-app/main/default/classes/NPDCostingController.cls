public with sharing class NPDCostingController {

    // === Dynamic Record Type options for NPD_Costing__c (radio labels) ===
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getRecordTypeOptions() {
        List<Map<String, String>> options = new List<Map<String, String>>();
        for (RecordType rt : [
            SELECT Id, Name, DeveloperName
            FROM RecordType
            WHERE SObjectType = 'NPD_Costing__c' AND IsActive = true
            ORDER BY Name
        ]) {
            options.add(new Map<String, String>{
                'label' => rt.Name,
                'value' => rt.DeveloperName
            });
        }
        return options;
    }

    // === Load parent + Agro & Non Agro costing items (your original) ===
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getExistingCostingItems(String recordId) {
        Map<String, Object> result = new Map<String, Object>();
        try {
            New_Product_Development__c npd = [
                SELECT Id, Name, 
                       Molecular_wt_of_the_Product__c, 
                       Yield_and_RMC_change__c,
                       Loss_in_Batch__c,              
                       Overheads_Utility_Packaging__c, 
                       Yield__c,                    
                       Manufacturing_Cost__c,       
                       Profit_Expected_Per_Kg__c,   
                       Selling_Price__c             
                FROM New_Product_Development__c 
                WHERE Id = :recordId 
                LIMIT 1
            ];

            result.put('parentMolecularWeight', npd.Molecular_wt_of_the_Product__c);
            result.put('yieldAndRMCChange', npd.Yield_and_RMC_change__c);
            result.put('lossInBatch', npd.Loss_in_Batch__c);
            result.put('overheadsUtilityPackaging', npd.Overheads_Utility_Packaging__c);
            result.put('yieldField', npd.Yield__c);
            result.put('manufacturingCost', npd.Manufacturing_Cost__c);
            result.put('profitExpectedPerKg', npd.Profit_Expected_Per_Kg__c);
            result.put('sellingPrice', npd.Selling_Price__c);

            List<NPD_Costing__c> costingItems = [
                SELECT Id, Name, Mol_wt__c, Used_in_Batch_Kgs__c, Recoverd__c, 
                       Consumed_Kgs__c, Kg_RM_Kg_Product__c, Unit_Cost_Per_Kg__c, 
                       Cost_in_Batch__c, Cost_Per_Kg__c, Gmoles__c, Use_for_Yield_Calc__c
                FROM NPD_Costing__c
                WHERE New_Product_Development__c = :recordId
                AND RecordType.DeveloperName = 'Agro_Non_Agro'
                ORDER BY CreatedDate
            ];
            result.put('costingItems', costingItems);
            return result;

        } catch (Exception e) {
            throw new AuraHandledException('Error fetching data: ' + e.getMessage());
        }
    }

    // === Load Oil & Gas costing items (UPDATED to include rollup fields) ===
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getOilGasCostingItems(String recordId) {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            // Get parent NPD record with all required fields including rollups
            New_Product_Development__c npd = [
                SELECT Id, Name, Average_SG__c, Total_Price__c, // Added rollup fields
                       Unit_Size_Ltr__c, Total_Drums__c, Unit_Size_Kg__c,
                       RM_Cost__c, OH__c, Packing__c, Palletizing__c, Margins__c,
                       FG_Per_KG__c, Cost_per_Unit__c, Price_Per_Unit__c
                FROM New_Product_Development__c 
                WHERE Id = :recordId 
                LIMIT 1
            ];
            result.put('npdRecord', npd);
            
            // Get costing items
            List<NPD_Costing__c> costingItems = [
                SELECT Id, Name, SG__c, Component__c, Cost_Kg__c, Kg_Drum__c, Liter_Drum__c,
                       For_Total_Drum__c, Loss__c, Total_KG__c, Total_Price_1__c
                FROM NPD_Costing__c
                WHERE New_Product_Development__c = :recordId
                AND RecordType.DeveloperName = 'Oil_Gas'
                ORDER BY CreatedDate
            ];
            result.put('costingItems', costingItems);
            
            return result;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching Oil & Gas data: ' + e.getMessage());
        }
    }

    // === Save Agro & Non Agro costing items + parent fields (your original) ===
    @AuraEnabled
    public static void saveCostingItems(String recordId, String costingItems, Decimal molecularWeight, 
                                      Decimal yieldAndRMCChange, Decimal profitExpectedPerKg,
                                      Decimal lossInBatch, Decimal overheadsUtilityPackaging) {

        // Update parent NPD record
        update new New_Product_Development__c(
            Id = recordId,
            Molecular_wt_of_the_Product__c = molecularWeight,
            Yield_and_RMC_change__c = yieldAndRMCChange,
            Profit_Expected_Per_Kg__c = profitExpectedPerKg,
            Loss_in_Batch__c = lossInBatch,
            Overheads_Utility_Packaging__c = overheadsUtilityPackaging
        );

        // Upsert costing items (Agro_Non_Agro record type)
        Id agroRt = Schema.SObjectType.NPD_Costing__c.getRecordTypeInfosByDeveloperName()
            .get('Agro_Non_Agro').getRecordTypeId();

        List<NPD_Costing__c> itemsToUpsert = new List<NPD_Costing__c>();
        List<Object> costingItemsData = (List<Object>) JSON.deserializeUntyped(costingItems);

        for (Object itemObj : costingItemsData) {
            Map<String, Object> itemData = (Map<String, Object>) itemObj;
            NPD_Costing__c item = new NPD_Costing__c();
            item.New_Product_Development__c = recordId;
            item.RecordTypeId = agroRt;
            item.Name = (String) itemData.get('name');
            item.Mol_wt__c = parseDecimal(itemData.get('molWeight'));
            item.Used_in_Batch_Kgs__c = parseDecimal(itemData.get('usedInBatch'));
            item.Recoverd__c = parseDecimal(itemData.get('recovered'));
            item.Unit_Cost_Per_Kg__c = parseDecimal(itemData.get('unitCostPerKg'));
            item.Use_for_Yield_Calc__c = (Boolean) itemData.get('useForYieldCalc');
            if (itemData.get('id') != null) item.Id = (String) itemData.get('id');
            itemsToUpsert.add(item);
        }
        if (!itemsToUpsert.isEmpty()) upsert itemsToUpsert;
    }

    // === Save Oil & Gas costing items ===
    @AuraEnabled
    public static void saveOilGasCostingItems(String recordId, String oilGasItems,
                                            Decimal unitSizeLtr, Decimal totalDrums,
                                            Decimal oh, Decimal packing,
                                            Decimal palletizing, Decimal margins) {
        System.debug('=== Starting saveOilGasCostingItems ===');
        
        // First update the parent NPD record with additional costing fields
        update new New_Product_Development__c(
            Id = recordId,
            Unit_Size_Ltr__c = unitSizeLtr,
            Total_Drums__c = totalDrums,
            OH__c = oh,
            Packing__c = packing,
            Palletizing__c = palletizing,
            Margins__c = margins
        );
        
        Id oilRt = Schema.SObjectType.NPD_Costing__c.getRecordTypeInfosByDeveloperName()
            .get('Oil_Gas').getRecordTypeId();
        
        List<NPD_Costing__c> toUpsert = new List<NPD_Costing__c>();
        List<Object> oilGasList = (List<Object>) JSON.deserializeUntyped(oilGasItems);
        
        System.debug('Number of items: ' + oilGasList.size());
        
        for (Object o : oilGasList) {
            Map<String, Object> i = (Map<String, Object>) o;
            
            NPD_Costing__c rec = new NPD_Costing__c(
                New_Product_Development__c = recordId,
                RecordTypeId = oilRt,
                Name = (String)i.get('Name'),
                SG__c = parseDecimal(i.get('SG__c')),
                Component__c = parseDecimal(i.get('Component__c')),
                Cost_Kg__c = parseDecimal(i.get('Cost_Kg__c')),
                Loss__c = parseDecimal(i.get('Loss__c')),
                Total_Price_1__c = parseDecimal(i.get('Total_Price_1__c'))
            );
            
            if (i.get('Id') != null) rec.Id = (String) i.get('Id');
            toUpsert.add(rec);
        }
        
        System.debug('Records to upsert: ' + toUpsert.size());
        
        if (!toUpsert.isEmpty()) {
            try {
                upsert toUpsert;
                System.debug('=== Upsert completed successfully ===');
            } catch (Exception e) {
                System.debug('Upsert error: ' + e.getMessage());
                throw new AuraHandledException('Save failed: ' + e.getMessage());
            }
        }
    }

    // === Delete (your original) ===
    @AuraEnabled
    public static void deleteCostingItem(String costingItemId) {
        delete [SELECT Id FROM NPD_Costing__c WHERE Id = :costingItemId LIMIT 1];
    }

    // === Utility ===
    private static Decimal parseDecimal(Object val) {
        if (val == null) return null;
        try {
            return Decimal.valueOf(String.valueOf(val));
        } catch (Exception e) {
            throw new AuraHandledException('Invalid decimal value: ' + val);
        }
    }
}