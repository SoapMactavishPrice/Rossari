public with sharing class CityLookupController {
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getCities(String searchTerm) {
        try {
            if (String.isBlank(searchTerm)) {
                return new List<Map<String, String>>();
            }
            
            searchTerm = '%' + String.escapeSingleQuotes(searchTerm) + '%';
            
            List<City__c> cities = [SELECT Id, Name, City_Type__c 
                                   FROM City__c 
                                   WHERE Name LIKE :searchTerm 
                                   ORDER BY Name 
                                   LIMIT 50];
            
            List<Map<String, String>> options = new List<Map<String, String>>();
            for (City__c city : cities) {
                options.add(new Map<String, String>{
                    'label' => city.Name,
                    'value' => city.Id,
                    'cityType' => city.City_Type__c != null ? city.City_Type__c : ''
                });
            }
            
            return options;
        } catch (Exception e) {
            throw new AuraHandledException('Error searching cities: ' + e.getMessage());
        }
    }
}