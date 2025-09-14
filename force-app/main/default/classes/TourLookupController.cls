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
    

    
    @AuraEnabled(cacheable=true)
    public static List<Account> getAccountsForTour(Id tourId) {
        return [
            SELECT Id, Name
            FROM Account
            WHERE Id IN (
                SELECT Account__c FROM Customer_Visited__c WHERE Tour__c = :tourId
            )
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Account> searchAccounts(String searchKey) {
        return [
            SELECT Id, Name
            FROM Account
            WHERE Name LIKE :('%' + searchKey + '%')
            LIMIT 10
        ];
    }

 @AuraEnabled
    public static Id createCustomerVisited(Id tourId, Id accountId) {
        if (tourId == null || accountId == null) {
            throw new AuraHandledException('Tour and Account are required.');
        }

        try {
            // Check if Customer_Visited__c already exists to avoid duplicates
            List<Customer_Visited__c> existingVisits = [
                SELECT Id 
                FROM Customer_Visited__c 
                WHERE Tour__c = :tourId AND Account__c = :accountId
                LIMIT 1
            ];
            
            if (!existingVisits.isEmpty()) {
                return existingVisits[0].Id;
            }

            // Get account name
            Account acc = [SELECT Id, Name FROM Account WHERE Id = :accountId LIMIT 1];

            // Create new Customer_Visited__c record
            Customer_Visited__c visit = new Customer_Visited__c();
            visit.Tour__c = tourId;
            visit.Account__c = accountId;
            visit.Name = acc.Name + ' - Visit';

            insert visit;
            return visit.Id;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error creating Customer Visit: ' + e.getMessage());
        }
    }
    
}