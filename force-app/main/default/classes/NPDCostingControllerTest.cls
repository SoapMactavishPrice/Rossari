@isTest
public class NPDCostingControllerTest {

    @isTest
    static void testNPDCostingController_AllInOne() {
        New_Product_Development__c npd = new New_Product_Development__c(
            Name = 'Test NPD',
            Yield_and_RMC_change__c = 100
        );
        insert npd;

        NPD_Costing__c costing = new NPD_Costing__c(
            Name = 'Test Costing',
            New_Product_Development__c = npd.Id,
            Mol_wt__c = 180,
            Used_in_Batch_Kgs__c = 90,
            Recoverd__c = 40,
            Unit_Cost_Per_Kg__c = 200
        );
        insert costing;

        Test.startTest();

        // 1. Get Existing Costing Items
        List<NPD_Costing__c> existingItems = NPDCostingController.getExistingCostingItems(npd.Id);

        // 2. Get Yield and RMC Change
        Decimal yield = NPDCostingController.getYieldAndRMCChange(npd.Id);

        // 3. Save Costing Items with various data types (Decimal, Integer, Double, String)
        List<Map<String, Object>> costingList = new List<Map<String, Object>>{
            new Map<String, Object>{
                'id' => costing.Id,
                'name' => 'Updated Name',
                'molWeight' => Decimal.valueOf('88.88'),   // Decimal
                'usedInBatch' => 100,                      // Integer
                'recovered' => 33.33,                      // Double
                'unitCostPerKg' => '55.55'                 // String
            }
        };
        String costingJson = JSON.serialize(costingList);
        NPDCostingController.saveCostingItems(npd.Id, costingJson);

        // 4. Save Costing Items with invalid decimal value to test exception block
        List<Map<String, Object>> invalidCostingList = new List<Map<String, Object>>{
            new Map<String, Object>{
                'name' => 'Invalid Decimal',
                'molWeight' => 'invalid_value',
                'usedInBatch' => 10,
                'recovered' => 2,
                'unitCostPerKg' => 50
            }
        };
        String invalidJson = JSON.serialize(invalidCostingList);
        try {
            NPDCostingController.saveCostingItems(npd.Id, invalidJson);
        } catch (AuraHandledException e) {
            // Expected
        }

        // 5. Delete costing item
        NPDCostingController.deleteCostingItem(costing.Id);

        Test.stopTest();
    }
}