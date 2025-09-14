public class BudgetReport {
    
    @AuraEnabled
    public static string getDefualtFiscId(){
        return [select Id from FY__c where isActive__c=:true].Id;
    }
   
    @AuraEnabled
    public static List<Budget__c> getBudget(string userId, string fiscId){
        system.debug('userId-->'+userId);
        system.debug('fiscId-->'+fiscId);
         List<Budget__c> listOfBudget =new  List<Budget__c> ();
         listOfBudget = [SELECT Id,Dist_Channel_Desc__c,CurrencyIsoCode,Distribution_Channel__c,Division__c,Division__r.Name,FY__c,Month__c,Year__c,Name,Sales_Employee__c,Customer_Name__c ,
                        COGS_Kg__c,COGS_Value__c,Customer_Code__c,Customer_Zone__c,division_desc__c,GM_Kg__c,GM_Value__c,Customer_Name__r.Name,
                        HR_Id_Manager__c, Manager__c,Material_Group_Desc__c,Price__c,product_code__c,Product_Description__c,sales_org_description__c,Sales_Organisations__c,
                         
                         Sales_Organisations__r.Name,Distribution_Channel__r.Name,Product_Description__r.Name,
                        Sales_Quantity__c,Sales_Value__c,SAP_Id_Manager__c,SAP_Id_Salesperson__c,Sub_Zone__c,Sub_Zone_Description__c FROM Budget__c where
                        Fy__c=:fiscId AND Sales_Employee__c = :userId];
       system.debug('BudgetReport-->'+listOfBudget.size());
        return listOfBudget;
      }
    
    
    @AuraEnabled(cacheable=true)
    public static PartyOutstandingWrapper getBudgetSummary(string userId, string fiscId) {
        List<Budget__c> listOfBudget =new  List<Budget__c> ();
         listOfBudget = [SELECT Id,Dist_Channel_Desc__c,CurrencyIsoCode,Distribution_Channel__c,Division__c,Division__r.Name,FY__c,Month__c,Year__c,Name,Sales_Employee__c,Customer_Name__c ,
                        COGS_Kg__c,COGS_Value__c,Customer_Code__c,Customer_Zone__c,division_desc__c,GM_Kg__c,GM_Value__c,Customer_Name__r.Name,
                        HR_Id_Manager__c, Manager__c,Material_Group_Desc__c,Price__c,product_code__c,Product_Description__c,sales_org_description__c,Sales_Organisations__c,
                         
                         Sales_Organisations__r.Name,Distribution_Channel__r.Name,Product_Description__r.Name,
                        Sales_Quantity__c,Sales_Value__c,SAP_Id_Manager__c,SAP_Id_Salesperson__c,Sub_Zone__c,Sub_Zone_Description__c FROM Budget__c
                        
                        ];
 
        Map<String, PartyOutstandingWrapper> groupedMap = new Map<String, PartyOutstandingWrapper>();
 		PartyOutstandingWrapper wrapper = new PartyOutstandingWrapper();
        for (Budget__c rec : listOfBudget) {
            if (!groupedMap.containsKey(rec.Id)) {
                wrapper.Total_Sales_Quantity += (rec.Sales_Quantity__c != null) ? rec.Sales_Quantity__c : 0;
                wrapper.Total_Price += (rec.Price__c != null) ? rec.Price__c : 0;
                wrapper.Total_GM_Kg += (rec.GM_Kg__c != null) ? rec.GM_Kg__c : 0;
                wrapper.Total_COGS_Value += (rec.COGS_Value__c != null) ? rec.COGS_Value__c : 0;
                wrapper.Total_COGS_Kg += (rec.COGS_Kg__c != null) ? rec.COGS_Kg__c : 0;
                wrapper.Total_GM_Value += (rec.GM_Value__c != null) ? rec.GM_Value__c : 0;
                wrapper.Total_Sales_Value += (rec.Sales_Value__c != null) ? rec.Sales_Value__c : 0;
                
            }
  
        }
        
        ///groupedMap.put(userId, wrapper);
 
        return wrapper;
    }
 
    public class PartyOutstandingWrapper {
        @AuraEnabled public String partyName;
        @AuraEnabled public String state;
        @AuraEnabled public String territory;
        @AuraEnabled public String accountGroup;
        @AuraEnabled public String salesPerson;
        @AuraEnabled public Decimal Total_Sales_Quantity = 0;
        @AuraEnabled public Decimal Total_Price= 0;
        @AuraEnabled public Decimal Total_GM_Kg= 0;
        @AuraEnabled public Decimal Total_COGS_Value= 0;
        @AuraEnabled public Decimal Total_COGS_Kg= 0;
        @AuraEnabled public Decimal Total_GM_Value= 0;
        @AuraEnabled public Decimal Total_Sales_Value= 0;
        @AuraEnabled public String onAc;
    }
 

}