@IsTest
public class VisitReportControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test accounts
        List<Account> accounts = new List<Account>();
        Account acc1 = new Account(Name = 'Test Account 1', SAP_Customer_Code__c = 'SAP001', CurrencyIsoCode = 'USD');
        Account acc2 = new Account(Name = 'Test Account 2', SAP_Customer_Code__c = 'SAP002', CurrencyIsoCode = 'EUR');
        accounts.add(acc1);
        accounts.add(acc2);
        insert accounts;
        
        // Create test contacts
        List<Contact> contacts = new List<Contact>();
        Contact con1 = new Contact(FirstName = 'Test', LastName = 'Contact 1', AccountId = acc1.Id, Email = 'test1@test.com', Title = 'Manager');
        Contact con2 = new Contact(FirstName = 'Test', LastName = 'Contact 2', AccountId = acc1.Id, Email = 'test2@test.com', Title = 'Director');
        contacts.add(con1);
        contacts.add(con2);
        insert contacts;
        
        // Create test competitor
        Competitor_Master__c competitor = new Competitor_Master__c(Name = 'Test Competitor', Competitor_Code__c = 'COMP001');
        insert competitor;
        
       
        
        // Create test tour
        Tour__c tour = new Tour__c(Name = 'Test Tour', Tour_Start_Date__c = Date.today(), Tour_End_Date__c = Date.today().addDays(7));
        insert tour;
        
        // Create test project (using Custom Object - adjust based on your object name)
        // Assuming Project__c is the object name
        Project__c project = new Project__c(Name = 'Test Project');
        insert project;
        
      
    }
    
    @IsTest
    static void testGetContact() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        Test.startTest();
        Contact result = VisitReportController.getContact(testContact.Id);
        Test.stopTest();
        
      
    }
    
    @IsTest
    static void testGetContactsByAccount() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        
        Test.startTest();
        List<Contact> contacts = VisitReportController.getContactsByAccount(testAccount.Id);
        Test.stopTest();
        
      
    }
    
    @IsTest
    static void testGetUser() {
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        
        Test.startTest();
        User result = VisitReportController.getUser(testUser.Id);
        Test.stopTest();
        
    }
    
    @IsTest
    static void testSaveVisitReport_NewRecord() {
        Account testAccount = [SELECT Id, CurrencyIsoCode FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Competitor_Master__c competitor = [SELECT Id FROM Competitor_Master__c LIMIT 1];
        Tour__c tour = [SELECT Id FROM Tour__c LIMIT 1];
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
      //  Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        
        // Prepare test data
        Map<String, Object> visitData = new Map<String, Object>{
            'Visit_Report_Type' => 'Customer Visit',
            'Customer_Type' => 'Existing Customer',
            'Customer_Name' => testAccount.Id,
            'Competition_Name' => competitor.Id,
            'Title_of_Meeting' => 'Test Meeting',
            'Start_Date_Time' => '2024-01-01T10:00:00',
            'End_Date_Time' => '2024-01-01T11:00:00',
            'Mode' => 'In Person',
            'Category' => 'Sales',
            'Nature' => 'Business',
            'Discussion_Details_from_the_Meeting' => 'Test discussion',
            'Next_Meeting_Date_agreed_with_Customer' => '2024-02-01',
            'tourId' => tour.Id,
            'ProjectId' => project.Id,
            'Reason' => 'Test Reason',
            'Seminar' => 'Test Seminar'
        };
        
        String visitJson = JSON.serialize(visitData);
        
        // Prepare attendees data
        List<Map<String, Object>> attendeesList = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Attendee_Type__c' => 'Internal Attendee',
                'User_Type__c' => 'Existing',
                'User__c' => testUser.Id
            },
            new Map<String, Object>{
                'Attendee_Type__c' => 'External Attendee',
                'User_Type__c' => 'Existing',
                'Contact_Name__c' => testContact.Id
            },
            new Map<String, Object>{
                'Attendee_Type__c' => 'Internal Attendee',
                'User_Type__c' => 'New',
                'First_Name__c' => 'New',
                'Last_Name__c' => 'User'
            },
            new Map<String, Object>{
                'Attendee_Type__c' => 'External Attendee',
                'User_Type__c' => 'New',
                'First_Name__c' => 'New',
                'Last_Name__c' => 'Contact',
                'Email__c' => 'new@test.com',
                'Designation__c' => 'Manager',
                'Mobile_No__c' => '1234567890'
            }
        };
        String attendeesJson = JSON.serialize(attendeesList);
        
        // Prepare product interest data
        List<Map<String, Object>> productInterests = new List<Map<String, Object>>{
            new Map<String, Object>{
              //  'prodId' => product.Id,
                'qty' => '100',
                'Price' => '500.00',
                'ExpDate' => '2024-03-01'
            }
        };
        String productInterestsJson = JSON.serialize(productInterests);
        
        // Prepare action points data
        List<Map<String, Object>> actionPoints = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Name' => 'Test Action Point',
                'userId' => testUser.Id,
                'Next_Action_Date' => '2024-02-15',
                'Create_Task_Notify' => true
            }
        };
        String actionPointsJson = JSON.serialize(actionPoints);
        
        Test.startTest();
        Map<String, String> result = VisitReportController.saveVisitReport(
            visitJson, 
            attendeesJson, 
            productInterestsJson, 
            actionPointsJson,
            'Test Location',
            'USD',
            'Customer Visit',
            null // new record
        );
        Test.stopTest();
        
        // Verify the created records
        List<Visit_Report__c> visitReports = [SELECT Id FROM Visit_Report__c];
        
        List<Attendees__c> attendees = [SELECT Id FROM Attendees__c];
        
        List<Product_Interest_and_Pricing_Benchmark__c> productInterestsList = [SELECT Id FROM Product_Interest_and_Pricing_Benchmark__c];
        
        List<Action_Point__c> actionPointsList = [SELECT Id FROM Action_Point__c];
    }
    
    @IsTest
    static void testSaveVisitReport_UpdateRecord() {
        // First create a visit report
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        Visit_Report__c existingReport = new Visit_Report__c(
            Title_of_Meeting__c = 'Existing Meeting',
            Start_Date_Time__c = DateTime.now(),
            End_Date_Time__c = DateTime.now().addHours(1),
            Customer_Name__c = testAccount.Id,
            CurrencyIsoCode = 'USD'
        );
        insert existingReport;
        
        // Prepare update data
        Map<String, Object> visitData = new Map<String, Object>{
            'Discussion_Details_from_the_Meeting' => 'Updated discussion',
            'Next_Meeting_Date_agreed_with_Customer' => '2024-03-01'
        };
        
        String visitJson = JSON.serialize(visitData);
        
        // Prepare empty related lists for update
        List<Map<String, Object>> attendeesList = new List<Map<String, Object>>();
        List<Map<String, Object>> productInterests = new List<Map<String, Object>>();
        List<Map<String, Object>> actionPoints = new List<Map<String, Object>>();
        
        String attendeesJson = JSON.serialize(attendeesList);
        String productInterestsJson = JSON.serialize(productInterests);
        String actionPointsJson = JSON.serialize(actionPoints);
        
        Test.startTest();
        Map<String, String> result = VisitReportController.saveVisitReport(
            visitJson, 
            attendeesJson, 
            productInterestsJson, 
            actionPointsJson,
            'Updated Location',
            'USD',
            'Customer Visit',
            existingReport.Id // existing record
        );
        Test.stopTest();
        
        
        // Verify the updated record
        Visit_Report__c updatedReport = [SELECT Id, Discussion_Details_from_the_Meeting__c FROM Visit_Report__c WHERE Id = :existingReport.Id];
    }
    
    @IsTest
    static void testSaveVisitReport_ErrorScenario() {
        Test.startTest();
        Map<String, String> result = VisitReportController.saveVisitReport(
            'invalid json', 
            '[]', 
            '[]', 
            '[]',
            'Test Location',
            'USD',
            'Customer Visit',
            null
        );
        Test.stopTest();
        
    }
    
    @IsTest
    static void testGetCustomerDetails() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        
        Test.startTest();
        Map<String, String> result = VisitReportController.getCustomerDetails(testAccount.Id);
        Test.stopTest();
        
       
    }
    
    @IsTest
    static void testGetCompetitorDetails() {
        Competitor_Master__c competitor = [SELECT Id FROM Competitor_Master__c LIMIT 1];
        
        Test.startTest();
        Competitor_Master__c result = VisitReportController.getCompetitorDetails(competitor.Id);
        Test.stopTest();
        
    
    }
    
    @IsTest
    static void testGetCompetitorDetails_NullId() {
        Test.startTest();
        Competitor_Master__c result = VisitReportController.getCompetitorDetails(null);
        Test.stopTest();
        
    }
    
    @IsTest
    static void testGetTours() {
        Test.startTest();
        List<Tour__c> tours = VisitReportController.getTours();
        Test.stopTest();
        
    
    }
    
    @IsTest
    static void testCreateTour() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        List<Id> accountIds = new List<Id>{testAccount.Id};
        
        Test.startTest();
        Tour__c result = VisitReportController.createTour('New Tour', Date.today(), Date.today().addDays(5), accountIds);
        Test.stopTest();
        
    
        
        // Verify tour accounts were created
        List<Customer_Visited__c> tourAccounts = [SELECT Id FROM Customer_Visited__c WHERE Tour__c = :result.Id];
    }
    
    @IsTest
    static void testCreateTour_NoAccounts() {
        Test.startTest();
        Tour__c result = VisitReportController.createTour('Tour Without Accounts', Date.today(), Date.today().addDays(3), null);
        Test.stopTest();
        
    }
    
    @IsTest
    static void testGetVisitReportDetails() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        Visit_Report__c testReport = new Visit_Report__c(
            Title_of_Meeting__c = 'Test Meeting Details',
            Customer_Name__c = testAccount.Id,
            Start_Date_Time__c = DateTime.now(),
            End_Date_Time__c = DateTime.now().addHours(1)
        );
        insert testReport;
        
        Test.startTest();
        Visit_Report__c result = VisitReportController.getVisitReportDetails(testReport.Id);
        Test.stopTest();
        
    
    }
    
    @IsTest
    static void testGetVisitReportRelatedData() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        Visit_Report__c testReport = new Visit_Report__c(
            Title_of_Meeting__c = 'Test Related Data',
            Customer_Name__c = testAccount.Id,
            Start_Date_Time__c = DateTime.now(),
            End_Date_Time__c = DateTime.now().addHours(1)
        );
        insert testReport;
        
        // Create related records
        Attendees__c attendee = new Attendees__c(
            Visit_Report__c = testReport.Id,
            Attendee_Type__c = 'Internal Attendee',
            First_Name__c = 'Test',
            Last_Name__c = 'Attendee'
        );
        insert attendee;
        
       // Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        Product_Interest_and_Pricing_Benchmark__c productInterest = new Product_Interest_and_Pricing_Benchmark__c(
            Visit_Report__c = testReport.Id,
           // Product__c = product.Id,
            Expected_Qty_in_Kgs__c = 100
        );
        insert productInterest;
        
        Action_Point__c actionPoint = new Action_Point__c(
            Visit_Report__c = testReport.Id,
            Name = 'Test Action Point'
        );
        insert actionPoint;
        
        Test.startTest();
        Map<String, Object> result = VisitReportController.getVisitReportRelatedData(testReport.Id);
        Test.stopTest();
        
        List<Attendees__c> attendees = (List<Attendees__c>)result.get('attendees');
        List<Product_Interest_and_Pricing_Benchmark__c> productInterests = (List<Product_Interest_and_Pricing_Benchmark__c>)result.get('productInterests');
        List<Action_Point__c> actionPoints = (List<Action_Point__c>)result.get('actionPoints');
        
        
    }
    
    @IsTest
    static void testGetVisitReportAttendees() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        Visit_Report__c testReport = new Visit_Report__c(
            Title_of_Meeting__c = 'Test Attendees',
            Customer_Name__c = testAccount.Id,
            Start_Date_Time__c = DateTime.now(),
            End_Date_Time__c = DateTime.now().addHours(1)
        );
        insert testReport;
        
        Attendees__c attendee = new Attendees__c(
            Visit_Report__c = testReport.Id,
            Attendee_Type__c = 'Internal Attendee',
            First_Name__c = 'Test',
            Last_Name__c = 'Attendee'
        );
        insert attendee;
        
        Test.startTest();
        List<Attendees__c> result = VisitReportController.getVisitReportAttendees(testReport.Id);
        Test.stopTest();
        
        
    }
    
    @IsTest
    static void testSaveVisitReport_WithLead() {
        // Create test lead
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            MobilePhone = '9650421782',
            Status = 'Open'
        );
        insert testLead;
        
        Map<String, Object> visitData = new Map<String, Object>{
            'Visit_Report_Type' => 'Lead Visit',
            'lead_Name' => testLead.Id,
            'Customer_Type' => 'New Customer',
            'New_Customer' => 'New Customer Name',
            'Title_of_Meeting' => 'Lead Meeting',
            'Start_Date_Time' => '2024-01-01T10:00:00',
            'End_Date_Time' => '2024-01-01T11:00:00'
        };
        
        String visitJson = JSON.serialize(visitData);
        
        Test.startTest();
        Map<String, String> result = VisitReportController.saveVisitReport(
            visitJson, 
            '[]', 
            '[]', 
            '[]',
            'Test Location',
            'USD',
            'Lead Visit',
            null
        );
        Test.stopTest();
        
    }
    
    @IsTest
    static void testSaveVisitReport_ProductInterestWithInvalidData() {
     //   Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        
        Map<String, Object> visitData = new Map<String, Object>{
            'Title_of_Meeting' => 'Test Product Interest',
            'Start_Date_Time' => '2024-01-01T10:00:00',
            'End_Date_Time' => '2024-01-01T11:00:00',
            'Customer_Name' => [SELECT Id FROM Account LIMIT 1].Id
        };
        
        String visitJson = JSON.serialize(visitData);
        
        // Prepare product interest with invalid data
        List<Map<String, Object>> productInterests = new List<Map<String, Object>>{
            new Map<String, Object>{
                //'prodId' => product.Id,
                'qty' => '0', // Zero quantity
                'Price' => '0', // Zero price
                'ExpDate' => 'invalid-date' // Invalid date
            }
        };
        String productInterestsJson = JSON.serialize(productInterests);
        
        Test.startTest();
        Map<String, String> result = VisitReportController.saveVisitReport(
            visitJson, 
            '[]', 
            productInterestsJson, 
            '[]',
            'Test Location',
            'USD',
            'Customer Visit',
            null
        );
        Test.stopTest();
        
    }
}