public class TargetNewController {
    @AuraEnabled
    public static FY__c getDefualtFiscId(){
        return [select Id,FY_Start_Date__c,FY_End_Date__c from FY__c where isActive__c=:true];
    }
    
    @AuraEnabled 
    public static void updateOnDemand(string Id,string feild, string value){
        system.debug('Id-->'+Id);
        system.debug('feild-->'+feild);
        system.debug('value-->'+value);
        Target__c target = new Target__c();
        target.Id = Id;
        if(feild.contains('Sales_Qauntity__c')){
            target.Quantity__c = value != null 
                ? double.valueOf(value) 
                : 0;
        }
        
        if(feild.contains('COGS_Kg__c')){
            target.Budgeted_COGS__c = value != null 
                ? double.valueOf(value)
                : 0;
        }
        
        if(feild.contains('GM_Kg__c')){
            target.Budgeted_GM_KG__c = value != null 
                ? double.valueOf(value)
                : 0;
        }
        
        if(feild.contains('Price__c')){
            target.Amount__c = value != null 
                ? double.valueOf(value)
                : 0;
        }
        update target;
        
        
    }
    
     
    
    @AuraEnabled
    public static List<Target__c> getExistingData(string usId, string fyId){
        
        List<Target__c> targetList = new List<Target__c>();
        targetList = [Select Id, FY__c, Product_Description__c,Sales_Employee__c, Month__c,Year__c,Quantity__c,COGS_Value__c,GM_Kg__c,Gross_Margin__c,
                      Budgeted_COGS__c,Budgeted_GM_KG__c,Amount__c,Product__c,Product_Code__c from Target__c where 
                      Sales_Employee__c=:usId AND FY__c=:fyId];
        
        return targetList;
    }
    
    @AuraEnabled
    public static List<Product2> getProductList(String itemGroupId) {
        
        String query = 'SELECT Id, Name, ProductCode, Description, Item_Group__c, Item_Group__r.Name FROM Product2 WHERE IsActive = true';
        
       
        if (itemGroupId != null && itemGroupId != '') {
            query += ' AND Item_Group__c = :itemGroupId';
        }
        
        query += ' ORDER BY CreatedDate ASC LIMIT 50';
        
       
        List<Product2> results = Database.query(query);
        
        
        Map<String, Product2> uniqueProducts = new Map<String, Product2>();
        for (Product2 p : results) {
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
            List<Target__c> targetListToInsert = new List<Target__c>();
            List<object> objList =(List<object>)JSON.deserializeUntyped(js);  
            for(object objRecord : objList){
                system.debug('obj-->'+objRecord);
                Map<string,Object> obj = (Map<string,Object>)objRecord; 
                Target__c target = new Target__c();
                target.FY__c = fyId;
                target.Product_Description__c= (string)obj.get('Description');
                target.Sales_Employee__c = userId;
                string monthOrYearVal =(string)obj.get('MonthName');
                string month = monthOrYearVal.substringBefore('-');
                string year = monthOrYearVal.substringAfter('-');
                
                target.Month__c = month;
                target.Year__c = year;
                // Quantity is an Integer
                target.Quantity__c = obj.get('Sales_Qauntity__c') != null 
                    ? double.valueOf(String.valueOf(obj.get('Sales_Qauntity__c'))) 
                    : 0;
                
                // The rest are Decimals
                target.Budgeted_COGS__c = obj.get('COGS_Kg__c') != null 
                    ? Decimal.valueOf(String.valueOf(obj.get('COGS_Kg__c'))) 
                    : 0;
                
                target.Budgeted_GM_KG__c = obj.get('GM_Kg__c') != null 
                    ? Decimal.valueOf(String.valueOf(obj.get('GM_Kg__c'))) 
                    : 0;
                
                target.Amount__c = obj.get('Price__c') != null 
                    ? Decimal.valueOf(String.valueOf(obj.get('Price__c'))) 
                    : 0;
                target.Product__c = (string)obj.get('ProductId') !=null ? (string)obj.get('ProductId'):null;
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