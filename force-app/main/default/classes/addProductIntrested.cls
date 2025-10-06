public class addProductIntrested {
    
    
    @AuraEnabled 
    public static Map<string,object> getProdInterest(string Id){
        Map<string,object> result = new Map<string,object>();
        Lead leadRecord = [select id, CurrencyIsoCode, RecordType.Name from lead where Id =:Id LIMIT 1];
        result.put('currencyCode', leadRecord.CurrencyIsoCode);
        result.put('leadRecordType', leadRecord.RecordType != null ? leadRecord.RecordType.Name : null);
        
        List<Product_Interested__c> piList= [
            SELECT Id, Product__c, Product__r.Name,Price_book_Entry_Id__c, 
                New_Product_Name__c, New_Product__c, List_Price__c, 
                Quantity_in_Kgs__c, Expected_Price__c, //Product_Family__c, 
                Add_in_Opportunity__c, Product_Code__c, Quantity_Frequency__c, Name 
            FROM Product_Interested__c 
            WHERE Lead__c =:Id 
            ORDER BY CreatedDate
        ];
        
        result.put('piList', piList);
        return result;
    }
    
    @AuraEnabled 
    public static string deleteProductInterested(string Id){
         Product_Interested__c  piList= [Select Id,Product__c,Product__r.Name,Quantity_in_Kgs__c,Expected_Price__c,New_Product__c,New_Product_Name__c,//Product_Family__c,
                                         Add_in_Opportunity__c,
                                              Product_Code__c,Quantity_Frequency__c, Name from Product_Interested__c where Id=:Id limit 1];
        string pInName =piList.Name;
        delete piList; 
        return 'Product Interested record deleted '+pInName;
    }
    
    
    
   @AuraEnabled(Cacheable=true)
    public static List<Id> getExistingProducts(string Id){
        List<Id> ids = new List<Id>();
        List<Product_Interested__c> pi= [Select Id,Product__c from Product_Interested__c where Lead__c=:Id];
        for(Product_Interested__c p : pi){
            ids.add(p.Product__c);
            }
        return ids;       
    }
    
   
      @AuraEnabled(Cacheable=true)
public static Map<String, List<Map<String, String>>> getPicklistValues() {
    Map<String, List<Map<String, String>>> allPicklists = new Map<String, List<Map<String, String>>>();
    
    
    // Volume Frequency picklist
    Schema.DescribeFieldResult frequencyField = Product_Interested__c.Quantity_Frequency__c.getDescribe();
    List<Map<String, String>> frequencyList = new List<Map<String, String>>();
    for (Schema.PicklistEntry frequencyPick : frequencyField.getPicklistValues()) {
        frequencyList.add(new Map<String, String>{
            'label' => frequencyPick.getLabel(),
            'value' => frequencyPick.getValue()
        });
    }
    allPicklists.put('frequency', frequencyList);
    
    return allPicklists;
}
    
    @AuraEnabled
    public static Map<string,string> saveProductInterested(Id Id, string JS){
        system.debug('Id'+Id);
        system.debug('JS'+JS);
        Map<string,string> result = new Map<string,string>();
        try{
            
            List<Product_Interested__c> piList = new List<Product_Interested__c>();
            
            List<Object> jsList = (List<Object>)JSON.deserializeUntyped(JS);
            
            for(Object obj : jsList){
                Map<string,object>objMap = (Map<string,object>)obj;
                Product_Interested__c pm = new Product_Interested__c();
                if(string.isNotBlank((string) objMap.get('inId'))){
                   pm.Id = (Id)objMap.get('inId');
                }
                pm.Lead__c  =Id ;
                if(string.isNotBlank((string)objMap.get('prodId'))){
                pm.Product__c = (Id)objMap.get('prodId');
                }
                pm.Quantity_in_Kgs__c = double.valueOf(objMap.get('volume'));
             //   pm.Expected_Price__c = double.valueOf(objMap.get('price'));
             	
                pm.Price_book_Entry_Id__c = (string)objMap.get('pbeId');
                pm.List_Price__c = double.valueOf(objMap.get('unitPrice'));
            //    pm.Product_Family__c = (string) objMap.get('prodFamily');
                pm.Add_in_Opportunity__c = (boolean) objMap.get('Add_In_Opty');
                
                pm.New_Product_Name__c = (string) objMap.get('New_Product_Name');
                pm.New_Product__c = (boolean) objMap.get('New_Product');
                pm.Quantity_Frequency__c = (String) objMap.get('frequency');
                
                // Updated version with null/blank check
                Object priceValue = objMap.get('price');
                if (priceValue != null && String.isNotBlank(String.valueOf(priceValue))) {
                    pm.Expected_Price__c = double.valueOf(priceValue);
                } else {
                    pm.Expected_Price__c = null; // or 0 if you prefer
                }
                piList.add(pm);
            }
            
            if(piList.size() > 0){
                upsert piList;
            }
            
            result.put('message','success');  
        }catch(exception e){
            system.debug(e);
            result.put('message',e.getLineNumber()+' - '+e.getMessage()); 
        }
        return result;
    }
  
    
}