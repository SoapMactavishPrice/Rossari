public class AccountTriggerHandler {

    public static void validateDistributorAccount(List<Account> newAccounts) {
        Set<Id> distributorIds = new Set<Id>();

        // Collect Distributor_Name__c IDs to query
        for (Account acc : newAccounts) {
            if (acc.RecordType.DeveloperName == 'Secondary' && acc.Distributor_Name__c != null) {
                distributorIds.add(acc.Distributor_Name__c);
            }
        }

        if (distributorIds.isEmpty()) return;

        // Query parent (distributor) accounts
        Map<Id, Account> distributors = new Map<Id, Account>(
            [SELECT Id, RecordType.DeveloperName FROM Account WHERE Id IN :distributorIds]
        );

        // Validate
        for (Account acc : newAccounts) {
            if (acc.RecordType.DeveloperName == 'Secondary' && acc.Distributor_Name__c != null) {
                Account parentAcc = distributors.get(acc.Distributor_Name__c);

                if (parentAcc == null || parentAcc.RecordType.DeveloperName != 'Primary') {
                    acc.Distributor_Name__c.addError('Only accounts with Record Type = Primary can be selected as Distributor.');
                }
            }
        }
    }

    public static void addSFCustomerSequence(List<Account> newAccounts) {
        // Query the code master for Account sequence
        List<Code_Master__c> codeMasters = [
            SELECT Id, Name, Object__c, Current_Sequence__c, Starting_Sequence__c,
            Backend_Current_Sequence__c
            FROM Code_Master__c
            WHERE Object__c = 'Account' AND isActive__c = true
            LIMIT 1
            FOR UPDATE
        ];

        System.debug('codeMasters: ' + codeMasters);
        
        if (!codeMasters.isEmpty()) {
            Code_Master__c codeMaster = codeMasters[0];
            
            // Get the next sequence number
            Decimal nextSequence = codeMaster.Current_Sequence__c + 1;
            
            for(Account acc : newAccounts) {
                // Format the sequence with leading zeros if needed
                String sequenceStr = String.valueOf(nextSequence);
                
                // Update the account field
                acc.SFDC_Customer_Code__c = sequenceStr;
                
                // Increment sequence for next account
                nextSequence++;
            }
            
            // Update the code master with the new sequence
            codeMaster.Current_Sequence__c = nextSequence - 1; // -1 because we already incremented
            update codeMaster;
        }
    }

}