public class VisitReportController {
    
    @AuraEnabled
    public static Contact getContact(string accId){
        system.debug([select Id,Name,Email,Title from Contact where Id=:accId limit 1]);
        return [select Id,Name,Email,Title from Contact where Id=:accId limit 1];
    }
    
    // 🔹 Get all Contacts for a given Account
    @AuraEnabled(cacheable=true)
    public static List<Contact> getContactsByAccount(Id accId) {
        return [
            SELECT Id, Name, Email, Title 
            FROM Contact 
            WHERE AccountId = :accId 
            ORDER BY Name
        ];
    }

    // 🔹 Get a User by Id
    @AuraEnabled(cacheable=true)
    public static User getUser(Id userId) {
        return [
            SELECT Id, Name, FirstName, LastName
            FROM User 
            WHERE Id = :userId
            LIMIT 1
        ];
    }
    
    @AuraEnabled
    public static map<string,string> saveVisitReport(string visit, string Attendees, string ProductInterestPoint, string ActionPoint, 
                                                     string location, string currencyCode, string visitType, string existingVisitReportId) {
        
        map<string,string> result = new map<string,string>();
        try {
            map<string,object> visitMap = (map<string,object>)JSON.deserializeUntyped(visit);
            List<object>ProductInterestPointList =(List<object>)JSON.deserializeUntyped(ProductInterestPoint);
            List<object>AttendeesList =(List<object>)JSON.deserializeUntyped(Attendees);
            List<object>ActionPointList =(List<object>)JSON.deserializeUntyped(ActionPoint);
            List<Task> taskList = new List<Task>();
            
            Visit_Report__c vrc;
            Event e;
            List<EventRelation> eventAttendees = new List<EventRelation>();
            
            // CHECK IF WE'RE UPDATING EXISTING RECORD OR CREATING NEW
            if (existingVisitReportId != null && !String.isBlank(existingVisitReportId)) {
                // UPDATE EXISTING RECORD
                vrc = [SELECT Id, Title_of_Meeting__c, Start_Date_Time__c, End_Date_Time__c,CurrencyIsoCode  
                       FROM Visit_Report__c WHERE Id = :existingVisitReportId];
                
                // Update only the fields that should be editable for existing records
                if(visitMap.containsKey('Discussion_Details_from_the_Meeting') && String.isNotBlank(String.valueOf(visitMap.get('Discussion_Details_from_the_Meeting'))))
                    vrc.Discussion_Details_from_the_Meeting__c = (string)visitMap.get('Discussion_Details_from_the_Meeting');
                
                if(visitMap.containsKey('Next_Meeting_Date_agreed_with_Customer') && String.isNotBlank(String.valueOf(visitMap.get('Next_Meeting_Date_agreed_with_Customer'))))
                    vrc.Next_Meeting_Date_agreed_with_Customer__c = date.valueOf((string)visitMap.get('Next_Meeting_Date_agreed_with_Customer'));
                
                update vrc;
                
                // Delete existing related records (except attendees since they should remain)
                delete [SELECT Id FROM Product_Interest_and_Pricing_Benchmark__c WHERE Visit_Report__c = :vrc.Id];
                delete [SELECT Id FROM Action_Point__c WHERE Visit_Report__c = :vrc.Id];
                
            } else {
                // CREATE NEW RECORD
                vrc = new Visit_Report__c();
                vrc.CurrencyIsoCode = currencyCode;
                
                // Populate all basic fields for new record
                if(visitMap.containsKey('Visit_Report_Type') && String.isNotBlank(String.valueOf(visitMap.get('Visit_Report_Type'))))
                    vrc.Visit_Report_Type__c = (string)visitMap.get('Visit_Report_Type');
                
                if(visitMap.containsKey('lead_Name') && String.isNotBlank(String.valueOf(visitMap.get('lead_Name'))))
                    vrc.Lead__c = (Id)visitMap.get('lead_Name');
                
                if(visitMap.containsKey('Customer_Name') && String.isNotBlank(String.valueOf(visitMap.get('Customer_Name'))))
                    vrc.Customer_Name__c = (Id)visitMap.get('Customer_Name');
                
                if(visitMap.containsKey('Competition_Name') && String.isNotBlank(String.valueOf(visitMap.get('Competition_Name'))))
                    vrc.Competition_Name__c = (Id)visitMap.get('Competition_Name');
                
                if(visitMap.containsKey('Title_of_Meeting') && String.isNotBlank(String.valueOf(visitMap.get('Title_of_Meeting'))))
                    vrc.Title_of_Meeting__c = (string)visitMap.get('Title_of_Meeting');
                
                if(visitMap.containsKey('End_Date_Time') && String.isNotBlank(String.valueOf(visitMap.get('End_Date_Time'))))
                    vrc.End_Date_Time__c = DateTime.valueOfGMT(String.valueOf(visitMap.get('End_Date_Time')).replace('T', ' '));
                
                if(visitMap.containsKey('Start_Date_Time') && String.isNotBlank(String.valueOf(visitMap.get('Start_Date_Time'))))
                    vrc.Start_Date_Time__c = DateTime.valueOfGMT(String.valueOf(visitMap.get('Start_Date_Time')).replace('T', ' '));
                
                if(visitMap.containsKey('Mode') && String.isNotBlank(String.valueOf(visitMap.get('Mode'))))
                    vrc.Type_of_Visit__c = (string)visitMap.get('Mode');
                
                if(visitMap.containsKey('Category') && String.isNotBlank(String.valueOf(visitMap.get('Category'))))
                    vrc.Visit_Category__c = (string)visitMap.get('Category');
                
                if(visitMap.containsKey('Nature') && String.isNotBlank(String.valueOf(visitMap.get('Nature'))))
                    vrc.Nature_of_Visit__c = (string)visitMap.get('Nature');
                
                if(visitMap.containsKey('Discussion_Details_from_the_Meeting') && String.isNotBlank(String.valueOf(visitMap.get('Discussion_Details_from_the_Meeting'))))
                    vrc.Discussion_Details_from_the_Meeting__c = (string)visitMap.get('Discussion_Details_from_the_Meeting');
                
                if(visitMap.containsKey('Next_Meeting_Date_agreed_with_Customer') && String.isNotBlank(String.valueOf(visitMap.get('Next_Meeting_Date_agreed_with_Customer'))))
                    vrc.Next_Meeting_Date_agreed_with_Customer__c = date.valueOf((string)visitMap.get('Next_Meeting_Date_agreed_with_Customer'));
                
                if(visitMap.containsKey('tourId') && String.isNotBlank(String.valueOf(visitMap.get('tourId'))))
                    vrc.Name_of_the_Tour__c = (Id)visitMap.get('tourId');
                
                if(visitMap.containsKey('ProjectId') && String.isNotBlank(String.valueOf(visitMap.get('ProjectId'))))
                    vrc.Name_of_the_Project__c = (Id)visitMap.get('ProjectId');
                
                if(visitMap.containsKey('Reason') && String.isNotBlank(String.valueOf(visitMap.get('Reason'))))
                    vrc.Reason__c = (string)visitMap.get('Reason');
                
                if(visitMap.containsKey('Seminar') && String.isNotBlank(String.valueOf(visitMap.get('Seminar'))))
                    vrc.Name_of_the_Conference_Seminar__c = (string)visitMap.get('Seminar');
                
                insert vrc;
                
                // Create task for new record
                Task t1 = new Task();
                t1.OwnerId = UserInfo.getUserId();
                t1.Subject = vrc.Title_of_Meeting__c;
                t1.Status = 'Not Started';
                t1.Priority = 'Normal';
                t1.WhatId = vrc.Id; 
                taskList.add(t1);
                
                // Create event for new record
                e = new Event();
                e.Subject = (string)visitMap.get('Title_of_Meeting');
                
                if (vrc.Start_Date_Time__c != null) {
                    e.StartDateTime = vrc.Start_Date_Time__c;
                }
                
                if (vrc.End_Date_Time__c != null) {
                    e.EndDateTime = vrc.End_Date_Time__c;
                }
                
                if (e.StartDateTime == null) {
                    e.StartDateTime = DateTime.now();
                }
                
                if (e.EndDateTime == null) {
                    e.EndDateTime = e.StartDateTime.addMinutes(30);
                }
                
                e.WhatId = vrc.Id;
                insert e;
            }
            
            // PROCESS ATTENDEES (for both new and existing records)
            List<Attendees__c> attList = new List<Attendees__c>();
            
            // For existing records, delete existing attendees if new ones are provided
            if (existingVisitReportId != null && !String.isBlank(existingVisitReportId) && !AttendeesList.isEmpty()) {
                delete [SELECT Id FROM Attendees__c WHERE Visit_Report__c = :vrc.Id];
            }
            
            for (Object obj : AttendeesList) {
                Map<String, Object> objMap = (Map<String, Object>)obj;
                Attendees__c att = new Attendees__c();
                att.Visit_Report__c = vrc.Id;
                
                // Common fields
                if (objMap.containsKey('Attendee_Type__c')) 
                    att.Attendee_Type__c = (String)objMap.get('Attendee_Type__c');
                if (objMap.containsKey('User_Type__c')) 
                    att.User_Type__c = (String)objMap.get('User_Type__c');
                
                // --- Internal Attendees ---
                if (att.Attendee_Type__c == 'Internal Attendee') {
                    if (att.User_Type__c == 'Existing' && objMap.containsKey('User__c')) {
                        Object userObj = objMap.get('User__c');
                        String userId;
                        
                        if (userObj instanceof List<Object>) {
                            List<Object> userList = (List<Object>)userObj;
                            if (!userList.isEmpty()) {
                                userId = (String)userList[0];
                            }
                        } else {
                            userId = (String)userObj;
                        }
                        
                        if (!String.isBlank(userId)) {
                            att.User__c = userId;
                            
                            // Event relation only for new records
                            if (existingVisitReportId == null || String.isBlank(existingVisitReportId)) {
                                EventRelation er = new EventRelation();
                                er.EventId = e.Id;
                                er.RelationId = userId;
                                er.IsParent = false;
                                er.Status = 'Accepted';
                                eventAttendees.add(er);
                            }
                        }
                    } else if (att.User_Type__c == 'New') {
                        att.First_Name__c = (String)objMap.get('First_Name__c');
                        att.Last_Name__c = (String)objMap.get('Last_Name__c');
                    }
                }
                
                // --- External Attendees ---
                if (att.Attendee_Type__c == 'External Attendee') {
                    if (att.User_Type__c == 'Existing' && objMap.containsKey('Contact_Name__c')) {
                        Object contactObj = objMap.get('Contact_Name__c');
                        if (contactObj != null && String.valueOf(contactObj).startsWith('003')) {
                            att.Contact_Name__c = (Id)String.valueOf(contactObj);
                            
                            // Event relation only for new records
                            if (existingVisitReportId == null || String.isBlank(existingVisitReportId)) {
                                EventRelation er = new EventRelation();
                                er.EventId = e.Id;
                                er.RelationId = att.Contact_Name__c;
                                er.IsParent = false;
                                er.Status = 'Accepted';
                                eventAttendees.add(er);
                            }
                        }
                    } else if (att.User_Type__c == 'New') {
                        att.First_Name__c = (String)objMap.get('First_Name__c');
                        att.Last_Name__c = (String)objMap.get('Last_Name__c');
                        att.Email__c = (String)objMap.get('Email__c');
                        att.Designation__c = (String)objMap.get('Designation__c');
                        att.Mobile_No__c = (String)objMap.get('Mobile_No__c');
                    }
                }
                
                attList.add(att);
            }
            
            // Insert Attendees and EventRelations (only for new records)
            if (!attList.isEmpty()) upsert attList;
            if (!eventAttendees.isEmpty()) insert eventAttendees;
            
           // PROCESS PRODUCT INTERESTS
List<Product_Interest_and_Pricing_Benchmark__c> pIList = new List<Product_Interest_and_Pricing_Benchmark__c>();
for (Object obj : ProductInterestPointList) {
    Map<String, Object> objMap = (Map<String, Object>)obj;
    if(String.isNotBlank(String.valueOf(objMap.get('prodId')))) {
        Product_Interest_and_Pricing_Benchmark__c cp = new Product_Interest_and_Pricing_Benchmark__c();
        cp.Visit_Report__c = vrc.Id;

        // ✅ Use the same currency as the Visit Report (Account's currency)
        cp.CurrencyIsoCode = vrc.CurrencyIsoCode;
        
        if (objMap.containsKey('prodId') && String.isNotBlank(String.valueOf(objMap.get('prodId')))) {
            cp.Product__c = (Id)objMap.get('prodId');
        }
        if (objMap.containsKey('qty') && String.isNotBlank(String.valueOf(objMap.get('qty')))) {
            Decimal qty = Decimal.valueOf(String.valueOf(objMap.get('qty')));
            cp.Expected_Qty_in_Kgs__c = qty > 0 ? qty : null;
        }
        if (objMap.containsKey('ExpDate')) {
            String expDateStr = String.valueOf(objMap.get('ExpDate'));
            if (String.isNotBlank(expDateStr) && expDateStr != 'false') {
                try {
                    cp.Expected_Date__c = Date.valueOf(expDateStr);
                } catch (Exception ex) {
                    // Optionally log or handle the error
                }
            }
        }
        
        if (objMap.containsKey('Price') && String.isNotBlank(String.valueOf(objMap.get('Price')))) {
            Decimal price = Decimal.valueOf(String.valueOf(objMap.get('Price')));
            cp.Expected_Price__c = price > 0 ? price : null;
        }
        
        pIList.add(cp);
    }
}

if(!pIList.isEmpty()) insert pIList;

            
            // PROCESS ACTION POINTS
            string cnTypeId = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Action_Point_Alert' LIMIT 1].Id;
            List<Action_Point__c> apList = new List<Action_Point__c>();
            for (Object obj : ActionPointList) {
                Map<String, Object> objMap = (Map<String, Object>)obj;
                if(String.isNotBlank(String.valueOf(objMap.get('Name')))) {
                    Action_Point__c cp = new Action_Point__c();
                    cp.Visit_Report__c = vrc.Id;
                //    cp.CurrencyIsoCode = currencyCode;
              
                    //vrc = new Visit_Report__c();
                    
                    // Determine currency from Customer_Name__c (Account)
                    if (visitMap.containsKey('Customer_Name') && String.isNotBlank(String.valueOf(visitMap.get('Customer_Name')))) {
                        Id accountId = (Id)visitMap.get('Customer_Name');
                        vrc.Customer_Name__c = accountId;
                        
                        try {
                            Account acc = [SELECT CurrencyIsoCode FROM Account WHERE Id = :accountId LIMIT 1];
                            vrc.CurrencyIsoCode = acc.CurrencyIsoCode;
                        } catch (Exception er) {
                            // fallback to provided currency code in case of error
                            vrc.CurrencyIsoCode = currencyCode;
                        }
                    } else {
                        vrc.CurrencyIsoCode = currencyCode; // fallback
                    }

                    
                    if (objMap.containsKey('Name') && String.isNotBlank(String.valueOf(objMap.get('Name')))) {
                        cp.Name = String.valueOf(objMap.get('Name'));
                    }
                    if (objMap.containsKey('userId') && String.isNotBlank(String.valueOf(objMap.get('userId')))) {
                        cp.Responsibility__c = String.valueOf(objMap.get('userId'));
                    }
                    if (objMap.containsKey('Next_Action_Date') && String.isNotBlank(String.valueOf(objMap.get('Next_Action_Date')))) {
                        cp.Next_Action_Date__c = Date.valueOf(String.valueOf(objMap.get('Next_Action_Date')));
                    }
                    
                    if (objMap.containsKey('Create_Task_Notify')) {
                        cp.Create_Task_Notify__c = (boolean)(objMap.get('Create_Task_Notify'));
                    }
                    
                    apList.add(cp);
                }
            }
            
            if(!apList.isEmpty()) {
                insert apList;
                
                for(Action_Point__c cp: apList) {
                    if (cp.Create_Task_Notify__c == true && String.isNotBlank(cp.Responsibility__c) && cp.Next_Action_Date__c != null) {
                        Task t = new Task();
                        t.OwnerId = cp.Responsibility__c;
                        t.Subject = 'Action Point: ' + cp.Name;
                        t.ActivityDate = cp.Next_Action_Date__c;
                        t.Status = 'Not Started';
                        t.Priority = 'Normal';
                        t.WhatId = cp.Id; 
                        
                        taskList.add(t);
                        
                        Messaging.CustomNotification customNotificationObj = new Messaging.CustomNotification();
                        customNotificationObj.setBody('Please check the action point details');
                        customNotificationObj.setTitle('Action Point: ' + cp.Name);
                        customNotificationObj.setNotificationTypeId(cnTypeId);
                        customNotificationObj.setSenderId(cp.Responsibility__c);
                        customNotificationObj.setTargetId(cp.Id);
                        customNotificationObj.send(new Set<String> {cp.Responsibility__c});
                    }
                }
            }
            
            // INSERT TASKS
            if(!taskList.isEmpty()) insert taskList;
            
            result.put('Message','Success');
            result.put('Id',vrc.Id);
            
        } catch(exception ex) {
            result.put('Message', ex.getLineNumber() + ' ' + ex.getMessage());
            System.debug('Error: ' + ex.getMessage() + ' at line ' + ex.getLineNumber());
        }
        return result;
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getCustomerDetails(Id accountId) {
        Map<String, String> resultMap = new Map<String, String>();
        
        if (accountId != null) {
            Account acc = [
                SELECT Id, SAP_Customer_Code__c, RecordType.DeveloperName,CurrencyIsoCode
                FROM Account
                WHERE Id = :accountId
                LIMIT 1
            ];
            
            // Convert Decimal to String (handle null safely)
            resultMap.put('SAP_Customer_Code__c', acc.SAP_Customer_Code__c != null ? String.valueOf(acc.SAP_Customer_Code__c) : '');
            
            // RecordType is already a String
            resultMap.put('RecordType', acc.RecordType.DeveloperName);

            // CurrencyIsoCode is already a String
            resultMap.put('CurrencyIsoCode', acc.CurrencyIsoCode);
        }
        
        return resultMap;
    }
    
     @AuraEnabled(cacheable=true)
    public static Competitor_Master__c getCompetitorDetails(Id competitorId) {
        if (competitorId == null) return null;

        return [
            SELECT Id, Competitor_Code__c
            FROM Competitor_Master__c
            WHERE Id = :competitorId
            LIMIT 1
        ];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Tour__c> getTours() {
        return [SELECT Id, Name, Tour_Start_Date__c, Tour_End_Date__c FROM Tour__c ORDER BY CreatedDate DESC LIMIT 50];
    }

    @AuraEnabled
    public static Tour__c createTour(String tourName, Date startDate, Date endDate, List<Id> accountIds) {
        Tour__c tour = new Tour__c(
            Name = tourName,
            Tour_Start_Date__c = startDate,
            Tour_End_Date__c = endDate
        );
        insert tour;
        
        // Create Tour Account relationships if accounts are selected
        if (accountIds != null && !accountIds.isEmpty()) {
            // Query Account Names
            Map<Id, Account> accountMap = new Map<Id, Account>(
                [SELECT Id, Name FROM Account WHERE Id IN :accountIds]
            );
            
            List<Customer_Visited__c> tourAccounts = new List<Customer_Visited__c>();
            for (Id accId : accountIds) {
                Account acc = accountMap.get(accId);
                tourAccounts.add(new Customer_Visited__c(
                    Tour__c = tour.Id,
                    Account__c = accId,
                    Name = acc != null ? acc.Name : 'Unknown Account'
                ));
            }
            insert tourAccounts;
        }
        
        return tour;
    }
    
    @AuraEnabled(cacheable=true)
    public static Visit_Report__c getVisitReportDetails(Id visitReportId) {
        return [
            SELECT Id,
            Title_of_Meeting__c, Type_of_Visit__c, Visit_Category__c, Nature_of_Visit__c,
            Customer_Name__c, Customer_Name__r.Name, Customer_Name__r.SAP_Customer_Code__c,
            Competition_Name__c, Competition_Name__r.Name, Competition_Name__r.Competitor_Code__c,
            Name_of_the_Tour__c, Name_of_the_Tour__r.Name,
            Name_of_the_Project__c, Name_of_the_Project__r.Name,
            Reason__c, Name_of_the_Conference_Seminar__c, 
            Discussion_Details_from_the_Meeting__c,
            Start_Date_Time__c, End_Date_Time__c,
            Next_Meeting_Date_agreed_with_Customer__c
            FROM Visit_Report__c
            WHERE Id = :visitReportId
        ];
    }

    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getVisitReportRelatedData(Id visitReportId) {
        Map<String, Object> result = new Map<String, Object>();
        
        // Get Attendees
        result.put('attendees', [
            SELECT Id, Attendee_Type__c, User_Type__c, User__c, Contact_Name__c,
            First_Name__c, Last_Name__c, Email__c, Mobile_No__c, Designation__c
            FROM Attendees__c
            WHERE Visit_Report__c = :visitReportId
        ]);
        
        // Get Product Interests
        result.put('productInterests', [
            SELECT Id, Product__c, Expected_Qty_in_Kgs__c, Expected_Price__c, Expected_Date__c
            FROM Product_Interest_and_Pricing_Benchmark__c
            WHERE Visit_Report__c = :visitReportId
        ]);
        
        // Get Action Points
        result.put('actionPoints', [
            SELECT Id, Name, Responsibility__c, Next_Action_Date__c, Create_Task_Notify__c
            FROM Action_Point__c
            WHERE Visit_Report__c = :visitReportId
        ]);
        
        return result;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Attendees__c> getVisitReportAttendees(Id visitReportId) {
        return [
            SELECT Id, Attendee_Type__c, User_Type__c, 
            User__c, User__r.Name, User__r.FirstName, User__r.LastName, User__r.Email,
            Contact_Name__c, Contact_Name__r.Name, Contact_Name__r.FirstName, 
            Contact_Name__r.LastName, Contact_Name__r.Email, Contact_Name__r.Phone,
            First_Name__c, Last_Name__c, Email__c, Mobile_No__c, Designation__c
            FROM Attendees__c
            WHERE Visit_Report__c = :visitReportId
        ];
    }

}