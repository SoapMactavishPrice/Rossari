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
            Base_UoM__c = uom.Id,
            Pack_Size__c = '20kg',
            IsActive = true,
            Create_PricebookEntry__c = false
        );

        Product2 p3 = new Product2(
            Name = 'Test Product C',
            ProductCode = 'MAT003',
            Base_UOM__c = uom.Id,
            Pack_Size__c = '10kg',
            IsActive = true,
            Create_PricebookEntry__c = false
        );

        Product2 p4 = new Product2(
            Name = 'Test Product D',
            ProductCode = 'MAT004',
            Base_UOM__c = uom.Id,
            Pack_Size__c = '10kg',
            IsActive = true,
            Create_PricebookEntry__c = false
        );

        Product2 p5 = new Product2(
            Name = 'Test Product E',
            ProductCode = 'MAT005',
            Base_UOM__c = uom.Id,
            Pack_Size__c = '10kg',
            IsActive = true,
            Create_PricebookEntry__c = false
        );

        Product2 p6 = new Product2(
            Name = 'Test Product F',
            ProductCode = 'MAT006',
            Base_UOM__c = uom.Id,
            Pack_Size__c = '20kg',
            IsActive = true,
            Create_PricebookEntry__c = false
        );

        Product2 p7 = new Product2(
            Name = 'Test Product G',
            ProductCode = 'MAT007',
            Base_UOM__c = uom.Id,
            Pack_Size__c = '10kg',
            IsActive = true,
            Create_PricebookEntry__c = false
        );

        Product2 p8 = new Product2(
            Name = 'Test Product H',
            ProductCode = 'MAT008',
            Base_UOM__c = uom.Id,
            Pack_Size__c = '10kg',
            IsActive = true,
            Create_PricebookEntry__c = false
        );

        insert new List<Product2>{ p1, p2, p3, p4, p5, p6, p7, p8 };

        PricebookEntry std1 = new PricebookEntry(
            Pricebook2Id = standardPb.Id,
            Product2Id = p1.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert std1;

        PricebookEntry usdEntry = new PricebookEntry(
            Pricebook2Id = standardPb.Id,
            Product2Id = p5.Id,
            UnitPrice = 100,
            CurrencyIsoCode = 'USD',
            Conversion_Rate_Dollar__c = 1.0,
            Conversion_Rate_Euro__c = 0.9,
            IsActive = true
        );

        PricebookEntry eurEntry = new PricebookEntry(
            Pricebook2Id = standardPb.Id,
            Product2Id = p6.Id,
            UnitPrice = 200,
            CurrencyIsoCode = 'EUR',
            Conversion_Rate_Dollar__c = 1.1,
            Conversion_Rate_Euro__c = 1.0,
            IsActive = true
        );

        PricebookEntry existingEntry = new PricebookEntry(
            Pricebook2Id = standardPb.Id,
            Product2Id = p7.Id,
            UnitPrice = 100,
            CurrencyIsoCode = 'USD',
            Conversion_Rate_Dollar__c = 1.0,
            IsActive = true
        );

        insert new List<PricebookEntry>{ usdEntry, eurEntry, existingEntry };

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

        rows.add(new Map<String,Object>{
            'Material' => 'MAT003',
            'UnitPrice' => '200',
            'Currency' => 'USD',
            'ConvDollar' => '₹1.2',
            'ConvEuro' => '$1.1',
            '__rowIndex' => '4'
        });

        rows.add(new Map<String,Object>{
            'Material' => 'MAT003',
            'UnitPrice' => '300',
            'Currency' => 'EUR',
            'ConvDollar' => '£1.4',
            'ConvEuro' => '1,500',
            '__rowIndex' => '5'
        });

        rows.add(new Map<String,Object>{
            'Material' => 'MAT004',
            'UnitPrice' => null,
            'Currency' => 'USD',
            '__rowIndex' => '6'
        });

        rows.add(new Map<String,Object>{
            'Material' => null,
            'UnitPrice' => '100',
            'Currency' => 'INR',
            '__rowIndex' => '7'
        });

        rows.add(new Map<String,Object>{
            'Material' => 'MAT005',
            'UnitPrice' => '150',
            'Currency' => 'USD',
            'ConvDollar' => '1.2',
            'ConvEuro' => '1.1',
            '__rowIndex' => '8'
        });

        rows.add(new Map<String,Object>{
            'Material' => 'MAT006',
            'UnitPrice' => '250',
            'Currency' => 'EUR',
            'ConvDollar' => '1.3',
            'ConvEuro' => '1.4',
            '__rowIndex' => '9'
        });

        rows.add(new Map<String,Object>{
            'Material' => 'MAT007',
            'UnitPrice' => '100',
            'Currency' => 'USD',
            'ConvDollar' => '1.0',
            '__rowIndex' => '10'
        });

        rows.add(new Map<String,Object>{
            'Material' => 'MAT008',
            'UnitPrice' => '100',
            'Currency' => 'INR',
            '__rowIndex' => '11'
        });

        String jsonInput = JSON.serialize(rows);

        Test.startTest();
        UploadPricebookEntriesController.processPriceChunk(jsonInput);
        Test.stopTest();
    }
}