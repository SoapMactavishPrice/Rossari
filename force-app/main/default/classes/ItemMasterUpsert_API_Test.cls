@IsTest
private class ItemMasterUpsert_API_Test {
    @TestSetup
    static void setupTestData() {
        Product2 existingProduct = new Product2(
            Name = 'Existing Product',
            ProductCode = 'EXISTING123',
            IsActive = true
        );
        insert existingProduct;
    }

    @IsTest
    static void testDoPostSuccessNewProduct() {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        String jsonBody = '[{"Name":"Test Product","itemCode":"TEST123","itemDescription":"Test Description"}]';
        request.requestBody = Blob.valueOf(jsonBody);
        request.httpMethod = 'POST';
        
        RestContext.request = request;
        RestContext.response = response;

        Test.startTest();
        ItemMasterUpsert_API.doPost();
        Test.stopTest();
    }

    @IsTest
    static void testDoPostSuccessUpdateProduct() {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        String jsonBody = '[{"Name":"Updated Product","itemCode":"EXISTING123","itemDescription":"Updated Description"}]';
        request.requestBody = Blob.valueOf(jsonBody);
        request.httpMethod = 'POST';
        
        RestContext.request = request;
        RestContext.response = response;

        Test.startTest();
        ItemMasterUpsert_API.doPost();
        Test.stopTest();
    }

    @IsTest
    static void testDoPostMultipleProducts() {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        String jsonBody = '[{"Name":"Product 1","itemCode":"P1","itemDescription":"Desc 1"},{"Name":"Product 2","itemCode":"P2","itemDescription":"Desc 2"}]';
        request.requestBody = Blob.valueOf(jsonBody);
        request.httpMethod = 'POST';
        
        RestContext.request = request;
        RestContext.response = response;

        Test.startTest();
        ItemMasterUpsert_API.doPost();
        Test.stopTest();
    }

    @IsTest
    static void testDoPostMissingItemCode() {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        String jsonBody = '[{"Name":"Test Product","itemDescription":"Test Description"}]';
        request.requestBody = Blob.valueOf(jsonBody);
        request.httpMethod = 'POST';
        
        RestContext.request = request;
        RestContext.response = response;

        Test.startTest();
        ItemMasterUpsert_API.doPost();
        Test.stopTest();
    }

    @IsTest
    static void testDoPostEmptyRequestBody() {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        request.requestBody = Blob.valueOf('[]');
        request.httpMethod = 'POST';
        
        RestContext.request = request;
        RestContext.response = response;

        Test.startTest();
        ItemMasterUpsert_API.doPost();
        Test.stopTest();
    }

}