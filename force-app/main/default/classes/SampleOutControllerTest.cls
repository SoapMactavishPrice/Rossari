@isTest
private class SampleOutControllerTest {

    @isTest
    static void testGetSampleRequestData_withCustomer() {
        Country__c country = new Country__c(Name = 'Country B');
        insert country;

        State__c state = new State__c(Name = 'State B', Country__c = country.Id);
        insert state;

        City__c city = new City__c(Name = 'City B', State__c = state.Id);
        insert city;

        Pin_Code__c pin = new Pin_Code__c(
            Name = '123456',
            City__c = city.Id
        );
        insert pin;

        Account acc = new Account(Name = 'Customer Acc');
        insert acc;

        Address_Information__c addr = new Address_Information__c(
            Account__c = acc.Id,
            Street_1__c = '123 Test Street',
            Street_2__c = 'Suite 100',
            Street_3__c = 'Block C',
            Pin_Code__c = pin.Id,
            City__c = city.Id,
            State__c = state.Id,
            Country__c = country.Id
        );
        insert addr;

        Sample_Request__c req = new Sample_Request__c(
            Customer_Name__c = acc.Id,
            CurrencyIsoCode = 'USD'
        );
        insert req;

        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
 
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


        Plant__c plant = new Plant__c(Name = 'Plant 1', Plant_Name__c = 'Plant Alpha');
        insert plant;

        Sample_Request_Line_Item__c line = new Sample_Request_Line_Item__c(
            Sample_Request__c = req.Id,
            Product__c = prod.Id,
            Sample_Request_To_Plant__c = plant.Id,
            Sample_Qty_in_Kgs__c = 10,
            Sales_Price__c = 100,
            Status__c = 'Ready'
        );
        insert line;

        Test.startTest();
        SampleOutController.getSampleRequestData(req.Id);
        Test.stopTest();
    }

    @isTest
    static void testGetAddressDataByPin() {
        Country__c country = new Country__c(Name = 'Country A');
        insert country;

        State__c state = new State__c(Name = 'State A', Country__c = country.Id);
        insert state;

        City__c city = new City__c(Name = 'City A', State__c = state.Id);
        insert city;

        Pin_Code__c pin = new Pin_Code__c(Name = '654321', City__c = city.Id);
        insert pin;

        Test.startTest();
        SampleOutController.getAddressDataByPin(pin.Id);
        Test.stopTest();
    }

    @isTest
    static void testGetCurrencyFromRequest() {
        Sample_Request__c req = new Sample_Request__c(
            CurrencyIsoCode = 'EUR'
        );
        insert req;

        Test.startTest();
        SampleOutController.getCurrencyFromRequest(req.Id);
        Test.stopTest();
    }

    @isTest
    static void testGetPicklistValues() {
        Test.startTest();
        SampleOutController.getPicklistValues();
        Test.stopTest();
    }

    @isTest
    static void testSaveSampleOut() {
        Country__c country = new Country__c(Name = 'Country X');
        insert country;

        State__c state = new State__c(Name = 'State X', Country__c = country.Id);
        insert state;

        City__c city = new City__c(Name = 'City X', State__c = state.Id);
        insert city;

        Pin_Code__c pin = new Pin_Code__c(Name = '111111', City__c = city.Id);
        insert pin;

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Sample_Request__c req = new Sample_Request__c(
            Customer_Name__c = acc.Id,
            CurrencyIsoCode = 'USD'
        );
        insert req;

        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
 
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

	
        Plant__c plant = new Plant__c(Name = 'Plant Z', Plant_Name__c = 'Plant Zeta');
        insert plant;
        
        Sample_Request_Line_Item__c lineItem = new Sample_Request_Line_Item__c(
            Sample_Request__c = req.Id,
            Product__c = prod.Id,
            Sample_Request_To_Plant__c = plant.id,
            Sample_Qty_in_Kgs__c = 5,
            Sales_Price__c = 50,
            Status__c = 'Ready'
        );
        insert lineItem;


        Map<String, Object> sampleOutData = new Map<String, Object>{
            'SampleRequest' => req.Id,
            'SampleSentByFactoryToHO' => Date.today(),
            'DeliveryDate' => Date.today().addDays(5),
            'Country' => country.Id,
            'State' => state.Id,
            'City' => city.Id,
            'PinCode' => pin.Id,
            'Street1' => 'Street 1',
            'Street2' => 'Street 2',
            'Street3' => 'Street 3',
           
            'IncoTerms' => 'FOB',
            'CurrencyIsoCode' => 'USD',
            'SampleReceivedByEndPerson' => 'Test Person'
        };

        Map<String, Object> lineData = new Map<String, Object>{
            'Product' => prod.Id,
            'SampleRequestLine' => lineItem.Id,
            'SampleQtyInKgs' => 10,
            'SampleOutPlant' => plant.Id,
            'Price' => 200,
            'Description' => 'Test Description'
        };

        String sampleOutJson = JSON.serialize(sampleOutData);
        String sampleOutLinesJson = JSON.serialize(new List<Object>{ lineData });

        Test.startTest();
        Id resultId = SampleOutController.saveSampleOut(sampleOutJson, sampleOutLinesJson);
        Test.stopTest();
    }
}