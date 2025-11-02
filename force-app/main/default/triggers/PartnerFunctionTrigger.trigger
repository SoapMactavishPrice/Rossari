trigger PartnerFunctionTrigger on Partner_function__c (before insert, before update) {
    Set<Id> salesAreaIds = new Set<Id>();

    // Step 1: Enforce mandatory fields
    for (Partner_function__c pf : Trigger.new) {
        if (String.isBlank(pf.PARTNER_FUNC__c)) {
            pf.addError('PARTNER_FUNC__c is required.');
        }
        if (String.isBlank(pf.Partner_code__c)) {
            pf.addError('Partner_code__c is required.');
        }
        if (pf.Customer_Sales_Area__c != null) {
            salesAreaIds.add(pf.Customer_Sales_Area__c);
        }
    }

    // Step 2: Query related Customer_Sales_Area__c fields
    Map<Id, Customer_Sales_Area__c> salesAreaMap = new Map<Id, Customer_Sales_Area__c>(
        [SELECT Id,
                Sales_Organisation__r.Name,
                Distribution_Channel__r.Name,
                Division__r.Division_Code__c
         FROM Customer_Sales_Area__c
         WHERE Id IN :salesAreaIds]
    );

    Set<String> newPFUniques = new Set<String>();
    Map<String, Partner_function__c> pfUniqueToRecord = new Map<String, Partner_function__c>();

    // Step 3: Build PF_Unique strings for new records
    for (Partner_function__c pf : Trigger.new) {
        if (pf.Customer_Sales_Area__c != null &&
            !String.isBlank(pf.Partner_code__c) &&
            !String.isBlank(pf.PARTNER_FUNC__c)) {

            Customer_Sales_Area__c csa = salesAreaMap.get(pf.Customer_Sales_Area__c);
            if (csa != null &&
                csa.Sales_Organisation__r != null &&
                csa.Distribution_Channel__r != null &&
                csa.Division__r != null) {

                String pfUnique = pf.Partner_code__c + '_' +
                                  pf.PARTNER_FUNC__c + '_' +
                                  csa.Sales_Organisation__r.Name + '_' +
                                  csa.Distribution_Channel__r.Name + '_' +
                                  csa.Division__r.Division_Code__c;

                newPFUniques.add(pfUnique);
                pfUniqueToRecord.put(pfUnique, pf);
            }
        }
    }

    // Step 4: Query existing records to check for duplicates
    List<Partner_function__c> existingRecords = [
        SELECT Id, Partner_code__c, PARTNER_FUNC__c,
               Customer_Sales_Area__r.Sales_Organisation__r.Name,
               Customer_Sales_Area__r.Distribution_Channel__r.Name,
               Customer_Sales_Area__r.Division__r.Division_Code__c
        FROM Partner_function__c
        WHERE Partner_code__c != null AND PARTNER_FUNC__c != null AND Customer_Sales_Area__c != null
    ];

    for (Partner_function__c existing : existingRecords) {
        Customer_Sales_Area__c csa = existing.Customer_Sales_Area__r;
        if (csa != null &&
            csa.Sales_Organisation__r != null &&
            csa.Distribution_Channel__r != null &&
            csa.Division__r != null &&
            !String.isBlank(existing.Partner_code__c) &&
            !String.isBlank(existing.PARTNER_FUNC__c)) {

            String existingPFUnique = existing.Partner_code__c + '_' +
                                      existing.PARTNER_FUNC__c + '_' +
                                      csa.Sales_Organisation__r.Name + '_' +
                                      csa.Distribution_Channel__r.Name + '_' +
                                      csa.Division__r.Division_Code__c;

            if (newPFUniques.contains(existingPFUnique)) {
                Partner_function__c pf = pfUniqueToRecord.get(existingPFUnique);
                if (pf != null) {
                    pf.addError('A Partner Function with the same PF_Unique__c combination already exists.');
                }
            }
        }
    }
}