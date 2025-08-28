public without sharing class Snop {

    @AuraEnabled
    public static List <Order> getSOData(String orderRecordType) {
        try {
            List<Order> linelist = [SELECT AccountId, Account.Name, ActivatedById, ActivatedDate, BillingAddress, BillingCity, BillingCountry, BillingGeocodeAccuracy, BillingLatitude, BillingLongitude, BillingPostalCode, BillingState, BillingStreet, BillToContactId, 
                CompanyAuthorizedById, SBU__c, Plant_Code__c, Plant_Code__r.Name, CompanyAuthorizedDate, CreatedById, CreatedDate, CurrencyIsoCode, CustomerAuthorizedById, CustomerAuthorizedDate, Description, Distribution_Channel__c, Division__c, Document_Currency__c, Division__r.Name,
                Document_No__c, Ship_to_party__c, Ship_to_party__r.Name, Bill_to_party__c, Bill_to_party__r.Name, Pricing_Status__c, COGS_Status__c, Credit_Status__c, isBlocked__c, Document_Type__c, EffectiveDate, EndDate, Exchange_Rate__c, Id, Inco_Remark__c, Inco_Terms__c, IsDeleted, LastModifiedById, LastModifiedDate, LastReferencedDate, LastViewedDate, Name, Name__c, OpportunityId, Order_Reason__c, 
                OrderNumber, OrderReferenceNumber, OriginalOrderId, OwnerId, Partner_code__c, Partner_function__c, Payment_Terms__c, PoDate, PoNumber, Pricebook2Id, QuoteId, Reason_for_Rejection__c, Reqd_Del_Date__c, Sales_Group__c, Sales_office__c, Sales_Organisations__c, 
                ShippingAddress, ShippingCity, ShippingCountry, ShippingGeocodeAccuracy, ShippingLatitude, ShippingLongitude, ShippingPostalCode, ShippingState, ShippingStreet, ShipToContactId, Status, StatusCode, SystemModstamp, TotalAmount, Type, Valid_from__c, Valid_To__c 
                FROM Order WHERE Account.Business_Type__c = :orderRecordType];
            return linelist;
        } catch (Exception e) {
            //ErrorLogCls.saveLog(e.getStackTraceString(), e.getMessage(), woid, '');
            return null;
        }
    }

    @AuraEnabled
    public static List<OrderItem> getSOLineItem(List<String> pdata) {
        try{
            System.debug('pdata '+pdata);

            List<OrderItem> piList = [SELECT AvailableQuantity, Product2.Name, Product2.ProductCode, Product2.Base_UOM__r.Name, Product2.Description, Dispatch_Quantity__c, Balanced_Quantity__c, COGS_Margin__c, 
                COGS_Percentage__c, COGS_Rate__c, CreatedById, CreatedDate, CurrencyIsoCode, Lead_time__c, Product2.Sales_UOM__c, Product2.Sales_UOM__r.Name,
                Description, Discount__c, Discount_Amount__c, EndDate, Enquiry_Line_Item_No__c, First_Date__c, HSN_Code__c, Id, IsDeleted, Item_Category__c, Item_Number__c, 
                LastModifiedById, LastModifiedDate, ListPrice, OrderId, OrderItemNumber, OriginalOrderItemId, Plant_Code__c, PricebookEntryId, Product2Id, Quantity, QuoteLineItemId, 
                Sales_UOM__c, SAP_Line_No__c, ServiceDate, Status__c, Total_Price__c, TotalPrice, UnitPrice
                FROM OrderItem WHERE OrderId IN :pdata];
            return piList;
        }
        catch(Exception e){
            return null;
        }
    }

    @AuraEnabled
    public static String saveHeader(String headerStringObj) {
        List<HeaderWrapper> wrapperObjs = parseHeader(headerStringObj);

        List<Order> ordersTobeUpdated = new List<Order>();

        for (HeaderWrapper wrapperObj : wrapperObjs) {
            Order order = new Order(Id = wrapperObj.id);
            order.Pricing_Status__c = wrapperObj.pricingStatus;
            order.COGS_Status__c = wrapperObj.cogsStatus;
            order.Credit_Status__c = wrapperObj.creditStatus;
            ordersTobeUpdated.add(order);
        }


        UPDATE ordersTobeUpdated;

        return 'Success';
    }

    private static List<HeaderWrapper> parseHeader(string js){
        return (List<HeaderWrapper>)system.JSON.deserialize(js,List<HeaderWrapper>.class);
    }

    private static FilterWrapper parseHeaderFilter(string js){
        return (FilterWrapper)system.JSON.deserialize(js,FilterWrapper.class);
    }

    @AuraEnabled(cacheable=true)
    public static OptionWrapper getOrderPicklistOptions(String orderRecordType) {
        List<Order> linelist = [
            SELECT Id, OrderNumber,
                Plant_Code__c, Plant_Code__r.Name,
                Bill_to_party__c, Bill_to_party__r.Name,
                Ship_to_party__c, Ship_to_party__r.Name,
                AccountId, Account.Name
            FROM Order
            WHERE Account.Business_Type__c = :orderRecordType
        ];

        OptionWrapper wrap = new OptionWrapper();

        // init lists
        wrap.orderNumberPicklist = new List<OptionChildWrapper>();
        wrap.sbuPicklist = new List<OptionChildWrapper>();
        wrap.orderStatusPicklist = new List<OptionChildWrapper>();
        wrap.plantPicklist = new List<OptionChildWrapper>();
        wrap.customerPicklist = new List<OptionChildWrapper>();
        wrap.billToPartyPicklist = new List<OptionChildWrapper>();
        wrap.shipToPartyPicklist = new List<OptionChildWrapper>();

        // use sets for uniqueness
        Set<String> orderNumbers = new Set<String>();
        Set<Id> plants = new Set<Id>();
        Set<Id> customers = new Set<Id>();
        Set<Id> billToParties = new Set<Id>();
        Set<Id> shipToParties = new Set<Id>();

        for (Order o : linelist) {

            if (String.isNotBlank(o.OrderNumber) && !orderNumbers.contains(o.OrderNumber)) {
                wrap.orderNumberPicklist.add(new OptionChildWrapper(o.OrderNumber, o.OrderNumber));
                orderNumbers.add(o.OrderNumber);
            }

            if (o.Plant_Code__c != null && !plants.contains(o.Plant_Code__c)) {
                wrap.plantPicklist.add(new OptionChildWrapper(o.Plant_Code__r.Name, o.Plant_Code__c));
                plants.add(o.Plant_Code__c);
            }

            if (o.AccountId != null && !customers.contains(o.AccountId)) {
                wrap.customerPicklist.add(new OptionChildWrapper(o.Account.Name, o.AccountId));
                customers.add(o.AccountId);
            }

            if (o.Bill_to_party__c != null && !billToParties.contains(o.Bill_to_party__c)) {
                wrap.billToPartyPicklist.add(new OptionChildWrapper(o.Bill_to_party__r.Name, o.Bill_to_party__c));
                billToParties.add(o.Bill_to_party__c);
            }

            if (o.Ship_to_party__c != null && !shipToParties.contains(o.Ship_to_party__c)) {
                wrap.shipToPartyPicklist.add(new OptionChildWrapper(o.Ship_to_party__r.Name, o.Ship_to_party__c));
                shipToParties.add(o.Ship_to_party__c);
            }
        }

        Schema.DescribeFieldResult fieldResult = Order.SBU__c.getDescribe();
        List<Schema.PicklistEntry> values = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry val : values) {
            wrap.sbuPicklist.add(new OptionChildWrapper(val.getLabel(), val.getValue()));
        }

        Schema.DescribeFieldResult fieldResult2 = Order.Status.getDescribe();
        List<Schema.PicklistEntry> values2 = fieldResult2.getPicklistValues();
        for (Schema.PicklistEntry val : values2) {
            wrap.orderStatusPicklist.add(new OptionChildWrapper(val.getLabel(), val.getValue()));
        }

        return wrap;
    }

    @AuraEnabled
    public static List<Order> getFilteredOrders(String filterStringObj, String orderType) {
        FilterWrapper filter = parseHeaderFilter(filterStringObj);

        String baseQuery = 
            'SELECT Id, OrderNumber, Status, SBU__c, ' +
            'Plant_Code__c, Plant_Code__r.Name, ' +
            'AccountId, Account.Name, ' +
            'Bill_to_party__c, Bill_to_party__r.Name, ' +
            'Ship_to_party__c, Ship_to_party__r.Name, ' +
            'EffectiveDate, isBlocked__c ' +
            'FROM Order WHERE Account.Business_Type__c = \'' + String.escapeSingleQuotes(orderType) + '\'';

        List<String> conditions = new List<String>();

        if (String.isNotBlank(filter.sbuFilter)) {
            conditions.add('SBU__c = \'' + String.escapeSingleQuotes(filter.sbuFilter) + '\'');
        }
        if (String.isNotBlank(filter.statusFilter)) {
            conditions.add('Status = \'' + String.escapeSingleQuotes(filter.statusFilter) + '\'');
        }
        if (String.isNotBlank(filter.orderNumberFilter)) {
            conditions.add('OrderNumber = \'' + String.escapeSingleQuotes(filter.orderNumberFilter) + '\'');
        }
        // if (filter.orderDateFilter != null) {
        //     conditions.add('EffectiveDate = ' + filter.orderDateFilter.format('yyyy-mm-dd'));
        // }
        if (String.isNotBlank(filter.plantFilter)) {
            conditions.add('Plant_Code__c = \'' + String.escapeSingleQuotes(filter.plantFilter) + '\'');
        }
        if (String.isNotBlank(filter.customerFilter)) {
            conditions.add('AccountId = \'' + String.escapeSingleQuotes(filter.customerFilter) + '\'');
        }
        if (String.isNotBlank(filter.billToFilter)) {
            conditions.add('Bill_to_party__c = \'' + String.escapeSingleQuotes(filter.billToFilter) + '\'');
        }
        if (String.isNotBlank(filter.shipToFilter)) {
            conditions.add('Ship_to_party__c = \'' + String.escapeSingleQuotes(filter.shipToFilter) + '\'');
        }

        if (!conditions.isEmpty()) {
            baseQuery += ' AND ' + String.join(conditions, ' AND ');
        }

        System.debug('Final Query ==> ' + baseQuery);

        return Database.query(baseQuery);
    }





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
                t.Lead_time__c = (String)mapdata.get('Lead_time__c');
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

    public class HeaderWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String pricingStatus;
        @AuraEnabled public String cogsStatus;
        @AuraEnabled public String creditStatus;
    }


    public class OptionWrapper {
        @AuraEnabled public List<OptionChildWrapper> orderNumberPicklist;
        @AuraEnabled public List<OptionChildWrapper> orderStatusPicklist;
        @AuraEnabled public List<OptionChildWrapper> sbuPicklist;
        @AuraEnabled public List<OptionChildWrapper> plantPicklist;
        @AuraEnabled public List<OptionChildWrapper> customerPicklist;
        @AuraEnabled public List<OptionChildWrapper> billToPartyPicklist;
        @AuraEnabled public List<OptionChildWrapper> shipToPartyPicklist;
    }

    public class OptionChildWrapper {
        @AuraEnabled public String label;
        @AuraEnabled public String value;

        public OptionChildWrapper(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    public class FilterWrapper {
        @AuraEnabled public String sbuFilter { get; set; }
        @AuraEnabled public String statusFilter { get; set; }
        @AuraEnabled public String orderNumberFilter { get; set; }
        @AuraEnabled public Date orderDateFilter { get; set; }
        @AuraEnabled public String plantFilter { get; set; }
        @AuraEnabled public String customerFilter { get; set; }
        @AuraEnabled public String billToFilter { get; set; }
        @AuraEnabled public String shipToFilter { get; set; }
    }

 
}