public class LeadTriggerHandler {
    
    public static void updateLeadAddresses(List<Lead> newLeads) {
        Set<Id> postalCodeIds = new Set<Id>();
        Set<Id> cityIds = new Set<Id>();
        Set<Id> stateIds = new Set<Id>();
        
        Set<Id> shippingPostalCodeIds = new Set<Id>();
        Set<Id> shippingCityIds = new Set<Id>();
        Set<Id> shippingStateIds = new Set<Id>();
        
        for (Lead lead : newLeads) {
            if (lead.Pin_Code__c != null) postalCodeIds.add(lead.Pin_Code__c);
            if (lead.City__c != null) cityIds.add(lead.City__c);
            if (lead.State__c != null) stateIds.add(lead.State__c);
            
            if (lead.Shipping_Pin_Code__c != null) shippingPostalCodeIds.add(lead.Shipping_Pin_Code__c);
            if (lead.Shipping_City__c != null) shippingCityIds.add(lead.Shipping_City__c);
            if (lead.Shipping_State__c != null) shippingStateIds.add(lead.Shipping_State__c);
        }
        
        Map<Id, Pin_Code__c> postalCodeMap = new Map<Id, Pin_Code__c>([
            SELECT Id, City__c, City__r.State__c, 
            City__r.State__r.Country__c,
            City__r.State__r.Zone__c,
            City__r.State__r.Country__r.Region__c
            FROM Pin_Code__c
            WHERE Id IN :postalCodeIds OR Id IN :shippingPostalCodeIds
        ]);
        
        Map<Id, City__c> cityMap = new Map<Id, City__c>([
            SELECT Id, State__c,
            State__r.Country__c,
            State__r.Zone__c,
            State__r.Country__r.Region__c
            FROM City__c
            WHERE Id IN :cityIds OR Id IN :shippingCityIds
        ]);
        
        Map<Id, State__c> stateMap = new Map<Id, State__c>([
            SELECT Id, Country__c,
            Zone__c,
            Country__r.Region__c
            FROM State__c
            WHERE Id IN :stateIds OR Id IN :shippingStateIds
        ]);
        
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
            
            
            if (lead.Shipping_Pin_Code__c != null && postalCodeMap.containsKey(lead.Shipping_Pin_Code__c)) {
                Pin_Code__c postalCode = postalCodeMap.get(lead.Shipping_Pin_Code__c);
                lead.Shipping_City__c = postalCode.City__c;
                lead.Shipping_State__c = postalCode.City__r.State__c;
                lead.Shipping_Country__c = postalCode.City__r.State__r.Country__c;
                lead.Shipping_Zone__c = postalCode.City__r.State__r.Zone__c;
                lead.Shipping_Region__c = postalCode.City__r.State__r.Country__r.Region__c;
            } else if (lead.Shipping_City__c != null && cityMap.containsKey(lead.Shipping_City__c)) {
                City__c city = cityMap.get(lead.Shipping_City__c);
                lead.Shipping_State__c = city.State__c;
                lead.Shipping_Country__c = city.State__r.Country__c;
                lead.Shipping_Zone__c = city.State__r.Zone__c;
                lead.Shipping_Region__c = city.State__r.Country__r.Region__c;
            } else if (lead.Shipping_State__c != null && stateMap.containsKey(lead.Shipping_State__c)) {
                State__c state = stateMap.get(lead.Shipping_State__c);
                lead.Shipping_Country__c = state.Country__c;
                lead.Shipping_Zone__c = state.Zone__c;
                lead.Shipping_Region__c = state.Country__r.Region__c;
            }
        }
        
        
  /*      Country__c india = [SELECT Id FROM Country__c WHERE Name = 'India' LIMIT 1];
        
        for (Lead lead : newLeads) {
            if (lead.Country__c == null &&
                (lead.Business_Type__c == 'Domestic' ||
                 lead.Business_Type__c == 'SEZ' ||
                 lead.Business_Type__c == 'Deemed Export')) {
                     lead.Country__c = india.Id;
                 }
        }	*/
        
