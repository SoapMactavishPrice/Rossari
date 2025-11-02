import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import getPlantOptions from '@salesforce/apex/SampleRequestController.getPlantOptions'; // Plant - removed
import getExistingLineItems from '@salesforce/apex/SampleRequestController.getExistingLineItems';
import saveLineItems from '@salesforce/apex/SampleRequestController.saveLineItems';
import { NavigationMixin } from 'lightning/navigation';
import getStatusPicklistValues from '@salesforce/apex/SampleRequestController.getStatusPicklistValues';
import deleteLineItem from '@salesforce/apex/SampleRequestController.deleteLineItem';
import getRecordType from '@salesforce/apex/Utility.getRecordType';

export default class SampleRequestLineItems extends NavigationMixin(LightningElement) {
    @api recordId;
    @track lineItems = [];
    @track leadRecordType;
    // @track plantOptions = []; // Plant - removed
    @track statusOptions = []; // Added missing statusOptions declaration
    @track isLoading = false;

    connectedCallback() {
        this.loadData();
        this.getRecordTypes();
    }

    getRecordTypes() {
        getRecordType({sampleRequestId: this.recordId}).then(result => {
            this.leadRecordType = result;
        }).catch(error => {
            this.showError('Error fetching record type', error.body ? error.body.message : error.message);
        });
    }

    loadData() {
        this.isLoading = true;

        Promise.all([
            // getPlantOptions(), // Plant - removed
            getStatusPicklistValues()
        ])
            .then(([/*plantResult,*/ statusResult]) => { // Plant - removed plantResult
                // Plant - removed plant options mapping
                // this.plantOptions = plantResult.map(plant => ({
                //     label: `${plant.Name} - ${plant.Plant_Name__c}`,
                //     value: plant.Id
                // }));

                this.statusOptions = statusResult.map(status => ({
                    label: status,
                    value: status
                }));

                if (this.recordId) {
                    return getExistingLineItems({ recordId: this.recordId });
                }
                return null;
            })
            .then(existingItems => {
                if (existingItems) {
                    this.lineItems = existingItems.map(item => ({
                        key: this.generateId(),
                        id: item.Id,
                        prodId: item.Product__c,
                        productName: item.Product__r.Name,
                        productCode: item.Product__r.ProductCode,
                        description: item.Product__r.Description,
                        quantity: item.Sample_Qty_in_Kgs__c,
                        status: item.Status__c || ''
                    }));
                } else {
                    this.addEmptyRow();
                }
            })
            .catch(error => {
                this.showError('Error loading data', error.body?.message || error.message);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleStatusChange(event) {
        const index = event.target.dataset.index;
        const value = event.detail.value;
        this.lineItems[index].status = value;
        this.lineItems = [...this.lineItems];
    }

    handleProductSelection(event) {
        const selectedRecord = event.detail;
        const index = parseInt(event.target.dataset.index, 10);

        if (!selectedRecord) {
            console.log("No record selected");
            return;
        }

        this.lineItems = this.lineItems.map((item, idx) => {
            if (idx === index) {
                return {
                    ...item,
                    prodId: selectedRecord.id,
                    productName: selectedRecord.mainField,
                    productCode: selectedRecord.subField || '',
                    description: selectedRecord.description || selectedRecord.Description || '',
                };
            }
            return item;
        });

        this.lineItems = [...this.lineItems];
    }

    addEmptyRow() {
        this.lineItems = [...this.lineItems, {
            key: this.generateId(),
            id: null,
            prodId: null,
            productName: null,
            productCode: null,
            description: null,
            quantity: null,
            status: ''
        }];
    }

    handleAddProduct() {
        this.addEmptyRow();
    }

    // Plant - removed handlePlantChange method
    // handlePlantChange(event) {
    //     const index = event.target.dataset.index;
    //     const plantId = event.detail.value;
    //     this.lineItems[index].plantId = plantId;
    //     this.lineItems = [...this.lineItems];
    // }

    handleQuantityChange(event) {
        const index = event.target.dataset.index;
        const quantity = event.detail.value;
        this.lineItems[index].quantity = quantity;
        this.lineItems = [...this.lineItems];
    }

    handleDeleteItem(event) {
        const index = event.target.dataset.index;
        const item = this.lineItems[index];

        if (this.lineItems.length <= 1) {
            this.showError('Cannot delete', 'At least one product is required');
            return;
        }

        // If record has been saved (has an Id), delete from Salesforce
        if (item.id) {
            this.isLoading = true;
            deleteLineItem({ lineItemId: item.id })
                .then(() => {
                    this.lineItems.splice(index, 1);
                    this.lineItems = [...this.lineItems];
                    this.showSuccess('Deleted', 'Line item deleted successfully');
                })
                .catch(error => {
                    this.showError('Delete Failed', error.body?.message || error.message);
                })
                .finally(() => {
                    this.isLoading = false;
                });
        } else {
            // Unsaved row — just remove from UI
            this.lineItems.splice(index, 1);
            this.lineItems = [...this.lineItems];
        }
    }

    handleSave() {
        if (this.validateForm()) {
            this.isLoading = true;

            const itemsToSave = this.lineItems.map(item => ({
                id: item.id || null,
                productId: item.prodId,
                quantity: Number(item.quantity),
                status: item.status
            }));

            saveLineItems({
                recordId: this.recordId,
                lineItems: JSON.stringify(itemsToSave)
            })
                .then(() => {
                    this.showSuccess('Success', 'Line items saved successfully');
                    this.navigateToSampleRequest();
                })
                .catch(error => {
                    console.error('Detailed error:', JSON.stringify(error, null, 2));
                    this.showError('Save Failed', error.body?.message || error.message);
                })
                .finally(() => {
                    this.isLoading = false;
                });
        }
    }

    handleCancel() {
        this.navigateToSampleRequest();
    }

    navigateToSampleRequest() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Sample_Request__c',
                actionName: 'view'
            }
        });
        setTimeout(() => {
            window.location.reload();
        }, 1000);
    }

    validateForm() {
        let isValid = true;
        let errorMessage = '';

        this.lineItems.forEach((item, index) => {
            if (!item.prodId) {
                errorMessage = `Please select a Product for row ${index + 1}`;
                isValid = false;
                return;
            }

            if (!item.quantity || item.quantity <= 0) {
                errorMessage = `Please enter a valid Quantity for ${item.productName || 'product'} in row ${index + 1}`;
                isValid = false;
                return;
            }
        });

        if (!isValid) {
            this.showError('Validation Error', errorMessage);
        }

        return isValid;
    }

    generateId() {
        return Math.random().toString(36).substring(2, 15);
    }

    showSuccess(title, message) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant: 'success'
        }));
    }

    showError(title, message) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant: 'error'
        }));
    }
}