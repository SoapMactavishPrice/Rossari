public class LeadLookupController {

    @AuraEnabled(cacheable=true)
    public static List<AccountWrapper> searchAccounts(String keyword, String type) {
        String searchKey = '%' + keyword + '%';

        List<Lead> leads = [
            SELECT Id, Name, Street_1__c, Street_2__c, Street_3__c, Company, Region__c,
                   Zone__c, Pin_Code__r.Name, City__r.Name, Country__r.Name, State__r.Name
            FROM Lead
            WHERE Name LIKE :searchKey OR Company LIKE :searchKey
            LIMIT 10
        ];

        List<AccountWrapper> wrapperList = new List<AccountWrapper>();
        for (Lead lead : leads) {
            wrapperList.add(new AccountWrapper(lead, type));
        }

        return wrapperList;
    }

    public class AccountWrapper {
        @AuraEnabled public String Id;
        @AuraEnabled public String Name;
        @AuraEnabled public String sapCode;
        @AuraEnabled public String billingPinCodeName;
        @AuraEnabled public String billingCityName;
        @AuraEnabled public String billingCountryName;
        @AuraEnabled public String billingStateName;
        @AuraEnabled public String billToaddress;

        public AccountWrapper(Lead lead, String type) {
            this.Id = lead.Id;

            // Build address string
            List<String> addressParts = new List<String>();
            if (String.isNotBlank(lead.Street_1__c)) addressParts.add(lead.Street_1__c);
            if (String.isNotBlank(lead.Street_2__c)) addressParts.add(lead.Street_2__c);
            if (String.isNotBlank(lead.Street_3__c)) addressParts.add(lead.Street_3__c);
            this.billToaddress = String.join(addressParts, ', ');

            // Build display name with location info
            List<String> locationParts = new List<String>();
            if (lead.Pin_Code__r != null && String.isNotBlank(lead.Pin_Code__r.Name)) locationParts.add(lead.Pin_Code__r.Name);
            if (lead.City__r != null && String.isNotBlank(lead.City__r.Name)) locationParts.add(lead.City__r.Name);
            if (lead.Country__r != null && String.isNotBlank(lead.Country__r.Name)) locationParts.add(lead.Country__r.Name);

            this.Name = lead.Name + (locationParts.isEmpty() ? '' : ' - ' + String.join(locationParts, ', '));

            // Assign other fields
            this.sapCode = lead.Company != null ? lead.Company : '';
            this.billingPinCodeName = lead.Pin_Code__r != null ? lead.Pin_Code__r.Name : '';
            this.billingCityName = lead.City__r != null ? lead.City__r.Name : '';
            this.billingStateName = lead.State__r != null ? lead.State__r.Name : '';
            this.billingCountryName = lead.Country__r != null ? lead.Country__r.Name : '';
        }
    }
}