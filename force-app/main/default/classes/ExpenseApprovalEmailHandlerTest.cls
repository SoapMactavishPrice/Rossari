@isTest
public class ExpenseApprovalEmailHandlerTest {

    @isTest
    static void testAllExpenseApprovalEmailHandlerMethods() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User ownerUser = new User(
            FirstName = 'Owner',
            LastName = 'User',
            Email = 'owneruser@example.com',
            Username = 'owneruser' + DateTime.now().getTime() + '@test.com',
            Alias = 'owner',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US',
            Cost_Center__c = '10000001'
        );
        insert ownerUser;

        User zonalHead = new User(
            FirstName = 'Zonal',
            LastName = 'Head',
            Email = 'zonalhead@example.com',
            Username = 'zonalhead' + DateTime.now().getTime() + '@test.com',
            Alias = 'zh',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US',
            Cost_Center__c = '10000001'
        );
        insert zonalHead;

        User csiUser = new User(
            FirstName = 'Customer',
            LastName = 'Incharge',
            Email = 'csiuser@example.com',
            Username = 'csiuser' + DateTime.now().getTime() + '@test.com',
            Alias = 'csi',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US',
            Cost_Center__c = '10000001'
        );
        insert csiUser;

        User hodUser = new User(
            FirstName = 'Business',
            LastName = 'HOD',
            Email = 'hoduser@example.com',
            Username = 'hoduser' + DateTime.now().getTime() + '@test.com',
            Alias = 'hod',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US',
            Cost_Center__c = '10000001'
        );
        insert hodUser;

        User u1 = new User(Id = UserInfo.getUserId(), Cost_Center__c = '10000001');
        update u1;

        Sales_Organisation__c salesOrg = new Sales_Organisation__c(Name = '10000001');
        insert salesOrg;

        Cost_Center__c cc = new Cost_Center__c(
            Name = '10000001',
            Sales_Org__c = salesOrg.Id
        );
        insert cc;

        RecordType rtRBL = [SELECT Id FROM RecordType WHERE SObjectType = 'Expense__c' AND DeveloperName = 'RBL' LIMIT 1];
        RecordType rtUnitop = [SELECT Id FROM RecordType WHERE SObjectType = 'Expense__c' AND DeveloperName = 'Unitop_Tristar' LIMIT 1];

        Expense__c expenseRBL = new Expense__c(
            Name = 'Expense RBL',
            OwnerId = ownerUser.Id,
            RecordTypeId = rtRBL.Id,
            Zonal_Head__c = zonalHead.Id,
            Business_HOD__c = hodUser.Id,
            Customer_Success_Incharge__c = csiUser.Id,
            Date__c = Date.today(),
            Type_of_Voucher__c = 'Outstation',
            Cost_Center__c = cc.Id
        );
        insert expenseRBL;

        Expense__c expenseUnitop = new Expense__c(
            Name = 'Expense Unitop',
            OwnerId = ownerUser.Id,
            RecordTypeId = rtUnitop.Id,
            Customer_Success_Incharge__c = csiUser.Id,
            Business_HOD__c = hodUser.Id,
            Date__c = Date.today(),
            Type_of_Voucher__c = 'Outstation',
            Cost_Center__c = cc.Id
        );
        insert expenseUnitop;

        insert new Expense_Line_Item__c(
            Expense__c = expenseRBL.Id,
            Amount_Claimed__c = 100,
            Type_of_Expense__c = null
        );

        insert new Expense_Line_Item__c(
            Expense__c = expenseUnitop.Id,
            Amount_Claimed__c = 200,
            Type_of_Expense__c = null
        );

        Expense__c expRBL = [
            SELECT Id, OwnerId, Name, RecordType.DeveloperName,
                   Zonal_Head__r.Email, Zonal_Head__r.Name,
                   Business_HOD__r.Email, Business_HOD__r.Name,
                   Customer_Success_Incharge__r.Email, Customer_Success_Incharge__r.Name,
                   Owner.Email, Owner.Name,
                   Date__c, Type_of_Voucher__c, Tour__r.Name,
                   Employee_Name__r.Name, Division__c, Zone__c
            FROM Expense__c
            WHERE Name = 'Expense RBL'
            LIMIT 1
        ];

        Expense__c expUnitop = [
            SELECT Id, OwnerId, Name, RecordType.DeveloperName,
                   Customer_Success_Incharge__r.Email, Customer_Success_Incharge__r.Name,
                   Business_HOD__r.Email, Business_HOD__r.Name,
                   Owner.Email, Owner.Name,
                   Date__c, Type_of_Voucher__c, Tour__r.Name,
                   Employee_Name__r.Name, Division__c, Zone__c
            FROM Expense__c
            WHERE Name = 'Expense Unitop'
            LIMIT 1
        ];

        Test.startTest();
        ExpenseApprovalEmailHandler.sendSubmissionEmail(expRBL, 'Test comment');
        ExpenseApprovalEmailHandler.sendDecisionEmail(expRBL, 'Approved', 'testto@example.com', 'testcc@example.com', 'Decision comment');
        ExpenseApprovalEmailHandler.sendEscalationToHOD(expRBL);
        ExpenseApprovalEmailHandler.sendEscalationFromCSIToHOD(expUnitop);
        ExpenseApprovalEmailHandler.sendSubmissionToCSI(expUnitop, 'Submit to CSI');
        Test.stopTest();
    }
}