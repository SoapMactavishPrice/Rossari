@isTest
public class NPDCostingControllerTest {

    @isTest
    static void testNPDCostingController_AllInOne() {
        // Step 1: Create test NPD record
        New_Product_Development__c npd = new New_Product_Development__c(
            Name = 'Test NPD',
            Yield_and_RMC_change__c = 100,
            Molecular_wt_of_the_Product__c = 200,
            Profit_Expected_Per_Kg__c = 50
        );
        insert npd;

        // Step 2: Create test costing item
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

        // 3. Get Existing Costing Items
        Map<String, Object> resultMap = NPDCostingController.getExistingCostingItems(npd.Id);
        List<NPD_Costing__c> existingItems = (List<NPD_Costing__c>) resultMap.get('costingItems');
        System.assertNotEquals(null, existingItems);
        System.assert(!existingItems.isEmpty(), 'Existing costing items should not be empty');

        // 4. Get Yield and RMC Change
        Decimal yield = NPDCostingController.getYieldAndRMCChange(npd.Id);
        System.assertEquals(100, yield);

        // 5. Save Costing Items with various data types
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

        NPDCostingController.saveCostingItems(
            npd.Id,
            costingJson,
            Decimal.valueOf('210.5'),         // updated molecularWeight
            Decimal.valueOf('90.2'),          // updated yieldAndRMCChange
            Decimal.valueOf('60.75')          // updated profitExpectedPerKg
        );

        // 6. Save Costing Items with invalid decimal value to test exception block
        List<Map<String, Object>> invalidCostingList = new List<Map<String, Object>>{
            new Map<String, Object>{
                'name' => 'Invalid Decimal',
                'molWeight' => 'invalid_value',   // should trigger parseDecimal failure
                'usedInBatch' => 10,
                'recovered' => 2,
                'unitCostPerKg' => 50
            }
        };
        String invalidJson = JSON.serialize(invalidCostingList);

        Boolean exceptionThrown = false;
        try {
            NPDCostingController.saveCostingItems(
                npd.Id,
                invalidJson,
                Decimal.valueOf('210'),
                Decimal.valueOf('85'),
                Decimal.valueOf('45')
            );
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'Expected exception for invalid decimal input');

        // 7. Delete costing item
        NPDCostingController.deleteCostingItem(costing.Id);

        Test.stopTest();
    }
}