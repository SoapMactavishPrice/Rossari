public without sharing class OutstandingController {
    @AuraEnabled(cacheable=true)
    public static List<PartyOutstandingWrapper> getBudget(string userId, string fiscId) {
        List<Budget__c> listOfBudget =new  List<Budget__c> ();
         listOfBudget = [SELECT Id,Dist_Channel_Desc__c,CurrencyIsoCode,Distribution_Channel__c,Division__c,Division__r.Name,FY__c,Month__c,Year__c,Name,Sales_Employee__c,Customer_Name__c ,
                        COGS_Kg__c,COGS_Value__c,Customer_Code__c,Customer_Zone__c,division_desc__c,GM_Kg__c,GM_Value__c,Customer_Name__r.Name,
                        HR_Id_Manager__c, Manager__c,Material_Group_Desc__c,Price__c,product_code__c,Product_Description__c,sales_org_description__c,Sales_Organisations__c,
                         
                         Sales_Organisations__r.Name,Distribution_Channel__r.Name,Product_Description__r.Name,
                        Sales_Quantity__c,Sales_Value__c,SAP_Id_Manager__c,SAP_Id_Salesperson__c,Sub_Zone__c,Sub_Zone_Description__c FROM Budget__c
                        where Sales_Employee__c =:userId AND FY__c =:fiscId AND Month__c !=null
                        ];
 
        Map<String, PartyOutstandingWrapper> groupedMap = new Map<String, PartyOutstandingWrapper>();
 
        for (Budget__c rec : listOfBudget) {
            String key = rec.Id;
            if (!groupedMap.containsKey(key)) {
                PartyOutstandingWrapper wrapper = new PartyOutstandingWrapper();
                wrapper.partyName = rec.Customer_Name__r.Name;
                wrapper.Total_Sales_Quantity = 0;
                wrapper.Total_Price = 0;
                wrapper.Total_GM_Kg = 0;
                wrapper.Total_COGS_Value = 0;
                wrapper.Total_COGS_Kg = 0;
                wrapper.Total_GM_Value = 0;
                wrapper.Total_Sales_Value = 0;
                wrapper.records = new List<Budget__c>();
                groupedMap.put(key, wrapper);
            }
 
            PartyOutstandingWrapper existing = groupedMap.get(key);
            existing.records.add(rec);
            existing.Total_Sales_Quantity += (rec.Sales_Quantity__c != null) ? rec.Sales_Quantity__c : 0;
            existing.Total_Price += (rec.Price__c != null) ? rec.Price__c : 0;
            existing.Total_GM_Kg += (rec.GM_Kg__c != null) ? rec.GM_Kg__c : 0;
            existing.Total_COGS_Value += (rec.COGS_Value__c != null) ? rec.COGS_Value__c : 0;
            existing.Total_COGS_Kg += (rec.COGS_Kg__c != null) ? rec.COGS_Kg__c : 0;
            existing.Total_GM_Value += (rec.GM_Value__c != null) ? rec.GM_Value__c : 0;
            existing.Total_Sales_Value += (rec.Sales_Value__c != null) ? rec.Sales_Value__c : 0;
            
        }
 
        return groupedMap.values();
    }
 
    public class PartyOutstandingWrapper {
        @AuraEnabled public String partyName;
        @AuraEnabled public String state;
        @AuraEnabled public String territory;
        @AuraEnabled public String accountGroup;
        @AuraEnabled public String salesPerson;
        @AuraEnabled public Decimal Total_Sales_Quantity;
        @AuraEnabled public Decimal Total_Price;
        @AuraEnabled public Decimal Total_GM_Kg;
        @AuraEnabled public Decimal Total_COGS_Value;
        @AuraEnabled public Decimal Total_COGS_Kg;
        @AuraEnabled public Decimal Total_GM_Value;
        @AuraEnabled public Decimal Total_Sales_Value;
        @AuraEnabled public String onAc;
        @AuraEnabled public List<Budget__c> records;
    }
 
     
  /*  @AuraEnabled(cacheable=true)
public static List<Budget__c> getOutstandingDataList(String erpId) {
    // Fetch and filter records
        List<Outstanding__c> filteredRecords = new List<Outstanding__c>();
    if(erpId==''){
        User currentUser = [SELECT Id, Profile.Name,Email, UserRoleId,UserRole.Name,Is_Sales_Engineer__c FROM User WHERE Id = :UserInfo.getUserId()];
        Id currentUserId = UserInfo.getUserId();
 
        // Fetch User Matrix for logged-in user
        List<User_Matrix__c> userMatrixList = [
            SELECT Account_Group__c
            FROM User_Matrix__c
            WHERE Sales_Person__c = :currentUserId
            LIMIT 1
        ];
 
        // If no User Matrix, return nothing
        if (userMatrixList.isEmpty()) {
            return new List<Outstanding__c>();
        }
 
        // Extract and clean account groups
        Set<String> allowedAccountGroups = new Set<String>();
        String rawGroups = userMatrixList[0].Account_Group__c;
        if (rawGroups != null) {
            for (String grp : rawGroups.split(';')) {
                if (String.isNotBlank(grp)) {
                    allowedAccountGroups.add(grp.trim());
                }
            }
        }
 
        // If no valid groups, return nothing
        if (allowedAccountGroups.isEmpty()) {
            return new List<Outstanding__c>();
        }
 
        
        if(currentUser.Is_Sales_Engineer__c){
            filteredRecords=[SELECT Id,SF_Due_Days__c, Not_Due_Amount__c, Overdue_Amount__c, State_Name__c, Due_Days__c, Territory__c,
                Account_Group__c, Sales_Person__c, Party_Name__c, Credit_days__c, Bill_Amount__c,
                Allocated_Amount__c, Balance_Outstanding__c, Bill_No__c, Bill_Date__c,
                X30_DAYS__c, X30_AND_60__c, X60_AND_90__c, X90_AND_120__c, X120_AND_150__c,
                X150_AND_180__c, X180_AND_210__c, X210_AND_240__c, X240_AND_270__c,
                X270_AND_365__c, Above_1_Year__c, Above_2_Year__c, On_Account__c
            FROM Outstanding__c
            WHERE Account_Group__c IN :allowedAccountGroups
            AND (OwnerId =:currentUserId OR Sales_Person_Email__c=:currentUser.Email)
            ORDER BY Party_Name__c, Bill_Date__c, SF_Due_Days__c DESC];
 
        }else{
            filteredRecords=[SELECT Id,SF_Due_Days__c, Not_Due_Amount__c, Overdue_Amount__c, State_Name__c, Due_Days__c, Territory__c,
                Account_Group__c, Sales_Person__c, Party_Name__c, Credit_days__c, Bill_Amount__c,
                Allocated_Amount__c, Balance_Outstanding__c, Bill_No__c, Bill_Date__c,
                X30_DAYS__c, X30_AND_60__c, X60_AND_90__c, X90_AND_120__c, X120_AND_150__c,
                X150_AND_180__c, X180_AND_210__c, X210_AND_240__c, X240_AND_270__c,
                X270_AND_365__c, Above_1_Year__c, Above_2_Year__c, On_Account__c
            FROM Outstanding__c
            WHERE Account_Group__c IN :allowedAccountGroups
            ORDER BY Party_Name__c, Bill_Date__c, SF_Due_Days__c DESC];
        }   
    }else{
 
             User currentUser = [SELECT Id, Profile.Name,Email, UserRoleId,UserRole.Name,Is_Sales_Engineer__c FROM User WHERE Id = :UserInfo.getUserId()];
        Id currentUserId = UserInfo.getUserId();
 
        // Fetch User Matrix for logged-in user
        List<User_Matrix__c> userMatrixList = [
            SELECT Account_Group__c
            FROM User_Matrix__c
            WHERE Sales_Person__c = :currentUserId
            LIMIT 1
        ];
 
        // If no User Matrix, return nothing
        if (userMatrixList.isEmpty()) {
            return new List<Outstanding__c>();
        }
 
        // Extract and clean account groups
        Set<String> allowedAccountGroups = new Set<String>();
        String rawGroups = userMatrixList[0].Account_Group__c;
        if (rawGroups != null) {
            for (String grp : rawGroups.split(';')) {
                if (String.isNotBlank(grp)) {
                    allowedAccountGroups.add(grp.trim());
                }
            }
        }
 
        // If no valid groups, return nothing
        if (allowedAccountGroups.isEmpty()) {
            return new List<Outstanding__c>();
        }
 
        if(currentUser.Is_Sales_Engineer__c){
            filteredRecords=[SELECT Id,SF_Due_Days__c, Not_Due_Amount__c, Overdue_Amount__c, State_Name__c, Due_Days__c, Territory__c,
                Account_Group__c, Sales_Person__c, Party_Name__c, Credit_days__c, Bill_Amount__c,
                Allocated_Amount__c, Balance_Outstanding__c, Bill_No__c, Bill_Date__c,
                X30_DAYS__c, X30_AND_60__c, X60_AND_90__c, X90_AND_120__c, X120_AND_150__c,
                X150_AND_180__c, X180_AND_210__c, X210_AND_240__c, X240_AND_270__c,
                X270_AND_365__c, Above_1_Year__c, Above_2_Year__c, On_Account__c
            FROM Outstanding__c
            WHERE Account_Group__c IN :allowedAccountGroups
            AND (OwnerId =:currentUserId OR Sales_Person_Email__c=:currentUser.Email)
            AND ERP_ID__c=:erpId
            ORDER BY Party_Name__c, Bill_Date__c, SF_Due_Days__c DESC];
 
        }else{
            filteredRecords=[SELECT Id,SF_Due_Days__c, Not_Due_Amount__c, Overdue_Amount__c, State_Name__c, Due_Days__c, Territory__c,
                Account_Group__c, Sales_Person__c, Party_Name__c, Credit_days__c, Bill_Amount__c,
                Allocated_Amount__c, Balance_Outstanding__c, Bill_No__c, Bill_Date__c,
                X30_DAYS__c, X30_AND_60__c, X60_AND_90__c, X90_AND_120__c, X120_AND_150__c,
                X150_AND_180__c, X180_AND_210__c, X210_AND_240__c, X240_AND_270__c,
                X270_AND_365__c, Above_1_Year__c, Above_2_Year__c, On_Account__c
            FROM Outstanding__c
            WHERE Account_Group__c IN :allowedAccountGroups
            AND ERP_ID__c=:erpId
            ORDER BY Party_Name__c, Bill_Date__c, SF_Due_Days__c DESC];
        }
    }
    
 
    return filteredRecords;
}
 */
 
 
}