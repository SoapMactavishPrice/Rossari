public class ExpenseTriggerHandler {
    public static void populateExpenseName(List<Expense__c> newExpenses) {
        System.debug('*** ExpenseTriggerHandler.populateExpenseName, # of recs: ' + newExpenses.size());

        // Get current user info
        User currentUser = [
            SELECT Id, Division_Code__c, Sales_Type_Code1__c 
            FROM User 
            WHERE Id = :UserInfo.getUserId()
        ];
        System.debug('Current User Division: ' + currentUser.Division_Code__c + ', SalesType: ' + currentUser.Sales_Type_Code1__c);

        String userDivision = currentUser.Division_Code__c;
        String userSalesType = currentUser.Sales_Type_Code1__c;

        if (String.isBlank(userDivision) || String.isBlank(userSalesType)) {
            System.debug('Skipping because division or sales type is blank');
            return;
        }

        // Fetch Code_Master__c record
        List<Code_Master__c> codeMasters = [
            SELECT Id, Current_Sequence__c 
            FROM Code_Master__c 
            WHERE Division__c = :userDivision 
              AND Sales_Type__c = :userSalesType 
            LIMIT 1 
            FOR UPDATE
        ];
        System.debug('Found codeMasters count: ' + codeMasters.size());

        if (codeMasters.isEmpty()) {
            System.debug('No Code_Master__c record found for key: Division=' + userDivision + ' / SalesType=' + userSalesType);
            return;
        }

        Code_Master__c cm = codeMasters[0];
        Integer currentSequence = (cm.Current_Sequence__c == null) ? 1 : Integer.valueOf(cm.Current_Sequence__c);
        
        System.debug('Starting sequence: ' + currentSequence);

        // Generate prefix
        String prefix = getPrefix(userDivision, userSalesType);
        System.debug('Using prefix: ' + prefix);

        // Assign names and increment sequence
        for (Expense__c exp : newExpenses) {
            exp.Name = prefix + String.valueOf(currentSequence);
            System.debug('Setting Name for expense record: Id=' + exp.Id + ', Name=' + exp.Name);
            currentSequence++;
        }

        // Update Code_Master__c with new sequence
        cm.Current_Sequence__c = currentSequence;
        update cm;
        System.debug('Updated Code_Master__c sequence to: ' + currentSequence);
    }

    private static String getPrefix(String division, String salesType) {
        if (salesType == '10' && (division == '10' || division == '11')) {
            return 'TEXT_DOM_FY25-25_';
        } else if (salesType == '20' && (division == '10' || division == '11')) {
            return 'TEXT_EXP_FY25-25_';
        } else if (salesType == '20' && division == '22') {
            return 'AHN_EXP_FY25-25_';
        } else if (salesType == '10' && division == '22') {
            return 'AHN_DOM_FY25-25_';
        }
        return 'GEN_FY25-25_';
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