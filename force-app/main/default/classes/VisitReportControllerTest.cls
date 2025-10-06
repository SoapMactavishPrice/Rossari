@isTest
public class VisitReportControllerTest {
    
    @isTest
    static void testGetMethods() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test@example.com',
            Title = 'Manager',
            AccountId = acc.Id
        );
        insert con;

        User u = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        Test.startTest();
        Contact resultCon = VisitReportController.getContact(con.Id);
        List<Contact> contactList = VisitReportController.getContactsByAccount(acc.Id);
        User resultUser = VisitReportController.getUser(u.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testSaveVisitReport() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test@example.com',
            AccountId = acc.Id
        );
        insert con;

        User u = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        String visitJson = '{'
            + '"Visit_Report_Type":"Type1",'
            + '"lead_Name":"' + u.Id + '",'
            + '"Customer_Name":"' + con.Id + '",'
            + '"Title_of_Meeting":"Test Meeting",'
            + '"Start_Date_Time":"' + Datetime.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss') + '",'
            + '"End_Date_Time":"' + Datetime.now().addHours(1).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss') + '",'
            + '"Mode":"Online",'
            + '"Category":"Category1",'
            + '"Nature":"Nature1",'
            + '"Discussion_Details_from_the_Meeting":"Details",'
            + '"Next_Meeting_Date_agreed_with_Customer":"' + Date.today().addDays(5).format() + '",'
            + '"Reason":"Reason1",'
            + '"Seminar":"Seminar1"'
            + '}';

        String attendeesJson = '[{' 
            + '"Attendee_Type__c":"Internal Attendee",'
            + '"User_Type__c":"Existing",'
            + '"User__c":"' + u.Id + '"'
            + '}]';

        String productInterestJson = '[{' 
            + '"prodId":"' + createTestProduct().Id + '",'
            + '"qty":"10",'
            + '"ExpDate":"' + Date.today().addDays(30).format() + '",'
            + '"Price":"100.5"'
            + '}]';

        String actionPointJson = '[{' 
            + '"Name":"Action1",'
            + '"userId":"' + u.Id + '",'
            + '"Next_Action_Date":"' + Date.today().addDays(10).format() + '",'
            + '"Create_Task_Notify":true'
            + '}]';

        Test.startTest();
        Map<String, String> result = VisitReportController.saveVisitReport(
            visitJson,
            attendeesJson,
            productInterestJson,
            actionPointJson,
            'Test Location',
            'USD',
            'TypeA',
            null
        );
        Test.stopTest();
        
        System.assertEquals('Success', result.get('Message'));
        System.assertNotEquals(null, result.get('Id'));
    }

    private static Product2 createTestProduct() {
        Product2 p = new Product2(Name = 'Test Product', ProductCode = 'TP123', IsActive = true);
        insert p;
        return p;
    }
}