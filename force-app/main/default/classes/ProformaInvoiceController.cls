public class ProformaInvoiceController {
    public Id quoteId { get; set; }
    public Boolean showCancelButton { get; set; }
    
    public ProformaInvoiceController() {
        quoteId = ApexPages.currentPage().getParameters().get('quoteId');
        showCancelButton = false;
    }
    
    public PageReference createProformaInvoice() {
        try {
            if (quoteId == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Quote ID is missing.'));
                showCancelButton = false;
                return null;
            }
            
            Quote quote = [
                SELECT Id, Name, Status, AccountId, ContactId, OpportunityId, GrandTotal,
                Inco_Terms__c, Payment_Terms__c, Quote_Document_No__c, ShippingHandling,
                Email, Phone, Quote_Document_Version__c, Partial_Shipment__c,
                ExpirationDate, Description, Revision_No__c, Country_of_Origin__c,
                Country_of_Destination__c, Place_of_Supplier__c, Pre_Carriage_Mode__c,
                Quote_Valid_From__c,Bank__c,Destination__c,BillingCity,BillingState,
                BillingCountry,ShippingStreet,ShippingPostalCode,ShippingCity,
                ShippingName,ShippingState,ShippingCountry,Vessel_Flight_No__c,
                Loading_Port__c, Destination_Port__c,Terms_and_Conditions__c,Declaration__c,
                BillingName,BillingStreet,BillingPostalCode,Pre_Carriage_Destination__c,                
                (SELECT Id, Product2Id, ListPrice, UnitPrice, Quantity, Quality__c, 
                 Previous_Quantity__c, Previous_Sales_Price__c, Reject_Reason__c, 
                 Approver__c, Approval_Status__c, Approval_Comments__c, Subtotal, 
                 Discount, TotalPrice, Description,Status__c
                 FROM QuoteLineItems)
                FROM Quote
                WHERE Id = :quoteId 
            ];
            
         /*    if (quote.QuoteLineItems.isEmpty()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
                                                           'Cannot create Proforma Invoice. No Quote Line Items with "Won" status found.'));
                showCancelButton = true;
                return null;
            }	*/
            
            if (quote.Status != 'Accepted') {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
                                                           'Proforma Invoice can only be created for Accepted Quotes.'));
                showCancelButton = true;
                return null;
            }
            
            List<Proforma_Invoice__c> existingInvoices = [
                SELECT Id FROM Proforma_Invoice__c WHERE Quote__c = :quote.Id LIMIT 1
            ];
            
            if (!existingInvoices.isEmpty()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
                                                           'Proforma Invoice already exists for this Quote.'));
                showCancelButton = true;
                return null;
            }
            
            // Create and populate new Proforma Invoice
            Proforma_Invoice__c invoice = new Proforma_Invoice__c(
                Quote__c = quote.Id,
                Name = quote.Name,
                Opportunity_Name__c = quote.OpportunityId,
                Account_Name__c = quote.AccountId,
                Inco_Terms__c = quote.Inco_Terms__c,
                Payment_Terms__c = quote.Payment_Terms__c,
                Quote_Document_No__c = quote.Quote_Document_No__c,
                Shipping_and_Handling__c = quote.ShippingHandling,
                Contact_Name__c = quote.ContactId,
                Email__c = quote.Email,
                Phone__c = quote.Phone,
                Quote_Document_Version__c = quote.Quote_Document_Version__c,
                Partial_Shipment__c = quote.Partial_Shipment__c,
                Quote_Valid_To__c = quote.ExpirationDate,
                Quote_Valid_From__c = quote.Quote_Valid_From__c,
                Bank__c = quote.Bank__c,
                Status__c = quote.Status,
                Destination__c = quote.Destination__c,
                Description__c = quote.Description,
                Revision_No__c = quote.Revision_No__c,
                Country_of_Origin__c = quote.Country_of_Origin__c,
                Country_of_Destination__c = quote.Country_of_Destination__c,
                Place_of_Supplier__c = quote.Place_of_Supplier__c,
                Pre_Carriage_Mode__c = quote.Pre_Carriage_Mode__c,
                Loading_Port__c = quote.Loading_Port__c,
                Destination_Port__c = quote.Destination_Port__c,
                Grand_Total__c = quote.GrandTotal,
                Terms_and_Conditions__c = quote.Terms_and_Conditions__c,
                Declaration__c = quote.Declaration__c,
                Bill_To_Name__c = quote.BillingName,
                Bill_To_Street__c = quote.BillingStreet,
                Bill_To_Zip_Postal_Code__c = quote.BillingPostalCode,
                Bill_To_City__c = quote.BillingCity,
                Bill_To_State__c = quote.BillingState,
                Bill_To_Country__c = quote.BillingCountry,
                Ship_To_Street__c = quote.ShippingStreet,
                Ship_To_Zip_Postal_Code__c = quote.ShippingPostalCode,
                Ship_To_City__c = quote.ShippingCity,
                Ship_To_Name__c = quote.ShippingName,
                Ship_To_State__c = quote.ShippingState,
                Ship_To_Country__c = quote.ShippingCountry,
                Pre_Carriage_Destination__c = quote.Pre_Carriage_Destination__c,
                Vessel_Flight_No__c = quote.Vessel_Flight_No__c
            );
            insert invoice;
            
            // Create Proforma Line Items
            List<Proforma_Invoice_Line_Item__c> lineItems = new List<Proforma_Invoice_Line_Item__c>();
            for (QuoteLineItem qli : quote.QuoteLineItems) {
                lineItems.add(new Proforma_Invoice_Line_Item__c(
                    Proforma_Invoice_Name__c = invoice.Id,
                    Product__c = qli.Product2Id,
                    List_Price__c = qli.ListPrice,
                    Sales_Price__c = qli.UnitPrice,
                    Quantity__c = qli.Quantity,
                    Quality__c = qli.Quality__c,
                    Previous_Quantity__c = qli.Previous_Quantity__c,
                    Previous_Sales_Price__c = qli.Previous_Sales_Price__c,
                    Reject_Reason__c = qli.Reject_Reason__c,
                    Approver__c = qli.Approver__c,
                    Approval_Status__c = qli.Approval_Status__c,
                    Approval_Comments__c = qli.Approval_Comments__c,
                    Subtotal__c = qli.Subtotal,
                    Discount_Percentage__c = qli.Discount,
                    Total_Price__c = qli.TotalPrice,
                    Line_Item_Description__c = qli.Description
                ));
            }
            
            if (!lineItems.isEmpty()) {
                insert lineItems;
            }
            
            return new PageReference('/' + invoice.Id).setRedirect(true);
            
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
                                                       'Unexpected error: ' + e.getMessage()));
            
            showCancelButton = true;
            return null;
        }
    }
    
    public PageReference cancel() {
        
        return new PageReference('/' + quoteId).setRedirect(true);
        
    }
}