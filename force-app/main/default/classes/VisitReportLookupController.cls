public with sharing class VisitReportLookupController {
    @AuraEnabled(cacheable=true)
    public static List<Visit_Report__c> searchVisitReports(String searchTerm) {
        try {
            Id currentUserId = UserInfo.getUserId();
            Datetime sixtyDaysAgo = Datetime.now().addDays(-60);

            if (String.isBlank(searchTerm)) {
                return [
                    SELECT Id, Name, Title_of_Meeting__c, Start_Date_Time__c
                    FROM Visit_Report__c
                    WHERE CreatedById = :currentUserId
                    AND Start_Date_Time__c >= :sixtyDaysAgo
                    ORDER BY Start_Date_Time__c DESC
                    LIMIT 10
                ];
            }

            String searchLike = '%' + String.escapeSingleQuotes(searchTerm) + '%';
            return [
                SELECT Id, Name, Title_of_Meeting__c, Start_Date_Time__c
                FROM Visit_Report__c
                WHERE CreatedById = :currentUserId
                  AND Start_Date_Time__c >= :sixtyDaysAgo
                  AND (Name LIKE :searchLike
                       OR Title_of_Meeting__c LIKE :searchLike)
                ORDER BY Start_Date_Time__c DESC
                LIMIT 10
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error searching visit reports: ' + e.getMessage());
        }
    }
}