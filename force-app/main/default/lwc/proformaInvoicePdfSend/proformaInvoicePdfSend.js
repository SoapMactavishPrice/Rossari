import { LightningElement, track, api } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import saveAndSend from '@salesforce/apex/ProformaInvoicePdfSendController.saveAndSend';
import save from '@salesforce/apex/ProformaInvoicePdfSendController.save';
import getQuoteDetails from '@salesforce/apex/ProformaInvoicePdfSendController.getQuoteDetails';
import getCustomerContactEmails from '@salesforce/apex/ProformaInvoicePdfSendController.getCustomerContactEmails';
import getPdfUrl from '@salesforce/apex/ProformaInvoicePdfSendController.getPdfUrl';
import getCurrentUserDetails from '@salesforce/apex/ProformaInvoicePdfSendController.getCurrentUserDetails';
import deletefile from '@salesforce/apex/ProformaInvoicePdfSendController.deletefile';
import validateQuote from '@salesforce/apex/ProformaInvoicePdfSendController.validateQuote';
import isQuoteLineItemsExist from '@salesforce/apex/ProformaInvoicePdfSendController.isQuoteLineItemsExist';
import getEmailBody from '@salesforce/apex/ProformaInvoicePdfController.getEmailBody';

export default class ProformaInvoicePdfSend extends NavigationMixin(LightningElement) {
    @track showSpinner = false;

    @api recordId;
    @api type;
    @track toEmailAddresses;
    @track ccEmailAddresses;
    @track pdfUrl;
    @track bccEmailAddresses;
    @track recordDeatils = {};
    @track files = [];
    @track body = '';
    @track ownerEmail = '';
    @track ownerName = '';
    customerType = '';
    @track isAttachPdf = true;

    get subject() {
        if (this.type == 'quote') {
            return `Quotation - ${this.recordDeatils?.Account_Name__r?.Name}`;
        } else if (this.type == 'invoice') {
            return `Proforma Invoice - ${this.recordDeatils?.Account_Name__r?.Name}`;
        }
    }

    connectedCallback() {
        console.log('Type -->', this.type)
        if (this.type == 'quote') {
            this.body = 'Dear Sir/Madam, <br/><br/> Please find attached Quotation.<br/><br/><br/><br/>';
        } else if (this.type == 'invoice') {
            this.body = 'Dear Sir/Madam, <br/><br/> Please find attached Proforma Invoice.<br/><br/><br/><br/>';
        }
        validateQuote({ quoteId: this.recordId }).then((result) => {
            this.customerType = result;
            if (this.customerType != null) {
                this.getLineItems();
                this.fetchPdfUrl();
                this.getDetails();
                this.getUser();
                this.getEmailDetails();
                this.fetchEmailBody();
            } else {
                this.showSuccess('Error', 'Customer type is not defined', 'Error');
                this.handleCancel();
            }
        }).catch((error) => {
            this.showSuccess('Error', error.body.message, 'Error');
            this.returnBack();
        })
    }

    getLineItems() {
        isQuoteLineItemsExist({ quoteId: this.recordId }).then((result) => {
            if (!result) {
                this.showSuccess('Error', 'No Quote line items found', 'Error');
            }
        })
    }

    fetchPdfUrl() {
        getPdfUrl({ quoteId: this.recordId, type: this.type })
            .then((result) => {
                if (result != null) {
                    this.pdfUrl = result;
                } else {
                    this.showSuccess('Error', 'Invalid Type', 'Error');
                }
                this.showSpinner = false;
            })
            .catch((error) => {
                console.error('Error fetching PDF URL: ', error);
                this.showSpinner = false;
            });
    }

    fetchEmailBody() {
        getEmailBody({ proformaInvoiceId: this.recordId, type: this.type }).then((result) => {
            this.body += result;
        }).catch((error) => {
            this.showSuccess('Error', error.body.message, 'error');
        })
    }

    getUser() {
        getCurrentUserDetails().then(result => {
            this.ccEmailAddresses = result.Email;
            this.ownerName = result.Name;
            this.ownerEmail = result.Email;
        })
    }

    getEmailDetails() {
        getCustomerContactEmails({ recordId: this.recordId }).then(result => {
            this.toEmailAddresses = result;
        }).catch((error) => {
            this.showSuccess('Error', error.body.message, 'Error');
            this.handleCancel();
        })
    }

    getDetails() {
        getQuoteDetails({ recordId: this.recordId }).then(result => {
            this.recordDeatils = JSON.parse(JSON.stringify(result));
        })
    }


    handleChange(event) {
        this.toEmailAddresses = event.target.value;

    }

