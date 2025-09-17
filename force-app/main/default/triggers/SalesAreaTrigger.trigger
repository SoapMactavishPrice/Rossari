trigger SalesAreaTrigger on Sales_Area__c (before insert) {
    // Collect unique keys from Trigger.new
    Map<String, Sales_Area__c> newCombinations = new Map<String, Sales_Area__c>();

    Set<Id> distChannels   = new Set<Id>();
    Set<Id> itemMasters    = new Set<Id>();
    Set<Id> plantCodes     = new Set<Id>();
    Set<Id> salesOrgs      = new Set<Id>();

    for (Sales_Area__c sa : Trigger.new) {
        if (sa.Distribution_Channel__c != null &&
            sa.Item_Master__c != null &&
            sa.Plant_Code__c != null &&
            sa.Sales_Organisation__c != null) {

            // Build a composite key
            String key = sa.Distribution_Channel__c + '-' +
                         sa.Item_Master__c + '-' +
                         sa.Plant_Code__c + '-' +
                         sa.Sales_Organisation__c;

            // prevent duplicate combination in same transaction
            if (newCombinations.containsKey(key)) {
                sa.addError('Duplicate Sales Area combination found in this transaction.');
            } else {
                newCombinations.put(key, sa);
            }

            // Collect for query
            distChannels.add(sa.Distribution_Channel__c);
            itemMasters.add(sa.Item_Master__c);
            plantCodes.add(sa.Plant_Code__c);
            salesOrgs.add(sa.Sales_Organisation__c);
        }
    }

    if (!newCombinations.isEmpty()) {
        // Query existing Sales_Area__c records matching any of these values
        List<Sales_Area__c> existing = [
            SELECT Id, Distribution_Channel__c, Item_Master__c, Plant_Code__c, Sales_Organisation__c
            FROM Sales_Area__c
            WHERE Distribution_Channel__c IN :distChannels
              AND Item_Master__c IN :itemMasters
              AND Plant_Code__c IN :plantCodes
              AND Sales_Organisation__c IN :salesOrgs
        ];

        Set<String> existingKeys = new Set<String>();
        for (Sales_Area__c sa : existing) {
            String key = sa.Distribution_Channel__c + '-' +
                         sa.Item_Master__c + '-' +
                         sa.Plant_Code__c + '-' +
                         sa.Sales_Organisation__c;
            existingKeys.add(key);
        }

        // Block inserts if key exists in DB
        for (Sales_Area__c sa : Trigger.new) {
            if (sa.Distribution_Channel__c != null &&
                sa.Item_Master__c != null &&
                sa.Plant_Code__c != null &&
                sa.Sales_Organisation__c != null) {

                String key = sa.Distribution_Channel__c + '-' +
                             sa.Item_Master__c + '-' +
                             sa.Plant_Code__c + '-' +
                             sa.Sales_Organisation__c;

                if (existingKeys.contains(key)) {
                    sa.addError('A Sales Area with the same Distribution Channel, Item Master, Plant Code, and Sales Organisation already exists.');
                }
            }
        }
    }
}