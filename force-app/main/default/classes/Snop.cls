public without sharing class Snop {

    

    @AuraEnabled(cacheable=true)
    public static List<OrderWrapper> getOrdersWithLineItems(String orderRecordType) {
        try {
            List<Order> orders = [
                SELECT Id, AccountId, Account.Name, SBU__c, Plant_Code__c, Plant_Code__r.Name,
                       Block_Status__c, Ship_to_party__c, Ship_to_party__r.Name, Bill_to_party__c, Bill_to_party__r.Name,
                       Pricing_Status__c, COGS_Status__c, Credit_Status__c, EffectiveDate, Status, OrderNumber, 
                       Document_No__c, Name, CreatedDate
                FROM Order
                WHERE Account.Business_Type__c = :orderRecordType
            ];

            if (orders.isEmpty()) {
                return new List<OrderWrapper>();
            }

            List<Order_Scheduling_Line_Item_wise__c> allLineItems = [
                SELECT Id, Name, Confirmed_Quantity__c, Scheduled_Quantity__c, Balance_Quantity__c, Delivery_Date__c,
                       Order__c,
                       Order_Product__c,
                       Order_Product__r.Plant_Code__c,
                       Order_Product__r.Product2.Name,
                       Order_Product__r.Product2.ProductCode,
                       Order_Product__r.Product2.Base_UOM__r.Name,
                       Order_Product__r.Product2.Description,
                       Order_Product__r.Product2.Sales_UOM__c,
                       Order_Product__r.Product2.Sales_UOM__r.Name
                FROM Order_Scheduling_Line_Item_wise__c
                WHERE Order__c IN :orders
            ];

            Map<Id, List<Order_Scheduling_Line_Item_wise__c>> lineItemMap = new Map<Id, List<Order_Scheduling_Line_Item_wise__c>>();
            for (Order_Scheduling_Line_Item_wise__c li : allLineItems) {
                if (!lineItemMap.containsKey(li.Order__c)) {
                    lineItemMap.put(li.Order__c, new List<Order_Scheduling_Line_Item_wise__c>());
                }
                lineItemMap.get(li.Order__c).add(li);
            }

            List<OrderWrapper> results = new List<OrderWrapper>();
            for (Order o : orders) {
                List<Order_Scheduling_Line_Item_wise__c> relatedItems = lineItemMap.containsKey(o.Id) 
                    ? lineItemMap.get(o.Id) 
                    : new List<Order_Scheduling_Line_Item_wise__c>();

                results.add(new OrderWrapper(o, relatedItems));
            }

            return results;

        } catch (Exception e) {
            throw new AuraHandledException('Error fetching Orders with Line Items: ' + e.getMessage());
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
    public static void saveCustomerSchedules(List<CustomerScheduleWrapper> wrapperList) {
        List<Customer_Order_Schedule_Line_Item__c> recordsToUpsert = new List<Customer_Order_Schedule_Line_Item__c>();

        for (CustomerScheduleWrapper wrap : wrapperList) {
            Customer_Order_Schedule_Line_Item__c rec = new Customer_Order_Schedule_Line_Item__c();

            if (wrap.recordId != null) {
                rec.Id = wrap.recordId; // ensures update instead of insert
            }

            rec.Name = wrap.name;
            rec.Customer_Scheduled_Quantity__c = wrap.customerScheduledQuantity;
            rec.Customer_Scheduled_Date__c = wrap.customerScheduledDate;
            rec.Production_Revised_Date__c = wrap.productionRevisedDate;
            rec.Production_Scheduled_Date__c = wrap.productionScheduledDate;
            rec.Remarks_for_Production_Planner__c = wrap.remarksForProductionPlanner;
            rec.Order__c = wrap.orderId;
            rec.Order_Product__c = wrap.orderProductId;
            rec.Order_Scheduling_Line_Item__c = wrap.orderSchedulingLineItemId;

            recordsToUpsert.add(rec);
        }

        if (!recordsToUpsert.isEmpty()) {
            upsert recordsToUpsert;
        }
    }


    @AuraEnabled
    public static List<CustomerScheduleWrapper> getScheduledOrder(String orderId, String orderLineItemId, String orderSchedulingLineItemId){
        List<Customer_Order_Schedule_Line_Item__c> customerScheduleLineItem = 
        [
            SELECT 
                Id, 
                Name, 
                Customer_Scheduled_Quantity__c,
                Customer_Scheduled_Date__c,
                Production_Revised_Date__c,
                Production_Scheduled_Date__c,
                Remarks_for_Production_Planner__c,
                Order__c,
                Order_Product__c,
                Order_Scheduling_Line_Item__c
            FROM Customer_Order_Schedule_Line_Item__c
            WHERE Order__c = :orderId
            AND Order_Product__c = :orderLineItemId
            AND Order_Scheduling_Line_Item__c = :orderSchedulingLineItemId
            ORDER By CreatedDate
        ];

        List<CustomerScheduleWrapper> customerScheduleObjs = new List<CustomerScheduleWrapper>();

        for (Customer_Order_Schedule_Line_Item__c eachCustomerScheduleLineItem : customerScheduleLineItem) {
            customerScheduleObjs.add(new CustomerScheduleWrapper(eachCustomerScheduleLineItem));
        }

        return customerScheduleObjs;
    }

    @AuraEnabled
    public static Boolean removeAllCustomerSchedules(String orderId, String orderLineItemId, String orderSchedulingLineItemId){
        List<Customer_Order_Schedule_Line_Item__c>  partialData = new List<Customer_Order_Schedule_Line_Item__c>();
        partialData =[SELECT Id
            FROM Customer_Order_Schedule_Line_Item__c
            WHERE Order__c=:orderId
            AND Order_Product__c=:orderLineItemId
            AND Order_Scheduling_Line_Item__c = :orderSchedulingLineItemId];
        DELETE partialData;
        return true;
    }

    @AuraEnabled
    public static Boolean removeRowCustomerSchedule(String scheduleId){
        List<Customer_Order_Schedule_Line_Item__c>  partialData=new List<Customer_Order_Schedule_Line_Item__c>();
        partialData =[SELECT Id
            FROM Customer_Order_Schedule_Line_Item__c
            WHERE Id=:scheduleId];
            DELETE partialData;
            return true;
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

    public class OrderMaster {
        @AuraEnabled public String orderId;
        @AuraEnabled public String accountId;
        @AuraEnabled public String accountName;
        @AuraEnabled public String sbu;
        @AuraEnabled public String plantCode;
        @AuraEnabled public String plantCodeName;
        @AuraEnabled public String blockStatus;
        @AuraEnabled public String shipToPartyId;
        @AuraEnabled public String shipToPartyName;
        @AuraEnabled public String billToPartyId;
        @AuraEnabled public String billToPartyName;
        @AuraEnabled public String pricingStatus;
        @AuraEnabled public String cogsStatus;
        @AuraEnabled public String creditStatus;
        @AuraEnabled public Date effectiveDate;
        @AuraEnabled public String status;
        @AuraEnabled public String orderNumber;
        @AuraEnabled public String documentNo;
        @AuraEnabled public String name;
        @AuraEnabled public Datetime createdDate;
        @AuraEnabled public Boolean isExpanded = false;
        @AuraEnabled public List<OrderSchedulingLine> orderSchedulingLine;

        public OrderMaster(Order order, List<OrderSchedulingLine> lineItems) {
            this.orderId          = order.Id;
            this.accountId        = order.AccountId;
            this.accountName      = (order.Account != null) ? order.Account.Name : null;
            this.sbu              = order.SBU__c;
            this.plantCode        = order.Plant_Code__c;
            this.plantCodeName    = (order.Plant_Code__r != null) ? order.Plant_Code__r.Name : null;
            this.blockStatus      = order.Block_Status__c;
            this.shipToPartyId    = order.Ship_to_party__c;
            this.shipToPartyName  = (order.Ship_to_party__r != null) ? order.Ship_to_party__r.Name : null;
            this.billToPartyId    = order.Bill_to_party__c;
            this.billToPartyName  = (order.Bill_to_party__r != null) ? order.Bill_to_party__r.Name : null;
            this.pricingStatus    = order.Pricing_Status__c;
            this.cogsStatus       = order.COGS_Status__c;
            this.creditStatus     = order.Credit_Status__c;
            this.effectiveDate    = order.EffectiveDate;
            this.status           = order.Status;
            this.orderNumber      = order.OrderNumber;
            this.documentNo       = order.Document_No__c;
            this.name             = order.Name;
            this.createdDate      = order.CreatedDate;
            this.orderSchedulingLine = lineItems;
        }
    }

    public class OrderSchedulingLine {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public Decimal confirmedQuantity;
        @AuraEnabled public Decimal scheduledQuantity;
        @AuraEnabled public Decimal balanceQuantity;
        @AuraEnabled public Date deliveryDate;
        @AuraEnabled public Id orderId;
        @AuraEnabled public Id orderProductId;
        @AuraEnabled public String plantCode;
        @AuraEnabled public String productName;
        @AuraEnabled public String productCode;
        @AuraEnabled public String baseUOMName;
        @AuraEnabled public String productDescription;
        @AuraEnabled public String salesUOM;
        @AuraEnabled public String salesUOMName;
        @AuraEnabled public List<CustomerOrderSchedulingLine> customerSchedules;

        public OrderSchedulingLine(Order_Scheduling_Line_Item_wise__c orderSchedulingLine, List<Customer_Order_Schedule_Line_Item__c> customerSchedules) {
            this.id                 = orderSchedulingLine.Id;
            this.name               = orderSchedulingLine.Name;
            this.confirmedQuantity  = orderSchedulingLine.Confirmed_Quantity__c;
            this.scheduledQuantity  = orderSchedulingLine.Scheduled_Quantity__c;
            this.balanceQuantity    = orderSchedulingLine.Balance_Quantity__c;
            this.deliveryDate       = orderSchedulingLine.Delivery_Date__c;
            this.orderId            = orderSchedulingLine.Order__c;
            this.orderProductId     = orderSchedulingLine.Order_Product__c;
            this.plantCode          = (orderSchedulingLine.Order_Product__r != null) ? orderSchedulingLine.Order_Product__r.Plant_Code__c : null;
            this.productName        = (orderSchedulingLine.Order_Product__r != null && orderSchedulingLine.Order_Product__r.Product2 != null) 
                                    ? orderSchedulingLine.Order_Product__r.Product2.Name : null;
            this.productCode        = (orderSchedulingLine.Order_Product__r != null && orderSchedulingLine.Order_Product__r.Product2 != null) 
                                    ? orderSchedulingLine.Order_Product__r.Product2.ProductCode : null;
            this.baseUOMName        = (orderSchedulingLine.Order_Product__r != null && orderSchedulingLine.Order_Product__r.Product2 != null && orderSchedulingLine.Order_Product__r.Product2.Base_UOM__r != null) 
                                    ? orderSchedulingLine.Order_Product__r.Product2.Base_UOM__r.Name : null;
            this.productDescription = (orderSchedulingLine.Order_Product__r != null && orderSchedulingLine.Order_Product__r.Product2 != null) 
                                    ? orderSchedulingLine.Order_Product__r.Product2.Description : null;
            this.salesUOM           = (orderSchedulingLine.Order_Product__r != null && orderSchedulingLine.Order_Product__r.Product2 != null) 
                                    ? orderSchedulingLine.Order_Product__r.Product2.Sales_UOM__c : null;
            this.salesUOMName       = (orderSchedulingLine.Order_Product__r != null && orderSchedulingLine.Order_Product__r.Product2 != null && orderSchedulingLine.Order_Product__r.Product2.Sales_UOM__r != null) 
                                    ? orderSchedulingLine.Order_Product__r.Product2.Sales_UOM__r.Name : null;

            for (Customer_Order_Schedule_Line_Item__c custSchedule : customerSchedules) {
                for (Customer_Order_Schedule_Line_Item__c custSchedule : customerSchedules) {
                    if (custSchedule.Order__c == this.orderId && custSchedule.Order_Product__c == this.orderProductId && custSchedule.Order_Scheduling_Line_Item__c == this.id) {
                        if (this.customerSchedules == null) {
                            this.customerSchedules = new List<CustomerOrderSchedulingLine>();
                        }
                        this.customerSchedules.add(new CustomerOrderSchedulingLine(custSchedule));
                    }
                }
            }
        }
    }

    public class CustomerOrderSchedulingLine {
        public String recordId { get; set; }
        public String name { get; set; }
        public Decimal customerScheduledQuantity { get; set; }
        public Date customerScheduledDate { get; set; }
        public Date productionRevisedDate { get; set; }
        public Date productionScheduledDate { get; set; }
        public String remarksForProductionPlanner { get; set; }
        public String orderId { get; set; }
        public String orderProductId { get; set; }
        public String orderSchedulingLineItemId { get; set; }

        public CustomerOrderSchedulingLine(Customer_Order_Schedule_Line_Item__c rec) {
            this.recordId = rec.Id;
            this.name = rec.Name;
            this.customerScheduledQuantity = rec.Customer_Scheduled_Quantity__c;
            this.customerScheduledDate = rec.Customer_Scheduled_Date__c;
            this.productionRevisedDate = rec.Production_Revised_Date__c;
            this.productionScheduledDate = rec.Production_Scheduled_Date__c;
            this.remarksForProductionPlanner = rec.Remarks_for_Production_Planner__c;
            this.orderId = rec.Order__c;
            this.orderProductId = rec.Order_Product__c;
            this.orderSchedulingLineItemId = rec.Order_Scheduling_Line_Item__c;
        }
    }


 
}