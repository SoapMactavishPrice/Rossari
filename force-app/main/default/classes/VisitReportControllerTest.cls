@isTest
private class VisitReportControllerTest {
    @isTest
    static void testAllVisitReportControllerLogic() {
        // Setup related master data
        Country__c india = new Country__c(Name = 'India');
        insert india;

        State__c state = new State__c(Name = 'Test State', Country__c = india.Id);
        insert state;

        City__c city = new City__c(Name = 'Test City', State__c = state.Id);
        insert city;

        Pin_Code__c pinCode = new Pin_Code__c(Name = '123456', City__c = city.Id);
        insert pinCode;

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = acc.Id);
        insert con;

        Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Pin_Code__c = pinCode.Id,
            Business_Type__c = 'Domestic',
            MobilePhone = '9999888898'
        );
        insert lead;

        Competitor_Master__c competitor = new Competitor_Master__c(Name = 'Test Competitor');
        insert competitor;

        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;

        Tour__c tour = new Tour__c(Name = 'Test Tour');
        insert tour;

        Visit_Report__c visit = new Visit_Report__c(Title_of_Meeting__c = 'Test');
        insert visit;

        // Insert CustomNotificationType for notification logic
        CustomNotificationType cnt = new CustomNotificationType(
            DeveloperName = 'Action_Point_Alert',
            MasterLabel = 'Action Point Alert'
        );

        // Valid JSON for visit
        String visitJson = '{"Visit_Report_Type":"Type","lead_Name":"' + lead.Id +
            '","Customer_Name":"' + con.Id +
            '","Competition_Name":"' + competitor.Id +
            '","Title_of_Meeting":"Meeting","End_Date_Time":"2024-01-01T10:00:00",' +
            '"Start_Date_Time":"2024-01-01T09:00:00","Mode":"Virtual","Category":"Sales",' +
            '"Nature":"Business","Discussion_Details_from_the_Meeting":"Discussion",' +
            '"Next_Meeting_Date_agreed_with_Customer":"2024-01-15","tourId":"' + tour.Id +
            '","Reason":"Some reason","Seminar":"Some Seminar"}';

        // Valid Product Interest JSON
        String productInterest = '[{"prodId":"' + prod.Id + '","qty":"100","ExpDate":"2024-01-15","Price":"50", "vrc":"' + visit.Id + '"}]';

        // Valid Action Point JSON
        String actionPoint = '[{"Name":"Follow up","userId":"' + UserInfo.getUserId() + '","Next_Action_Date":"2024-01-15","Create_Task_Notify":true}]';

        // Edge case: incomplete product interest
        String incompleteProductInterest = '[{"prodId":"","qty":"0","ExpDate":"","Price":"-10"}]';

        // Edge case: incomplete action point
        String incompleteActionPoint = '[{"Name":"","userId":"","Next_Action_Date":"","Create_Task_Notify":false}]';

        Test.startTest();
        VisitReportController.saveVisitReport(visitJson, productInterest, actionPoint, 'Location', 'USD', 'Visit');
        VisitReportController.saveVisitReport(visitJson, incompleteProductInterest, actionPoint, 'Location', 'USD', 'Visit');
        VisitReportController.saveVisitReport(visitJson, productInterest, incompleteActionPoint, 'Location', 'USD', 'Visit');
        VisitReportController.saveVisitReport('{}', '[]', '[]', null, 'USD', 'Visit');
        VisitReportController.saveVisitReport('invalid', 'invalid', 'invalid', null, 'USD', 'Visit');
        VisitReportController.getContact(con.Id);
        VisitReportController.getCustomerDetails(acc.Id);
        VisitReportController.getCustomerDetails(null);
        VisitReportController.getCompetitorDetails(competitor.Id);
        VisitReportController.getCompetitorDetails(null);
        VisitReportController.getTours();
        VisitReportController.createTour('Another Test Tour');
        Test.stopTest();

        // Assertions
    }
}