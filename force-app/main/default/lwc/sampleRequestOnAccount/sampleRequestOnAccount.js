import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import getAccountInfo from '@salesforce/apex/AccountSampleRequestController.getAccountInfo';
import getPlantOptions from '@salesforce/apex/AccountSampleRequestController.getPlantOptions';
import saveSampleRequest from '@salesforce/apex/AccountSampleRequestController.saveSample';

const ACCOUNT_FIELDS = ['Account.Name', 'Account.CurrencyIsoCode'];

export default class AccountSampleRequest extends NavigationMixin(LightningElement) {
    @api recordId; // Account ID
    @track SampleLine = [];
    @track plantOptions = [];
    @track accountName = '';
    @track currencyIsoCode;
    @track uploadedFiles = [];
    @track isViewFile = false;
    @track filesData = [];
    @track sendEmailToPlant = true;

    todayDate = new Date().toISOString().split('T')[0];

    @wire(getRecord, { recordId: '$recordId', fields: ACCOUNT_FIELDS })
    wiredAccount({ error, data }) {
        if (data) {
            this.accountName = data.fields.Name.value;
            this.currencyIsoCode = data.fields.CurrencyIsoCode.value;
        } else if (error) {
            this.showError('Error loading account', error.body.message);
        }
    }

    connectedCallback() {
        this.loadInitialData();
    }

    async loadInitialData() {
        try {
            // Load plant options
            this.plantOptions = await getPlantOptions();
            this.plantOptions = this.plantOptions.map(plant => ({
                label: plant.Name,
                value: plant.Id
            }));

            // Start with one empty product row
            this.addEmptyRow();
        } catch (error) {
            this.showError('Error loading data', error.body ? error.body.message : error.message);
        }
    }

    handleSendEmailCheckbox(event) {
        this.sendEmailToPlant = event.target.checked;
    }

    handleProductSelection(event) {
        const selectedRecord = event.detail;
        const index = parseInt(event.target.dataset.index, 10);

        if (!selectedRecord) {
            console.log("No record selected");
            return;
        }

        this.SampleLine = this.SampleLine.map((item, idx) => {
            if (idx === index) {
                return {
                    ...item,
                    prodId: selectedRecord.id,
                    Product: selectedRecord.mainField,
                    Product_Code: selectedRecord.subField || '',
                    Description: selectedRecord.description || '',
                    Sample_Request_To_Plant: selectedRecord.productPlant || ''
                };
            }
            return item;
        });

        this.SampleLine = [...this.SampleLine];
    }

    addEmptyRow() {
        this.SampleLine = [...this.SampleLine, {
            sqNo: this.generateId(),
            prodId: '',
            Product: '',
            Product_Code: '',
            Description: '',
            Sample_Request_To_Plant: '',
            Sample_Qty_in_Kgs: 0
        }];
    }

    handleAddProduct() {
        if (this.validateCurrentProducts()) {
            this.addEmptyRow();
        }
    }

    handleDelete(event) {
        const index = event.target.dataset.index;
        if (this.SampleLine.length > 1) {
            this.SampleLine.splice(index, 1);
            this.SampleLine = [...this.SampleLine];
        } else {
            this.showError('Cannot delete', 'At least one product is required');
        }
    }

    handlePlantChange(event) {
        const index = event.target.dataset.index;
        const value = event.detail.value;
        this.SampleLine[index].Sample_Request_To_Plant = value;
        this.SampleLine = [...this.SampleLine];
    }

    handleQtyChange(event) {
        const index = event.target.dataset.index;
        const value = event.detail.value;
        this.SampleLine[index].Sample_Qty_in_Kgs = value;
        this.SampleLine = [...this.SampleLine];
    }

    handleUploadClick() {
        this.template.querySelector('.hiddenFileInput').click();
    }

