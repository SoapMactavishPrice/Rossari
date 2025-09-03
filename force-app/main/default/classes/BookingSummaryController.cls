public class BookingSummaryController {

     @AuraEnabled
    public static FY__c getDefualtFiscId(){
        return [select Id,FY_Start_Date__c,FY_End_Date__c from FY__c where isActive__c=:true];
    }
    
    @AuraEnabled
    public static List<Account> getDefualtAccount(string ownerId){
        return [select Id,Name from Account where CurrencyIsoCode !=null and OwnerId=:ownerId];
    }
     
    
  @AuraEnabled
    public static List<Booking_Target__c> getAllExistingData(string usId, string fyId){
      
        List<Booking_Target__c> targetList = new List<Booking_Target__c>();
        targetList = [Select Id, FY__c, Product__c,Sales_Employee__c,Sales_Value__c, Month__c,Account__c,Year__c,Sales_Quantity__c,COGS_Value__c,GM_Kg__c,Gross_Margin__c,
                      COGS_Rate__c,Budget_Rate__c,Product_Code__c from Booking_Target__c where 
                      Sales_Employee__c=:usId AND FY__c=:fyId ];
        
        system.debug('targetList-->'+targetList.size());
        return targetList;
    }
    
                
   @AuraEnabled
    public static List<Booking_Target__c> getExistingData(string usId, string fyId ,string accId){
        system.debug('accId-->'+accId);
        
        List<Booking_Target__c> targetList = new List<Booking_Target__c>();
        targetList = [Select Id, FY__c, Product__c,Sales_Employee__c, Month__c,Account__c,Year__c,Sales_Quantity__c,COGS_Value__c,GM_Kg__c,Gross_Margin__c,
                      COGS_Rate__c,Budget_Rate__c,Product_Code__c from Booking_Target__c where 
                      Sales_Employee__c=:usId AND FY__c=:fyId AND Account__c=:accId];
        
        system.debug('targetList-->'+targetList.size());
        return targetList;
    }
    
    
     @AuraEnabled 
    public static void updateOnDemand(string Id,string feild, string value){
        system.debug('Id-->'+Id);
        system.debug('feild-->'+feild);
        system.debug('value-->'+value);
        Booking_Target__c target = new Booking_Target__c();
        target.Id = Id;
        if(feild.contains('Sales_Qauntity__c')){
            target.Sales_Quantity__c = value != null 
                ? double.valueOf(value) 
                : 0;
        }
        
        if(feild.contains('COGS_Kg__c')){
            target.COGS_Rate__c = value != null 
                ? double.valueOf(value)
                : 0;
        }
        
       
        
        if(feild.contains('Price__c')){
            target.Budget_Rate__c = value != null 
                ? double.valueOf(value)
                : 0;
        }
        update target;
        
        
    }
    
    
     @AuraEnabled
    public static List<Product2> getProductList() {
        List<Product2> prodList = [
            SELECT Id, Name, ProductCode, Description 
            FROM Product2 
            WHERE IsActive = true 
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];
        
        // Use a Map to avoid duplicates by ProductCode
        Map<String, Product2> uniqueProducts = new Map<String, Product2>();
        for (Product2 p : prodList) {
            if (String.isNotBlank(p.ProductCode) && !uniqueProducts.containsKey(p.ProductCode)) {
                uniqueProducts.put(p.ProductCode, p);
            }
        }
        
        return new List<Product2>(uniqueProducts.values());
    }
    
    @AuraEnabled 
    public static string saveToServer (string js,string userId,string fyId){
        system.debug('userId-->'+userId);
        system.debug('fyId-->'+fyId);
        try{
            List<Booking_Target__c> targetListToInsert = new List<Booking_Target__c>();
            List<object> objList =(List<object>)JSON.deserializeUntyped(js);  
            for(object objRecord : objList){
                system.debug('obj-->'+objRecord);
                Map<string,Object> obj = (Map<string,Object>)objRecord; 
                Booking_Target__c target = new Booking_Target__c();
                target.FY__c = fyId;
                target.Product__c= (string)obj.get('ProductId');
                target.Sales_Employee__c = userId;
                string monthOrYearVal =(string)obj.get('MonthName');
                string month = monthOrYearVal.substringBefore('-');
                string year = monthOrYearVal.substringAfter('-');
                
                target.Month__c = month;
                target.Year__c = year;
                // Quantity is an Integer
                target.Sales_Quantity__c = obj.get('Sales_Qauntity__c') != null 
                    ? double.valueOf(String.valueOf(obj.get('Sales_Qauntity__c'))) 
                    : 0;
                
                // The rest are Decimals
                target.COGS_Rate__c = obj.get('COGS_Kg__c') != null 
                    ? Decimal.valueOf(String.valueOf(obj.get('COGS_Kg__c'))) 
                    : 0;
                
                //target.GM_Kg__c = obj.get('GM_Kg__c') != null 
                  //  ? Decimal.valueOf(String.valueOf(obj.get('GM_Kg__c'))) 
                    //: 0;
                
               target.Budget_Rate__c = obj.get('Price__c') != null 
                  ? Decimal.valueOf(String.valueOf(obj.get('Price__c'))) 
                : 0;
                target.Account__c = (string)obj.get('CustomerId') !=null ? (string)obj.get('CustomerId'):null;
                target.Product_Code__c = (string)obj.get('ProductCode') !=null ? (string)obj.get('ProductCode'):null;
                targetListToInsert.add(target);
            }
            
            system.debug('targetListToInsert->'+targetListToInsert.size());
            if(targetListToInsert.size()  > 0){
                insert targetListToInsert;
            }
            return 'Success';
        }catch(exception e){
            return 'line-->'+e.getLineNumber() +' message '+e.getMessage();
        }
        
    }
}