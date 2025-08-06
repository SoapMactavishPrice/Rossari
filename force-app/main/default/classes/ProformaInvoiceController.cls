public class ProformaInvoiceController {
    public Id quoteId { get; set; }
    
    public ProformaInvoiceController() {
        quoteId = ApexPages.currentPage().getParameters().get('quoteId');
    }
    
    public PageReference createProformaInvoice() {
        // Fetch the Quote and its Line Items
        Quote quote = [
            SELECT Id, Name, AccountId, ContactId, OpportunityId, Inco_Terms__c, 
            Payment_Terms__c, Quote_Document_No__c, ShippingHandling, 
            Email, Phone, Quote_Document_Version__c, Partial_Shipment__c,
            ExpirationDate, Status, Description, Revision_No__c, 
            Country_of_Origin__c, Country_of_Destination__c, 
            Place_of_Supplier__c, Pre_Carriage_Mode__c, 
            Loading_Port__c, Destination_Port__c,GrandTotal,
            (SELECT Id, Product2Id, ListPrice, UnitPrice, 
             Quantity, Quality__c, Previous_Quantity__c,
             Previous_Sales_Price__c,Reject_Reason__c,
             Approver__c, Approval_Status__c, Approval_Comments__c,
             Subtotal, Discount, TotalPrice, Description
             FROM QuoteLineItems) 
            FROM Quote 
            WHERE Id = :quoteId
        ];
        
        // Check if a Proforma Invoice already exists
        List<Proforma_Invoice__c> existingInvoices = [
            SELECT Id 
            FROM Proforma_Invoice__c 
            WHERE Quote__c = :quote.Id
        ];
        
        Proforma_Invoice__c proformaInvoice;
        
        if (existingInvoices.isEmpty()) {
            proformaInvoice = new Proforma_Invoice__c(Quote__c = quote.Id);
        } else {
            proformaInvoice = existingInvoices[0];
        }
        
        // Map Quote fields to Proforma Invoice
        proformaInvoice.Name = quote.Name;
        proformaInvoice.Opportunity_Name__c = quote.OpportunityId;
        proformaInvoice.Account_Name__c = quote.AccountId;
        proformaInvoice.Inco_Terms__c = quote.Inco_Terms__c;
        proformaInvoice.Payment_Terms__c = quote.Payment_Terms__c;
        proformaInvoice.Quote_Document_No__c = quote.Quote_Document_No__c;
        proformaInvoice.Shipping_and_Handling__c = quote.ShippingHandling;
        proformaInvoice.Contact_Name__c = quote.ContactId;
        proformaInvoice.Email__c = quote.Email;
        proformaInvoice.Phone__c = quote.Phone;
        proformaInvoice.Quote_Document_Version__c = quote.Quote_Document_Version__c;
        proformaInvoice.Partial_Shipment__c = quote.Partial_Shipment__c;
        proformaInvoice.Quote_Valid_To__c = quote.ExpirationDate;
        proformaInvoice.Status__c = quote.Status;
        proformaInvoice.Description__c = quote.Description;
        proformaInvoice.Revision_No__c = quote.Revision_No__c;
        proformaInvoice.Country_of_Origin__c = quote.Country_of_Origin__c;
        proformaInvoice.Country_of_Destination__c = quote.Country_of_Destination__c;
        proformaInvoice.Place_of_Supplier__c = quote.Place_of_Supplier__c;
        proformaInvoice.Pre_Carriage_Mode__c = quote.Pre_Carriage_Mode__c;
        proformaInvoice.Loading_Port__c = quote.Loading_Port__c;
        proformaInvoice.Destination_Port__c = quote.Destination_Port__c;
        proformaInvoice.Grand_Total__c = quote.GrandTotal;
        
        upsert proformaInvoice;
        
        // Delete existing line items
        List<Proforma_Invoice_Line_Item__c> existingLineItems = [
            SELECT Id 
            FROM Proforma_Invoice_Line_Item__c 
            WHERE Proforma_Invoice_Name__c = :proformaInvoice.Id
        ];
        if (!existingLineItems.isEmpty()) {
            delete existingLineItems;
        }
        
        // Create new line items
        List<Proforma_Invoice_Line_Item__c> proformaLineItems = new List<Proforma_Invoice_Line_Item__c>();
        for (QuoteLineItem qli : quote.QuoteLineItems) {
            Proforma_Invoice_Line_Item__c pili = new Proforma_Invoice_Line_Item__c();
            pili.Proforma_Invoice_Name__c = proformaInvoice.Id;
            pili.Product__c = qli.Product2Id;
            pili.List_Price__c = qli.ListPrice;
            pili.Sales_Price__c = qli.UnitPrice;
            pili.Total_Price__c = qli.TotalPrice;
            pili.Quantity__c = qli.Quantity;
            pili.Quality__c = qli.Quality__c;
            pili.Previous_Quantity__c = qli.Previous_Quantity__c;
            pili.Previous_Sales_Price__c = qli.Previous_Sales_Price__c;
            pili.Reject_Reason__c = qli.Reject_Reason__c;
            pili.Approver__c = qli.Approver__c;
            pili.Approval_Status__c = qli.Approval_Status__c;
            pili.Approval_Comments__c = qli.Approval_Comments__c;
            pili.Subtotal__c = qli.Subtotal;
            pili.Discount_Percentage__c = qli.Discount;
            pili.Total_Price__c = qli.TotalPrice;
            pili.Line_Item_Description__c = qli.Description;
            
            proformaLineItems.add(pili);
        }
        
        if (!proformaLineItems.isEmpty()) {
            insert proformaLineItems;
        }
        
        // Redirect to the Proforma Invoice record page
        return new PageReference('/' + proformaInvoice.Id).setRedirect(true);
    }
}