    handleFileChange(event) {
        const files = event.target.files;
        if (!files || files.length === 0) return;

        const allowedTypes = ['application/pdf', 'image/jpeg', 'image/jpg'];
        const validFiles = [...files].filter(file => allowedTypes.includes(file.type));

        if (validFiles.length === 0) {
            this.showError('Invalid Files', 'Only PDF, JPG, and JPEG files are allowed');
            return;
        }

        this.uploadedFiles = [];
        this.filesData = [];

        const fileReadPromises = validFiles.map(file => {
            return new Promise((resolve) => {
                const reader = new FileReader();
                reader.onload = () => {
                    const base64 = reader.result.split(',')[1];
                    resolve({
                        filename: file.name,
                        base64: base64
                    });
                };
                reader.readAsDataURL(file);
            });
        });

        Promise.all(fileReadPromises).then(results => {
            this.uploadedFiles = results;
            this.filesData = [...results];
        });
    }

    handleSave() {
        if (this.validateForm()) {
            const formData = this.getFormData();

            saveSampleRequest({
                accountId: this.recordId,
                sampleJs: JSON.stringify(formData),
                attachmentsFromUploadFile: this.uploadedFiles,
                sampleLine: JSON.stringify(this.SampleLine)
            })
                .then(result => {
                    this.showSuccess('Success', 'Sample request created successfully');
                    this.navigateToRecord(result);
                })
                .catch(error => {
                    console.error('Error:', error);
                    this.showError('Error', error.body?.message || error.message);
                });
        }
    }

    handleCancel() {
        this.navigateToRecord(this.recordId);
    }

    viewFile() {
        if (this.filesData.length > 0) {
            this.isViewFile = true;
        } else {
            this.showError('No Files', 'Please upload at least one file');
        }
    }

    hideModalBox() {
        this.isViewFile = false;
    }

    removeFile(event) {
        const index = event.target.dataset.index;
        if (index !== undefined) {
            this.filesData.splice(index, 1);
            this.uploadedFiles.splice(index, 1);
            this.filesData = [...this.filesData];
            this.uploadedFiles = [...this.uploadedFiles];
        }
    }

    validateCurrentProducts() {
        for (let i = 0; i < this.SampleLine.length; i++) {
            const item = this.SampleLine[i];

            if (!item.prodId) {
                this.showError('Validation Error', `Please select a product for item ${i + 1}`);
                return false;
            }

            if (!item.Sample_Request_To_Plant) {
                this.showError('Validation Error', `Please select a plant for product "${item.Product}"`);
                return false;
            }

            if (!item.Sample_Qty_in_Kgs || item.Sample_Qty_in_Kgs <= 0) {
                this.showError('Validation Error', `Please enter a valid quantity (greater than 0) for product "${item.Product}"`);
                return false;
            }
        }
        return true;
    }

    validateForm() {
        const requestDate = this.template.querySelector("[data-name='Sample_Request_Date__c']")?.value;
        const expectedDate = this.template.querySelector("[data-name='Sample_Expected_Date__c']")?.value;

        if (!requestDate) {
            this.showError('Validation Error', 'Sample Request Date is required');
            return false;
        }

        if (!expectedDate) {
            this.showError('Validation Error', 'Sample Expected Date is required');
            return false;
        }

        if (new Date(expectedDate) < new Date(requestDate)) {
            this.showError('Validation Error', 'Sample Expected Date cannot be earlier than Sample Request Date');
            return false;
        }

        return this.validateCurrentProducts();
    }

    getFormData() {
        return {
            Request_Date: this.template.querySelector("[data-name='Sample_Request_Date__c']")?.value,
            Sample_Expected_Date: this.template.querySelector("[data-name='Sample_Expected_Date__c']")?.value,
            Sample_Follow_Up_Date: this.template.querySelector("[data-name='Sample_Follow_Up_Date__c']")?.value,
            Consignee_Name: this.accountName,
            Send_Email_To_Plant: this.sendEmailToPlant,
            Remark: this.template.querySelector("[data-name='Remark__c']")?.value
        };
    }

    generateId() {
        return Math.random().toString(36).substring(2, 15);
    }

    showSuccess(title, message) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: 'success'
        }));
    }

    showError(title, message) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: 'error'
        }));
    }

    navigateToRecord(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
    }
}