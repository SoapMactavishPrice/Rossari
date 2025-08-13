public class OpportunityTriggerHandler {
    
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
    
    @future
    public static void markConvertedOpportunitiesFuture(Set<Id> opportunityIds) {
        
        // Wait briefly to ensure conversion completes
        Long startTime = DateTime.now().getTime();
        Long maxWaitTime = 5000; // 5 second max wait
        Boolean recordsFound = false;
        
        while (!recordsFound && DateTime.now().getTime() - startTime < maxWaitTime) {
            List<Lead> convertedLeads = [
                SELECT ConvertedOpportunityId 
                FROM Lead 
                WHERE ConvertedOpportunityId IN :opportunityIds
                AND IsConverted = true
                LIMIT 1
            ];
            
            if (!convertedLeads.isEmpty()) {
                recordsFound = true;
            } else {
                // Brief pause before retrying
                Long waitTime = Math.min(1000, maxWaitTime - (DateTime.now().getTime() - startTime));
                if (waitTime > 0) {
                    doWait(waitTime);
                }
            }
        }
        
        // Now process all matching records
        Set<Id> convertedOppIds = new Set<Id>();
        for (Lead lead : [
            SELECT ConvertedOpportunityId 
            FROM Lead 
            WHERE ConvertedOpportunityId IN :opportunityIds
            AND IsConverted = true
        ]) {
            convertedOppIds.add(lead.ConvertedOpportunityId);
        }
        
        if (!convertedOppIds.isEmpty()) {
            List<Opportunity> oppsToUpdate = new List<Opportunity>();
            for (Id oppId : convertedOppIds) {
                oppsToUpdate.add(new Opportunity(
                    Id = oppId,
                    Created_via_Lead_Conversion__c = true
                ));
            }
            update oppsToUpdate;
        }
    }
    
    private static void doWait(Long milliseconds) {
        Long start = DateTime.now().getTime();
        while (DateTime.now().getTime() - start < milliseconds) {
            // Busy wait - can't use Sleep in Apex
        }
    }
    
    public static void setStandardPricebook(List<Opportunity> newOpps) {
        // Query Standard Pricebook once
        Pricebook2 standardPB = [SELECT Id FROM Pricebook2 WHERE IsStandard = true AND IsActive = true LIMIT 1];
        
        for (Opportunity opp : newOpps) {
            if (opp.Pricebook2Id == null) {
                opp.Pricebook2Id = standardPB.Id;
            }
        }
    }
    
    @AuraEnabled
    public static List<String> getLostReasonPicklist() {
        List<String> options = new List<String>();
        Schema.DescribeFieldResult fieldResult = Opportunity.Loss_Reason__c.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        
        for (Schema.PicklistEntry entry : picklistValues) {
            if (entry.isActive()) {
                options.add(entry.getLabel());
            }
        }
        return options;
    }
    
    @AuraEnabled
    public static void updateOpportunityStatus(Map<String, Object> opportunityData) {
        try {
            
            Date followUpDate = null;
            if (opportunityData.get('nextFollowUp') != null) {
                followUpDate = Date.valueOf(String.valueOf(opportunityData.get('nextFollowUp')));
            }
            
            
            Opportunity oppToUpdate = new Opportunity(
                Id = (Id)opportunityData.get('opportunityId'),
                StageName = 'Closed Lost',
                Loss_Reason__c = (String)opportunityData.get('lostReason'),
                Notes__c = (String)opportunityData.get('note'),
                //   CloseDate = System.today(),
                Next_Follow_Up__c = followUpDate
            );
            
            if ('Lost to Competitor'.equals(opportunityData.get('lostReason'))) {
                oppToUpdate.Competitor_Lost_to1__c = (Id)opportunityData.get('competitorLostTo');
                oppToUpdate.Competitor_Price__c = (String)opportunityData.get('competitorPrice');
                oppToUpdate.Competitor_Product__c = (String)opportunityData.get('competitorProduct');
            } else if ('Others'.equals(opportunityData.get('lostReason'))) {
                if (opportunityData.containsKey('otherReasons') && opportunityData.get('otherReasons') != null) {
                    oppToUpdate.Other_Reasons__c = (String)opportunityData.get('otherReasons');
                } else {
                    throw new AuraHandledException('Other Reasons are required when selecting "Others" as the lost reason');
                }
            }
            
            update oppToUpdate;
        } catch (Exception e) {
            System.debug('Error updating opportunity: ' + e.getMessage());
            throw new AuraHandledException('Error updating opportunity: ' + e.getMessage());
        }
    }
    
    public static void handleFollowUpTask(List<Opportunity> newOpps, Map<Id, Opportunity> oldMap) {
        List<Task> tasksToInsert = new List<Task>();
        List<Task> tasksToUpdate = new List<Task>();
        Map<Id, Task> oppTaskMap = new Map<Id, Task>();
        
        // Collect Opportunity IDs where Next_Follow_Up__c is populated/changed
        Set<Id> oppIds = new Set<Id>();
        for (Opportunity opp : newOpps) {
            if (opp.Next_Follow_Up__c != null && 
                (oldMap == null || // for insert
                 oldMap.get(opp.Id).Next_Follow_Up__c != opp.Next_Follow_Up__c)) {
                     oppIds.add(opp.Id);
                 }
        }
        
        if (oppIds.isEmpty()) return;
        
        // Query existing tasks only for relevant Opportunities
        for (Task t : [SELECT Id, WhatId, Subject, ActivityDate 
                       FROM Task 
                       WHERE WhatId IN :oppIds 
                       AND Subject = 'Follow Up Task']) {
                           oppTaskMap.put(t.WhatId, t);
                       }
        
        // Create or update tasks
        for (Opportunity opp : newOpps) {
            if (!oppIds.contains(opp.Id)) continue;
            
            Date followUpDate = opp.Next_Follow_Up__c;
            
            if (oppTaskMap.containsKey(opp.Id)) {
                Task existingTask = oppTaskMap.get(opp.Id);
                if (existingTask.ActivityDate != followUpDate) {
                    existingTask.ActivityDate = followUpDate;
                    existingTask.Description = 'Opportunity follow-up.';
                    tasksToUpdate.add(existingTask);
                }
            } else {
                tasksToInsert.add(new Task(
                    WhatId = opp.Id,
                    Subject = 'Follow Up Task',
                    ActivityDate = followUpDate,
                    Status = 'Not Started',
                    Priority = 'Normal',
                    Description = 'Opportunity follow-up',
                    OwnerId = opp.OwnerId // Important - assign to opportunity owner
                ));
            }
        }
        
        try {
            if (!tasksToInsert.isEmpty()) insert tasksToInsert;
            if (!tasksToUpdate.isEmpty()) update tasksToUpdate;
        } catch (Exception e) {
            System.debug('Error creating/updating follow-up tasks: ' + e.getMessage());
        }
    }
}