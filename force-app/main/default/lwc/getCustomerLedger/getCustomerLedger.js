import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getCompany from '@salesforce/apex/CustomerLedgerController.getCompany';
import customerLedgerCallout from '@salesforce/apex/CustomerLedgerController.customerLedgerCallout';
import { CloseActionScreenEvent } from 'lightning/actions';
import { RefreshEvent } from 'lightning/refresh';


export default class GetCustomerLedger extends LightningElement {

    @api recordId;
    @api objectApiName;
    @track showSpinner = false;
    @track companyOptions = [];
    @track companyValue = '';
    @track customerNumber = '';
    @track downloadBtnFlag = true;
    @track xString = '';
    @track fromDate = '';
    @track toDate = '';
    @track dateError = '';

    showToast(toastTitle, toastMsg, toastType) {
        const event = new ShowToastEvent({
            title: toastTitle,
            message: toastMsg,
            variant: toastType,
            mode: "dismissable"
        });
        this.dispatchEvent(event);
    }

    formatDateForAPI(dateString) {
        if (!dateString) return '';
        const date = new Date(dateString);
        const day = String(date.getDate()).padStart(2, '0');
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const year = date.getFullYear();
        return `${day}.${month}.${year}`;
    }

    connectedCallback() {
        this.showSpinner = true;
        setTimeout(() => {
            this.handleGetCompany();
        }, 1000);
    }

    handleGetCompany() {
        getCompany({
            accId: this.recordId
        }).then(result => {
            console.log('>>> Company Result:', result);
            if (result != '') {
                let data = JSON.parse(result);
                this.companyOptions = data.company;
                this.customerNumber = data.account.SAP_Customer_Code__c;
            }
            this.showSpinner = false;
        }).catch(error => {
            this.showSpinner = false;
            this.showToast('Error', error.body?.message || 'Failed to fetch Company', 'error');
        });
    }

    handleFieldChange(event) {
        const field = event.target.dataset.field;
        if (field === 'company') {
            this.companyValue = event.detail.value;
            this.validateForm();
        }
    }

    handleDateChange(event) {
        const field = event.target.dataset.field;
        const value = event.detail.value;

        if (field === 'fromDate') {
            this.fromDate = value;
        } else if (field === 'toDate') {
            this.toDate = value;
        }

        this.validateDates();
        this.validateForm();
    }

    validateDates() {
        // Clear previous error
        this.dateError = '';

        if (!this.fromDate || !this.toDate) {
            return; // Let required field validation handle empty fields
        }

        // Convert dates to timestamps for comparison
        const fromDate = new Date(this.fromDate);
        const toDate = new Date(this.toDate);

        if (fromDate > toDate) {
            this.dateError = 'From Date cannot be greater than To Date';
            this.showToast('Error', this.dateError, 'error');
        } else {
            // Clear any previous error if dates are valid
            this.dateError = '';
        }
    }

    validateForm() {
        // Enable download button only if all required fields are filled and no date error
        this.downloadBtnFlag = !(
            this.companyValue &&
            this.fromDate &&
            this.toDate &&
            !this.dateError
        );
    }

    handleCallout() {
        // Final validation before proceeding
        // if (this.dateError || !this.fromDate || !this.toDate || !this.companyValue) {
        //     this.showToast('Error', 'Please fill in all required fields and fix any validation errors', 'error');
        //     return;
        // }

        // Format dates to DD.MM.YYYY for the API call
        const fromDate = this.formatDateForAPI(this.fromDate);
        const toDate = this.formatDateForAPI(this.toDate);

        console.log('>>> Company:', this.companyValue);
        console.log('>>> From Date:', fromDate);
        console.log('>>> To Date:', toDate);

        this.showSpinner = true;
        customerLedgerCallout({
            accId: this.recordId,
            company: this.companyValue,
            fromDate: fromDate,
            toDate: toDate
        }).then((result) => {
            console.log('>>> Result:', result);
            this.showSpinner = false;
            this.xString = result;
            this.handleDownloadPDF();
        }).catch((error) => {
            this.showSpinner = false;
        })
    }

    handleDownloadPDF() {
        const base64Data = this.xString; // from API
        const fileName = 'CustomerLedger_'+this.customerNumber+'_'+this.companyValue+'_'+this.fromDate+'_To_'+this.toDate+'.pdf';

        const element = document.createElement('a');
        element.href = 'data:application/pdf;base64,' + base64Data;
        element.download = fileName;
        document.body.appendChild(element);
        element.click();
        document.body.removeChild(element);
    }

    closeModal(event) {
        this.dispatchEvent(new CloseActionScreenEvent());
        this.dispatchEvent(new RefreshEvent());
    }

}