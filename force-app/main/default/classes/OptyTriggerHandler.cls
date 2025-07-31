public class OptyTriggerHandler {
    public static void convertHandler(List<Lead> newRecords, Map<Id, Lead> oldLeadMap) {
        
        System.debug('==== convertHandler called ====');
        
        Map<Id, Id> leadToOppMap = new Map<Id, Id>();
        Map<Id, Id> leadToAccountMap = new Map<Id, Id>();
        
        for (Lead newLead : newRecords) {
            Lead oldLead = oldLeadMap.get(newLead.Id);
            System.debug('Processing Lead: ' + newLead.Id + ' Converted: ' + newLead.IsConverted);
            
            if (newLead.IsConverted && !oldLead.IsConverted) {
                if (newLead.ConvertedOpportunityId != null) {
                    leadToOppMap.put(newLead.Id, newLead.ConvertedOpportunityId);
                    System.debug('Mapped Lead to Opportunity: ' + newLead.Id + ' => ' + newLead.ConvertedOpportunityId);
                }
                if (newLead.ConvertedAccountId != null) {
                    leadToAccountMap.put(newLead.Id, newLead.ConvertedAccountId);
                    System.debug('Mapped Lead to Account: ' + newLead.Id + ' => ' + newLead.ConvertedAccountId);
                }
            }
        }
        
        System.debug('Lead to Opportunity Map: ' + leadToOppMap);
        System.debug('Lead to Account Map: ' + leadToAccountMap);
        
        if (leadToOppMap.isEmpty() && leadToAccountMap.isEmpty()) {
            System.debug('No leads converted, exiting handler.');
            return;
        }

        List<Product_Interested__c> piList = [
            SELECT Id, Product__c, Lead__c, Account__c, Quantity_in_Kgs__c, Expected_Price__c, 
                   Quantity_Frequency__c, Add_in_Opportunity__c
            FROM Product_Interested__c
            WHERE Lead__c IN :leadToAccountMap.keySet()
        ];
        
        System.debug('Product Interested records found: ' + piList.size());
        
        if (piList.isEmpty()) {
            System.debug('No Product Interested found for converted leads.');
            return;
        }

        Set<Id> productIds = new Set<Id>();
        for (Product_Interested__c pi : piList) {
            if (pi.Product__c != null) {
                productIds.add(pi.Product__c);
            }
        }
        System.debug('Product IDs collected: ' + productIds);

        Map<Id, Id> productToPbeMap = new Map<Id, Id>();
        if (!productIds.isEmpty()) {
            for (PricebookEntry pbe : [
                SELECT Id, Product2Id
                FROM PricebookEntry
                WHERE IsActive = true AND Pricebook2.IsStandard = true AND Product2Id IN :productIds
            ]) {
                productToPbeMap.put(pbe.Product2Id, pbe.Id);
            }
        }
        System.debug('PricebookEntry Map: ' + productToPbeMap);

        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
        List<Product_Interested__c> piToUpdateList = new List<Product_Interested__c>();
        
        for (Product_Interested__c pi : piList) {
            Id oppId = leadToOppMap.get(pi.Lead__c);
            Id acctId = leadToAccountMap.get(pi.Lead__c);

            System.debug('Processing Product_Interested__c: ' + pi.Id + ' OppId: ' + oppId + ' AcctId: ' + acctId);

            if (pi.Add_in_Opportunity__c == true && oppId != null && productToPbeMap.containsKey(pi.Product__c)) {
                OpportunityLineItem oli = new OpportunityLineItem();
                oli.OpportunityId = oppId;
                oli.PricebookEntryId = productToPbeMap.get(pi.Product__c);
                oli.Product2Id = pi.Product__c;
                oli.UnitPrice = pi.Expected_Price__c;
                oli.Quantity = pi.Quantity_in_Kgs__c;
                oli.Quantity_Frequency__c = pi.Quantity_Frequency__c;
                oliList.add(oli);

                System.debug('Added OpportunityLineItem for Product_Interested__c: ' + pi.Id);
            }

            if (acctId != null && (pi.Account__c == null || pi.Account__c != acctId)) {
                pi.Account__c = acctId;
                piToUpdateList.add(pi);

                System.debug('Prepared to update Product_Interested__c Account__c: ' + pi.Id + ' => ' + acctId);
            }
        }

        if (!oliList.isEmpty()) {
            insert oliList;
            System.debug('Inserted OpportunityLineItems: ' + oliList.size());
        } else {
            System.debug('No OpportunityLineItems to insert.');
        }

        if (!piToUpdateList.isEmpty()) {
            update piToUpdateList;
            System.debug('Updated Product_Interested__c records linked to Account: ' + piToUpdateList.size());
        } else {
            System.debug('No Product_Interested__c records needed Account update.');
        }

        System.debug('==== convertHandler completed ====');
    }
    
     public static void handleLeadConversionOpportunities(List<Opportunity> newOpportunities) {
        // Get converted opportunity IDs from the Lead object
        Set<Id> convertedOppIds = getConvertedOpportunityIds(newOpportunities);
        
        if (!convertedOppIds.isEmpty()) {
            updateConvertedOpportunities(convertedOppIds);
        }
    }
    
    // Query Lead records to find which ones were converted to these opportunities
    private static Set<Id> getConvertedOpportunityIds(List<Opportunity> opportunities) {
        Set<Id> opportunityIds = new Set<Id>();
        for (Opportunity opp : opportunities) {
            opportunityIds.add(opp.Id);
        }
        
        Set<Id> convertedOppIds = new Set<Id>();
        // Add debug logs to verify query results
        System.debug('Checking for converted opportunities with IDs: ' + opportunityIds);
        
        for (Lead lead : [
            SELECT Id, ConvertedOpportunityId 
            FROM Lead 
            WHERE ConvertedOpportunityId IN :opportunityIds
            AND IsConverted = true
        ]) {
            System.debug('Found converted lead with OpportunityId: ' + lead.ConvertedOpportunityId);
            convertedOppIds.add(lead.ConvertedOpportunityId);
        }
        
        System.debug('Total converted opportunities found: ' + convertedOppIds.size());
        return convertedOppIds;
    }
    
    // Update the opportunities with the conversion flag
    private static void updateConvertedOpportunities(Set<Id> opportunityIds) {
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        
        for (Id oppId : opportunityIds) {
            opportunitiesToUpdate.add(new Opportunity(
                Id = oppId,
                Created_via_Lead_Conversion__c = true
            ));
        }
        
        if (!opportunitiesToUpdate.isEmpty()) {
            System.debug('Updating ' + opportunitiesToUpdate.size() + ' opportunities');
            // Using Database.update with opt_allOrNone=false for partial success handling
            Database.SaveResult[] results = Database.update(opportunitiesToUpdate, false);
            
            // Log any errors
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    System.debug('Error updating opportunity: ' + opportunitiesToUpdate[i].Id + 
                               ' - ' + results[i].getErrors());
                }
            }
        }
    }
}