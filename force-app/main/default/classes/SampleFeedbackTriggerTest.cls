@IsTest
private class SampleFeedbackTriggerTest {
    
    @IsTest
    static void testSampleFeedbackTrigger() {

        Sample_Request__c sampleRequest = new Sample_Request__c(
            //Name = 'Test Request'
        );
        insert sampleRequest;

        Sample_Out__c sampleOut = new Sample_Out__c(
            //Name = 'Test Out',
            Sample_Request__c = sampleRequest.Id
        );
        insert sampleOut;
        System.debug('Inserted Sample_Out__c: ' + sampleOut.Id + 
                     ' linked to Request: ' + sampleOut.Sample_Request__c);

        Sample_Feedback__c feedback = new Sample_Feedback__c(
            //Name = 'Test Feedback',
            Sample_Out__c = sampleOut.Id
        );

        insert feedback;

        Sample_Feedback__c insertedFeedback = [
            SELECT Id, Name, Sample_Out__c, Sample_Request__c 
            FROM Sample_Feedback__c 
            WHERE Id = :feedback.Id
        ];
    }
}