public with sharing class TourLookupController {

    @AuraEnabled(cacheable=true)
    public static List<Tour__c> searchTours(String searchKey) {
        if (String.isBlank(searchKey)) {
            return new List<Tour__c>();
        }

        return [
            SELECT Id, Name
            FROM Tour__c
            WHERE Name LIKE :('%' + searchKey + '%')
            LIMIT 10
        ];
    }

    @AuraEnabled
    public static Tour__c createTour(String tourName) {
        if (String.isBlank(tourName)) {
            throw new AuraHandledException('Tour name cannot be empty');
        }
        Tour__c newTour = new Tour__c(Name = tourName);
        insert newTour;
        return newTour;
    }
}