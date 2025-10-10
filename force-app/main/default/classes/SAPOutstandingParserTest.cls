@IsTest
private class SAPOutstandingParserTest {

    @IsTest
    static void testParseAndCreate() {

        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

        Sales_Organisation__c salesOrg = new Sales_Organisation__c(Name = 'SO01');
        insert salesOrg;

        Distribution_Channel__c distCh = new Distribution_Channel__c(Distribution_Code__c = 'D01');
        insert distCh;

        Profit_Center__c profitCenter = new Profit_Center__c(Name = 'P01');
        insert profitCenter;

        Product2 testProduct = new Product2(Name = 'Test Product', ProductCode = 'MAT01', IsActive = true);
        insert testProduct;

        PricebookEntry standardPBE = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert standardPBE;

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Company__c comp = new Company__c(Name = 'Company 01');
        insert comp;

        String xml = 
        '<DynamicCellSet>' +
            '<DynamicCell>' +
                '<SalesOrg>SO01</SalesOrg>' +
                '<DistributionChannel>D01</DistributionChannel>' +
                '<ProfitCenter>P01</ProfitCenter>' +
                '<Material>MAT01</Material>' +
                '<CustomerCode>CUST01</CustomerCode>' +
                '<Currency>INR</Currency>' +
                '<DocumentNumber>DOC001</DocumentNumber>' +
                '<TotalNotOverdue>1500.00</TotalNotOverdue>' +
                '<TotalOverdue>200.00-</TotalOverdue>' +
                '<OverdueDays>10</OverdueDays>' +
                '<UpdateDate>20241010</UpdateDate>' +
                '<NetDueDate>20241101</NetDueDate>' +
                '<PostingDate>20241020</PostingDate>' +
                '<DocumentDate>20241005</DocumentDate>' +
                '<Date>20241009</Date>' +
            '</DynamicCell>' +
        '</DynamicCellSet>';


        List<Outstanding__c> parsedRecords = SAPOutstandingParser.parseAndCreate(xml, acc.Id, comp.Id);

        Outstanding__c rec = parsedRecords[0];
    }
}