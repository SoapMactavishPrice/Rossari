public with sharing class QuotationPdfController {

    public String quotationId {get;set;}
    public Quote quotation {get;set;}
    public List<QuoteLineItem> quoteLineItems {get;set;}
    public String billingAddress {get;set;}
    public String shippingAddress {get;set;}
    public String totalAmountInWords {get;set;}
    public String type {get;set;}
    public Boolean isExport {get;set;}

    public QuotationPdfController() {
        this.quotationId = ApexPages.currentPage().getparameters().get('id');

        if (String.isBlank(this.quotationId)) {
            this.quotationId = '0Q0C1000000MEYzKAO';
        }

        this.quotation = [SELECT Id, QuoteNumber, CreatedDate, ExpirationDate, CurrencyIsoCode, Payment_Terms__c, BillingName, Account.Rossari_Company__r.Name,
                            BillingAddress, Inco_Terms__c, Pre_Carriage_Mode__c, Country_of_Origin__c, Country_of_Destination__c, Net_weight__c,
                            Destination__c, Loading_Port__c, Destination_Port__c, Place_of_Supplier__c, Partial_Shipment__c, ShippingName,
                            BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, Business_Type__c, Vessel_Flight_No__c, Pre_Carriage_Destination__c,
                            ShippingStreet, ShippingCity, ShippingCountry, ShippingPostalCode, ShippingState, Terms_and_Conditions__c, Declaration__c,
                            Bank__r.Bank_Account_No__c, Bank__r.Name, Bank__r.Branch__c, Bank__r.SWIFT_Code__c, Subtotal, PO_No__c, PO_Date__c, Account.GST_No__c, Letter_Company_Name__c, Letter_Company_Name__r.Name,
                            ShippingAddress, GrandTotal FROM Quote WHERE Id = :quotationId];

        this.isExport = quotation.Business_Type__c == 'Export';

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

        this.quoteLineItems = [SELECT Description, Quantity, UnitPrice, TotalPrice, ListPrice, Product2.ProductCode, Product2.HSN__c, Product2.Pack_Size__c, Product2.Base_UOM__r.Name FROM QuoteLineItem WHERE QuoteId = :quotationId AND (Status__c = 'Won' OR Status__c = null)];
    }

    public QuotationPdfController(String quoteId, String type) {
        this.type = type;

        this.quotationId = quoteId;

        this.quotation = [SELECT Id, QuoteNumber, CreatedDate, ExpirationDate, CurrencyIsoCode, Payment_Terms__c, BillingName, Account.Rossari_Company__r.Name,
                            BillingAddress, Inco_Terms__c, Pre_Carriage_Mode__c, Country_of_Origin__c, Country_of_Destination__c, Net_weight__c,
                            Destination__c, Loading_Port__c, Destination_Port__c, Place_of_Supplier__c, Partial_Shipment__c, ShippingName,
                            BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, Business_Type__c, Vessel_Flight_No__c, Pre_Carriage_Destination__c,
                            ShippingStreet, ShippingCity, ShippingCountry, ShippingPostalCode, ShippingState, Terms_and_Conditions__c, Declaration__c,
                            Bank__r.Bank_Account_No__c, Bank__r.Name, Bank__r.Branch__c, Bank__r.SWIFT_Code__c, Subtotal, PO_No__c, PO_Date__c, Account.GST_No__c, Letter_Company_Name__c, Letter_Company_Name__r.Name,
                            ShippingAddress, GrandTotal FROM Quote WHERE Id = :quotationId];

        this.isExport = quotation.Business_Type__c == 'Export';

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

        this.quoteLineItems = [SELECT Description, Quantity, UnitPrice, TotalPrice, ListPrice, Product2.ProductCode, Product2.HSN__c, Product2.Pack_Size__c, Product2.Base_UOM__r.Name FROM QuoteLineItem WHERE QuoteId = :quotationId AND (Status__c = 'Won' OR Status__c = null)];
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

    String ns(Object val) {
        return val == null ? '' : String.valueOf(val);
    }

    public String buildEmailContent() {

        // Decide title text
        String docTitle = '';
        String docLabel = '';
        if (type != null && type.toLowerCase() == 'invoice') {
            docTitle = 'PROFORMA INVOICE';
            docLabel = 'Invoice';
        } else {
            docTitle = 'QUOTATION';
            docLabel = 'Quote';
        }

        // Common styles
        String borderStyle = 'border:1px solid black; padding:4px; vertical-align:top; font-size:10px;';
        String tableStyle = 'width:100%; border-collapse:collapse; font-size:10px;';
        String sectionTitleStyle = 'border-top: 1px solid black; border-right: 1px solid black; border-left: 1px solid black; border-collapse: collapse; text-align:center; font-weight:bold; font-size:13px;';
        String boldStyle = 'font-weight:bold;';
        String leftBorder = 'border-left:1px solid black; border-right:none; border-top:none; border-bottom:none; padding:4px; vertical-align:top; font-size:10px;';
        String doubleBorder = 'border-left:1px solid black; border-right:1px solid black; border-top:none; border-bottom:none; padding:4px; vertical-align:top; font-size:10px;';
        String borderless = 'border:none; padding:4px; vertical-align:top; font-size:10px;';

        String html = '';

        // Section Title
        html += '<table style="' + tableStyle + '">';
        html += '<tr><td style="' + sectionTitleStyle + '">' + docTitle + '</td></tr>';
        html += '</table>';

        // Details Table
        html += '<table style="' + tableStyle + '">';
        html += '<tr>';
        html += '<th colspan="2" style="' + borderStyle + '">' + docLabel + ' Details</th>';
        html += '<th colspan="2" style="' + borderStyle + '">Bill to</th>';
        html += '</tr>';

        html += '<tr>';
        html += '<td style="' + leftBorder + 'width:36%;">' + docLabel + ' No.: ' + ns(quotation.QuoteNumber) + '</td>';
        html += '<td style="' + borderless + 'width:36%;">Payment Terms: ' + ns(quotation.Payment_Terms__c) + '</td>';
        html += '<td style="' + doubleBorder + 'width:27%;" colspan="2">Name: ' + ns(quotation.BillingName) + '</td>';
        html += '</tr>';

        html += '<tr>';
        html += '<td style="' + leftBorder + '">' + docLabel + ' Date: ' + (quotation.CreatedDate != null ? quotation.CreatedDate.format('dd/MM/yyyy') : '') + '</td>';
        html += '<td style="' + borderless + '">Our Bankers: </td>';
        html += '<td style="' + doubleBorder + '" colspan="2" rowspan="' + (isExport ? '5' : '4') + '">Address: ' + ns(billingAddress) + '</td>';
        html += '</tr>';

        html += '<tr>';
        html += '<td style="' + leftBorder + '">Buyer Ref No.: ' + ns(quotation.PO_No__c) + '</td>';
        html += '<td style="' + borderless + '">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;A/c No.: ' + ns(quotation.Bank__r.Bank_Account_No__c) + '</td>';
        html += '</tr>';

        html += '<tr>';
        html += '<td style="' + leftBorder + '">Buyer Ref Date: ' + (quotation.PO_Date__c != null ? quotation.PO_Date__c.format() : '') + '</td>';
        html += '<td style="' + borderless + '">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Bank Name: ' + ns(quotation.Bank__r.Name) + '</td>';
        html += '</tr>';

        html += '<tr>';
        html += '<td style="' + leftBorder + '">' + docLabel + ' Validity: ' + (quotation.ExpirationDate != null ? quotation.ExpirationDate.format() : '') + '</td>';
        html += '<td style="' + borderless + '">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Branch: ' + ns(quotation.Bank__r.Branch__c) + '</td>';
        html += '</tr>';

        html += '<tr>';
        html += '<td style="' + leftBorder + '">Currency: ' + ns(quotation.CurrencyIsoCode) + '</td>';
        html += '<td style="' + borderless + '">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Swift Code: ' + ns(quotation.Bank__r.SWIFT_Code__c) + '</td>';
        if (!isExport) {
            html += '<td style="' + doubleBorder + '" colspan="2">GSTIN: ' + ns(quotation.Account.GST_No__c) + '</td>';
        }
        html += '</tr>';
        html += '</table>';

        // Shipment Details
        html += '<table style="' + tableStyle + '">';
        html += '<tr>';
        html += '<th colspan="2" style="' + borderStyle + '">Shipment Details</th>';
        html += '<th colspan="2" style="' + borderStyle + '">Ship to</th>';
        html += '</tr>';

        if (isExport) {
            html += '<tr>';
            html += '<td style="' + leftBorder + 'width:36%;">Incoterms: ' + ns(quotation.Inco_Terms__c) + '</td>';
            html += '<td style="' + borderless + 'width:36%;">Pre-Carriage Mode: ' + ns(quotation.Pre_Carriage_Mode__c) + '</td>';
            html += '<td style="' + doubleBorder + 'width:27%;" colspan="2">Name: ' + ns(quotation.ShippingName) + '</td>';
            html += '</tr>';

            html += '<tr>';
            html += '<td style="' + leftBorder + '">Country of Origin: ' + ns(quotation.Country_of_Origin__c) + '</td>';
            html += '<td style="' + borderless + '">Pre-Carriage Destination: ' + ns(quotation.Pre_Carriage_Destination__c) + '</td>';
            html += '<td style="' + doubleBorder + '" colspan="2" rowspan="5">Address: ' + ns(shippingAddress) + '</td>';
            html += '</tr>';

            html += '<tr><td style="' + leftBorder + '">Country of Destination: ' + ns(quotation.Country_of_Destination__c) + '</td><td style="' + borderless + '">Vessel/Flight No.: ' + ns(quotation.Vessel_Flight_No__c) + '</td></tr>';
            html += '<tr><td style="' + leftBorder + '">Final Destination: ' + ns(quotation.Destination__c) + '</td><td style="' + borderless + '">Loading Port: ' + ns(quotation.Loading_Port__c) + '</td></tr>';
            html += '<tr><td style="' + leftBorder + '">Place of Supply: ' + ns(quotation.Place_of_Supplier__c) + '</td><td style="' + borderless + '">Discharge Port: ' + ns(quotation.Destination_Port__c) + '</td></tr>';
            html += '<tr><td style="' + leftBorder + '">Partial Shipment: ' + ns(quotation.Partial_Shipment__c) + '</td><td style="' + borderless + '"></td></tr>';
        } else {
            html += '<tr>';
            html += '<td style="' + leftBorder + 'width:36%;">Incoterms: ' + ns(quotation.Inco_Terms__c) + '</td>';
            html += '<td style="' + borderless + 'width:36%;">Destination: ' + ns(quotation.Destination__c) + '</td>';
            html += '<td style="' + doubleBorder + 'width:27%;" colspan="2">Name: ' + ns(quotation.ShippingName) + '</td>';
            html += '</tr>';

            html += '<tr><td style="' + leftBorder + '"></td><td style="' + borderless + '"></td><td style="' + doubleBorder + '" colspan="2" rowspan="4">Address: ' + ns(shippingAddress) + '</td></tr>';
            html += '<tr><td style="' + leftBorder + '"></td><td style="' + borderless + '"></td></tr>';
            html += '<tr><td style="' + leftBorder + '"></td><td style="' + borderless + '"></td></tr>';
            html += '<tr><td style="' + leftBorder + '"></td><td style="' + borderless + '"></td></tr>';
            html += '<tr><td style="' + leftBorder + '"></td><td style="' + borderless + '"></td><td style="' + doubleBorder + '" colspan="2">GSTIN: ' + ns(quotation.Account.GST_No__c) + '</td></tr>';
        }
        html += '</table>';

        // Line Items
        html += '<table style="' + tableStyle + '">';
        html += '<tr>';
        html += '<th style="' + borderStyle + '">Sr. No.</th>';
        html += '<th style="' + borderStyle + '">Material Code</th>';
        html += '<th style="' + borderStyle + '">HSN/SAC</th>';
        html += '<th style="' + borderStyle + '">Item Description</th>';
        html += '<th style="' + borderStyle + '">Pack Size</th>';
        html += '<th style="' + borderStyle + '">UOM</th>';
        html += '<th style="' + borderStyle + '">Quantity</th>';
        html += '<th style="' + borderStyle + '">Unit</th>';
        html += '<th style="' + borderStyle + '">Price</th>';
        html += '<th style="' + borderStyle + '">Amount</th>';
        html += '</tr>';

        Integer srNo = 1;
        for (QuoteLineItem item : quoteLineItems) {
            html += '<tr>';
            html += '<td style="' + borderStyle + '">' + srNo + '</td>';
            html += '<td style="' + borderStyle + '">' + ns(item.Product2.ProductCode) + '</td>';
            html += '<td style="' + borderStyle + '">' + ns(item.Product2.HSN__c) + '</td>';
            html += '<td style="' + borderStyle + '">' + ns(item.Description) + '</td>';
            html += '<td style="' + borderStyle + '">' + ns(item.Product2.Pack_Size__c) + '</td>';
            html += '<td style="' + borderStyle + '">' + ns(item.Product2.Base_UOM__r.Name) + '</td>';
            html += '<td style="' + borderStyle + '">' + ns(item.Quantity) + '</td>';
            html += '<td style="' + borderStyle + '">' + ns(item.ListPrice) + '</td>';
            html += '<td style="' + borderStyle + '">' + ns(item.UnitPrice) + '</td>';
            html += '<td style="' + borderStyle + '">' + ns(item.TotalPrice) + '</td>';
            html += '</tr>';
            srNo++;
        }

        // Terms & Totals
        html += '<tr>';
        html += '<td colspan="10" style="' + borderStyle + 'white-space: pre-wrap; padding: 0px; margin: 0px;' + '"><b>Terms and Conditions:</b><br/>' + ns(quotation.Terms_and_Conditions__c) + '</td>';
        // html += '<td colspan="3" style="' + boldStyle + borderStyle + '">Amount Before Tax</td><td style="' + borderStyle + '">' + quotation.Subtotal + '</td>';
        html += '</tr>';

        // html += '<tr><td colspan="2" style="' + boldStyle + borderStyle + '">CGST</td><td style="' + borderStyle + '">(HC)</td><td style="' + borderStyle + '">(HC)</td></tr>';
        // html += '<tr><td colspan="2" style="' + boldStyle + borderStyle + '">SGST</td><td style="' + borderStyle + '">(HC)</td><td style="' + borderStyle + '">(HC)</td></tr>';
        // html += '<tr><td colspan="2" style="' + boldStyle + borderStyle + '">IGST</td><td style="' + borderStyle + '">(HC)</td><td style="' + borderStyle + '">(HC)</td></tr>';
        // html += '<tr><td colspan="2" style="' + boldStyle + borderStyle + '">Round Off</td><td style="' + borderStyle + '">(HC)</td><td style="' + borderStyle + '">(HC)</td></tr>';

        html += '<tr><td colspan="6" style="' + borderStyle + '"><b>Net Weight</b>: ' + quotation.Net_weight__c + '</td><td colspan="3" style="' + boldStyle + borderStyle + '">Grand Total</td><td style="' + borderStyle + '">' + ns(quotation.GrandTotal) + '</td></tr>';
        html += '</table>';

        // Amount in Words & Declaration
        html += '<table style="' + tableStyle + '">';
        html += '<tr><td style="text-align:left; ' + borderStyle + 'border-top:none;' + '"><b>Total Amount in Words:</b> ' + ns(totalAmountInWords) + '</td></tr>';
        html += '<tr><td style="text-align:left; ' + borderStyle + '"><b>Declaration</b>: ' + ns(this.quotation.Declaration__c) + '</td></tr>';
        html += '</table>';

        return html;
    }




    @AuraEnabled
    public static String getEmailBody(String quoteId, String type) {
        QuotationPdfController controller = new QuotationPdfController(quoteId, type);
        return controller.buildEmailContent();
    }

}