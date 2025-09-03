@isTest
private class SampleInControllerTest {

    @isTest
    static void testGetSampleInInfo() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Sample_Request__c sampleRequest = new Sample_Request__c(Customer_Name__c = acc.Id, CurrencyIsoCode = 'USD');
        insert sampleRequest;

        Plant__c plant = new Plant__c(Name = 'Plant A', Plant_Name__c = 'Plant Alpha');
        insert plant;

        Courier_Master__c courier = new Courier_Master__c(Name = 'Courier XYZ');
        insert courier;

        Sample_In__c sampleIn = new Sample_In__c(
            Sample_Request__c = sampleRequest.Id,
            Competitor_Name__c = 'Competitor X',
            Remark__c = 'Sample Remark',
            Sample_Sent_To_Unit__c = plant.Id,
            Courier_Name__c = courier.Id,
            Sample_Received_Date__c = Date.today(),
            Sample_Sent_To_Factory_From_HO__c = Date.today().addDays(-1)
        );
        insert sampleIn;

        Test.startTest();
        SampleInController.getSampleInInfo(sampleIn.Id);
        Test.stopTest();
    }

    @isTest
    static void testSaveSample() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Sample_Request__c sampleRequest = new Sample_Request__c(Customer_Name__c = acc.Id, CurrencyIsoCode = 'USD');
        insert sampleRequest;

        Plant__c plant = new Plant__c(Name = 'Plant B', Plant_Name__c = 'Plant Beta');
        insert plant;

        Courier_Master__c courier = new Courier_Master__c(Name = 'Courier ABC');
        insert courier;

        Map<String, Object> sampleData = new Map<String, Object>{
            'Competitor_Name' => 'Competitor A',
            'Sample_Sent_To_Unit' => plant.Id,
            'Sample_Received_Date' => String.valueOf(Date.today()),
            'Sample_Sent_To_Factory_From_HO' => String.valueOf(Date.today().addDays(-1)),
            'Courier_Name' => courier.Id,
            'Courier_Tracking_No' => 'TRACK123',
            'Remark' => 'This is a remark value',
            'Account_No' => 'ACC123'
        };

        Map<String, Object> line1 = new Map<String, Object>{
            'sqNo' => '1',
            'Product' => 'P1',
            'prodName' => 'Customer Product A',
            'Product_Code' => 'CP-A',
            'Description' => 'Test Description A',
            'qty' => 5.0,
            'application' => 'Paint'
        };

        String sampleJson = JSON.serialize(sampleData);
        String sampleLineJson = JSON.serialize(new List<Object>{ line1 });

        Test.startTest();
        SampleInController.saveSample(sampleRequest.Id, sampleJson, sampleLineJson);
        Test.stopTest();
    }

    @isTest
    static void testParseMethods() {
        String wrapperJson = '{"CompetitorName":"Comp A","sampleSentToPlant":"Plant A","SampleReceivedDate":"2024-01-01","SampleSentToFactoryFromHO":"2024-01-02","CourierName":"C1","CourierTrackingNo":"T1","OtherRemark":"R1","AccountNo":"A1"}';
        String wrapperLineJson = '[{"sqNo":"1","Product":"P1","prodName":"Prod 1","Product_Code":"PC1","Description":"D1","qty":10,"application":"App1"}]';

        Test.startTest();
        SampleInController.wrapper w = SampleInController.parse(wrapperJson);
        List<SampleInController.wrapperLine> lines = SampleInController.parseLine(wrapperLineJson);
        Date goodDate = SampleInController.parseDate('2024-08-21');
        Date badDate = SampleInController.parseDate('not-a-date');
        Test.stopTest();
    }
}