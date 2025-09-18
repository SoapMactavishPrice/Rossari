trigger CustomerSalesAreaTrigger on Customer_Sales_Area__c (before insert, before update) {
    // Collect unique keys from Trigger.new
    Map<String, Customer_Sales_Area__c> newCombinations = new Map<String, Customer_Sales_Area__c>();
    
    Set<Id> companyCodes  = new Set<Id>();
    Set<Id> distChannels  = new Set<Id>();
    Set<Id> divisions     = new Set<Id>();
    Set<Id> salesOrgs     = new Set<Id>();
    
    for (Customer_Sales_Area__c csa : Trigger.new) {
        if (csa.Comapany_Code__c  != null &&
            csa.Distribution_Channel__c != null &&
            csa.Division__c != null &&
            csa.Sales_Organisation__c != null) {
                
                // Build composite key
                String key = csa.Comapany_Code__c  + '-' +
                    csa.Distribution_Channel__c + '-' +
                    csa.Division__c + '-' +
                    csa.Sales_Organisation__c;
                
                // Prevent duplicate combination in same transaction
                if (newCombinations.containsKey(key)) {
                    csa.addError('Duplicate Customer Sales Area combination found in this transaction.');
                } else {
                    newCombinations.put(key, csa);
                }
                
                // Collect for query
                companyCodes.add(csa.Comapany_Code__c );
                distChannels.add(csa.Distribution_Channel__c);
                divisions.add(csa.Division__c);
                salesOrgs.add(csa.Sales_Organisation__c);
            }
    }
    
    if (!newCombinations.isEmpty()) {
        // Query existing Customer_Sales_Area__c records that match
        List<Customer_Sales_Area__c> existing = [
            SELECT Id, Comapany_Code__c , Distribution_Channel__c, Division__c, Sales_Organisation__c
            FROM Customer_Sales_Area__c
            WHERE Comapany_Code__c  IN :companyCodes
            AND Distribution_Channel__c IN :distChannels
            AND Division__c IN :divisions
            AND Sales_Organisation__c IN :salesOrgs
        ];
        
        Set<String> existingKeys = new Set<String>();
        for (Customer_Sales_Area__c csa : existing) {
            String key = csa.Comapany_Code__c  + '-' +
                csa.Distribution_Channel__c + '-' +
                csa.Division__c + '-' +
                csa.Sales_Organisation__c;
            existingKeys.add(key);
        }
        
        // Block if combination already exists in DB
        for (Customer_Sales_Area__c csa : Trigger.new) {
            if (csa.Comapany_Code__c  != null &&
                csa.Distribution_Channel__c != null &&
                csa.Division__c != null &&
                csa.Sales_Organisation__c != null) {
                    
                    String key = csa.Comapany_Code__c  + '-' +
                        csa.Distribution_Channel__c + '-' +
                        csa.Division__c + '-' +
                        csa.Sales_Organisation__c;
                    
                    if (existingKeys.contains(key) && (Trigger.isInsert || (Trigger.isUpdate && csa.Id != null && csa.Id != newCombinations.get(key).Id))) {
                        csa.addError('A Customer Sales Area with the same Company Code, Distribution Channel, Division, and Sales Organisation already exists.');
                    }
                }
        }
    }
}