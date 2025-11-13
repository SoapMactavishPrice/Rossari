import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getLineItem from '@salesforce/apex/CreateQuotation_ToSAP.getLineItem';
import quoteValidation from '@salesforce/apex/CreateQuotation_ToSAP.quoteValidation';
import createQuotation from '@salesforce/apex/CreateQuotation_ToSAP.createQuotation';
import syncQuoteLineItems from '@salesforce/apex/CreateQuotation_ToSAP.syncQuoteLineItems';
import getPartnerFunctions from '@salesforce/apex/CreateQuotation_ToSAP.getPartnerFunctions';
import getInventoryData from '@salesforce/apex/GetInventory_FromSAP.fetchInventoryData';
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
    @track syncDataResponseFlag = true;
    @track billtopartyOptions = [];
    @track billtopartyValue = '';
    @track shiptopartyOptions = [];
    @track shiptopartyValue = '';

    // Inventory Modal Properties
    @track showInventoryModal = false;
    @track isLoading = false;
    @track inventoryData = [];
    @track selectedProductName = '';
    @track selectedProductId = '';
    @track totalStock = 0;
    @track totalValue = 0;
    @track unitOfMeasure = '';
    @track currency = '';

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
        this.showSpinner = true;
        setTimeout(() => {
            console.log('recordId ', this.recordId);
            console.log('objectApiName ', this.objectApiName);
            if (this.recordId) {
                this.handleQuoteCheck();
                // this.handleGetLineItems();
            } else {
                this.showToast('Error', 'Invalid Record Id', 'error');
            }
        }, 2000);
    }

    handleQuoteCheck() {
        quoteValidation({
            qId: this.recordId
        }).then((result) => {
            console.log('quoteValidation result ', result);
            let data = JSON.parse(result);
            if (data.status == 'true') {
                // this.showToast('Please wait for callout response', '', 'info');
                this.syncDataResponseFlag = false;
                this.handleGetLineItems();
            } else {
                this.showToast(data.message, '', 'error');
                this.errorResponseMessage = data.message;
                this.showSpinner = false;
            }
        }).catch((error) => {
            console.log('= erorr quoteValidation : ', error);
            this.errorResponseMessage = error;
            this.showSpinner = false;
        });
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
            this.showSpinner = false;
            this.handlerGetPartnerFunctions();
        }).catch(error => {
            console.error('Error fetching line items:', error);
            this.showToast('Error', 'Failed to load line items', 'error');
            this.showSpinner = false;
        });
    }

    handlerGetPartnerFunctions() {
        getPartnerFunctions({
            qId: this.recordId
        }).then(result => {
            let data = JSON.parse(result);
            console.log('getPartnerFunctions result ', data);

            // Create temporary arrays to hold the new options
            const newBillToPartyOptions = [];
            const newShipToPartyOptions = [];

            if (data && data.length > 0) {
                data.forEach(ele => {
                    const name = ele.Name || '';
                    const id = ele.Id || '';
                    const option = {
                        label: name,
                        value: id
                    };

                    if (name.includes('AG')) {
                        newBillToPartyOptions.push(option);
                    }
                    if (name.includes('WE')) {
                        newShipToPartyOptions.push(option);
                    }
                });

                // Assign the new arrays to trigger reactivity
                this.billtopartyOptions = [...newBillToPartyOptions];
                this.shiptopartyOptions = [...newShipToPartyOptions];

                console.log('billtopartyOptions: ', this.billtopartyOptions);
                console.log('shiptopartyOptions: ', this.shiptopartyOptions);
            }
        }).catch(error => {
            console.error('Error fetching partner functions:', error);
            // Optionally show error to user
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Error loading partner functions: ' + error.message,
                    variant: 'error',
                }),
            );
        });
    }

    handleInputChange(event) {
        const fieldName = event.currentTarget.dataset.name;
        const value = event.target.value;
        if (fieldName == 'billtopartydata') {
            this.billtopartyValue = value;
        }
        if (fieldName == 'shiptopartydata') {
            this.shiptopartyValue = value;
        }
        console.log(this.billtopartyValue);
        console.log(this.shiptopartyValue);
        
    }

    // Handle View Inventory button click
    handleViewInventory(event) {
        event.stopPropagation();  // Prevent event from bubbling up
        event.preventDefault();
        const productId = event.currentTarget.dataset.productId;
        const material = event.currentTarget.dataset.material;
        const productName = this.orderLineItemList.find(item => item.Product2Id === productId)?.Product2?.Name;

        if (material) {
            this.selectedProductId = productId;
            this.selectedProductName = productName;
            this.showInventoryModal = true;
            this.loadInventoryData(material);
        }
    }

    // Load inventory data for the selected product
    // Calculate total stock and value
    calculateTotals() {
        if (!this.inventoryData || this.inventoryData.length === 0) {
            this.totalStock = 0;
            this.totalValue = 0;
            return;
        }

        // Calculate total stock
        this.totalStock = this.inventoryData.reduce((sum, item) => {
            return sum + (item.unrestrictedUseStock || 0);
        }, 0);

        // Calculate total value
        this.totalValue = this.inventoryData.reduce((sum, item) => {
            return sum + (item.valueOfUnrestrictedStock || 0);
        }, 0);

        // Get the unit of measure and currency from the first item
        this.unitOfMeasure = this.inventoryData[0]?.baseUnitOfMeasure || '';
        this.currency = this.inventoryData[0]?.currencyKey || '';
    }

    loadInventoryData(material) {
        this.isLoading = true;
        this.inventoryData = [];

        // Call the Apex method to get inventory data
        getInventoryData({
            materialNumber: material
        }).then(result => {
            if (result && result.length > 0) {
                this.inventoryData = result.map(item => ({
                    ...item,
                    // Format dates if needed
                    formattedManufactureDate: item.dateOfManufacture ?
                        new Date(item.dateOfManufacture).toLocaleDateString() : 'N/A',
                    formattedExpiryDate: item.shelfLifeExpirationDate ?
                        new Date(item.shelfLifeExpirationDate).toLocaleDateString() : 'N/A'
                }));

                // Calculate totals
                // this.calculateTotals();
            } else {
                this.inventoryData = [];
                this.totalStock = 0;
                this.totalValue = 0;
            }
            this.isLoading = false;
        }).catch(error => {
            console.error('Error loading inventory data:', error);
            this.showToast('Error', 'Failed to load inventory data', 'error');
            this.isLoading = false;
        });
    }

    // Close the inventory modal
    closeInventoryModal() {
        this.showInventoryModal = false;
        this.inventoryData = [];
        this.selectedProductId = '';
        this.selectedProductName = '';
    }

    // Check if there is inventory data to display
    get hasInventoryData() {
        return this.inventoryData && this.inventoryData.length > 0;
    }

    get totalsDisplay() {
        if (!this.hasInventoryData) return '';
        return `${this.totalStock.toFixed(2)} ${this.unitOfMeasure} | ${this.currency} ${this.totalValue.toFixed(2)}`;
    }

    // Format date for display
    formatDate(dateString) {
        if (!dateString) return 'N/A';
        try {
            const date = new Date(dateString);
            return date.toLocaleDateString();
        } catch (error) {
            console.error('Error formatting date:', error);
            return dateString; // Return original string if parsing fails
        }
    }

    // ------------ Main Order Submit --------------------
    handleMainSubmit(event) {
        this.showSpinner = true;
        event.preventDefault();
        const mandatoryFields = ['Sales_Organisations__c', 'Distribution_Channel__c', 'Division__c', 'RequestedDeliveryDate__c', 'PO_No__c'];
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
            if (this.billtopartyValue == '') {
                validationFlag = true;
            }
            if (this.shiptopartyValue == '') {
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

    handleMainSuccess(event) {
        // this.showToast('Customer Details Save', '', 'success');
        this.showToast('Please wait for callout response', '', 'info');
        this.syncDataResponseFlag = true;
        // this.showSpinner = false;
        this.handleCallout();
    }

    handleCallout() {
        this.syncDataResponseFlag = true;
        this.showSpinner = true;
        createQuotation({
            quoteId: this.recordId,
            btp: this.billtopartyValue,
            stp: this.shiptopartyValue
        }).then((result) => {
            console.log('createQuotation result ', result);
            let data = JSON.parse(result);
            console.log('createQuotation parse data:>>> ', data);
            if (data.StatusCode == 201) {
                if (data.SalesDocument) {
                    this.handlerSendLineItem(data.SalesDocument);
                    this.showToast('Enquiry created in SAP succesfully!', '', 'success');
                    this.ResponseMessage = 'SAP Enquiry Number: ' + data.SalesDocument;
                } else {
                    this.showToast('Something went wrong while creating Enquiry in SAP', '', 'info');
                    // this.errorResponseMessage = 'Something went wrong while creating Enquiry in SAP';
                    this.errorResponseMessage = data.message;
                }
            } else {
                this.syncDataResponseFlag = false;
                this.errorResponseMessage = data.message;
                this.showToast('Error', 'Something went wrong!!!', 'error');
            }
            this.showSpinner = false;

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