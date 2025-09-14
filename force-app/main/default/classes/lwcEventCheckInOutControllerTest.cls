@isTest
public class lwcEventCheckInOutControllerTest {
    @isTest
    static void testAllMethods() {
        Event ev = new Event(
            Subject = 'Test Event',
            StartDateTime = System.now().addHours(1),
            EndDateTime = System.now().addHours(2)
        );
        insert ev;

        String resultCheckIn = lwcEventCheckInOutController.updateCheckIn(ev.Id, 12.34, 56.78);
        Event updatedEvent1 = [SELECT Id, Check_In_Time__c FROM Event WHERE Id = :ev.Id];
        String resultCheckInAgain = lwcEventCheckInOutController.updateCheckIn(ev.Id, 12.34, 56.78);

        String resultEventRecord = lwcEventCheckInOutController.updateEventRecord(ev.Id, 10.0, 20.0);

        String resultCheckOut = lwcEventCheckInOutController.updateCheckOut(
            ev.Id,
            30.0,
            40.0,
            'Completed',
            'Visit Description',
            'Client Feedback',
            'Next Steps',
            Date.today()
        );

        Event fetchedEvent = lwcEventCheckInOutController.getEventById(ev.Id);

        Map<String, Object> formData = new Map<String, Object>();
        formData.put('Subject', 'Updated Event Subject');
        Event updatedEvent2 = lwcEventCheckInOutController.updateEventById(ev.Id, formData);
    }
}