public class AddressInformationHelper {

    public static void updateAddressFields(List<Address_Information__c> addressList) {
        Set<Id> postalCodeIds = new Set<Id>();
        Set<Id> cityIds = new Set<Id>();
        Set<Id> stateIds = new Set<Id>();

        for (Address_Information__c addr : addressList) {
            if (addr.Pin_Code__c != null) {
                postalCodeIds.add(addr.Pin_Code__c);
            }
            if (addr.City__c != null) {
                cityIds.add(addr.City__c);
            }
            if (addr.State__c != null) {
                stateIds.add(addr.State__c);
            }
        }

        Map<Id, Pin_Code__c> postalCodeMap = new Map<Id, Pin_Code__c>(
            [SELECT Id, City__c, City__r.State__c, 
                    City__r.State__r.Country__c,
                    City__r.State__r.Zone__c,
                    City__r.State__r.Country__r.Region__c
             FROM Pin_Code__c
             WHERE Id IN :postalCodeIds]
        );

        Map<Id, City__c> cityMap = new Map<Id, City__c>(
            [SELECT Id, State__c,
                    State__r.Country__c,
                    State__r.Zone__c,
                    State__r.Country__r.Region__c
             FROM City__c
             WHERE Id IN :cityIds]
        );

        Map<Id, State__c> stateMap = new Map<Id, State__c>(
            [SELECT Id, Country__c,
                    Zone__c,
                    Country__r.Region__c
             FROM State__c
             WHERE Id IN :stateIds]
        );

        for (Address_Information__c addr : addressList) {
            if (addr.Pin_Code__c != null && postalCodeMap.containsKey(addr.Pin_Code__c)) {
                Pin_Code__c postal = postalCodeMap.get(addr.Pin_Code__c);
                addr.City__c = postal.City__c;
                addr.State__c = postal.City__r.State__c;
                addr.Country__c = postal.City__r.State__r.Country__c;
                addr.Zone__c = postal.City__r.State__r.Zone__c;
                addr.Region__c = postal.City__r.State__r.Country__r.Region__c;

            } else if (addr.City__c != null && cityMap.containsKey(addr.City__c)) {
                City__c city = cityMap.get(addr.City__c);
                addr.State__c = city.State__c;
                addr.Country__c = city.State__r.Country__c;
                addr.Zone__c = city.State__r.Zone__c;
                addr.Region__c = city.State__r.Country__r.Region__c;

            } else if (addr.State__c != null && stateMap.containsKey(addr.State__c)) {
                State__c state = stateMap.get(addr.State__c);
                addr.Country__c = state.Country__c;
                addr.Zone__c = state.Zone__c;
                addr.Region__c = state.Country__r.Region__c;
            }
        }
    }
}