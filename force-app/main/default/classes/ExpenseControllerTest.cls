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
    static void testAllMethodsInOne() {
        // Setup additional data
        City__c city = new City__c(Name = 'Test City');
        insert city;

        Grade__c grade = new Grade__c(
            Name = 'TestGrade',
            Sales_Type__c = 'Export',
            Mode_of_Travel__c = 'Car;Bike'
        );
        insert grade;

        User testUser = [SELECT Id FROM User WHERE UserName LIKE 'tuser%@test.com' LIMIT 1];
        Tour__c testTour = [SELECT Id FROM Tour__c WHERE Name = 'Test Tour' LIMIT 1];
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        // Create test expense records
        Expense__c localExpense = new Expense__c(
            Name = 'Local Test Expense',
            Employee_Name__c = testUser.Id,
            Type_of_Voucher__c = 'Local',
            Date__c = Date.today()
        );
        insert localExpense;
        
        Expense__c outstationExpense = new Expense__c(
            Name = 'Outstation Test Expense',
            Employee_Name__c = testUser.Id,
            Type_of_Voucher__c = 'Outstation',
            Date__c = Date.today()
        );
        insert outstationExpense;
        
        // Create line items
        Expense_Line_Item__c dailyAllowanceItem = new Expense_Line_Item__c(
            Expense__c = localExpense.Id,
            Daily_Allowance__c = 100,
            Date__c = Date.today()
        );
        insert dailyAllowanceItem;
        
        Expense_Line_Item__c outOfPocketItem = new Expense_Line_Item__c(
            Expense__c = outstationExpense.Id,
            Daily_Allowance__c = 200,
            Date__c = Date.today()
        );
        insert outOfPocketItem;

        // Create another test user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser2 = new User(
            Alias = 'tuser2',
            Email = 'tuser2@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test2',
            FirstName = 'User2',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Asia/Kolkata',
            UserName = 'tuser2' + DateTime.now().getTime() + '@test.com',
            ProfileId = p.Id
        );
        insert testUser2;

        // Create Expense for team members test
        Expense__c expense = new Expense__c(Name = 'Test Expense');
        insert expense;

        // Create user without grade
        User userWithoutGrade = new User(
            FirstName = 'NoGrade',
            LastName = 'User',
            Email = 'nograde@example.com',
            Username = 'nograde' + DateTime.now().getTime() + '@example.com',
            Alias = 'ngusr',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert userWithoutGrade;

        // Create Grade for combined allowances tests
        Grade__c grade1 = new Grade__c(
            Name = 'Grade1',
            Sales_Type__c = 'Domestic',
            Lodging_Hotel__c = 5000,
            Lodging_Hotel_B_Class__c = 3000,
            Boarding_Food__c = 1500,
            Boarding_Food_B_Class__c = 1000
        );
        insert grade1;

        Grade__c grade2 = new Grade__c(
            Name = 'Grade2',
            Sales_Type__c = 'Domestic',
            Lodging_Hotel__c = 5000,
            Lodging_Hotel_B_Class__c = 3000,
            Boarding_Food__c = 1500,
            Boarding_Food_B_Class__c = 1000
        );
        insert grade2;

        // Create test users with grades for combined allowances
        List<User> users = new List<User>();
        for (Integer i = 0; i < 2; i++) {
            users.add(new User(
                FirstName = 'Test',
                LastName = 'User' + i,
                Email = 'testuser' + i + '@example.com',
                Username = 'testuserassa21' + i + DateTime.now().getTime() + '@example.com',
                Alias = 'tusr' + i,
                TimeZoneSidKey = 'Asia/Kolkata',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = p.Id,
                Grades__c = 'DR'
            ));
        }
        insert users;

        Test.startTest();
        
        // Test Core Functions and Exceptions
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
        
        // Test Customer Visit and Expense Creation
        Id visitId1 = ExpenseController.createCustomerVisit(testTour.Id, testAccount.Id);
        Id visitId2 = ExpenseController.createCustomerVisit(testTour.Id, testAccount.Id);
        
        try { ExpenseController.createCustomerVisit(null, testAccount.Id); } catch (AuraHandledException e) {}
        try { ExpenseController.createCustomerVisit(testTour.Id, null); } catch (AuraHandledException e) {}
        
        // Test Initialize Expense and Create Expense With Files Exception
        testUser.Grades__c = null;
        update testUser;
        
        System.runAs(testUser) {
            try { ExpenseController.initializeExpense(); } catch (Exception e) {}
            
            Expense__c exp = new Expense__c(Name='Test Expense');
            List<Expense_Line_Item__c> lineItems = new List<Expense_Line_Item__c>();
            try {
                ExpenseController.createExpenseWithFiles(exp, lineItems, null);
            } catch (Exception e) {}
        }
        
        // Test Additional Methods
        Map<String, Object> cityDetails = ExpenseController.getCityDetails(city.Id);
        try {
            ExpenseController.getCityDetails('001000000000000AAA');
        } catch (AuraHandledException e) {}
        Map<String, Object> blankCity = ExpenseController.getCityDetails('');
        List<Map<String, String>> exportModes = ExpenseController.getExportTransportModes(grade.Name);
        List<Map<String, String>> exportModesInvalid = ExpenseController.getExportTransportModes('InvalidGrade');
        List<Map<String, String>> modes = ExpenseController.getModeOfTravelOptions();
        
        // Test Eligible For Both (placeholder)
        String todayStr = String.valueOf(Date.today());
        // Map<String, Object> result = ExpenseController.checkAllowanceEligibility(todayStr, testUser.Id);
        
        // Test Create Expense Team Members
        List<Expense_Team_Member__c> teamMembers = new List<Expense_Team_Member__c>{
            new Expense_Team_Member__c(Expense__c = expense.Id, Attendee__c = testUser.Id),
            new Expense_Team_Member__c(Expense__c = expense.Id, Attendee__c = testUser.Id)
        };
        List<Expense_Team_Member__c> insertedMembers = ExpenseController.createExpenseTeamMembers(teamMembers);
        List<Expense_Team_Member__c> resultEmpty = ExpenseController.createExpenseTeamMembers(new List<Expense_Team_Member__c>());
        
        // Test Get Combined Allowances
        Decimal allowance1 = ExpenseController.getCombinedAllowances(
            users[0].Id,
            new List<String>{users[1].Id},
            'A Class City',
            'Domestic',
            'Hotel'
        );
        
        Decimal allowance2 = ExpenseController.getCombinedAllowances(
            users[0].Id,
            null,
            'B Class City',
            'Domestic',
            'Food'
        );
        
        Decimal allowance3 = ExpenseController.getCombinedAllowances(
            null,
            null,
            'A Class City',
            'Retail',
            'Hotel'
        );
        
        Decimal allowance4 = ExpenseController.getCombinedAllowances(
            userWithoutGrade.Id,
            null,
            'A Class City',
            'Retail',
            'Hotel'
        );
        
        // Test Check Allowance Eligibility For Date
        Map<String, Object> result1 = ExpenseController.checkAllowanceEligibilityForDate(
            String.valueOf(Date.today().addDays(1)),
            testUser.Id,
            null,
            null
        );
        
        Map<String, Object> result2 = ExpenseController.checkAllowanceEligibilityForDate(
            String.valueOf(Date.today()),
            testUser.Id,
            null,
            null
        );
        
        Map<String, Object> result3 = ExpenseController.checkAllowanceEligibilityForDate(
            String.valueOf(Date.today()),
            testUser.Id,
            dailyAllowanceItem.Id,
            null
        );
        
        List<Map<String, Object>> currentPageItems = new List<Map<String, Object>>();
        currentPageItems.add(new Map<String, Object>{
            'id' => 'tempId1',
            'date' => String.valueOf(Date.today()),
            'voucherType' => 'Local',
            'dailyAllowance' => 100,
            'userId' => testUser.Id
        });
        
        Map<String, Object> result4 = ExpenseController.checkAllowanceEligibilityForDate(
            String.valueOf(Date.today()),
            testUser.Id,
            null,
            currentPageItems
        );
        
        Map<String, Object> result5 = ExpenseController.checkAllowanceEligibilityForDate(
            null,
            null,
            null,
            null
        );
        
        Map<String, Object> result6 = ExpenseController.checkAllowanceEligibilityForDate(
            '',
            testUser.Id,
            null,
            null
        );
        
        try {
            Map<String, Object> result7 = ExpenseController.checkAllowanceEligibilityForDate(
                'invalid-date',
                testUser.Id,
                null,
                null
            );
        } catch (Exception e) {}
        
        // Test Check Multiple Dates Allowance Eligibility
        Map<String, String> dateUserIdMap = new Map<String, String>();
        dateUserIdMap.put(Date.today() + '_' + testUser.Id, 'value1');
        dateUserIdMap.put(Date.today().addDays(1) + '_' + testUser.Id, 'value2');
        dateUserIdMap.put(Date.today() + '_' + testUser2.Id, 'value3');
        dateUserIdMap.put(Date.today().addDays(2) + '_' + testUser2.Id, 'value4');
        
        Map<String, Map<String, Object>> multiResult1 = ExpenseController.checkMultipleDatesAllowanceEligibility(
            dateUserIdMap,
            null
        );
        
        List<Map<String, Object>> currentPageItems2 = new List<Map<String, Object>>();
        currentPageItems2.add(new Map<String, Object>{
            'id' => 'tempId1',
            'date' => String.valueOf(Date.today().addDays(1)),
            'voucherType' => 'Outstation',
            'dailyAllowance' => 200,
            'userId' => testUser.Id
        });
        currentPageItems2.add(new Map<String, Object>{
            'id' => 'tempId2',
            'outstationDate' => String.valueOf(Date.today().addDays(2)),
            'voucherType' => 'Local',
            'dailyAllowance' => 150,
            'userId' => testUser2.Id
        });
        
        Map<String, Map<String, Object>> multiResult2 = ExpenseController.checkMultipleDatesAllowanceEligibility(
            dateUserIdMap,
            currentPageItems2
        );
        
        Map<String, Map<String, Object>> multiResult3 = ExpenseController.checkMultipleDatesAllowanceEligibility(
            new Map<String, String>(),
            null
        );
        
        Map<String, String> invalidMap = new Map<String, String>();
        invalidMap.put('invalid_key', 'value');
        
        try {
            Map<String, Map<String, Object>> multiResult4 = ExpenseController.checkMultipleDatesAllowanceEligibility(
                invalidMap,
                null
            );
        } catch (Exception e) {}
        
        try {
            Map<String, Map<String, Object>> multiResult5 = ExpenseController.checkMultipleDatesAllowanceEligibility(
                null,
                null
            );
        } catch (Exception e) {}
        
        Map<String, Map<String, Object>> multiResult6 = ExpenseController.checkMultipleDatesAllowanceEligibility(
            dateUserIdMap,
            new List<Map<String, Object>>()
        );
        
        Test.stopTest();
    }
}