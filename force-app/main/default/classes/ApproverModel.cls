public class ApproverModel {
    @AuraEnabled
    public String tdsApproverId { get; set; }
    
    @AuraEnabled
    public String msdsApproverId { get; set; }
    
    @AuraEnabled
    public String technicalDocApproverId { get; set; }
}