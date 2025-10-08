public class ExpenseTriggerHandler {
    public static void populateExpenseName(List<Expense__c> newExpenses) {
        System.debug('*** ExpenseTriggerHandler.populateExpenseName, # of recs: ' + newExpenses.size());

        // Get current user with required fields
        User currentUser = [
            SELECT Id, Division_Code__c, Sales_Type_Code1__c, Cost_Center__c
            FROM User 
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        String userDivision = currentUser.Division_Code__c;
        String userCostCenter = currentUser.Cost_Center__c;

        if (String.isBlank(userDivision) || String.isBlank(userCostCenter)) {
            System.debug('Missing user Division or Cost Center');
            return;
        }

        // Fetch Cost Center to get Sales Org
        Cost_Center__c userCostCenterRecord = [
            SELECT Id, Name, Sales_Org__r.Name
            FROM Cost_Center__c 
            WHERE Name = :userCostCenter
            LIMIT 1
        ];

        String salesOrgName = userCostCenterRecord.Sales_Org__r?.Name;
        if (String.isBlank(salesOrgName)) {
            System.debug('Sales Org is blank');
            return;
        }

        // 🔁 Convert sales org name to full company name
        String companyName = getCompanyNameFromSalesOrgName(salesOrgName);
        if (String.isBlank(companyName)) {
            System.debug('Could not determine Company Name from Sales Org: ' + salesOrgName);
            return;
        }

        // Group expenses by Sales Type
        Map<String, List<Expense__c>> salesTypeToExpenses = new Map<String, List<Expense__c>>();
        Set<String> salesTypeCodes = new Set<String>();

        for (Expense__c exp : newExpenses) {
            String salesTypeCode = getSalesTypeCode(exp.Sales_Type__c);
            if (String.isBlank(salesTypeCode)) continue;

            salesTypeCodes.add(salesTypeCode);
            if (!salesTypeToExpenses.containsKey(salesTypeCode)) {
                salesTypeToExpenses.put(salesTypeCode, new List<Expense__c>());
            }
            salesTypeToExpenses.get(salesTypeCode).add(exp);
        }

        // Query Code_Master__c using Company Name and Sales Type
        List<Code_Master__c> codeMasters = [
            SELECT Id, Backend_Current_Sequence__c, Current_Sequence__c, Sales_Type__c, Company__r.Name
            FROM Code_Master__c
            WHERE Sales_Type__c IN :salesTypeCodes
              
              AND Company__r.Name = :companyName
              AND IsActive__c = true
            FOR UPDATE
        ];

        // Build map for lookup
        Map<String, Code_Master__c> keyToCodeMaster = new Map<String, Code_Master__c>();
        for (Code_Master__c cm : codeMasters) {
            String key = cm.Company__r.Name + '_' + cm.Sales_Type__c;
            keyToCodeMaster.put(key, cm);
        }

        // Assign name from backend sequence and increment sequence
        List<Code_Master__c> cmsToUpdate = new List<Code_Master__c>();

        for (String salesTypeCode : salesTypeToExpenses.keySet()) {
            String key = companyName + '_' + salesTypeCode;
            Code_Master__c cm = keyToCodeMaster.get(key);

            if (cm == null) {
                System.debug('⚠️ No Code_Master__c found for Company=' + companyName + ', SalesType=' + salesTypeCode);
                continue;
            }

            Decimal currentSeq = (cm.Current_Sequence__c == null) ? 1 : cm.Current_Sequence__c;

            for (Expense__c exp : salesTypeToExpenses.get(salesTypeCode)) {
                exp.Name = cm.Backend_Current_Sequence__c;
                System.debug('✅ Assigned Expense Name: ' + exp.Name);
                currentSeq++;
            }

            cm.Current_Sequence__c = currentSeq;
            cmsToUpdate.add(cm);
        }

        if (!cmsToUpdate.isEmpty()) {
            update cmsToUpdate;
            System.debug('✅ Updated Code_Master__c sequence values');
        }
    }

    // 🔁 Map Sales Org Name to Company Name
    private static String getCompanyNameFromSalesOrgName(String salesOrgName) {
        if (String.isNotBlank(salesOrgName)) {
            salesOrgName = salesOrgName.toLowerCase().trim();
            if (salesOrgName.contains('rossari') || salesOrgName == '1000' || salesOrgName.contains('rbl')) {
                return 'Rossari Biotech Limited';
            } else if (salesOrgName.contains('unitop') || salesOrgName == '3000' || salesOrgName.contains('uni')) {
                return 'Unitop Chemicals Private Limited';
            } else if (salesOrgName.contains('tristar') || salesOrgName == '4000' || salesOrgName.contains('tri')) {
                return 'Tristar Intermediates Private Limited';
            }
        }
        return null;
    }

    // 🔁 Map Picklist values to Sales Type codes
    private static String getSalesTypeCode(String salesType) {
        if (salesType == 'Domestic') {
            return '10';
        } else if (salesType == 'Export') {
            return '20';
        }
        return null;
    }
    
    public static void statusChangeToSubmitted(List<Expense__c> newList, Map<Id, Expense__c> oldMap) {
        List<Id> expenseIds = new List<Id>();

        for (Expense__c exp : newList) {
            Expense__c oldExp = oldMap.get(exp.Id);

            // Detect status change Draft → Submitted
            if (oldExp != null && oldExp.Status__c != 'Submitted' && exp.Status__c == 'Submitted') {
                expenseIds.add(exp.Id);
            }
        }

        if (!expenseIds.isEmpty()) {
            // Query with relationships so emails are available, including record type
            List<Expense__c> expensesToNotify = [
                SELECT Id, Name, Owner.Email, Owner.Name,
                       Zonal_Head__c, Zonal_Head__r.Email, Zonal_Head__r.Name,
                       Customer_Success_Incharge__c, Customer_Success_Incharge__r.Email, Customer_Success_Incharge__r.Name,
                       Date__c, Type_of_Voucher__c, Tour__r.Name, RecordType.DeveloperName,
                       Employee_Name__r.Name, Division__c, Zone__c
                FROM Expense__c
                WHERE Id IN :expenseIds
            ];

            for (Expense__c exp : expensesToNotify) {
                try {
                    String recordType = exp.RecordType.DeveloperName;
                    
                    if (recordType == 'RBL') {
                        // For RBL - send to Zonal Head
                        if (String.isNotBlank(exp.Zonal_Head__r?.Email)) {
                            ExpenseApprovalEmailHandler.sendSubmissionEmail(exp, '');
                        }
                    } else if (recordType == 'Unitop_Tristar') {
                        // For Unitop/Tristar - send to Customer Success Incharge
                        if (String.isNotBlank(exp.Customer_Success_Incharge__r?.Email)) {
                            ExpenseApprovalEmailHandler.sendSubmissionEmail(exp, '');
                        }
                    }
                } catch (Exception e) {
                    System.debug('Error sending submission email for Expense ' + exp.Id + ': ' + e.getMessage());
                    // Log the error but don't fail the transaction
                }
            }
        }
    }
}