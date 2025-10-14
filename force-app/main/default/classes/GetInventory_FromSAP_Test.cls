@isTest
private class GetInventory_FromSAP_Test {
    
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/xml');
            res.setStatusCode(200);
            res.setBody('<?xml version="1.0" encoding="UTF-8"?>' +
                        '<InventorySet>' +
                        '    <Inventory>' +
                        '        <MaterialNumber>123456</MaterialNumber>' +
                        '        <MaterialDescription>Test Material</MaterialDescription>' +
                        '        <BatchNumber>BN001</BatchNumber>' +
                        '        <Plant>PL01</Plant>' +
                        '        <StorageLocation>SL01</StorageLocation>' +
                        '        <StorageLocationDescription>Test Location</StorageLocationDescription>' +
                        '        <UnrestrictedUseStock>100.5</UnrestrictedUseStock>' +
                        '        <BaseUnitofMeasure>EA</BaseUnitofMeasure>' +
                        '        <DateofManufacture>2023-01-01</DateofManufacture>' +
                        '        <ShelfLifeExpirationDate>2024-01-01</ShelfLifeExpirationDate>' +
                        '        <MaterialType>ZFG</MaterialType>' +
                        '        <MaterialGroup>MG01</MaterialGroup>' +
                        '        <ProductHierarchy>PH01</ProductHierarchy>' +
                        '        <ProductHierarchyText>Test Hierarchy</ProductHierarchyText>' +
                        '        <ValueofUnrestrictedStock>500.75</ValueofUnrestrictedStock>' +
                        '        <CurrencyKey>USD</CurrencyKey>' +
                        '    </Inventory>' +
                        '</InventorySet>');
            return res;
        }
    }

    @isTest
    static void testFetchInventoryData() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        List<GetInventory_FromSAP.InventoryData> result = GetInventory_FromSAP.fetchInventoryData('123456');
    }
}