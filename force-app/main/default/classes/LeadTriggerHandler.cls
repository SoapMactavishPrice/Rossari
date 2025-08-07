public class LeadTriggerHandler {
    
    public static void updateLeadAddresses(List<Lead> newLeads) {
        Set<Id> postalCodeIds = new Set<Id>();
        Set<Id> cityIds = new Set<Id>();
        Set<Id> stateIds = new Set<Id>();
        
        for (Lead lead : newLeads) {
            if (lead.Pin_Code__c != null) {
                postalCodeIds.add(lead.Pin_Code__c);
            }
            if (lead.City__c != null) {
                cityIds.add(lead.City__c);
            }
            if (lead.State__c != null) {
                stateIds.add(lead.State__c);
            }
        }
        
        Map<Id, Pin_Code__c> postalCodeMap = new Map<Id, Pin_Code__c>(
            [SELECT Id, City__c, City__r.State__c, 
             City__r.State__r.Country__c,
             City__r.State__r.Zone__c,
             City__r.State__r.Country__r.Region__c
             FROM Pin_Code__c
             WHERE Id IN :postalCodeIds]
        );
        
        Map<Id, City__c> cityMap = new Map<Id, City__c>(
            [SELECT Id, State__c,
             State__r.Country__c,
             State__r.Zone__c,
             State__r.Country__r.Region__c
             FROM City__c
             WHERE Id IN :cityIds]
        );
        
        Map<Id, State__c> stateMap = new Map<Id, State__c>(
            [SELECT Id, Country__c,
             Zone__c,
             Country__r.Region__c
             FROM State__c
             WHERE Id IN :stateIds]
        );
        
        for (Lead lead : newLeads) {
            if (lead.Pin_Code__c != null && postalCodeMap.containsKey(lead.Pin_Code__c)) {
                Pin_Code__c postalCode = postalCodeMap.get(lead.Pin_Code__c);
                lead.City__c = postalCode.City__c;
                lead.State__c = postalCode.City__r.State__c;
                lead.Country__c = postalCode.City__r.State__r.Country__c;
                lead.Zone__c = postalCode.City__r.State__r.Zone__c;
                lead.Region__c = postalCode.City__r.State__r.Country__r.Region__c;
                
            } else if (lead.City__c != null && cityMap.containsKey(lead.City__c)) {
                City__c city = cityMap.get(lead.City__c);
                lead.State__c = city.State__c;
                lead.Country__c = city.State__r.Country__c;
                lead.Zone__c = city.State__r.Zone__c;
                lead.Region__c = city.State__r.Country__r.Region__c;
                
            } else if (lead.State__c != null && stateMap.containsKey(lead.State__c)) {
                State__c state = stateMap.get(lead.State__c);
                lead.Country__c = state.Country__c;
                lead.Zone__c = state.Zone__c;
                lead.Region__c = state.Country__r.Region__c;
            }
        }
    }
    
    public static void setDefaultLeadStatus(List<Lead> leads) {
        /*   for (Lead l : leads) {
if (String.isBlank(l.Status) || l.Status == 'New') {
l.Status = 'Working';
}			
}	*/
    }
    
    
    public static void setLeadTypeBasedOnRecordType(List<Lead> leads) {
        Map<Id, RecordType> rtMap = new Map<Id, RecordType>(
            [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Lead']
        );
        
        for (Lead l : leads) {
            String rtDevName = rtMap.get(l.RecordTypeId).DeveloperName;
            if ((rtDevName == 'Unitop' || rtDevName == 'Tristar') && String.isBlank(l.Lead_Type__c)) {
                l.Lead_Type__c = 'Primary';
            }
        }
    }
    
    
    public static void setRossariCompany(List<Lead> leads) {
        if (leads == null || leads.isEmpty()) return;
        
        // Query safely to avoid exceptions
        List<Company__c> companies = [
            SELECT Id 
            FROM Company__c 
            WHERE Name = 'Rossari Biotech Limited' 
            LIMIT 1
        ];
        
        if (companies.isEmpty()) {
            System.debug('No "Rossari Biotech Limited" Company__c record found.');
            return; // or handle differently based on business logic
        }
        
        Id defaultCompanyId = companies[0].Id;
        
        for (Lead l : leads) {
            if (l.Rossari_Company__c == null) {
                l.Rossari_Company__c = defaultCompanyId;
                l.Is_New_from_Lead__c = true;
            }
        }
    }
    
    
    
    public static void createContactInformation(List<Lead> newLeads) {
        List<Contact_Information__c> contactInfoToInsert = new List<Contact_Information__c>();
        
        // Iterate over each Lead record that was inserted
        for (Lead lead : newLeads) {
            try {
                // Only create Contact Information if the Lead has relevant fields populated
                if (String.isNotEmpty(lead.FirstName) && String.isNotEmpty(lead.LastName)) {
                    
                    // Create a new Contact Information record
                    Contact_Information__c contactInfo = new Contact_Information__c(
                        
                        Lead__c = lead.Id,
                        Salutation__c = lead.Salutation,
                        Name = lead.FirstName,
                        Last_Name__c = lead.LastName,
                        Email__c = lead.Email,
                        Mobile__c = lead.MobilePhone,
                        Designation__c = lead.Title,
                        Is_Primary__c = true
                        //Department__c = lead.Department__c
                    );
                    // Add to the list to insert
                    contactInfoToInsert.add(contactInfo);
                } else {
                    System.debug('Lead missing required information: ' + lead.Id);
                }
            } catch (Exception e) {
                // Exception handling: Log the error with the Lead ID
                System.debug('Error processing Lead ' + lead.Id + ': ' + e.getMessage());
            }
        }
        
        // Insert the new Contact Information records
        if (!contactInfoToInsert.isEmpty()) {
            try {
                insert contactInfoToInsert;
                System.debug('Inserted ' + contactInfoToInsert.size() + ' Contact Information records.');
            } catch (Exception e) {
                // Catch any errors during the insert and log them
                System.debug('Error inserting Contact Information records: ' + e.getMessage());
            }
        }
    }
    
    public static void handleAfterLeadConvert(List<Lead> newLeads, Map<Id, Lead> oldLeadMap) {
        // === Step 1: Identify Converted Leads ===
        Set<Id> convertedLeadIds = new Set<Id>();
        Map<Id, Lead> convertedLeadsMap = new Map<Id, Lead>();
        Map<Id, Id> leadToAccountMap = new Map<Id, Id>();
        Map<Id, Id> leadToOpportunityMap = new Map<Id, Id>();
        Set<Id> convertedAccountIds = new Set<Id>();
        Set<Id> cityIds = new Set<Id>();
        
        for (Lead lead : newLeads) {
            Lead oldLead = oldLeadMap.get(lead.Id);
            if (!oldLead.IsConverted && lead.IsConverted) {
                if (String.isNotBlank(lead.ConvertedAccountId)) {
                    convertedAccountIds.add(lead.ConvertedAccountId);
                    convertedLeadsMap.put(lead.Id, lead);
                    leadToAccountMap.put(lead.Id, lead.ConvertedAccountId);
                    if (lead.City__c != null) cityIds.add(lead.City__c);
                }
                if (String.isNotBlank(lead.ConvertedOpportunityId)) {
                    leadToOpportunityMap.put(lead.Id, lead.ConvertedOpportunityId);
                }
            }
        }
        
        if (convertedLeadsMap.isEmpty()) {
            System.debug('No leads were converted. Skipping processing.');
            return;
        }
        
        // === Step 2: Contact Creation from Contact_Information__c ===
        List<Contact_Information__c> relatedInfos = [
            SELECT  Last_Name__c,Name, Email__c, Mobile__c, Designation__c, Department__c, Lead__c, Is_Primary__c, Salutation__c
            FROM Contact_Information__c
            WHERE Lead__c IN :convertedLeadsMap.keySet() ANd Is_Primary__c = false
        ];
        
        List<Contact> contactsToInsert = new List<Contact>();
        for (Contact_Information__c info : relatedInfos) {
            Lead convertedLead = convertedLeadsMap.get(info.Lead__c);
            Contact con = new Contact();
            con.Salutation     = info.Salutation__c;
            con.FirstName     = info.Name;
            con.LastName      = info.Last_Name__c;
            con.Email         = info.Email__c;
            con.Title         = info.Designation__c;
            con.Department    = info.Department__c;
            con.MobilePhone   = info.Mobile__c;
            con.AccountId     = convertedLead.ConvertedAccountId;
            contactsToInsert.add(con);
        }
        
        if (!contactsToInsert.isEmpty()) {
            try {
                insert contactsToInsert;
                System.debug('Inserted Contact records: ' + contactsToInsert.size());
            } catch (Exception e) {
                System.debug('Contact insert error: ' + e.getMessage());
            }
        }
        
        
        // ------------------ Update Converted Contact's Department ------------------
        List<Contact> contactsToUpdate = new List<Contact>();
        for (Lead lead : convertedLeadsMap.values()) {
            if (lead.ConvertedContactId != null && lead.Department__c != null) {   
                Contact c = new Contact();
                c.Id = lead.ConvertedContactId;
                c.Department = lead.Department__c;
                contactsToUpdate.add(c);
            }
        }
        
        if (!contactsToUpdate.isEmpty()) {   
            try {
                update contactsToUpdate;
            } catch (Exception e) {
                System.debug('Contact update error: ' + e.getMessage());
            }
        }
    }
    
    
    public static void handleFollowUpTask(List<Lead> newLeads, Map<Id, Lead> oldMap) {
        List<Task> tasksToInsert = new List<Task>();
        List<Task> tasksToUpdate = new List<Task>();
        Map<Id, Task> leadTaskMap = new Map<Id, Task>();
        
        Set<Id> leadIds = new Set<Id>();
        for (Lead l : newLeads) {
            leadIds.add(l.Id);
        }
        
        List<Task> existingTasks = [
            SELECT Id, WhatId, Subject, ActivityDate
            FROM Task
            WHERE WhatId IN :leadIds AND Subject = 'Follow Up Task'
        ];
        for (Task t : existingTasks) {
            leadTaskMap.put(t.WhatId, t);
        }
        
        for (Lead lead : newLeads) {
            // Check if the field was actually modified
            if (lead.Next_Follow_Up__c != null && 
                (oldMap == null || // for insert
                 oldMap.get(lead.Id).Next_Follow_Up__c != lead.Next_Follow_Up__c)) {
                     
                     Date followUpDate = lead.Next_Follow_Up__c;
                     
                     if (leadTaskMap.containsKey(lead.Id)) {
                         Task existingTask = leadTaskMap.get(lead.Id);
                         // Only update if the date is actually changing
                         if (existingTask.ActivityDate != followUpDate) {
                             existingTask.ActivityDate = followUpDate;
                             existingTask.Description = 'Lead follow-up days.';
                             tasksToUpdate.add(existingTask);
                         }
                     } else {
                         Task newTask = new Task(
                             WhoId = lead.Id,  // Changed from WhoId to WhatId for Lead
                             Subject = 'Follow Up Task',
                             ActivityDate = followUpDate,
                             Status = 'Not Started',
                             Priority = 'Normal',
                             Description = 'Lead follow-up'
                         );
                         tasksToInsert.add(newTask);
                     }
                 }
        }
        
        if (!tasksToInsert.isEmpty()) insert tasksToInsert;
        if (!tasksToUpdate.isEmpty()) update tasksToUpdate;
    }
    
    public static void createAddressInfoFromConvertedLead(List<Lead> convertedLeads, Map<Id, Lead> oldLeadsMap) {
        
        Id billToRecordTypeId = Schema.SObjectType.Address_Information__c.getRecordTypeInfosByDeveloperName()
            .get('Bill_To').getRecordTypeId();
        
        
        Set<Id> cityIds = new Set<Id>();
        for (Lead lead : convertedLeads) {
            if (lead.IsConverted && oldLeadsMap.get(lead.Id).IsConverted != lead.IsConverted && lead.City__c != null) {
                cityIds.add(lead.City__c);
            }
        }
        
        
        Map<Id, City__c> citiesMap = new Map<Id, City__c>([
            SELECT Id, Name FROM City__c WHERE Id IN :cityIds
        ]);
        
        List<Address_Information__c> addressesToInsert = new List<Address_Information__c>();
        
        for (Lead lead : convertedLeads) {
            
            if (lead.IsConverted && oldLeadsMap.get(lead.Id).IsConverted != lead.IsConverted) {
                
                Address_Information__c newAddress = new Address_Information__c();
                
                
                newAddress.Account__c = lead.ConvertedAccountId;
                newAddress.RecordTypeId = billToRecordTypeId;
                
                
                newAddress.Street_1__c = lead.Street_1__c;
                newAddress.Street_2__c = lead.Street_2__c;
                newAddress.Street_3__c = lead.Street_3__c;
                newAddress.Pin_Code__c = lead.Pin_Code__c;
                newAddress.City__c = lead.City__c;
                newAddress.State__c = lead.State__c;
                newAddress.Country__c = lead.Country__c;
                newAddress.Region__c = lead.Region__c;
                newAddress.Zone__c = lead.Zone__c;
                
                
                String cityName = (lead.City__c != null && citiesMap.containsKey(lead.City__c)) 
                    ? citiesMap.get(lead.City__c).Name : '';
                
                String addressName = 'Bill To - ' + 
                    (String.isNotBlank(cityName) ? cityName : '');
                
                newAddress.Name = addressName.abbreviate(80).trim();
                
                addressesToInsert.add(newAddress);
                
            }
        }
        
        if (!addressesToInsert.isEmpty()) {
            try {
                insert addressesToInsert;
            } catch (Exception e) {
                
                System.debug('Error creating Address Information records: ' + 
                             e.getMessage() + '\n' + e.getStackTraceString());
                
            }
        }
    }
    
    public static void handleAfterUpdate(List<Lead> newLeads, Map<Id, Lead> oldLeadMap) {
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        List<Account> accountsToUpdate = new List<Account>();
        
        for (Lead l : newLeads) {
            Lead oldLead = oldLeadMap.get(l.Id);
            
            // Check if the lead was just converted
            if (!oldLead.IsConverted && l.IsConverted) {
                // Update related Opportunity
                if (l.ConvertedOpportunityId != null) {
                    Opportunity opp = new Opportunity(
                        Id = l.ConvertedOpportunityId,
                        Description = l.Description
                    );
                    opportunitiesToUpdate.add(opp);
                }
                
                // Update related Account
                if (l.ConvertedAccountId != null) {
                    Account acct = new Account(
                        Id = l.ConvertedAccountId,
                        Rating__c = l.Rating,
                        Hierarchy__c = l.Hierarchy__c
                    );
                    accountsToUpdate.add(acct);
                }
            }
        }
        
        if (!opportunitiesToUpdate.isEmpty()) {
            update opportunitiesToUpdate;
        }
        
        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }
    
    
    
    public static void createQuotesForConvertedLeads(List<Id> convertedLeadIds) {
        // Query converted leads
        List<Lead> convertedLeads = [
            SELECT Id, ConvertedOpportunityId, ConvertedOpportunity.Name, 
            ConvertedAccountId, ConvertedContactId
            FROM Lead 
            WHERE Id IN :convertedLeadIds 
            AND ConvertedOpportunityId != NULL
        ];
        
        // Query related opportunities with line items
        List<Opportunity> opportunities = [
            SELECT Id, Name, Pricebook2Id, StageName,
            (SELECT Id, PricebookEntryId, Quantity, UnitPrice FROM OpportunityLineItems)
            FROM Opportunity 
            WHERE Id IN (SELECT ConvertedOpportunityId FROM Lead WHERE Id IN :convertedLeadIds)
        ];
        
        // Map opportunities for quick access
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        for (Opportunity opp : opportunities) {
            oppMap.put(opp.Id, opp);
        }
        
        // Create Quotes
        List<Quote> quotesToInsert = new List<Quote>();
        Map<Id, Id> quoteToOpportunityMap = new Map<Id, Id>(); // To use later for line items
        Set<Id> oppIdsToUpdateStage = new Set<Id>();
        
        for (Lead lead : convertedLeads) {
            if (lead.ConvertedOpportunityId != null && oppMap.containsKey(lead.ConvertedOpportunityId)) {
                Opportunity opp = oppMap.get(lead.ConvertedOpportunityId);
                
                Quote quote = new Quote(
                    Name = opp.Name,
                    OpportunityId = opp.Id,
                    Pricebook2Id = opp.Pricebook2Id,
                    ContactId = lead.ConvertedContactId,
                    ExpirationDate = System.today().addDays(30)
                );
                quotesToInsert.add(quote);
                quoteToOpportunityMap.put(opp.Id, opp.Id);
                oppIdsToUpdateStage.add(opp.Id);
            }
        }
        
        // Insert Quotes
        if (!quotesToInsert.isEmpty()) {
            insert quotesToInsert;
            
            // Create QuoteLineItems
            List<QuoteLineItem> lineItemsToInsert = new List<QuoteLineItem>();
            Map<Id, Id> oppToQuoteMap = new Map<Id, Id>();
            
            // Map OpportunityId -> QuoteId
            for (Quote quote : quotesToInsert) {
                oppToQuoteMap.put(quote.OpportunityId, quote.Id);
            }
            
            for (Opportunity opp : opportunities) {
                if (opp.OpportunityLineItems != null && !opp.OpportunityLineItems.isEmpty()) {
                    for (OpportunityLineItem oli : opp.OpportunityLineItems) {
                        if (oppToQuoteMap.containsKey(opp.Id)) {
                            QuoteLineItem qli = new QuoteLineItem(
                                QuoteId = oppToQuoteMap.get(opp.Id),
                                PricebookEntryId = oli.PricebookEntryId,
                                Quantity = oli.Quantity,
                                UnitPrice = oli.UnitPrice,
                                OpportunityLineItemId = oli.Id
                            );
                            lineItemsToInsert.add(qli);
                        }
                    }
                }
            }
            
            if (!lineItemsToInsert.isEmpty()) {
                Database.SaveResult[] qliResults = Database.insert(lineItemsToInsert, false);
                
                // Get the inserted QLI IDs
                List<Id> insertedQLIIds = new List<Id>();
                for (Database.SaveResult sr : qliResults) {
                    if (sr.isSuccess()) {
                        insertedQLIIds.add(sr.getId());
                    }
                }
                
                if (!insertedQLIIds.isEmpty()) {
                    // Query inserted QuoteLineItems with ListPrice
                    List<QuoteLineItem> insertedQLIs = [
                        SELECT Id, QuoteId, UnitPrice, ListPrice
                        FROM QuoteLineItem
                        WHERE Id IN :insertedQLIIds
                    ];
                    
                    Set<Id> quoteIdsWithDiscounts = new Set<Id>();
                    for (QuoteLineItem qli : insertedQLIs) {
                        if (qli.ListPrice != null && qli.UnitPrice < qli.ListPrice) {
                            quoteIdsWithDiscounts.add(qli.QuoteId);
                        }
                    }
                    
                    // Send emails for quotes with discounts
                    for (Id quoteId : quoteIdsWithDiscounts) {
                        try {
                            ManagerEmailSender.sendEmailToManagerForQuote(quoteId);
                        } catch(Exception e) {
                            System.debug('Error sending email for quote ' + quoteId + ': ' + e.getMessage());
                        }
                    }
                }
            }
            
            
        }
        
        // Update Opportunity stage to 'Quotation'
        if (!oppIdsToUpdateStage.isEmpty()) {
            List<Opportunity> oppsToUpdate = new List<Opportunity>();
            for (Id oppId : oppIdsToUpdateStage) {
                oppsToUpdate.add(new Opportunity(
                    Id = oppId,
                    StageName = 'Quotation'
                ));
            }
            update oppsToUpdate;
        }
    }
    
    
    private static Id getOpportunityPricebook(List<Opportunity> opportunities, Id opportunityId) {
        for (Opportunity opp : opportunities) {
            if (opp.Id == opportunityId) {
                return opp.Pricebook2Id;
            }
        }
        return null;
    }
    
    
    
}