public class AccountLookupController {

    @AuraEnabled(cacheable=true)
    public static List<AccountWrapper> searchAccounts(String keyword, String type) {
        String searchKey = '%' + keyword + '%';

        List<Account> accounts = [
            SELECT Id, Name, SAP_Customer_Code__c, Street1__c,
                   Postal_Code__r.Name, City__r.Name, Country__r.Name
            FROM Account
            WHERE Name LIKE :searchKey
            LIMIT 10
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
        @AuraEnabled public String billingPinCodeName;
        @AuraEnabled public String billingCityName;
        @AuraEnabled public String billingCountryName;

        public AccountWrapper(Account acc) {
            this.Id = acc.Id;
            this.Name = acc.Name;

            // Convert Decimal to String safely
            this.sapCode = acc.SAP_Customer_Code__c != null ? String.valueOf(acc.SAP_Customer_Code__c) : '';

            // Safely access related fields
            this.billingPinCodeName = acc.Postal_Code__r != null ? acc.Postal_Code__r.Name : '';
            this.billingCityName = acc.City__r != null ? acc.City__r.Name : '';
            this.billingCountryName = acc.Country__r != null ? acc.Country__r.Name : '';
        }
    }
}