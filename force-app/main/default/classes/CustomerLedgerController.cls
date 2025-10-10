public class CustomerLedgerController {
    
    @AuraEnabled
    public static string getCompany(String accId){
        try {

            Map<String, Object> resMap = new Map<String, Object>();

            Account acc = [SELECT Id, Name, SAP_Customer_Code__c FROM Account WHERE Id = :accId];
            resMap.put('account', acc);

            List < Company__c > cmList = new List < Company__c > ();
            cmList = [SELECT Id, SAP_Code__c FROM Company__c  WHERE SAP_Code__c != null];

            List<Map < string, string >> companyMapList = new List<Map < string, string >>();
            for (Company__c com : cmList) {
                Map < string, string > mapCompany = new Map < string, string > ();
                mapCompany.put('label', com.SAP_Code__c);
                mapCompany.put('value', com.SAP_Code__c);
                companyMapList.add(mapCompany);
            }

            resMap.put('company', companyMapList);

            return JSON.serialize(resMap);

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static String customerLedgerCallout(String accId, String company, String fromDate, String toDate) {

        Account acc = [SELECT Id, Name, SAP_Customer_Code__c FROM Account WHERE Id = :accId];

        String filter = 'Company eq \''+company+'\' and Customer eq \''+acc.SAP_Customer_Code__c+'\' and DateFrom eq \''+fromDate+'\' and DateTo eq \''+toDate+'\'';
        // String filter = 'Company eq \'1000\' and Customer eq \'1000374\' and DateFrom eq \'20.09.2024\' and DateTo eq \'15.12.2025\'';
        
        // URL encode the filter
        String encodedFilter = EncodingUtil.urlEncode(filter, 'UTF-8');

        String endPointUrl = System.Label.CustomerLedger_URL+'?$filter='+encodedFilter;

        System.debug('endPointUrl: ' + endPointUrl);

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endPointUrl);
        req.setMethod('GET');
        // req.setHeader('Accept', 'application/xml');
        // Add basic auth if needed
        String username = System.Label.CreateQuotation_ToSAP_Username;
        String password = System.Label.CreateQuotation_ToSAP_Pass;
        String authHeader = 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(username + ':' + password));
        req.setHeader('Authorization', authHeader);

        Http http = new Http();
        HttpResponse res;
        try {
            res = http.send(req);
        } catch (Exception ex) {
            throw new AuraHandledException('Error calling external service: ' + ex.getMessage());
        }

        if (res.getStatusCode() == 200) {
            String body = res.getBody();
            // Parse the XML to extract XString
            Dom.Document doc = new Dom.Document();
            doc.load(body);
            Dom.XmlNode root = doc.getRootElement();  // <BalanceConfirmationSet>
            // Might have multiple <Balance_confirmation> nodes, assuming you want first
            for (Dom.XmlNode bc : root.getChildElements()) {
                if (bc.getName().equals('Balance_confirmation')) {
                    Dom.XmlNode xNode = bc.getChildElement('XString', null);
                    if (xNode != null) {
                        String base64Pdf = xNode.getText();
                        return base64Pdf;
                    }
                }
            }
            // If no XString found
            // throw new AuraHandledException('XString element not found in response');
        } else {
            // Log error or throw
            String err = 'Callout failed, status: ' + res.getStatusCode() + ' body: ' + res.getBody();
            System.debug(err);
            // throw new AuraHandledException(err);
        }
        return '';
    }


}