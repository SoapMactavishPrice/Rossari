@isTest
public class SampleOutTriggerTest {

    private static Sample_Out__c createSampleOut(Id sampleRequestId) {
        Sample_Out__c sample = new Sample_Out__c(
            Sample_Request__c = sampleRequestId
        );
        return sample;
    }

    @isTest
    static void testBeforeInsertAndAfterInsert() {
        Sample_Request__c request = new Sample_Request__c(
        );
        insert request;

        Sample_Out__c sample = createSampleOut(request.Id);
        insert sample;

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
        Sample_Request__c request = new Sample_Request__c(
        );
        insert request;

        Sample_Out__c sample = createSampleOut(request.Id);
        insert sample;

        sample.Inco_Terms__c = 'CFR';
        update sample;

        Sample_Out__c updatedRecord = [
            SELECT Id, Sample_Request__c 
            FROM Sample_Out__c 
            WHERE Id = :sample.Id
        ];

        System.assertEquals(request.Id, updatedRecord.Sample_Request__c, 
            'Sample_Out__c should still be linked after update');
    }
}