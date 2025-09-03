public with sharing class ExpenseController {

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> initializeExpense() {
        Map<String, Object> result = new Map<String, Object>();
        try {
            User currentUser = [SELECT Id, Name, Division, Zone__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

            List<Map<String, String>> voucherOptions = new List<Map<String, String>>();
            for (Schema.PicklistEntry entry : Expense__c.Type_of_Voucher__c.getDescribe().getPicklistValues()) {
                if (entry.isActive()) {
                    voucherOptions.add(new Map<String, String>{
                        'label' => entry.getLabel(),
                        'value' => entry.getValue()
                    });
                }
            }

            result.put('currentUser', currentUser);
            result.put('voucherOptions', voucherOptions);
            result.put('todayDate', Date.today().format()); // Returns formatted date string

        } catch (Exception e) {
            throw new AuraHandledException('Error initializing expense: ' + e.getMessage());
        }
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getUsers(String searchTerm) {
        try {
            searchTerm = '%' + String.escapeSingleQuotes(searchTerm) + '%';
            List<User> users = [SELECT Id, Name, Division, Zone__c 
                               FROM User 
                               WHERE Name LIKE :searchTerm 
                               AND IsActive = true
                               ORDER BY Name 
                               LIMIT 50];
            
            List<Map<String, String>> options = new List<Map<String, String>>();
            for (User u : users) {
                options.add(new Map<String, String>{
                    'label' => u.Name,
                    'value' => u.Id,
                    'division' => u.Division != null ? u.Division : '',
                    'zone' => u.Zone__c != null ? u.Zone__c : ''
                });
            }
            return options;
        } catch (Exception e) {
            throw new AuraHandledException('Error getting users: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getTypeOfExpense(String searchTerm) {
        try {
            searchTerm = '%' + String.escapeSingleQuotes(searchTerm) + '%';
            List<Type_of_Expense__c> expenses = [SELECT Id, Name 
                                                FROM Type_of_Expense__c 
                                                WHERE Name LIKE :searchTerm 
                                                ORDER BY Name 
                                                LIMIT 50];
            
            List<Map<String, String>> options = new List<Map<String, String>>();
            for (Type_of_Expense__c e : expenses) {
                options.add(new Map<String, String>{
                    'label' => e.Name,
                    'value' => e.Id
                });
            }
            return options;
        } catch (Exception e) {
            throw new AuraHandledException('Error getting expense types: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String createExpenseWithFiles(Expense__c expense, List<Expense_Line_Item__c> lineItems, Map<String, List<Id>> filesPerLineItem) {
        Savepoint sp = Database.setSavepoint();
        try {
            // 1. Insert main Expense
            insert expense;
    
            // 2. Insert line items
            if (lineItems != null && !lineItems.isEmpty()) {
                for (Expense_Line_Item__c li : lineItems) {
                    li.Expense__c = expense.Id;
                }
                insert lineItems;
    
                // 3. Create ContentDocumentLinks for files
                if (filesPerLineItem != null && !filesPerLineItem.isEmpty()) {
                    List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
                    
                    for (Integer i = 0; i < lineItems.size(); i++) {
                        List<Id> fileIds = filesPerLineItem.get(String.valueOf(i));
                        if (fileIds != null && !fileIds.isEmpty()) {
                            Expense_Line_Item__c lineItem = lineItems[i];
                            
                            for (Id fileId : fileIds) {
                                cdlList.add(new ContentDocumentLink(
                                    LinkedEntityId = lineItem.Id,
                                    ContentDocumentId = fileId,
                                    ShareType = 'V',
                                    Visibility = 'AllUsers'
                                ));
                            }
                        }
                    }
                    
                    if (!cdlList.isEmpty()) {
                        insert cdlList;
                    }
                }
            }
            
            return expense.Id;
    
        } catch (Exception e) {
            Database.rollback(sp);
            throw new AuraHandledException('Error creating expense: ' + e.getMessage() + ' - ' + e.getStackTraceString());
        }
    }
}