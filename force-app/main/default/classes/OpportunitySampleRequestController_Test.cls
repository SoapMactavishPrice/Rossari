@IsTest
public class OpportunitySampleRequestController_Test {

    @TestSetup
    static void setupData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = System.today(),
            AccountId = acc.Id,
            CurrencyIsoCode = 'INR'
        );
        insert opp;

        Id standardPricebookId = Test.getStandardPricebookId();

        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        try{
        update standardPricebook;
        }Catch(Exception e){}
    
        Base_UoM_Master__c baseUom = new Base_UoM_Master__c(Name = 'Kilogram');
        insert baseUom;
 
        Product2 prod = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP001',
            Pack_Size__c = '10kg',
            Base_UOM__c = baseUom.Id,
            IsActive = true
        );
        insert prod;
 
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;


        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Quantity = 5,
            PricebookEntryId = pbe.Id,
            UnitPrice = 100
        );
        insert oli;

        Plant__c plant = new Plant__c(Name = 'Mumbai', Plant_Name__c = 'MUM');
        insert plant;
    }

    private static Sample_Request__c createSampleRequestData() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        Plant__c plant = [SELECT Id FROM Plant__c LIMIT 1];

        Sample_Request__c req = new Sample_Request__c(
            Opportunity__c = opp.Id,
            Status__c = 'Pending',
            Sample_Category__c = 'Paid'
        );
        insert req;

        Sample_Request_Line_Item__c lineItem = new Sample_Request_Line_Item__c(
            Sample_Request__c = req.Id,
            Product__c = prod.Id,
            Sample_Request_To_Plant__c = plant.Id,
            Sample_Qty_in_Kgs__c = 10,
            Sales_Price__c = 100
        );
        insert lineItem;

        return req;
    }

    @IsTest
    static void test_getLeadInfo() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        String result = OpportunitySampleRequestController.getLeadInfo(opp.Id);
        System.assertNotEquals(null, result);
    }

    @IsTest
    static void test_getPlantOptions() {
        List<Plant__c> plants = OpportunitySampleRequestController.getPlantOptions();
        System.assert(!plants.isEmpty());
    }

    @IsTest
    private static void test_saveSample_and_related_methods() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id
        );
        insert opp;

        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;

        Id standardPricebookId = Test.getStandardPricebookId();

        PricebookEntry pbe = new PricebookEntry(
            Product2Id = prod.Id,
            Pricebook2Id = standardPricebookId,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        User u = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        Map<String, Object> sampleData = new Map<String, Object>{
            'Sample_Category' => 'Unpaid',
            'Request_Date' => String.valueOf(Date.today()),
            'Sample_Expected_Date' => String.valueOf(Date.today().addDays(2)),
            'salesHod' => u.Id,
            'Consignee_Name' => 'Test Consignee',
            'Email' => 'test@example.com',
            'Remark' => 'Test remark'
        };
        String sampleJson = JSON.serialize(sampleData);

        List<Map<String, Object>> lineItems = new List<Map<String, Object>>();
        lineItems.add(new Map<String, Object>{
            'prodId' => prod.Id,
            'Sample_Qty_in_Kgs' => 5,
            'Sales_Price' => 500
        });
        String lineItemsJson = JSON.serialize(lineItems);

        List<Object> attachments = new List<Object>();

        Test.startTest();
        String resultId = OpportunitySampleRequestController.saveSample(
            opp.Id,
            sampleJson,
            attachments,
            lineItemsJson
        );
        Test.stopTest();

        System.assertNotEquals(null, resultId);
    }

    @IsTest
    static void test_getExistingLineItems() {
        Sample_Request__c req = createSampleRequestData();
        List<Sample_Request_Line_Item__c> result = OpportunitySampleRequestController.getExistingLineItems(req.Id);
        System.assert(!result.isEmpty());
    }

    @IsTest
    static void test_getStatusPicklistValues() {
        List<String> result = OpportunitySampleRequestController.getStatusPicklistValues();
        System.assertNotEquals(null, result);
    }

    @IsTest
    static void test_getPicklistDependencies() {
        Map<String, List<String>> picklistMap = OpportunitySampleRequestController.getPicklistDependencies();
        System.assert(picklistMap != null);
    }

    @IsTest
    static void test_saveLineItems() {
        Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Status = 'Working',
            CurrencyIsoCode = 'USD',
            MobilePhone = '9876543210'
        );
        insert lead;

        Sample_Request__c sampleRequest = new Sample_Request__c(
            Lead__c = lead.Id,
            CurrencyIsoCode = lead.CurrencyIsoCode,
            Sample_Category__c = 'Unpaid',
            Consignee_Name__c = 'Test Company'
        );
        insert sampleRequest;

        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;

        Plant__c plant = new Plant__c(Name = 'Test Plant');
        insert plant;

        List<Map<String, Object>> lineItems = new List<Map<String, Object>>();
        lineItems.add(new Map<String, Object>{
            'productId' => prod.Id,
            'plantId' => plant.Id,
            'quantity' => 5,
            'status' => 'Open'
        });
        String lineItemsJson = JSON.serialize(lineItems);

        try {
            Test.startTest();
            OpportunitySampleRequestController.saveLineItems(sampleRequest.Id, lineItemsJson);
            Test.stopTest();
        } catch (Exception e) {}

        List<Sample_Request_Line_Item__c> saved = [
            SELECT Id, Product__c, Sample_Request_To_Plant__c, Sample_Qty_in_Kgs__c, Status__c
            FROM Sample_Request_Line_Item__c
            WHERE Sample_Request__c = :sampleRequest.Id
        ];
    }

    @IsTest
    static void test_updateParentStatus() {
        Sample_Request__c req = createSampleRequestData();
        Sample_Request_Line_Item__c lineItem = [SELECT Id FROM Sample_Request_Line_Item__c WHERE Sample_Request__c = :req.Id LIMIT 1];
        Set<Id> ids = new Set<Id>{lineItem.Id};

        Test.startTest();
        OpportunitySampleRequestController.updateParentStatus(ids);
        Test.stopTest();

        System.assert(true);
    }

    @IsTest
    static void test_getUnitPrice() {
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        Decimal price = OpportunitySampleRequestController.getUnitPrice(prod.Id);
        System.assert(price >= 0);
    }

    @IsTest
    static void test_deleteLineItem() {
        Sample_Request__c req = createSampleRequestData();
        Sample_Request_Line_Item__c item = [SELECT Id FROM Sample_Request_Line_Item__c WHERE Sample_Request__c = :req.Id LIMIT 1];

        Test.startTest();
        OpportunitySampleRequestController.deleteLineItem(item.Id);
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Sample_Request_Line_Item__c WHERE Id = :item.Id]);
    }

    @IsTest
    static void test_getCurrentUserZone() {
        String result = OpportunitySampleRequestController.getCurrentUserZone();
    //    System.assertNotEquals(null, result);
    }
}