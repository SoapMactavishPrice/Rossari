import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import getLeadInfo from '@salesforce/apex/SampleRequestController.getLeadInfo';
import getPlantOptions from '@salesforce/apex/SampleRequestController.getPlantOptions';
import saveSampleRequest from '@salesforce/apex/SampleRequestController.saveSample';

const LEAD_FIELDS = ['Lead.Company', 'Lead.CurrencyIsoCode'];

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

    todayDate = new Date().toISOString().split('T')[0];

    @wire(getRecord, { recordId: '$recordId', fields: LEAD_FIELDS })
    wiredLead({ error, data }) {
        if (data) {
            this.leadCompany = data.fields.Company.value;
            this.currencyIsoCode = data.fields.CurrencyIsoCode.value;
        } else if (error) {
            this.showError('Error loading lead', error.body.message);
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
                    Sample_Qty_in_Kgs: 0
                }));
                console.log('Initialized SampleLine:', JSON.stringify(this.SampleLine, null, 2));
            } else {
                this.addEmptyRow();
            }
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
                    Product: selectedRecord.mainField, // Product Name
                    Product_Code: selectedRecord.subField || '', // ProductCode
                    Description: selectedRecord.description || selectedRecord.Description || '',
                    Sample_Request_To_Plant: selectedRecord.productPlant || '' // Plant_Name__c
                };
            }
            return item;
        });

        this.SampleLine = [...this.SampleLine];
        console.log('Updated SampleLine:', JSON.stringify(this.SampleLine, null, 2));
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
                        this.showSuccess('Success!', 'Sample request created', 'success');
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
        // First validate Sample Expected Date
        const requestDate = this.template.querySelector("[data-name='Sample_Request_Date__c']")?.value;
        const expectedDate = this.template.querySelector("[data-name='Sample_Expected_Date__c']")?.value;

        if (!expectedDate) {
            this.showError('Validation Error', 'Sample Expected Date is required');
            return false;
        }

        if (new Date(expectedDate) < new Date(requestDate)) {
            this.showError('Validation Error', 'Sample Expected Date cannot be earlier than Sample Request Date');
            return false;
        }

        // Now validate each product line item one by one
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

    getFormData() {
        return {
            Request_Date: this.template.querySelector("[data-name='Sample_Request_Date__c']")?.value,
            Sample_Expected_Date: this.template.querySelector("[data-name='Sample_Expected_Date__c']")?.value,
            Sample_Follow_Up_Date: this.template.querySelector("[data-name='Sample_Follow_Up_Date__c']")?.value,
            Consignee_Name: this.leadCompany,
            CC_Email: this.template.querySelector("[data-name='CC_Email__c']")?.value,
            Send_Email_To_Plant: this.template.querySelector("[data-name='Send_Email_To_Plant__c']")?.checked,
            Remark: this.template.querySelector("[data-name='Remark__c']")?.value
        };
    }



    generateId() {
        return Math.random().toString(36).substring(2, 15);
    }

    showSuccess(message) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Success',
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