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
    
    public static void createNewProductDevelopment(List<Product_Interested__c> newList) {
        List<New_Product_Development__c> npdList = new List<New_Product_Development__c>();

        for (Product_Interested__c pi : newList) {
            // Only create if the field is NOT blank
            if (String.isNotBlank(pi.New_Product_Name__c)) {

                New_Product_Development__c npd = new New_Product_Development__c();
                
                npd.Name = pi.New_Product_Name__c;
             //   npd.Product_Interested__c = pi.Id;   // If lookup exists
             //   npd.Lead__c = pi.Lead__c;            // To associate with lead
                npd.Product_Name__c = pi.New_Product_Name__c; // If field exists
                
                npdList.add(npd);
            }
        }

        if (!npdList.isEmpty()) {
            insert npdList;
        }
    }
}