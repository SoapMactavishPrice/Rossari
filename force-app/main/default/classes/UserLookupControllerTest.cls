@isTest
public class UserLookupControllerTest {

    @isTest
    static void testGetUsers() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User activeUser = new User(
            FirstName = 'Active',
            LastName = 'User',
            Email = 'activeuser@test.com',
            Username = 'activeuser@test.com.' + System.currentTimeMillis(),
            Alias = 'actusr',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            IsActive = true
        );
        insert activeUser;

        User inactiveUser = new User(
            FirstName = 'Inactive',
            LastName = 'User',
            Email = 'inactiveuser@test.com',
            Username = 'inactiveuser@test.com.' + System.currentTimeMillis(),
            Alias = 'inactusr',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            IsActive = false
        );
        insert inactiveUser;

        Test.startTest();
        List<User> users = UserLookupController.getUsers();
        Test.stopTest();

    }
}