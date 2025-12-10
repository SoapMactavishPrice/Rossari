public with sharing class ProformaInvoiceControllerLWC {
    
    // Data wrapper class
    public class LineItemData {
        @AuraEnabled public String quoteLineItemId;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public String productId;
        @AuraEnabled public Decimal unitPrice;
    }
    
    // Result wrapper class
    public class ResultWrapper {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String error;
        @AuraEnabled public String proformaInvoiceId;
    }
    
    // Get quote details with line items
    @AuraEnabled
    public static Map<String, Object> getQuoteDetails(Id quoteId) {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            List<Map<String, Object>> lineItems = new List<Map<String, Object>>();
            
            // Query quote line items
            List<QuoteLineItem> qlis = [
                SELECT Id, Product2Id, Product2.Name, Quantity, UnitPrice, 
                       PI_Quantity__c, Remaining_Quantity__c, Description,
                       ListPrice, Quality__c, Container_Type__c,
                       Customer_Product_Name__c, Customer_Target_Price__c,
                       Total_Price__c
                FROM QuoteLineItem 
                WHERE QuoteId = :quoteId 
                ORDER BY CreatedDate
            ];
            
            // Get all active Proforma Invoices for this quote and their line items
            Map<Id, Decimal> productToTotalPIQuantity = new Map<Id, Decimal>();
            
            List<Proforma_Invoice__c> proformaInvoices = [
                SELECT Id, 
                    (SELECT Id, Product__c, Quantity__c 
                     FROM Proforma_Invoice_Line_Item__r)
                FROM Proforma_Invoice__c 
                WHERE Quote__c = :quoteId
            ];
            
            // Calculate total PI quantity for each product
            for (Proforma_Invoice__c pi : proformaInvoices) {
                for (Proforma_Invoice_Line_Item__c piItem : pi.Proforma_Invoice_Line_Item__r) {
                    if (piItem.Product__c != null) {
                        Decimal currentTotal = productToTotalPIQuantity.get(piItem.Product__c) != null ? 
                            productToTotalPIQuantity.get(piItem.Product__c) : 0;
                        productToTotalPIQuantity.put(piItem.Product__c, currentTotal + piItem.Quantity__c);
                    }
                }
            }
            
            // Also sync the PI_Quantity__c fields with actual data
            List<QuoteLineItem> qlisToUpdate = new List<QuoteLineItem>();
            for (QuoteLineItem qli : qlis) {
                if (qli.Product2Id != null && productToTotalPIQuantity.containsKey(qli.Product2Id)) {
                    Decimal actualPIQty = productToTotalPIQuantity.get(qli.Product2Id);
                    if (qli.PI_Quantity__c != actualPIQty) {
                        qli.PI_Quantity__c = actualPIQty;
                        qlisToUpdate.add(qli);
                    }
                } else if (qli.Product2Id != null && qli.PI_Quantity__c != null && qli.PI_Quantity__c > 0) {
                    // If no proforma invoices exist but PI_Quantity__c has value, reset it
                    qli.PI_Quantity__c = 0;
                    qlisToUpdate.add(qli);
                }
            }
            
            if (!qlisToUpdate.isEmpty()) {
                update qlisToUpdate;
            }
            
            // Prepare line items data for LWC
            for (QuoteLineItem qli : qlis) {
                // Calculate actual PI quantity from existing Proforma Invoices
                Decimal actualPIQuantity = 0;
                if (qli.Product2Id != null && productToTotalPIQuantity.containsKey(qli.Product2Id)) {
                    actualPIQuantity = productToTotalPIQuantity.get(qli.Product2Id);
                }
                
                // Calculate remaining quantity
                Decimal remainingQuantity = qli.Quantity - actualPIQuantity;
                
                lineItems.add(new Map<String, Object>{
                    'quoteLineItemId' => qli.Id,
                    'productId' => qli.Product2Id,
                    'productName' => qli.Product2.Name,
                    'quoteQuantity' => qli.Quantity,
                    'piQuantity' => actualPIQuantity, // Use calculated value
                    'remainingQuantity' => remainingQuantity,
                    'unitPrice' => qli.UnitPrice,
                    'description' => qli.Description,
                    'totalPrice' => qli.Total_Price__c
                });
            }
            
            result.put('success', true);
            result.put('lineItems', lineItems);
            
        } catch (Exception e) {
            result.put('success', false);
            result.put('error', 'Error loading quote details: ' + e.getMessage());
        }
        
        return result;
    }
    
    // Create proforma invoice
    @AuraEnabled
    public static ResultWrapper createProformaInvoice(Id quoteId, List<Map<String, Object>> lineItemsData, 
                                                      String referenceNumber, String piDate, String notes) {
        ResultWrapper result = new ResultWrapper();
        result.success = false;
        
        Savepoint sp = Database.setSavepoint();
        
        try {
            if (quoteId == null) {
                result.error = 'Quote ID is missing.';
                return result;
            }
            
            if (lineItemsData == null || lineItemsData.isEmpty()) {
                result.error = 'No line items selected.';
                return result;
            }
            
            // Get quote details
            Quote quote = [
                SELECT Id, Name, Status, AccountId, ContactId, OpportunityId, GrandTotal,
                       Inco_Terms__c, Payment_Terms__c, Quote_Document_No__c, ShippingHandling,
                       Email, Phone, Quote_Document_Version__c, Partial_Shipment__c,
                       ExpirationDate, Description, Revision_No__c, Country_of_Origin__c,
                       Country_of_Destination__c, Place_of_Supplier__c, Pre_Carriage_Mode__c,
                       Quote_Valid_From__c, Bank__c, Destination__c, BillingCity, BillingState,
                       BillingCountry, ShippingStreet, ShippingPostalCode, ShippingCity,
                       ShippingName, ShippingState, ShippingCountry, Vessel_Flight_No__c,
                       Grand_Total__c, Transportation_Cost__c, Loading_Port__c, 
                       Destination_Port__c, Terms_and_Conditions__c, Declaration__c,
                       BillingName, BillingStreet, BillingPostalCode, Pre_Carriage_Destination__c,
                       Payment_Term__c, (SELECT Id, Product2Id, Quantity, UnitPrice, PI_Quantity__c 
                                         FROM QuoteLineItems)
                FROM Quote 
                WHERE Id = :quoteId 
                LIMIT 1
            ];
            
            // Generate PI number
            String piNumber;
            if (quote.Quote_Document_No__c != null) {
                // Get existing PI count for this quote
                Integer existingPICount = [SELECT COUNT() FROM Proforma_Invoice__c 
                                          WHERE Quote__c = :quoteId];
                piNumber = quote.Quote_Document_No__c + '-PI-' + (existingPICount + 1);
            } else {
                piNumber = 'PI-' + System.now().format('yyyyMMdd');
            }
            
            // Create Proforma Invoice - use existing fields
            Proforma_Invoice__c invoice = new Proforma_Invoice__c(
                Quote__c = quote.Id,
                Name = piNumber,
                // Use Description__c to store notes if you don't have specific fields
                Description__c = (String.isNotBlank(notes) ? 'Notes: ' + notes + '\n' : '') +
                                (String.isNotBlank(referenceNumber) ? 'Reference: ' + referenceNumber : ''),
                Opportunity_Name__c = quote.OpportunityId,
                Account_Name__c = quote.AccountId,
                Inco_Terms__c = quote.Inco_Terms__c,
                Payment_Term__c = quote.Payment_Term__c,
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
                Revision_No__c = quote.Revision_No__c,
                Country_of_Origin__c = quote.Country_of_Origin__c,
                Country_of_Destination__c = quote.Country_of_Destination__c,
                Place_of_Supplier__c = quote.Place_of_Supplier__c,
                Pre_Carriage_Mode__c = quote.Pre_Carriage_Mode__c,
                Loading_Port__c = quote.Loading_Port__c,
                Destination_Port__c = quote.Destination_Port__c,
                Grand_Total__c = 0, // Will be calculated from line items
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
                Vessel_Flight_No__c = quote.Vessel_Flight_No__c,
                Transportation_Cost__c = quote.Transportation_Cost__c
            );
            
            // If you have custom fields for date and reference, add them here
            // Example if you have fields: PI_Date__c and PI_Reference_Number__c
            /*
            if (String.isNotBlank(piDate)) {
                invoice.PI_Date__c = Date.valueOf(piDate);
            }
            if (String.isNotBlank(referenceNumber)) {
                invoice.PI_Reference_Number__c = referenceNumber;
            }
            */
            
            insert invoice;
            
            // Create map for quick lookup
            Map<Id, QuoteLineItem> qliMap = new Map<Id, QuoteLineItem>();
            for (QuoteLineItem qli : quote.QuoteLineItems) {
                qliMap.put(qli.Id, qli);
            }
            
            // Create Proforma Invoice Line Items
            List<Proforma_Invoice_Line_Item__c> piLineItems = new List<Proforma_Invoice_Line_Item__c>();
            Decimal grandTotal = 0;
            List<QuoteLineItem> qlisToUpdate = new List<QuoteLineItem>();
            
            for (Map<String, Object> itemData : lineItemsData) {
                String qliId = (String)itemData.get('quoteLineItemId');
                Decimal quantity = (Decimal)itemData.get('quantity');
                
                if (quantity <= 0) continue;
                
                QuoteLineItem qli = qliMap.get(qliId);
                
                if (qli != null) {
                    // Create PI line item
                    Proforma_Invoice_Line_Item__c piLineItem = new Proforma_Invoice_Line_Item__c(
                        Proforma_Invoice_Name__c = invoice.Id,
                        Product__c = (String)itemData.get('productId'),
                        Sales_Price__c = (Decimal)itemData.get('unitPrice'),
                        Quantity__c = quantity,
                        Total_Price__c = quantity * (Decimal)itemData.get('unitPrice')
                    );
                    piLineItems.add(piLineItem);
                    
                    // Calculate grand total
                    grandTotal += quantity * (Decimal)itemData.get('unitPrice');
                    
                    // Update QLI PI quantities - Remaining_Quantity__c will auto-update via formula
                    Decimal currentPIQty = qli.PI_Quantity__c != null ? qli.PI_Quantity__c : 0;
                    qli.PI_Quantity__c = currentPIQty + quantity;
                    qlisToUpdate.add(qli);
                }
            }
            
            if (!piLineItems.isEmpty()) {
                insert piLineItems;
                
                // Update quote line items
                if (!qlisToUpdate.isEmpty()) {
                    update qlisToUpdate;
                }
                
                // Update invoice grand total
                invoice.Grand_Total__c = grandTotal;
                update invoice;
                
                result.success = true;
                result.proformaInvoiceId = invoice.Id;
            } else {
                result.error = 'No valid line items to create.';
                Database.rollback(sp);
            }
            
        } catch (Exception e) {
            result.error = 'Error creating Proforma Invoice: ' + e.getMessage() + 
                          ' Line: ' + e.getLineNumber();
            Database.rollback(sp);
        }
        
        return result;
    }
    
    // Method to delete a Proforma Invoice and update PI quantities
    @AuraEnabled
    public static ResultWrapper deleteProformaInvoice(Id proformaInvoiceId) {
        ResultWrapper result = new ResultWrapper();
        result.success = false;
        
        Savepoint sp = Database.setSavepoint();
        
        try {
            if (proformaInvoiceId == null) {
                result.error = 'Proforma Invoice ID is missing.';
                return result;
            }
            
            // Get the Proforma Invoice with its line items
            Proforma_Invoice__c invoice = [
                SELECT Id, Quote__c, 
                    (SELECT Id, Product__c, Quantity__c 
                     FROM Proforma_Invoice_Line_Item__r)
                FROM Proforma_Invoice__c 
                WHERE Id = :proformaInvoiceId
                LIMIT 1
            ];
            
            Id quoteId = invoice.Quote__c;
            
            // Group quantities by product from the deleted invoice
            Map<Id, Decimal> productQuantities = new Map<Id, Decimal>();
            for (Proforma_Invoice_Line_Item__c item : invoice.Proforma_Invoice_Line_Item__r) {
                if (item.Product__c != null) {
                    Decimal currentTotal = productQuantities.containsKey(item.Product__c) ? 
                        productQuantities.get(item.Product__c) : 0;
                    productQuantities.put(item.Product__c, currentTotal + item.Quantity__c);
                }
            }
            
            // Get all QuoteLineItems for the quote
            List<QuoteLineItem> qlis = [
                SELECT Id, Product2Id, Quantity, PI_Quantity__c
                FROM QuoteLineItem
                WHERE QuoteId = :quoteId
                AND Product2Id IN :productQuantities.keySet()
            ];
            
            // Update PI_Quantity__c on QuoteLineItems
            List<QuoteLineItem> qlisToUpdate = new List<QuoteLineItem>();
            for (QuoteLineItem qli : qlis) {
                if (productQuantities.containsKey(qli.Product2Id)) {
                    Decimal quantityToDeduct = productQuantities.get(qli.Product2Id);
                    Decimal currentPIQty = qli.PI_Quantity__c != null ? qli.PI_Quantity__c : 0;
                    
                    // Deduct the deleted quantity
                    qli.PI_Quantity__c = Math.max(0, currentPIQty - quantityToDeduct);
                    qlisToUpdate.add(qli);
                }
            }
            
            // Delete the Proforma Invoice (this will cascade delete line items)
            delete invoice;
            
            // Update QuoteLineItems
            if (!qlisToUpdate.isEmpty()) {
                update qlisToUpdate;
            }
            
            result.success = true;
            result.error = 'Proforma Invoice deleted successfully. PI quantities updated.';
            
        } catch (Exception e) {
            result.error = 'Error deleting Proforma Invoice: ' + e.getMessage();
            Database.rollback(sp);
        }
        
        return result;
    }
    
    // Method to fix all PI quantities for a quote (use if data is already inconsistent)
    @AuraEnabled
    public static ResultWrapper fixPIQuantities(Id quoteId) {
        ResultWrapper result = new ResultWrapper();
        result.success = false;
        
        Savepoint sp = Database.setSavepoint();
        
        try {
            if (quoteId == null) {
                result.error = 'Quote ID is missing.';
                return result;
            }
            
            // Get all QuoteLineItems for this quote
            List<QuoteLineItem> qlis = [
                SELECT Id, Product2Id, Quantity, PI_Quantity__c
                FROM QuoteLineItem 
                WHERE QuoteId = :quoteId
            ];
            
            if (qlis.isEmpty()) {
                result.success = true;
                result.error = 'No line items found for this quote.';
                return result;
            }
            
            // Get all active Proforma Invoices for this quote
            Map<Id, Decimal> productToTotalPIQuantity = new Map<Id, Decimal>();
            
            List<Proforma_Invoice__c> proformaInvoices = [
                SELECT Id, 
                    (SELECT Id, Product__c, Quantity__c 
                     FROM Proforma_Invoice_Line_Item__r)
                FROM Proforma_Invoice__c 
                WHERE Quote__c = :quoteId
            ];
            
            // Calculate actual PI quantity for each product
            for (Proforma_Invoice__c pi : proformaInvoices) {
                for (Proforma_Invoice_Line_Item__c piItem : pi.Proforma_Invoice_Line_Item__r) {
                    if (piItem.Product__c != null) {
                        Decimal currentTotal = productToTotalPIQuantity.get(piItem.Product__c) != null ? 
                            productToTotalPIQuantity.get(piItem.Product__c) : 0;
                        productToTotalPIQuantity.put(piItem.Product__c, currentTotal + piItem.Quantity__c);
                    }
                }
            }
            
            // Update QuoteLineItems with correct PI_Quantity__c values
            List<QuoteLineItem> qlisToUpdate = new List<QuoteLineItem>();
            
            for (QuoteLineItem qli : qlis) {
                if (qli.Product2Id != null) {
                    Decimal actualPIQuantity = productToTotalPIQuantity.get(qli.Product2Id) != null ? 
                        productToTotalPIQuantity.get(qli.Product2Id) : 0;
                    
                    // Only update if values are different
                    if (qli.PI_Quantity__c != actualPIQuantity) {
                        qli.PI_Quantity__c = actualPIQuantity;
                        qlisToUpdate.add(qli);
                    }
                }
            }
            
            if (!qlisToUpdate.isEmpty()) {
                update qlisToUpdate;
                result.success = true;
                result.error = 'Successfully fixed PI quantities for ' + qlisToUpdate.size() + ' line items.';
            } else {
                result.success = true;
                result.error = 'All PI quantities are already correct.';
            }
            
        } catch (Exception e) {
            result.error = 'Error fixing PI quantities: ' + e.getMessage();
            Database.rollback(sp);
        }
        
        return result;
    }
}