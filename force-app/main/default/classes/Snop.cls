public without sharing class Snop {

    @AuraEnabled
    public static List <Order> getSOData(String woid, String orderRecordType) {
        try {
            List<Order> linelist = [SELECT AccountId, Account.Name, ActivatedById, ActivatedDate, BillingAddress, BillingCity, BillingCountry, BillingGeocodeAccuracy, BillingLatitude, BillingLongitude, BillingPostalCode, BillingState, BillingStreet, BillToContactId, 
                CompanyAuthorizedById, SBU__c, Plant_Code__c, Plant_Code__r.Name, CompanyAuthorizedDate, CreatedById, CreatedDate, CurrencyIsoCode, CustomerAuthorizedById, CustomerAuthorizedDate, Description, Distribution_Channel__c, Division__c, Document_Currency__c, Division__r.Name,
                Document_No__c, Ship_to_party__c, Ship_to_party__r.Name, Bill_to_party__c, Bill_to_party__r.Name, Pricing_Status__c, COGS_Status__c, Credit_Status__c, isBlocked__c, Document_Type__c, EffectiveDate, EndDate, Exchange_Rate__c, Id, Inco_Remark__c, Inco_Terms__c, IsDeleted, LastModifiedById, LastModifiedDate, LastReferencedDate, LastViewedDate, Name, Name__c, OpportunityId, Order_Reason__c, 
                OrderNumber, OrderReferenceNumber, OriginalOrderId, OwnerId, Partner_code__c, Partner_function__c, Payment_Terms__c, PoDate, PoNumber, Pricebook2Id, QuoteId, Reason_for_Rejection__c, Reqd_Del_Date__c, Sales_Group__c, Sales_office__c, Sales_Organisations__c, 
                ShippingAddress, ShippingCity, ShippingCountry, ShippingGeocodeAccuracy, ShippingLatitude, ShippingLongitude, ShippingPostalCode, ShippingState, ShippingStreet, ShipToContactId, Status, StatusCode, SystemModstamp, TotalAmount, Type, Valid_from__c, Valid_To__c 
                FROM Order];
            return linelist;
        } catch (Exception e) {
            //ErrorLogCls.saveLog(e.getStackTraceString(), e.getMessage(), woid, '');
            return null;
        }
    }

    // @AuraEnabled
    // public static List <Order> getSearchSOData(List<String> pData,String filters,String orderRecordType) {
    //     Set<Id> sitem = new Set<Id>();
    //     try {
    //         // List<Object> lineListdata = (List<Object>) JSON.deserializeUntyped(pdata);
    //         // for (Object wpline : lineListdata) {
    //         //     Map<String, Object> mapdata = (Map<String, Object>)wpline;
    //         //     sitem.add((Id)mapdata.get('Id'));
    //         // }
    //         Map<String, Object> mapdatafilter = (Map<String, Object>)JSON.deserializeUntyped(filters);
    //         // system.debug('filters >> ' +lineListdata.size());
    //         String specialIntruction='Z005';
    //         String query = '';
           
    //         if(mapdatafilter != null && (String.isNotBlank(String.valueOf(mapdatafilter.get('Product2Id'))) || String.isNotBlank(String.valueOf(mapdatafilter.get('Material_Group_3__c'))) || String.isNotBlank(String.valueOf(mapdatafilter.get('Plant_Code__c')))  || String.isNotBlank(String.valueOf(mapdatafilter.get('First_Date__c')))  )){
    //             List<Order> ord=new List<Order>();
    //             ord=getSOLineItems(pData , mapdatafilter);
    //             return ord;
    //         }
    //         if(mapdatafilter != null) {
    //             query = 'SELECT Id,Ship_to_Party__c,Ship_to_Party__r.Name,Ship_to_Party_Account__c,Ship_to_Party_Account__r.Name,SAP_Doc_no__c,Customer_Raj_Petro_Vehical__c,Order_Clearance_Date__c,OrderNumber, AccountId, Account.Name, Account.City__c,Account.State__c,EffectiveDate,Sales_Executive_Approval_Status__c, Sales_Head_Approval_Status__c, Pricing_Block_Approval_Status__c, Credit_Control_Approval_Status__c, Overall_Approval_Status__c, Inspection_Needed__c, Palletization_Needed__c,Status,Approval_Status__c, ';
    //             query+=' toLabel(SBU1__c) SBU_val,Distribution_Channel__c,Distribution_Channel__r.Name,Division__c,Division__r.Name,Division__r.Division_Code__c, (SELECT Id , Text_ID__c , Text_Description__c  FROM Order_Header_Text__r WHERE Text_ID__c= \'' + String.valueOf(specialIntruction) +'\' LIMIT 1)';
    //             query+=' FROM Order WHERE Id != null ';
    //             query += getIndividualFilter(mapdatafilter, 'SBU1__c','SBU1__c', ' like \'%' + String.valueOf(mapdatafilter.get('SBU1__c')) + '%\' ');
    //             query += getIndividualFilter(mapdatafilter, 'Status','soStatus', '= \'' + String.valueOf(mapdatafilter.get('soStatus')) +'\'');
    //             query += getIndividualFilter(mapdatafilter, 'Division__c','Division__c', '= \'' + String.valueOf(mapdatafilter.get('Division__c')) +'\'');
    //             query += getIndividualFilter(mapdatafilter, 'Distribution_Channel__c','Distribution_Channel__c', '= \'' + String.valueOf(mapdatafilter.get('Distribution_Channel__c')) +'\'');
    //             // query += getIndividualFilter(mapdatafilter, 'Plant_Code__c','Plant_Code__c', '= \'' + String.valueOf(mapdatafilter.get('Plant_Code__c')) +'\'');
    //             query += getIndividualFilter(mapdatafilter, 'Id','Id', '= \'' + String.valueOf(mapdatafilter.get('Id')) +'\'');
    //             // query += getIndividualFilter(mapdatafilter, 'EffectiveDate','EffectiveDate', '= \'' + String.valueOf(mapdatafilter.get('EffectiveDate')) +'\'');
    //             system.debug('EffectiveDate >> ' +mapdatafilter.get('EffectiveDate'));
    //             if (String.isNotBlank(String.valueOf(mapdatafilter.get('EffectiveDate')))) {
    //                 query += ' AND EffectiveDate = ' + mapdatafilter.get('EffectiveDate');
    //             }
    //             if (String.isNotBlank(String.valueOf(mapdatafilter.get('inspectionOrder')))) {
    //                 query += ' AND Inspection_Required__c = ' + mapdatafilter.get('inspectionOrder');
    //             }
    //             query += getIndividualFilter(mapdatafilter, 'Sales_Executive__c','Sales_Executive__c', '= \'' + String.valueOf(mapdatafilter.get('Sales_Executive__c')) +'\'');
    //             query += getIndividualFilter(mapdatafilter, 'AccountId','AccountId', '= \'' + String.valueOf(mapdatafilter.get('AccountId')) +'\'');
    //             query += getIndividualFilter(mapdatafilter, 'Ship_to_Party__c','Ship_to_Party__c', '= \'' + String.valueOf(mapdatafilter.get('Ship_to_Party__c')) +'\'');
    //             query += getIndividualFilter(mapdatafilter, 'Sales_District__c','Sales_District__c', '= \'' + String.valueOf(mapdatafilter.get('Sales_District__c')) +'\'');
    //             query += getIndividualFilter(mapdatafilter, 'Account.State__c','state', ' like \'%' + String.valueOf(mapdatafilter.get('state')) + '%\' ');
    //             query += getIndividualFilter(mapdatafilter, 'Account.City__c','City__c', ' like \'%' + String.valueOf(mapdatafilter.get('City__c')) + '%\' ');
    //             query += getIndividualFilter(mapdatafilter, 'Order_Clearance_Date__c','Order_Clearance_Date__c', '= \'' + String.valueOf(mapdatafilter.get('Order_Clearance_Date__c')) +'\'');
    //             query += getIndividualFilter(mapdatafilter, 'Customer_Raj_Petro_Vehical__c','Customer_Raj_Petro_Vehical__c', '= \'' + String.valueOf(mapdatafilter.get('Customer_Raj_Petro_Vehical__c')) +'\'');
    //         }
    //         query += ' AND LineItemCount__c > 0 AND RecordType.Name =: orderRecordType ORDER BY CreatedDate DESC ';
    //         // system.debug('lineListdata >> ' +lineListdata.size());
    //         system.debug('queryquery >> ' +query);
    //         return Database.query(query);
    //     } catch (Exception e) {
    //         //ErrorLogCls.saveLog(e.getStackTraceString(), e.getMessage(), woid, '');
    //         return null;
    //     }
    // }

    @AuraEnabled
    public static List<OrderItem> getSOLineItem(List<String> pdata) {
        // Set<Id> sitem = new Set<Id>();
        try{
            // List<Object> lineListdata = (List<Object>) JSON.deserializeUntyped(pdata);
            // for (Object wpline : lineListdata) {
            //     Map<String, Object> mapdata = (Map<String, Object>)wpline;
            //     sitem.add((Id)mapdata.get('Id'));
            // }
            System.debug('pdata '+pdata);

            List<OrderItem> piList = [SELECT AvailableQuantity, Product2.Name, Product2.ProductCode, Product2.Base_UOM__r.Name, Product2.Description, Dispatch_Quantity__c, Balanced_Quantity__c, COGS_Margin__c, 
                COGS_Percentage__c, COGS_Rate__c, CreatedById, CreatedDate, CurrencyIsoCode, Lead_time__c,
                Description, Discount__c, Discount_Amount__c, EndDate, Enquiry_Line_Item_No__c, First_Date__c, HSN_Code__c, Id, IsDeleted, Item_Category__c, Item_Number__c, 
                LastModifiedById, LastModifiedDate, ListPrice, OrderId, OrderItemNumber, OriginalOrderItemId, Plant_Code__c, PricebookEntryId, Product2Id, Quantity, QuoteLineItemId, 
                Sales_UOM__c, SAP_Line_No__c, ServiceDate, Status__c, Total_Price__c, TotalPrice, UnitPrice
                FROM OrderItem WHERE OrderId IN :pdata];
            return piList;
        }
        catch(Exception e){
            //ErrorLogCls.saveLog(e.getStackTraceString(),e.getMessage(),pdata,'');
            return null;
        }
    }

    // @AuraEnabled
    // public static List<Order> getSOLineItems(List<String> sitem,Map<String, Object> mapdatafilter) {
    //     // Set<Id> sitem = new Set<Id>();
    //     try{
    //         // List<Object> lineListdata = (List<Object>) JSON.deserializeUntyped(pdata);
    //         // for (Object wpline : lineListdata) {
    //         //     Map<String, Object> mapdata = (Map<String, Object>)wpline;
    //         //     sitem.add((Id)mapdata.get('Id'));
    //         // }
    //         // Map<String, Object> mapdatafilter = (Map<String, Object>)JSON.deserializeUntyped(filters);
    //         // system.debug('filters >> ' +lineListdata.size());
    //         // system.debug('filters >> ' +sitem.size());
    //         // if(sbu =='' && distributionChannel =='' && dispatchLocationCode =='' && dispatchLocationName=='' && soStatus =='' && salesOrderNo =='' && soDate =='' && executive =='' && customerCode =='' && customerName =='' && shipToPartyCode =='' && shipToPartyName =='' && region =='' && state =='' && city =='' && materialGroup3 =='' && materialFrieghtGroup =='' && skuCode =='' && skuName =='' && scheduleDate =='' &&orderClearanceDate =='' && inspectionOrder =='' && vehicleType =='' && nddSku =='' && customerExpectedDate ==''){}

    //         String query = 'SELECT Id,Order.SAP_Doc_no__c, Pending_Volume__c,TotalPrice,Quantity,Sales_UOM__c, Sales_UOM__r.Name, UnitPrice,Freight__c,Insurance__c,Commission__c, Product2Id, Product2.Name,Product2.ProductCode, OrderId, Plant_Code__c, Plant_Code__r.Name,Planning_Ready_by_Date__c,Planning_RM_Confirmation__c, Planning_Dispatch_Remark__c,Planning_Delay_Reason__c, Planning_Remark__c, Logistics_Vehicle_Placement_Date__c, Logistics_Vehicle_Delay_Reason__c, Logistics_Remark__c,Product2.In_Stock__c, First_Date__c, Deviation_Reason__c FROM OrderItem WHERE OrderId IN: sitem ';

    //         if(mapdatafilter != null) {
    //             query += getIndividualFilter(mapdatafilter, 'Product2Id','Product2Id', '= \'' + String.valueOf(mapdatafilter.get('Product2Id')) +'\'');
    //             system.debug('materialgroup >> ' +String.valueOf(mapdatafilter.get('Material_Group_3__c')));
    //             query += getIndividualFilter(mapdatafilter, 'Plant_Code__c','Plant_Code__c', '= \'' + String.valueOf(mapdatafilter.get('Plant_Code__c')) +'\'');
    //             query += getIndividualFilter(mapdatafilter, 'Product2.Material_Group_3__c','Product2.Material_Group_3__c', '= \'' + String.valueOf(mapdatafilter.get('Material_Group_3__c')) +'\'');
    //             if (String.isNotBlank(String.valueOf(mapdatafilter.get('First_Date__c')))) {
    //                 query += ' AND First_Date__c = ' + mapdatafilter.get('First_Date__c');
    //             }
               
    //             // query += getIndividualFilter(filters, 'Order.Division__r.id', 'Division__c');
    //         }
    //         query += ' ORDER BY SAP_Line_No__c asc ';
    //         // system.debug('lineListdata >> ' +lineListdata.size());
    //         system.debug('queryquery >> ' +query);
    //         List<OrderItem> ordLine=new List<OrderItem>();
    //         ordLine=Database.query(query);
    //         Set<Id> ordList=new Set<Id>();
    //         for(OrderItem row:ordLine){
    //             ordList.add(row.OrderId);
    //         }

    //         query = 'SELECT Id,Division__r.Division_Code__c,Status,SAP_Doc_no__c,Ship_to_Party_Account__r.Name,Customer_Raj_Petro_Vehical__c, Order_Clearance_Date__c,OrderNumber, AccountId, Account.Name, EffectiveDate,Sales_Executive_Approval_Status__c, '+
    //             'Sales_Head_Approval_Status__c, Pricing_Block_Approval_Status__c, Credit_Control_Approval_Status__c, Overall_Approval_Status__c, Inspection_Needed__c, Palletization_Needed__c, '+
    //             'toLabel(SBU1__c) SBU_val,Distribution_Channel__c,Distribution_Channel__r.Name,Division__c,Division__r.Name , (SELECT Id , Text_ID__c , Text_Description__c '+
    //             'FROM Order_Header_Text__r WHERE Text_ID__c=\'Z005\' LIMIT 1) FROM Order ' +
    //             'WHERE Id IN :ordList ';

    //         query += getIndividualFilter(mapdatafilter, 'SBU1__c','SBU1__c', ' like \'%' + String.valueOf(mapdatafilter.get('SBU1__c')) + '%\' ');
    //         query += getIndividualFilter(mapdatafilter, 'Status','soStatus', '= \'' + String.valueOf(mapdatafilter.get('soStatus')) +'\'');
    //         query += getIndividualFilter(mapdatafilter, 'Division__c','Division__c', '= \'' + String.valueOf(mapdatafilter.get('Division__c')) +'\'');
    //         query += getIndividualFilter(mapdatafilter, 'Distribution_Channel__c','Distribution_Channel__c', '= \'' + String.valueOf(mapdatafilter.get('Distribution_Channel__c')) +'\'');
    //         // query += getIndividualFilter(mapdatafilter, 'Plant_Code__c','Plant_Code__c', '= \'' + String.valueOf(mapdatafilter.get('Plant_Code__c')) +'\'');
    //         query += getIndividualFilter(mapdatafilter, 'Id','Id', '= \'' + String.valueOf(mapdatafilter.get('Id')) +'\'');
    //         query += getIndividualFilter(mapdatafilter, 'EffectiveDate','EffectiveDate', '= \'' + String.valueOf(mapdatafilter.get('EffectiveDate')) +'\'');
    //         query += getIndividualFilter(mapdatafilter, 'Sales_Executive__c','Sales_Executive__c', '= \'' + String.valueOf(mapdatafilter.get('Sales_Executive__c')) +'\'');
    //         query += getIndividualFilter(mapdatafilter, 'AccountId','AccountId', '= \'' + String.valueOf(mapdatafilter.get('AccountId')) +'\'');
    //         query += getIndividualFilter(mapdatafilter, 'Ship_to_Party__c','Ship_to_Party__c', '= \'' + String.valueOf(mapdatafilter.get('Ship_to_Party__c')) +'\'');
    //         query += getIndividualFilter(mapdatafilter, 'Sales_District__c','Sales_District__c', '= \'' + String.valueOf(mapdatafilter.get('Sales_District__c')) +'\'');
    //         query += getIndividualFilter(mapdatafilter, 'Account.City__c','City__c', ' like \'%' + String.valueOf(mapdatafilter.get('City__c')) + '%\' ');
    //         query += getIndividualFilter(mapdatafilter, 'Order_Clearance_Date__c','Order_Clearance_Date__c', '= \'' + String.valueOf(mapdatafilter.get('Order_Clearance_Date__c')) +'\'');
    //         query += getIndividualFilter(mapdatafilter, 'Customer_Raj_Petro_Vehical__c','Customer_Raj_Petro_Vehical__c', '= \'' + String.valueOf(mapdatafilter.get('Customer_Raj_Petro_Vehical__c')) +'\'');

            
    //         // List<Order> fetchordList=new List<Order>();

    //         // fetchordList=[SELECT Id,Customer_Raj_Petro_Vehical__c, Order_Clearance_Date__c,OrderNumber, AccountId, Account.Name, EffectiveDate,Sales_Executive_Approval_Status__c, Sales_Head_Approval_Status__c, Pricing_Block_Approval_Status__c, Credit_Control_Approval_Status__c, Overall_Approval_Status__c, Inspection_Needed__c, Palletization_Needed__c,
    //         // toLabel(SBU1__c) SBU_val,Distribution_Channel__c,Distribution_Channel__r.Name,Division__c,Division__r.Name , (SELECT Id , Text_ID__c , Text_Description__c  FROM Order_Header_Text__r WHERE Text_ID__c='Z005' LIMIT 1) FROM Order WHERE Id IN :ordList];
    //         // return fetchordList;
            

    //         return Database.query(query);

    //     }
    //     catch(Exception e){
    //         //ErrorLogCls.saveLog(e.getStackTraceString(),e.getMessage(),pdata,'');
    //         return null;
    //     }
    // }


    // private static string getIndividualFilter(Map<String, Object> filters, String fieldName, String filterName ,String queryCond) {
    //     System.debug(filterName);
    //     System.debug(filters);
    //     String filterNametemp = '';
    //     if (filterName == 'Product2.Material_Group_3__c') {
    //         filterNametemp = 'Material_Group_3__c';
    //     } else {
    //         filterNametemp = filterName;
    //     }
    //     if(filters != null) {
    //         if(filters.containsKey(filterNametemp) && String.isNotBlank(String.valueOf(filters.get(filterNametemp)))) {
    //             return ' AND ' + fieldName +' '+ queryCond;
    //         }
    //     }
    //     return '';
    // }


    @AuraEnabled
    public static string saveline(String lineItem){
        system.debug('lineItem >> ' +lineItem);

        Savepoint sp = Database.setSavepoint();

        Map<String,Object> mp=new Map<String,Object>();
        // try
        // {
            List<Object> lineListdata = (List<Object>) JSON.deserializeUntyped(lineItem);
            System.debug('lst_data -> ' + lineListdata );
            Set<Id> orderIds=new Set<Id>();
            Set<Id> orderItemIds=new Set<Id>();
            for (Object asnline : lineListdata) {
                Map<String, Object> mapdata = (Map<String, Object>)asnline;
                orderIds.add((String)mapdata.get('OrderId'));
                orderItemIds.add((String)mapdata.get('Id'));
            }
            List<Partial_Disptach_Qty__c> partiaList=new List<Partial_Disptach_Qty__c>();
            partiaList=[SELECT Id,Name , Disptach_Qty__c,Order__c,Order_Product__c,Planning_Dispatch_Remark__c,Planning_Ready_by_Date__c,Deviation_Reason__c 
                    FROM Partial_Disptach_Qty__c
                    WHERE Order__c IN :orderIds
                    AND Order_Product__c IN:orderItemIds];
            Map<String,String> mpPartialList=new Map<String,String>();
            for(Partial_Disptach_Qty__c row:partiaList){
                mpPartialList.put(row.Order__c+'-'+row.Order_Product__c,row.Id);
            }

            List<Partial_Disptach_Qty__c> linelist_partial = new List<Partial_Disptach_Qty__c>();
            List<OrderItem> linelist = new List<OrderItem>();
            for (Object asnline : lineListdata) {
                Map<String, Object> mapdata = (Map<String, Object>)asnline;
                System.debug('mp_data -> ' + mapdata );

                OrderItem t  = new OrderItem();
                t.Id  = (String)mapdata.get('Id');
                t.Planning_Ready_by_Date__c = null;
                if ((String)mapdata.get('Planning_Ready_by_Date__c') != null) {
                    // System.debug('mp_data -> ' + (String)mapdata.get('OrderId') );
                    // System.debug('mp_data -> ' + (String)mapdata.get('Id') );
                    // System.debug('mp_data -> ' + (String)mapdata.get('OrderId')+'-'+(String)mapdata.get('Id') );
                    // System.debug('mp_data -> ' +mpPartialList.get((String)mapdata.get('OrderId')+'-'+(String)mapdata.get('Id')) );
                   // if(mpPartialList.get((String)mapdata.get('OrderId')+'-'+(String)mapdata.get('Id')) ==null){
                        Partial_Disptach_Qty__c parDis=new Partial_Disptach_Qty__c();
                        parDis.Id=mpPartialList.get((String)mapdata.get('OrderId')+'-'+(String)mapdata.get('Id'));
                        parDis.Name=Integer.valueOf(mapdata.get('Pending_Volume__c'))+' qty Will be dispacthed on '+t.Planning_Ready_by_Date__c;
                        parDis.Order__c=(String)mapdata.get('OrderId');
                        parDis.Order_Product__c=(String)mapdata.get('Id');
                        parDis.Planning_Ready_by_Date__c = Date.valueOf((String)mapdata.get('Planning_Ready_by_Date__c'));
                        parDis.Disptach_Qty__c = Integer.valueOf(mapdata.get('Pending_Volume__c'));
                        parDis.Planning_Dispatch_Remark__c= (String)mapdata.get('Planning_Dispatch_Remark__c');
                        parDis.Deviation_Reason__c= (String)mapdata.get('Deviation_Reason__c');
                        linelist_partial.add(parDis);
                    //}
                    t.Planning_Ready_by_Date__c         = Date.valueOf((String)mapdata.get('Planning_Ready_by_Date__c'));
                }
                t.Planning_RM_Confirmation__c           = (String)mapdata.get('Planning_RM_Confirmation__c');
                t.Planning_Dispatch_Remark__c           = (String)mapdata.get('Planning_Dispatch_Remark__c');
                t.Planning_Remark__c                    = (String)mapdata.get('Planning_Remark__c');
                t.Deviation_Reason__c                    = (String)mapdata.get('Deviation_Reason__c');
                //t.Logistics_Vehicle_Placement_Date__c   = Date.valueOf((String)mapdata.get('Logistics_Vehicle_Placement_Date__c'));
                // t.Logistics_Vehicle_Placement_Date__c = null;
                // if ((String)mapdata.get('Logistics_Vehicle_Placement_Date__c') != null) {
                //     t.Logistics_Vehicle_Placement_Date__c   = Date.valueOf((String)mapdata.get('Logistics_Vehicle_Placement_Date__c'));
                // }
                // t.Logistics_Vehicle_Delay_Reason__c     = (String)mapdata.get('Logistics_Vehicle_Delay_Reason__c');
                // t.Logistics_Remark__c                   = (String)mapdata.get('Logistics_Remark__c');
                // t.No_of_Pallete__c      = ((String)mapdata.get('aaaa') == null ? null : Integer.valueOf(mapdata.get('aaaaa')));
                // t.Aisle__c              = ((String)mapdata.get('Aisle__c') == ''? null : (String)mapdata.get('Aisle__c'));
                // t.Gross_Weight__c       = Integer.valueOf(mapdata.get('customQuantity')) *((Decimal)((Map<String, Object>)mapdata.get('SKU_Code__r')).get('Per_Unit_Gross_Weight__c')).setscale(ConstantCls.WEIGHTT_DECIMAL);
                linelist.add(t);
            }

            Boolean valiadateCheck = false;
            if(linelist.size() > 0) {
                UPDATE linelist;
                List<Order> ord=[SELECT Id,Status FROM  Order WHERE Id IN: orderIds];
                for(Order row:ord){
                    row.Status='Dispatch Planned';
                }
                UPDATE ord; 
            }
            UPSERT linelist_partial;
            valiadateCheck = true;

            mp.put('status', true);
            mp.put('msg','Insert Succesfully');
            mp.put('ReceiptIssued', valiadateCheck);
        // } catch (Exception e) {
        //     Database.RollBack(sp);
        //     //ErrorLogCls.saveLog(e.getStackTraceString(),e.getMessage(),lineItem, '');
        //     mp.put('status', false);
        //     mp.put('msg', e.getMessage());
        // }
        return JSON.serialize(mp);
    }

    public static String replacer(Object obj) {
        if (obj == null) {
            return '';
        } else {
            return String.valueOf(obj);
        }
    }
    @AuraEnabled
    public static Boolean savePartialDisptach(String orderId,String orderLineItemId,String dataList){
        try {
            List<Object> lineListdata = (List<Object>) JSON.deserializeUntyped(dataList);
            System.debug('lst_data -> ' + lineListdata );

            // List<Order> linelist = new List<Order>();
            List<Partial_Disptach_Qty__c> linelist = new List<Partial_Disptach_Qty__c>();
            for (Object asnline : lineListdata) {
                Map<String, Object> mapdata = (Map<String, Object>)asnline;
                System.debug('mp_data -> ' + mapdata );
                Partial_Disptach_Qty__c t=new Partial_Disptach_Qty__c();
                String id= (String)mapdata.get('Id');
                t.Order__c=orderId;
                t.Order_Product__c=orderLineItemId;
                if(!id.Contains('create')){
                    t.Id=(String)mapdata.get('Id');
                }
                if ((String)mapdata.get('Planning_Ready_by_Date__c') != null) {
                    t.Planning_Ready_by_Date__c = Date.valueOf((String)mapdata.get('Planning_Ready_by_Date__c'));
                    t.Name=Decimal.valueOf(String.valueOf(mapdata.get('Disptach_Qty__c')))+'qty Will be dispacthed on '+Date.valueOf((String)mapdata.get('Planning_Ready_by_Date__c'));
                    // t.Name=(String)mapdata.get('Planning_Ready_by_Date__c')+'-'+(String)mapdata.get('Disptach_Qty__c');
                   
                }
                System.debug('==> '+mapdata.get('Disptach_Qty__c') );
                // if (mapdata.get('Disptach_Qty__c') != null) {
                    t.Disptach_Qty__c = Decimal.valueOf(String.valueOf(mapdata.get('Disptach_Qty__c')));
                    // t.Disptach_Qty__c = (Decimal)mapdata.get('Disptach_Qty__c');
                // }
                t.Planning_Dispatch_Remark__c= (String)mapdata.get('Planning_Dispatch_Remark__c');
                t.Deviation_Reason__c= (String)mapdata.get('Deviation_Reason__c');
                linelist.add(t);
            }
            UPSERT linelist;
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    @AuraEnabled
    public static List<Partial_Disptach_Qty__c> getPartialData(String orderId,String orderLineItemId){
        try {
            return [SELECT Id,Name , Disptach_Qty__c,Order__c,Order_Product__c,Planning_Dispatch_Remark__c,Planning_Ready_by_Date__c,Deviation_Reason__c 
                    FROM Partial_Disptach_Qty__c
                    WHERE Order__c=:orderId
                    AND Order_Product__c=:orderLineItemId
                    ORDER By CreatedDate];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Partial_Disptach_Qty__c> getDisptachList(String lineItem){
        Set<Id> sitem = new Set<Id>();
        try{
            List<Object> lineListdata = (List<Object>) JSON.deserializeUntyped(lineItem);
            System.debug('lst_data -> ' + lineListdata );
            Set<Id> orderIds=new Set<Id>();
            Set<Id> orderItemIds=new Set<Id>();
            for (Object asnline : lineListdata) {
                Map<String, Object> mapdata = (Map<String, Object>)asnline;
                orderIds.add((String)mapdata.get('OrderId'));
                orderItemIds.add((String)mapdata.get('Id'));
            }

            List<Partial_Disptach_Qty__c> partiaList=new List<Partial_Disptach_Qty__c>();
            partiaList=[SELECT Id,Name , Disptach_Qty__c,Order__c,Order_Product__c,Planning_Dispatch_Remark__c,Planning_Ready_by_Date__c,Deviation_Reason__c 
                    FROM Partial_Disptach_Qty__c
                    WHERE Order__c IN :orderIds
                    AND Order_Product__c IN:orderItemIds];

            return partiaList;
        }
        catch(Exception e){
            //ErrorLogCls.saveLog(e.getStackTraceString(),e.getMessage(),pdata,'');
            return null;
        }
    }

    @AuraEnabled
    public static Boolean removeALlPartialData(String orderId,String orderLineItemId){
        try {
             List<Partial_Disptach_Qty__c>  partialData=new List<Partial_Disptach_Qty__c>();
             partialData =[SELECT Id,Name , Disptach_Qty__c,Order__c,Order_Product__c,Planning_Dispatch_Remark__c,Planning_Ready_by_Date__c,Deviation_Reason__c 
                    FROM Partial_Disptach_Qty__c
                    WHERE Order__c=:orderId
                    AND Order_Product__c=:orderLineItemId];
                    DELETE partialData;
                    return true;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean removeRowPartialData(String dispatchId){
        try {
             List<Partial_Disptach_Qty__c>  partialData=new List<Partial_Disptach_Qty__c>();
             partialData =[SELECT Id,Name , Disptach_Qty__c,Order__c,Order_Product__c,Planning_Dispatch_Remark__c,Planning_Ready_by_Date__c,Deviation_Reason__c 
                    FROM Partial_Disptach_Qty__c
                    WHERE Id=:dispatchId];
                    DELETE partialData;
                    return true;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
 
}