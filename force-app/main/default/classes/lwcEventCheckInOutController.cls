public with sharing class lwcEventCheckInOutController {
    public lwcEventCheckInOutController() {
        
    }
    @AuraEnabled
    public static string updateCheckIn(String recordId, Decimal latitude, Decimal longitude) {
        try {
            // Retrieve the Event record to check its Check_In_Time__c
            Event ev = [SELECT Id, Check_In_Time__c FROM Event WHERE Id = :recordId LIMIT 1];
            
            // Check if Check_In_Time__c is already set (i.e., already checked in)
            if (ev.Check_In_Time__c != null) {
                return 'Already Checked In'; // You can return a specific message here
            }
            
            // If not already checked in, update the record with the new latitude and longitude
            ev.Check_In_GeoLocation__Latitude__s = latitude;
            ev.Check_In_GeoLocation__Longitude__s = longitude;
            ev.Check_In_Time__c = System.now();
            
            update ev;
            
            return 'Success';
        } catch (Exception e) {
            System.debug(e);
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    
    @AuraEnabled
    public static string updateEventRecord(String recordId, Decimal latitude, Decimal longitude) {
        try {
            Event ev = new Event();
            ev.Id = recordId;
            
            ev.Check_In_GeoLocation__Latitude__s = latitude;
            ev.Check_In_GeoLocation__Longitude__s = longitude;
            ev.Check_In_Time__c = System.now();
            
            update ev;
            
            return 'Success';
        } catch (Exception e) {
            System.debug(e);
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static string updateCheckOut(String recordId, Decimal latitude, Decimal longitude,String VisitResult,String Description,String Client_Feedback_Or_Insights,String Action_To_Do, Date Date_Of_Visit) {
        
        try {
            if (String.isBlank(recordId)) {
                throw new AuraHandledException('Event record ID is required.');
            }
            Event ev = new Event();
            ev.Id = recordId;
            
            ev.Check_Out_GeoLocation__Latitude__s = latitude;
            ev.Check_Out_GeoLocation__Longitude__s = longitude;
            ev.Check_Out_Time__c = System.now();
            ev.Description = Description;
            
            update ev;
            
            return 'Success';
        } catch (Exception e) {
            System.debug(e);
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Event getEventById(Id recordId) {
        // Query the Event record dynamically based on recordId
        
        return [SELECT Id, Description FROM Event WHERE Id = :recordId];
    }
    
    
    @AuraEnabled
    public static Event updateEventById(Id recordId ,Map<String, Object> formData) {
        // List<Object> lineListdata = (List<Object>) JSON.deserializeUntyped(porLineItemList);
        
        try {  
            Event ev = [SELECT Id FROM Event WHERE Id = :recordId LIMIT 1];
            
            for (String fieldName : formData.keySet()) {
                Object fieldValue = formData.get(fieldName);
                
                // Check the field type before assigning (assuming all are Strings for simplicity)
                if (fieldValue != null) {
                    ev.put(fieldName, fieldValue);
                }
            }
            update ev;
            
            return ev;
        } catch (Exception e) {
            System.debug(e);
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
        
    }
    
}