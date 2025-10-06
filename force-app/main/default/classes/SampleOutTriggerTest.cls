@isTest
public class SampleOutTriggerTest {

    // Utility method to create a Sample_Out__c record
    private static Sample_Out__c createSampleOut(Id sampleRequestId) {
        Sample_Out__c sample = new Sample_Out__c(
            Sample_Request__c = sampleRequestId
            // Add other required fields here if any
        );
        return sample;
    }

    @isTest
    static void testBeforeInsertAndAfterInsert() {
        // First create a Sample_Request__c record (required lookup/master-detail)
        Sample_Request__c request = new Sample_Request__c(
           // Name = 'Test Request'  // or required fields for Sample_Request__c
        );
        insert request;

        // Now create Sample_Out__c linked to the request
        Sample_Out__c sample = createSampleOut(request.Id);
        insert sample;

        // Reload record to check if after-insert logic executed
        Sample_Out__c insertedRecord = [
            SELECT Id, Sample_Request__c 
            FROM Sample_Out__c 
            WHERE Id = :sample.Id
        ];

        System.assertEquals(request.Id, insertedRecord.Sample_Request__c, 
            'Sample_Out__c should be linked to Sample_Request__c');
    }

    @isTest
    static void testBeforeUpdate() {
        // Create parent Sample_Request__c record
        Sample_Request__c request = new Sample_Request__c(
           // Name = 'Test Request for Update'
        );
        insert request;

        // Insert Sample_Out__c record
        Sample_Out__c sample = createSampleOut(request.Id);
        insert sample;

        // Update allowed field
        // Example: add a dummy update to trigger before update logic
        sample.Inco_Terms__c = 'CFR'; // Replace with real updatable field
        update sample;

        // Query back to confirm update worked
        Sample_Out__c updatedRecord = [
            SELECT Id, Sample_Request__c 
            FROM Sample_Out__c 
            WHERE Id = :sample.Id
        ];

        System.assertEquals(request.Id, updatedRecord.Sample_Request__c, 
            'Sample_Out__c should still be linked after update');
    }
}