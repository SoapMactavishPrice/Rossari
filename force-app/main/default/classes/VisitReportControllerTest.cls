@IsTest
public class VisitReportControllerTest {
    
    @TestSetup
    static void setupTestData() {
        List<SObject> recordsToInsert = new List<SObject>();
        
        List<Account> accounts = new List<Account>();
        Account acc1 = new Account(Name = 'Test Account 1', SAP_Customer_Code__c = 'SAP001', CurrencyIsoCode = 'USD');
        Account acc2 = new Account(Name = 'Test Account 2', SAP_Customer_Code__c = 'SAP002', CurrencyIsoCode = 'EUR');
        accounts.add(acc1);
        accounts.add(acc2);
        recordsToInsert.addAll(accounts);
        
        insert recordsToInsert;
        recordsToInsert.clear();

        List<Contact> contacts = new List<Contact>();
        Contact con1 = new Contact(FirstName = 'Test', LastName = 'Contact 1', AccountId = acc1.Id, Email = 'test1@test.com', Title = 'Manager');
        Contact con2 = new Contact(FirstName = 'Test', LastName = 'Contact 2', AccountId = acc1.Id, Email = 'test2@test.com', Title = 'Director');
        contacts.add(con1);
        contacts.add(con2);
        recordsToInsert.addAll(contacts);
        
        Competitor_Master__c competitor = new Competitor_Master__c(Name = 'Test Competitor', Competitor_Code__c = 'COMP001');
        recordsToInsert.add(competitor);
        
        Tour__c tour = new Tour__c(Name = 'Test Tour', Tour_Start_Date__c = Date.today(), Tour_End_Date__c = Date.today().addDays(7));
        recordsToInsert.add(tour);
        
        Project__c project = new Project__c(Name = 'Test Project');
        recordsToInsert.add(project);
        
        insert recordsToInsert;
        recordsToInsert.clear();

        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        try{
        update standardPricebook;
         }Catch(Exception e){}

        Base_UoM_Master__c baseUom = new Base_UoM_Master__c(Name = 'Kilogram');
        recordsToInsert.add(baseUom);
 
        Product2 prod = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP001',
            Pack_Size__c = '10kg',
            Base_UOM__c = baseUom.Id,
            IsActive = true
        );
        recordsToInsert.add(prod);
        
        insert recordsToInsert;
        recordsToInsert.clear();

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        recordsToInsert.add(pbe);
        
