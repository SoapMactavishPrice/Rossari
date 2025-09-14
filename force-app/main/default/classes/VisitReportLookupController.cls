public with sharing class VisitReportLookupController {
    @AuraEnabled(cacheable=true)
    public static List<Visit_Report__c> searchVisitReports(String searchTerm) {
        try {
            Id currentUserId = UserInfo.getUserId();

            if (String.isBlank(searchTerm)) {
                return [
                    SELECT Id, Name, Title_of_Meeting__c
                    FROM Visit_Report__c
                    WHERE CreatedById = :currentUserId
                    ORDER BY CreatedDate DESC
                    LIMIT 10
                ];
            }

            String searchLike = '%' + String.escapeSingleQuotes(searchTerm) + '%';
            return [
                SELECT Id, Name, Title_of_Meeting__c
                FROM Visit_Report__c
                WHERE CreatedById = :currentUserId
                  AND (Name LIKE :searchLike
                       OR Title_of_Meeting__c LIKE :searchLike)
                ORDER BY CreatedDate DESC
                LIMIT 10
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error searching visit reports: ' + e.getMessage());
        }
    }
}