@isTest
private class ExpenseTriggerHandlerTest {

    private static User createTestUser(String costCenterValue) {
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tuser',
            Email = 'testuser' + Math.round(Math.random() * 10000) + '@example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US',
            Sales_Type_Code1__c = '10',
            Cost_Center__c = costCenterValue
        );
        insert u;
        return u;
    }

    private static Cost_Center__c createCostCenter(String name, String salesOrgName) {
        Sales_Organisation__c salesOrg = new Sales_Organisation__c(Name = salesOrgName);
        insert salesOrg;
        
        Cost_Center__c cc = new Cost_Center__c(Name = name, Sales_Org__c = salesOrg.Id); 
        insert cc;
        return cc;
    }

    private static Company__c createCompany(String companyName) {
        Company__c comp = new Company__c(Name = companyName);
        insert comp;
        return comp;
    }

    private static Code_Master__c createCodeMaster(String companyName, String salesType, String backendSequence) {
        Company__c comp = createCompany(companyName);
        Code_Master__c cm = new Code_Master__c(
            Sales_Type__c = salesType,
            Company__c = comp.Id,
            Current_Sequence__c = 1,
            IsActive__c = true
        );
        insert cm;
        return cm;
    }

    @isTest
    static void testAllMethodsInOne() {
        Cost_Center__c cc1 = createCostCenter('10000013', '1000');
        Cost_Center__c cc2 = createCostCenter('10000014', '3000');
        Cost_Center__c cc3 = createCostCenter('10000015', '4000');
        
        User u1 = createTestUser('10000013');
        User u2 = createTestUser('10000014');
        User u3 = createTestUser('10000015');
        User u4 = createTestUser(null);

        Code_Master__c cm1 = createCodeMaster('Rossari Biotech Limited', '10', 'EXP-001');
        Code_Master__c cm2 = createCodeMaster('Unitop Chemicals Private Limited', '20', 'EXP-002');
        Code_Master__c cm3 = createCodeMaster('Tristar Intermediates Private Limited', '10', 'EXP-003');

        System.runAs(u1) {
            Test.startTest();

            List<Expense__c> expenses1 = new List<Expense__c>();
            expenses1.add(new Expense__c(Sales_Type__c = 'Domestic'));
            expenses1.add(new Expense__c(Sales_Type__c = 'Domestic'));
            ExpenseTriggerHandler.populateExpenseName(expenses1);

            List<Expense__c> expenses2 = new List<Expense__c>();
            expenses2.add(new Expense__c(Sales_Type__c = 'Export'));
            ExpenseTriggerHandler.populateExpenseName(expenses2);

            List<Expense__c> expenses3 = new List<Expense__c>();
            expenses3.add(new Expense__c(Sales_Type__c = null));
            ExpenseTriggerHandler.populateExpenseName(expenses3);

            List<Expense__c> expenses4 = new List<Expense__c>();
            expenses4.add(new Expense__c(Sales_Type__c = 'Domestic'));
            expenses4.add(new Expense__c(Sales_Type__c = 'Export'));
            ExpenseTriggerHandler.populateExpenseName(expenses4);

            String companyName1 = ExpenseTriggerHandler.getCompanyNameFromSalesOrgName('Rossari');
            String companyName2 = ExpenseTriggerHandler.getCompanyNameFromSalesOrgName('1000');
            String companyName3 = ExpenseTriggerHandler.getCompanyNameFromSalesOrgName('RBL');
            String companyName4 = ExpenseTriggerHandler.getCompanyNameFromSalesOrgName('Unitop');
            String companyName5 = ExpenseTriggerHandler.getCompanyNameFromSalesOrgName('3000');
            String companyName6 = ExpenseTriggerHandler.getCompanyNameFromSalesOrgName('Tristar');
            String companyName7 = ExpenseTriggerHandler.getCompanyNameFromSalesOrgName('4000');
            String companyName8 = ExpenseTriggerHandler.getCompanyNameFromSalesOrgName('Invalid');
            String companyName9 = ExpenseTriggerHandler.getCompanyNameFromSalesOrgName(null);

            String salesTypeCode1 = ExpenseTriggerHandler.getSalesTypeCode('Domestic');
            String salesTypeCode2 = ExpenseTriggerHandler.getSalesTypeCode('Export');
            String salesTypeCode3 = ExpenseTriggerHandler.getSalesTypeCode('Invalid');
            String salesTypeCode4 = ExpenseTriggerHandler.getSalesTypeCode(null);

            Test.stopTest();
        }
    }

    @isTest
    static void testAllRemainingScenarios() {
        Cost_Center__c cc = createCostCenter('10000013', '1000');
        User u = createTestUser('10000013');
        User uNoCostCenter = createTestUser(null);

        System.runAs(u) {
            Test.startTest();

            List<Expense__c> expenses1 = new List<Expense__c>();
            ExpenseTriggerHandler.populateExpenseName(expenses1);

            List<Expense__c> expenses2 = new List<Expense__c>();
            expenses2.add(new Expense__c(Sales_Type__c = 'Domestic'));
            ExpenseTriggerHandler.populateExpenseName(expenses2);

            List<Expense__c> expenses3 = new List<Expense__c>();
            expenses3.add(new Expense__c(Sales_Type__c = 'Domestic'));
            expenses3.add(new Expense__c(Sales_Type__c = 'Domestic'));
            expenses3.add(new Expense__c(Sales_Type__c = 'Export'));
            expenses3.add(new Expense__c(Sales_Type__c = 'Export'));
            ExpenseTriggerHandler.populateExpenseName(expenses3);

            Expense__c expOld = new Expense__c(Status__c = 'Draft', OwnerId = u.Id);
            insert expOld;

            Expense__c expNew = new Expense__c(Id = expOld.Id, Status__c = 'Submitted', OwnerId = u.Id);

            Map<Id, Expense__c> oldMap = new Map<Id, Expense__c>{expOld.Id => expOld};
            List<Expense__c> newList = new List<Expense__c>{expNew};

            ExpenseTriggerHandler.statusChangeToSubmitted(newList, oldMap);

            Expense__c expOld2 = new Expense__c(Status__c = 'Submitted', OwnerId = u.Id);
            insert expOld2;

            Expense__c expNew2 = new Expense__c(Id = expOld2.Id, Status__c = 'Draft', OwnerId = u.Id);

            Map<Id, Expense__c> oldMap2 = new Map<Id, Expense__c>{expOld2.Id => expOld2};
            List<Expense__c> newList2 = new List<Expense__c>{expNew2};

            ExpenseTriggerHandler.statusChangeToSubmitted(newList2, oldMap2);

            Test.stopTest();
        }

        System.runAs(uNoCostCenter) {
            List<Expense__c> expensesNoCostCenter = new List<Expense__c>();
            expensesNoCostCenter.add(new Expense__c(Sales_Type__c = 'Domestic'));
            ExpenseTriggerHandler.populateExpenseName(expensesNoCostCenter);
        }
    }

    @isTest
    static void testCodeMasterNotFoundScenarios() {
        Cost_Center__c cc = createCostCenter('10000013', '1000');
        User u = createTestUser('10000013');

        System.runAs(u) {
            Test.startTest();

            List<Expense__c> expenses1 = new List<Expense__c>();
            expenses1.add(new Expense__c(Sales_Type__c = 'Domestic'));
            ExpenseTriggerHandler.populateExpenseName(expenses1);

            List<Expense__c> expenses2 = new List<Expense__c>();
            expenses2.add(new Expense__c(Sales_Type__c = 'Export'));
            ExpenseTriggerHandler.populateExpenseName(expenses2);

            Test.stopTest();
        }
    }

    @isTest
    static void testMultipleCompaniesAndSalesTypes() {
        Cost_Center__c cc1 = createCostCenter('10000013', '1000');
        Cost_Center__c cc2 = createCostCenter('11300036', '3000');
        Cost_Center__c cc3 = createCostCenter('12400031', '4000');
        
        User u1 = createTestUser('10000013');
        User u2 = createTestUser('11300036');
        User u3 = createTestUser('12400031');

        Code_Master__c cm1 = createCodeMaster('Rossari Biotech Limited', '10', 'RBL-EXP-001');
        Code_Master__c cm2 = createCodeMaster('Rossari Biotech Limited', '20', 'RBL-EXP-002');
        Code_Master__c cm3 = createCodeMaster('Unitop Chemicals Private Limited', '10', 'UNITOP-EXP-001');
        Code_Master__c cm4 = createCodeMaster('Tristar Intermediates Private Limited', '20', 'TRI-EXP-001');

        System.runAs(u1) {
            Test.startTest();

            List<Expense__c> expenses = new List<Expense__c>();
            expenses.add(new Expense__c(Sales_Type__c = 'Domestic'));
            expenses.add(new Expense__c(Sales_Type__c = 'Export'));
            expenses.add(new Expense__c(Sales_Type__c = 'Domestic'));
            expenses.add(new Expense__c(Sales_Type__c = 'Export'));
            ExpenseTriggerHandler.populateExpenseName(expenses);

            Test.stopTest();
        }

        System.runAs(u2) {
            List<Expense__c> expensesUnitop = new List<Expense__c>();
            expensesUnitop.add(new Expense__c(Sales_Type__c = 'Domestic'));
            ExpenseTriggerHandler.populateExpenseName(expensesUnitop);
        }

        System.runAs(u3) {
            List<Expense__c> expensesTristar = new List<Expense__c>();
            expensesTristar.add(new Expense__c(Sales_Type__c = 'Export'));
            ExpenseTriggerHandler.populateExpenseName(expensesTristar);
        }
    }

    @isTest
    static void testInvalidSalesOrgScenarios() {
        Cost_Center__c cc = createCostCenter('10000013', 'InvalidSalesOrg');
        User u = createTestUser('10000013');

        System.runAs(u) {
            Test.startTest();

            List<Expense__c> expenses = new List<Expense__c>();
            expenses.add(new Expense__c(Sales_Type__c = 'Domestic'));
            ExpenseTriggerHandler.populateExpenseName(expenses);

            Test.stopTest();
        }
    }

    @isTest
    static void testEmptyExpenseList() {
        Cost_Center__c cc = createCostCenter('10000013', '1000');
        User u = createTestUser('10000013');

        System.runAs(u) {
            Test.startTest();

            List<Expense__c> emptyExpenses = new List<Expense__c>();
            ExpenseTriggerHandler.populateExpenseName(emptyExpenses);

            Test.stopTest();
        }
    }
}