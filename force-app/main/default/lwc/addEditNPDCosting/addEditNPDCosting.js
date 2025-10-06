import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getExistingCostingItems from '@salesforce/apex/NPDCostingController.getExistingCostingItems';
import saveCostingItems from '@salesforce/apex/NPDCostingController.saveCostingItems';
import deleteCostingItem from '@salesforce/apex/NPDCostingController.deleteCostingItem';
import getYieldAndRMCChange from '@salesforce/apex/NPDCostingController.getYieldAndRMCChange';

export default class NpdCostingLineItems extends NavigationMixin(LightningElement) {
    @api recordId; // New_Product_Development__c record Id
    @track lineItems = [];
    @track isLoading = false;
    @track yieldAndRMCChange = 0;

    connectedCallback() {
        this.loadData();
    }

    loadData() {
        this.isLoading = true;

        if (this.recordId) {
            // First get the Yield_and_RMC_change__c value
            getYieldAndRMCChange({ recordId: this.recordId })
                .then(yieldValue => {
                    this.yieldAndRMCChange = yieldValue || 0;

                    // Then load existing costing items
                    return getExistingCostingItems({ recordId: this.recordId });
                })
                .then(existingItems => {
                    console.log('Existing items:', JSON.stringify(existingItems));

                    if (existingItems && existingItems.length > 0) {
                        this.lineItems = existingItems.map(item => ({
                            key: this.generateId(),
                            id: item.Id,
                            name: item.Name || '',
                            molWeight: item.Mol_wt__c || null,
                            usedInBatch: item.Used_in_Batch_Kgs__c || null,
                            recovered: item.Recoverd__c || null,
                            consumed: item.Consumed_Kgs__c || null,
                            kgRmPerKgProduct: item.Kg_RM_Kg_product__c, // This comes from formula field
                            unitCostPerKg: item.Unit_Cost_Per_Kg__c || null,
                            costInBatch: item.Cost_in_Batch__c || null,
                            costPerKg: item.Cost_Per_Kg__c || null,
                            gmoles: item.Gmoles__c || null
                        }));
                        console.log('lineItems items:', JSON.stringify(this.lineItems));
                    } else {
                        this.addEmptyRow();
                    }
                })
                .catch(error => {
                    this.showError('Error loading data', error.body?.message || error.message);
                    this.addEmptyRow();
                })
                .finally(() => {
                    this.isLoading = false;
                });
        } else {
            this.addEmptyRow();
            this.isLoading = false;
        }
    }

    // Handler methods for each field
    handleNameChange(event) {
        const index = event.target.dataset.index;
        const value = event.detail.value;
        this.lineItems[index].name = value;
        this.lineItems = [...this.lineItems];
    }

    handleMolWeightChange(event) {
        const index = event.target.dataset.index;
        this.lineItems[index].molWeight = event.detail.value ? parseFloat(event.detail.value) : null;
        this.lineItems = [...this.lineItems];
        this.calculateDerivedFields(index);
    }

    handleUsedInBatchChange(event) {
        const index = event.target.dataset.index;
        this.lineItems[index].usedInBatch = event.detail.value ? parseFloat(event.detail.value) : null;
        this.lineItems = [...this.lineItems];
        this.calculateDerivedFields(index);
    }

    handleRecoveredChange(event) {
        const index = event.target.dataset.index;
        this.lineItems[index].recovered = event.detail.value ? parseFloat(event.detail.value) : null;
        this.lineItems = [...this.lineItems];
        this.calculateDerivedFields(index);
    }

    handleConsumedChange(event) {
        const index = event.target.dataset.index;
        const value = event.detail.value;
        this.lineItems[index].consumed = value ? parseFloat(value) : null;
        this.lineItems = [...this.lineItems];
        this.calculateDerivedFields(index);
    }

    handleUnitCostPerKgChange(event) {
        const index = event.target.dataset.index;
        this.lineItems[index].unitCostPerKg = event.detail.value ? parseFloat(event.detail.value) : null;
        this.lineItems = [...this.lineItems];
        this.calculateDerivedFields(index);
    }

    handleCostInBatchChange(event) {
        const index = event.target.dataset.index;
        const value = event.detail.value;
        this.lineItems[index].costInBatch = value ? parseFloat(value) : null;
        this.lineItems = [...this.lineItems];
    }

    handleCostPerKgChange(event) {
        const index = event.target.dataset.index;
        const value = event.detail.value;
        this.lineItems[index].costPerKg = value ? parseFloat(value) : null;
        this.lineItems = [...this.lineItems];
    }

    handleGmolesChange(event) {
        const index = event.target.dataset.index;
        const value = event.detail.value;
        this.lineItems[index].gmoles = value ? parseFloat(value) : null;
        this.lineItems = [...this.lineItems];
    }

