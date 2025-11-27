trigger CustomerSalesAreaTrigger on Customer_Sales_Area__c (before insert, before update) {
    Map<String, Customer_Sales_Area__c> newCombinations = new Map<String, Customer_Sales_Area__c>();

    // Change from Set<Id> to Set<String>
    Set<String> companyCodes = new Set<String>();
    Set<String> distChannels = new Set<String>();
    Set<String> divisions = new Set<String>();
    Set<String> salesOrgs = new Set<String>();

    for (Customer_Sales_Area__c csa : Trigger.new) {
        if (csa.Customer_Code__c != null &&
            csa.Distribution_Channel__c != null &&
            csa.Division__c != null &&
            csa.Sales_Organisation__c != null) {

            String key = csa.Customer_Code__c + '-' +
                         csa.Distribution_Channel__c + '-' +
                         csa.Division__c + '-' +
                         csa.Sales_Organisation__c;

            // Prevent duplicate within same transaction
            if (newCombinations.containsKey(key)) {
                csa.addError('Duplicate Customer Sales Area combination found in this transaction.');
            } else {
                newCombinations.put(key, csa);
            }

            // Add values to sets
            companyCodes.add(csa.Customer_Code__c);
            distChannels.add(csa.Distribution_Channel__c);
            divisions.add(csa.Division__c);
            salesOrgs.add(csa.Sales_Organisation__c);
        }
    }

    if (!newCombinations.isEmpty()) {
        // Query existing combinations
        List<Customer_Sales_Area__c> existing = [
            SELECT Id, Customer_Code__c, Distribution_Channel__c, Division__c, Sales_Organisation__c
            FROM Customer_Sales_Area__c
            WHERE Customer_Code__c IN :companyCodes
              AND Distribution_Channel__c IN :distChannels
              AND Division__c IN :divisions
              AND Sales_Organisation__c IN :salesOrgs
        ];

        // Build key map from existing records
        Map<String, Id> existingKeyMap = new Map<String, Id>();
        for (Customer_Sales_Area__c csa : existing) {
            String key = csa.Customer_Code__c + '-' +
                         csa.Distribution_Channel__c + '-' +
                         csa.Division__c + '-' +
                         csa.Sales_Organisation__c;
            existingKeyMap.put(key, csa.Id);
        }

        // Validate against existing records
        for (Customer_Sales_Area__c csa : Trigger.new) {
            if (csa.Customer_Code__c != null &&
                csa.Distribution_Channel__c != null &&
                csa.Division__c != null &&
                csa.Sales_Organisation__c != null) {

                String key = csa.Customer_Code__c + '-' +
                             csa.Distribution_Channel__c + '-' +
                             csa.Division__c + '-' +
                             csa.Sales_Organisation__c;

                if (existingKeyMap.containsKey(key)) {
                    Id existingId = existingKeyMap.get(key);
                    // Prevent duplicates except for the same record being updated
                    if (Trigger.isInsert || (Trigger.isUpdate && existingId != csa.Id)) {
                        csa.addError('A Customer Sales Area with the same Company Code, Distribution Channel, Division, and Sales Organisation already exists.');
                    }
                }
            }
        }
    }
}