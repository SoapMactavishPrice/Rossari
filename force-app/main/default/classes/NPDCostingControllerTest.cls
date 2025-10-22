@isTest
public class NPDCostingControllerTest {

    @isTest
    static void testNPDCostingController_AllInOne() {
        // Step 1: Create base NPD record
        New_Product_Development__c npd = new New_Product_Development__c(
            Name = 'Test NPD',
            Yield_and_RMC_change__c = 100,
            Molecular_wt_of_the_Product__c = 200,
            Profit_Expected_Per_Kg__c = 50
        );
        insert npd;

        // Step 2: Create costing item (existing one)
        NPD_Costing__c costing = new NPD_Costing__c(
            Name = 'Test Costing',
            New_Product_Development__c = npd.Id,
            Mol_wt__c = 180,
            Used_in_Batch_Kgs__c = 90,
            Recoverd__c = 40,
            Unit_Cost_Per_Kg__c = 200,
            Use_for_Yield_Calc__c = true
        );
        insert costing;

        Test.startTest();

        // Step 3: Call getExistingCostingItems
        Map<String, Object> resultMap = NPDCostingController.getExistingCostingItems(npd.Id);
        List<NPD_Costing__c> existingItems = (List<NPD_Costing__c>) resultMap.get('costingItems');

        // Step 4: Call getYieldAndRMCChange
        Decimal yield = NPDCostingController.getYieldAndRMCChange(npd.Id);

        // Step 5: Prepare JSON to cover saveCostingItems (Valid)
        List<Map<String, Object>> costingList = new List<Map<String, Object>>{
            new Map<String, Object>{
                'id' => costing.Id,
                'name' => 'Updated Costing Item',
                'molWeight' => 111.11,
                'usedInBatch' => 222.22,
                'recovered' => 50.50,
                'unitCostPerKg' => 333.33,
                'useForYieldCalc' => true
            },
            new Map<String, Object>{
                'name' => 'New Item Without ID',
                'molWeight' => 123.45,
                'usedInBatch' => 67.89,
                'recovered' => 12.34,
                'unitCostPerKg' => 999.99,
                'useForYieldCalc' => false
            }
        };
        String costingJson = JSON.serialize(costingList);

        // Step 6: Call saveCostingItems (Valid Path)
        NPDCostingController.saveCostingItems(
            npd.Id,
            costingJson,
            250.5,
            90.2,
            60.75
        );

        // Step 7: Call saveCostingItems (Invalid Decimal Path — should throw error)
        List<Map<String, Object>> invalidCostingList = new List<Map<String, Object>>{
            new Map<String, Object>{
                'name' => 'Invalid Decimal',
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
                npd.Id,
                invalidJson,
                200,
                85,
                45
            );
        } catch (AuraHandledException e) {
            // Expected: Invalid decimal parsing
        }

        // Step 8: Delete existing costing item
        NPDCostingController.deleteCostingItem(costing.Id);

        Test.stopTest();
    }
}