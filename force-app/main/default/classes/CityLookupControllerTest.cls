@isTest
public class CityLookupControllerTest {

    @isTest
    static void testGetCitiesWithValidSearchTerm() {
        // Insert test City records
        List<City__c> cityList = new List<City__c>{
            new City__c(Name = 'New York', City_Type__c = 'A Class City'),
            new City__c(Name = 'Newark', City_Type__c = 'A Class City'),
            new City__c(Name = 'Newton', City_Type__c = 'B Class City')
        };
        insert cityList;

        Test.startTest();
        // Call with search term that should match inserted cities
        List<Map<String, String>> results = CityLookupController.getCities('New');
        Test.stopTest();
    }

    @isTest
    static void testGetCitiesWithEmptyAndNullSearchTerm() {
        Test.startTest();
        // Call with empty string
        List<Map<String, String>> resultsEmpty = CityLookupController.getCities('');
        // Call with null
        List<Map<String, String>> resultsNull = CityLookupController.getCities(null);
        Test.stopTest();
    }

    @isTest
    static void testGetCitiesNoResults() {
        Test.startTest();
        // Call with search term unlikely to return records
        List<Map<String, String>> results = CityLookupController.getCities('ZZZZZZZZ');
        Test.stopTest();
    }
}