trigger OrderHeaderPartnerFunctionTrigger on Order_Header_Partner_Function__c (after insert, after update) {
    
    // Step 1: Filter only valid VE records with non-null Partner_Function_Code__c
    Map<Id, Order_Header_Partner_Function__c> veHeaders = new Map<Id, Order_Header_Partner_Function__c>();
    
    for (Order_Header_Partner_Function__c ohpf : Trigger.new) {
        if (ohpf.Partner_Function__c == 'VE' && 
            String.isNotBlank(ohpf.Partner_code__c) && 
            ohpf.Order__c != null) 
        {
            veHeaders.put(ohpf.Id, ohpf);
        }
    }
    
    if (veHeaders.isEmpty()) return;
    
    // Step 2: Collect codes to match with User.SAP_User_Id__c
    Set<String> pfCodes = new Set<String>();
    for (Order_Header_Partner_Function__c ohpf : veHeaders.values()) {
        pfCodes.add(ohpf.Partner_Function_Code__c);
    }
    
    // Step 3: Query Users
    Map<String, User> userBySAP = new Map<String, User>();
    for (User u : [
        SELECT Id, SAP_User_Id__c
        FROM User
        WHERE SAP_User_Id__c IN :pfCodes
    ]) {
        if (String.isNotBlank(u.SAP_User_Id__c)) {
            userBySAP.put(u.SAP_User_Id__c, u);
        }
    }
    
    // Step 4: Prepare Orders to update
    List<Order> ordersToUpdate = new List<Order>();
    
    for (Order_Header_Partner_Function__c ohpf : veHeaders.values()) {
        
        User matchedUser = userBySAP.get(ohpf.Partner_Function_Code__c);
        
        Order ord = new Order(
            Id = ohpf.Order__c,
            Sales_Employee_Code__c = ohpf.Partner_Function_Code__c
        );
        
        // Only set OwnerId if user is matched
        if (matchedUser != null) {
            ord.OwnerId = matchedUser.Id;
        }
        
        ordersToUpdate.add(ord);
    }
    
    // Step 5: Safe update
    if (!ordersToUpdate.isEmpty()) {
        try {
            update ordersToUpdate;
        } catch (Exception e) {
            System.debug('Order update failed but skipped safely: ' + e.getMessage());
        }
    }
}