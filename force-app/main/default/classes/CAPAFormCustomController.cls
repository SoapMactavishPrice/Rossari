public class CAPAFormCustomController {
    
    public Case caseRecord { get; set; }
    
    public CAPAFormCustomController() {
        String recordId = ApexPages.currentPage().getParameters().get('id');
        if (recordId == null) {
            recordId = '500C100000E4TEnIAN';
        }
        if (String.isNotBlank(recordId)) {
            try {
                caseRecord = [
                    SELECT Id, CaseNumber, CAPA_No__c, CAPA_Date__c, Nature_of_Complaint__c,
                    Ref_Document_No__c, Description_of_Non_Conformity__c, Root_Cause__c,
                    Concern_Department_Head__c, Concern_Department_Head_Sign__c,
                    Concern_Department_Head_Date__c, Q_A_Manager_Designee__c,
                    Q_A_Manager_Designee__r.Name, Q_A_Manager_Designee_Sign__c,
                    Q_A_Manager_Designee_Date__c, Verification_of_Corrective_Preventive__c,
                    Head_of_Quality_Assurance_Department__c, 
                    Head_of_Quality_Assurance_Department__r.Name,
                    Head_of_Quality_Assurance_Sign__c, Head_of_Quality_Assurance_Date__c,
                    Closure_of_CAPA__c, Head_Designee_QA__c, Head_Designee_QA__r.Name,
                    Head_Designee_QA_Sign__c, Head_Designee_QA_Date__c,Corrective_Preventive_Action_To_Be_Taken__c, Responsible_Staff__c,Target_Date_for_Completion_of_Corrective__c,
                    // Additional fields you might need
                    Subject, Status, Priority, CreatedDate, Action_Taken_By_Name_Designation__c, Date_of_completion_of_Corrective_Action__c, Corrective_Preventive_Action_Taken__c
                    FROM Case 
                    WHERE Id = :recordId
                    LIMIT 1
                ];
            } catch (QueryException e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Case record not found.'));
                caseRecord = new Case();
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No record ID provided.'));
            caseRecord = new Case();
        }
    }
    
    // Optional: Add method to format dates if needed
    public String getFormattedDate(Date dateValue) {
        if (dateValue != null) {
            return dateValue.format();
        }
        return '';
    }
}