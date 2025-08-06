/**
* @File Name : AccountMasterAPI.cls
* @Description :
* @Author : Shashank
* @Last Modified By :
* @Last Modified On : August 5, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | August 5, 2025 | Shashank  | Initial Version
**/

@RestResource(urlMapping = '/accountMaster/*')
global  class AccountMasterAPI {
    
//     @HttpPost
//     global static void doPost() {
//         RestResponse response;
//         RestRequest request;
//         API_log__c apiLog=new API_log__c();
//         apiLog.Name ='Customer Master';
        
        
//         List<AccountMasterJson> jData ;
//         map<String,Account> accountList = new map<String,Account>();
        
//         map<String,Contact> contactList = new  map<String,Contact>();
//         map<String,Address_Information__c> addressInfoList = new  map<String,Address_Information__c>();
//         map<String,Customer_Sales_Area_Line_Item__c> cSalesAreaLinList = new  map<String,Customer_Sales_Area_Line_Item__c>();
//         map<String,Bank_Information__c> bankInfoList = new  map<String,Bank_Information__c>();
        
//         Savepoint sp = Database.setSavepoint();
//         try {  
            
//             request = RestContext.request;
//             response = RestContext.response;
//             String jSONRequestBody = request.requestBody.toString().trim();
//             if (String.isBlank(jSONRequestBody)) {
//                 throw new CustomException('No Customer data found');
                
//             }
//             System.debug('IjSONRequestBody=' + jSONRequestBody);
//             jData = parse(jSONRequestBody);
//             System.debug('Json--' + jData);
//             //apiLog.Request__c='Total Size ='+jData.size();
//             apiLog.Request__c='Total Size ='+jData.size()+'-'+jSONRequestBody;
            
//             map<String,AccountMasterJson> responceIdMap =new map<String,AccountMasterJson>();
            
//             map<String,String> mapTem =new map<String,String>();
            
//             List<String> companyCode = new List<String>();
//             List<String> slorgList = new List<String>();
//             List<String> disChlList = new List<String>();
//             List<String> divList = new List<String>();
//             List<String> plantCode = new List<String>();
//             List<String> accIdList = new List<String>();
            
//             List<String> pfList = new List<String>();
//             List<String> sAreaList = new List<String>();
//             List<String> bankList = new List<String>();
//             List<String> userSAPCodeList = new List<String>();
//             List<String> parAccountList = new List<String>();
            
//             Map<String,String> countryPickListMap =new  Map<String,String>();
//             Map<String,String> statePickListMap =new  Map<String,String>();
            
            
//             countryPickListMap=UtilityCls.picklistValues('Address_Information__c','Country_Code_Temp__c');
//             statePickListMap=UtilityCls.picklistValues('Address_Information__c','State_Code_Temp__c');
            
            
            
//             for (AccountMasterJson jd : jData) {
                
//                 responceIdMap.put(jd.CUSTOMER_NO, jd);
                
//                 companyCode.add(jd.COCODE);
//                 slorgList.add(jd.SALES_ORG);
//                 disChlList.add(jd.DISTR_CHL);
//                 divList.add(jd.DIVISION);
//                 plantCode.add(jd.DELIVERY_PLANT);
                
//                 for (cls_PARTNERFUNCTION_LIST pf : jd.PARTNERFUNCTION_LIST) {
//                    // pfList.add(pf.CUSTOMER_NO+'_'+pf.PARTNERFN);
//                     if (pf.PARTNERFN=='ZM' || pf.PARTNERFN=='ZE' ) {
//                         userSAPCodeList.add(pf.CUSTOMR_NO);
//                     }else{
//                         parAccountList.add(pf.CUSTOMER_NO);
//                     }
//                     if(String.isBlank(pf.CUSTOMER_NO)&&String.isNotBlank(pf.CUSTOMR_NO)){
//                          pf.CUSTOMER_NO=pf.CUSTOMR_NO;
//                     }

//                     pfList.add(jd.CUSTOMER_NO+'_'+pf.CUSTOMER_NO+'_'+pf.PARTNERFN);
//                 }
                
//                 for (cls_SALES_AREA_LIST sa : jd.SALES_AREA){
//                     sAreaList.add(jd.CUSTOMER_NO+'_'+sa.SALES_ORG+'_'+sa.DISTR_CHL+'_'+sa.DIVISION);
//                 }
                
//                 for (cls_BANK_DETAILS_LIST sa : jd.BANK_DETAILS){
                    
//                     bankList.add(jd.CUSTOMER_NO+'_'+sa.BANK_ACC_NO);
//                 }
                
//             }
            
            
            
            
            
            
            
            
//             map<String,String>  accgrpPkList=    UtilityCls.picklistValues('Account', 'Account_Group__c');
//             map<String,String>  titlePkList=    UtilityCls.picklistValues('Account', 'Title__c');
            
//             //Contact
//             List<Contact>  ctList = new   List<Contact>();
//             ctList=[Select id,name,account.Name,account.SAP_Customer_Code__c from contact where account.SAP_Customer_Code__c=:responceIdMap.keySet() ];
            
//             map<String,Contact> mapContaccTemp = new map<String,Contact>();
//             for (Contact cn : ctList) {
//                 mapContaccTemp.put(cn.account.SAP_Customer_Code__c, cn);
                
//             }
            
            
//             //Partner Function
//             List<Address_Information__c> addInfList = new List<Address_Information__c> ();
//             map<String,Address_Information__c> mapAddInf = new map<String,Address_Information__c>();
            
//             addInfList=[SELECT ID,Unique_Record__c   FROM Address_Information__c WHERE Unique_Record__c=:pfList];
            
            
//             for (Address_Information__c af : addInfList) {
//                 mapAddInf.put(af.Unique_Record__c,af);
                
//             }
            
            
//             //Customer Sales Area 
//             List<Customer_Sales_Area_Line_Item__c> cust_SalesAreaList = new List<Customer_Sales_Area_Line_Item__c> ();
//             //map<String,Address_Information__c> mapSalesArea = new map<String,Address_Information__c>();
            
//             cust_SalesAreaList=[SELECT ID,Unique_Record__c   FROM Customer_Sales_Area_Line_Item__c WHERE Unique_Record__c=:sAreaList];
            
//             map<String,Customer_Sales_Area_Line_Item__c> mapSalesArea =new map<String,Customer_Sales_Area_Line_Item__c>();
            
//             for (Customer_Sales_Area_Line_Item__c sa : cust_SalesAreaList) {
//                 mapSalesArea.put(sa.Unique_Record__c,sa);
                
//             }
            
            
//             //Bank 
            
//             List<Bank_Information__c> bank_info = new List<Bank_Information__c> ();
//             //map<String,Address_Information__c> mapSalesArea = new map<String,Address_Information__c>();
            
//             bank_info=[SELECT ID,Unique_Record__c   FROM Bank_Information__c WHERE Unique_Record__c=:bankList];
            
//             map<String,Bank_Information__c> mapBankInfo =new map<String,Bank_Information__c>();
            
//             for (Bank_Information__c sa : bank_info) {
//                 mapBankInfo.put(sa.Unique_Record__c,sa);
                
//             }
            
            
//             //User List 
            
//             List<User> userList = new List<User> ();
//             //map<String,Address_Information__c> mapSalesArea = new map<String,Address_Information__c>();
            
//             userList=[SELECT ID,SAP_User_Id__c  FROM User WHERE SAP_User_Id__c=:userSAPCodeList];
            
//             map<String,User> mapUserInfo =new map<String,User>();
            
//             for (User sa : userList) {
//                 mapUserInfo.put(sa.SAP_User_Id__c,sa);
//                 System.debug('User='+sa.SAP_User_Id__c);
//             }
            
//             Pricebook2 pbk1 =[ SELECT IsActive ,Description, IsStandard, Id, Name, SystemModstamp FROM Pricebook2 WHERE IsActive=True and Name='Raj Petro Domestic Price Book' ];
            
//             Pricebook2 pbk2 =[ SELECT IsActive ,Description, IsStandard, Id, Name, SystemModstamp FROM Pricebook2 WHERE IsActive=True and Name='Raj Petro Export Price Book' ];
            
//             List<Company_Master__c> cmList= new List<Company_Master__c>();
//             cmList = [SELECT ID,Company_Code__c FROM Company_Master__c WHERE Company_Code__c IN : companyCode];
            
//             Map<String,Company_Master__c> cmMap = new  Map<String,Company_Master__c>();
//             for (Company_Master__c va : cmList) {
                
//                 cmMap.put(va.Company_Code__c,va);
//             }
            
            
//             List<Sales_Organisation__c> soList= new List<Sales_Organisation__c>();
//             soList = [SELECT ID,Name FROM Sales_Organisation__c WHERE Name IN : slorgList];
            
//             Map<String,Sales_Organisation__c> soMap = new  Map<String,Sales_Organisation__c>();
//             for (Sales_Organisation__c va : soList) {
                
//                 soMap.put(va.Name,va);
//             }
            
//             List<Distribution_Channel__c> dcList= new List<Distribution_Channel__c>();
//             dcList = [SELECT ID,Distribution_Code__c  FROM Distribution_Channel__c WHERE Distribution_Code__c IN : disChlList];
            
//             Map<String,Distribution_Channel__c> dcMap = new  Map<String,Distribution_Channel__c>();
//             for (Distribution_Channel__c va : dcList) {
                
//                 dcMap.put(va.Distribution_Code__c,va);
//             }
            
            
//             List<Division__c> diList= new List<Division__c>();
//             diList = [SELECT ID,Division_Code__c FROM Division__c WHERE Division_Code__c IN : divList];
            
//             Map<String,Division__c> diMap = new  Map<String,Division__c>();
//             for (Division__c va : diList) {
                
//                 diMap.put(va.Division_Code__c,va);
//             }
            
//             List<Plant_Code__c> plList= new List<Plant_Code__c>();
//             plList = [SELECT ID,Name,Plant_Code_Name__c FROM Plant_Code__c WHERE Name IN : plantCode];
            
//             Map<String,Plant_Code__c> pcMap = new  Map<String,Plant_Code__c>();
//             for (Plant_Code__c va : plList) {
                
//                 pcMap.put(va.Name,va);
//             }

          



            
//             for (AccountMasterJson jd : jData) {
//                 Account acc= new Account();
//                 if(String.isNotBlank(jd.SFDC_ID) && jd.TYPE=='M'){
                    
//                     acc.Id=jd.SFDC_ID;
//                 }
                
//                 if (cmMap.containsKey(jd.COCODE)) {
//                     acc.Company_Code__c=cmMap.get(jd.COCODE).id;
//                     // acc.Company_Code__c=jd.COCODE;
//                 }
//                 acc.SAP_Customer_Code__c=jd.CUSTOMER_NO;
                
//                 if (soMap.containsKey(jd.SALES_ORG)) {
//                     acc.Sales_Organisation__c=soMap.get(jd.SALES_ORG).id;
                    
//                     if (jd.SALES_ORG=='1000') {
//                         acc.Price_Book__c=pbk1.Id;
//                     }else if (jd.SALES_ORG=='2000') {
//                         acc.Price_Book__c=pbk2.Id;
//                     }
                    
                    
                    
//                 }
//                 if (dcMap.containsKey(jd.DISTR_CHL)) {
//                     acc.Distribution_Channel_L__c=dcMap.get(jd.DISTR_CHL).id;
//                 }
//                 if (diMap.containsKey(jd.DIVISION)) {
//                     acc.Division_L__c=diMap.get(jd.DIVISION).id;
//                 }
                
//                 if (pcMap.containsKey(jd.DELIVERY_PLANT)) {
//                     acc.Plant_code__c=pcMap.get(jd.DELIVERY_PLANT).id;
//                 }
                
//                 // acc.Distribution_Channel_L__c=jd.DISTR_CHL;
//                 // acc.Division_L__c=jd.DIVISION;
                
//                 acc.Account_Group__c=jd.CUST_ACCT_GROUP; //picklist
//                 acc.Title__c=jd.TITLE;
//                 acc.State__c=jd.REGION;
//                 //acc.IsActive=true;
//                 acc.Name=jd.CUST_NAME;
//                 acc.Website=jd.URL;
//                 acc.Type_of_Company__c=jd.IND_SECTOR;
//                 acc.CurrencyIsoCode=jd.CURRENCY1;
//                 System.debug('Currency'+acc.CurrencyIsoCode);
//                 acc.Mobile_Number__c=jd.C_TELEPHONE1;
//                 acc.Email_Id__c=jd.EMAIL;
//                 acc.GST_No__c=jd.TAXNO3;
//                 // acc.GST_Type__c=jd.TAX_CLASS;
//                 acc.Pan_No__c=jd.PARAM_VALUE;
//                 acc.Inco_Term_1__c=jd.INCOTERMS;
//                 acc.Inco_Term_2__c=jd.INCOTERMS2;
//                 acc.Terms_of_Payment__c=jd.PAYT_TERMS;
//                 if (String.isNotBlank(jd.CRED_LIMIT)) {
//                     acc.Credit_Limit_Required__c=Decimal.valueOf(jd.CRED_LIMIT);
//                 }
                
//                 acc.Industry=jd.INDUSTRY;
//                 acc.Any_Special_Instruction__c=jd.INSTR_KEY;
//                 acc.Landline_No_2__c=jd.C_TELEPHONE2;
//                // acc.Landline_No_2__c=jd.C_TELEPHONE2;
//                 acc.Country__c=jd.COUNTRY;
               
                
//                 if(String.isNotBlank(jd.C_STREET)){
//                     acc.Street__c = jd.C_STREET;
//                 }
//                   if(String.isNotBlank(jd.STREET)){
//                     if (String.isNotBlank(acc.Street__c)) {
//                         acc.Street__c=acc.Street__c +' , ';
//                     }
//                     acc.Street__c =acc.Street__c + jd.STREET;
//                 }
//                 if(String.isNotBlank(jd.STREET2)){
//                     if (String.isNotBlank(acc.Street__c)) {
//                         acc.Street__c=acc.Street__c +' , ';
//                     }
//                     acc.Street__c =acc.Street__c + jd.STREET2;
//                 }
                
//                 if(String.isNotBlank(jd.HOUSE_NO)){
//                     if (String.isNotBlank(acc.Street__c)) {
//                         acc.Street__c=acc.Street__c +' , ';
//                     }
//                     acc.Street__c =acc.Street__c + jd.HOUSE_NO;
//                 }
//                 if(String.isNotBlank(jd.POST_CODE)){
//                     acc.Postal_Code__c =jd.POST_CODE;
//                 }
//                 if(String.isNotBlank(jd.CITY)){
//                     acc.City__c =jd.CITY;
//                 }
                
                
                
//                 if (String.isNotBlank(jd.SALES_DISTRICT)) {
//                     acc.Sales_District__c=jd.SALES_DISTRICT;
                    
//                 }
//                 if (String.isNotBlank(jd.SALES_OFF)) {
//                     acc.Sales_office__c=jd.SALES_OFF;
                    
//                 }
//                 if (String.isNotBlank(jd.SALES_GRP)) {
//                     acc.Sales_Group__c=jd.SALES_GRP;
                    
//                 }
//                 if (String.isNotBlank(jd.CUSTGROUP)) {
//                     acc.Cust_Price_group__c=jd.CUSTGROUP;
                    
//                 }
                
//                 if (String.isNotBlank(jd.ABC_CLASS)) {
//                     // acc.ABC_Class__c=jd.ABC_CLASS;
                    
//                 }
                
                
//                 if (String.isNotBlank(jd.PRICEGRP)) {
//                     acc.Price_Group__c=jd.PRICEGRP;
                    
//                 }
                
//                 if (String.isNotBlank(jd.INVOIC_DAT)) {
//                     acc.Invoicing_Date__c=Date.valueOf(jd.INVOIC_DAT);
                    
//                 }
//                 if (String.isNotBlank(jd.INVLISTSCH)) {
                    
//                     acc.InvoicingList_Date__c=Date.valueOf(jd.INVLISTSCH);
                    
//                 }
//                 if (String.isNotBlank(jd.RECON_ACCT)) {
//                     acc.Recon_Account__c=jd.RECON_ACCT;
                    
//                 }
//                 if (String.isNotBlank(jd.EXRATETYPE)) {
//                     acc.Exch_Rate_Type__c=jd.EXRATETYPE;
//                 }
                
                
                
                
//                 accountList.put(jd.CUSTOMER_NO,acc);
                
                
//             }
//             System.debug('Json test='+jData[0].SFDC_ID);
//             //Map<String,Account> accountList = new Map<String,Account>();
//             if (accountList.values().size()>0) {
//                 upsert accountList.values();
                
                
//             }

//                List<Account> pAccList= new List<Account>();
//             pAccList = [SELECT ID,Name,SAP_Customer_Code__c FROM Account WHERE SAP_Customer_Code__c IN : parAccountList];
            
//             Map<Decimal,Account> pAccMap = new  Map<Decimal,Account>();
//             for (Account va : pAccList) {
                
//                 pAccMap.put(va.SAP_Customer_Code__c,va);
//             }
            
//             map<String,Account> accShipAndBillMap = new   map<String,Account>();
            
//             for (AccountMasterJson jd : jData) {
                
//                 //Contact
//                 for (cls_CONTACT_LIST con : jd.CONTACT_LIST) {
//                     Contact cn= new Contact();    
//                     if(mapContaccTemp.containsKey(jd.CUSTOMER_NO)){
//                         //   cn.Id=con.C_SFDCID;
//                         cn.Id=mapContaccTemp.get(jd.CUSTOMER_NO).id;
//                     }
                    
//                     cn.AccountId = accountList.get(con.CUSTOMER_NO).id;    
//                     cn.Salutation=con.TITLE;
//                     cn.FirstName=con.FIRST_NAME;
//                     if (String.isNotBlank(con.LAST_NAME)) {
//                         cn.LastName=con.LAST_NAME;
//                     }else {
//                         cn.LastName='.';
//                     }
                    
//                     cn.MobilePhone=con.C_TELEPHONE1;
//                     cn.Email = con.EMAIL;
//                     //cn.Role_Function__c=con.PARTNERFN;
//                     cn.Title=con.TITLE;
//                     cn.Is_Prmary__c=true;
                    
//                     contactList.put(con.CUSTOMER_NO+'_'+con.PARTNERFN,cn);
                    
//                 }
                
//                 // Address Information
//                 for (cls_PARTNERFUNCTION_LIST pf : jd.PARTNERFUNCTION_LIST) {
                    
//                     //if (accountList.containsKey(jd.CUSTOMER_NO)) {
                        
//                         Address_Information__c addInf= new Address_Information__c();

                        

//                          if(String.isBlank(pf.CUSTOMER_NO)&&String.isNotBlank(pf.CUSTOMR_NO)){
//                                 pf.CUSTOMER_NO=pf.CUSTOMR_NO;
//                             }
                        
//                         if(mapAddInf.containsKey(jd.CUSTOMER_NO+'_'+pf.CUSTOMER_NO+'_'+pf.PARTNERFN)){
//                             addInf.Id=mapAddInf.get(jd.CUSTOMER_NO+'_'+pf.CUSTOMER_NO+'_'+pf.PARTNERFN).id;
//                         }
//                         System.debug('PF_Funct='+pf.CUSTOMER_NO);
//                         if(pf.PARTNERFN =='ZM'||pf.PARTNERFN =='ZE' ){
//                             if (mapUserInfo.containsKey(pf.CUSTOMR_NO)) {
//                                 System.debug('ZMUser='+mapUserInfo.get(pf.CUSTOMR_NO).Id);
//                                 addInf.Customer_Executive__c =mapUserInfo.get(pf.CUSTOMR_NO).Id;
//                             }
                            
//                         }
                        
//                         addInf.Account__c =accountList.get(jd.CUSTOMER_NO).id;
//                        // if (pAccMap.containsKey(pf.CUSTOMER_NO) && pf.PARTNERFN !='ZM' ) {
//                              //addInf.Partner_Account__c =pAccMap.get(pf.CUSTOMER_NO).id;
//                         }
//                         addInf.Partner_SAP_Code__c=pf.CUSTOMER_NO;
                       
//                         addInf.Address_Type__c=pf.ADDR_VERS;
//                         addInf.c_0__c=pf.CAREOF;
//                         addInf.Number_Address_line_1__c=pf.NAME;
//                         addInf.Address_line_2__c=pf.NAME2;
//                         addInf.Address_line_3__c=pf.NAME3;
//                         addInf.City__c=pf.CITY1;
//                         addInf.Pin_Code__c=pf.POSTL_CODE;
//                         addInf.District__c=pf.DISTRICT;
                       
                        
//                         if (String.isNotBlank(pf.STATE)&& pf.COUNTRY=='IN') {
//                    			 addInf.State__c=pf.COUNTRY+'_'+pf.STATE;
                    
//                     	}
                       
//                         addInf.Region__c=pf.REGION;
//                         addInf.Country__c=pf.COUNTRY;
//                         addInf.GSTIN__c=pf.TAXNO3;
//                         // addInf.GST_Type__c=pf.TAX_CLASS;
//                         addInf.Pan_No__c=pf.PARAM_VALUE;
//                          if (String.isNotEmpty(pf.FIRST_NAME)) {
//                             addInf.Name=pf.NAME;
//                             if (String.isNotEmpty(pf.LAST_NAME)) {
//                                 addInf.Name=pf.FIRST_NAME+' '+pf.LAST_NAME;
//                             }

//                         }
//                          else if (String.isNotEmpty(pf.P_NAME)) {
//                                 addInf.Name=pf.P_NAME;
//                         }
//                        else if (String.isNotEmpty(pf.NAME)) {
//                                 addInf.Name=pf.NAME;
//                         }
                      
                     
//                         // addInf.Address_Type__c=pf.PARTNERFN;
//                         addInf.Address_Type__c=pf.PARTNERFN;
//                         addInf.Customer_No__c=pf.CUSTOMER_NO;
                        
//                         Account accTemp = new Account();
//                         accTemp = accountList.get(jd.CUSTOMER_NO);
//                         Boolean flagAcc =false;
                        
                        
//                         if(pf.PARTNERFN =='BP' ){
                            
//                             System.debug('STATE='+statePickListMap.get(pf.COUNTRY+'_'+pf.STATE));
//                             System.debug('country='+countryPickListMap.get(pf.COUNTRY));
                            
//                             accTemp.BillingStreet =  addInf.Number_Address_line_1__c +' '+  addInf.Address_line_2__c +' '+ addInf.Address_line_3__c;
//                             accTemp.BillingCity = pf.CITY1;
//                             if(statePickListMap.containsKey(pf.COUNTRY+'_'+pf.STATE) &&pf.COUNTRY=='IN' && String.isNotBlank(pf.STATE) && String.isNotBlank(pf.COUNTRY)){
//                                  accTemp.BillingState =statePickListMap.get(pf.COUNTRY+'_'+pf.STATE);
//                             }
//                             if(String.isNotBlank(pf.COUNTRY) && countryPickListMap.containsKey(pf.COUNTRY)){
//                                accTemp.BillingCountry =countryPickListMap.get(pf.COUNTRY);
//                             }
                         
//                             accTemp.BillingPostalCode = pf.POSTL_CODE;
//                             accShipAndBillMap.put(jd.CUSTOMER_NO, accTemp);
//                         }
                        
//                         if(pf.PARTNERFN =='SH' ){
                            
//                             System.debug('STATE1='+statePickListMap.get(pf.COUNTRY+'_'+pf.STATE));
//                             System.debug('country1='+countryPickListMap.get(pf.COUNTRY));
                            
//                             accTemp.ShippingStreet =  addInf.Number_Address_line_1__c +' '+  addInf.Address_line_2__c +' '+ addInf.Address_line_3__c;
//                             accTemp.ShippingCity = pf.CITY1; 
//                              if(statePickListMap.containsKey(pf.COUNTRY+'_'+pf.STATE) &&pf.COUNTRY=='IN' && String.isNotBlank(pf.STATE) && String.isNotBlank(pf.COUNTRY)){
//                           		  accTemp.ShippingState =statePickListMap.get(pf.COUNTRY+'_'+pf.STATE);
//                              }
//                              if(String.isNotBlank(pf.COUNTRY) && countryPickListMap.containsKey(pf.COUNTRY)){
//                                accTemp.ShippingCountry =countryPickListMap.get(pf.COUNTRY);
//                              }
                          
//                             accTemp.ShippingPostalCode = pf.POSTL_CODE;
//                             accShipAndBillMap.put(jd.CUSTOMER_NO, accTemp);
                            
//                         }
                        
 
//                         addressInfoList.put(jd.CUSTOMER_NO+'_'+pf.CUSTOMER_NO+'_'+pf.PARTNERFN,addInf);
//                        // addressInfoList.put(pf.CUSTOMER_NO+'_'+pf.PARTNERFN,addInf);
     
//                 }
//                 //
                
//                 //Sales Area Line Item
//                 for (cls_SALES_AREA_LIST sa : jd.SALES_AREA) {
//                     if (accountList.containsKey(sa.CUSTOMER_NO)) {
//                         Customer_Sales_Area_Line_Item__c custSALin = new Customer_Sales_Area_Line_Item__c();
                        
//                         if(mapSalesArea.containsKey(sa.CUSTOMER_NO+'_'+sa.SALES_ORG+'_'+sa.DISTR_CHL+'_'+sa.DIVISION)){
//                             custSALin.Id=mapSalesArea.get(sa.CUSTOMER_NO+'_'+sa.SALES_ORG+'_'+sa.DISTR_CHL+'_'+sa.DIVISION).id;//   sa.S_SFDCID;
//                         }
                        
//                         custSALin.Account__c=accountList.get(sa.CUSTOMER_NO).id;
//                         //custSALin.SAP_Document_Number__c = sa.DOC_NUM;
//                         if (soMap.containsKey(sa.SALES_ORG)) {
//                             custSALin.Sales_Organisation__c=soMap.get(sa.SALES_ORG).id;
//                         }
                      
//                         if (dcMap.containsKey(sa.DISTR_CHL)) {
//                             // custSALin.Sales_Organisation__c=soMap.get(sa.SALES_ORG).id;
//                             custSALin.Distribution_Channel__c=dcMap.get(sa.DISTR_CHL).id;
//                         }
//                         if (diMap.containsKey(sa.DIVISION)) {
//                             // custSALin.Sales_Organisation__c=soMap.get(sa.SALES_ORG).id;
//                             custSALin.Division__c=diMap.get(sa.DIVISION).id;
//                         }
//                         //custSALin.Sales_Organisation__c=soMap.get(sa.SALES_ORG).id;
                        
//                         //custSALin.Division__c=diMap.get(sa.DIVISION).id;
                        
//                         cSalesAreaLinList.put(sa.CUSTOMER_NO+'_'+sa.SALES_ORG+'_'+sa.DISTR_CHL+'_'+sa.DIVISION,custSALin);
//                     }
                    
//                 }
                
//                 //Bank Info
//                 for (cls_BANK_DETAILS_LIST sa : jd.BANK_DETAILS) {
//                     if (accountList.containsKey(jd.CUSTOMER_NO)) {
//                         Bank_Information__c bInf = new Bank_Information__c();
//                         if(mapBankInfo.containsKey(jd.CUSTOMER_NO+'_'+sa.BANK_ACC_NO)){
//                             bInf.Id=mapBankInfo.get(jd.CUSTOMER_NO+'_'+sa.BANK_ACC_NO).id;
//                         }
                        
//                         bInf.Account_Name__c=accountList.get(jd.CUSTOMER_NO).id;
//                         //custSALin.SAP_Document_Number__c = sa.DOC_NUM;
//                         bInf.Name  =sa.BANKNAME;
//                         bInf.Branch__c = sa.BANKBRANCH;
//                         bInf.IFSC_Code__c=sa.BANKL;
//                         bInf.Bank_A_C_No__c=sa.BANK_ACC_NO;
                        
//                         bankInfoList.put(jd.CUSTOMER_NO+'_'+sa.BANK_ACC_NO,bInf);
//                     }
                    
//                 }
                
                
//             }
            
//             if (contactList.values().size()>0) {
//                 upsert contactList.values();
//             }
//             if (addressInfoList.values().size()>0) {
//                 upsert addressInfoList.values();
                
                
//             }
//             if (cSalesAreaLinList.values().size()>0) {
//                 upsert cSalesAreaLinList.values();
                
//             }
//             if (bankInfoList.values().size()>0) {
//                 upsert bankInfoList.values();
                
//             }
            
//             if (accShipAndBillMap.values().size()>0) {
//                 update accShipAndBillMap.values();
                
//             }
            
            
            
            
            
//             response.statusCode=200;
//             for (AccountMasterJson jd : jData) {
                
                
//                 if (String.isBlank(jd.SFDC_ID) ){
//                     jd.SFDC_ID=accountList.get(jd.CUSTOMER_NO).id;
//                     apiLog.Account__c=accountList.get(jd.CUSTOMER_NO).id;
//                 }
                
//                 for (cls_CONTACT_LIST obj : jd.CONTACT_LIST) {
//                     if (String.isBlank(obj.C_SFDCID) &&  contactList.containsKey(obj.CUSTOMER_NO+'_'+obj.PARTNERFN)){
//                         obj.C_SFDCID=contactList.get(obj.CUSTOMER_NO+'_'+obj.PARTNERFN).id;
//                     }
                    
//                 }
                
//                 for (cls_PARTNERFUNCTION_LIST obj : jd.PARTNERFUNCTION_LIST) { 
//                    if (String.isBlank(obj.P_SFDCID) && addressInfoList.containsKey(jd.CUSTOMER_NO+'_'+obj.CUSTOMER_NO+'_'+obj.PARTNERFN) ){
//                         obj.P_SFDCID=addressInfoList.get(jd.CUSTOMER_NO+'_'+obj.CUSTOMER_NO+'_'+obj.PARTNERFN).id;
//                     }

//                    /* if (String.isBlank(obj.P_SFDCID) && addressInfoList.containsKey(obj.CUSTOMER_NO+'_'+obj.PARTNERFN) ){
//                         obj.P_SFDCID=addressInfoList.get(obj.CUSTOMER_NO+'_'+obj.PARTNERFN).id;
//                     }*/
//                 }
                
//                 for (cls_SALES_AREA_LIST obj : jd.SALES_AREA) { 
//                     if (String.isBlank(obj.S_SFDCID) && cSalesAreaLinList.containsKey(obj.CUSTOMER_NO+'_'+obj.SALES_ORG+'_'+obj.DISTR_CHL+'_'+obj.DIVISION)){
//                         obj.S_SFDCID=cSalesAreaLinList.get(obj.CUSTOMER_NO+'_'+obj.SALES_ORG+'_'+obj.DISTR_CHL+'_'+obj.DIVISION).id;
//                     }
//                 }
                
//               //  for (cls_BANK_DETAILS_LIST obj : jd.BANK_DETAILS) { 
//                   //  if (String.isBlank(obj.B_SFDCID) && bankInfoList.containsKey(jd.CUSTOMER_NO+'_'+obj.BANK_KEY+'_'+obj.BANKL+'_'+Obj.BANK_ACC_NO)){
//                        // obj.B_SFDCID=bankInfoList.get(jd.CUSTOMER_NO+'_'+obj.BANK_KEY+'_'+obj.BANKL+'_'+Obj.BANK_ACC_NO).id;
//                     }
//                 }
                
                
                
//             }
//           //  response.responseBody=Blob.valueOf(JSON.serialize(jData));
//             apiLog.Status__c='Success';
//             // response.responseBody=
//         } catch (Exception e) {
//             Database.RollBack(sp);
//             apiLog.Exception_Description__c=e.getMessage() +' : '+e.getCause()+' : '+e.getStackTraceString();
//             apiLog.Status__c='Failed';
//             response.statusCode=201;
//             response.responseBody=Blob.valueOf('{"ERR_MSG":"'+apiLog.Exception_Description__c+'","Status":"Failed"}');
//         }
//         finally{
            
//             INSERT apiLog; 
//         }
        
        
        
    
    
    
//     //
//     //Generated by AdminBooster
//     //
    
    
    
//     public static List<AccountMasterJson> parse(String json){
//         return (List<AccountMasterJson>) System.JSON.deserialize(json, List<AccountMasterJson>.class);
//     }
//     public class AccountMasterJson {
//         public String SFDC_ID;  //
//         public String TYPE; //
        
//         public String DOC_NUM;  //
//         public String CHRT_ACCTS;
//          public String GL_ACCT;    //
//         public String CUSTOMER_NO;  //
//         public String COCODE;   //
//         public String SALES_ORG;    //
//         public String DISTR_CHL;    //
//         public String DIVISION; //
//         public String CUST_ACCT_GROUP;  //
//         public String TITLE;    //
//         public String CUST_NAME;    //
//         public String ADDRESS;  //
//         public String URL;  //
//         public String IND_SECTOR;   //
//         public String C_CURRENCY;   //
//         public String C_TELEPHONE1; //
//         public String EMAIL;    //
//         public String C_TELEPHONE2; //
//         public String C_STREET; //add
//         public String STREET2;  //add
//         public String STREET;
//         public String HOUSE_NO;   //add
//         public String POST_CODE;    //add
//         public String DELIVERY_PLANT;
//         public String REGION;
//         public String CITY; //add
//         public String COUNTRY;  //
//         public String CURRENCY1;    //
//         public String TAXNO3;   //
//         public String TAX_CLASS;    //
//         public String PARAM_VALUE;  //
//         public String INCOTERMS;    //
//         public String INCOTERMS2;   //
//         public String PAYT_TERMS;   //
//         public String CRED_LIMIT;   //
//         public String INDUSTRY; //
//         public String INSTR_KEY;    //
//         public String SALES_DISTRICT;   //
//         public String SALES_OFF;    //
//         public String SALES_GRP;    //
//         public String CUSTGROUP;    //
//         public String ABC_CLASS;    //
//         public String PRICEGRP; //
//         public String PRICE_LIST;   //
//         public String CUSTSTATGR;   //
//         public String INVOIC_DAT;   //
//         public String INVLISTSCH;   //
//         public String RECON_ACCT;   //
//         public String EXRATETYPE;   //
//         public cls_CONTACT_LIST[] CONTACT_LIST;
//         public cls_PARTNERFUNCTION_LIST[] PARTNERFUNCTION_LIST;
//         public cls_SALES_AREA_LIST[] SALES_AREA;
//         public cls_BANK_DETAILS_LIST[] BANK_DETAILS;
//         public String ER_MSG;   //
//     }
//     class cls_CONTACT_LIST {
//         public String C_SFDCID; //
//         public String CUSTOMER_NO;  //
//         public String CUST_DOC_NUM; //
//         public String CUST_NAME;    //
//         public String FIRST_NAME;   //
//         public String LAST_NAME;    //
//         public String C_TELEPHONE1; //
//         public String EMAIL;    //
//         public String PARTNERFN;    //
//         public String TITLE;    //
//         public String CITY; //
//         public String REGION;   //
//         public String COUNTRY;  //
//         public String POST_CODE;    //
//     }
//     class cls_PARTNERFUNCTION_LIST {
//         public String P_SFDCID; //
//         public String CUSTOMER_NO;  //
//         public String CUST_DOC_NUM; //
//         public String ADDR_VERS;    //
//         public String CAREOF;   //
//         public String NAME; //
//         public String NAME2;    //
//         public String NAME3;    //
//         public String CITY1;    //
//         public String POSTL_CODE;   //
//         public String DISTRICT; //
//         public String STATE;    //
//         public String REGION;   //
//         public String COUNTRY;  //
//         public String TAXNO3;   //
//         public String TAX_CLASS;    //
//         public String PARAM_VALUE;  //
//         public String PARTNERFN;    //
//         public String PARTNER_COUNT;    //
//         public String P_NAME;    //
//         public String FIRST_NAME;    //
//         public String LAST_NAME;    //
//         public String CUSTOMR_NO;    //
        
//     }
//     class cls_SALES_AREA_LIST {
//         public String S_SFDCID; //
//         public String CUSTOMER_NO;  //
//         public String CUST_DOC_NUM; //
//         public String SALES_ORG;    //
//         public String DISTR_CHL;    //
//         public String DIVISION; //
//     }
//     class cls_BANK_DETAILS_LIST {
//         public String B_SFDCID; //
//         public String BANK_KEY; //
//         public String BANKL;    //
//         public String BANKNAME; //
//         public String BANKBRANCH;   //
//         public String BANK_ACC_NO;  //
        
        
//     }
    
    
//     /** 

// static testMethod void testParse() {
// String json=        '[{"DOC_NUM":"","CHRT_ACCTSGL_ACCT":"","CUSTOMER_NO":"","COCODE":"","SALES_ORG":"","DISTR_CHL":"","DIVISION":"","CUST_ACCT_GROUP":"","TITLE":"","CUST_NAME":"","ADDRESS":"","URL":"","IND_SECTOR":"","CURRENCY":"","C_TELEPHONE1":"","EMAIL":"","C_TELEPHONE2":"","C_STREET":"","STREET2":"","STREETHOUSE_NO":"","POST_CODE":"","CITY":"","COUNTRY":"","CURRNCY":"","TAXNO3":"","TAX_CLASS":"","PARAM_VALUE":"","INCOTERMS":"","INCOTERMS2":"","PAYT_TERMS":"","CRED_LIMIT":"","INDUSTRY":"","INSTR_KEY":"","SALES_DISTRICT":"","SALES_OFF":"","SALES_GRP":"","CUSTGROUP":"","ABC_CLASS":"","PRICEGRP":"","PRICE_LIST":"","CUSTSTATGR":"","INVOIC_DAT":"","INVLISTSCH":"","RECON_ACCT":"","EXRATETYPE":"","CONTACT_LIST":[{"DOC_NUM":"","CUST_DOC_NUM":"","CUST_NAME":"","C_TELEPHONE1":"","EMAIL":"","PARTNERFN":"","TITLE":"","CITY":"","REGION":"","COUNTRY":"","POST_CODE":""}],"PARTNERFUNCTION_LIST":[{"DOC_NUM":"","CUST_DOC_NUM":"","ADDR_VERS":"","CAREOF":"","NAME":"","NAME2":"","NAME3":"","CITY1":"","POSTL_CODE":"","DISTRICT":"","STATE":"","REGION":"","COUNTRY":"","TAXNO3":"","TAX_CLASS":"","PARAM_VALUE":"","PARTNERFN":"","PARTNER_COUNT":""}],"SALES_AREA_LIST":[{"DOC_NUM":"","CUST_DOC_NUM":"","SALES_ORG":"","DISTR_CHL":"","DIVISION":""}]}]';
// AccountMasterJson obj = parse(json);
// System.assert(obj != null);
// }*/
    
}