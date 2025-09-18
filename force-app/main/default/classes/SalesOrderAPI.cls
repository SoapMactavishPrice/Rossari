/*******************************************************************************************
* SalesOrderAPI.class

* Author    :   Huzaifa
* Purpose   :   For Upsert Sales Order
* Date      :   21/10/2025
--------------------------------------------------------------------------------------------
Version         Date               Author          Remarks  
V1              21/10/2025         Huzaifa
=======         ===========        ========        ======================
*******************************************************************************************/
@RestResource(urlMapping = '/SalesOrder')
global class SalesOrderAPI {

    @HttpPost
    global static void doPost() {

        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;

        String jSONRequestBody = request.requestBody.toString().trim();

        API_log__c apiLog = new API_log__c();
        apiLog.Name = 'Sales Order API';
        apiLog.Request__c = jSONRequestBody;

        if (String.isBlank(jSONRequestBody)) {
            throw new CustomException('No Sales Order data found');
        }

        SalesOrderJson soRequest = parse(jSONRequestBody);

        if (String.isBlank(soRequest.QUOTE_NUM)) {
            // throw new CustomException('QUOTE_NUM cannot be blank!');
        }

        List < Quote > quoteList = [
            SELECT Id, Name, SAP_Order_No__c FROM Quote
            // WHERE Quote_Document_No__c =: soRequest.QUOTE_NUM
            WHERE SAP_Order_No__c =: soRequest.QUOTE_NUM
        ];

        if (quoteList.isEmpty()) {
            // throw new CustomException('QUOTE_NUM :' +soRequest.QUOTE_NUM+ ' is not valid!');
        }

        Map < String, Object > quoteMap = new Map < String, Object > ();
        for (Quote q: quoteList) {
            // quoteMap.put(q.Quote_Document_No__c, q.Id);
            quoteMap.put(q.SAP_Order_No__c, q.Id);
        }

        Order ord = new Order();

        Boolean globalFlag = soRequest.SFDC_ID != '' ? true : false;

        try {

            Set < String > ProductCodeSet = new Set < String > ();

            for (cls_ITEMS item: soRequest.ITEMS) {
                ProductCodeSet.add(item.MATERIAL);
            }

            Map < String, Product2 > product2Map_v1 = new Map < String, Product2 > ();
            for (Product2 product: [SELECT Id, ProductCode FROM Product2 WHERE ProductCode IN: ProductCodeSet]) {
                product2Map_v1.put(product.ProductCode, product);
            }

            if (product2Map_v1.size() > 0) {
                List < Account > acc = new List < Account > ();
                acc = [
                    SELECT Id, Name, SAP_Customer_Code__c
                    FROM Account
                    WHERE Id IN(SELECT AccountId FROM Contact)
                    AND SAP_Customer_Code__c =: soRequest.CUSTOMER_NO
                ];
                if (acc.size() > 0) {

                    List<Address_Information__c> shiptoAdd = [
                        SELECT Id, Name FROM Address_Information__c
                        WHERE Partner_SAP_Code__c = :soRequest.SHIP_TO_PARTY
                        AND RecordType.DeveloperName = 'Ship_To'
                        AND Account__c = :acc[0].Id
                    ];
                    List<Address_Information__c> billtoAdd = [
                        SELECT Id, Name FROM Address_Information__c
                        WHERE Partner_SAP_Code__c = :soRequest.BILL_TO_PARTY
                        AND RecordType.DeveloperName = 'Bill_To'
                        AND Account__c = :acc[0].Id
                    ];

                    if (shiptoAdd.size() > 0) {
                        ord.Ship_to_party__c = shiptoAdd[0].Id;
                    }
                    if (billtoAdd.size() > 0) {
                        ord.Bill_to_party__c = billtoAdd[0].Id;
                    }

                    List < User > user = new List < User > ();
                    user = [
                        SELECT Id, SAP_User_Id__c
                        FROM User
                        WHERE SAP_User_Id__c =: soRequest.SALES_EXECUTIVE
                    ];

                    if (user.size() > 0) {

                        Sales_Organisation__c so = [
                            SELECT Id, Name
                            FROM Sales_Organisation__c
                            WHERE Name =: soRequest.SALES_ORG
                        ];
                        Distribution_Channel__c dc = [
                            SELECT Id, Distribution_Code__c
                            FROM Distribution_Channel__c
                            WHERE Distribution_Code__c =: soRequest.DISTR_CHANN
                        ];
                        Division__c div = [
                            SELECT Id, Division_Code__c
                            FROM Division__c
                            WHERE Division_Code__c =: soRequest.DIVISION
                        ];
                        // SBU__c sbu = [
                        //     SELECT Id, Distribution_Channel__c, Distribution_Code__c, Division__c, Division_Code__c,
                        //     Sales_Organizations__c, Sales_Organization_Code__c, SBU_Code__c
                        //     FROM SBU__c
                        //     WHERE Sales_Organizations__c =: so.Id
                        //     AND Distribution_Channel__c =: dc.Id
                        //     AND Division__c =: div.Id
                        // ];

                        // Map < String, Bank_Information__c > bankInfos = new Map < String, Bank_Information__c > ();
                        // for (Bank_Information__c bankInfo: [SELECT Id, Name FROM Bank_Information__c WHERE Name =: soRequest.CUST_BANK OR Name =: soRequest.PLANT_BANK]) {
                        //     bankInfos.put(bankInfo.Name, bankInfo);
                        // }

                        if (String.isNotBlank(soRequest.SFDC_ID)) {
                            ord.Id = soRequest.SFDC_ID;
                        }
                        // ord.QuoteId = String.valueOf(quoteMap.get(soRequest.QUOTE_NUM));
                        // ord.Contact_Name__c = [SELECT Id FROM Contact WHERE AccountId =: acc[0].Id AND Is_Prmary__c = true].Id;
                        ord.Sales_Organisations__c = so.Id;
                        // ord.Sales_Executive__c = user[0].Id;
                        // ord.SAP_Doc_no__c = soRequest.DOC_NUM;
                        ord.Name = soRequest.DOC_NUM;
                        ord.AccountId = acc[0].Id;
                        // ord.Order_Type__c = soRequest.SALES_DOC_TYPE;
                        ord.Distribution_Channel__c = dc.Id;
                        ord.Division__c = div.Id;
                        ord.PoNumber = soRequest.CUST_PURC_NO;
                        ord.Payment_Terms__c = soRequest.PMNTRMS;
                        ord.Inco_Terms__c = soRequest.INCOTERMS1;
                        ord.Inco_Remark__c = soRequest.INCOTERMS2;
                        ord.Order_Reason__c = soRequest.ORD_REASON;
                        ord.Sales_office__c = soRequest.SALES_OFF;
                        ord.Sales_Group__c = soRequest.SALES_GRP;
                        // ord.SBU1__c = sbu.SBU_Code__c;
                        if (String.isNotBlank(soRequest.PO_DATE)) {
                            ord.PoDate = Date.valueOf(soRequest.PO_DATE);
                        }
                        ord.CurrencyIsoCode = soRequest.DOCUMENT_CURRENCY;
                        // if (String.isNotBlank(soRequest.SALE_DATE_A)) {
                        //     ord.approval_status_by_sales__c = Date.valueOf(soRequest.SALE_DATE_A);
                        // }
                        // if (String.isNotBlank(soRequest.CRCO_DATE)) {
                        //     ord.Approval_status_by_credit_control__c = Date.valueOf(soRequest.CRCO_DATE);
                        // }
                        // if (String.isNotBlank(soRequest.APPL_DATE)) {
                        //     ord.Overall_approval_date__c = Date.valueOf(soRequest.APPL_DATE);
                        // }
                        // if (String.isNotBlank(soRequest.APPL_STA)) {
                        //     ord.Overall_Approval_Status__c = String.valueOf(soRequest.APPL_STA);
                        // }
                        ord.Exchange_Rate__c = soRequest.EXCHG_RATE;
                        if (String.isNotBlank(soRequest.REQD_DEL_DATE)) {
                            ord.Reqd_Del_Date__c = Date.valueOf(soRequest.REQD_DEL_DATE);
                        }
                        // ord.Port_of_Discharge__c = soRequest.PORT_DICRG;
                        // ord.Port_of_Destination__c = soRequest.PORT_DEST;
                        // if (String.isNotBlank(soRequest.PKT_TYPE)) {
                        //     ord.Pack_Type__c = soRequest.PKT_TYPE;
                        // }
                        // ord.Palletization__c = soRequest.PALLET == 'YES';
                        // if (String.isNotBlank(soRequest.CUST_BANK) && bankInfos.containsKey(soRequest.CUST_BANK)) {
                        //     ord.Customer_Bank_Detail__c = bankInfos.get(soRequest.CUST_BANK).Id;
                        // }
                        // if (String.isNotBlank(soRequest.PLANT_BANK) && bankInfos.containsKey(soRequest.PLANT_BANK)) {
                        //     ord.Plant_Bank_Detail__c = bankInfos.get(soRequest.PLANT_BANK).Id;
                        // }
                        // if (String.isNotBlank(soRequest.DOC_SENT)) {
                        //     ord.Document_Send__c = Decimal.valueOf(soRequest.DOC_SENT);
                        // }
                        ord.EffectiveDate = System.today();
                        ord.PoNumber = soRequest.CUST_PURC_NO;
                        ord.Status = 'Sale Order Created';
                        Pricebook2 pbk1 = [
                            SELECT IsActive, Description, IsStandard, Id, Name, SystemModstamp
                            FROM Pricebook2
                            WHERE IsActive = true
                            AND Name = 'Standard Price Book'
                        ];
                        ord.Pricebook2Id = pbk1.Id;
                        System.debug('ord ' + ord.Pricebook2Id);
                        upsert ord;

                        // ord.Delivery_Status__c = soRequest.DEL_STATUS;
                        // ord.Overall_Status__c = soRequest.OVER_STATUS;
                        // ord.Overall_delivery_status__c = soRequest.O_DEL_STAS;
                        // ord.Credit_Status_v1__c = soRequest.CR_STATUS;
                        // ord.User_Status__c = soRequest.USER_STATUS;

                        //update order status 
                        // if (soRequest.DEL_STATUS == 'Not delivered') {
                        //     if (soRequest.OVER_STATUS == 'Completed' && soRequest.O_DEL_STAS == 'Completed') {
                        //         ord.Status = 'Dispatched_Cancelled';
                        //     }
                        //     if (soRequest.OVER_STATUS == 'Being processed') {
                        //         if ((soRequest.CR_STATUS == 'Released' || soRequest.CR_STATUS == 'Approved') && soRequest.USER_STATUS == '0002') {
                        //             ord.Status = 'Credit Check passed';

                        //         }
                        //         if ((soRequest.CR_STATUS == 'Not approved' || soRequest.CR_STATUS == 'Not performed') && soRequest.USER_STATUS == '0002') {
                        //             ord.Status = 'Sales Head Approved';
                        //             // ord.Level_1__c = true;
                        //             // ord.Level_2__c = true;
                        //             // ord.Level_3__c = false;
                        //             // ord.Approval_Status__c = 'Submitted';
                        //         }
                        //         if ((soRequest.CR_STATUS == 'Not approved' || soRequest.CR_STATUS == 'Not performed') && soRequest.USER_STATUS == '0001') {
                        //             // ord.Status = 'Sale Order Created';
                        //             // ord.Level_2__c = false;
                        //             // ord.Level_3__c = false;
                        //             // ord.Credit_Status__c = '';
                        //         }
                        //         if ((soRequest.CR_STATUS == 'Released' || soRequest.CR_STATUS == 'Approved') && soRequest.USER_STATUS == '0001') {
                        //             ord.Status = 'Sale Order Created';
                        //             // ord.Level_2__c = false;
                        //             // ord.Level_3__c = false;
                        //             // ord.Credit_Status__c = '';
                        //         }
                        //     }
                        // }
                        // if (soRequest.DEL_STATUS == 'Fully delivered') {
                        //     ord.Status = 'Dispatched';
                        // }
                        // if (soRequest.DEL_STATUS == 'Partially delivered') {
                        //     if (soRequest.OVER_STATUS == 'Completed' && soRequest.O_DEL_STAS == 'Completed') {
                        //         ord.Status = 'Dispatched';
                        //     }
                        //     if (soRequest.OVER_STATUS == 'Being processed') {
                        //         ord.Status = 'Partially Dispatched';
                        //     }
                        // }
                        // if (soRequest.DEL_STATUS == '' && soRequest.OVER_STATUS == 'Completed') {
                        //     ord.Status = 'Completed';
                        // }
                        // if ((soRequest.OVER_STATUS == '' || soRequest.OVER_STATUS == 'Open') && (soRequest.CR_STATUS == 'Not approved' || soRequest.CR_STATUS == 'Not performed') && soRequest.USER_STATUS == '0002') {
                        //     ord.Status = 'Sales Head Approved';
                        //     // ord.Level_1__c = true;
                        //     // ord.Level_2__c = true;
                        //     // ord.Level_3__c = false;
                        //     // ord.Approval_Status__c = 'Submitted';
                        // }
                        // if ((soRequest.OVER_STATUS == '' || soRequest.OVER_STATUS == 'Open') && (soRequest.CR_STATUS == 'Not approved' || soRequest.CR_STATUS == 'Not performed') && soRequest.USER_STATUS == '0001') {
                        //     ord.Status = 'Sale Order Created';
                        //     // ord.Level_2__c = false;
                        //     // ord.Level_3__c = false;
                        //     // ord.Credit_Status__c = '';
                        // }
                        // if ((soRequest.OVER_STATUS == '' || soRequest.OVER_STATUS == 'Open') && (soRequest.CR_STATUS == 'Released' || soRequest.CR_STATUS == 'Approved') && soRequest.USER_STATUS == '0001') {
                        //     ord.Status = 'Sale Order Created';
                        //     // ord.Level_2__c = false;
                        //     // ord.Level_3__c = false;
                        //     // ord.Credit_Status__c = '';
                        // }
                        if (String.isNotBlank(soRequest.ORDER_DATE)) {
                            ord.EffectiveDate = Date.valueOf(soRequest.ORDER_DATE);
                        }
                        // ord.Customer_Account_Group__c = soRequest.CUSTOMER_GROUP;
                        // ord.Sales_District__c = soRequest.SALES_DISTRICT;
                        // ord.Country__c = soRequest.COUNTRY;
                        // ord.SAP_Order_Created_By__c = soRequest.CREATED_BY;

                        // if (String.isNotBlank(soRequest.BILLING_BLOCK) || String.isNotBlank(soRequest.DELIVERY_BLOCK)) {
                        // ord.Status = 'Order on Hold';
                        // ord.Order_Clearance_Date__c = System.today();
                        // ord.Level_1__c = false;
                        // ord.Level_2__c = false;
                        // ord.Level_3__c = false;
                        // ord.Credit_Status__c = '';
                        // ord.Approval_Status__c = null;

                        // ---------- Need to check below condition ---------------
                        // if (String.isNotBlank(ord.Id)) {
                        //     List < ProcessInstanceWorkitem > pval = [
                        //         SELECT Id FROM ProcessInstanceWorkItem
                        //         WHERE ProcessInstance.TargetObjectId =: ord.Id
                        //         AND ProcessInstance.Status = 'Pending'
                        //     ];
                        //     if (pval.size() > 0) {
                        //         Approval.ProcessWorkItemRequest Preq = new Approval.ProcessWorkItemRequest();
                        //         Preq.setAction('Reject');
                        //         Preq.setWorkItemId(Pval[0].Id);
                        //         Approval.ProcessResult result = Approval.process(Preq);
                        //     }
                        // }
                        // }

                        // ======================================================================================
                        // For Order_Header_Partner_Function__c Start
                        // ======================================================================================

                        // PartnerList
                        if (!globalFlag) {

                            List < Order_Header_Text__c > orderHeaderTextList = new List < Order_Header_Text__c > ();
                            for (cls_HEADERTEXT header: soRequest.HEADERTEXT) {
                                Order_Header_Text__c orderHeaderText = new Order_Header_Text__c();
                                orderHeaderText.Order__c = ord.Id;
                                orderHeaderText.Instruction_Type__c = header.INSTRUCTION_TYPE;
                                orderHeaderText.Instruction_Description__c = header.INSTRUCTION_DESCRIPTION;
                                orderHeaderTextList.add(orderHeaderText);
                                // if (mpHeadertext.get(header.TEXT_ID) != null) {
                                //     orderHeaderText.Id = mpHeadertext.get(header.TEXT_ID);
                                // }
                                // orderHeaderText.Order__c = ord.Id;
                                // orderHeaderText.Text_ID__c = header.TEXT_ID;
                                // orderHeaderText.Text_Description__c = header.TEXT_LINE;
                                // orderHeaderTextList.add(orderHeaderText);
                                // if (header.TEXT_ID == 'Z005') {
                                //     ord.Internal_Remarks__c = header.TEXT_LINE;
                                // }
                            }

                            if (orderHeaderTextList.size() > 0) {
                                upsert orderHeaderTextList;
                            }

                            List < Order_Header_Partner_Function__c > partnerFuncList = new List < Order_Header_Partner_Function__c > ();
                            for (cls_PARTNER_LIST partnerFunctionItem: soRequest.PARTNERLIST) {
                                Order_Header_Partner_Function__c partnerFunc = new Order_Header_Partner_Function__c();
                                partnerFunc.Order__c = ord.Id;
                                partnerFunc.Name = partnerFunctionItem.PARTNER_NAME;
                                partnerFunc.Partner_code__c = partnerFunctionItem.PARTNER_CODE;
                                partnerFunc.Partner_function__c = partnerFunctionItem.PARTNER_FUNCTION;
                                partnerFuncList.add(partnerFunc);
                            }

                            if (partnerFuncList.size() > 0) {
                                upsert partnerFuncList;
                            }
                        }

                        // Map < String, Order_Header_Partner_Function__c > partnerFunctionMap = new Map < String, Order_Header_Partner_Function__c > ();
                        // for (Order_Header_Partner_Function__c partnerFunc: partnerFuncList) {
                        //     partnerFunctionMap.put(partnerFunc.Partner_function__c, partnerFunc);
                        // }

                        // Set < String > sapCustomerCodes = new Set < String > ();
                        // if (partnerFunctionMap.containsKey('Bill-to party')) {
                        //     sapCustomerCodes.add(partnerFunctionMap.get('Bill-to party').Partner_code__c);
                        // }
                        // if (partnerFunctionMap.containsKey('Ship-to party')) {
                        //     sapCustomerCodes.add(partnerFunctionMap.get('Ship-to party').Partner_code__c);
                        // }

                        // Map < String, Account > sapCodeWiseAccounts = new Map < String, Account > ();
                        // for (Account accnt: [SELECT Id, SAP_Customer_Code__c, BillingAddress, ShippingAddress, Street__c, City__c, Postal_Code__c, Country__c FROM Account WHERE SAP_Customer_Code__c IN: sapCustomerCodes]) {
                        //     sapCodeWiseAccounts.put(accnt.SAP_Customer_Code__c, accnt);
                        // }

                        // if (partnerFunctionMap.containsKey('Bill-to party')) {
                        //     if (sapCodeWiseAccounts.containsKey(partnerFunctionMap.get('Bill-to party').Partner_code__c)) {
                        //         Account billtoPartyAcc = sapCodeWiseAccounts.get(partnerFunctionMap.get('Bill-to party').Partner_code__c);
                        //         ord.Bill_to_Party_Account__c = billtoPartyAcc.Id;
                        //         String address = '';
                        //         address += String.isBlank(billtoPartyAcc.Street__c) ? '' : billtoPartyAcc.Street__c + '\n';
                        //         address += String.isBlank(billtoPartyAcc.City__c) ? '' : billtoPartyAcc.City__c + '\n';
                        //         address += String.isBlank(billtoPartyAcc.Postal_Code__c) ? '' : billtoPartyAcc.Postal_Code__c + '\n';
                        //         if (!String.isBlank(billtoPartyAcc.Country__c)) {
                        //             address += UtilityCls.getCountryName(billtoPartyAcc.Country__c);
                        //         }
                        //         ord.Bill_to_Party_Address__c = address;
                        //     }
                        // }
                        // if (partnerFunctionMap.containsKey('Ship-to party')) {
                        //     if (sapCodeWiseAccounts.containsKey(partnerFunctionMap.get('Ship-to party').Partner_code__c)) {
                        //         Account shipToPartyAcc = sapCodeWiseAccounts.get(partnerFunctionMap.get('Ship-to party').Partner_code__c);
                        //         ord.Ship_to_Party_Account__c = shipToPartyAcc.Id;
                        //         String address = '';
                        //         address += String.isBlank(shipToPartyAcc.Street__c) ? '' : shipToPartyAcc.Street__c + '\n';
                        //         address += String.isBlank(shipToPartyAcc.City__c) ? '' : shipToPartyAcc.City__c + '\n';
                        //         address += String.isBlank(shipToPartyAcc.Postal_Code__c) ? '' : shipToPartyAcc.Postal_Code__c + '\n';
                        //         if (!String.isBlank(shipToPartyAcc.Country__c)) {
                        //             address += UtilityCls.getCountryName(shipToPartyAcc.Country__c);
                        //         }

                        //         ord.Ship_To_Party_Address__c = address;
                        //     }
                        // }

                        // ======================================================================================
                        // For Order_Header_Partner_Function__c END
                        // ======================================================================================

                        soRequest.SFDC_ID = ord.Id;

                        Set < String > productCodes = new Set < String > ();
                        Set < String > plantNames = new Set < String > ();
                        Set < String > baseUOMNames = new Set < String > ();
                        for (cls_ITEMS item: soRequest.ITEMS) {
                            productCodes.add(item.MATERIAL);
                            plantNames.add(item.PLANT);
                            plantNames.add(item.SHIP_POINT);
                            baseUOMNames.add(item.UOM);
                        }

                        Map < String, Product2 > product2Map = new Map < String, Product2 > ();
                        for (Product2 product: [SELECT Id, ProductCode FROM Product2 WHERE ProductCode IN: productCodes]) {
                            product2Map.put(product.ProductCode, product);
                        }

                        if (product2Map.size() > 0) {
                            // Map < String, Plant_Code__c > plantCodeMap = new Map < String, Plant_Code__c > ();
                            // for (Plant_Code__c plant: [SELECT Id, Name FROM Plant_Code__c WHERE Name IN: plantNames]) {
                            //     plantCodeMap.put(plant.Name, plant);
                            // }
                            // Map < String, Base_UOM_Master__c > uomCodeMap = new Map < String, Base_UOM_Master__c > ();
                            // for (Base_UOM_Master__c uom: [SELECT Id, Name FROM Base_UOM_Master__c WHERE Name IN: baseUOMNames]) {
                            //     uomCodeMap.put(uom.Name, uom);
                            // }
                            Map < String, PricebookEntry > pricebookEntryMap = new Map < String, PricebookEntry > ();
                            for (PricebookEntry entry: [
                                SELECT Id, Product2Id, Product2.ProductCode, CurrencyIsoCode 
                                FROM PricebookEntry 
                                WHERE Pricebook2Id = :ord.Pricebook2Id 
                                AND Product2.ProductCode IN :productCodes
                                AND CurrencyIsoCode = :ord.CurrencyIsoCode
                            ]) {
                                pricebookEntryMap.put(entry.Product2.ProductCode, entry);
                            }
                            Map < String, OrderItem > mpOrderLineItemList = new Map < String, OrderItem > ();
                            List < OrderItem > orderItemList = new List < OrderItem > ();

                            for (cls_ITEMS item: soRequest.ITEMS) {
                                OrderItem orderItem = new OrderItem();

                                if (String.isNotBlank(item.SFDC_LINE_ITEM_ID)) {
                                    orderItem.Id = item.SFDC_LINE_ITEM_ID;
                                } else {
                                    if (!pricebookEntryMap.containsKey(item.MATERIAL)) {
                                        apiLog.Response__c = 'No pricebook entry found for product ' + item.MATERIAL + ' with currency ' + ord.CurrencyIsoCode;
                                        apiLog.Status__c = 'Failed';
                                        continue;
                                    }
                                    orderItem.OrderId = ord.Id;
                                    orderItem.Product2Id = product2Map.get(item.MATERIAL).Id;
                                    orderItem.PricebookEntryId = pricebookEntryMap.get(item.MATERIAL).Id;
                                    // Currency is automatically set from the PricebookEntry
                                    // orderItem.Material_Group_1_Temp__c = product2Map.get(item.MATERIAL).Material_Group_1__c;
                                }
                                if (String.isNotBlank(item.ITEM_NUM)) {
                                    orderItem.SAP_Line_No__c = item.ITEM_NUM;
                                }
                                // if (String.isNotBlank(item.PLANT)) {
                                //     orderItem.Plant_Code__c = plantCodeMap.get(item.PLANT).Id;
                                // }
                                orderItem.Quantity = item.QTY;
                                orderItem.UnitPrice = item.PRICE;
                                // if (item.PRICE == 0) {
                                //     orderItem.Free_Item__c = 'Yes';
                                // } else {
                                //     orderItem.Free_Item__c = 'No';
                                // }
                                // if (String.isNotBlank(item.UOM)) {
                                //     orderItem.Sales_UOM__c = uomCodeMap.get(item.UOM).Id;
                                // }
                                orderItem.Description = item.ITM_DESC;
                                // orderItem.Display_Name__c = item.ITM_DESC;
                                // orderItem.Item_Category__c = item.ITEM_CATEG;
                                // orderItem.Order_Item_Category__c = item.ITEM_CATEG;

                                // if (String.isNotBlank(item.CUST_ETD)) {
                                //     orderItem.Cust_ETA__c = Date.valueOf(item.CUST_ETD);
                                // }

                                // orderItem.Material_Freight_Group__c = item.MAT_FRT_GRP;
                                // orderItem.Over_Delivery_Tolerance__c = item.OVER_DEL_TOL;
                                // orderItem.Under_Delivery_Tolerance__c = item.UNDER_DEL_TOL;
                                // orderItem.Gross_Wt__c = item.GROSS_WT;
                                // orderItem.Net_Wt__c = item.NET_WT;
                                // orderItem.Reason_for_Rejection__c = item.REASON_REJ;

                                //Added Field
                                // orderItem.Customer_Material_Number__c = item.CUSTOMER_MATERIAL_NUMBER;
                                // orderItem.Route_Label_Name__c = item.ROUTE_LABEL_NAME;
                                if (String.isNotBlank(item.FIRST_DATE)) {
                                    orderItem.First_Date__c = Date.valueOf(item.FIRST_DATE);
                                }
                                // orderItem.SAP_NET_VALUE__c = item.NET_VALUE;

                                mpOrderLineItemList.put(String.valueOf(ord.Id + '' + orderItem.SAP_Line_No__c), orderItem);
                                orderItemList.add(orderItem);
                            }

                            if (mpOrderLineItemList.values().size() > 0) {
                                upsert mpOrderLineItemList.values();
                                // List<cls_ITEMS> newItemList=new List<cls_ITEMS>();
                                for (cls_ITEMS item: soRequest.ITEMS) {
                                    if (mpOrderLineItemList.get(ord.Id + '' + item.ITEM_NUM) != null) {
                                        if (String.isBlank(item.SFDC_LINE_ITEM_ID)) {
                                            item.SFDC_LINE_ITEM_ID = mpOrderLineItemList.get(ord.Id + '' + item.ITEM_NUM).Id;
                                        }

                                    }
                                }
                            }

                            if (!globalFlag) {
                                List < Order_Scheduling_Line_Item_wise__c > orderSchedulingLineItemWiseList = new List < Order_Scheduling_Line_Item_wise__c > ();
                                List < Order_Detail_Text__c > orderdetailTextList = new List < Order_Detail_Text__c > ();
                                for (cls_ITEMS item: soRequest.ITEMS) {
                                    for (cls_SCHED_LINES orderSched: item.SCHED_LINES) {
                                        Order_Scheduling_Line_Item_wise__c ordSch = new Order_Scheduling_Line_Item_wise__c();
                                        ordSch.Order__c = ord.Id;
                                        ordSch.Order_Product__c = mpOrderLineItemList.get(ord.Id + '' + item.ITEM_NUM).Id;
                                        ordSch.Order_Quantity__c = orderSched.ORD_QTY;
                                        ordSch.Confirmed_Quantity__c = orderSched.CONF_QTY;
                                        ordSch.Delivery_Date__c = Date.valueOf(orderSched.DELIVERY_DATE);
                                        orderSchedulingLineItemWiseList.add(ordSch);
                                    }
    
                                    for (cls_ITEM_TEXT rowDetailText: item.ITEM_TEXT) {
                                        Order_Detail_Text__c orderDetailText = new Order_Detail_Text__c();
                                        orderDetailText.Order__c = ord.Id;
                                        orderDetailText.Order_Product__c = mpOrderLineItemList.get(ord.Id + '' + item.ITEM_NUM).Id;
                                        orderDetailText.Text_Type__c = rowDetailText.TEXT_TYPE;
                                        orderDetailText.Text_Description__c = rowDetailText.TEXT_DESCRIPTION;
                                        orderDetailText.Document_upload__c = rowDetailText.DOC_UPLOAD;
                                        // orderDetailText.Unique__c = mpOrderLineItemList.get(ord.Id + '' + item.ITEM_NUM).Id + '-' + rowDetailText.TEXT_ID;
                                        orderdetailTextList.add(orderDetailText);
                                    }
                                }
    
                                if (orderdetailTextList.size() > 0) {
                                    // upsert orderdetailTextList Unique__c;
                                    upsert orderdetailTextList;
                                }
                                if (orderSchedulingLineItemWiseList.size() > 0) {
                                    upsert orderSchedulingLineItemWiseList;
                                }
                                
                            }

                            //     upsert ord;

                            //Partner Function
                            apiLog.Response__c = JSON.serialize(soRequest);
                            apiLog.Status__c = 'Success';

                            Map < String, Object > responseMap = new Map < String, Object > ();
                            responseMap.put('status', 'success');
                            responseMap.put('message', 'Created Successfully');
                            response.responseBody = Blob.valueOf(JSON.serialize(soRequest));
                            response.statusCode = 200;
                        } else {

                            apiLog.Response__c = 'Material ' + ProductCodeSet + ' is not present ';
                            apiLog.Status__c = 'Failed';

                            Map < String, Object > responseMap = new Map < String, Object > ();
                            responseMap.put('status', 'fail');
                            responseMap.put('message', apiLog.Response__c);
                            // response.responseBody = Blob.valueOf(JSON.serialize(soRequest));
                            response.responseBody = Blob.valueOf(JSON.serialize(responseMap));
                            response.statusCode = 400;
                        }

                    } else {

                        apiLog.Response__c = 'Executive ' + soRequest.SALES_EXECUTIVE + ' is not present ';
                        apiLog.Status__c = 'Failed';

                        Map < String, Object > responseMap = new Map < String, Object > ();
                        responseMap.put('status', 'fail');
                        responseMap.put('message', apiLog.Response__c);
                        // response.responseBody = Blob.valueOf(JSON.serialize(soRequest));
                        response.responseBody = Blob.valueOf(JSON.serialize(responseMap));
                        response.statusCode = 400;

                    }

                } else {
                    
                    apiLog.Response__c = 'Customer Number ' + soRequest.CUSTOMER_NO + ' is not present ';
                    apiLog.Status__c = 'Failed';

                    Map < String, Object > responseMap = new Map < String, Object > ();
                    responseMap.put('status', 'fail');
                    responseMap.put('message', apiLog.Response__c);
                    // response.responseBody = Blob.valueOf(JSON.serialize(soRequest));
                    response.responseBody = Blob.valueOf(JSON.serialize(responseMap));
                    response.statusCode = 400;

                }

            } else {

                apiLog.Response__c = 'Material ' + ProductCodeSet + ' is not present ';
                apiLog.Status__c = 'Failed';

                Map < String, Object > responseMap = new Map < String, Object > ();
                responseMap.put('status', 'fail');
                responseMap.put('message', apiLog.Response__c);
                // response.responseBody = Blob.valueOf(JSON.serialize(soRequest));
                response.responseBody = Blob.valueOf(JSON.serialize(responseMap));
                response.statusCode = 400;
            }

        } catch (Exception e) {

            apiLog.Exception_Description__c = e.getMessage() + ' : ' + e.getCause() + ' : ' + e.getStackTraceString();
            apiLog.Status__c = 'Failed';
            response.statusCode = 500;
            response.responseBody = Blob.valueOf('{"ERR_MSG":"' + apiLog.Exception_Description__c + '","Status":"Failed"}');

        } finally {

            insert apiLog;
        }

    }

    // Parsing the JSON requested data
    public static SalesOrderJson parse(String json) {
        return (SalesOrderJson) System.JSON.deserialize(json, SalesOrderJson.class);
    }

    public class SalesOrderJson {
        public String SFDC_ID; //
        public String SALES_EXECUTIVE;
        public String QUOTE_NUM;
        public String DOC_NUM; //
        public String CUSTOMER_NO; //0005002762
        public String SALES_ORG; //1000
        // public String SALES_DOC_TYPE; //ZDCO
        public String DISTR_CHANN; //10
        public String DIVISION; //29
        public String CUST_PURC_NO; //.
        public String PMNTRMS; //
        public String INCOTERMS1; //
        public String INCOTERMS2; //
        public String ORD_REASON; //
        public String SALES_OFF; //
        public String SALES_GRP; //
        public String VALID_FROM; //
        public String VALID_TO; //
        public String PO_DATE; //
        public String DOCUMENT_CURRENCY; //
        public Decimal EXCHG_RATE;
        public String REQD_DEL_DATE; //
        // public String PORT_DICRG;
        // public String PORT_DEST;
        // public String PKT_TYPE;
        public String PALLET;
        // public String DOC_SENT;
        // public String MESSAGE; //
        // public String USER_ID;
        // public String CREATED_ON;
        // public String MODIFY_ON;
        public String INDICATOR;
        public String BILLING_BLOCK;
        public String DELIVERY_BLOCK;
        public String SHIP_TO_PARTY;
        public String ORDER_DATE;
        public String CUSTOMER_GROUP;
        public String SALES_DISTRICT;
        public String COUNTRY;
        public String BILL_TO_PARTY;
        public String CREATED_BY;
        // public String OVER_STATUS;
        // public String REJ_STATUS;
        // public String DEL_STATUS;
        // public String O_DEL_STAS;
        // public String CR_STATUS;
        // public String O_BLKD_STAS;
        // public String USER_STATUS;
        // public string SALE_DATE_A;
        // public string CRCO_DATE;
        // public string APPL_DATE;
        // public string APPL_STA;
        public List < cls_ITEMS > ITEMS;
        public List < cls_HEADERTEXT > HEADERTEXT;
        public List < cls_PARTNER_LIST > PARTNERLIST;
    }

    public class cls_ITEMS {
        // public String CUST_ETD;
        public String SFDC_LINE_ITEM_ID;
        // public String FREE_ITEM;
        public String DOC_NUM; //
        public String ITEM_NUM; //10
        // public Decimal NET_VALUE; //10
        public String MATERIAL; //000000000400012317
        public String PLANT; //9002
        public Decimal QTY; //36
        public String UOM; //KG
        public String CUST_PURC_NO; //.
        public Decimal PRICE; //0
        // public String UNLMT_TOL; //0
        public String SHIP_POINT; //0
        public String ROUTE; //0
        // public String MAT_FRT_GRP; //0
        // public Decimal OVER_DEL_TOL; //0
        // public Decimal UNDER_DEL_TOL; //0
        // public Decimal GROSS_WT; //0
        // public Decimal NET_WT; //0
        // public String REASON_REJ; //0
        public String ITM_DESC; //0
        // public String ITEM_CATEG; //0
        public String PRICE_LIST; //0
        public String SALES_UOM; //0
        // public String CUSTOMER_MATERIAL_NUMBER; //0
        public String ROUTE_LABEL_NAME; //0
        // public String SCHEDULE_DATE;
        public String FIRST_DATE;
        public List<cls_ITEM_TEXT> ITEM_TEXT;
        public List<cls_SCHED_LINES> SCHED_LINES;
    }

    public class cls_HEADERTEXT {
        public String INSTRUCTION_TYPE;
        public String INSTRUCTION_DESCRIPTION;
    }

    public class cls_PARTNER_LIST {
        public String PARTNER_FUNCTION;
        public String PARTNER_CODE;
        public String PARTNER_NAME; //0013000321
    }

    public class cls_SCHED_LINES {
        public String SF_SchduleLineId;
        public String SFDC_LINE_ITEM_ID;
        public String ITEM_NO;
        public String DELIVERY_DATE;
        public Decimal ORD_QTY; //0013000321
        public Decimal confirm_QTY; //0013000321
        public Decimal CONF_QTY;
    }

    public class cls_ITEM_TEXT {
        public String TEXT_TYPE;
        public String DOC_UPLOAD;
        public String TEXT_DESCRIPTION; //0013000321
    }

    

}