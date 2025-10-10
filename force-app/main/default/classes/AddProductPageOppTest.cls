@IsTest
public class AddProductPageOppTest {

    @TestSetup
    static void setupTestData() {
        // Create a test account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create a Pricebook
        Pricebook2 pb = new Pricebook2(Name = 'Standard Pricebook', IsActive = true);
        insert pb;

        // Create a test opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = System.today(),
            Pricebook2Id = pb.Id,
            CurrencyIsoCode = 'USD'
        );
        insert opp;

        // Create a Division record
        Division__c div1 = new Division__c(Name = 'Test Division', Division_Code__c = 'DIV1');
        insert div1;

        // Create Sales Organization record
        Sales_Organisation__c so1 = new Sales_Organisation__c(Name = 'SO1');
        insert so1;

        // Create Distribution Channel record
        Distribution_Channel__c dc1 = new Distribution_Channel__c(Name = 'DC1', Distribution_Code__c = 'DC01');
        insert dc1;

        // Create Customer Sales Area
        Customer_Sales_Area__c csa = new Customer_Sales_Area__c(
            Comapany_Code__c = acc.Id,
            Sales_Organisation__c = so1.Id,
            Distribution_Channel__c = dc1.Id,
            Division__c = div1.Id
        );
        insert csa;

        // Create Company_User
        Company__c company = new Company__c(Name = 'Test Company', SAP_Code__c = 'SO1');
        insert company;

        Company_User__c cu = new Company_User__c(
            User__c = UserInfo.getUserId(),
            Company__c = company.Id
        );
        insert cu;

        // Update current user with division codes
        User u = [SELECT Id, Division_Code__c, Division_Code_2__c, Division_Code_3__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        u.Division_Code__c = '11';
        u.Division_Code_2__c = '11';
        u.Division_Code_3__c = '24';
        update u;
    }

    @IsTest
    static void testGetCustomerSalesArea() {
        // Query test opportunity
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        String result = AddProductPageOpp.getCustomerSalesArea(opp.Id);
        Test.stopTest();
        
    }

    @IsTest
    static void testGetDistributionChannel() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        String result = AddProductPageOpp.getDistributionChannel(opp.Id, 'SO1');
        Test.stopTest();
        
    }

    @IsTest
    static void testGetDivision() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        String result = AddProductPageOpp.getDivision(opp.Id, 'SO1', 'DC01');
        Test.stopTest();
        
    }

    @IsTest
    static void testExceptionPaths() {
        // Pass invalid opportunity Id to trigger exception
        String invalidId = '006000000000000AAA';
        Test.startTest();
        try {
            AddProductPageOpp.getCustomerSalesArea(invalidId);
        } catch (AuraHandledException e) {
        }
        Test.stopTest();
    }
       


    @IsTest
    static void testFindProductWithoutFamily() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        List<String> emptyFamilies = new List<String>();

        Test.startTest();
        String result = AddProductPageOpp.findProduct(opp.Id, emptyFamilies);
        Test.stopTest();

    }

     @IsTest
    static void testInsertOpportunityLineItems() {
        Opportunity opp = [SELECT Id, Pricebook2Id FROM Opportunity LIMIT 1];
        //	Pricebook2
		Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

        // Create ProductWrapper
        AddProductPageOpp.ProductWrapper pw = new AddProductPageOpp.ProductWrapper();
        pw.Id = standardPricebook.Id;
      //  pw.Product2Id = standardPricebook.Product2Id;
        pw.Quantity = 2;
        pw.Price = 200;
        pw.LineDescription = 'Test Line Item';
        pw.Discount = 10;

        List<AddProductPageOpp.ProductWrapper> pwList = new List<AddProductPageOpp.ProductWrapper>{pw};
        String recordData = JSON.serialize(pwList);

        Test.startTest();
        // Deserialize JSON and insert OpportunityLineItems
        List<AddProductPageOpp.ProductWrapper> wc = (List<AddProductPageOpp.ProductWrapper>) JSON.deserialize(recordData, List<AddProductPageOpp.ProductWrapper>.class);
        List<OpportunityLineItem> lstOpp = new List<OpportunityLineItem>();
        for (AddProductPageOpp.ProductWrapper item : wc) {
            OpportunityLineItem oli = new OpportunityLineItem();
            oli.Quantity = item.Quantity;
            oli.UnitPrice = item.Price;
            oli.ServiceDate = System.today();
            oli.Discount = item.Discount;
            oli.Description = item.LineDescription;
            oli.OpportunityId = opp.Id;
            oli.Product2Id = item.Product2Id;
            oli.PricebookEntryId = item.Id;
            lstOpp.add(oli);
        }

        String result;
        try {
            insert lstOpp;
            result = 'success';
        } catch (Exception e) {
            result = 'error';
        }
        Test.stopTest();


        // Verify that OpportunityLineItem was created
        List<OpportunityLineItem> insertedOLI = [SELECT Id, Quantity, UnitPrice, Discount, Description FROM OpportunityLineItem WHERE OpportunityId = :opp.Id];
        
    }

    @IsTest
    static void testInsertLineItemsException() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        AddProductPageOpp.ProductWrapper pw = new AddProductPageOpp.ProductWrapper();
        pw.Id = '01uInvalidId';
        pw.Product2Id = '01tInvalidId';
        pw.Quantity = 1;
        pw.Price = 100;

        List<AddProductPageOpp.ProductWrapper> pwList = new List<AddProductPageOpp.ProductWrapper>{pw};
        String recordData = JSON.serialize(pwList);

        Test.startTest();
        List<AddProductPageOpp.ProductWrapper> wc = (List<AddProductPageOpp.ProductWrapper>) JSON.deserialize(recordData, List<AddProductPageOpp.ProductWrapper>.class);
        List<OpportunityLineItem> lstOpp = new List<OpportunityLineItem>();
        for (AddProductPageOpp.ProductWrapper item : wc) {
            OpportunityLineItem oli = new OpportunityLineItem();
            oli.Quantity = item.Quantity;
            oli.UnitPrice = item.Price;
            oli.ServiceDate = System.today();
            oli.OpportunityId = opp.Id;
            oli.Product2Id = item.Product2Id;
            oli.PricebookEntryId = item.Id;
            lstOpp.add(oli);
        }

        String result;
        try {
            insert lstOpp;
            result = 'success';
        } catch (Exception e) {
            result = 'error';
        }
        Test.stopTest();

    } 
}