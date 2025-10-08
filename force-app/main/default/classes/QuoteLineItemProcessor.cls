public with sharing class QuoteLineItemProcessor implements Queueable, Database.AllowsCallouts {
    private List<Id> quoteLineItemIds;
    private Integer currentIndex;
    
    // Constructor for initial processing
    public QuoteLineItemProcessor(List<Id> qliIds) {
        this.quoteLineItemIds = qliIds;
        this.currentIndex = 0;
    }
    
    // Constructor for chaining queueable jobs
    public QuoteLineItemProcessor(List<Id> qliIds, Integer currentIndex) {
        this.quoteLineItemIds = qliIds;
        this.currentIndex = currentIndex;
    }
    
    public void execute(QueueableContext context) {
        if (currentIndex >= quoteLineItemIds.size()) {
            return; // All items processed
        }
        
        try {
            // Get the current item to process
            Id currentItemId = quoteLineItemIds[currentIndex];
            
            // Get the item with all required fields
            QuoteLineItem item = [
                SELECT Id, LineNumber, Product2Id, Product2.Name, Product2.ProductCode,
                       Quantity, QuoteId, Quote.SAP_Order_No__c, Quote.Account.SAP_Customer_Code__c
                FROM QuoteLineItem
                WHERE Id = :currentItemId
                LIMIT 1
            ];
            
            // Process the current item
            CreateQuotation_ToSAP.addItem(item);
            
            // If there are more items to process, chain the next job
            if (currentIndex < quoteLineItemIds.size() - 1) {
                System.enqueueJob(new QuoteLineItemProcessor(quoteLineItemIds, currentIndex + 1));
            }
            
        } catch(Exception e) {
            System.debug('Error processing quote line item at index ' + currentIndex + ': ' + 
                        e.getMessage() + '\n' + e.getStackTraceString());
            // Continue with next item even if one fails
            if (currentIndex < quoteLineItemIds.size() - 1) {
                System.enqueueJob(new QuoteLineItemProcessor(quoteLineItemIds, currentIndex + 1));
            }
        }
    }
}