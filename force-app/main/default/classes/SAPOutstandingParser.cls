public with sharing class SAPOutstandingParser {
    public static List < Outstanding__c > parseAndCreate(String xmlResponse, String accId, String compId) {
        List < Outstanding__c > recordsToInsert = new List < Outstanding__c > ();

        Dom.Document doc = new Dom.Document();
        doc.load(xmlResponse);

        // Root Node: <DynamicCellSet>
        Dom.XmlNode root = doc.getRootElement();

        Set < String > salesOrgSet = new Set < String > ();
        Set < String > distChSet = new Set < String > ();
        Set < String > profitCenterSet = new Set < String > ();
        Set < String > materialSet = new Set < String > ();
        for (Dom.XmlNode cell: root.getChildElements()) {
            if (getValue(cell, 'SalesOrg') != '') {
                salesOrgSet.add(getValue(cell, 'SalesOrg'));
            }
            if (getValue(cell, 'DistributionChannel') != '') {
                distChSet.add(getValue(cell, 'DistributionChannel'));
            }
            if (getValue(cell, 'ProfitCenter') != '') {
                profitCenterSet.add(getValue(cell, 'ProfitCenter'));
            }
            if (getValue(cell, 'Material') != '') {
                materialSet.add(getValue(cell, 'Material'));
            }
        }

        List < Sales_Organisation__c > salesOrgList = [SELECT Id, Name FROM Sales_Organisation__c WHERE Name IN: salesOrgSet];
        Map < String, Sales_Organisation__c > salesOrgMap = new Map < String, Sales_Organisation__c > ();
        for (Sales_Organisation__c so: salesOrgList) {
            salesOrgMap.put(so.Name, so);
        }

        List < Distribution_Channel__c > distChList = [SELECT Id, Distribution_Code__c FROM Distribution_Channel__c WHERE Distribution_Code__c IN: distChSet];
        Map < String, Distribution_Channel__c > distChMap = new Map < String, Distribution_Channel__c > ();
        for (Distribution_Channel__c dc: distChList) {
            distChMap.put(dc.Distribution_Code__c, dc);
        }

        List < Profit_Center__c > profitCenterList = [SELECT Id, Name FROM Profit_Center__c WHERE Name IN: profitCenterSet];
        Map < String, Profit_Center__c > profitCenterDesMap = new Map < String, Profit_Center__c > ();
        for (Profit_Center__c pcd: profitCenterList) {
            profitCenterDesMap.put(pcd.Name, pcd);
        }

        List < Product2 > materialList = [SELECT Id, ProductCode FROM Product2 WHERE ProductCode IN: materialSet];
        Map < String, Product2 > materialMap = new Map < String, Product2 > ();
        for (Product2 p: materialList) {
            materialMap.put(p.ProductCode, p);
        }

        // Loop through each <DynamicCell>
        for (Dom.XmlNode cell: root.getChildElements()) {
            Outstanding__c rec = new Outstanding__c();

            // Example mappings (expand as needed)
            rec.County_Code__c = getValue(cell, 'CountyCode');
            rec.Customer_Code__c = getValue(cell, 'CustomerCode');
            rec.City_Code__c = getValue(cell, 'CityCode');
            // rec.Customer__c          = getValue(cell,'Customer');
            rec.Customer_Name__c = accId;
            //rec.Customer_Name__c = null;
            rec.City_Des__c = getValue(cell, 'CityDes');
            if (salesOrgMap.containsKey(getValue(cell, 'SalesOrg'))) {
                rec.Sales_Org__c = salesOrgMap.get(getValue(cell, 'SalesOrg')).Id;
            }
            rec.CurrencyIsoCode = getValue(cell, 'Currency');
            rec.Sales_District__c = getValue(cell, 'SalesDistrict');
            rec.Sales_District_Text__c = getValue(cell, 'SalesDistrictText');
            rec.Sales_Group_Des__c = getValue(cell, 'SalesGroupDes');
            rec.Sales_Group__c = getValue(cell, 'SalesGroup');
            rec.Reference__c = getValue(cell, 'Reference');
            rec.ProfitCentreDes__c = getValue(cell, 'ProfitCentreDes');
            rec.Recon_Account__c = getValue(cell, 'ReconAccount');
            rec.Document_Number__c = getValue(cell, 'DocumentNumber');
            rec.Document_Type__c = getValue(cell, 'DocumentType');
            rec.GI_Account__c = getValue(cell, 'GlAccount');
            rec.Original_Doc__c = getValue(cell, 'OriginalDoc');
            rec.Line_Item__c = getValue(cell, 'LineItem');
            if (profitCenterDesMap.containsKey(getValue(cell, 'ProfitCenter'))) {
                rec.Profit_Center_Des__c = profitCenterDesMap.get(getValue(cell, 'ProfitCenter')).Id;
            }
            rec.Dist_Channel_Des__c = getValue(cell, 'DistChannelDes');
            rec.Material_Text__c = getValue(cell, 'MaterialText');
            rec.Gl_Account_Des__c = getValue(cell, 'GlAccountDes');
            rec.Sal_Dis_Des__c = getValue(cell, 'SalDisDes');
            rec.Customer_Group__c = getValue(cell, 'CustomerGroup');
            rec.Customer_Group_Des__c = getValue(cell, 'CustomerGroupDes');
            rec.City__c = getValue(cell, 'City');
            rec.Division_Des__c = getValue(cell, 'DivisionDes');
            rec.Sales_Office_Des__c = getValue(cell, 'SalesOfficeDes');
            rec.Text__c = getValue(cell, 'Text');
            rec.Region__c = getValue(cell, 'Region');
            rec.Country__c = getValue(cell, 'Country');
            rec.Row__c = getValue(cell, 'Row;');
            rec.District__c = getValue(cell, 'District');
            rec.Not_Overdue_Bucket_7__c = getValue(cell, 'NotOverdueBucket7');
            rec.Segment__c = getValue(cell, 'Segment');
            rec.Credit_Control_Area__c = getValue(cell, 'CreditControlArea');
            rec.Special_GL__c = getValue(cell, 'SpecialGL');
            rec.Overdue_Bucket_3__c = getValue(cell, 'OverdueBucket3');
            rec.Overdue_Bucket_2__c = getValue(cell, 'OverdueBucket2');
            rec.Overdue_Bucket_5__c = getValue(cell, 'OverdueBucket5');
            rec.Overdue_Bucket_4__c = getValue(cell, 'OverdueBucket4');
            rec.Overdue_Bucket_7__c = getValue(cell, 'OverdueBucket7');
            rec.Overdue_Bucket_6__c = getValue(cell, 'OverdueBucket6');
            rec.Overdue_Bucket_8__c = getValue(cell, 'OverdueBucket8');
            rec.Overdue_Bucket_1__c = getValue(cell, 'OverdueBucket1');
            rec.Payment_Term_Des__c = getValue(cell, 'PaymentTerms');
            rec.Sales_Office__c = getValue(cell, 'SalesOfficee');
            rec.Segment_Des__c = getValue(cell, 'SegmentsDes');
            rec.Not_Overdue_Bucket_5__c = getValue(cell, 'NotOverdueBucket5');
            rec.Not_Overdue_Bucket_6__c = getValue(cell, 'NotOverdueBucket6');
            rec.Not_Overdue_Bucket_3__c = getValue(cell, 'NotOverdueBucket3');
            rec.Sales_Org_Des__c = getValue(cell, 'SalesOrgsDes');
            rec.Not_Overdue_Bucket_4__c = getValue(cell, 'NotOverdueBucket4');
            rec.Not_Overdue_Bucket_1__c = getValue(cell, 'NotOverdueBucket1');
            rec.Not_Overdue_Bucket_2__c = getValue(cell, 'NotOverdueBucket2');

            // rec.Fiscal_Year__c = getValue(cell, 'FiscalYear');
            // rec.Fiscal_Year__c = null;
            if (distChMap.containsKey(getValue(cell, 'DistributionChannel'))) {
                rec.Distribution_Channel__c = distChMap.get(getValue(cell, 'DistributionChannel')).Id;
            }
            rec.Company_Code__c = compId;
            // rec.Company_Code__c = null;
            rec.Name_1_Text__c = getValue(cell, 'Name1Text');
            // rec.Material__c = getValue(cell, 'Material');
            // rec.Material__c = null;
            if (materialMap.containsKey(getValue(cell, 'Material'))) {
                rec.Material__c = materialMap.get(getValue(cell, 'Material')).Id;
            }
            
            // rec.Payment_Term__c = getValue(cell, 'PaymentTerm');
            // rec.Payment_Term__c = null;
            // rec.Division__c = getValue(cell, 'Division');
            //rec.Division__c = null;

            // Numeric fields
            rec.Total_Not_Overdue__c = toDecimal(getValue(cell, 'TotalNotOverdue'), 0);
            rec.Total_Overdue__c = toDecimal(getValue(cell, 'TotalOverdue'), 0);
            rec.DP_Amount__c = toDecimal(getValue(cell, 'DpAmount'), 0);
            rec.Net_Outstanding__c = toDecimal(getValue(cell, 'NetOutstanding'), 0);
            rec.Due_Amount__c = toDecimal(getValue(cell, 'DueAmount'), 0);
            rec.Deposit__c = toDecimal(getValue(cell, 'Deposit'), 0);
            rec.Adjusted_Local_Amount__c = toDecimal(getValue(cell, 'AdjustedLocalAmount'), 0);
            rec.On_Account_Amount__c = toDecimal(getValue(cell, 'OnAccountAmount'), 0);
            rec.Exchange_Rate__c = toDecimal(getValue(cell, 'ExchangeRate'), 0);
            rec.BG_Amount__c = toDecimal(getValue(cell, 'BGAmount'), 0);
            rec.Amount_In_Doc_Currency__c = toDecimal(getValue(cell, 'AmountInDocCurrency'), 0);
            rec.Security_Deposit__c = toDecimal(getValue(cell, 'SecurityDeposit'), 0);

            // Integer fields
            rec.Overdue_Days__c = toInteger(getValue(cell, 'OverdueDays'), 0);
            rec.Non_Overdue_Days__c = toInteger(getValue(cell, 'NonOverdueDays'), 0);
            rec.Due_Days__c = toInteger(getValue(cell, 'DueDays'), 0);

            // Date fields
            rec.Update_Date__c = convertDate(getValue(cell, 'UpdateDate'));
            rec.Net_Due_Date__c = convertDate(getValue(cell, 'NetDueDate'));
            rec.Document_Date__c = convertDate(getValue(cell, 'DocumentDate'));
            rec.Posting_Date__c = convertDate(getValue(cell, 'PostingDate'));
            rec.Date__c = convertDate(getValue(cell, 'Date'));

            // Add record
            recordsToInsert.add(rec);
        }

        // Insert in bulk
        // if (!recordsToInsert.isEmpty()) {
        //     insert recordsToInsert;
        // }
        return recordsToInsert;
    }

    // ===== Helper Methods =====

    // Get XML child value safely
    private static String getValue(Dom.XmlNode node, String tagName) {
        return getValue(node, tagName, '');
    }
    private static String getValue(Dom.XmlNode node, String tagName, String defaultVal) {
        try {
            Dom.XmlNode child = node.getChildElement(tagName, null);
            if (child != null && String.isNotBlank(child.getText())) {
                return child.getText().trim();
            }
        } catch (Exception e) {}
        return defaultVal;
    }

    // Convert to Decimal safely
    private static Decimal toDecimal(String val, Decimal defaultVal) {
        try {
            if (String.isBlank(val)) return defaultVal;
            
            String cleaned = val.trim();
            
            // If SAP-style negative (e.g. "1584118.00-"), move '-' to front
            if (cleaned.endsWith('-')) {
                cleaned = '-' + cleaned.substring(0, cleaned.length() - 1);
            }
            
            return Decimal.valueOf(cleaned);
        } catch (Exception e) {
            return defaultVal;
        }
    }


    // Convert to Integer safely
    private static Integer toInteger(String val, Integer defaultVal) {
        try {
            return String.isNotBlank(val) ? Integer.valueOf(val.trim()) : defaultVal;
        } catch (Exception e) {
            return defaultVal;
        }
    }

    // Convert SAP YYYYMMDD → Date
    private static Date convertDate(String sapDate) {
        if (String.isBlank(sapDate) || sapDate == '00000000') {
            return null;
        }
        try {
            return Date.newInstance(
                Integer.valueOf(sapDate.substring(0, 4)),
                Integer.valueOf(sapDate.substring(4, 6)),
                Integer.valueOf(sapDate.substring(6, 8))
            );
        } catch (Exception e) {
            return null;
        }
    }
}