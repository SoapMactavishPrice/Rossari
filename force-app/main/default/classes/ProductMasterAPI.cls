/**
* @File Name : ProductMasterAPI.cls
* @Description :
* @Author :Shashank
* @Last Modified By :
* @Last Modified On : August 5, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | August 5, 2025 | Shashank  | Initial Version
**/

@RestResource(urlMapping = '/productMaster/*')
global  class ProductMasterAPI {
    
    
    @HttpPost
    global static void doPost() {
        RestResponse response;
        RestRequest request;
        API_log__c apiLog=new API_log__c();
        apiLog.Name ='Product Master';
        Savepoint sp = Database.setSavepoint();
        try {
            
            
            request = RestContext.request;
            response = RestContext.response;
            String jSONRequestBody = request.requestBody.toString().trim();
            System.debug('IjSONRequestBody=' + jSONRequestBody);
            //apiLog.Request__c=jSONRequestBody;
            List<ProductMasterJson> jData = parse(jSONRequestBody);
            System.debug('Json--' + jData);
			apiLog.Request__c='Total Size ='+jData.size()+'-'+jSONRequestBody;

            
            
            map<String,Product2> productList = new map<String,Product2>();
            map<String,Plant_Extension__c> plantExtList = new  map<String,Plant_Extension__c>();
            map<String,Sales_Area__c> SalesAreaList = new  map<String,Sales_Area__c>();
            map<String,Conversion_factor_for_Sales__c> cfSaleList = new  map<String,Conversion_factor_for_Sales__c>();
            List<Conversion_factor_for_Sales__c> cfList = new List<Conversion_factor_for_Sales__c>();
            
            
            List<String> itemCode = new List<String>();
            List<String> slorgList = new List<String>();
            List<String> disChlList = new List<String>();
            List<String> divList = new List<String>();
            List<String> bUomCodeList = new List<String>();
            List<String> pCodeList = new List<String>();
            List<String> hsnCodeList = new List<String>();
            List<String> itmGrpCodeList = new List<String>();

			Pricebook2 pbk1 =[ SELECT IsActive ,Description, IsStandard, Id, Name, SystemModstamp FROM Pricebook2 WHERE IsActive=True and Name='Raj Petro Domestic Price Book' ];

    		 Pricebook2 pbk2 =[ SELECT IsActive ,Description, IsStandard, Id, Name, SystemModstamp FROM Pricebook2 WHERE IsActive=True and Name='Raj Petro Export Price Book' ];

			  Pricebook2 pbk3 =[ SELECT IsActive ,Description, IsStandard, Id, Name, SystemModstamp FROM Pricebook2 WHERE IsActive=True and IsStandard=true ];

			  Pricebook2 standardPriceBook = [ SELECT Id  FROM Pricebook2 WHERE isStandard = true  LIMIT 1];
            
            //added by shashank
            Set<String> plantExtensionIds=new Set<String>();
            Set<String> salesareanIds=new Set<String>();
            Set<String> itemNumberIds=new Set<String>();
            for (ProductMasterJson jd : jData) {
                itemNumberIds.add(jd.ITEM_NUMBER);
                itmGrpCodeList.add(jd.ITEM_GROUP);
                hsnCodeList.add(jd.HSN_CODE);
                pCodeList.add(jd.PLANT_CODE);
                bUomCodeList.add(jd.SALES_UOM);
				bUomCodeList.add(jd.WT_UOM);
				bUomCodeList.add(jd.BASE_UOM);
				slorgList.add(jd.SALES_ORGANISATION);
                disChlList.add(jd.DISTRIBUTION_CHANNEL);
                divList.add(jd.DIVISION);

				 for (cls_PLANT_EXTENTION data : jd.PLANT_EXTENTION) { 
                    pCodeList.add(data.PLANT_CODE);
                    plantExtensionIds.add(jd.ITEM_NUMBER+'-'+data.PLANT_CODE);
                }
                
                for (cls_SALES_AREA data : jd.SALES_AREA) { 
                    slorgList.add(data.SALES_ORGANISATION);
                    disChlList.add(data.DISTRIBUTION_CHANNEL);
                    divList.add(data.DIVISION);
                    salesareanIds.add(jd.ITEM_NUMBER+'-'+data.SALES_ORGANISATION+'-'+data.DISTRIBUTION_CHANNEL+'-'+data.DIVISION);
                }
                
                for (cls_CONV_FACT_SALE data : jd.CONV_FACT_SALE) {
                    bUomCodeList.add(data.BASE_UOM);
                    bUomCodeList.add(data.ALT_UOM);
                     
                }
                
                
            }
            //added by shashank
            Map<String,String> mpproductIds=new Map<String,String>();
            List<Product2> prodList=new List<Product2>();
            prodList=[SELECT Id,ProductCode FROM Product2 WHERE ProductCode IN : itemNumberIds];
            for(Product2 pex:prodList){
                mpproductIds.put(pex.ProductCode , pex.Id);
            }



            //added by shashank
            Map<String,String> mpplantExtension=new Map<String,String>();
            List<Plant_Extension__c> plEx=new List<Plant_Extension__c>();
            plEx=[SELECT Id,Unique__c FROM Plant_Extension__c WHERE Unique__c IN : plantExtensionIds];
            for(Plant_Extension__c pex:plEx){
                mpplantExtension.put(pex.Unique__c , pex.Id);
            }

            Map<String,String> mpsalesArea=new Map<String,String>();
            List<Sales_Area__c> sa=new List<Sales_Area__c>();
            sa=[SELECT Id,Unique__c FROM Sales_Area__c WHERE Unique__c IN : salesareanIds];
            for(Sales_Area__c pex:sa){
                mpsalesArea.put(pex.Unique__c , pex.Id);
            }
            
            
            List<Sales_Organisation__c> soList= new List<Sales_Organisation__c>();
            soList = [SELECT ID,Name FROM Sales_Organisation__c WHERE Name IN : slorgList];
            
            Map<String,Sales_Organisation__c> soMap = new  Map<String,Sales_Organisation__c>();
            for (Sales_Organisation__c va : soList) {
                
                soMap.put(va.Name,va);
            }
            
            List<Distribution_Channel__c> dcList= new List<Distribution_Channel__c>();
            dcList = [SELECT ID,Distribution_Code__c  FROM Distribution_Channel__c WHERE Distribution_Code__c IN : disChlList];
            
            Map<String,Distribution_Channel__c> dcMap = new  Map<String,Distribution_Channel__c>();
            for (Distribution_Channel__c va : dcList) {
                
                dcMap.put(va.Distribution_Code__c,va);
            }
            
            
            List<Division__c> diList= new List<Division__c>();
            diList = [SELECT ID,Division_Code__c FROM Division__c WHERE Division_Code__c IN : divList];
            
            Map<String,Division__c> diMap = new  Map<String,Division__c>();
            for (Division__c va : diList) {
                
                diMap.put(va.Division_Code__c,va);
            }
            
            
            List<Base_UOM_Master__c> baseList= new List<Base_UOM_Master__c>();
            baseList = [SELECT ID,Base_Code__c,Type__c FROM Base_UOM_Master__c WHERE Base_Code__c IN : bUomCodeList];
            
            Map<String,Base_UOM_Master__c> baseUomMap = new  Map<String,Base_UOM_Master__c>();
            Map<String,Base_UOM_Master__c> wtUomMap = new  Map<String,Base_UOM_Master__c>();
            
            for (Base_UOM_Master__c va : baseList) {
			     System.debug('va.'+va.Base_Code__c);
                
                if (va.Type__c=='Base UOM') {
                    baseUomMap.put(va.Base_Code__c,va);
                    
                }
                if (va.Type__c=='Wt UOM') {
                    wtUomMap.put(va.Base_Code__c,va);
                    
                }
                  
            }
            
            
            List<HSN_Master__c> hsnList= new List<HSN_Master__c>();
            hsnList = [SELECT ID,SAP_HSN_Code__c,Name FROM HSN_Master__c WHERE Name IN : hsnCodeList];
            
            Map<String,HSN_Master__c> hsnMap = new  Map<String,HSN_Master__c>();
            for (HSN_Master__c va : hsnList) {
                
                hsnMap.put(va.Name,va);
            }
            
            
            List<Plant__c> pltList= new List<Plant__c>();
            pltList = [SELECT ID,Name FROM Plant__c WHERE Name IN : pCodeList];
            
            Map<String,Plant__c> pltMap = new  Map<String,Plant__c>();
            for (Plant__c va : pltList) {
                
                pltMap.put(va.Name,va);
            }
            
            
            String sfdc_id='';
            for (ProductMasterJson jd : jData) {
                Product2 pr=new Product2();
                if(jd.SFDC_ID!=''){
                    pr.Id=jd.SFDC_ID;
                    sfdc_id=jd.SFDC_ID;
                }else{
                    if(mpproductIds.get(jd.ITEM_NUMBER)!=null){
                        pr.Id=mpproductIds.get(jd.ITEM_NUMBER);
                        sfdc_id=mpproductIds.get(jd.ITEM_NUMBER);
                    }
                }
                pr.Name=jd.DISPLAY_NAME;
                pr.ProductCode=jd.ITEM_NUMBER;
                pr.Description=jd.ITEM_DESCRIPTION;
                pr.Display_Name__c=jd.DISPLAY_NAME;
				pr.IsActive=true;
                pr.Item_Group__c=jd.ITEM_GROUP;
               

				if (String.isNotBlank(jd.ITEM_TYPE)) {
                     pr.Item_Type__c=jd.ITEM_TYPE; //Pick
                } 



              
            if (baseUomMap.containsKey(jd.BASE_UOM)) {
                    pr.Base_UOM__c=baseUomMap.get(jd.BASE_UOM).id;
                }

				if (String.isNotBlank(jd.OLD_MATERIAL_CODE)) {
					 pr.Old_Material_Code__c=jd.OLD_MATERIAL_CODE;
				}
                //pr.Old_Material_Code__c=jd.OLD_MATERIAL_CODE;
                
                if (soMap.containsKey(jd.SALES_ORGANISATION)) {
                    pr.Sales_Organisation__c=soMap.get(jd.SALES_ORGANISATION).id;
                }
                if (dcMap.containsKey(jd.DISTRIBUTION_CHANNEL)) {
                    pr.Distribution_Channel__c=dcMap.get(jd.DISTRIBUTION_CHANNEL).id;
                }
                if (diMap.containsKey(jd.DIVISION)) {
                    pr.Division__c=diMap.get(jd.DIVISION).id;
                }
                
                if (String.isNotBlank(jd.SALES_UOM)) {
					if (baseUomMap.containsKey(jd.SALES_UOM)) {


				System.debug('BaseUom='+jd.SALES_UOM);
						
						pr.Sales_UOM__c=baseUomMap.get(jd.SALES_UOM).id;
					}
					
				}
               
                
                if (pltMap.containsKey(jd.PLANT_CODE)) {
                    pr.Plant_Code__c=pltMap.get(jd.PLANT_CODE).id;
                }
                
              
                pr.Prod_Hierachy__c=jd.PROD_HIERACHY;
                pr.GenItemCatGroup__c=jd.GENITEMCATGROUP;

				if (String.isNotBlank(jd.GENITEMCATGROUP)) {
					pr.GenItemCatGroup__c=jd.GENITEMCATGROUP;
				}

                pr.Gross_Wt__c = jd.GROSS_WT;
                pr.Net_Wt__c=jd.NET_WT;
                if (wtUomMap.containsKey(jd.WT_UOM)) {
				   System.debug('WT_UOM='+jd.WT_UOM);
                    pr.Wt_UOM__c=wtUomMap.get(jd.WT_UOM).id;
                }
                //pr.Wt_UOM__c=jd.WT_UOM;
                pr.Volume__c=jd.VOLUME;
                pr.Size_Dimensions__c=jd.SIZE_DIMENSIONS;
                pr.Material_Group_1__c=jd.MATERIAL_GROUP_1;
                pr.Material_Group_2__c=jd.MATERIAL_GROUP_2;
                pr.Material_Group_3__c=jd.MATERIAL_GROUP_3;
                pr.Material_Group_4__c=jd.MATERIAL_GROUP_4;
                pr.Material_Group_5__c=jd.MATERIAL_GROUP_5;

				if (String.isNotBlank(jd.MATERIAL_FREIGHT_GROUP) ){
					//pr.List_Price_MRP_Price__c=Decimal.valueOf(jd.LIST_PRICE_MRP_PRICE);
					pr.Material_Freight_Group__c=jd.MATERIAL_FREIGHT_GROUP;
				}
                

				if (String.isNotBlank(jd.LIST_PRICE_MRP_PRICE) ){
					pr.List_Price_MRP_Price__c=Decimal.valueOf(jd.LIST_PRICE_MRP_PRICE);
				}
                
             
                if (hsnMap.containsKey(jd.HSN_CODE)) {
                    pr.HSN_Code__c=hsnMap.get(jd.HSN_CODE).id;
                }
                
                pr.Lead_Time__c=jd.LEAD_TIME;
                //pr.=jd.PRODUCT_STATUS;

				// PricebookEntry priceEntry = new PricebookEntry();
				// priceEntry.UnitPrice=1;
				// priceEntry.Pricebook2Id=pr.Id;
				// priceEntry.isActive=true;



                productList.put(jd.ITEM_NUMBER, pr);
            }
            
            if (productList.values().size()>0) {
                upsert productList.values();
				
				List<PricebookEntry>  priceEntry = new List<PricebookEntry>();
				List<PricebookEntry>  priceEntry1 = new List<PricebookEntry>();
                if(sfdc_id==''){
                    for (Product2 pr : productList.values()) {

                    PricebookEntry p3 = new PricebookEntry();
                     p3.UnitPrice=pr.List_Price_MRP_Price__c;
                     p3.Pricebook2Id=standardPriceBook.Id;
                     p3.isActive=true;
                     p3.Product2Id=pr.id;
                     priceEntry1.add(p3);
    
                     PricebookEntry p4 = new PricebookEntry();
                     p4.UnitPrice=pr.List_Price_MRP_Price__c;
                     p4.Pricebook2Id=standardPriceBook.Id;
                     p4.isActive=true;
                     p4.Product2Id=pr.id;
                    p4.CurrencyIsoCode='USD';
                     priceEntry1.add(p4);
                        
                     PricebookEntry p5 = new PricebookEntry();
                     p5.UnitPrice=pr.List_Price_MRP_Price__c;
                     p5.Pricebook2Id=standardPriceBook.Id;
                     p5.isActive=true;
                     p5.Product2Id=pr.id;
                     p5.CurrencyIsoCode='EUR';
                     priceEntry1.add(p5);   
    
    
                     PricebookEntry p1 = new PricebookEntry();
                     p1.UnitPrice=pr.List_Price_MRP_Price__c;
                     p1.Pricebook2Id=pbk1.Id;
                     p1.isActive=true;
                     p1.Product2Id=pr.id;
                    p1.CurrencyIsoCode='INR';
                     priceEntry.add(p1);
    
                    PricebookEntry p2 = new PricebookEntry();
                     p2.UnitPrice=pr.List_Price_MRP_Price__c;
                     p2.Pricebook2Id=pbk2.Id;
                     p2.isActive=true;
                     p2.Product2Id=pr.id;
                     p2.CurrencyIsoCode='USD';
                    priceEntry.add(p2);
                        
                     PricebookEntry p6 = new PricebookEntry();
                     p6.UnitPrice=pr.List_Price_MRP_Price__c;
                     p6.Pricebook2Id=pbk2.Id;
                     p6.isActive=true;
                     p6.Product2Id=pr.id;
                     p6.CurrencyIsoCode='EUR';
                    priceEntry.add(p6);
					
				}
                }
				
				upsert priceEntry1;
				upsert priceEntry;


				
				}



            
            for (ProductMasterJson jd : jData) {
                
                
                //Plant Extention 
                
                for (cls_PLANT_EXTENTION data : jd.PLANT_EXTENTION) {
                    Plant_Extension__c obj= new Plant_Extension__c();    
                    // if(String.isNotBlank(data.SFDC_ID)){
                    //     obj.Id=data.SFDC_ID;
                    // }
                    //added by shashank
                    if(mpplantExtension.get(data.ITEM_NUMBER+'-'+data.PLANT_CODE)!=null){
                        obj.Id=mpplantExtension.get(data.ITEM_NUMBER+'-'+data.PLANT_CODE);
                    }
                    obj.Item_Master__c = productList.get(data.ITEM_NUMBER).id;    
                    //obj.Plant_Code__c=data.PLANT_CODE;
					 if (pltMap.containsKey(data.PLANT_CODE)) {
                    obj.Plant_Code__c=pltMap.get(data.PLANT_CODE).id;
                }
                    obj.Total_Stock__c=Integer.valueOf(data.TOTAL_STOCK);
                    plantExtList.put(data.ITEM_NUMBER+'_'+data.PLANT_CODE,obj);
                    
                }
                
                
                // Sales Area 
                for (cls_SALES_AREA data : jd.SALES_AREA) {
                    Sales_Area__c obj= new Sales_Area__c();    
                    // if(String.isNotBlank(data.SFDC_ID)){
                    //     obj.Id=data.SFDC_ID;
                    // }
                    //added by shashank
                    if(mpsalesArea.get(data.ITEM_NUMBER+'-'+data.SALES_ORGANISATION+'-'+data.DISTRIBUTION_CHANNEL+'-'+data.DIVISION)!=null){
                        obj.Id=mpsalesArea.get(data.ITEM_NUMBER+'-'+data.SALES_ORGANISATION+'-'+data.DISTRIBUTION_CHANNEL+'-'+data.DIVISION);
                    }
                    obj.Item_Master__c = productList.get(data.ITEM_NUMBER).id; 
                    
                    if (soMap.containsKey(data.SALES_ORGANISATION)) {
                        obj.Sales_Organisation__c=soMap.get(data.SALES_ORGANISATION).id;
                    }
                    if (dcMap.containsKey(data.DISTRIBUTION_CHANNEL)) {
                        obj.Distribution_Channel__c=dcMap.get(data.DISTRIBUTION_CHANNEL).id;
                    }
                    if (diMap.containsKey(data.DIVISION)) {
                        obj.Division__c=diMap.get(data.DIVISION).id;
                    }
                    
                   
                    
                    SalesAreaList.put(data.ITEM_NUMBER+'_'+data.SALES_ORGANISATION+'_'+data.DISTRIBUTION_CHANNEL+'_'+data.DIVISION,obj);
                    
                }
                //Conversion Factor
                for (cls_CONV_FACT_SALE data : jd.CONV_FACT_SALE) {
                    Conversion_factor_for_Sales__c obj= new Conversion_factor_for_Sales__c();    
                    if(String.isNotBlank(data.SFDC_ID)){
                        obj.Id=data.SFDC_ID;
                    }
                    obj.Item_Master__c = productList.get(data.ITEM_NUMBER).id;    
                    obj.Alt_Quantity__c	=Decimal.valueOf(data.ALT_QUANITTY);
                    if (baseUomMap.containsKey(data.ALT_UOM)) {
                        obj.Alt_UOM__c=baseUomMap.get(data.ALT_UOM).id;
                   }
                    //obj.Alt_UOM__c=data.ALT_UOM;
                    obj.Base_Qty__c=Decimal.valueOf(data.BASE_QTY);
                    if (baseUomMap.containsKey(data.BASE_UOM)) {
                        obj.Base_UOM__c=baseUomMap.get(data.BASE_UOM).id;
                    }
                    
                    obj.Default__c	=Boolean.valueOf(data.IS_DEFAULT);
                    cfList.add(obj);
                    
                    
                    // cfSaleList.put(data.ITEM_NUMBER+'_'+data.Alt_UOM__c+'_'+data.Base_UOM__c+'_'+data.Alt_Quantity__c+'_'+data.Base_Qty__c,obj);
                    
                }
                
            }
            if (plantExtList.values().size()>0) {
                upsert plantExtList.values();
            }
            if (SalesAreaList.values().size()>0) {
                upsert SalesAreaList.values();
                
                
            }
            if (cfList.size()>0) {
                upsert cfList;
                
            }
            
            for (ProductMasterJson jd : jData) {
                
                
                if (String.isBlank(jd.SFDC_ID) ){
                    jd.SFDC_ID=productList.get(jd.ITEM_NUMBER).id;
                    apiLog.Item_Master__c=productList.get(jd.ITEM_NUMBER).id;
                }
                
                for (cls_PLANT_EXTENTION obj : jd.PLANT_EXTENTION) {
                    if (String.isBlank(obj.SFDC_ID) &&  plantExtList.containsKey(obj.ITEM_NUMBER+'_'+obj.PLANT_CODE)){
                        obj.SFDC_ID=plantExtList.get(obj.ITEM_NUMBER+'_'+obj.PLANT_CODE).id;
                    }
                    
                }
                
                for (cls_SALES_AREA obj : jd.SALES_AREA) {
                    if (String.isBlank(obj.SFDC_ID) &&  SalesAreaList.containsKey(obj.ITEM_NUMBER+'_'+obj.SALES_ORGANISATION+'_'+obj.DISTRIBUTION_CHANNEL+'_'+obj.DIVISION)){
                        obj.SFDC_ID=SalesAreaList.get(obj.ITEM_NUMBER+'_'+obj.SALES_ORGANISATION+'_'+obj.DISTRIBUTION_CHANNEL+'_'+obj.DIVISION).id;
                    }
                    
                }
                
                
            }
            
            response.statusCode=200;
            response.responseBody=Blob.valueOf(JSON.serialize(jData));
			apiLog.Status__c='Success';

            
            
        }catch(Exception e){
            Database.RollBack(sp);
            apiLog.Exception_Description__c=e.getMessage() +' : '+e.getCause()+' : '+e.getStackTraceString();
            response.statusCode=201;
            response.responseBody=Blob.valueOf('{"ERR_MSG":"'+apiLog.Exception_Description__c+'","Status":"Failed"}');
             apiLog.Status__c='Failed';
            
        }
        finally{
            INSERT apiLog; 
        }
        
        
    }
    
    
    public static List<ProductMasterJson> parse(String json){
        return (List<ProductMasterJson>) System.JSON.deserialize(json, List<ProductMasterJson>.class);
    }
    
    
    
    
    class ProductMasterJson {
        public String SFDC_ID;	//
        public String ITEM_NUMBER;	//000000000400009166
        public String ITEM_DESCRIPTION;	//KYROS STNSL 80DA-210LT HD BL
        public String DISPLAY_NAME;	//KYROS STNSL 80DA-210LT HD BL
        public String ITEM_GROUP;	//FG3000
        public String ITEM_TYPE;	//FERT
        public String BASE_UOM;	//L
        public String OLD_MATERIAL_CODE;	//KSL40401PM551
        public String SALES_ORGANISATION;	//
        public String DISTRIBUTION_CHANNEL;	//10
        public String DIVISION;	//28
        public String SALES_UOM;	//NOS
        public String PLANT_CODE;	//1000
        public String PROD_HIERACHY;	//000140001300000001
        public String GENITEMCATGROUP;	//NORM
        public String GROSS_WT;	//0
        public String NET_WT;	//0
        public String WT_UOM;	//KG
        public String VOLUME;	//0
        public String SIZE_DIMENSIONS;	//210 LT
        public String ITEM_TYPE_C;	//Fertigerzeugnis
        public String MATERIAL_GROUP_1;	//AD
        public String MATERIAL_GROUP_1_C;	//SBU-4
        public String MATERIAL_GROUP_2;	//AO
        public String MATERIAL_GROUP_2_C;	//Kyros
        public String MATERIAL_GROUP_3;	//AS
        public String MATERIAL_GROUP_3_C;	//Solvent
        public String MATERIAL_GROUP_4;	//CL
        public String MATERIAL_GROUP_4_C;	//Solvents
        public String MATERIAL_GROUP_5;	//CM
        public String MATERIAL_GROUP_5_C;	//Commodity
        public String MATERIAL_FREIGHT_GROUP;	//AB
        public String MATERIAL_FREIGHT_GROUP_C;	//Non MRP(Barrel&Drum)
        public String LIST_PRICE_MRP_PRICE;	//
        public String HSN_CODE;	//27101990
        public Integer LEAD_TIME;	//0
        public String PRODUCT_STATUS;	//KCVEDALQBGZX
        public cls_PLANT_EXTENTION[] PLANT_EXTENTION;
        public cls_SALES_AREA[] SALES_AREA;
        public cls_CONV_FACT_SALE[] CONV_FACT_SALE;
    }
    class cls_PLANT_EXTENTION {
        public String SFDC_ID;	//
        public String ITEM_NUMBER;	//000000000400009166
        public String PLANT_CODE;	//1000
        public Decimal TOTAL_STOCK;	//0
    }
    class cls_SALES_AREA {
        public String SFDC_ID;	//
        public String ITEM_NUMBER;	//000000000400009166
        public String SALES_ORGANISATION;	//
        public String DISTRIBUTION_CHANNEL;	//10
        public String DIVISION;	//28
    }
    class cls_CONV_FACT_SALE {
        public String SFDC_ID;	//
        public String ALT_QUANITTY;	//
        public String ALT_UOM;	//
        public String BASE_QTY;	//
        public String BASE_UOM;	//L
        public String ITEM_NUMBER;	//000000000400009166
        public String IS_DEFAULT;	//
    }
    /*
static testMethod void testParse() {
String json=		'[{"SFDC_ID":"","ITEM_NUMBER":"000000000400009166","ITEM_DESCRIPTION":"KYROS STNSL 80DA-210LT HD BL","DISPLAY_NAME":"KYROS STNSL 80DA-210LT HD BL","ITEM_GROUP":"FG3000","ITEM_TYPE":"FERT","BASE_UOM":"L","OLD_MATERIAL_CODE":"KSL40401PM551","SALES_ORGANISATION":"","DISTRIBUTION_CHANNEL":"10","DIVISION":"28","SALES_UOM":"NOS","PLANT_CODE":"1000","PROD_HIERACHY":"000140001300000001","GENITEMCATGROUP":"NORM","GROSS_WT":0,"NET_WT":0,"WT_UOM":"KG","VOLUME":0,"SIZE_DIMENSIONS":"210 LT","ITEM_TYPE_C":"Fertigerzeugnis","MATERIAL_GROUP_1":"AD","MATERIAL_GROUP_1_C":"SBU-4","MATERIAL_GROUP_2":"AO","MATERIAL_GROUP_2_C":"Kyros","MATERIAL_GROUP_3":"AS","MATERIAL_GROUP_3_C":"Solvent","MATERIAL_GROUP_4":"CL","MATERIAL_GROUP_4_C":"Solvents","MATERIAL_GROUP_5":"CM","MATERIAL_GROUP_5_C":"Commodity","MATERIAL_FREIGHT_GROUP":"AB","MATERIAL_FREIGHT_GROUP_C":"Non MRP(Barrel&Drum)","LIST_PRICE_MRP_PRICE":"","HSN_CODE":"27101990","LEAD_TIME":0,"PRODUCT_STATUS":"KCVEDALQBGZX","PLANT_EXTENTION":[{"SFDC_ID":"","ITEM_NUMBER":"000000000400009166","PLANT_CODE":"1000","TOTAL_STOCK":0}],"SALES_AREA":[{"SFDC_ID":"","ITEM_NUMBER":"000000000400009166","SALES_ORGANISATION":"","DISTRIBUTION_CHANNEL":"10","DIVISION":"28"}],"CONV_FACT_SALE":[{"SFDC_ID":"","ALT_QUANITTY":"","ALT_UOM":"","BASE_QTY":"","BASE_UOM":"L","ITEM_NUMBER":"000000000400009166","IS_DEFAULT":""}]}]';
ProductMasterJson obj = parse(json);
System.assert(obj != null);
}
*/
    
    
}