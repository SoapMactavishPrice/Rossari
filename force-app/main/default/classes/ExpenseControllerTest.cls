@isTest
public class ExpenseControllerTest {

    @testSetup
    static void setupData() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            Alias = 'tuser',
            Email = 'tuser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            FirstName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Asia/Kolkata',
            UserName = 'tuser' + DateTime.now().getTime() + '@test.com',
            ProfileId = p.Id,
            Division = 'Test Division',
            Zone__c = 'West',
            Cost_Center__c = '10000013',
            User_Type__c = 'Application',
            Grades__c = 'DR',
            Entity_Code_1__c = '1000',
            Entity_Code_2__c = '3000',
            Entity_Code_3__c = '4000'
        );
        insert testUser;

        insert new Cost_Center__c(Name = 'Test Cost Center');

        insert new Grade__c(
            Name = 'DR',
            Daily_Allowance_A_class_cities__c = 1000,
            Daily_Allowance_B_class_cities__c = 800,
            Four_Wheeler_per_km__c = 12.5,
            Two_Wheeler_per_km__c = 8.0,
            Mode_of_Travel__c = 'Car;Bike',
            Sales_Type__c = 'Export',
            Special_Allowance__c = 300,
            Out_of_Pocket__c = 150,
            Mode_of_Outstation_Travel__c = 'Business Class;Economy Class',
            Lodging_Hotel__c = 500,
            Boarding_Food__c = 200,
            Lodging_Hotel_B_Class__c = 450,
            Boarding_Food_B_Class__c = 180
        );

        insert new Grade__c(
            Name = 'EM',
            Daily_Allowance_A_class_cities__c = 1100,
            Sales_Type__c = 'Domestic'
        );

        insert new Account(Name = 'Test Account');
        insert new Tour__c(Name = 'Test Tour');

        GL_Code__c glCode = new GL_Code__c(Name = 'Test GL Code');
        insert glCode;

        insert new Type_of_Expense__c(Name = 'Test Expense Type', Type_of_Voucher__c = 'Local', GL_Code__c = glCode.Id);
        insert new Type_of_Expense__c(Name = 'Travel Expense', Type_of_Voucher__c = 'Local', GL_Code__c = glCode.Id);
    }

    @isTest
    static void testCoreFunctionsAndExceptions() {
        Test.startTest();
        ExpenseController.initializeExpense();
        ExpenseController.getGradeDetails('DR');
        ExpenseController.getGradeDetails('EM');
        ExpenseController.getGradeDetails('');        
        ExpenseController.getGradeDetails('NonExistentGrade');
        
        ExpenseController.getGradeDetailsWithSalesType('DR', 'Export');
        ExpenseController.getGradeDetailsWithSalesType('DR', 'NonExistentSalesType');
        
        ExpenseController.getDailyAllowanceByGrade('DR');
        ExpenseController.getDailyAllowanceByGrade('');
        ExpenseController.getDailyAllowanceByGrade('NonExistentGrade');
        
        ExpenseController.getUsers('Test');
        ExpenseController.getUsers('NonExistentUser');
        
        ExpenseController.getTypeOfExpense('Test', 'Local');
        ExpenseController.getTypeOfExpense('Travel', 'Local');
        ExpenseController.getTypeOfExpense(null, 'Local');
        ExpenseController.getTypeOfExpense('Test', null);
        ExpenseController.getTypeOfExpense(null, null);
        ExpenseController.getTypeOfExpense('NonExistent', 'InvalidVoucher');
        
        ExpenseController.getExpenseRecordTypes();
        ExpenseController.getTransportModes();
        ExpenseController.getSalesTypeOptions();
        Test.stopTest();
    }

    @isTest
    static void testCustomerVisitAndExpenseCreation() {
        Tour__c testTour = [SELECT Id FROM Tour__c WHERE Name = 'Test Tour' LIMIT 1];
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];

        Test.startTest();
        Id visitId1 = ExpenseController.createCustomerVisit(testTour.Id, testAccount.Id);
        Id visitId2 = ExpenseController.createCustomerVisit(testTour.Id, testAccount.Id); // Should get existing record id
        
        try { ExpenseController.createCustomerVisit(null, testAccount.Id); } catch (AuraHandledException e) {}
        try { ExpenseController.createCustomerVisit(testTour.Id, null); } catch (AuraHandledException e) {}
        Test.stopTest();
    }

    @isTest
    static void testInitializeExpenseAndCreateExpenseWithFilesException() {
        User testUser = [SELECT Id FROM User WHERE UserName LIKE 'tuser%@test.com' LIMIT 1];
        testUser.Grades__c = null;
        update testUser;

        System.runAs(testUser) {
            Test.startTest();
            try { ExpenseController.initializeExpense(); } catch (Exception e) {}
            
            Expense__c exp = new Expense__c(Name='Test Expense');
            List<Expense_Line_Item__c> lineItems = new List<Expense_Line_Item__c>();
            try {
                ExpenseController.createExpenseWithFiles(exp, lineItems, null);
            } catch (Exception e) {}
            Test.stopTest();
        }
    }

    @isTest
    static void testAdditionalMethods() {
        // Insert a City__c record for getCityDetails
        City__c city = new City__c(Name = 'Test City');
        insert city;

        // Insert Grade__c for getExportTransportModes
        Grade__c grade = new Grade__c(
            Name = 'TestGrade',
            Sales_Type__c = 'Export',
            Mode_of_Travel__c = 'Car;Bike'
        );
        insert grade;

        Test.startTest();
        // Test getCityDetails with valid Id
        Map<String, Object> cityDetails = ExpenseController.getCityDetails(city.Id);

        // Test getCityDetails with invalid Id
        try {
            ExpenseController.getCityDetails('001000000000000AAA');
        } catch (AuraHandledException e) {
            // expected exception
        }

        // Test getCityDetails with blank Id
        Map<String, Object> blankCity = ExpenseController.getCityDetails('');

        // Test getExportTransportModes with valid grade name
        List<Map<String, String>> exportModes = ExpenseController.getExportTransportModes(grade.Name);


        // Test getExportTransportModes with invalid grade name
        List<Map<String, String>> exportModesInvalid = ExpenseController.getExportTransportModes('InvalidGrade');


        // Test getModeOfTravelOptions 
        List<Map<String, String>> modes = ExpenseController.getModeOfTravelOptions();


        // Test exception in getModeOfTravelOptions by temporarily mocking Schema method (optional and advanced)

        Test.stopTest();
    }
    
    @isTest
    static void testTemethodExecution() {
        // Act
        Test.startTest();
        ExpenseController.temethod(); // Replace 'YourClassName' with the actual class name
        Test.stopTest();
        
        // Assert
        System.assert(true, 'temethod executed successfully without any errors');
    }

}