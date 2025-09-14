@isTest
private class VisitReportControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create Country, State, City, Pin Code
        Country__c india = new Country__c(Name = 'India');
        insert india;

        State__c state = new State__c(Name = 'Test State', Country__c = india.Id);
        insert state;

        City__c city = new City__c(Name = 'Test City', State__c = state.Id);
        insert city;

        Pin_Code__c pinCode = new Pin_Code__c(Name = '123456', City__c = city.Id);
        insert pinCode;

        // Get a RecordType for Account
        RecordType customerRecordType = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Account' AND IsActive = true LIMIT 1];

        // Create Account
        Account acc = new Account(
            Name = 'Test Account',
            SAP_Customer_Code__c = 'SAP123',
            RecordTypeId = customerRecordType.Id
        );
        insert acc;

        // Create Contact
        Contact con = new Contact(
            FirstName = 'Test', 
            LastName = 'Contact', 
            AccountId = acc.Id,
            Email = 'test.contact@example.com',
            Title = 'Manager'
        );
        insert con;

        // Create Lead
        Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Pin_Code__c = pinCode.Id,
            Business_Type__c = 'Domestic',
            MobilePhone = '9999888898'
        );
        insert lead;

        // Create Competitor
        Competitor_Master__c competitor = new Competitor_Master__c(
            Name = 'Test Competitor',
            Competitor_Code__c = 'COMP001'
        );
        insert competitor;

        // Create Product
        Product2 prod = new Product2(
            Name = 'Test Product', 
            IsActive = true
        );
        insert prod;

        // Create Tour
        Tour__c tour = new Tour__c(
            Name = 'Test Tour',
            Tour_Start_Date__c = Date.today(),
            Tour_End_Date__c = Date.today().addDays(7)
        );
        insert tour;
    }

    @isTest
    static void testGetContact() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        Test.startTest();
        Contact result = VisitReportController.getContact(testContact.Id);
        Test.stopTest();
        
        System.assertEquals(testContact.Id, result.Id, 'Should return the correct contact');
    }

    @isTest
    static void testGetContactsByAccount() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        List<Contact> contacts = VisitReportController.getContactsByAccount(testAccount.Id);
        Test.stopTest();
        
        System.assert(!contacts.isEmpty(), 'Should return contacts for the account');
    }

    @isTest
    static void testGetUser() {
        Test.startTest();
        User result = VisitReportController.getUser(UserInfo.getUserId());
        Test.stopTest();
        
        System.assertEquals(UserInfo.getUserId(), result.Id, 'Should return the correct user');
    }

    @isTest
    static void testSaveVisitReport_Success() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Lead lead = [SELECT Id FROM Lead LIMIT 1];
        Competitor_Master__c competitor = [SELECT Id FROM Competitor_Master__c LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        Tour__c tour = [SELECT Id FROM Tour__c LIMIT 1];
        
        // Use valid picklist values: "Tour" or "Stakeholder Visit" instead of "Virtual"
        String visitJson = '{"Visit_Report_Type":"Type","lead_Name":"' + lead.Id +
            '","Customer_Name":"' + con.Id +
            '","Competition_Name":"' + competitor.Id +
            '","Title_of_Meeting":"Test Meeting","End_Date_Time":"2024-01-01T10:00:00",' +
            '"Start_Date_Time":"2024-01-01T09:00:00","Mode":"Tour","Category":"Sales",' +
            '"Nature":"Business","Discussion_Details_from_the_Meeting":"Test discussion",' +
            '"Next_Meeting_Date_agreed_with_Customer":"2024-01-15","tourId":"' + tour.Id +
            '","Reason":"Test reason","Seminar":"Test Seminar"}';

        String productInterest = '[{"prodId":"' + prod.Id + '","qty":"100","ExpDate":"2024-01-15","Price":"50"}]';
        String actionPoint = '[{"Name":"Follow up","userId":"' + UserInfo.getUserId() + '","Next_Action_Date":"2024-01-15","Create_Task_Notify":true}]';
        String attendees = '[{"Attendee_Type__c":"Internal Attendee","User_Type__c":"Existing","User__c":"' + UserInfo.getUserId() + '"}]';

        Test.startTest();
        Map<String, String> result = VisitReportController.saveVisitReport(
            visitJson, attendees, productInterest, actionPoint, 'Test Location', 'USD', 'Visit'
        );
        Test.stopTest();
        
        // Don't add assertion as requested
    }

    @isTest
    static void testSaveVisitReport_WithExternalAttendee() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Lead lead = [SELECT Id FROM Lead LIMIT 1];
        Competitor_Master__c competitor = [SELECT Id FROM Competitor_Master__c LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        Tour__c tour = [SELECT Id FROM Tour__c LIMIT 1];
        
        String visitJson = '{"Visit_Report_Type":"Type","lead_Name":"' + lead.Id +
            '","Customer_Name":"' + con.Id +
            '","Competition_Name":"' + competitor.Id +
            '","Title_of_Meeting":"Test Meeting","End_Date_Time":"2024-01-01T10:00:00",' +
            '"Start_Date_Time":"2024-01-01T09:00:00","Mode":"Stakeholder Visit","Category":"Sales",' +
            '"Nature":"Business","Discussion_Details_from_the_Meeting":"Test discussion",' +
            '"Next_Meeting_Date_agreed_with_Customer":"2024-01-15","tourId":"' + tour.Id +
            '","Reason":"Test reason","Seminar":"Test Seminar"}';

        String productInterest = '[{"prodId":"' + prod.Id + '","qty":"100","ExpDate":"2024-01-15","Price":"50"}]';
        String actionPoint = '[{"Name":"Follow up","userId":"' + UserInfo.getUserId() + '","Next_Action_Date":"2024-01-15","Create_Task_Notify":true}]';
        
        // Test with external attendee
        String attendees = '[{"Attendee_Type__c":"External Attendee","User_Type__c":"Existing","Contact_Name__c":"' + con.Id + 
            '","First_Name__c":"External","Last_Name__c":"Attendee","Email__c":"external@test.com","Designation__c":"Manager"}]';

        Test.startTest();
        Map<String, String> result = VisitReportController.saveVisitReport(
            visitJson, attendees, productInterest, actionPoint, 'Test Location', 'USD', 'Visit'
        );
        Test.stopTest();
        
        // Don't add assertion as requested
    }

    @isTest
    static void testSaveVisitReport_WithNewAttendees() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Lead lead = [SELECT Id FROM Lead LIMIT 1];
        Competitor_Master__c competitor = [SELECT Id FROM Competitor_Master__c LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        Tour__c tour = [SELECT Id FROM Tour__c LIMIT 1];
        
        String visitJson = '{"Visit_Report_Type":"Type","lead_Name":"' + lead.Id +
            '","Customer_Name":"' + con.Id +
            '","Competition_Name":"' + competitor.Id +
            '","Title_of_Meeting":"Test Meeting","End_Date_Time":"2024-01-01T10:00:00",' +
            '"Start_Date_Time":"2024-01-01T09:00:00","Mode":"Tour","Category":"Sales",' +
            '"Nature":"Business","Discussion_Details_from_the_Meeting":"Test discussion",' +
            '"Next_Meeting_Date_agreed_with_Customer":"2024-01-15","tourId":"' + tour.Id +
            '","Reason":"Test reason","Seminar":"Test Seminar"}';

        String productInterest = '[{"prodId":"' + prod.Id + '","qty":"100","ExpDate":"2024-01-15","Price":"50"}]';
        String actionPoint = '[{"Name":"Follow up","userId":"' + UserInfo.getUserId() + '","Next_Action_Date":"2024-01-15","Create_Task_Notify":true}]';
        
        // Test with new internal and external attendees
        String attendees = '[' +
            '{"Attendee_Type__c":"Internal Attendee","User_Type__c":"New","First_Name__c":"New","Last_Name__c":"Internal"},' +
            '{"Attendee_Type__c":"External Attendee","User_Type__c":"New","First_Name__c":"New","Last_Name__c":"External","Email__c":"new@test.com","Designation__c":"Director"}' +
        ']';

        Test.startTest();
        Map<String, String> result = VisitReportController.saveVisitReport(
            visitJson, attendees, productInterest, actionPoint, 'Test Location', 'USD', 'Visit'
        );
        Test.stopTest();
        
        // Don't add assertion as requested
    }

    @isTest
    static void testSaveVisitReport_WithEmptyData() {
        Test.startTest();
        Map<String, String> result = VisitReportController.saveVisitReport(
            '{}', '[]', '[]', '[]', null, 'USD', 'Visit'
        );
        Test.stopTest();
        
        // Don't add assertion as requested
    }

    @isTest
    static void testSaveVisitReport_WithInvalidData() {
        Test.startTest();
        Map<String, String> result = VisitReportController.saveVisitReport(
            'invalid', 'invalid', 'invalid', 'invalid', null, 'USD', 'Visit'
        );
        Test.stopTest();
        
        // Don't add assertion as requested
    }

    @isTest
    static void testGetCustomerDetails() {
        Account testAccount = [SELECT Id, SAP_Customer_Code__c, RecordTypeId FROM Account LIMIT 1];
        RecordType rt = [SELECT Id, DeveloperName FROM RecordType WHERE Id = :testAccount.RecordTypeId];
        
        Test.startTest();
        Map<String, String> result = VisitReportController.getCustomerDetails(testAccount.Id);
        Test.stopTest();
        
        System.assertEquals('SAP123', result.get('SAP_Customer_Code__c'), 'Should return SAP code');
        System.assertEquals(rt.DeveloperName, result.get('RecordType'), 'Should return record type');
    }

    @isTest
    static void testGetCustomerDetails_Null() {
        Test.startTest();
        Map<String, String> result = VisitReportController.getCustomerDetails(null);
        Test.stopTest();
        
        System.assert(result.isEmpty(), 'Should return empty map for null input');
    }

    @isTest
    static void testGetCompetitorDetails() {
        Competitor_Master__c competitor = [SELECT Id FROM Competitor_Master__c LIMIT 1];
        
        Test.startTest();
        Competitor_Master__c result = VisitReportController.getCompetitorDetails(competitor.Id);
        Test.stopTest();
        
        System.assertEquals(competitor.Id, result.Id, 'Should return the correct competitor');
    }

    @isTest
    static void testGetCompetitorDetails_Null() {
        Test.startTest();
        Competitor_Master__c result = VisitReportController.getCompetitorDetails(null);
        Test.stopTest();
        
        System.assertEquals(null, result, 'Should return null for null input');
    }

    @isTest
    static void testGetTours() {
        Test.startTest();
        List<Tour__c> tours = VisitReportController.getTours();
        Test.stopTest();
        
        System.assert(!tours.isEmpty(), 'Should return tours');
    }

    @isTest
    static void testCreateTour() {
        Test.startTest();
        Tour__c result = VisitReportController.createTour('New Test Tour', Date.today(), Date.today().addDays(5));
        Test.stopTest();
        
        System.assertEquals('New Test Tour', result.Name, 'Should create tour with correct name');
        System.assert(result.Id != null, 'Should have an ID after creation');
    }

    @isTest
    static void testSaveVisitReport_WithProjectId() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Lead lead = [SELECT Id FROM Lead LIMIT 1];
        Competitor_Master__c competitor = [SELECT Id FROM Competitor_Master__c LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        Tour__c tour = [SELECT Id FROM Tour__c LIMIT 1];
        
        // Create a project (using Account as project for testing)
        Account project = new Account(Name = 'Test Project');
        insert project;
        
        String visitJson = '{"Visit_Report_Type":"Type","lead_Name":"' + lead.Id +
            '","Customer_Name":"' + con.Id +
            '","Competition_Name":"' + competitor.Id +
            '","Title_of_Meeting":"Test Meeting","End_Date_Time":"2024-01-01T10:00:00",' +
            '"Start_Date_Time":"2024-01-01T09:00:00","Mode":"Stakeholder Visit","Category":"Sales",' +
            '"Nature":"Business","Discussion_Details_from_the_Meeting":"Test discussion",' +
            '"Next_Meeting_Date_agreed_with_Customer":"2024-01-15","tourId":"' + tour.Id +
            '","ProjectId":"' + project.Id + '","Reason":"Test reason","Seminar":"Test Seminar"}';

        String productInterest = '[{"prodId":"' + prod.Id + '","qty":"100","ExpDate":"2024-01-15","Price":"50"}]';
        String actionPoint = '[{"Name":"Follow up","userId":"' + UserInfo.getUserId() + '","Next_Action_Date":"2024-01-15","Create_Task_Notify":true}]';
        String attendees = '[{"Attendee_Type__c":"Internal Attendee","User_Type__c":"Existing","User__c":"' + UserInfo.getUserId() + '"}]';

        Test.startTest();
        Map<String, String> result = VisitReportController.saveVisitReport(
            visitJson, attendees, productInterest, actionPoint, 'Test Location', 'USD', 'Visit'
        );
        Test.stopTest();
        
        // Don't add assertion as requested
    }

    @isTest
    static void testSaveVisitReport_WithEmptyProductInterest() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Lead lead = [SELECT Id FROM Lead LIMIT 1];
        Competitor_Master__c competitor = [SELECT Id FROM Competitor_Master__c LIMIT 1];
        Tour__c tour = [SELECT Id FROM Tour__c LIMIT 1];
        
        String visitJson = '{"Visit_Report_Type":"Type","lead_Name":"' + lead.Id +
            '","Customer_Name":"' + con.Id +
            '","Competition_Name":"' + competitor.Id +
            '","Title_of_Meeting":"Test Meeting","End_Date_Time":"2024-01-01T10:00:00",' +
            '"Start_Date_Time":"2024-01-01T09:00:00","Mode":"Tour","Category":"Sales",' +
            '"Nature":"Business","Discussion_Details_from_the_Meeting":"Test discussion",' +
            '"Next_Meeting_Date_agreed_with_Customer":"2024-01-15","tourId":"' + tour.Id +
            '","Reason":"Test reason","Seminar":"Test Seminar"}';

        String productInterest = '[{"prodId":"","qty":"0","ExpDate":"","Price":"-10"}]';
        String actionPoint = '[{"Name":"Follow up","userId":"' + UserInfo.getUserId() + '","Next_Action_Date":"2024-01-15","Create_Task_Notify":true}]';
        String attendees = '[{"Attendee_Type__c":"Internal Attendee","User_Type__c":"Existing","User__c":"' + UserInfo.getUserId() + '"}]';

        Test.startTest();
        Map<String, String> result = VisitReportController.saveVisitReport(
            visitJson, attendees, productInterest, actionPoint, 'Test Location', 'USD', 'Visit'
        );
        Test.stopTest();
        
        // Don't add assertion as requested
    }

    @isTest
    static void testSaveVisitReport_WithEmptyActionPoint() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Lead lead = [SELECT Id FROM Lead LIMIT 1];
        Competitor_Master__c competitor = [SELECT Id FROM Competitor_Master__c LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        Tour__c tour = [SELECT Id FROM Tour__c LIMIT 1];
        
        String visitJson = '{"Visit_Report_Type":"Type","lead_Name":"' + lead.Id +
            '","Customer_Name":"' + con.Id +
            '","Competition_Name":"' + competitor.Id +
            '","Title_of_Meeting":"Test Meeting","End_Date_Time":"2024-01-01T10:00:00",' +
            '"Start_Date_Time":"2024-01-01T09:00:00","Mode":"Stakeholder Visit","Category":"Sales",' +
            '"Nature":"Business","Discussion_Details_from_the_Meeting":"Test discussion",' +
            '"Next_Meeting_Date_agreed_with_Customer":"2024-01-15","tourId":"' + tour.Id +
            '","Reason":"Test reason","Seminar":"Test Seminar"}';

        String productInterest = '[{"prodId":"' + prod.Id + '","qty":"100","ExpDate":"2024-01-15","Price":"50"}]';
        String actionPoint = '[{"Name":"","userId":"","Next_Action_Date":"","Create_Task_Notify":false}]';
        String attendees = '[{"Attendee_Type__c":"Internal Attendee","User_Type__c":"Existing","User__c":"' + UserInfo.getUserId() + '"}]';

        Test.startTest();
        Map<String, String> result = VisitReportController.saveVisitReport(
            visitJson, attendees, productInterest, actionPoint, 'Test Location', 'USD', 'Visit'
        );
        Test.stopTest();
        
       
    }
}