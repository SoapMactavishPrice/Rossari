public class AccountOutstandingService {
    
    public static void processOutstandingForAccount(String accId, String customerCode, String compId, String companyCode, Date fromDate, Date toDate) {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(System.Label.SAP_Outstanding_API); // Named Credential
            req.setMethod('GET');

            // Convert Date → Datetime → format
            Datetime fdDT = Datetime.newInstance(fromDate.year(), fromDate.month(), fromDate.day());
            Datetime tdDT = Datetime.newInstance(toDate.year(), toDate.month(), toDate.day());

            // Required headers
            req.setHeader('tcode', 'ZFI015');
            req.setHeader('custn', customerCode);
            req.setHeader('cocode', companyCode);
            req.setHeader('fd', fdDT.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss'));
            req.setHeader('td', tdDT.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss'));
            String username = 'saansu.sahoo@rossari.com';
            String password = 'Saansu97@1';
            String authHeader = 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(username + ':' + password));
            req.setHeader('Authorization', authHeader);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            // Process the response
            if (res.getStatusCode() == 200) {
                System.debug('SAP Outstanding Response for customer: ' + customerCode + ', company: ' + companyCode);
                
                // Parse and create records using the existing parser
                List<Outstanding__c> records = SAPOutstandingParser.parseAndCreate(res.getBody(), accId, compId);
                if (records != null && !records.isEmpty()) {
                    // Insert the records
                    Database.SaveResult[] saveResults = Database.insert(records, false);
                    
                    // Log any errors
                    for (Integer i = 0; i < saveResults.size(); i++) {
                        if (!saveResults[i].isSuccess()) {
                            System.debug('Error inserting record: ' + saveResults[i].getErrors());
                        }
                    }
                }
            } else {
                throw new CalloutException('API callout failed with status: ' + res.getStatusCode() + ' - ' + res.getStatus());
            }
        } catch (Exception e) {
            System.debug('Error in processOutstandingForAccount: ' + e.getMessage() + ' at line: ' + e.getLineNumber());
            throw e; // Re-throw to be caught by the batch
        }
    }
}