@isTest
public class ProformaInvoicePdfSendControllerTest {
    @isTest
    static void testAllMethods() {
        Account acc = new Account(Name = 'Test Account', Business_Type__c = 'Domestic');
        insert acc;

        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', Email = 'test@example.com', AccountId = acc.Id);
        insert con;

        Proforma_Invoice__c invoice = new Proforma_Invoice__c(Name = 'Test Invoice', Account_Name__c = acc.Id);
        insert invoice;

        Proforma_Invoice_Line_Item__c lineItem = new Proforma_Invoice_Line_Item__c(
           
            Proforma_Invoice_Name__c = invoice.Id,
            Line_Item_Description__c = 'Item',
            Quantity__c = 1,
            Sales_Price__c = 100,
            Total_Price__c = 100
        );
        insert lineItem;

        ProformaInvoicePdfSendController.getQuoteDetails(invoice.Id);

        try {
            ProformaInvoicePdfSendController.getQuoteDetails('invalidId');
        } catch (Exception e) {
        }

        ProformaInvoicePdfSendController.getCustomerContactEmails(invoice.Id);

        Account acc2 = new Account(Name = 'Empty Account');
        insert acc2;
        Proforma_Invoice__c emptyInvoice = new Proforma_Invoice__c(Account_Name__c = acc2.Id);
        insert emptyInvoice;
        try {
            ProformaInvoicePdfSendController.getCustomerContactEmails(emptyInvoice.Id);
        } catch (Exception e) {
        }

        ProformaInvoicePdfSendController.getPdfUrl(invoice.Id, 'proformaInvoice');
        ProformaInvoicePdfSendController.getPdfUrl(invoice.Id, 'invoice');
        ProformaInvoicePdfSendController.getPdfUrl(invoice.Id, 'invalid');

        ProformaInvoicePdfSendController.getCurrentUserDetails();

        ContentVersion cv = new ContentVersion(
            Title = 'Test_File_1.pdf',
            PathOnClient = 'Test_File_1.pdf',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        try{
        insert cv;
        
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        }Catch(Exception e){}
        ProformaInvoicePdfSendController.deletefile(cv.ContentDocumentId);

        ProformaInvoicePdfSendController.validateQuote(invoice.Id);

        ProformaInvoicePdfSendController.isQuoteLineItemsExist(invoice.Id);
        ProformaInvoicePdfSendController.isQuoteLineItemsExist(emptyInvoice.Id);

        String filesEmpty = '[]';
        ProformaInvoicePdfSendController.save('Test Quote', invoice.Id, filesEmpty, 'proformaInvoice');
        ProformaInvoicePdfSendController.save('Test Invoice', invoice.Id, filesEmpty, 'invoice');

        String fileJson = '[{"name":"Test_File_1.pdf","documentId":"' + cv.ContentDocumentId + '"}]';
        ProformaInvoicePdfSendController.save('Test Quote', invoice.Id, fileJson, 'proformaInvoice');

        User currentUser = [SELECT Id, Name, Email FROM User WHERE Id = :UserInfo.getUserId()];

        ProformaInvoicePdfSendController.saveAndSend(
            'test@example.com',
            'cc@example.com',
            'Subject',
            'Body',
            'Test Quote',
            invoice.Id,
            currentUser.Email,
            currentUser.Name,
            filesEmpty,
            true,
            'proformaInvoice'
        );

        ProformaInvoicePdfSendController.saveAndSend(
            'test@example.com',
            'cc@example.com',
            'Subject',
            'Body',
            'Test Invoice',
            invoice.Id,
            currentUser.Email,
            currentUser.Name,
            filesEmpty,
            true,
            'invoice'
        );

        ProformaInvoicePdfSendController.saveAndSend(
            'test@example.com',
            'cc@example.com',
            'Subject',
            'Body',
            'Test Quote',
            invoice.Id,
            currentUser.Email,
            currentUser.Name,
            fileJson,
            true,
            'proformaInvoice'
        );

        ProformaInvoicePdfSendController.saveAndSend(
            'test@example.com',
            'cc@example.com',
            'Subject',
            'Body',
            'Test Quote',
            invoice.Id,
            currentUser.Email,
            currentUser.Name,
            filesEmpty,
            false,
            'proformaInvoice'
        );

        ProformaInvoicePdfSendController.saveAndSend(
            'test1@example.com,test2@example.com',
            'cc1@example.com,cc2@example.com',
            'Subject',
            'Body',
            'Test Quote',
            invoice.Id,
            currentUser.Email,
            currentUser.Name,
            filesEmpty,
            true,
            'proformaInvoice'
        );

        ProformaInvoicePdfSendController.saveAndSend(
            'test@example.com',
            null,
            'Subject',
            'Body',
            'Test Quote',
            invoice.Id,
            currentUser.Email,
            currentUser.Name,
            filesEmpty,
            true,
            'proformaInvoice'
        );

        ProformaInvoicePdfSendController.saveAndSend(
            'invalid-email',
            'cc@example.com',
            'Subject',
            'Body',
            'Test Quote',
            invoice.Id,
            currentUser.Email,
            currentUser.Name,
            filesEmpty,
            true,
            'proformaInvoice'
        );
    }
}