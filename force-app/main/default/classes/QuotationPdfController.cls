public with sharing class QuotationPdfController {

    public String quotationId {get;set;}
    public Quote quotation {get;set;}
    public List<QuoteLineItem> quoteLineItems {get;set;}
    public String billingAddress {get;set;}
    public String shippingAddress {get;set;}
    public String totalAmountInWords {get;set;}
    public Boolean isExport {get;set;}

    public QuotationPdfController() {
        this.quotationId = ApexPages.currentPage().getparameters().get('id');

        this.quotation = [SELECT Id, QuoteNumber, CreatedDate, ExpirationDate, CurrencyIsoCode, Payment_Terms__c, BillingName, Account.Company__r.Name,
                            BillingAddress, Inco_Terms__c, Pre_Carriage_Mode__c, Country_of_Origin__c, Country_of_Destination__c, 
                            Destination__c, Loading_Port__c, Destination_Port__c, Place_of_Supplier__c, Partial_Shipment__c, ShippingName,
                            BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, Business_Type__c,
                            ShippingStreet, ShippingCity, ShippingCountry, ShippingPostalCode, ShippingState,
                            ShippingAddress, GrandTotal FROM Quote WHERE Id = :quotationId];

        if (quotation.Business_Type__c == 'Export') {
            this.isExport = true;
        }

        Integer grandTotal = quotation.GrandTotal.intValue();

        String grandTotalInWords = ConvertCurrencytowords.convert(grandTotal);
        if (quotation.CurrencyIsoCode == 'INR') {
            totalAmountInWords = 'Rupees ' + grandTotalInWords + ' Only.';
        } else if (quotation.CurrencyIsoCode != 'INR' && quotation.CurrencyIsoCode != null) {
            totalAmountInWords = quotation.CurrencyIsoCode + ' ' + grandTotalInWords + ' Only.';
        } else {
            totalAmountInWords = grandTotalInWords + ' Only.';
        }

        this.billingAddress = this.getFormattedBillingAddress(quotation);
        this.shippingAddress = this.getFormattedShippingAddress(quotation);

        this.quoteLineItems = [SELECT Description, Quantity, UnitPrice, TotalPrice, ListPrice FROM QuoteLineItem WHERE QuoteId = :quotationId];
    }

    public String getFormattedBillingAddress(Quote quote) {
        List<String> parts = new List<String>();
        
        if (String.isNotBlank(quote.BillingStreet)) {
            parts.add(quote.BillingStreet);
        }
        if (String.isNotBlank(quote.BillingCity)) {
            parts.add(quote.BillingCity);
        }
        if (String.isNotBlank(quote.BillingState)) {
            parts.add(quote.BillingState);
        }
        if (String.isNotBlank(quote.BillingPostalCode)) {
            parts.add(quote.BillingPostalCode);
        }
        if (String.isNotBlank(quote.BillingCountry)) {
            parts.add(quote.BillingCountry);
        }
        
        return String.join(parts, ', ');
    }
    
    public String getFormattedShippingAddress(Quote quote) {
        List<String> parts = new List<String>();
        
        if (String.isNotBlank(quote.ShippingStreet)) {
            parts.add(quote.ShippingStreet);
        }
        if (String.isNotBlank(quote.ShippingCity)) {
            parts.add(quote.ShippingCity);
        }
        if (String.isNotBlank(quote.ShippingState)) {
            parts.add(quote.ShippingState);
        }
        if (String.isNotBlank(quote.ShippingPostalCode)) {
            parts.add(quote.ShippingPostalCode);
        }
        if (String.isNotBlank(quote.ShippingCountry)) {
            parts.add(quote.ShippingCountry);
        }
        
        return String.join(parts, ', ');
    }

}