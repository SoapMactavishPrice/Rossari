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
}