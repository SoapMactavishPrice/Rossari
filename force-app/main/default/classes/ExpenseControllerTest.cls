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
            Mode_of_Travel__c = 'Car'
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
        ExpenseController.getGradeDetails('');
        ExpenseController.getGradeDetails('NonExistentGrade');
        ExpenseController.getDailyAllowanceByGrade('DR');
        ExpenseController.getDailyAllowanceByGrade('');
        ExpenseController.getDailyAllowanceByGrade('NonExistentGrade');
        ExpenseController.getUsers('Test');
        ExpenseController.getUsers('NonExistentUser');
        ExpenseController.getTypeOfExpense('Test', 'Local');
        ExpenseController.getTypeOfExpense('Travel', 'Transport');
        ExpenseController.getTypeOfExpense(null, 'Local');
        ExpenseController.getTypeOfExpense('Test', null);
        ExpenseController.getTypeOfExpense(null, null);
        ExpenseController.getTypeOfExpense('NonExistent', 'InvalidVoucher');
        ExpenseController.getExpenseRecordTypes();
        ExpenseController.getTransportModes();
        ExpenseController.getSalesTypeOptions();
        ExpenseController.getTypeOfExpense('\' OR Name LIKE \'%', 'Invalid');
        ExpenseController.getGradeDetails('InvalidGrade');
        Test.stopTest();
    }

    @isTest
    static void testCustomerVisitAndExpenseCreation() {
        Tour__c testTour = [SELECT Id FROM Tour__c WHERE Name = 'Test Tour' LIMIT 1];
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];

        Test.startTest();
        ExpenseController.createCustomerVisit(testTour.Id, testAccount.Id);
        ExpenseController.createCustomerVisit(testTour.Id, testAccount.Id);
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
            try {
                Expense__c invalidExp = new Expense__c();
                List<Expense_Line_Item__c> invalidItems = new List<Expense_Line_Item__c>();
                ExpenseController.createExpenseWithFiles(invalidExp, invalidItems, null);
            } catch (Exception e) {}
            Test.stopTest();
        }
    }
}