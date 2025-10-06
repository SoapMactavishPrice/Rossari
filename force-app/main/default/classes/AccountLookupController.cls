public with sharing class AccountLookupController {

    @AuraEnabled(cacheable=true)
    public static List<AccountWrapper> searchAccounts(String keyword, String type) {
        String searchKey = '%' + String.escapeSingleQuotes(keyword) + '%';
        
        List<Account> accounts = [
            SELECT Id, Name, SAP_Customer_Code__c, BillingCity, BillingCountry,CurrencyIsoCode
            FROM Account 
            WHERE (Name LIKE :searchKey OR SAP_Customer_Code__c LIKE :searchKey)
            ORDER BY Name 
            LIMIT 50
        ];

        List<AccountWrapper> accountWrapperList = new List<AccountWrapper>();
        for (Account acc : accounts) {
            accountWrapperList.add(new AccountWrapper(acc));
        }

        return accountWrapperList;
    }

    public class AccountWrapper {
        @AuraEnabled public String Id;
        @AuraEnabled public String Name;
        @AuraEnabled public String sapCode;
        @AuraEnabled public String BillingCity;
        @AuraEnabled public String BillingCountry;
        @AuraEnabled public String CurrencyIsoCode;

        public AccountWrapper(Account acc) {
            this.Id = acc.Id;
            this.Name = acc.Name;
            this.sapCode = acc.SAP_Customer_Code__c != null ? String.valueOf(acc.SAP_Customer_Code__c) : '';
            this.BillingCity = acc.BillingCity;
            this.BillingCountry = acc.BillingCountry;
            this.CurrencyIsoCode = acc.CurrencyIsoCode;
        }
    }
}