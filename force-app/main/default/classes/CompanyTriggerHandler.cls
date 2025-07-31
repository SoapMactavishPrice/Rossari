public class CompanyTriggerHandler {
    public static void updateCompanyAddresses(List<Company__c> newCompanys){
        
        Set<Id> postalCodeIds = new Set<Id>();
        Set<Id> areaIds = new Set<Id>();
        Set<Id> cityIds = new Set<Id>();
        Set<Id> stateIds = new Set<Id>();
        
        for (Company__c company : newCompanys) {
            if (company.Company_Postal_Code__c != null) {
                postalCodeIds.add(company.Company_Postal_Code__c);
            }
          
            if (company.Company_City__c != null) {
                cityIds.add(company.Company_City__c);
            }
            if (company.Company_State__c != null) {
                stateIds.add(company.Company_State__c);
            }
        }
        
        // Query the related records
        Map<Id, Pin_Code__c> postalCodeMap = new Map<Id, Pin_Code__c>(
            [SELECT Id,City__c,City__r.State__c,City__r.State__r.Country__c FROM Pin_Code__c WHERE Id IN :postalCodeIds]
        );
      
        Map<Id, City__c> cityMap = new Map<Id, City__c>(
            [SELECT Id, State__c, State__r.Country__c FROM City__c WHERE Id IN :cityIds]
        );
        Map<Id, State__c> stateMap = new Map<Id, State__c>(
            [SELECT Id, Country__c FROM State__c WHERE Id IN :stateIds]
        );
        
        // Update the company fields based on the selected values
        for (Company__c company : newCompanys) {
            if (company.Company_Postal_Code__c != null && postalCodeMap.containsKey(company.Company_Postal_Code__c)) {
                Pin_Code__c postalCode = postalCodeMap.get(company.Company_Postal_Code__c);
             
                company.Company_City__c = postalCode.City__c;
                company.Company_State__c = postalCode.City__r.State__c;
                company.Company_Country__c = postalCode.City__r.State__r.Country__c;
            }else if (company.Company_City__c != null && cityMap.containsKey(company.Company_City__c)) {
                City__c city = cityMap.get(company.Company_City__c);
                company.Company_State__c = city.State__c;
                company.Company_Country__c = city.State__r.Country__c;
            } else if (company.Company_State__c != null && stateMap.containsKey(company.Company_State__c)) {
                State__c state = stateMap.get(company.Company_State__c);
                company.Company_Country__c = state.Country__c;
            }
        }
    }
}