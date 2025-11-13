@isTest
public class NPDCostingControllerTest {

    @isTest
    static void testAllMethodsInSingleMethod() {
        // Create test NPD records
        New_Product_Development__c npd1 = new New_Product_Development__c(
            Name = 'Test NPD Agro',
            Molecular_wt_of_the_Product__c = 200,
            Yield_and_RMC_change__c = 100,
            Loss_in_Batch__c = 10,
            Overheads_Utility_Packaging__c = 5,
            Profit_Expected_Per_Kg__c = 50
        );
        
        New_Product_Development__c npd2 = new New_Product_Development__c(
            Name = 'Test NPD Oil Gas',
            Unit_Size_Ltr__c = 20,
            Total_Drums__c = 100,
            OH__c = 500,
            Packing__c = 200,
            Palletizing__c = 100,
            Margins__c = 300
        );
        insert new List<New_Product_Development__c>{npd1, npd2};

        // Get record types
        Id agroRt = Schema.SObjectType.NPD_Costing__c.getRecordTypeInfosByDeveloperName()
            .get('Agro_Non_Agro').getRecordTypeId();
        Id oilRt = Schema.SObjectType.NPD_Costing__c.getRecordTypeInfosByDeveloperName()
            .get('Oil_Gas').getRecordTypeId();

        // Create test costing items
        NPD_Costing__c agroCosting = new NPD_Costing__c(
            Name = 'Agro Costing Item',
            New_Product_Development__c = npd1.Id,
            RecordTypeId = agroRt,
            Mol_wt__c = 180,
            Used_in_Batch_Kgs__c = 90,
            Recoverd__c = 40,
            Unit_Cost_Per_Kg__c = 200,
            Use_for_Yield_Calc__c = true
        );
        
        NPD_Costing__c oilGasCosting = new NPD_Costing__c(
            Name = 'Oil Gas Costing Item',
            New_Product_Development__c = npd2.Id,
            RecordTypeId = oilRt,
            SG__c = 0.8,
            Component__c = 80,
            Cost_Kg__c = 25,
            Loss__c = 2,
            Total_Price_1__c = 44100
        );
        insert new List<NPD_Costing__c>{agroCosting, oilGasCosting};

        Test.startTest();

        // Test 1: Get Record Type Options
        List<Map<String, String>> recordTypeOptions = NPDCostingController.getRecordTypeOptions();

        // Test 2: Get Existing Costing Items (Agro/Non-Agro)
        Map<String, Object> existingCostingResult = NPDCostingController.getExistingCostingItems(npd1.Id);

        // Test 3: Get Oil Gas Costing Items
        Map<String, Object> oilGasCostingResult = NPDCostingController.getOilGasCostingItems(npd2.Id);

        // Test 4: Save Agro Costing Items
        List<Map<String, Object>> agroCostingList = new List<Map<String, Object>>{
            new Map<String, Object>{
                'id' => agroCosting.Id,
                'name' => 'Updated Agro Item',
                'molWeight' => 111.11,
                'usedInBatch' => 222.22,
                'recovered' => 50.50,
                'unitCostPerKg' => 333.33,
                'useForYieldCalc' => true
            },
            new Map<String, Object>{
                'name' => 'New Agro Item',
                'molWeight' => 123.45,
                'usedInBatch' => 67.89,
                'recovered' => 12.34,
                'unitCostPerKg' => 999.99,
                'useForYieldCalc' => false
            }
        };
        String agroCostingJson = JSON.serialize(agroCostingList);
        NPDCostingController.saveCostingItems(
            npd1.Id,
            agroCostingJson,
            250.5,
            90.2,
            60.75,
            15,
            8
        );

        // Test 5: Save Oil Gas Costing Items
        List<Map<String, Object>> oilGasList = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Id' => oilGasCosting.Id,
                'Name' => 'Updated Oil Component',
                'SG__c' => 0.85,
                'Component__c' => 85,
                'Cost_Kg__c' => 28,
                'Loss__c' => 1.5,
                'Total_Price_1__c' => 50000
            },
            new Map<String, Object>{
                'Name' => 'New Oil Component',
                'SG__c' => 0.9,
                'Component__c' => 15,
                'Cost_Kg__c' => 30,
                'Loss__c' => 1,
                'Total_Price_1__c' => 15000
            }
        };
        String oilGasJson = JSON.serialize(oilGasList);
        NPDCostingController.saveOilGasCostingItems(
            npd2.Id,
            oilGasJson,
            25,
            150,
            600,
            250,
            150,
            350
        );

        // Test 6: Delete Costing Item
        NPDCostingController.deleteCostingItem(agroCosting.Id);

        // Test 7: Exception handling for invalid IDs
        try {
            NPDCostingController.getExistingCostingItems('invalid_id');
        } catch (AuraHandledException e) {
        }

        try {
            NPDCostingController.getOilGasCostingItems('invalid_id');
        } catch (AuraHandledException e) {
        }

        // Test 8: Invalid decimal handling
        List<Map<String, Object>> invalidCostingList = new List<Map<String, Object>>{
            new Map<String, Object>{
                'name' => 'Invalid Decimal Item',
                'molWeight' => 'bad_value',
                'usedInBatch' => 10,
                'recovered' => 2,
                'unitCostPerKg' => 50,
                'useForYieldCalc' => true
            }
        };
        String invalidJson = JSON.serialize(invalidCostingList);

        try {
            NPDCostingController.saveCostingItems(
                npd1.Id,
                invalidJson,
                200,
                85,
                45,
                5,
                2
            );
        } catch (AuraHandledException e) {
        }

        Test.stopTest();
    }
}