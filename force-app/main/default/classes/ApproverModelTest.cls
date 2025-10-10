@IsTest
private class ApproverModelTest {
    
    @IsTest
    static void testApproverModelFields() {
        ApproverModel model = new ApproverModel();
        
        model.tdsApproverId = '005xx000001ABCDE';
        model.msdsApproverId = '005xx000001XYZAB';
        model.technicalDocApproverId = '005xx000001LMNOP';

        
        String tds = model.tdsApproverId;
        String msds = model.msdsApproverId;
        String tech = model.technicalDocApproverId;
    }
}