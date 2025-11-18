public class NewProductDevelopmentTriggerHandler {
    
    public static void handleBeforeInsert(List<New_Product_Development__c> newRecords) {
        Id currentUserId = UserInfo.getUserId();
        
        for(New_Product_Development__c npd : newRecords) {
            npd.Is_New_NPD__c = true;
            npd.Stage__c = 'NPD New Request';

            if (npd.Sales_Person_Name__c == null) {
                npd.Sales_Person_Name__c = currentUserId;
            }
        }
    }
}