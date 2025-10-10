@IsTest
public class VisitReportLookupControllerTest {

    @IsTest
    static void testSearchVisitReports() {

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tuser',
            Email = 'testuser@example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            CommunityNickname = 'tuser',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;

        System.runAs(testUser) {

            List<Visit_Report__c> reports = new List<Visit_Report__c>();
            reports.add(new Visit_Report__c(Title_of_Meeting__c = 'Sales Discussion', Start_Date_Time__c = System.now().addDays(-10)));
            reports.add(new Visit_Report__c(Title_of_Meeting__c = 'Product Launch', Start_Date_Time__c = System.now().addDays(-5)));
            reports.add(new Visit_Report__c(Title_of_Meeting__c = 'Strategy Meeting', Start_Date_Time__c = System.now().addDays(-1)));
            insert reports;

            Test.startTest();

            List<Visit_Report__c> resultWithoutSearch = VisitReportLookupController.searchVisitReports('');

            List<Visit_Report__c> resultWithTitleSearch = VisitReportLookupController.searchVisitReports('Strategy');

            List<Visit_Report__c> resultNoMatch = VisitReportLookupController.searchVisitReports('Nonexistent');

            Test.stopTest();
        }
    }
}