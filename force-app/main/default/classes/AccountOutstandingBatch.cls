global class AccountOutstandingBatch implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {
    Date fromDate;
    Date toDate;
    Map<String, String> companyCodes = new Map<String, String>();
    List<String> errorLogs = new List<String>();
    
    public AccountOutstandingBatch(Date fd, Date td) {
        this.fromDate = fd;
        this.toDate = td;
        
        // Get all company codes once in the constructor
        for (Company__c com : [SELECT Id, SAP_Code__c FROM Company__c WHERE SAP_Code__c != null]) {
            companyCodes.put(com.Id, com.SAP_Code__c);
        }
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        // Get all accounts that need processing
        return Database.getQueryLocator(
            'SELECT Id, SAP_Customer_Code__c FROM Account WHERE SAP_Customer_Code__c != null LIMIT 100'
        );
    }

    global void execute(Database.BatchableContext bc, List<Account> scope) {
        // Process each account in the current batch scope
        for (Account acc : scope) {
            if (String.isNotBlank(acc.SAP_Customer_Code__c)) {
                try {
                    // Process all companies for this account in a single Queueable job
                    System.enqueueJob(new AccountOutstandingQueueable(
                        acc.SAP_Customer_Code__c,
                        companyCodes.values()[0], // Start with first company
                        fromDate,
                        toDate,
                        acc.Id,
                        new List<String>(companyCodes.keySet())
                    ));
                } catch (Exception e) {
                    String errorMsg = 'Error processing account ' + acc.Id + ': ' + e.getMessage();
                    errorLogs.add(errorMsg);
                    System.debug(errorMsg);
                }
            }
        }
    }

    global void finish(Database.BatchableContext bc) {
        // Log any errors that occurred during processing
        if (!errorLogs.isEmpty()) {
            // You might want to send an email or create a custom log record here
            System.debug('Errors occurred during processing: ' + errorLogs);
        }
        System.debug('Batch processing completed. All callouts have been queued.');
    }
}