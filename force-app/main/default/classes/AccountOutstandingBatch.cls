global class AccountOutstandingBatch implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {
    Date fromDate;
    Date toDate;
    Map<String, String> companyCodes = new Map<String, String>();
    List<String> errorLogs = new List<String>();
    
    // Track the current account index for chaining
    private Integer currentAccountIndex = 0;
    private List<Account> accountsToProcess = new List<Account>();

    public AccountOutstandingBatch(Date fd, Date td) {
        this.fromDate = fd;
        this.toDate = td;
        
        // Get all company codes once in the constructor
        for (Company__c com : [SELECT Id, SAP_Code__c FROM Company__c WHERE SAP_Code__c != null]) {
            companyCodes.put(com.Id, com.SAP_Code__c);
        }
    }
    
    // Additional constructor for chaining
    public AccountOutstandingBatch(Date fd, Date td, List<Account> accounts, Integer startIndex) {
        this(fd, td);
        this.accountsToProcess = accounts;
        this.currentAccountIndex = startIndex;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        // Get all accounts that need processing
        return Database.getQueryLocator(
            'SELECT Id, SAP_Customer_Code__c FROM Account WHERE SAP_Customer_Code__c != null AND Id = \'001C100000NEl3cIAD\''
        );
    }

    global void execute(Database.BatchableContext bc, List<Account> scope) {
        // Store accounts for processing
        if (accountsToProcess.isEmpty()) {
            accountsToProcess = scope;
        }
        
        // Process one account at a time
        if (currentAccountIndex < accountsToProcess.size()) {
            Account acc = accountsToProcess[currentAccountIndex];
            
            // Process all companies for this account in a single Queueable job
            System.enqueueJob(new AccountOutstandingQueueable(
                acc.SAP_Customer_Code__c,
                companyCodes.values()[0], // Process first company
                fromDate,
                toDate,
                acc.Id,
                new List<String>(companyCodes.keySet())
            ));
            
            // Increment for next batch execution
            currentAccountIndex++;
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