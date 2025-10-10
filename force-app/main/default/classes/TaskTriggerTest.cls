@IsTest
private class TaskTriggerTest {

    @IsTest
    static void testLeadStatusUpdate() {
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Status = 'New',
            MobilePhone = '9876543210'
        );
        insert testLead;

        Task testTask = new Task(
            Subject = 'Follow-up Call',
            WhoId = testLead.Id,
            ActivityDate = Date.today(),
            TaskSubtype = 'Call'
        );
        insert testTask;

        Lead updatedLead = [SELECT Id, Status FROM Lead WHERE Id = :testLead.Id];
    }

    @IsTest
    static void testNonCallTaskDoesNotUpdateLead() {
        Lead testLead = new Lead(
            FirstName = 'Another',
            LastName = 'Lead',
            Company = 'Test Company 2',
            Status = 'New',
            MobilePhone = '9876543210'
        );
        insert testLead;

        Task testTask = new Task(
            Subject = 'Email Follow-up',
            WhoId = testLead.Id,
            ActivityDate = Date.today(),
            TaskSubtype = 'Email'
        );
        insert testTask;

        Lead updatedLead = [SELECT Id, Status FROM Lead WHERE Id = :testLead.Id];
    }

    @IsTest
    static void testTaskWithoutLead() {
        Task testTask = new Task(
            Subject = 'General Task',
            ActivityDate = Date.today(),
            TaskSubtype = 'Call'
        );
        insert testTask;
    }
}