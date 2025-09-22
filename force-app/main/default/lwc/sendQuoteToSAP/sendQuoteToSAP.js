import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getLineItem from '@salesforce/apex/CreateQuotation_ToSAP.getLineItem';
// import quoteValidation from '@salesforce/apex/CreateQuotation_ToSAP.quoteValidation';
import createQuotation from '@salesforce/apex/CreateQuotation_ToSAP.createQuotation';
import syncQuoteLineItems from '@salesforce/apex/CreateQuotation_ToSAP.syncQuoteLineItems';
// import updateQuotation from '@salesforce/apex/CreateQuotation_ToSAP.updateQuotation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { RefreshEvent } from 'lightning/refresh';

export default class SendQuoteToSAP extends LightningElement {

    @api recordId;
    @api objectApiName;
    @api salesDocNo;
    @track showSpinner = false;
    @track recTypeName = '';
    @track ResponseMessage = '';
    @track errorResponseMessage = '';
    @track syncDataResponseFlag = false;
    @track partnerfunctionOptions = [];
    @track partnerfunctionValue = '';

    showToast(toastTitle, toastMsg, toastType) {
        const event = new ShowToastEvent({
            title: toastTitle,
            message: toastMsg,
            variant: toastType,
            mode: "dismissable"
        });
        this.dispatchEvent(event);
    }

    connectedCallback() {
        setTimeout(() => {
            console.log('recordId ', this.recordId);
            console.log('objectApiName ', this.objectApiName);
            if (this.recordId) {
                // this.handleQuoteCheck();
                this.handleGetLineItems();
            } else {
                this.showToast('Error', 'Invalid Record Id', 'error');
            }
        }, 2000);
    }

    @track orderLineItemList = [];
    handleGetLineItems() {
        getLineItem({
            qId: this.recordId
        }).then((result) => {
            let data = JSON.parse(result);
            console.log('data:>>> ', data);
            this.orderLineItemList = data.quoteLineItemList;
            console.log('orderLineItemList ', this.orderLineItemList);
        })
    }

    // ------------ Main Order Submit --------------------
    handleMainSubmit(event) {
        this.showSpinner = true;
        event.preventDefault();
        const mandatoryFields = ['Quote_Date__c', 'Quote_Valid_Till__c', 'CustomerPurchaseOrderDate__c', 'RequestedDeliveryDate__c'];
        const lwcInputFields = this.template.querySelectorAll('lightning-input-field');
        let validationFlag = false;
        if (lwcInputFields) {
            lwcInputFields.forEach(field => {
                if (mandatoryFields.includes(field.fieldName) && (field.value == null || field.value === '')) {
                    console.log(field.fieldName);
                    validationFlag = true;
                }
                field.reportValidity();
            });
            if (this.partnerfunctionValue == '') {
                validationFlag = true;
            }
            if (validationFlag) {
                console.log('validation flag trigger');
                // Optionally show a toast message for validation errors
                this.showToast('Please fill all the mandatory fields', '', 'error');
                this.showSpinner = false;
            } else {
                const form1 = this.template.querySelector('lightning-record-edit-form[data-id="mainform"]');
                const fields = {};
                form1.submit();
            }
        }
    }

    handleNewError(event) {
        // This will display the error in the lightning-messages component
        const error = event.detail;
        console.log('Error occurred: ', error);

        // Optionally show an error toast message
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: 'An error occurred: ' + error.detail,
                variant: 'error'
            })
        );

    }

    // handleMainSuccess(event) {
    //     // this.showToast('Customer Details Save', '', 'success');
    //     this.showToast('Please wait for callout response', '', 'info');
    //     this.syncDataResponseFlag = true;
    //     // this.showSpinner = false;
    //     this.handleCallout();
    // }

    handleCallout() {
        this.syncDataResponseFlag = true;
        this.showSpinner = true;
        createQuotation({
            quoteId: this.recordId
        }).then((result) => {
            console.log('createQuotation result ', result);
            let data = JSON.parse(result);
            console.log('createQuotation parse data:>>> ', data);
            if (data.StatusCode == 201) {
                this.handlerSendLineItem(data.SalesDocument);
                this.showToast('Quotation created in SAP succesfully!', '', 'success');
                this.ResponseMessage = 'SAP Quotation Number: ' + data.SalesDocument;
            } else {
                this.showSpinner = false;
                this.syncDataResponseFlag = false;
                this.errorResponseMessage = data.message;
                this.showToast('Error', 'Something went wrong!!!', 'error');
            }

        }).catch((error) => {
            console.log('= erorr createQuotation', error);
            this.showToast('Error', 'Something went wrong!!!', 'error');
            this.errorResponseMessage = error;
            this.showSpinner = false;
        })
    }

    handlerSendLineItem() {
        syncQuoteLineItems({
            quoteId: this.recordId
        }).then((result) => {
            console.log('syncQuoteLineItems result : ', result);
            this.showSpinner = false;
        }).catch((error) => {
            console.log('= erorr syncQuoteLineItems : ', error);
            this.showToast('Error', 'Something went wrong!!!', 'error');
        })
    }

    closeModal(event) {
        this.dispatchEvent(new CloseActionScreenEvent());
        this.dispatchEvent(new RefreshEvent());
    }

}