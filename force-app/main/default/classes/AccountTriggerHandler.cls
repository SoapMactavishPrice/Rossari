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
}