public class AccountOutstandingQueueable implements Queueable, Database.AllowsCallouts {
    private String customerNumber;
    private String currentCompanyCode;
    private String accountId;
    private Date fromDate;
    private Date toDate;
    private List<String> remainingCompanyIds;
    private Map<String, String> companyCodes = new Map<String, String>();

    public AccountOutstandingQueueable(String customerNumber, String currentCompanyCode, 
                                     Date fromDate, Date toDate, String accountId, 
                                     List<String> companyIds) {
        this.customerNumber = customerNumber;
        this.currentCompanyCode = currentCompanyCode;
        this.fromDate = fromDate;
        this.toDate = toDate;
        this.accountId = accountId;
        this.remainingCompanyIds = companyIds;
        
        // Store company codes in a map for easy lookup
        for (Company__c com : [SELECT Id, SAP_Code__c FROM Company__c WHERE Id IN :companyIds]) {
            this.companyCodes.put(com.Id, com.SAP_Code__c);
        }
    }

    public void execute(QueueableContext context) {
        try {
            // Process the current company if we have one
            if (String.isNotBlank(currentCompanyCode)) {
                makeCalloutToSAP(currentCompanyCode);
            }
            
            // Process next company if any
            if (remainingCompanyIds != null && !remainingCompanyIds.isEmpty()) {
                // Create a new list to avoid modifying the original
                List<String> nextCompanies = new List<String>(remainingCompanyIds);
                
                // Remove the first company (current one) if it exists in the list
                if (nextCompanies.size() > 0) {
                    nextCompanies.remove(0);
                }
                
                if (!nextCompanies.isEmpty()) {
                    // Get the next company to process
                    String nextCompanyId = nextCompanies[0];
                    String nextCompanyCode = companyCodes.get(nextCompanyId);
                    
                    // Chain the next job with the remaining companies
                    System.enqueueJob(new AccountOutstandingQueueable(
                        customerNumber, 
                        nextCompanyCode, 
                        fromDate, 
                        toDate,
                        accountId,
                        nextCompanies  // Pass the updated list without the current company
                    ));
                }
            }
        } catch (Exception e) {
            System.debug('Error in AccountOutstandingQueueable: ' + e.getMessage() + 
                       ' at line: ' + e.getLineNumber());
            // You might want to log this error to a custom object
        }
    }
    
    private void makeCalloutToSAP(String companyCode) {
        API_Log__c apiLog = new API_Log__c();
        String companyId = getCompanyIdByCode(companyCode);
        String requestBody = '';
        String responseBody = '';
        
        try {
            // Create API Log record
            apiLog.Name = 'Outstanding_API_' + customerNumber + '_' + companyCode;
            
            // Prepare request
            HttpRequest req = new HttpRequest();
            req.setEndpoint(System.Label.SAP_Outstanding_API);
            req.setMethod('GET');
            
            // Set headers
            Datetime fdDT = Datetime.newInstance(fromDate.year(), fromDate.month(), fromDate.day());
            Datetime tdDT = Datetime.newInstance(toDate.year(), toDate.month(), toDate.day());
            
            req.setHeader('tcode', 'ZFI015');
            req.setHeader('custn', customerNumber);
            req.setHeader('cocode', companyCode);
            req.setHeader('fd', fdDT.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss'));
            req.setHeader('td', tdDT.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss'));
            
            // Add basic auth if needed
            String username = 'saansu.sahoo@rossari.com';
            String password = 'Saansu97@1';
            String authHeader = 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(username + ':' + password));
            req.setHeader('Authorization', authHeader);
            
            // Log request
            Map<String, String> requestHeaders = new Map<String, String>{
                'tcode' => 'ZFI015',
                'custn' => customerNumber,
                'cocode' => companyCode,
                'fd' => fdDT.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss'),
                'td' => tdDT.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss')
            };
            
            requestBody = JSON.serializePretty(requestHeaders);
            
            // Make the callout
            Http http = new Http();
            HttpResponse res = http.send(req);
            responseBody = res.getBody();
            
            if (res.getStatusCode() == 200) {
                System.debug('SAP Response for customer: ' + customerNumber + ', company: ' + companyCode);
                
                // Parse and create records
                List<Outstanding__c> records = SAPOutstandingParser.parseAndCreate(responseBody, accountId, companyId);
                if (records != null && !records.isEmpty()) {
                    // Insert the records with all or none set to false to allow partial success
                    Database.SaveResult[] saveResults = Database.insert(records, false);
                    
                    // Check for errors
                    List<String> errorMessages = new List<String>();
                    for (Integer i = 0; i < saveResults.size(); i++) {
                        if (!saveResults[i].isSuccess()) {
                            for (Database.Error err : saveResults[i].getErrors()) {
                                errorMessages.add('Record ' + i + ': ' + err.getMessage());
                            }
                        }
                    }
                    
                    if (!errorMessages.isEmpty()) {
                        apiLog.Exception_Description__c = String.join(errorMessages, '\n');
                        apiLog.Status__c = 'Failed';
                    } else {
                        apiLog.Status__c = 'Success';
                    }
                } else {
                    apiLog.Status__c = 'Success';
                }
            } else {
                String errorMsg = 'Error from SAP: ' + res.getStatusCode() + ' - ' + res.getBody();
                System.debug(errorMsg);
                apiLog.Exception_Description__c = errorMsg;
                apiLog.Status__c = 'Failed';
            }
            
        } catch (Exception e) {
            String errorMsg = 'Error in makeCalloutToSAP: ' + e.getMessage() + ' at line: ' + e.getLineNumber();
            System.debug(errorMsg);
            apiLog.Exception_Description__c = errorMsg + '\n' + e.getStackTraceString();
            apiLog.Status__c = 'Failed';
        } finally {
            try {
                // Update API Log with final details
                apiLog.Request__c = requestBody;
                
                // Limit response size to avoid hitting field size limits
                apiLog.Response__c = responseBody != null && responseBody.length() > 131072 
                    ? responseBody.substring(0, 131072) 
                    : responseBody;
                
                // Insert the API Log
                insert apiLog;
                
            } catch (Exception logEx) {
                System.debug('Error logging API call: ' + logEx.getMessage());
            }
        }
    }
    
    private String getCompanyIdByCode(String companyCode) {
        for (String companyId : companyCodes.keySet()) {
            if (companyCodes.get(companyId) == companyCode) {
                return companyId;
            }
        }
        return null;
    }
}