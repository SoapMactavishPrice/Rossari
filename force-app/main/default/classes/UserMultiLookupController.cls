public with sharing class UserMultiLookupController {
    
    @AuraEnabled(cacheable=true)
    public static List<User> searchUsers(String searchTerm, Integer maxResults) {
        try {
            // Validate inputs with safe defaults
            if (String.isBlank(searchTerm) || searchTerm.length() < 2) {
                return new List<User>();
            }
            
            if (maxResults == null || maxResults <= 0 || maxResults > 50) {
                maxResults = 10; // Safe default
            }
            
            // Prepare search term safely
            String cleanSearchTerm = searchTerm.trim();
            String searchKey = '%' + cleanSearchTerm + '%';
            
            System.debug('Searching users with term: ' + cleanSearchTerm);
            
            // Simple query without complex conditions initially
            return [SELECT Id, Name, FirstName, LastName, Email, Username, IsActive 
                   FROM User 
                   WHERE (Name LIKE :searchKey OR Email LIKE :searchKey) 
                   AND IsActive = true 
                   ORDER BY Name 
                   LIMIT :maxResults];
            
        } catch (Exception e) {
            System.debug('Error in searchUsers: ' + e.getMessage() + ' at ' + e.getLineNumber());
            // Return empty list instead of throwing exception for better UX
            return new List<User>();
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<User> getUsersByIds(List<String> userIds) {
        try {
            if (userIds == null || userIds.isEmpty()) {
                return new List<User>();
            }
            
            return [SELECT Id, Name, FirstName, LastName, Email, Username, Title, Department, IsActive,
                           SmallPhotoUrl, FullPhotoUrl
                    FROM User 
                    WHERE Id IN :userIds 
                    AND IsActive = true 
                    ORDER BY Name];
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching users: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<User> getRecentlyUsedUsers(Integer maxResults) {
        try {
            if (maxResults == null || maxResults <= 0) {
                maxResults = 5;
            }
            
            return [SELECT Id, Name, FirstName, LastName, Email, Username, Title, Department, IsActive,
                           SmallPhotoUrl, FullPhotoUrl
                    FROM User 
                    WHERE IsActive = true 
                    ORDER BY LastLoginDate DESC NULLS LAST
                    LIMIT :maxResults];
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching recent users: ' + e.getMessage());
        }
    }
}