    handleCCChange(event) {
        this.ccEmailAddresses = event.target.value;
    }

    handlesubjectChange(event) {
        this.subject = event.target.value;
    }

    handlebodyChange(event) {
        this.body = event.target.value;
    }

    handleAttachPdfChange(event) {
        this.isAttachPdf = event.target.checked;
    }

    @track isOpenFileView = false;

    previewFile() {

        if (this.files.length == 0) {
            this.showSuccess('Error', ` File Not uploaded `, 'error');
        } else {
            this.isOpenFileView = true;
        }
    }

    viewFile(event) {
        let fileIds = event.target.dataset.id;
        console.log('fileId', fileIds);

        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                selectedRecordId: fileIds
            }
        });
    }

    handleOkay() {
        this.isOpenFileView = false;
    }

    deleteFiles(event) {
        let fileIds = event.target.dataset.id;
        deletefile({ prodId: fileIds }).then(result => {
            if (result) {
                this.showSuccess('Success', `File Deleted Successfully`, 'success');
                this.files = this.files.filter(file => file.documentId != fileIds);
                if (this.files.length == 0) {
                    this.isOpenFileView = false;
                }
            }
        })

    }



    handleSendEmail() {
        let validate = this.validateData();

        setTimeout(() => {
            if (validate) {

                this.showSpinner = true;

                saveAndSend({ emailId: this.toEmailAddresses, CC_Addresses: this.ccEmailAddresses, subject: this.subject, body: this.body, qtName: this.recordDeatils.Name, qId: this.recordId, OwnerEmail: this.ownerEmail, OwnerName: this.ownerName, files: JSON.stringify(this.files), isAttachPdf: this.isAttachPdf, type: this.type }).then(result => {
                    this.showSpinner = false;
                    if (result == 'Success') {
                        this.showSuccess('Success', 'Saved and Sent Successfully !!!', 'Success');
                        this.handleCancel();
                    } else {
                        if (result != 'Success') {
                            this.showSuccess('Error', result, 'Error');
                        }
                    }
                })
            }
        }, 100)
    }
    handleSaveEmail() {
        this.showSpinner = true;
        save({ qtName: this.recordDeatils.Name, qId: this.recordId, files: JSON.stringify(this.files), type: this.type }).then(result => {
            this.showSpinner = false;
            if (result == 'Success') {

                this.showSuccess('Success', 'Saved Successfully !!!', 'Success');
                this.handleCancel();
            } else
                if (result != 'Success') {
                    this.showSuccess('Error', result, 'Error');
                }
        })
    }

    validateData() {
        let validate = true;

        // Utility function to check for empty values
        const isEmpty = (value) => value == null || value == '' || value == undefined;

        // Check 'To' email addresses
        if (isEmpty(this.toEmailAddresses)) {
            this.showSuccess('Error', 'Please fill to Email Address', 'Error');
            validate = false;
        }
        // Check subject
        else if (isEmpty(this.subject)) {
            this.showSuccess('Error', 'Please fill Subject', 'Error');
            validate = false;
        }
        // Check body
        else if (isEmpty(this.body)) {
            this.showSuccess('Error', 'Please fill body', 'Error');
            validate = false;
        }

        return validate;
    }


    handleUploadFinished(event) {
        // Get the list of uploaded files
        const uploadedFiles = event.detail.files;

        // Loop through each file and push it into the array if it's allowed
        uploadedFiles.forEach(file => {
            const fileExtension = file.name.split('.').pop().toLowerCase();

            // Check if the file extension is allowed
            if (['pdf', 'jpg', 'jpeg'].includes(fileExtension)) {
                const fileInfo = {
                    name: file.name,
                    size: file.size,
                    documentId: file.documentId,
                    base64Content: file.base64
                };

                // Push the file info into the uploadedFiles array
                this.files.push(fileInfo);
            } else {
                this.showSuccess('Error', 'No valid files selected. Only PDF, JPG, and JPEG files are allowed.', 'error');
            }
        });

        // Optionally, log the array to verify it's being updated
        console.log('Uploaded Files:', this.files);
    }



    handleButtonClick(event) {
        // Trigger the file upload component by selecting it using the 'record-id' (item.Id)
        const fileUpload = this.template.querySelector('lightning-file-upload');
        if (fileUpload) {
            fileUpload.click();  // Simulate a click to open the file picker
        }
    }


    showSuccess(title, msg, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant
        });
        this.dispatchEvent(evt);
    }

    returnBack() {
        setTimeout(() => {
            this.handleCancel();
        }, 3000);
    }

    handleCancel() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view'
            }
        });
    }

}