@IsTest
public class UploadPricebookEntriesControllerTest {

    @IsTest
    static void testProcessPriceChunk() {

        Pricebook2 standardPb = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPb;

        Base_UoM_Master__c uom = new Base_UoM_Master__c(Name = 'Kilogram');
        insert uom;

        Product2 p1 = new Product2(
            Name = 'Test Product A',
            ProductCode = 'MAT001',
            Base_UOM__c = uom.Id,
            Pack_Size__c = '10kg',
            IsActive = true,
            Create_PricebookEntry__c = false
        );

        Product2 p2 = new Product2(
            Name = 'Test Product B',
            ProductCode = 'MAT002',
            Base_UOM__c = uom.Id,
            Pack_Size__c = '20kg',
            IsActive = true,
            Create_PricebookEntry__c = false
        );

        insert new List<Product2>{ p1, p2 };

        PricebookEntry std1 = new PricebookEntry(
            Pricebook2Id = standardPb.Id,
            Product2Id = p1.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert std1;

        List<Map<String,Object>> rows = new List<Map<String,Object>>();

        rows.add(new Map<String,Object>{
            'Material' => 'MAT001',
            'UnitPrice' => '150',
            'Currency' => 'INR',
            'ConvDollar' => '1.2',
            'ConvEuro' => '1.1',
            '__rowIndex' => '0'
        });

        rows.add(new Map<String,Object>{
            'Material' => 'MAT002',
            'UnitPrice' => '250',
            'Currency' => 'USD',
            'ConvDollar' => '1.5',
            'ConvEuro' => '1.3',
            '__rowIndex' => '1'
        });

        rows.add(new Map<String,Object>{
            'Material' => 'MAT002',
            'UnitPrice' => '250',
            'Currency' => 'USD',
            '__rowIndex' => '2'
        });

        rows.add(new Map<String,Object>{
            'Material' => '',
            'UnitPrice' => '300',
            'Currency' => 'EUR',
            '__rowIndex' => '3'
        });

        String jsonInput = JSON.serialize(rows);

        Test.startTest();
        UploadPricebookEntriesController.processPriceChunk(jsonInput);
        Test.stopTest();
    }
}