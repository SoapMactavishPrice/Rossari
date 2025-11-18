public with sharing class ProformaInvoicePdfController {

    public String proformaInvoiceId {get;set;}
    public Proforma_Invoice__c proformaInvoice {get;set;}
    public List<Proforma_Invoice_Line_Item__c> proformaInvoiceLineItems {get;set;}
    public String billingAddress {get;set;}
    public String shippingAddress {get;set;}
    public String totalAmountInWords {get;set;}
    public String type {get;set;}
    public Boolean isExport {get;set;}

    public ProformaInvoicePdfController() {
        this.proformaInvoiceId = ApexPages.currentPage().getparameters().get('id');

        this.proformaInvoice = [SELECT Id, Proforma_Invoice_Number__c, CreatedDate, Quote_Valid_To__c, CurrencyIsoCode, Payment_Terms__c, Account_Name__r.Rossari_Company__r.Name,
                            Inco_Terms__c, Pre_Carriage_Mode__c, Country_of_Origin__c, Country_of_Destination__c, Vessel_Flight_No__c, Pre_Carriage_Destination__c,
                            Destination__c, Loading_Port__c, Destination_Port__c, Place_of_Supplier__c, Partial_Shipment__c, Business_Type__c, Net_weight__c,
                            Bill_To_Name__c, Bill_To_Street__c, Bill_To_City__c, Bill_To_State__c, Bill_To_Zip_Postal_Code__c, Bill_To_Country__c,
                            Ship_To_Name__c, Ship_To_Street__c, Ship_To_City__c, Ship_To_Country__c, Ship_To_Zip_Postal_Code__c, Ship_To_State__c,
                            Bank__r.Bank_Account_No__c, Bank__r.Name, Bank__r.Branch__c, Bank__r.SWIFT_Code__c, Quote__r.Letter_Company_Name__c, Quote__r.Letter_Company_Name__r.Name,
                            Terms_and_Conditions__c, Declaration__c, Subtotal__c, PO_No__c, PO_Date__c, Account_Name__r.GST_No__c,
                            Grand_Total__c FROM Proforma_Invoice__c WHERE Id = :proformaInvoiceId];

        this.isExport = proformaInvoice.Business_Type__c == 'Export';

        Integer grandTotal = proformaInvoice.Grand_Total__c.intValue();

        String grandTotalInWords = ConvertCurrencytowords.convert(grandTotal);
        if (proformaInvoice.CurrencyIsoCode == 'INR') {
            totalAmountInWords = 'Rupees ' + grandTotalInWords + ' Only.';
        } else if (proformaInvoice.CurrencyIsoCode != 'INR' && proformaInvoice.CurrencyIsoCode != null) {
            totalAmountInWords = proformaInvoice.CurrencyIsoCode + ' ' + grandTotalInWords + ' Only.';
        } else {
            totalAmountInWords = grandTotalInWords + ' Only.';
        }

        this.billingAddress = this.getFormattedBillingAddress(proformaInvoice);
        this.shippingAddress = this.getFormattedShippingAddress(proformaInvoice);

        this.proformaInvoiceLineItems = [SELECT Line_Item_Description__c, Quantity__c, Sales_Price__c, Total_Price__c, List_Price__c, Product__r.ProductCode, Product__r.HSN__c, Product__r.Pack_Size__c, Product__r.Base_UOM__r.Name FROM Proforma_Invoice_Line_Item__c WHERE Proforma_Invoice_Name__c = :proformaInvoiceId];
    }

    public ProformaInvoicePdfController(String proformaInvoiceId, String type) {
        this.type = type;

        this.proformaInvoiceId = proformaInvoiceId;

        this.proformaInvoice = [SELECT Id, Proforma_Invoice_Number__c, CreatedDate, Quote_Valid_To__c, CurrencyIsoCode, Payment_Terms__c, Account_Name__r.Rossari_Company__r.Name,
                            Inco_Terms__c, Pre_Carriage_Mode__c, Country_of_Origin__c, Country_of_Destination__c, Vessel_Flight_No__c, Pre_Carriage_Destination__c,
                            Destination__c, Loading_Port__c, Destination_Port__c, Place_of_Supplier__c, Partial_Shipment__c, Business_Type__c, Net_weight__c,
                            Bill_To_Name__c, Bill_To_Street__c, Bill_To_City__c, Bill_To_State__c, Bill_To_Zip_Postal_Code__c, Bill_To_Country__c,
                            Ship_To_Name__c, Ship_To_Street__c, Ship_To_City__c, Ship_To_Country__c, Ship_To_Zip_Postal_Code__c, Ship_To_State__c,
                            Bank__r.Bank_Account_No__c, Bank__r.Name, Bank__r.Branch__c, Bank__r.SWIFT_Code__c, Quote__r.Letter_Company_Name__c, Quote__r.Letter_Company_Name__r.Name,
                            Terms_and_Conditions__c, Declaration__c, Subtotal__c, PO_No__c, PO_Date__c, Account_Name__r.GST_No__c,
                            Grand_Total__c FROM Proforma_Invoice__c WHERE Id = :proformaInvoiceId];

        this.isExport = proformaInvoice.Business_Type__c == 'Export';

        Integer grandTotal = proformaInvoice.Grand_Total__c.intValue();

        String grandTotalInWords = ConvertCurrencytowords.convert(grandTotal);
        if (proformaInvoice.CurrencyIsoCode == 'INR') {
            totalAmountInWords = 'Rupees ' + grandTotalInWords + ' Only.';
        } else if (proformaInvoice.CurrencyIsoCode != 'INR' && proformaInvoice.CurrencyIsoCode != null) {
            totalAmountInWords = proformaInvoice.CurrencyIsoCode + ' ' + grandTotalInWords + ' Only.';
        } else {
            totalAmountInWords = grandTotalInWords + ' Only.';
        }

        this.billingAddress = this.getFormattedBillingAddress(proformaInvoice);
        this.shippingAddress = this.getFormattedShippingAddress(proformaInvoice);

        this.proformaInvoiceLineItems = [SELECT Line_Item_Description__c, Quantity__c, Sales_Price__c, Total_Price__c, List_Price__c, Product__r.ProductCode, Product__r.HSN__c, Product__r.Pack_Size__c, Product__r.Base_UOM__r.Name FROM Proforma_Invoice_Line_Item__c WHERE Proforma_Invoice_Name__c = :proformaInvoiceId];
    }

    public String getFormattedBillingAddress(Proforma_Invoice__c proformaInvoice) {
        List<String> parts = new List<String>();
        
        if (String.isNotBlank(proformaInvoice.Bill_To_Street__c)) {
            parts.add(proformaInvoice.Bill_To_Street__c);
        }
        if (String.isNotBlank(proformaInvoice.Bill_To_City__c)) {
            parts.add(proformaInvoice.Bill_To_City__c);
        }
        if (String.isNotBlank(proformaInvoice.Bill_To_State__c)) {
            parts.add(proformaInvoice.Bill_To_State__c);
        }
        if (String.isNotBlank(proformaInvoice.Bill_To_Zip_Postal_Code__c)) {
            parts.add(proformaInvoice.Bill_To_Zip_Postal_Code__c);
        }
        if (String.isNotBlank(proformaInvoice.Bill_To_Country__c)) {
            parts.add(proformaInvoice.Bill_To_Country__c);
        }
        
        return String.join(parts, ', ');
    }
    
    public String getFormattedShippingAddress(Proforma_Invoice__c proformaInvoice) {
        List<String> parts = new List<String>();
        
        if (String.isNotBlank(proformaInvoice.Ship_To_Street__c)) {
            parts.add(proformaInvoice.Ship_To_Street__c);
        }
        if (String.isNotBlank(proformaInvoice.Ship_To_City__c)) {
            parts.add(proformaInvoice.Ship_To_City__c);
        }
        if (String.isNotBlank(proformaInvoice.Ship_To_State__c)) {
            parts.add(proformaInvoice.Ship_To_State__c);
        }
        if (String.isNotBlank(proformaInvoice.Ship_To_Zip_Postal_Code__c)) {
            parts.add(proformaInvoice.Ship_To_Zip_Postal_Code__c);
        }
        if (String.isNotBlank(proformaInvoice.Ship_To_Country__c)) {
            parts.add(proformaInvoice.Ship_To_Country__c);
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
            docLabel = 'Proforma_Invoice__c';
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
        html += '<td style="' + leftBorder + 'width:36%;">' + docLabel + ' No.: ' + ns(proformaInvoice.Proforma_Invoice_Number__c) + '</td>';
        html += '<td style="' + borderless + 'width:36%;">Payment Terms: ' + ns(proformaInvoice.Payment_Terms__c) + '</td>';
        html += '<td style="' + doubleBorder + 'width:27%;" colspan="2">Name: ' + ns(proformaInvoice.Bill_To_Name__c) + '</td>';
        html += '</tr>';

        html += '<tr>';
        html += '<td style="' + leftBorder + '">' + docLabel + ' Date: ' + (proformaInvoice.CreatedDate != null ? proformaInvoice.CreatedDate.format('dd/MM/yyyy') : '') + '</td>';
        html += '<td style="' + borderless + '">Our Bankers: </td>';
        html += '<td style="' + doubleBorder + '" colspan="2" rowspan="' + (isExport ? '5' : '4') + '">Address: ' + ns(billingAddress) + '</td>';
        html += '</tr>';

        html += '<tr>';
        html += '<td style="' + leftBorder + '">Buyer Ref No.: ' + ns(proformaInvoice.PO_No__c) + '</td>';
        html += '<td style="' + borderless + '">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;A/c No.: ' + ns(proformaInvoice.Bank__r.Bank_Account_No__c) + '</td>';
        html += '</tr>';

        html += '<tr>';
        html += '<td style="' + leftBorder + '">Buyer Ref Date: ' + (proformaInvoice.PO_Date__c != null ? proformaInvoice.PO_Date__c.format() : '') + '</td>';
        html += '<td style="' + borderless + '">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Bank Name: ' + ns(proformaInvoice.Bank__r.Name) + '</td>';
        html += '</tr>';

        html += '<tr>';
        html += '<td style="' + leftBorder + '">' + docLabel + ' Validity: ' + (proformaInvoice.Quote_Valid_To__c != null ? proformaInvoice.Quote_Valid_To__c.format() : '') + '</td>';
        html += '<td style="' + borderless + '">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Branch: ' + ns(proformaInvoice.Bank__r.Branch__c) + '</td>';
        html += '</tr>';

        html += '<tr>';
        html += '<td style="' + leftBorder + '">Currency: ' + ns(proformaInvoice.CurrencyIsoCode) + '</td>';
        html += '<td style="' + borderless + '">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Swift Code: ' + ns(proformaInvoice.Bank__r.SWIFT_Code__c) + '</td>';
        if (!isExport) {
            html += '<td style="' + doubleBorder + '" colspan="2">GSTIN: ' + ns(proformaInvoice.Account_Name__r.GST_No__c) + '</td>';
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
            html += '<td style="' + leftBorder + 'width:36%;">Incoterms: ' + ns(proformaInvoice.Inco_Terms__c) + '</td>';
            html += '<td style="' + borderless + 'width:36%;">Pre-Carriage Mode: ' + ns(proformaInvoice.Pre_Carriage_Mode__c) + '</td>';
            html += '<td style="' + doubleBorder + 'width:27%;" colspan="2">Name: ' + ns(proformaInvoice.Ship_To_Name__c) + '</td>';
            html += '</tr>';

            html += '<tr>';
            html += '<td style="' + leftBorder + '">Country of Origin: ' + ns(proformaInvoice.Country_of_Origin__c) + '</td>';
            html += '<td style="' + borderless + '">Pre-Carriage Destination: ' + ns(proformaInvoice.Pre_Carriage_Destination__c) + '</td>';
            html += '<td style="' + doubleBorder + '" colspan="2" rowspan="5">Address: ' + ns(shippingAddress) + '</td>';
            html += '</tr>';

            html += '<tr><td style="' + leftBorder + '">Country of Destination: ' + ns(proformaInvoice.Country_of_Destination__c) + '</td><td style="' + borderless + '">Vessel/Flight No.: ' + ns(proformaInvoice.Vessel_Flight_No__c) + '</td></tr>';
            html += '<tr><td style="' + leftBorder + '">Final Destination: ' + ns(proformaInvoice.Destination__c) + '</td><td style="' + borderless + '">Loading Port: ' + ns(proformaInvoice.Loading_Port__c) + '</td></tr>';
            html += '<tr><td style="' + leftBorder + '">Place of Supply: ' + ns(proformaInvoice.Place_of_Supplier__c) + '</td><td style="' + borderless + '">Discharge Port: ' + ns(proformaInvoice.Destination_Port__c) + '</td></tr>';
            html += '<tr><td style="' + leftBorder + '">Partial Shipment: ' + ns(proformaInvoice.Partial_Shipment__c) + '</td><td style="' + borderless + '"></td></tr>';
        } else {
            html += '<tr>';
            html += '<td style="' + leftBorder + 'width:36%;">Incoterms: ' + ns(proformaInvoice.Inco_Terms__c) + '</td>';
            html += '<td style="' + borderless + 'width:36%;">Destination: ' + ns(proformaInvoice.Destination__c) + '</td>';
            html += '<td style="' + doubleBorder + 'width:27%;" colspan="2">Name: ' + ns(proformaInvoice.Ship_To_Name__c) + '</td>';
            html += '</tr>';

            html += '<tr><td style="' + leftBorder + '"></td><td style="' + borderless + '"></td><td style="' + doubleBorder + '" colspan="2" rowspan="4">Address: ' + ns(shippingAddress) + '</td></tr>';
            html += '<tr><td style="' + leftBorder + '"></td><td style="' + borderless + '"></td></tr>';
            html += '<tr><td style="' + leftBorder + '"></td><td style="' + borderless + '"></td></tr>';
            html += '<tr><td style="' + leftBorder + '"></td><td style="' + borderless + '"></td></tr>';
            html += '<tr><td style="' + leftBorder + '"></td><td style="' + borderless + '"></td><td style="' + doubleBorder + '" colspan="2">GSTIN: ' + ns(proformaInvoice.Account_Name__r.GST_No__c) + '</td></tr>';
        }
        html += '</table>';

        // Line Items
        html += '<table style="' + tableStyle + '">';
        html += '<tr>';
        html += '<th style="' + borderStyle + 'text-align:center; width:5%;">Sr. No.</th>';
        html += '<th style="' + borderStyle + 'text-align:center; width:12%;">Material Code</th>';
        html += '<th style="' + borderStyle + 'text-align:center; width:10%;">HSN/SAC</th>';
        html += '<th style="' + borderStyle + 'text-align:center; width:23%;">Item Description</th>';
        html += '<th style="' + borderStyle + 'text-align:center; width:8%;">UOM</th>';
        html += '<th style="' + borderStyle + 'text-align:center; width:10%;">Quantity</th>';
        html += '<th style="' + borderStyle + 'text-align:center; width:10%;">List Price</th>';
        html += '<th style="' + borderStyle + 'text-align:center; width:10%;">Sales Price</th>';
        html += '<th style="' + borderStyle + 'text-align:center; width:12%;">Amount</th>';
        html += '</tr>';

        Integer srNo = 1;
        for (Proforma_Invoice_Line_Item__c item : proformaInvoiceLineItems) {
            html += '<tr>';
            html += '<td style="' + borderStyle + 'text-align:center;">' + srNo + '</td>';
            html += '<td style="' + borderStyle + 'text-align:left;">' + ns(item.Product__r.ProductCode) + '</td>';
            html += '<td style="' + borderStyle + 'text-align:center;">' + ns(item.Product__r.HSN__c) + '</td>';
            html += '<td style="' + borderStyle + 'text-align:left;">' + ns(item.Product__c) + '</td>';
            html += '<td style="' + borderStyle + 'text-align:center;">' + ns(item.Product__r.Base_UOM__r.Name) + '</td>';
            html += '<td style="' + borderStyle + 'text-align:right;">' + ns(item.Quantity__c) + '</td>';
            html += '<td style="' + borderStyle + 'text-align:right;">' + ns(item.List_Price__c) + '</td>';
            html += '<td style="' + borderStyle + 'text-align:right;">' + ns(item.Sales_Price__c) + '</td>';
            html += '<td style="' + borderStyle + 'text-align:right;">' + ns(item.Total_Price__c) + '</td>';
            html += '</tr>';
            srNo++;
        }

        // Terms & Totals
        html += '<tr>';
        html += '<td colspan="9" style="' + borderStyle + 'text-align:left; white-space:pre-wrap;"><b>Terms and Conditions:</b><br/>' + ns(proformaInvoice.Terms_and_Conditions__c) + '</td>';
        html += '</tr>';

        html += '<tr>';
        html += '<td colspan="5" style="' + borderStyle + 'text-align:left;"><b>Net Weight</b>: ' + ns(proformaInvoice.Net_weight__c) + '</td>';
        html += '<td colspan="3" style="' + boldStyle + borderStyle + 'text-align:right;">Grand Total</td>';
        html += '<td style="' + borderStyle + 'text-align:right;">' + ns(proformaInvoice.Grand_Total__c) + '</td>';
        html += '</tr>';
        html += '</table>';

        // Amount in Words & Declaration
        html += '<table style="' + tableStyle + '">';
        html += '<tr><td style="text-align:left; ' + borderStyle + 'border-top:none;' + '"><b>Total Amount in Words:</b> ' + ns(totalAmountInWords) + '</td></tr>';
        html += '<tr><td style="text-align:left; ' + borderStyle + '"><b>Declaration</b>: ' + ns(this.proformaInvoice.Declaration__c) + '</td></tr>';
        html += '</table>';

        return html;
    }




    @AuraEnabled
    public static String getEmailBody(String proformaInvoiceId, String type) {
        ProformaInvoicePdfController controller = new ProformaInvoicePdfController(proformaInvoiceId, type);
        return controller.buildEmailContent();
    }

}