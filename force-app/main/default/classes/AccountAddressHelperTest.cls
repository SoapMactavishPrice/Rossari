@IsTest
private class AccountAddressHelperTest {
    @TestSetup
    static void setupTestData() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Country__c country = new Country__c(Name = 'Test Country', Region__c = 'Asia');
        insert country;

        State__c state = new State__c(Name = 'Test State', Country__c = country.Id, Zone__c = 'West');
        insert state;

        City__c city = new City__c(Name = 'Test City', State__c = state.Id);
        insert city;

        Pin_Code__c pinCode = new Pin_Code__c(Name = '123456', City__c = city.Id);
        insert pinCode;

        Id billToRecordTypeId = Schema.SObjectType.Address_Information__c
            .getRecordTypeInfosByDeveloperName().get('Bill_To').getRecordTypeId();
        Id shipToRecordTypeId = Schema.SObjectType.Address_Information__c
            .getRecordTypeInfosByDeveloperName().get('Ship_To').getRecordTypeId();

        List<Address_Information__c> addresses = new List<Address_Information__c>{
            new Address_Information__c(
                Name = 'Bill To - Test City',
                Account__c = testAccount.Id,
                RecordTypeId = billToRecordTypeId,
                Street_1__c = '123 Test St',
                City__c = city.Id,
                State__c = state.Id,
                Country__c = country.Id,
                Pin_Code__c = pinCode.Id,
                Region__c = 'Asia',
                Zone__c = 'West'
            ),
            new Address_Information__c(
                Name = 'Ship To - Test City',
                Account__c = testAccount.Id,
                RecordTypeId = shipToRecordTypeId,
                Street_1__c = '456 Test St',
                City__c = city.Id,
                State__c = state.Id,
                Country__c = country.Id,
                Pin_Code__c = pinCode.Id,
                Region__c = 'Asia',
                Zone__c = 'West'
            )
        };
        insert addresses;
    }

    @IsTest
    static void testAllMethods() {
        // Setup test data references
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Pin_Code__c pinCode = [SELECT Id FROM Pin_Code__c LIMIT 1];
        Address_Information__c address = [SELECT Id FROM Address_Information__c 
                                        WHERE RecordType.DeveloperName = 'Bill_To' LIMIT 1];
        City__c city = [SELECT Id FROM City__c LIMIT 1];

        List<Address_Information__c> addresses = AccountAddressHelper.getAddressesByAccount(testAccount.Id, 'Bill_To');

        Map<String, String> pinData = AccountAddressHelper.getAddressDataByPin(pinCode.Id);

        List<Country__c> countries = AccountAddressHelper.getCountriesByRegion('Asia');

        List<String> regions = AccountAddressHelper.getRegionOptions();

        List<String> zones = AccountAddressHelper.getZoneOptions();

        Id recordTypeId = AccountAddressHelper.getRecordTypeId('Address_Information__c', 'Bill_To');

        AccountAddressHelper.deleteAddress(address.Id);

        Map<String, Object> addressFields = new Map<String, Object>{
            'Street_1__c' => '789 Test St',
            'Street_2__c' => 'Apt 101',
            'City__c' => city.Id,
            'Account__c' => testAccount.Id
        };
        Id savedAddressId = AccountAddressHelper.saveAddress(addressFields, 'Bill_To');

        try {
            AccountAddressHelper.getAddressDataByPin(null);
        } catch (Exception e) {}

        try {
            AccountAddressHelper.saveAddress(new Map<String, Object>{'Street_2__c' => 'Apt 101'}, 'Bill_To');
        } catch (Exception e) {}

        List<Country__c> nullRegionCountries = AccountAddressHelper.getCountriesByRegion(null);
    }
}