        List<Country__c> countries = [SELECT Id FROM Country__c WHERE Name = 'India' LIMIT 1];
        Id indiaId = (countries.size() > 0) ? countries[0].Id : null;
        
        for (Lead lead : newLeads) {
            if (lead.Country__c == null &&
                (lead.Business_Type__c == 'Domestic' ||
                 lead.Business_Type__c == 'SEZ' ||
                 lead.Business_Type__c == 'Deemed Export')) {
                     if (indiaId != null) {
                         lead.Country__c = indiaId;
                     }
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
            if ((rtDevName == 'Unitop_Tristar') && String.isBlank(l.Lead_Type__c)) {
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
                        Is_Primary__c = true,
                        Department__c = lead.Department__c,
                        Hierarchy__c = lead.Hierarchy__c
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
    
    
    public static void updateContactInformationOnLeadChange(List<Lead> newLeads, Map<Id, Lead> oldLeadMap) {
        Set<Id> leadIdsWithChanges = new Set<Id>();
        
        // Identify leads where Department or Hierarchy changed
        for (Lead lead : newLeads) {
            Lead oldLead = oldLeadMap.get(lead.Id);
            if (lead.Department__c != oldLead.Department__c || lead.Hierarchy__c != oldLead.Hierarchy__c) {
                leadIdsWithChanges.add(lead.Id);
            }
        }
        
        if (leadIdsWithChanges.isEmpty()) return;
        
        // Get related Contact Information records
        Map<Id, Contact_Information__c> contactInfoMap = new Map<Id, Contact_Information__c>();
        for (Contact_Information__c ci : [
            SELECT Id, Lead__c, Department__c, Hierarchy__c 
            FROM Contact_Information__c 
            WHERE Lead__c IN :leadIdsWithChanges AND Is_Primary__c = true
        ]) {
            contactInfoMap.put(ci.Lead__c, ci);
        }
        
        // Update Contact Information records
        List<Contact_Information__c> contactInfoToUpdate = new List<Contact_Information__c>();
        for (Lead lead : newLeads) {
            if (leadIdsWithChanges.contains(lead.Id) && contactInfoMap.containsKey(lead.Id)) {
                Contact_Information__c ci = contactInfoMap.get(lead.Id);
                ci.Department__c = lead.Department__c;
             //   ci.Hierarchy__c = lead.Hierarchy__c;
                contactInfoToUpdate.add(ci);
            }
        }
        
        if (!contactInfoToUpdate.isEmpty()) {
            update contactInfoToUpdate;
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
        
        // ------------------ Update Opportunity.Contact__c with Converted Contact ------------------
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        
        for (Lead lead : convertedLeadsMap.values()) {
            if (lead.ConvertedOpportunityId != null && lead.ConvertedContactId != null) {
                Opportunity opp = new Opportunity();
                opp.Id = lead.ConvertedOpportunityId;
                opp.Contact__c = lead.ConvertedContactId;
                opportunitiesToUpdate.add(opp);
            }
        }
        
        if (!opportunitiesToUpdate.isEmpty()) {
            try {
                update opportunitiesToUpdate;
                System.debug('Updated Opportunity.Contact__c for: ' + opportunitiesToUpdate.size() + ' opportunities.');
            } catch (Exception e) {
                System.debug('Opportunity update error: ' + e.getMessage());
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
    
/*    public static void createAddressInfoFromConvertedLead(List<Lead> convertedLeads, Map<Id, Lead> oldLeadsMap) {
        
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
    }   */
    
    public static void createAddressInfoFromConvertedLead(List<Lead> convertedLeads, Map<Id, Lead> oldLeadsMap) {
        
        // Get both record type IDs
        Id billToRecordTypeId = Schema.SObjectType.Address_Information__c.getRecordTypeInfosByDeveloperName()
            .get('Bill_To').getRecordTypeId();
        Id shipToRecordTypeId = Schema.SObjectType.Address_Information__c.getRecordTypeInfosByDeveloperName()
            .get('Ship_To').getRecordTypeId();
        
        Set<Id> cityIds = new Set<Id>();
        Set<Id> shippingCityIds = new Set<Id>();
        
        for (Lead lead : convertedLeads) {
            if (lead.IsConverted && oldLeadsMap.get(lead.Id).IsConverted != lead.IsConverted) {
                if (lead.City__c != null) {
                    cityIds.add(lead.City__c);
                }
                if (lead.Shipping_City__c != null) {
                    shippingCityIds.add(lead.Shipping_City__c);
                }
            }
        }
        
        // Get all cities in one query
        Set<Id> allCityIds = new Set<Id>();
        allCityIds.addAll(cityIds);
        allCityIds.addAll(shippingCityIds);
        
        Map<Id, City__c> citiesMap = new Map<Id, City__c>([
            SELECT Id, Name FROM City__c WHERE Id IN :allCityIds
        ]);
        
        List<Address_Information__c> addressesToInsert = new List<Address_Information__c>();
        
        for (Lead lead : convertedLeads) {
            
            if (lead.IsConverted && oldLeadsMap.get(lead.Id).IsConverted != lead.IsConverted) {
                
                // Create Bill To Address
                if (hasBillToAddressData(lead)) {
                    Address_Information__c billToAddress = new Address_Information__c();
                    
                    billToAddress.Account__c = lead.ConvertedAccountId;
                    billToAddress.RecordTypeId = billToRecordTypeId;
                    
                    // Map Bill To fields
                    billToAddress.Street_1__c = lead.Street_1__c;
                    billToAddress.Street_2__c = lead.Street_2__c;
                    billToAddress.Street_3__c = lead.Street_3__c;
                    billToAddress.Pin_Code__c = lead.Pin_Code__c;
                    billToAddress.City__c = lead.City__c;
                    billToAddress.State__c = lead.State__c;
                    billToAddress.Country__c = lead.Country__c;
                    billToAddress.Region__c = lead.Region__c;
                    billToAddress.Zone__c = lead.Zone__c;
                    
                    String billToCityName = (lead.City__c != null && citiesMap.containsKey(lead.City__c)) 
                        ? citiesMap.get(lead.City__c).Name : '';
                    
                    String billToAddressName = 'Bill To - ' + 
                        (String.isNotBlank(billToCityName) ? billToCityName : '');
                    
                    billToAddress.Name = billToAddressName.abbreviate(80).trim();
                    
                    addressesToInsert.add(billToAddress);
                }
                
                // Create Ship To Address
                if (hasShipToAddressData(lead)) {
                    Address_Information__c shipToAddress = new Address_Information__c();
                    
                    shipToAddress.Account__c = lead.ConvertedAccountId;
                    shipToAddress.RecordTypeId = shipToRecordTypeId;
                    
                    // Map Ship To fields
                    shipToAddress.Street_1__c = lead.Shipping_Street_1__c;
                    shipToAddress.Street_2__c = lead.Shipping_Street_2__c;
                    shipToAddress.Street_3__c = lead.Shipping_Street_3__c;
                    shipToAddress.Pin_Code__c = lead.Shipping_Pin_Code__c;
                    shipToAddress.City__c = lead.Shipping_City__c;
                    shipToAddress.State__c = lead.Shipping_State__c;
                    shipToAddress.Country__c = lead.Shipping_Country__c;
                    shipToAddress.Region__c = lead.Shipping_Region__c;
                    shipToAddress.Zone__c = lead.Shipping_Zone__c;
                    
                    String shipToCityName = (lead.Shipping_City__c != null && citiesMap.containsKey(lead.Shipping_City__c)) 
                        ? citiesMap.get(lead.Shipping_City__c).Name : '';
                    
                    String shipToAddressName = 'Ship To - ' + 
                        (String.isNotBlank(shipToCityName) ? shipToCityName : '');
                    
                    shipToAddress.Name = shipToAddressName.abbreviate(80).trim();
                    
                    addressesToInsert.add(shipToAddress);
                }
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
    
    // Helper method to check if Bill To address has data
    private static Boolean hasBillToAddressData(Lead lead) {
        return String.isNotBlank(lead.Street_1__c) ||
            String.isNotBlank(lead.Street_2__c) ||
            String.isNotBlank(lead.Street_3__c) ||
            String.isNotBlank(lead.Pin_Code__c) ||
            lead.City__c != null ||
            String.isNotBlank(lead.State__c) ||
            String.isNotBlank(lead.Country__c) ||
            String.isNotBlank(lead.Region__c) ||
            String.isNotBlank(lead.Zone__c);
    }
    
    // Helper method to check if Ship To address has data
    private static Boolean hasShipToAddressData(Lead lead) {
        return String.isNotBlank(lead.Shipping_Street_1__c) ||
            String.isNotBlank(lead.Shipping_Street_2__c) ||
            String.isNotBlank(lead.Shipping_Street_3__c) ||
            String.isNotBlank(lead.Shipping_Pin_Code__c) ||
            lead.Shipping_City__c != null ||
            String.isNotBlank(lead.Shipping_State__c) ||
            String.isNotBlank(lead.Shipping_Country__c) ||
            String.isNotBlank(lead.Shipping_Region__c) ||
            String.isNotBlank(lead.Shipping_Zone__c);
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
        // Query converted leads with required fields
        List<Lead> convertedLeads = [
            SELECT Id, ConvertedOpportunityId, ConvertedOpportunity.Name, 
            ConvertedAccountId, ConvertedContactId,
            Create_Quote_upon_Conversion__c,
            Inco_Terms__c, Payment_Term__c, Bill_to__c, Ship_to__c,
            Loading_Port__c, Destination_Port__c,
            Quote_Valid_From__c, Quote_Valid_To__c,
            Bank__c, Destination__c,
            Country_of_Origin__c, Country_of_Destination__c,
            Pre_Carriage_Mode__c, Place_of_Supplier__c,
            Partial_Shipment__c, Vessel_Flight_No__c,Payment_Terms__c,
            Street_1__c,Street_2__c,Street_3__c,Pin_Code__c,Pin_Code__r.Name,City__c,City__r.Name,Zone__c,State__c,
            State__r.Name,Region__c,Country__c,Country__r.Name,
            Shipping_Street_1__c,Shipping_Street_2__c,Shipping_Street_3__c,Shipping_Pin_Code__c,Shipping_Pin_Code__r.Name,
            Shipping_City__c,Shipping_City__r.Name,Shipping_State__r.Name,Shipping_Country__r.Name,
            Shipping_Zone__c,Shipping_State__c,Shipping_Region__c,Shipping_Country__c,Company,Email,MobilePhone,
            Division__c, Business_Type__c  // ADDED THESE FIELDS
            FROM Lead 
            WHERE Id IN :convertedLeadIds 
            AND ConvertedOpportunityId != NULL
        ];
        
        // Get mapping values for Quote creation
        List<Sales_Organisation__c> salesOrg1000 = [
            SELECT Id FROM Sales_Organisation__c 
            WHERE Name = '1000'
            LIMIT 1
        ];
        
        List<Distribution_Channel__c> distChannel10 = [
            SELECT Id FROM Distribution_Channel__c 
            WHERE Name = '10' 
            LIMIT 1
        ];
        
        List<Distribution_Channel__c> distChannel20 = [
            SELECT Id FROM Distribution_Channel__c 
            WHERE Name = '20' 
            LIMIT 1
        ];
        
        Id salesOrg1000Id = salesOrg1000.isEmpty() ? null : salesOrg1000[0].Id;
        Id distChannel10Id = distChannel10.isEmpty() ? null : distChannel10[0].Id;
        Id distChannel20Id = distChannel20.isEmpty() ? null : distChannel20[0].Id;
        
        List<Opportunity> opportunities = [
            SELECT Id, Name, Pricebook2Id, StageName,
            (SELECT Id, PricebookEntryId, Quantity, UnitPrice FROM OpportunityLineItems)
            FROM Opportunity 
            WHERE Id IN (SELECT ConvertedOpportunityId FROM Lead WHERE Id IN :convertedLeadIds)
        ];
        
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        for (Opportunity opp : opportunities) {
            oppMap.put(opp.Id, opp);
        }
        
        List<Quote> quotesToInsert = new List<Quote>();
        Map<Id, Id> quoteToOpportunityMap = new Map<Id, Id>(); // For later use
        Set<Id> oppIdsToUpdateStage = new Set<Id>();
        
        for (Lead lead : convertedLeads) {
            if (lead.Create_Quote_upon_Conversion__c == true && 
                lead.ConvertedOpportunityId != null && 
                oppMap.containsKey(lead.ConvertedOpportunityId)) {
                    
                    Opportunity opp = oppMap.get(lead.ConvertedOpportunityId);
                    
                    Company__c rossariCompany = [SELECT Id FROM Company__c WHERE Name = 'Rossari Biotech Limited' LIMIT 1];
                    
                    // Get current user
                    User currentUser = [SELECT Id, Entity_Code_1__c, Entity_Code_2__c, Entity_Code_3__c FROM User WHERE Id = :UserInfo.getUserId()];
                    
                    // Collect all non-null entity codes
                    Set<String> entityCodes = new Set<String>();
                    if (currentUser.Entity_Code_1__c != null) entityCodes.add(currentUser.Entity_Code_1__c);
                    if (currentUser.Entity_Code_2__c != null) entityCodes.add(currentUser.Entity_Code_2__c);
                    if (currentUser.Entity_Code_3__c != null) entityCodes.add(currentUser.Entity_Code_3__c);
                    
                    // Find matching Sales HOD user
                    User hodUser = null;
                    if (!entityCodes.isEmpty()) {
                        List<User> hodUsers = [
                            SELECT Id FROM User 
                            WHERE Is_Sales_HOD__c = true AND (
                                Entity_Code_1__c IN :entityCodes OR 
                                Entity_Code_2__c IN :entityCodes OR 
                                Entity_Code_3__c IN :entityCodes
                            )
                            LIMIT 1
                        ];
                        if (!hodUsers.isEmpty()) {
                            hodUser = hodUsers[0];
                        }
                    }
                    
                    // Determine Distribution Channel based on Business_Type__c
                    Id distributionChannelId = null;
                    if (lead.Business_Type__c == 'Domestic' || 
                        lead.Business_Type__c == 'Deemed Export' || 
                        lead.Business_Type__c == 'SEZ') {
                            distributionChannelId = distChannel10Id;  // Use '10' for Domestic, Deemed Export, and SEZ
                        } else if (lead.Business_Type__c == 'Export') {
                            distributionChannelId = distChannel20Id;  // Use '20' only for Export
                        }
                    
                    Quote quote = new Quote(
                        Name = opp.Name,
                        OpportunityId = opp.Id,
                        Pricebook2Id = opp.Pricebook2Id,
                        ContactId = lead.ConvertedContactId,
                        Letter_Company_Name__c = rossariCompany.Id,
                        
                        // MAP DIRECTLY FROM LEAD TO QUOTE USING UPDATED LOGIC
                        Sales_Organisations__c = salesOrg1000Id,  // Always '1000'
                        Division__c = lead.Division__c,           // Direct from Lead
                        Distribution_Channel__c = distributionChannelId, // Based on updated Business_Type__c logic
                        
                        // Mapped fields from Lead to Quote
                        Inco_Terms__c = lead.Inco_Terms__c,
                        Payment_Term__c = lead.Payment_Terms__c,
                        Loading_Port__c = lead.Loading_Port__c,
                        Destination_Port__c = lead.Destination_Port__c,
                        Quote_Valid_From__c = lead.Quote_Valid_From__c,
                        ExpirationDate = lead.Quote_Valid_To__c,
                        Bank__c = lead.Bank__c,
                        Destination__c = lead.Destination__c,
                        Country_of_Origin__c = lead.Country_of_Origin__c,
                        Country_of_Destination__c = lead.Country_of_Destination__c,
                        Pre_Carriage_Mode__c = lead.Pre_Carriage_Mode__c,
                        Place_of_Supplier__c = lead.Place_of_Supplier__c,
                        Partial_Shipment__c = lead.Partial_Shipment__c,
                        Vessel_Flight_No__c = lead.Vessel_Flight_No__c,
                        Email	= lead.Email,
                        Phone	= lead.MobilePhone,
                        HOD_of_Sales_Department__c = hodUser != null ? hodUser.Id : null,
                        
                        BillingStreet = 
                        (lead.Street_1__c != null ? lead.Street_1__c + '\n' : '') +
                        (lead.Street_2__c != null ? lead.Street_2__c + '\n' : '') +
                        (lead.Street_3__c != null ? lead.Street_3__c : ''),
                        
                        BillingPostalCode = lead.Pin_Code__r != null ? lead.Pin_Code__r.Name : null,
                        BillingCity = lead.City__r != null ? lead.City__r.Name : null,
                        BillingState = lead.State__r != null ? lead.State__r.Name : null,
                        BillingCountry = lead.Country__r != null ? lead.Country__r.Name : null,
                        
                        ShippingStreet = 
                        (lead.Shipping_Street_1__c != null ? lead.Shipping_Street_1__c + '\n' : '') +
                        (lead.Shipping_Street_2__c != null ? lead.Shipping_Street_2__c + '\n' : '') +
                        (lead.Shipping_Street_3__c != null ? lead.Shipping_Street_3__c : ''),
                        
                        ShippingPostalCode = lead.Shipping_Pin_Code__r != null ? lead.Shipping_Pin_Code__r.Name : null,
                        ShippingCity = lead.Shipping_City__r != null ? lead.Shipping_City__r.Name : null,
                        ShippingState = lead.Shipping_State__r != null ? lead.Shipping_State__r.Name : null,
                        ShippingCountry = lead.Shipping_Country__r != null ? lead.Shipping_Country__r.Name : null,
                        
                        BillingName = lead.Company,
                        ShippingName = lead.Company,
                        
                        Terms_and_Conditions__c =
                        'All bank charges outside India will be borne by the customer and such charges should not be deducted from our payment.\n' +
                        'We should receive full invoice amount in our bank account and you are liable to pay the bank charges which are applicable in India only.\n' +
                        'After finalization of order if there is any change in Statutory Govt. levies than it will be in your scope.',
                        
                        Declaration__c = 'We declare that this quotation shows the actual price of goods and that all particulars are true and correct'
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
    
    
    public static void setRossariCompanyOnAccount(List<Lead> newLeads, Map<Id, Lead> oldLeadMap) {
        Map<String, String> recordTypeToCompanyName = new Map<String, String>{
            'RBL' => 'Rossari Biotech Limited',
                'Unitop_Tristar' => 'Rossari Biotech Limited'
              //  'Unitop' => 'Rossari Biotech Limited'
                };
                    
                    Set<Id> convertedLeadIds = new Set<Id>();
        for (Lead lead : newLeads) {
            Lead oldLead = oldLeadMap.get(lead.Id);
            if (lead.IsConverted && !oldLead.IsConverted && lead.ConvertedAccountId != null) {
                convertedLeadIds.add(lead.Id);
            }
        }
        
        if (convertedLeadIds.isEmpty()) return;
        
        // Query leads with RecordType DeveloperName
        Map<Id, Lead> convertedLeadsWithRT = new Map<Id, Lead>(
            [SELECT Id, ConvertedAccountId, RecordType.DeveloperName FROM Lead WHERE Id IN :convertedLeadIds]
        );
        
        // Get all company records
        Map<String, Id> companyNameToId = new Map<String, Id>();
        for (Company__c company : [SELECT Id, Name FROM Company__c WHERE Name IN :recordTypeToCompanyName.values()]) {
            companyNameToId.put(company.Name, company.Id);
        }
        
        List<Account> accountsToUpdate = new List<Account>();
        for (Id leadId : convertedLeadIds) {
            Lead convertedLead = convertedLeadsWithRT.get(leadId);
            String recordTypeDevName = convertedLead.RecordType.DeveloperName;
            String companyName = recordTypeToCompanyName.get(recordTypeDevName);
            
            if (companyName != null && companyNameToId.containsKey(companyName)) {
                accountsToUpdate.add(new Account(
                    Id = convertedLead.ConvertedAccountId,
                    Rossari_Company__c = companyNameToId.get(companyName)
                ));
            }
        }
        
        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }

     public static void validateLeadConversion(List<Lead> newLeads, Map<Id, Lead> oldMap) {
        Set<Id> accountIds = new Set<Id>();

       
        for (Lead ld : newLeads) {
            Lead oldLead = oldMap.get(ld.Id);
            if (ld.IsConverted && !oldLead.IsConverted) {
                if (ld.ConvertedAccountId != null) {
                    accountIds.add(ld.ConvertedAccountId);
                }
            }
        }

        if (accountIds.isEmpty()) return;


        Map<Id, Account> accMap = new Map<Id, Account>([
            SELECT Id, RecordTypeId FROM Account WHERE Id IN :accountIds
        ]);

        
        Map<Id, RecordType> leadRecordTypes = new Map<Id, RecordType>(
            [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Lead']
        );

        
        Map<Id, RecordType> accountRecordTypes = new Map<Id, RecordType>(
            [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Account']
        );

        for (Lead ld : newLeads) {
            Lead oldLead = oldMap.get(ld.Id);
            if (ld.IsConverted && !oldLead.IsConverted && ld.ConvertedAccountId != null) {
                Account acc = accMap.get(ld.ConvertedAccountId);

                String leadRecordTypeDevName = leadRecordTypes.get(ld.RecordTypeId)?.DeveloperName;
                String accountRecordTypeDevName = accountRecordTypes.get(acc.RecordTypeId)?.DeveloperName;

                
                if ((leadRecordTypeDevName == 'Unitop_Tristar') 
                    && accountRecordTypeDevName == 'Secondary') {
                    ld.addError('Leads with Record Type "' + leadRecordTypeDevName + '" must be converted to an Account with Record Type = "Primary", not "Secondary".');
                }
            }
        }
    }
    
    public static void mapLeadFieldsToOpportunity(List<Lead> newLeads, Map<Id, Lead> oldLeadMap) {
        Set<Id> convertedLeadIds = new Set<Id>();
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        
        // Identify converted leads
        for (Lead lead : newLeads) {
            Lead oldLead = oldLeadMap.get(lead.Id);
            if (lead.IsConverted && !oldLead.IsConverted && lead.ConvertedOpportunityId != null) {
                convertedLeadIds.add(lead.Id);
            }
        }
        
        if (convertedLeadIds.isEmpty()) return;
        
        // Query converted leads with required fields
        List<Lead> convertedLeads = [
            SELECT Id, ConvertedOpportunityId, Division__c, Business_Type__c
            FROM Lead 
            WHERE Id IN :convertedLeadIds
        ];
        
        // Get Sales Organisation with value 1000 - using Name field
        List<Sales_Organisation__c> salesOrg1000 = [
            SELECT Id FROM Sales_Organisation__c 
            WHERE Name = '1000'
            LIMIT 1
        ];
        
        // Get Distribution Channels based on Name field
        List<Distribution_Channel__c> distChannel10 = [
            SELECT Id FROM Distribution_Channel__c 
            WHERE Name = '10' 
            LIMIT 1
        ];
        
        List<Distribution_Channel__c> distChannel20 = [
            SELECT Id FROM Distribution_Channel__c 
            WHERE Name = '20' 
            LIMIT 1
        ];
        
        Id salesOrg1000Id = salesOrg1000.isEmpty() ? null : salesOrg1000[0].Id;
        Id distChannel10Id = distChannel10.isEmpty() ? null : distChannel10[0].Id;
        Id distChannel20Id = distChannel20.isEmpty() ? null : distChannel20[0].Id;
        
        // Prepare opportunities for update
        for (Lead lead : convertedLeads) {
            Opportunity opp = new Opportunity(Id = lead.ConvertedOpportunityId);
            
            // Always set Sales_Organisation__c to 1000 on Opportunity
            if (salesOrg1000Id != null) {
                opp.Sales_Organisations__c = salesOrg1000Id;
            }
            
            // Map Division__c from Lead to Opportunity
            if (lead.Division__c != null) {
                opp.Division__c = lead.Division__c;
            }
            
            // Map Distribution_Channel__c on Opportunity based on Lead's Business_Type__c - UPDATED LOGIC
            if ((lead.Business_Type__c == 'Domestic' || 
                 lead.Business_Type__c == 'Deemed Export' || 
                 lead.Business_Type__c == 'SEZ') && distChannel10Id != null) {
                     opp.Distribution_Channel__c = distChannel10Id;  // Use '10' for Domestic, Deemed Export, and SEZ
                 } else if (lead.Business_Type__c == 'Export' && distChannel20Id != null) {
                     opp.Distribution_Channel__c = distChannel20Id;  // Use '20' only for Export
                 }
            
            opportunitiesToUpdate.add(opp);
        }
        
        // Update opportunities
        if (!opportunitiesToUpdate.isEmpty()) {
            try {
                update opportunitiesToUpdate;
                System.debug('Successfully updated ' + opportunitiesToUpdate.size() + ' opportunities with lead field mappings');
            } catch (Exception e) {
                System.debug('Error updating opportunities: ' + e.getMessage());
            }
        }
    }
    
    public static void updateSampleRequestsAfterConversion(List<Lead> newLeads, Map<Id, Lead> oldLeadMap) {
        // Step 1: Identify converted leads
        Set<Id> convertedLeadIds = new Set<Id>();
        Map<Id, Id> leadToAccountMap = new Map<Id, Id>();
        Map<Id, Id> leadToOpportunityMap = new Map<Id, Id>();
        
        for (Lead lead : newLeads) {
            Lead oldLead = oldLeadMap.get(lead.Id);
            // Check if lead was just converted
            if (!oldLead.IsConverted && lead.IsConverted) {
                convertedLeadIds.add(lead.Id);
                
                // Store the mapping from Lead to converted Account and Opportunity
                if (lead.ConvertedAccountId != null) {
                    leadToAccountMap.put(lead.Id, lead.ConvertedAccountId);
                }
                if (lead.ConvertedOpportunityId != null) {
                    leadToOpportunityMap.put(lead.Id, lead.ConvertedOpportunityId);
                }
            }
        }
        
        if (convertedLeadIds.isEmpty()) {
            return;
        }
        
        // Step 2: Query all Sample Request records related to these leads
        List<Sample_Request__c> sampleRequestsToUpdate = new List<Sample_Request__c>();
        
        List<Sample_Request__c> relatedSampleRequests = [
            SELECT Id, Lead__c, Customer_Name__c, Opportunity__c 
            FROM Sample_Request__c 
            WHERE Lead__c IN :convertedLeadIds
            AND (Customer_Name__c = null OR Opportunity__c = null) // Only update if not already set
        ];
        
        if (relatedSampleRequests.isEmpty()) {
            return;
        }
        
        // Step 3: Update Sample Requests with Account and Opportunity IDs
        for (Sample_Request__c sampleRequest : relatedSampleRequests) {
            Id leadId = sampleRequest.Lead__c;
            
            // Update Account if not already set and available from conversion
            if (sampleRequest.Customer_Name__c == null && leadToAccountMap.containsKey(leadId)) {
                sampleRequest.Customer_Name__c = leadToAccountMap.get(leadId);
            }
            
            // Update Opportunity if not already set and available from conversion
            if (sampleRequest.Opportunity__c == null && leadToOpportunityMap.containsKey(leadId)) {
                sampleRequest.Opportunity__c = leadToOpportunityMap.get(leadId);
            }
            
            sampleRequestsToUpdate.add(sampleRequest);
        }
        
        // Step 4: Perform the update
        if (!sampleRequestsToUpdate.isEmpty()) {
            try {
                update sampleRequestsToUpdate;
                System.debug('Successfully updated ' + sampleRequestsToUpdate.size() + ' Sample Request records after lead conversion');
            } catch (Exception e) {
                System.debug('Error updating Sample Request records: ' + e.getMessage());
                // You might want to handle this error differently based on your business requirements
            }
        }
    }
}