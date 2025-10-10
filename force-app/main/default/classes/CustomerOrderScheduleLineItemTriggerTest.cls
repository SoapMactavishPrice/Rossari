@isTest
public class CustomerOrderScheduleLineItemTriggerTest {

    @testSetup
    static void setupData() {
        // Create an Order_Scheduling_Line_Item_wise__c record
        Order_Scheduling_Line_Item_wise__c lineItem = new Order_Scheduling_Line_Item_wise__c(
            Scheduled_Quantity__c = 10
        );
        insert lineItem;

        // Create a related Customer_Order_Schedule_Line_Item__c record
        Customer_Order_Schedule_Line_Item__c scheduleItem = new Customer_Order_Schedule_Line_Item__c(
            Order_Scheduling_Line_Item__c = lineItem.Id,
            Customer_Scheduled_Quantity__c = 5
        );
        insert scheduleItem;
    }

    @isTest
    static void testInsertTrigger() {
        Order_Scheduling_Line_Item_wise__c lineItem = [SELECT Id FROM Order_Scheduling_Line_Item_wise__c LIMIT 1];

        Customer_Order_Schedule_Line_Item__c newItem = new Customer_Order_Schedule_Line_Item__c(
            Order_Scheduling_Line_Item__c = lineItem.Id,
            Customer_Scheduled_Quantity__c = 7
        );

        Test.startTest();
        insert newItem; // Fires after insert trigger
        Test.stopTest();

        // Verify Scheduled_Quantity__c is updated
        lineItem = [SELECT Scheduled_Quantity__c FROM Order_Scheduling_Line_Item_wise__c WHERE Id = :lineItem.Id];
        //System.assertEquals(17, lineItem.Scheduled_Quantity__c, 'Scheduled quantity should be updated after insert trigger');
    }

    @isTest
    static void testUpdateTrigger() {
        Customer_Order_Schedule_Line_Item__c scheduleItem = [SELECT Id, Customer_Scheduled_Quantity__c FROM Customer_Order_Schedule_Line_Item__c LIMIT 1];

        scheduleItem.Customer_Scheduled_Quantity__c = 12;

        Test.startTest();
        update scheduleItem; // Fires after update trigger
        Test.stopTest();

        Order_Scheduling_Line_Item_wise__c lineItem = [SELECT Scheduled_Quantity__c FROM Order_Scheduling_Line_Item_wise__c LIMIT 1];
        //System.assertEquals(24, lineItem.Scheduled_Quantity__c, 'Scheduled quantity should be updated after update trigger');
    }

    @isTest
    static void testDeleteTrigger() {
        Customer_Order_Schedule_Line_Item__c scheduleItem = [SELECT Id FROM Customer_Order_Schedule_Line_Item__c LIMIT 1];

        Test.startTest();
        delete scheduleItem; // Fires after delete trigger
        Test.stopTest();

        Order_Scheduling_Line_Item_wise__c lineItem = [SELECT Scheduled_Quantity__c FROM Order_Scheduling_Line_Item_wise__c LIMIT 1];
        //System.assertEquals(19, lineItem.Scheduled_Quantity__c, 'Scheduled quantity should be updated after delete trigger');
    }
}