import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getExistingCostingItems from '@salesforce/apex/NPDCostingController.getExistingCostingItems';
import saveCostingItems from '@salesforce/apex/NPDCostingController.saveCostingItems';
import deleteCostingItem from '@salesforce/apex/NPDCostingController.deleteCostingItem';

export default class NpdCostingLineItems extends NavigationMixin(LightningElement) {
    @api recordId; // New_Product_Development__c record Id
    @track lineItems = [];
    @track isLoading = false;
    @track yieldAndRMCChange = 0;
    @track parentMolecularWeight = 0;
    @track deletedItemIds = [];

    // New fields for additional parent object fields
    @track yieldField = 0;
    @track manufacturingCost = 0;
    @track profitExpectedPerKg = 0;
    @track sellingPrice = 0;

    // Reference table properties
    @track referenceRows = [];

    connectedCallback() {
        this.loadData();
        this.addEmptyReferenceRow(); // Start with one empty row
    }

    loadData() {
        this.isLoading = true;

        if (this.recordId) {
            getExistingCostingItems({ recordId: this.recordId })
                .then(result => {
                    console.log('Full result:', JSON.stringify(result));

                    // Set parent fields from the result
                    this.parentMolecularWeight = result.parentMolecularWeight || 0;
                    this.yieldAndRMCChange = result.yieldAndRMCChange || 0;

                    // Set additional parent fields
                    this.yieldField = result.yieldField || 0;
                    this.manufacturingCost = result.manufacturingCost || 0;
                    this.profitExpectedPerKg = result.profitExpectedPerKg || 0;
                    this.sellingPrice = result.sellingPrice || 0;

                    const existingItems = result.costingItems;

                    if (existingItems && existingItems.length > 0) {
                        this.lineItems = existingItems.map(item => ({
                            key: this.generateId(),
                            id: item.Id,
                            name: item.Name || '',
                            molWeight: item.Mol_wt__c || null,
                            usedInBatch: item.Used_in_Batch_Kgs__c || null,
                            recovered: item.Recoverd__c || null,
                            consumed: item.Consumed_Kgs__c || null,
                            kgRmPerKgProduct: item.Kg_RM_Kg_Product__c,
                            unitCostPerKg: item.Unit_Cost_Per_Kg__c || null,
                            costInBatch: item.Cost_in_Batch__c || null,
                            costPerKg: item.Cost_Per_Kg__c || null,
                            gmoles: item.Gmoles__c || null,
                            useForYieldCalc: item.Use_for_Yield_Calc__c || false
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

    // Reference table methods
    addEmptyReferenceRow() {
        const newRow = {
            key: this.generateId(),
            molarYield: null,
            rmc: null,
            cost: null,
            sellingPrice: null
        };
        this.referenceRows = [...this.referenceRows, newRow];
        this.updateDeleteButtonVisibility();
    }

    updateDeleteButtonVisibility() {
        const total = this.referenceRows.length;
        this.referenceRows = this.referenceRows.map((row, index) => {
            return {
                ...row,
                shouldShowDeleteButton: total > 1 && index !== total - 1
            };
        });
    }


    handleMolarYieldChange(event) {
        const index = event.target.dataset.index;
        this.referenceRows[index].molarYield = event.detail.value ? parseFloat(event.detail.value) : null;
        this.calculateReferenceRow(index);
    }

    handleRMCChange(event) {
        const index = event.target.dataset.index;
        this.referenceRows[index].rmc = event.detail.value ? parseFloat(event.detail.value) : null;
        this.calculateReferenceRow(index);
    }

    calculateReferenceRow(index) {
        const row = this.referenceRows[index];

        // Cost = RMC * (1 + 0.15) = RMC * 1.15
        if (row.rmc !== null) {
            row.cost = row.rmc * 1.15;
        } else {
            row.cost = null;
        }

        // Selling Price = Cost + Profit Expected Per Kg
        if (row.cost !== null && this.profitExpectedPerKg !== null) {
            row.sellingPrice = row.cost + this.profitExpectedPerKg;
        } else {
            row.sellingPrice = null;
        }

        this.referenceRows = [...this.referenceRows];
    }

    handleAddReferenceRow() {
        this.addEmptyReferenceRow();
    }

    handleDeleteReferenceRow(event) {
        const index = event.target.dataset.index;
        if (this.referenceRows.length > 1) {
            this.referenceRows.splice(index, 1);
            this.referenceRows = [...this.referenceRows];
            this.updateDeleteButtonVisibility();
        }
    }


    // Method to determine if delete button should be shown for reference rows
    getShowDeleteReferenceButton(index) {
        return index !== this.referenceRows.length - 1;
    }

    // Handler for Use for Yield Calc checkbox
    handleUseForYieldCalcChange(event) {
        const index = event.target.dataset.index;
        this.lineItems[index].useForYieldCalc = event.detail.checked;
        this.lineItems = [...this.lineItems];
    }

    // Parent field handlers
    handleParentMolecularWeightChange(event) {
        this.parentMolecularWeight = event.detail.value ? parseFloat(event.detail.value) : null;
        this.recalculateAllDerivedFields();
    }

    handleYieldAndRMCChange(event) {
        this.yieldAndRMCChange = event.detail.value ? parseFloat(event.detail.value) : null;
        this.recalculateAllDerivedFields();
    }

    handleProfitExpectedPerKgChange(event) {
        this.profitExpectedPerKg = event.detail.value ? parseFloat(event.detail.value) : null;
        // Recalculate all reference rows when profit changes
        this.referenceRows.forEach((row, index) => {
            this.calculateReferenceRow(index);
        });
    }

    // Recalculate all derived fields when parent fields change
    recalculateAllDerivedFields() {
        this.lineItems.forEach((item, index) => {
            this.calculateDerivedFields(index);
        });
    }

    // Line item handlers
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
        const molecularWeight = item.molWeight !== null ? item.molWeight : this.parentMolecularWeight;
        if (item.consumed !== null && molecularWeight !== null && molecularWeight !== 0) {
            item.gmoles = (item.consumed * 1000) / molecularWeight;
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
            gmoles: null,
            useForYieldCalc: false
        }];
    }

    handleAddItem(event) {
        const index = parseInt(event.target.dataset.index, 10);
        const originalItem = this.lineItems[index];

        if (!originalItem) {
            console.error('Item not found for index:', index);
            return;
        }

        const newItem = {
            ...originalItem,
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
            gmoles: null,
            useForYieldCalc: false
        };

        const originalIndex = this.lineItems.findIndex(item => item.key === originalItem.key);
        this.lineItems.splice(originalIndex + 1, 0, newItem);
        this.lineItems = [...this.lineItems];
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

        // If record has been saved, track its ID for deletion on save
        if (item.id) {
            this.deletedItemIds.push(item.id);
        }

        // Remove from UI
        this.lineItems.splice(index, 1);
        this.lineItems = [...this.lineItems];
    }

    // Save and Refresh - Stay on the same page and reload data
    handleSaveAndRefresh() {
        this.saveData(false);
    }

    // Save and Exit - Save and redirect to NPD record
    handleSaveAndExit() {
        this.saveData(true);
    }

    // Common save method with navigation flag
    saveData(shouldNavigateAway) {
        if (this.validateForm()) {
            this.isLoading = true;

            const itemsToSave = this.lineItems.map(item => ({
                id: item.id || null,
                name: item.name,
                molWeight: item.molWeight,
                usedInBatch: item.usedInBatch,
                recovered: item.recovered,
                consumed: item.consumed,
                unitCostPerKg: item.unitCostPerKg,
                costInBatch: item.costInBatch,
                costPerKg: item.costPerKg,
                gmoles: item.gmoles,
                useForYieldCalc: item.useForYieldCalc
            }));

            // 1. Call Apex method to save items AND parent fields
            saveCostingItems({
                recordId: this.recordId,
                costingItems: JSON.stringify(itemsToSave),
                molecularWeight: this.parentMolecularWeight,
                yieldAndRMCChange: this.yieldAndRMCChange,
                profitExpectedPerKg: this.profitExpectedPerKg
            })
                .then(() => {
                    // 2. After saving items, delete the marked ones
                    if (this.deletedItemIds.length > 0) {
                        return Promise.all(
                            this.deletedItemIds.map(id => deleteCostingItem({ costingItemId: id }))
                        );
                    }
                })
                .then(() => {
                    this.showSuccess('Success', 'Records Saved successfully');
                    this.deletedItemIds = [];

                    if (shouldNavigateAway) {
                        this.navigateToNPDRecord();
                    } else {
                        this.refreshCurrentPage();
                    }
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

    // Refresh current page without navigation
    refreshCurrentPage() {
        setTimeout(() => {
            window.location.reload();
        }, 1000);
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

        // Validate parent fields
        if (this.parentMolecularWeight !== null && isNaN(this.parentMolecularWeight)) {
            errorMessage = 'Please enter a valid number for Molecular Weight of the Product';
            isValid = false;
        }

        if (this.yieldAndRMCChange !== null && isNaN(this.yieldAndRMCChange)) {
            errorMessage = 'Please enter a valid number for Yield and RMC Change';
            isValid = false;
        }

        if (this.profitExpectedPerKg !== null && isNaN(this.profitExpectedPerKg)) {
            errorMessage = 'Please enter a valid number for Profit Expected Per Kg';
            isValid = false;
        }

        // Validate line items
        this.lineItems.forEach((item, index) => {
            if (!item.name) {
                errorMessage = `Please enter a Name for row ${index + 1}`;
                isValid = false;
                return;
            }

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