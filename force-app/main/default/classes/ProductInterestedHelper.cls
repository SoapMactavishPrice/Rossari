public class ProductInterestedHelper {
    public static void updateLeadTotalQuantities(Set<Id> leadIds) {
        // Map to hold LeadId -> total quantity
        Map<Id, Decimal> leadToQuantityMap = new Map<Id, Decimal>();

        // Query all related Product_Interested__c records
        List<Product_Interested__c> relatedProducts = [
            SELECT Lead__c, Quantity_in_Kgs__c
            FROM Product_Interested__c
            WHERE Lead__c IN :leadIds
        ];

        // Sum quantities per Lead
        for (Product_Interested__c pi : relatedProducts) {
            if (pi.Lead__c != null) {
                leadToQuantityMap.put(
                    pi.Lead__c,
                    (leadToQuantityMap.containsKey(pi.Lead__c) ? leadToQuantityMap.get(pi.Lead__c) : 0) + 
                    (pi.Quantity_in_Kgs__c != null ? pi.Quantity_in_Kgs__c : 0)
                );
            }
        }

        // Prepare Leads to update
        List<Lead> leadsToUpdate = new List<Lead>();

        for (Id leadId : leadToQuantityMap.keySet()) {
            leadsToUpdate.add(new Lead(
                Id = leadId,
                Total_Quantity_PI__c = leadToQuantityMap.get(leadId)
            ));
        }

        if (!leadsToUpdate.isEmpty()) {
            update leadsToUpdate;
        }
    }
}