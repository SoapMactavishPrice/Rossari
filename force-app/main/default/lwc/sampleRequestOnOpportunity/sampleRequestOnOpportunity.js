import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import getLeadInfo from '@salesforce/apex/OpportunitySampleRequestController.getLeadInfo';
import getPlantOptions from '@salesforce/apex/OpportunitySampleRequestController.getPlantOptions';
import saveSampleRequest from '@salesforce/apex/OpportunitySampleRequestController.saveSample';
import getPicklistDependencies from '@salesforce/apex/OpportunitySampleRequestController.getPicklistDependencies';
import getUnitPrice from '@salesforce/apex/OpportunitySampleRequestController.getUnitPrice';
import getCurrentUserZone from '@salesforce/apex/OpportunitySampleRequestController.getCurrentUserZone';
import getRecordTypeFromOpportunity from '@salesforce/apex/Utility.getRecordTypeFromOpportunity';

const LEAD_FIELDS = ['Opportunity.Account.Name', 'Opportunity.CurrencyIsoCode'];

export default class SampleRequestForm extends NavigationMixin(LightningElement) {
    @api recordId; // Lead ID
    @track SampleLine = [];
    @track plantOptions = [];
    @track leadCompany = '';
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

    @track salesHod = null;

    handleSalesHodChange(event) {
        this.salesHod = event.detail.recordId;
    }

    todayDate = new Date().toISOString().split('T')[0];
    @track leadNumber = '';
    @track zone = '';



