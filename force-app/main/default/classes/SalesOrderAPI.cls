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

            List<Order> exOrd = [
                SELECT Id, SAP_Order_Number__c
                FROM Order WHERE SAP_Order_Number__c = :soRequest.DOC_NUM
            ];

            Map<String, String> ohpfMap = new Map<String, String>();
            Map<String, String> ordItemMap = new Map<String, String>();
            List<Order_Header_Text__c> exOrderHeaderText = new List<Order_Header_Text__c>();
            if (exOrd.size() > 0) {
                ord.Id = exOrd[0].Id;

                exOrderHeaderText = [
                    SELECT Id, Name FROM Order_Header_Text__c
                    WHERE Order__c = :ord.Id
                ];

                List<Order_Header_Partner_Function__c> exOrderHeaderPF = new List<Order_Header_Partner_Function__c>();
                exOrderHeaderPF = [
                    SELECT Id, Partner_function__c, Partner_code__c, Order__c
                    FROM Order_Header_Partner_Function__c
                    WHERE Order__c = :exOrd[0].Id
                ];
                
                for (Order_Header_Partner_Function__c ohpf : exOrderHeaderPF) {
                    ohpfMap.put(ohpf.Partner_function__c+'-'+ohpf.Partner_code__c, ohpf.Id);
                }

                List<OrderItem> exItemList = new List<OrderItem>();
                exItemList = [
                    SELECT Id, Product2Id, Product2.ProductCode
                    FROM OrderItem WHERE OrderId = :exOrd[0].Id
                ];

                for (OrderItem ordItem : exItemList) {
                    ordItemMap.put(ordItem.Product2.ProductCode, ordItem.Id);
                }
            } else {
                if (String.isNotBlank(soRequest.QUOTE_NUM) && quoteMap.containsKey(soRequest.QUOTE_NUM)) {
                    ord.QuoteId = String.valueOf(quoteMap.get(soRequest.QUOTE_NUM));
                }
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
                    WHERE SAP_Customer_Code__c =: soRequest.CUSTOMER_NO
                ];
                if (acc.size() > 0) {

                    // List<Address_Information__c> shiptoAdd = [
                    //     SELECT Id, Name FROM Address_Information__c
                    //     WHERE Partner_SAP_Code__c = :soRequest.SHIP_TO_PARTY
                    //     AND RecordType.DeveloperName = 'Ship_To'
                    //     AND Account__c = :acc[0].Id
                    // ];
                    // List<Address_Information__c> billtoAdd = [
                    //     SELECT Id, Name FROM Address_Information__c
                    //     WHERE Partner_SAP_Code__c = :soRequest.BILL_TO_PARTY
                    //     AND RecordType.DeveloperName = 'Bill_To'
                    //     AND Account__c = :acc[0].Id
                    // ];

                    // if (shiptoAdd.size() > 0) {
                    //     ord.Ship_to_party__c = shiptoAdd[0].Id;
                    // }
                    // if (billtoAdd.size() > 0) {
                    //     ord.Bill_to_party__c = billtoAdd[0].Id;
                    // }

                    List < User > user = new List < User > ();
                    user = [
                        SELECT Id, SAP_User_Id__c
                        FROM User
                        // WHERE SAP_User_Id__c =: soRequest.SALES_EXECUTIVE
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
                        // Get Existing Payment Term
                        List<Payment_Term__c> paymentTermList = [
                            SELECT Id, Name, Payment_Term_Code__c
                            FROM Payment_Term__c
                            WHERE Payment_Term_Code__c = :soRequest.PMNTRMS
                            LIMIT 1
                        ];
                        // Get Sale District
                        List<Sales_District__c> salesDistrictList = [
                            SELECT Id, Name, Sales_District_Code__c
                            FROM Sales_District__c
                            WHERE Sales_District_Code__c = :soRequest.SALES_DISTRICT
                        ];

                        // if (String.isNotBlank(soRequest.SFDC_ID)) {
                        //     ord.Id = soRequest.SFDC_ID;
                        // }
                        ord.SAP_Order_Number__c = soRequest.DOC_NUM;
                        ord.Document_Type__c = soRequest.DOC_TYPE;
                        ord.AccountId = acc[0].Id;
                        ord.ShiptoParty__c = soRequest.SHIP_TO_PARTY;
                        ord.BilltoParty__c = soRequest.BILL_TO_PARTY;
                        if (String.isNotBlank(soRequest.ORDER_DATE)) {
                            ord.EffectiveDate = Date.valueOf(soRequest.ORDER_DATE);
                        }
                        ord.SAP_Order_Created_By__c = soRequest.CREATED_BY;
                        ord.Customer_Account_Group__c = soRequest.CUSTOMER_GROUP;
                        if (String.isNotBlank(soRequest.SALES_DISTRICT) && salesDistrictList.size() > 0) {
                            ord.Sales_District__c = salesDistrictList[0].Id;
                        }
                        ord.Country__c = soRequest.COUNTRY;
                        // ord.Sales_Executive__c = user[0].Id;
                        ord.Sales_Organisations__c = so.Id;
                        ord.Distribution_Channel__c = dc.Id;
                        ord.Division__c = div.Id;
                        ord.PoNumber = soRequest.CUST_PURC_NO;
                        if (String.isNotBlank(soRequest.PMNTRMS) && paymentTermList.size() > 0) {
                            ord.PaymentTerms__c = paymentTermList[0].Id;
                        }
                        ord.Inco_Terms__c = soRequest.INCOTERMS1;
                        ord.Inco_Remark__c = soRequest.INCOTERMS2;
                        ord.Order_Reason__c = soRequest.ORD_REASON;
                        ord.Sales_office__c = soRequest.SALES_OFF;
                        ord.Sales_Group__c = soRequest.SALES_GRP;
                        if (String.isNotBlank(soRequest.PO_DATE)) {
                            ord.PoDate = Date.valueOf(soRequest.PO_DATE);
                        }
                        ord.CurrencyIsoCode = soRequest.DOCUMENT_CURRENCY;
                        ord.Exchange_Rate__c = soRequest.EXCHG_RATE;
                        if (String.isNotBlank(soRequest.REQD_DEL_DATE)) {
                            ord.Reqd_Del_Date__c = Date.valueOf(soRequest.REQD_DEL_DATE);
                        }
                        ord.Palletization__c = soRequest.PALLET;
                        ord.DELIVERY_BLOCK__c = soRequest.DELIVERY_BLOCK;
                        ord.BILLING_BLOCK__c = soRequest.BILLING_BLOCK;
                        ord.VARIABLE_PRICE__c = soRequest.VARIABLE_PRICE;
                        ord.EffectiveDate = System.today();
                        ord.PoNumber = soRequest.CUST_PURC_NO;
                        ord.Status = 'Sale Order Created';
                        if (String.isNotBlank(soRequest.STATUS)) {
                            ord.Status__c = soRequest.STATUS;
                        } else {
                            ord.Status__c = 'Nothing rejected';
                        }
                        Pricebook2 pbk1 = [
                            SELECT IsActive, Description, IsStandard, Id, Name, SystemModstamp
                            FROM Pricebook2
                            WHERE IsActive = true
                            AND Name = 'Standard Price Book'
                        ];
                        ord.Pricebook2Id = pbk1.Id;
                        System.debug('ord ' + ord.Pricebook2Id);
                        upsert ord;

                        // ======================================================================================
                        // For Order_Header_Partner_Function__c Start
                        // ======================================================================================

                        // PartnerList

                        List < Order_Header_Text__c > orderHeaderTextList = new List < Order_Header_Text__c > ();
                        for (cls_HEADERTEXT header: soRequest.HEADERTEXT) {
                            Order_Header_Text__c orderHeaderText = new Order_Header_Text__c();
                            orderHeaderText.Order__c = ord.Id;
                            // orderHeaderText.Instruction_Type__c = header.INSTRUCTION_TYPE;
                            orderHeaderText.Instruction_Id__c = header.INSTRUCTION_TYPE;
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
                            if (exOrderHeaderText.size()>0) {
                                delete exOrderHeaderText;
                            }
                        }

                        List < Order_Header_Partner_Function__c > partnerFuncList = new List < Order_Header_Partner_Function__c > ();
                        for (cls_PARTNER_LIST partnerFunctionItem: soRequest.PARTNERLIST) {
                            Order_Header_Partner_Function__c partnerFunc = new Order_Header_Partner_Function__c();
                            if (ohpfMap.containsKey(partnerFunctionItem.PARTNER_FUNCTION+'-'+partnerFunctionItem.PARTNER_CODE)) {
                                partnerFunc.Id = ohpfMap.get(partnerFunctionItem.PARTNER_FUNCTION+'-'+partnerFunctionItem.PARTNER_CODE);
                            } else {
                                partnerFunc.Order__c = ord.Id;
                            }
                            partnerFunc.Name = partnerFunctionItem.PARTNER_FUNCTION+'-'+partnerFunctionItem.PARTNER_NAME;
                            partnerFunc.Partner_code__c = partnerFunctionItem.PARTNER_CODE;
                            partnerFunc.Partner_function__c = partnerFunctionItem.PARTNER_FUNCTION;
                            partnerFuncList.add(partnerFunc);
                        }

                        if (partnerFuncList.size() > 0) {
                            upsert partnerFuncList;
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
                            Map < String, Base_UOM_Master__c > uomCodeMap = new Map < String, Base_UOM_Master__c > ();
                            for (Base_UOM_Master__c uom: [SELECT Id, Name FROM Base_UOM_Master__c WHERE Name IN: baseUOMNames]) {
                                uomCodeMap.put(uom.Name, uom);
                            }
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

                                if (ordItemMap.containsKey(item.MATERIAL)) {
                                    orderItem.Id = ordItemMap.get(item.MATERIAL);
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
                                if (String.isNotBlank(item.PLANT)) {
                                    orderItem.Plant2__c = item.PLANT;
                                }
                                orderItem.Quantity = item.QTY;
                                orderItem.UnitPrice = item.PRICE;
                                // if (item.PRICE == 0) {
                                //     orderItem.Free_Item__c = 'Yes';
                                // } else {
                                //     orderItem.Free_Item__c = 'No';
                                // }
                                if (String.isNotBlank(item.UOM)) {
                                    orderItem.SalesUOM__c = uomCodeMap.get(item.UOM).Id;
                                }
                                orderItem.Description = item.ITM_DESC;
                                orderItem.Material_Code__c = item.MATERIAL;
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
                                        // orderDetailText.Text_Type__c = rowDetailText.TEXT_TYPE;
                                        orderDetailText.Text_Id__c = rowDetailText.TEXT_TYPE;
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
        public String DOC_NUM; //
        public String CUSTOMER_NO; //0005002762
        public String SHIP_TO_PARTY;
        public String BILL_TO_PARTY;
        public String ORDER_DATE;
        public String CREATED_BY;
        public String CUSTOMER_GROUP;
        public String SALES_DISTRICT;
        public String COUNTRY;
        public String SALES_EXECUTIVE;
        public String SALES_ORG; //1000
        public String DISTR_CHANN; //10
        public String DIVISION; //29
        public String CUST_PURC_NO; //
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
        public String PALLET;
        public String REQD_DEL_DATE; //
        public String DELIVERY_BLOCK;
        public String BILLING_BLOCK;
        public String VARIABLE_PRICE;
        public String STATUS;

        public String QUOTE_NUM;
        public String DOC_TYPE; //ZDCO
        // public String PORT_DICRG;
        // public String PORT_DEST;
        // public String PKT_TYPE;
        // public String DOC_SENT;
        // public String MESSAGE; //
        // public String USER_ID;
        // public String CREATED_ON;
        // public String MODIFY_ON;
        public String INDICATOR;
        
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