        insert recordsToInsert;
    }
    
    @IsTest
    static void testAllMethodsInOne() {
        Account testAccount = [SELECT Id, CurrencyIsoCode FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Competitor_Master__c competitor = [SELECT Id FROM Competitor_Master__c LIMIT 1];
        Tour__c tour = [SELECT Id FROM Tour__c LIMIT 1];
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        
        Test.startTest();
        
        Contact result1 = VisitReportController.getContact(testContact.Id);
        List<Contact> result2 = VisitReportController.getContactsByAccount(testAccount.Id);
        User result3 = VisitReportController.getUser(testUser.Id);
        Map<String, String> result4 = VisitReportController.getCustomerDetails(testAccount.Id);
        Competitor_Master__c result5 = VisitReportController.getCompetitorDetails(competitor.Id);
        Competitor_Master__c result6 = VisitReportController.getCompetitorDetails(null);
        List<Tour__c> result7 = VisitReportController.getTours();
        
        List<Id> accountIds = new List<Id>{testAccount.Id};
        Tour__c result8 = VisitReportController.createTour('New Tour', Date.today(), Date.today().addDays(5), accountIds);
        Tour__c result9 = VisitReportController.createTour('Tour Without Accounts', Date.today(), Date.today().addDays(3), null);
        
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
        
        List<Map<String, Object>> productInterests = new List<Map<String, Object>>{
            new Map<String, Object>{
                'prodId' => product.Id,
                'qty' => '100',
                'Price' => '500.00',
                'ExpDate' => '2024-03-01'
            }
        };
        String productInterestsJson = JSON.serialize(productInterests);
        
        List<Map<String, Object>> actionPoints = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Name' => 'Test Action Point',
                'userId' => testUser.Id,
                'Next_Action_Date' => '2024-02-15',
                'Create_Task_Notify' => true
            }
        };
        String actionPointsJson = JSON.serialize(actionPoints);
        
        Map<String, String> result10 = VisitReportController.saveVisitReport(
            visitJson, attendeesJson, productInterestsJson, actionPointsJson,
            'Test Location', 'USD', 'Customer Visit', null
        );
        
        Test.stopTest();
    }
    
    @IsTest
    static void testAllRemainingScenarios() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Competitor_Master__c competitor = [SELECT Id FROM Competitor_Master__c LIMIT 1];
        Tour__c tour = [SELECT Id FROM Tour__c LIMIT 1];
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        
        Test.startTest();
        
        Visit_Report__c existingReport = new Visit_Report__c(
            Title_of_Meeting__c = 'Existing Meeting',
            Start_Date_Time__c = DateTime.now(),
            End_Date_Time__c = DateTime.now().addHours(1),
            Customer_Name__c = testAccount.Id,
            CurrencyIsoCode = 'USD'
        );
        insert existingReport;
        
        Map<String, Object> visitData = new Map<String, Object>{
            'Discussion_Details_from_the_Meeting' => 'Updated discussion',
            'Next_Meeting_Date_agreed_with_Customer' => '2024-03-01'
        };
        
        String visitJson = JSON.serialize(visitData);
        
        List<Map<String, Object>> attendeesList = new List<Map<String, Object>>();
        List<Map<String, Object>> productInterests = new List<Map<String, Object>>();
        List<Map<String, Object>> actionPoints = new List<Map<String, Object>>();
        
        String attendeesJson = JSON.serialize(attendeesList);
        String productInterestsJson = JSON.serialize(productInterests);
        String actionPointsJson = JSON.serialize(actionPoints);
        
        Map<String, String> result1 = VisitReportController.saveVisitReport(
            visitJson, attendeesJson, productInterestsJson, actionPointsJson,
            'Updated Location', 'USD', 'Customer Visit', existingReport.Id
        );
        
        Map<String, String> result2 = VisitReportController.saveVisitReport(
            'invalid json', '[]', '[]', '[]', 'Test Location', 'USD', 'Customer Visit', null
        );
        
        Visit_Report__c result3 = VisitReportController.getVisitReportDetails(existingReport.Id);
        
        Attendees__c attendee = new Attendees__c(
            Visit_Report__c = existingReport.Id,
            Attendee_Type__c = 'Internal Attendee',
            First_Name__c = 'Test',
            Last_Name__c = 'Attendee'
        );
        insert attendee;
        
        Product_Interest_and_Pricing_Benchmark__c productInterest = new Product_Interest_and_Pricing_Benchmark__c(
            Visit_Report__c = existingReport.Id,
            Product__c = product.Id,
            Expected_Qty_in_Kgs__c = 100
        );
        insert productInterest;
        
        Action_Point__c actionPoint = new Action_Point__c(
            Visit_Report__c = existingReport.Id,
            Name = 'Test Action Point'
        );
        insert actionPoint;
        
        Map<String, Object> result4 = VisitReportController.getVisitReportRelatedData(existingReport.Id);
        List<Attendees__c> result5 = VisitReportController.getVisitReportAttendees(existingReport.Id);
        
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            MobilePhone = '9650421782',
            Status = 'Open'
        );
        insert testLead;
        
        Map<String, Object> leadVisitData = new Map<String, Object>{
            'Visit_Report_Type' => 'Lead Visit',
            'lead_Name' => testLead.Id,
            'Customer_Type' => 'New Customer',
            'New_Customer' => 'New Customer Name',
            'Title_of_Meeting' => 'Lead Meeting',
            'Start_Date_Time' => '2024-01-01T10:00:00',
            'End_Date_Time' => '2024-01-01T11:00:00'
        };
        
        String leadVisitJson = JSON.serialize(leadVisitData);
        
        Map<String, String> result6 = VisitReportController.saveVisitReport(
            leadVisitJson, '[]', '[]', '[]', 'Test Location', 'USD', 'Lead Visit', null
        );
        
        Map<String, Object> productInterestData = new Map<String, Object>{
            'Title_of_Meeting' => 'Test Product Interest',
            'Start_Date_Time' => '2024-01-01T10:00:00',
            'End_Date_Time' => '2024-01-01T11:00:00',
            'Customer_Name' => testAccount.Id
        };
        
        String productVisitJson = JSON.serialize(productInterestData);
        
        List<Map<String, Object>> invalidProductInterests = new List<Map<String, Object>>{
            new Map<String, Object>{
                'prodId' => product.Id,
                'qty' => '0',
                'Price' => '0',
                'ExpDate' => 'invalid-date'
            }
        };
        String invalidProductInterestsJson = JSON.serialize(invalidProductInterests);
        
        Map<String, String> result7 = VisitReportController.saveVisitReport(
            productVisitJson, '[]', invalidProductInterestsJson, '[]',
            'Test Location', 'USD', 'Customer Visit', null
        );
        
        Test.stopTest();
    }
    
    @IsTest
    static void testAttendeesWithListUserObject() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        
        Test.startTest();
        
        Map<String, Object> visitData = new Map<String, Object>{
            'Title_of_Meeting' => 'Test List User Object',
            'Start_Date_Time' => '2024-01-01T10:00:00',
            'End_Date_Time' => '2024-01-01T11:00:00',
            'Customer_Name' => testAccount.Id
        };
        
        String visitJson = JSON.serialize(visitData);
        
        List<Map<String, Object>> attendeesList = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Attendee_Type__c' => 'Internal Attendee',
                'User_Type__c' => 'Existing',
                'User__c' => new List<Object>{testUser.Id}
            }
        };
        String attendeesJson = JSON.serialize(attendeesList);
        
        Map<String, String> result = VisitReportController.saveVisitReport(
            visitJson, attendeesJson, '[]', '[]',
            'Test Location', 'USD', 'Customer Visit', null
        );
        
        Test.stopTest();
    }
    
    @IsTest
    static void testAttendeesWithEmptyUserList() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        
        Test.startTest();
        
        Map<String, Object> visitData = new Map<String, Object>{
            'Title_of_Meeting' => 'Test Empty User List',
            'Start_Date_Time' => '2024-01-01T10:00:00',
            'End_Date_Time' => '2024-01-01T11:00:00',
            'Customer_Name' => testAccount.Id
        };
        
        String visitJson = JSON.serialize(visitData);
        
        List<Map<String, Object>> attendeesList = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Attendee_Type__c' => 'Internal Attendee',
                'User_Type__c' => 'Existing',
                'User__c' => new List<Object>()
            }
        };
        String attendeesJson = JSON.serialize(attendeesList);
        
        Map<String, String> result = VisitReportController.saveVisitReport(
            visitJson, attendeesJson, '[]', '[]',
            'Test Location', 'USD', 'Customer Visit', null
        );
        
        Test.stopTest();
    }
    
    @IsTest
    static void testActionPointsWithNotification() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        
        Test.startTest();
        
        Map<String, Object> visitData = new Map<String, Object>{
            'Title_of_Meeting' => 'Test Action Points Notification',
            'Start_Date_Time' => '2024-01-01T10:00:00',
            'End_Date_Time' => '2024-01-01T11:00:00',
            'Customer_Name' => testAccount.Id
        };
        
        String visitJson = JSON.serialize(visitData);
        
        List<Map<String, Object>> actionPoints = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Name' => 'Action Point with Notification',
                'userId' => testUser.Id,
                'Next_Action_Date' => '2024-02-15',
                'Create_Task_Notify' => true
            },
            new Map<String, Object>{
                'Name' => 'Action Point without Notification',
                'userId' => testUser.Id,
                'Next_Action_Date' => '2024-02-20',
                'Create_Task_Notify' => false
            }
        };
        String actionPointsJson = JSON.serialize(actionPoints);
        
        Map<String, String> result = VisitReportController.saveVisitReport(
            visitJson, '[]', '[]', actionPointsJson,
            'Test Location', 'USD', 'Customer Visit', null
        );
        
        Test.stopTest();
    }
    
    @IsTest
    static void testActionPointsWithoutRequiredFields() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        
        Test.startTest();
        
        Map<String, Object> visitData = new Map<String, Object>{
            'Title_of_Meeting' => 'Test Action Points Missing Fields',
            'Start_Date_Time' => '2024-01-01T10:00:00',
            'End_Date_Time' => '2024-01-01T11:00:00',
            'Customer_Name' => testAccount.Id
        };
        
        String visitJson = JSON.serialize(visitData);
        
        List<Map<String, Object>> actionPoints = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Name' => 'Action Point Missing User',
                'Next_Action_Date' => '2024-02-15',
                'Create_Task_Notify' => true
            },
            new Map<String, Object>{
                'Name' => 'Action Point Missing Date',
                'userId' => [SELECT Id FROM User WHERE IsActive = true LIMIT 1].Id,
                'Create_Task_Notify' => true
            }
        };
        String actionPointsJson = JSON.serialize(actionPoints);
        
        Map<String, String> result = VisitReportController.saveVisitReport(
            visitJson, '[]', '[]', actionPointsJson,
            'Test Location', 'USD', 'Customer Visit', null
        );
        
        Test.stopTest();
    }
    
    @IsTest
    static void testExistingVisitReportWithAttendees() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        
        Visit_Report__c existingReport = new Visit_Report__c(
            Title_of_Meeting__c = 'Existing Report with Attendees',
            Start_Date_Time__c = DateTime.now(),
            End_Date_Time__c = DateTime.now().addHours(1),
            Customer_Name__c = testAccount.Id,
            CurrencyIsoCode = 'USD'
        );
        insert existingReport;
        
        Attendees__c existingAttendee = new Attendees__c(
            Visit_Report__c = existingReport.Id,
            Attendee_Type__c = 'Internal Attendee',
            User_Type__c = 'Existing',
            User__c = testUser.Id
        );
        insert existingAttendee;
        
        Test.startTest();
        
        Map<String, Object> visitData = new Map<String, Object>{
            'Discussion_Details_from_the_Meeting' => 'Updated discussion for existing report',
            'Next_Meeting_Date_agreed_with_Customer' => '2024-03-01'
        };
        
        String visitJson = JSON.serialize(visitData);
        
        List<Map<String, Object>> newAttendeesList = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Attendee_Type__c' => 'External Attendee',
                'User_Type__c' => 'Existing',
                'Contact_Name__c' => testContact.Id
            }
        };
        String attendeesJson = JSON.serialize(newAttendeesList);
        
        Map<String, String> result = VisitReportController.saveVisitReport(
            visitJson, attendeesJson, '[]', '[]',
            'Updated Location', 'USD', 'Customer Visit', existingReport.Id
        );
        
        Test.stopTest();
    }
}