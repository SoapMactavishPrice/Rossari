import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import getAccountInfo from '@salesforce/apex/AccountSampleRequestController.getAccountInfo';
import getPlantOptions from '@salesforce/apex/AccountSampleRequestController.getPlantOptions';
import saveSampleRequest from '@salesforce/apex/AccountSampleRequestController.saveSample';
import getPicklistDependencies from '@salesforce/apex/AccountSampleRequestController.getPicklistDependencies';
import getUnitPrice from '@salesforce/apex/AccountSampleRequestController.getUnitPrice';
import getCurrentUserZone from '@salesforce/apex/SampleRequestController.getCurrentUserZone';
import getRecordTypeFromCustomerAccount from '@salesforce/apex/Utility.getRecordTypeFromCustomerAccount';


const ACCOUNT_FIELDS = ['Account.Name', 'Account.CurrencyIsoCode', 'Account.SAP_Customer_Code__c'];

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
    @track sampleCategoryOptions = [];
    @track leadRecordType;
    @track allSAPDocTypeOptions = {
        Paid: [],
        Unpaid: []
    };
    @track filteredSAPDocTypeOptions = [];
    @track zone = '';
    @track accountNumber = '';

    @track salesHod = null;

    handleSalesHodChange(event) {
        this.salesHod = event.detail.recordId;
    }



    todayDate = new Date().toISOString().split('T')[0];

    @wire(getRecord, { recordId: '$recordId', fields: ACCOUNT_FIELDS })
    wiredAccount({ error, data }) {
        if (data) {
            this.accountName = data.fields.Name.value;
            this.currencyIsoCode = data.fields.CurrencyIsoCode.value;
            this.accountNumber = data.fields.SAP_Customer_Code__c?.value || '';
        } else if (error) {
            this.showError('Error loading account', error.body.message);
        }
    }

    connectedCallback() {
        this.loadInitialData();
        this.loadPicklists();
        this.getRecordType();

        getCurrentUserZone()
            .then(result => {
                this.zone = result;
            })
            .catch(error => {
                this.showError('Error fetching user zone', error.body?.message || error.message);
            });
    }

    getRecordType() {
        getRecordTypeFromCustomerAccount({ accountId: this.recordId }).then(result => {
            this.leadRecordType = result;
        }).catch(error => {
            this.showError('Error fetching lead record type', error.body ? error.body.message : error.message);
        });
    }

    async loadInitialData() {
        try {
            // Load plant options
            this.plantOptions = await getPlantOptions();
            this.plantOptions = this.plantOptions.map(plant => ({
                label: `${plant.Name} - ${plant.Plant_Name__c}`,
                value: plant.Id
            }));

            // Start with one empty product row
            this.addEmptyRow();
        } catch (error) {
            this.showError('Error loading data', error.body ? error.body.message : error.message);
        }
    }

    async loadPicklists() {
        try {
            const result = await getPicklistDependencies();

            this.sampleCategoryOptions = result['Sample_Category__c'].map(val => ({
                label: val,
                value: val
            }));

            // Initialize SAP options manually
            const allSAPOptions = result['SAP_Sample_Document_Type__c'];

            // Example logic: match values based on hard-coded dependency
            this.allSAPDocTypeOptions = {
                Paid: allSAPOptions.filter(v => v === 'ZDOM' || v === 'ZDEM').map(val => ({ label: val, value: val })),
                Unpaid: allSAPOptions.filter(v => v === 'ZFOC').map(val => ({ label: val, value: val }))
            };

        } catch (error) {
            console.error('Error loading picklists', error);
        }
    }

    handlePriceChange(event) {
        const index = event.target.dataset.index;
        const value = event.detail.value;
        this.SampleLine[index].Sales_Price = value;
        this.SampleLine = [...this.SampleLine];
    }

    get isUnpaidSampleCategory() {
        return this.selectedSampleCategory === 'Unpaid';
    }

    handleSampleCategoryChange(event) {
        this.selectedSampleCategory = event.detail.value;
        this.selectedSAPDocType = '';
        this.filteredSAPDocTypeOptions = this.allSAPDocTypeOptions[this.selectedSampleCategory] || [];

        if (this.selectedSampleCategory === 'Unpaid') {
            this.SampleLine = this.SampleLine.map(item => ({
                ...item,
                Sales_Price: 0
            }));
        }
    }

    handleSAPDocTypeChange(event) {
        if (!this.selectedSampleCategory) {
            this.showError('Validation Error', 'Please select Sample Category first');
            this.selectedSAPDocType = ''; // Clear any accidental selection
            return;
        }

        this.selectedSAPDocType = event.detail.value;
    }


    handleSendEmailCheckbox(event) {
        this.sendEmailToPlant = event.target.checked;
    }

    async handleProductSelection(event) {
        const selectedRecord = event.detail;
        const index = parseInt(event.target.dataset.index, 10);

        if (!selectedRecord) return;

        const productId = selectedRecord.id;
        let unitPrice = 0;

        try {
            unitPrice = await getUnitPrice({ productId });
        } catch (error) {
            console.error('Failed to fetch UnitPrice:', error);
        }

        this.SampleLine = this.SampleLine.map((item, idx) => {
            if (idx === index) {
                return {
                    ...item,
                    prodId: selectedRecord.id,
                    Product: selectedRecord.mainField,
                    Product_Code: selectedRecord.subField || '',
                    Description: selectedRecord.description || '',
                    Sample_Request_To_Plant: selectedRecord.productPlant || '',
                    Sales_Price: unitPrice
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
            Sample_Qty_in_Kgs: 0,
            Sales_Price: 0
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

    handleCustomerProductNameChange(event) {
        const sqNo = event.target.dataset.id;
        const value = event.target.value;
        const index = this.SampleLine.findIndex(line => line.sqNo === sqNo);
        if (index === -1) return;
        this.SampleLine[index].customerProductName = value;
        this.SampleLine = [...this.SampleLine];
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

            if (!item.Sample_Qty_in_Kgs || item.Sample_Qty_in_Kgs <= 0) {
                this.showError('Validation Error', `Please enter a valid quantity (greater than 0) for product "${item.Product}"`);
                return false;
            }
        }
        return true;
    }

    validateEmails(input) {
        const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

        const emails = input
            .split(/[,;]/)        // Split by comma or semicolon
            .map(e => e.trim())   // Trim each entry
            .filter(e => e);      // Remove empty strings

        let validate = true;
        emails.forEach(email => {
            if (emailPattern.test(email)) {

            } else {
                validate = false;
            }
        });

        return validate;
    }


    validateForm() {
        const today = new Date();
        today.setHours(0, 0, 0, 0); // Set time to 00:00:00 for accurate comparison

        const requestDate = new Date(this.template.querySelector("[data-name='Sample_Request_Date__c']")?.value);
        //    const expectedDate = new Date(this.template.querySelector("[data-name='Sample_Expected_Date__c']")?.value);
        const followUpDate = new Date(this.template.querySelector("[data-name='Sample_Follow_Up_Date__c']")?.value);
        const email = this.template.querySelector("[data-name='Email__c']")?.value;

        const expectedDateStr = this.template.querySelector("[data-name='Sample_Expected_Date__c']")?.value;
        const expectedDate = expectedDateStr ? new Date(expectedDateStr) : null;

        console.log('email', email);

        if (requestDate < today) {
            this.showError('Validation Error', "Sample Request Date cannot be earlier than today's date.");
            return false;
        }

        if (!requestDate) {
            this.showError('Validation Error', 'Sample Request Date is required');
            return false;
        }

        if (!expectedDate) {
            this.showError('Validation Error', 'Sample Expected Date is required');
            return false;
        }

        if (expectedDate < today) {
            this.showError('Validation Error', "Sample Expected Date cannot be earlier than today's date.");
            return false;
        }

        if (new Date(expectedDate) < new Date(requestDate)) {
            this.showError('Validation Error', 'Sample Expected Date cannot be earlier than Sample Request Date');
            return false;
        }

        if (followUpDate && followUpDate < today) {
            this.showError('Validation Error', "Follow Up Date cannot be earlier than today's date.");
            return false;
        }

        if (!this.selectedSampleCategory) {
            this.showError('Validation Error', 'Please select a Sample Category');
            return false;
        }


        if (!this.selectedSAPDocType) {
            this.showError('Validation Error', 'Please select an SAP Document Type');
            return false;
        }


        if (email && !this.validateEmails(email)) {
            this.showError('Validation Error', 'Enter valid emails separated by comma or semicolon');
            return false;
        }

        return this.validateCurrentProducts();
    }

    getFormData() {
        return {
            Request_Date: this.template.querySelector("[data-name='Sample_Request_Date__c']")?.value,
            Sample_Expected_Date: this.template.querySelector("[data-name='Sample_Expected_Date__c']")?.value,
            Sample_Follow_Up_Date: this.template.querySelector("[data-name='Sample_Follow_Up_Date__c']")?.value,
            Email: this.template.querySelector("[data-name='Email__c']")?.value,
            Consignee_Name: this.accountName,
            Send_Email_To_Plant: this.sendEmailToPlant,
            Remark: this.template.querySelector("[data-name='Remark__c']")?.value,
            Sample_Category: this.selectedSampleCategory,
            SAP_Doc_Type: this.selectedSAPDocType,
            Zone__c: this.zone,
            Customer_Code__c: this.accountNumber,
            salesHod: this.salesHod,
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