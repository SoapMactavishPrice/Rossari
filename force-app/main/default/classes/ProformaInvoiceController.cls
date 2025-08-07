public class ProformaInvoiceController {
    public Id quoteId { get; set; }

    public ProformaInvoiceController() {
        quoteId = ApexPages.currentPage().getParameters().get('quoteId');
    }

    public PageReference createProformaInvoice() {
        try {
            if (quoteId == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Quote ID is missing.'));
                return null;
            }

            Quote quote = [
                SELECT Id, Name, Status, AccountId, ContactId, OpportunityId, GrandTotal,
                       Inco_Terms__c, Payment_Terms__c, Quote_Document_No__c, ShippingHandling,
                       Email, Phone, Quote_Document_Version__c, Partial_Shipment__c,
                       ExpirationDate, Description, Revision_No__c, Country_of_Origin__c,
                       Country_of_Destination__c, Place_of_Supplier__c, Pre_Carriage_Mode__c,
                       Loading_Port__c, Destination_Port__c,
                       (SELECT Id, Product2Id, ListPrice, UnitPrice, Quantity, Quality__c, 
                               Previous_Quantity__c, Previous_Sales_Price__c, Reject_Reason__c, 
                               Approver__c, Approval_Status__c, Approval_Comments__c, Subtotal, 
                               Discount, TotalPrice, Description
                        FROM QuoteLineItems)
                FROM Quote
                WHERE Id = :quoteId
            ];

            if (quote.Status != 'Accepted') {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
                    'Proforma Invoice can only be created for Accepted Quotes.'));
                return null;
            }

            List<Proforma_Invoice__c> existingInvoices = [
                SELECT Id FROM Proforma_Invoice__c WHERE Quote__c = :quote.Id LIMIT 1
            ];

            if (!existingInvoices.isEmpty()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
                    'Proforma Invoice already exists for this Quote.'));
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
                Status__c = quote.Status,
                Description__c = quote.Description,
                Revision_No__c = quote.Revision_No__c,
                Country_of_Origin__c = quote.Country_of_Origin__c,
                Country_of_Destination__c = quote.Country_of_Destination__c,
                Place_of_Supplier__c = quote.Place_of_Supplier__c,
                Pre_Carriage_Mode__c = quote.Pre_Carriage_Mode__c,
                Loading_Port__c = quote.Loading_Port__c,
                Destination_Port__c = quote.Destination_Port__c,
                Grand_Total__c = quote.GrandTotal
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
            return null;
        }
    }
}