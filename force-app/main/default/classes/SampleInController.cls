public class SampleInController {

    @AuraEnabled(cacheable = true)
    public static string getSampleInInfo(string SampleInId){
        system.debug('SampleInId-->'+SampleInId);
        Sample_In__c ld =  [select Id, Name, Competitor_Name__c,Remark__c, Sample_Sent_To_Unit__c, Sample_Received_Date__c, Sample_Sent_To_Factory_From_HO__c 
                            from Sample_In__c where Id =: SampleInId limit 1];

        wrapper wrp = new wrapper();
     //   wrp.Kind_Attention = ld.Name;
     //   wrp.Consignee_Name = ld.Company;
    //    wrp.Email_Id = ld.email;//
    //    wrp.Contact_No = ld.Phone;
        return JSON.serialize(wrp);
        
    }
    
    @AuraEnabled
    public static string saveSample(string leadId,string sampleJs, string sampleLine){
        try{
             system.debug('sampleJs-->'+leadId);
             system.debug('sampleJs-->'+sampleJs);
            system.debug('sampleJs-->'+sampleLine);
            Map<String, Object> sampleData = (Map<String, Object>) System.JSON.deserializeUntyped(sampleJs);
           
            String CompetitorName = (String) sampleData.get('Competitor_Name');
            String sampleSentToPlant = (String) sampleData.get('Sample_Sent_To_Unit');
            String SampleReceivedDate = (String) sampleData.get('Sample_Received_Date');
            String SampleSentToFactoryFromHO = (String) sampleData.get('Sample_Sent_To_Factory_From_HO');
            String CourierName = (String) sampleData.get('Courier_Name');
            String CourierTrackingNo = (String) sampleData.get('Courier_Tracking_No');
            String OtherRemark = (String) sampleData.get('Remark');
            String AccountNo = (String) sampleData.get('Account_No');
        
            System.debug('CompetitorName: ' + CompetitorName);
            System.debug('sampleSentToPlant: ' + sampleSentToPlant);
            System.debug('SampleReceivedDate: ' + SampleReceivedDate);
            System.debug('SampleSentToFactoryFromHO: ' + SampleSentToFactoryFromHO);
            System.debug('CourierName: ' + CourierName);
            System.debug('CourierTrackingNo: ' + CourierTrackingNo);
            System.debug('AccountNo: ' + AccountNo);
            System.debug('OtherRemark: ' + OtherRemark);
            
            // Create the Sample_Request__c record
            Sample_In__c src = new Sample_In__c();
            src.Sample_Request__c = leadId;
            src.Competitor_Name__c = CompetitorName; // Converting string to Date
            src.Sample_Received_Date__c = Date.valueOf(SampleReceivedDate); // Converting string to Date
            src.Sample_Sent_To_Unit__c = sampleSentToPlant;
            src.Sample_Sent_To_Factory_From_HO__c = Date.valueOf(SampleSentToFactoryFromHO); // Converting string to Date
            src.Courier_Name__c = CourierName;
            src.Remark__c = OtherRemark;
          //  src.Email_Id__c = emailId;
            insert src;
            List<Sample_In_Line_Item__c> srcList = new List<Sample_In_Line_Item__c>();
            List<wrapperLine> wrpList = parseLine(sampleLine);
            for(wrapperLine wrpl : wrpList){
                Sample_In_Line_Item__c srl = new Sample_In_Line_Item__c();  
                srl.Sample_In__c = src.Id;
                srl.Customer_Product_Name__c = wrpl.prodName;
                srl.Received_Sample_Qty_in_Kgs__c = wrpl.qty;
                srl.application__c = wrpl.application;
                srcList.add(srl);
            }
            if(srcList.size()> 0){
                insert srcList;
            }
            return src.Id;
        }catch(exception e){
            system.debug(e.getMessage() + e.getLineNumber());
            return e.getMessage() + e.getLineNumber(); 
        }
        
    }
    
    
    public static wrapper parse(string js){
        return (wrapper)system.JSON.deserialize(js,wrapper.class);
    }
    
    public static List<wrapperLine> parseLine(string js){
        return (List<wrapperLine>)system.JSON.deserialize(js,List<wrapperLine>.class);
    }
    
    public static Date parseDate(String dateStr) {
        try {
            return Date.valueOf(dateStr);
        } catch (Exception e) {
            System.debug('Invalid date format: ' + dateStr);
            return null;
        }
    }
    
    public class wrapper {
        public String CompetitorName;
        public String sampleSentToPlant;
        public String SampleReceivedDate;
        public String SampleSentToFactoryFromHO;
        public String CourierName;
        public String CourierTrackingNo;
        public String OtherRemark;
        public String AccountNo;
      //  public String Contact_No;
     //   public String Consignee_Name;
        
    }
    
    
    public class wrapperLine {
        public string sqNo;
        public string Product;
        public string prodName;
        public string Product_Code;
        public string Description;
        public decimal qty;
        public string application;
    }
    
}