@IsTest
public class CustomerLedgerControllerTest {

    private class SuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            String xmlResponse = 
                '<BalanceConfirmationSet>' +
                    '<Balance_confirmation>' +
                        '<XString>' + EncodingUtil.base64Encode(Blob.valueOf('Sample PDF Data')) + '</XString>' +
                    '</Balance_confirmation>' +
                '</BalanceConfirmationSet>';

            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/xml');
            res.setBody(xmlResponse);
            res.setStatusCode(200);
            return res;
        }
    }

    private class ErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setBody('Bad Request');
            return res;
        }
    }

    @IsTest
    static void testGetCompany() {
        // Create test data
        Account acc = new Account(
            Name = 'Test Account',
            SAP_Customer_Code__c = 'CUST001'
        );
        insert acc;

        Company__c comp1 = new Company__c(Name = 'Company A', SAP_Code__c = '1000');
        Company__c comp2 = new Company__c(Name = 'Company B', SAP_Code__c = '2000');
        insert new List<Company__c>{ comp1, comp2 };

        Test.startTest();
        String jsonResult = CustomerLedgerController.getCompany(acc.Id);
        Test.stopTest();

        System.assertNotEquals(null, jsonResult, 'Result should not be null');
        System.assert(jsonResult.contains('account'), 'Should contain account info');
        System.assert(jsonResult.contains('company'), 'Should contain company list');
        System.assert(jsonResult.contains('1000'), 'Should contain SAP code 1000');
    }

    // -------- TEST METHOD FOR SUCCESSFUL CALLOUT --------
    @IsTest
    static void testCustomerLedgerCalloutSuccess() {
        Account acc = new Account(
            Name = 'Test Account',
            SAP_Customer_Code__c = '1000374'
        );
        insert acc;

        // Set mock
        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        String pdfBase64 = CustomerLedgerController.customerLedgerCallout(
            acc.Id,
            '1000',
            '01.01.2025',
            '31.01.2025'
        );
        Test.stopTest();

        System.assertNotEquals('', pdfBase64, 'Base64 PDF should not be empty');
        Blob decoded = EncodingUtil.base64Decode(pdfBase64);
        System.assert(decoded.toString().contains('Sample PDF Data'), 'Decoded data should match mock content');
    }

    // -------- TEST METHOD FOR ERROR RESPONSE --------
    @IsTest
    static void testCustomerLedgerCalloutError() {
        Account acc = new Account(
            Name = 'Error Account',
            SAP_Customer_Code__c = '999999'
        );
        insert acc;

        // Set mock to simulate error
        Test.setMock(HttpCalloutMock.class, new ErrorMock());

        Test.startTest();
        String response = CustomerLedgerController.customerLedgerCallout(
            acc.Id,
            '9999',
            '01.01.2025',
            '31.01.2025'
        );
        Test.stopTest();

        System.assertEquals('', response, 'Should return empty string on failed callout');
    }
}