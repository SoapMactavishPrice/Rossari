@isTest
public class TourLookupControllerTest {
    @isTest
    static void testAllMethods() {
        Tour__c tour = new Tour__c(Name = 'Test Tour');
        insert tour;

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Customer_Visited__c visit = new Customer_Visited__c(
            Tour__c = tour.Id,
            Account__c = acc.Id,
            Name = acc.Name + ' - Visit'
        );
        insert visit;

        TourLookupController.searchTours('Test');
        TourLookupController.searchTours('');

        TourLookupController.createTour('New Tour');

        TourLookupController.getAccountsForTour(tour.Id);

        TourLookupController.searchAccounts('Test');

        TourLookupController.createCustomerVisited(tour.Id, acc.Id);

        Account acc2 = new Account(Name = 'Another Account');
        insert acc2;

        TourLookupController.createCustomerVisited(tour.Id, acc2.Id);
    }
}