    @wire(getRecord, { recordId: '$recordId', fields: LEAD_FIELDS })
    wiredLead({ error, data }) {
        if (data) {
            console.log('Lead data:', JSON.parse(JSON.stringify(data)));
            this.leadCompany = data.fields?.Account?.value?.fields?.Name?.value;
            this.currencyIsoCode = data.fields?.CurrencyIsoCode?.value;
            console.log('curreny' , JSON.parse(JSON.stringify(this.currencyIsoCode)));
            // this.leadNumber = data.fields.Lead_Number__c?.value || '';

        } else if (error) {
            this.showError('Error loading lead', error.body.message);
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
        getRecordTypeFromOpportunity({ opportunityId: this.recordId }).then(result => {
            this.leadRecordType = result;
        }).catch(error => {
            this.showError('Error fetching lead record type', error.body ? error.body.message : error.message);
        });
    }

    get isUnpaidSampleCategory() {
        return this.selectedSampleCategory === 'Unpaid';
    }


    async loadInitialData() {
        try {
            // Load plant options
            this.plantOptions = await getPlantOptions();
            this.plantOptions = this.plantOptions.map(plant => ({
                label: `${plant.Name} - ${plant.Plant_Name__c}`,
                value: plant.Id
            }));

            // Load lead's interested products
            const result = await getLeadInfo({ leadId: this.recordId });
            const data = JSON.parse(result);

            if (data.piList && data.piList.length > 0) {
                this.SampleLine = data.piList.map((product, index) => ({
                    sqNo: this.generateId(),
                    prodId: product.prodId,
                    Product: product.Product || '', // Ensure Product name is initialized
                    Product_Code: product.Product_Code,
                    Description: product.Description || '',
                    Sample_Request_To_Plant: product.productPlant || '',
                    //    Sample_Qty_in_Kgs: product.Sample_Qty_in_Kgs || 0,
                    Sample_Qty_in_Kgs: 0,
                    Sales_Price: product.Sales_Price || 0
                }));
                console.log('Initialized SampleLine:', JSON.stringify(this.SampleLine, null, 2));
            } else {
                this.addEmptyRow();
            }
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

    // handleSampleCategoryChange(event) {
    //     this.selectedSampleCategory = event.detail.value;
    //     this.selectedSAPDocType = '';
    //     this.filteredSAPDocTypeOptions = this.allSAPDocTypeOptions[this.selectedSampleCategory] || [];
    // }

    // Update the handleSampleCategoryChange method
    handleSampleCategoryChange(event) {
        this.selectedSampleCategory = event.detail.value;
        this.selectedSAPDocType = '';
        this.filteredSAPDocTypeOptions = this.allSAPDocTypeOptions[this.selectedSampleCategory] || [];

        // Reset Sales Price to 0 for all items when Unpaid is selected
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

            // Clear the combobox selection both in JS and UI
            this.selectedSAPDocType = '';

            // Reset UI selection explicitly
            const input = this.template.querySelector("[data-name='SAP_Doc_Type__c']");
            if (input) {
                input.value = '';  // This helps reflect empty value on UI
            }

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

    // Update the handlePriceChange method to prevent changes when Unpaid
    handlePriceChange(event) {
        if (this.isUnpaidSampleCategory) {
            // Don't allow price changes for Unpaid samples
            return;
        }

        const index = event.target.dataset.index;
        const value = event.detail.value;
        this.SampleLine[index].Sales_Price = value;
        this.SampleLine = [...this.SampleLine];
    }


    handleAddProduct() {
        this.addEmptyRow();
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

        // Reset file arrays
        this.uploadedFiles = [];
        this.filesData = [];

        // Process each file sequentially
        const processFile = (file, index) => {
            return new Promise((resolve) => {
                const reader = new FileReader();
                reader.onload = () => {
                    const base64 = reader.result.split(',')[1];
                    const fileData = {
                        'filename': file.name,
                        'base64': base64
                    };
                    this.uploadedFiles.push(fileData);
                    this.filesData.push(fileData);
                    console.log(`Processed file ${index}: ${file.name} (size: ${base64.length})`);
                    resolve();
                };
                reader.readAsDataURL(file);
            });
        };

        // Process files sequentially to avoid memory issues
        let promiseChain = Promise.resolve();
        Array.from(files).forEach((file, index) => {
            promiseChain = promiseChain.then(() => processFile(file, index));
        });
    }
    handleSave() {
        // First validate without files
        if (this.validateForm()) {
            const formData = this.getFormData();

            // Process files separately if they exist
            const filePromises = this.uploadedFiles.map(file => {
                return new Promise((resolve) => {
                    // Ensure base64 is clean
                    const cleanBase64 = file.base64.replace(/\s/g, '');
                    resolve({
                        filename: file.filename,
                        base64: cleanBase64
                    });
                });
            });

            Promise.all(filePromises).then(processedFiles => {
                saveSampleRequest({
                    leadId: this.recordId,
                    sampleJs: JSON.stringify(formData),
                    attachmentsFromUploadFile: processedFiles,
                    sampleLine: JSON.stringify(this.SampleLine)
                })
                    .then(result => {
                        this.showSuccess('Success!', 'Sample request created successfully', 'success');
                        this.navigateToRecord(result);
                    })
                    .catch(error => {
                        console.error('Detailed error:', JSON.stringify(error, null, 2));
                        this.showError('Save Failed', error.body?.message || error.message);
                    });
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
            this.showError('No Files', 'Please upload files first');
        }
    }

    hideModalBox() {
        this.isViewFile = false;
    }

    handleCustomerProductNameChange(event) {
        const sqNo = event.target.dataset.id;
        const value = event.target.value;
        const index = this.SampleLine.findIndex(line => line.sqNo === sqNo);
        if (index === -1) return;
        this.SampleLine[index].customerProductName = value;
        this.SampleLine = [...this.SampleLine];
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

    handleExpectedDateChange(event) {
        const expectedDate = event.detail.value;
        const requestDate = this.template.querySelector("[data-name='Sample_Request_Date__c']")?.value;

        if (expectedDate && requestDate && new Date(expectedDate) < new Date(requestDate)) {
            this.showError('Invalid Date', 'Sample Expected Date cannot be earlier than Sample Request Date');
            // Optionally clear the invalid date
            event.target.value = '';
        }
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

        if (requestDate < today) {
            this.showError('Validation Error', "Sample Request Date cannot be earlier than today's date.");
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


    getFormData() {
        const data = {
            Request_Date: this.template.querySelector("[data-name='Sample_Request_Date__c']")?.value,
            Sample_Expected_Date: this.template.querySelector("[data-name='Sample_Expected_Date__c']")?.value,
            Sample_Follow_Up_Date: this.template.querySelector("[data-name='Sample_Follow_Up_Date__c']")?.value,
            Consignee_Name: this.leadCompany,
            Email: this.template.querySelector("[data-name='Email__c']")?.value,
            Send_Email_To_Plant: this.template.querySelector("[data-name='Send_Email_To_Plant__c']")?.checked,
            Remark: this.template.querySelector("[data-name='Remark__c']")?.value,
            Sample_Category: this.selectedSampleCategory,
            SAP_Doc_Type: this.selectedSAPDocType,
            Customer_Code__c: this.leadNumber,
            salesHod: this.salesHod,
            Zone__c: this.zone
        };

        console.log('Form Data being sent to Apex:', JSON.stringify(data, null, 2));
        return data;
    }





    generateId() {
        return Math.random().toString(36).substring(2, 15);
    }

    showSuccess(title, message, variant = 'success') {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode: 'dismissable'
            })
        );
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