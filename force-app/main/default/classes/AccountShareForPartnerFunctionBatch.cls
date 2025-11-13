public class AccountShareForPartnerFunctionBatch implements Database.Batchable<SObject>, Database.Stateful, Schedulable {
    
    // ----------- BATCH START -----------
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Account__c, Sales_Employee__c
            FROM Partner_function__c
            WHERE PARTNER_FUNC__c = 'VE'
            AND Sales_Employee__c != null
            AND Account__c != null
        ]);
    }
    
    // ----------- BATCH EXECUTE -----------
    public void execute(Database.BatchableContext bc, List<Partner_function__c> partnerList) {
        Set<Id> accountIds = new Set<Id>();
        Map<Id, Id> accountToUserMap = new Map<Id, Id>();
        
        for (Partner_function__c pf : partnerList) {
            if (pf.Account__c != null && pf.Sales_Employee__c != null) {
                accountIds.add(pf.Account__c);
                accountToUserMap.put(pf.Account__c, pf.Sales_Employee__c);
            }
        }
        
        if (accountIds.isEmpty()) return;
        
        // Existing shares check
        Map<String, AccountShare> existingSharesMap = new Map<String, AccountShare>();
        for (AccountShare ash : [
            SELECT Id, AccountId, UserOrGroupId
            FROM AccountShare
            WHERE AccountId IN :accountIds
        ]) {
            existingSharesMap.put(ash.AccountId + '_' + ash.UserOrGroupId, ash);
        }
        
        List<AccountShare> sharesToInsert = new List<AccountShare>();
        
        for (Id accId : accountToUserMap.keySet()) {
            Id userId = accountToUserMap.get(accId);
            String key = accId + '_' + userId;
            
            if (!existingSharesMap.containsKey(key)) {
                AccountShare newShare = new AccountShare();
                newShare.AccountId = accId;
                newShare.UserOrGroupId = userId;
                newShare.AccountAccessLevel = 'Edit';
                newShare.OpportunityAccessLevel = 'None';
                newShare.CaseAccessLevel = 'None';
                newShare.RowCause = Schema.AccountShare.RowCause.Manual;
                sharesToInsert.add(newShare);
            }
        }
        
        if (!sharesToInsert.isEmpty()) {
            try {
                insert sharesToInsert;
                System.debug('Inserted ' + sharesToInsert.size() + ' AccountShare records.');
            } catch (DmlException e) {
                System.debug('Error inserting AccountShare records: ' + e.getMessage());
            }
        }
    }
    
    // ----------- BATCH FINISH -----------
    public void finish(Database.BatchableContext bc) {
        System.debug('AccountShareForPartnerFunctionBatch completed successfully.');
    }
    
    // ----------- SCHEDULABLE EXECUTE -----------
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new AccountShareForPartnerFunctionBatch(), 1);
    }
}