    // Calculate derived fields for UI display only
    calculateDerivedFields(index) {
        const item = this.lineItems[index];

        // Consumed = Used in Batch - Recovered
        if (item.usedInBatch !== null && item.recovered !== null) {
            item.consumed = item.usedInBatch - item.recovered;
        }

        // Calculate Kg RM / Kg Product for UI display only
        // This matches the formula: Consumed_Kgs__c / New_Product_Development__r.Yield_and_RMC_change__c
        console.log('item.consumed', item.consumed + '  - ' + this.yieldAndRMCChange);

        if (item.consumed !== null && this.yieldAndRMCChange !== null && this.yieldAndRMCChange !== 0) {
            item.kgRmPerKgProduct = item.consumed / this.yieldAndRMCChange;
        } else {
            item.kgRmPerKgProduct = null;
        }

        // Cost in Batch = Consumed * Unit Cost Per Kg
        if (item.consumed !== null && item.unitCostPerKg !== null) {
            item.costInBatch = item.consumed * item.unitCostPerKg;
        } else {
            item.costInBatch = null;
        }

        // Cost Per Kg = Kg RM / Kg Product * Unit Cost Per Kg
        if (item.kgRmPerKgProduct !== null && item.unitCostPerKg !== null) {
            item.costPerKg = item.kgRmPerKgProduct * item.unitCostPerKg;
        } else {
            item.costPerKg = null;
        }

        // Gmoles = (Consumed * 1000) / Molecular Weight
        if (item.consumed !== null && item.molWeight !== null && item.molWeight !== 0) {
            item.gmoles = (item.consumed * 1000) / item.molWeight;
        } else {
            item.gmoles = null;
        }

        // Force reactive refresh
        this.lineItems = [...this.lineItems];
    }

    addEmptyRow() {
        this.lineItems = [...this.lineItems, {
            key: this.generateId(),
            id: null,
            name: '',
            molWeight: null,
            usedInBatch: null,
            recovered: null,
            consumed: null,
            kgRmPerKgProduct: null,
            unitCostPerKg: null,
            costInBatch: null,
            costPerKg: null,
            gmoles: null
        }];
    }

    handleAddItem() {
        this.addEmptyRow();
    }

    getDeleteButtonClass(index) {
        const item = this.lineItems[index];
        return item?.id ? '' : 'slds-hide';
    }

    handleDeleteItem(event) {
        const index = event.target.dataset.index;
        const item = this.lineItems[index];

        if (this.lineItems.length <= 1) {
            this.showError('Cannot delete', 'At least one item is required');
            return;
        }

        // If record has been saved (has an Id), delete from Salesforce
        if (item.id) {
            this.isLoading = true;
            deleteCostingItem({ costingItemId: item.id })
                .then(() => {
                    this.lineItems.splice(index, 1);
                    this.lineItems = [...this.lineItems];
                    this.showSuccess('Deleted', 'Costing item deleted successfully');
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
                name: item.name,
                molWeight: item.molWeight,
                usedInBatch: item.usedInBatch,
                recovered: item.recovered,
                consumed: item.consumed,
                // DO NOT include kgRmPerKgProduct as it's a formula field
                unitCostPerKg: item.unitCostPerKg,
                costInBatch: item.costInBatch,
                costPerKg: item.costPerKg,
                gmoles: item.gmoles
            }));

            saveCostingItems({
                recordId: this.recordId,
                costingItems: JSON.stringify(itemsToSave)
            })
                .then(() => {
                    this.showSuccess('Success', 'Costing items saved successfully');
                    this.navigateToNPDRecord(); // <--- Redirect after save
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
        this.navigateToNPDRecord();
    }

    navigateToNPDRecord() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'New_Product_Development__c',
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
            if (!item.name) {
                errorMessage = `Please enter a Name for row ${index + 1}`;
                isValid = false;
                return;
            }

            // Validate numeric fields
            const numericFields = [
                { field: item.molWeight, name: 'Molecular Weight' },
                { field: item.usedInBatch, name: 'Used in Batch' },
                { field: item.recovered, name: 'Recovered' },
                { field: item.consumed, name: 'Consumed' },
                { field: item.unitCostPerKg, name: 'Unit Cost Per Kg' },
                { field: item.costInBatch, name: 'Cost in Batch' },
                { field: item.costPerKg, name: 'Cost Per Kg' },
                { field: item.gmoles, name: 'Gmoles' }
            ];

            for (let numericField of numericFields) {
                if (numericField.field !== null && isNaN(numericField.field)) {
                    errorMessage = `Please enter a valid number for ${numericField.name} in row ${index + 1}`;
                    isValid = false;
                    return;
                }
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