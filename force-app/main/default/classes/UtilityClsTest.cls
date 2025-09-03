@isTest
private class UtilityClsTest {
    @isTest
    static void testAllMethods() {
        Map<String, String> picklistResult = UtilityCls.picklistValues('Account', 'Industry');
        
        RecordType rt = [SELECT Id, DeveloperName, SObjectType FROM RecordType LIMIT 1];
        Id recordTypeResult = UtilityCls.getRecordTypeId(rt.SObjectType, rt.DeveloperName);
        
        String currencyResult = UtilityCls.getCorporateCurrencyType();
        List<String> currencyListResult = UtilityCls.getCurrencyTypeList();
        
        String countryResult1 = UtilityCls.getCountryName('US');
        String countryResult2 = UtilityCls.getCountryName('XX');
        String countryResult3 = UtilityCls.getCountryName(null);
        
        try {
            Map<String, String> invalidPicklist = UtilityCls.picklistValues('InvalidObject', 'Field');
        } catch (Exception e) {
        }
        
        Id invalidRecordType = UtilityCls.getRecordTypeId('InvalidObject', 'Test');
    }
}