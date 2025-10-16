@isTest
public class NPDCostingControllerTest {

    @isTest
    static void testNPDCostingController_AllInOne() {
        New_Product_Development__c npd = new New_Product_Development__c(
            Name = 'Test NPD',
            Yield_and_RMC_change__c = 100,
            Molecular_wt_of_the_Product__c = 200,
            Profit_Expected_Per_Kg__c = 50
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

        Map<String, Object> resultMap = NPDCostingController.getExistingCostingItems(npd.Id);
        List<NPD_Costing__c> existingItems = (List<NPD_Costing__c>) resultMap.get('costingItems');

        Decimal yield = NPDCostingController.getYieldAndRMCChange(npd.Id);

        List<Map<String, Object>> costingList = new List<Map<String, Object>>{
            new Map<String, Object>{
                'id' => costing.Id,
                'name' => 'Updated Name',
                'molWeight' => Decimal.valueOf('88.88'),
                'usedInBatch' => 100,
                'recovered' => 33.33,
                'unitCostPerKg' => '55.55'
            }
        };
        String costingJson = JSON.serialize(costingList);

   /*     NPDCostingController.saveCostingItems(
            npd.Id,
            costingJson,
            Decimal.valueOf('210.5'),
            Decimal.valueOf('90.2'),
            Decimal.valueOf('60.75')
        );	*/

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
            NPDCostingController.saveCostingItems(
                npd.Id,
                invalidJson,
                Decimal.valueOf('210'),
                Decimal.valueOf('85'),
                Decimal.valueOf('45')
            );
        } catch (AuraHandledException e) {
            // Expected exception for invalid decimal input
        }

        NPDCostingController.deleteCostingItem(costing.Id);

        Test.stopTest();
    }
}