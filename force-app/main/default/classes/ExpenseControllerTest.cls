@isTest
public class ExpenseControllerTest {

    static User testUser;
    static Account testAccount;
    static Tour__c testTour;

    @testSetup
    static void setupData() {
        // Create test user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        testUser = new User(
            Alias = 'tuser',
            Email='tuser@test.com',
            EmailEncodingKey='UTF-8',
            LastName='Test',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            TimeZoneSidKey='Asia/Kolkata',
            UserName='tuser' + DateTime.now().getTime() + '@test.com',
            ProfileId = p.Id
        );
        insert testUser;

        // Create Account
        testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Create Tour
        testTour = new Tour__c(Name = 'Test Tour');
        insert testTour;

        // Create Expense Type
        Type_of_Expense__c toe = new Type_of_Expense__c(
            Name = 'Other',
            Type_of_Voucher__c = 'Local'
        );
        insert toe;
    }

    @isTest
    static void testInitializeExpense() {
        Test.startTest();
        Map<String, Object> result = ExpenseController.initializeExpense();
        Test.stopTest();
    }

    @isTest
    static void testGetUsers() {
        Test.startTest();
        List<Map<String, String>> users = ExpenseController.getUsers('Test');
        Test.stopTest();
    }

    @isTest
    static void testGetTypeOfExpense() {
        Test.startTest();
        List<Map<String, String>> res1 = ExpenseController.getTypeOfExpense('Travel', 'Transport');        List<Map<String, String>> res2 = ExpenseController.getTypeOfExpense(null, null);
        Test.stopTest();
    }
    
   @isTest
static void testCreateExpenseWithFiles() {
    Expense__c exp = new Expense__c(
        Type_of_Voucher__c = 'Local'
    );
    insert exp;
    
    
    List<Expense_Line_Item__c> items = new List<Expense_Line_Item__c>{
        new Expense_Line_Item__c(Reason__c = 'Test'),
        new Expense_Line_Item__c(Reason__c = 'Test 2')
    };
    
    // Insert a file (ContentVersion) – Salesforce auto-creates ContentDocument
    ContentVersion cv = new ContentVersion(
        Title = 'TestFile',
        PathOnClient = 'test.txt',
        VersionData = Blob.valueOf('test file')
    );
    insert cv;

    // Requery to get the ContentDocumentId safely
    ContentVersion insertedCV = [
        SELECT Id, ContentDocumentId 
        FROM ContentVersion 
        WHERE Id = :cv.Id
    ];
    
    // Use ContentDocumentId here
    Map<String, List<String>> filesMap = new Map<String, List<String>>();
    filesMap.put('0', new List<String>{insertedCV.ContentDocumentId});
    
    Test.startTest();
    String expId = ExpenseController.createExpenseWithFiles(exp, items, filesMap);
    Test.stopTest();
    
}




    @isTest
    static void testGetTransportModes() {
        Test.startTest();
        List<Map<String, String>> modes = ExpenseController.getTransportModes();
        Test.stopTest();
    }

    @isTest
    static void testCreateCustomerVisit_NewAndExisting() {
        
        testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Create Tour
        testTour = new Tour__c(Name = 'Test Tour');
        insert testTour;
        
        Test.startTest();
        // Case 1: New Visit
        Id visitId = ExpenseController.createCustomerVisit(testTour.Id, testAccount.Id);

        // Case 2: Existing Visit (should return same Id)
        Id visitId2 = ExpenseController.createCustomerVisit(testTour.Id, testAccount.Id);

        // Case 3: Invalid input
        try {
            ExpenseController.createCustomerVisit(null, testAccount.Id);
        } catch (AuraHandledException e) {
        }
        Test.stopTest();
    }
}