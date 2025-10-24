@isTest
public class ItemMasterUpsert_APITest {

    @isTest
    static void testDoPost_AllScenarios() {
        Id standardPricebookId = Test.getStandardPricebookId();

        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        try{
        update standardPricebook;
         }Catch(Exception e){}

        Base_UoM_Master__c baseUom = new Base_UoM_Master__c(Name = 'Kilogram');
        insert baseUom;
 
        Product2 prod = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP001',
            Pack_Size__c = '10kg',
            Base_UOM__c = baseUom.Id,
            IsActive = true
        );
        insert prod;
 
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;


        Product2 existingProduct = new Product2(Name = 'Existing Product', ProductCode = 'EX123', IsActive = true);
        insert existingProduct;

        Product2 anotherExistingProduct = new Product2(Name = 'Another Existing', ProductCode = 'EX789', IsActive = true);
        insert anotherExistingProduct;

        List<String> payloads = new List<String>{
            '[{"Name":"Updated Product","itemCode":"EX123","itemDescription":"Updated Description"}]',
            '[{"Name":"New Product","itemCode":"NEW456","itemDescription":"New Description"}]',
            '[{"Name":"Invalid Product","itemCode":"","itemDescription":"Missing Code"}]',
            '[' +
                '{"Name":"Existing Product Updated","itemCode":"EX789","itemDescription":"Updated Desc"},' +
                '{"Name":"Brand New Product","itemCode":"NEW999","itemDescription":"Fresh Entry"}' +
            ']'
        };

        for (String jsonBody : payloads) {
            RestRequest req = new RestRequest();
            req.requestBody = Blob.valueOf(jsonBody);
            req.httpMethod = 'POST';
            req.requestURI = '/services/apexrest/ItemMasterUpsert';

            RestContext.request = req;
            RestContext.response = new RestResponse();

            ItemMasterUpsert_API.doPost();
        }
    }
}