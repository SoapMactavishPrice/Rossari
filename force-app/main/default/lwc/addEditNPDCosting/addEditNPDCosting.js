import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

// === NEW dynamic RT + oil&gas methods ===
import getRecordTypeOptions from '@salesforce/apex/NPDCostingController.getRecordTypeOptions';
import getOilGasCostingItems from '@salesforce/apex/NPDCostingController.getOilGasCostingItems';
import saveOilGasCostingItems from '@salesforce/apex/NPDCostingController.saveOilGasCostingItems';

// === ORIGINAL methods ===
import getExistingCostingItems from '@salesforce/apex/NPDCostingController.getExistingCostingItems';
import saveCostingItems from '@salesforce/apex/NPDCostingController.saveCostingItems';
import deleteCostingItem from '@salesforce/apex/NPDCostingController.deleteCostingItem';

export default class NpdCostingLineItems extends NavigationMixin(LightningElement) {
    @api recordId;

    // ===== Record type UI state =====
    @track recordTypeOptions = [];
    @track selectedRecordType = '';
    @track recordTypeSelected = false;
    @track isAgroNonAgro = false;
    @track isOilGas = false;

    @track isApplicationSelected = false;
    @track isSyntheticSelected = false;

    // ===== ORIGINAL state =====
    @track lineItems = [];
    @track isLoading = false;
    @track yieldAndRMCChange = 0;
    @track parentMolecularWeight = 0;
    @track deletedItemIds = [];

    // Parent extra fields
    @track yieldField = 0;
    @track manufacturingCost = 0;
    @track profitExpectedPerKg = 0;
    @track sellingPrice = 0;

    // NEW parent fields
    @track lossInBatch = 0;
    @track overheadsUtilityPackaging = 0;

    // Reference table
    @track referenceRows = [];

    // ===== Oil & Gas table state =====
    @track oilGasItems = [];

    // ===== NEW: Oil & Gas Additional Costing Fields (from parent object) =====
    @track oilGasExtra = {
        unitSizeLtr: 0,
        totalDrums: 0,
        unitSizeKg: 0,
        averageSG: 0, // Added Average SG rollup field
        rmCost: 0, // This will be calculated from Per_Kg__c
        oh: 0,
        packing: 0,
        palletizing: 0,
        margins: 0,
        fgPerKg: 0,
        costPerUnit: 0,
        pricePerUnit: 0,
        totalPrice: 0 // Added Total Price rollup field
    };

    // Constants
    UNIT_SIZE_KG = 50;

    // ---------- lifecycle ----------
    connectedCallback() {
        // get RT options first
        getRecordTypeOptions()
            .then(data => {
                this.recordTypeOptions = data.map(rt => ({
                    ...rt,
                    isSelected: rt.value === this.selectedRecordType
                }));
            })
            .catch(error => {
                this.showError('Error loading record types', error.body?.message);
            });
    }

    // handleRecordTypeChange(event) {
    //     this.selectedRecordType = event.target.value;

    //     // Refresh checked flags
    //     this.recordTypeOptions = this.recordTypeOptions.map(rt => ({
    //         ...rt,
    //         isSelected: rt.value === this.selectedRecordType
    //     }));
    // }

    handleRecordTypeChange(event) {
        const selectedValue = event.target.value;
        console.log('Selected record type:', selectedValue);

        this.selectedRecordType = selectedValue;
        this.recordTypeSelected = true;

        if (selectedValue === 'Application') {
            this.isOilGas = true;
            this.isAgroNonAgro = false;
            this.isApplicationSelected = true;
            this.isSyntheticSelected = false;
            this.loadOilGasData(); // ADDED THIS
        } else if (selectedValue === 'Synthesis') {
            this.isAgroNonAgro = true;
            this.isOilGas = false;
            this.isSyntheticSelected = true;
            this.isApplicationSelected = false;
            this.loadData(); // ADDED THIS
            this.addEmptyReferenceRow(); // ADDED THIS
        }
    }

    handleApplicationClick() {
        this.selectedRecordType = 'Application';
        this.navigateToRecordType();
    }

    handleSyntheticClick() {
        this.selectedRecordType = 'Synthesis';
        this.navigateToRecordType();
    }

    handleProceed() {
        if (!this.selectedRecordType) {
            this.showError('Select Record Type', 'Please choose a record type to continue.');
            return;
        }
        this.recordTypeSelected = true;
        this.isAgroNonAgro = this.selectedRecordType === 'Synthesis';
        this.isOilGas = this.selectedRecordType === 'Application';

        if (this.isAgroNonAgro) {
            this.loadData();
            this.addEmptyReferenceRow();
        } else if (this.isOilGas) {
            this.loadOilGasData();
        }
    }

    // =========================================================
    // ===============  YOUR ORIGINAL AGRO CODE  ===============
    // =========================================================

    loadData() {
        this.isLoading = true;

        if (this.recordId) {
            getExistingCostingItems({ recordId: this.recordId })
                .then(result => {
                    // Set parent fields from the result
                    this.parentMolecularWeight = result.parentMolecularWeight || 0;
                    this.yieldAndRMCChange = result.yieldAndRMCChange || 0;

                    // NEW fields only
                    this.lossInBatch = result.lossInBatch || 0;
                    this.overheadsUtilityPackaging = result.overheadsUtilityPackaging || 0;

                    // Additional parent fields
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

    handleLossInBatchChange(event) {
        this.lossInBatch = event.detail.value ? parseFloat(event.detail.value) : null;
        this.calculateManufacturingCost();
    }

    handleOverheadsUtilityPackagingChange(event) {
        this.overheadsUtilityPackaging = event.detail.value ? parseFloat(event.detail.value) : null;
        this.calculateManufacturingCost();
    }

    calculateManufacturingCost() {
        let totalRawMaterialCost = 0;
        this.lineItems.forEach(item => {
            if (item.costInBatch !== null && !isNaN(item.costInBatch)) {
                totalRawMaterialCost += item.costInBatch;
            }
        });

        let calculatedManufacturingCost = 0;

        if (totalRawMaterialCost !== 0 && this.yieldAndRMCChange !== null && this.yieldAndRMCChange !== 0) {
            const baseCost = (totalRawMaterialCost / this.yieldAndRMCChange) + (this.lossInBatch || 0);
            calculatedManufacturingCost = baseCost * (1 + ((this.overheadsUtilityPackaging || 0) / 100));
        }

        this.manufacturingCost = calculatedManufacturingCost.toFixed(2);
        this.calculateSellingPrice();
    }

    calculateSellingPrice() {
        if (this.manufacturingCost && this.profitExpectedPerKg !== null) {
            const manufacturingCostNum = parseFloat(this.manufacturingCost);
            const profitNum = this.profitExpectedPerKg || 0;
            this.sellingPrice = (manufacturingCostNum + profitNum).toFixed(2);
        } else {
            this.sellingPrice = '0.00';
        }
    }

    handleYieldAndRMCChange(event) {
        this.yieldAndRMCChange = event.detail.value ? parseFloat(event.detail.value) : null;
        this.recalculateAllDerivedFields();
        this.calculateManufacturingCost();
    }

    handleProfitExpectedPerKgChange(event) {
        this.profitExpectedPerKg = event.detail.value ? parseFloat(event.detail.value) : null;
        this.referenceRows.forEach((row, index) => {
            this.calculateReferenceRow(index);
        });
        this.calculateSellingPrice();
    }

    calculateDerivedFields(index) {
        const item = this.lineItems[index];

        if (item.usedInBatch !== null && item.recovered !== null) {
            item.consumed = item.usedInBatch - item.recovered;
        }

        if (item.consumed !== null && this.yieldAndRMCChange !== null && this.yieldAndRMCChange !== 0) {
            item.kgRmPerKgProduct = item.consumed / this.yieldAndRMCChange;
        } else {
            item.kgRmPerKgProduct = null;
        }

        if (item.consumed !== null && item.unitCostPerKg !== null) {
            item.costInBatch = item.consumed * item.unitCostPerKg;
        } else {
            item.costInBatch = null;
        }

        if (item.kgRmPerKgProduct !== null && item.unitCostPerKg !== null) {
            item.costPerKg = item.kgRmPerKgProduct * item.unitCostPerKg;
        } else {
            item.costPerKg = null;
        }

        const molecularWeight = item.molWeight !== null ? item.molWeight : this.parentMolecularWeight;
        if (item.consumed !== null && molecularWeight !== null && molecularWeight !== 0) {
            item.gmoles = (item.consumed * 1000) / molecularWeight;
        } else {
            item.gmoles = null;
        }

        this.lineItems = [...this.lineItems];
        this.calculateManufacturingCost();
    }

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

        if (row.rmc !== null) {
            row.cost = row.rmc * 1.15;
        } else {
            row.cost = null;
        }

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

    getShowDeleteReferenceButton(index) {
        return index !== this.referenceRows.length - 1;
    }

    handleUseForYieldCalcChange(event) {
        const index = event.target.dataset.index;
        this.lineItems[index].useForYieldCalc = event.detail.checked;
        this.lineItems = [...this.lineItems];
    }

    handleParentMolecularWeightChange(event) {
        this.parentMolecularWeight = event.detail.value ? parseFloat(event.detail.value) : null;
        this.recalculateAllDerivedFields();
    }

    recalculateAllDerivedFields() {
        this.lineItems.forEach((item, index) => {
            this.calculateDerivedFields(index);
        });
    }

    handleNameChange(event) {
        const index = event.target.dataset.index;
        this.lineItems[index].name = event.detail.value;
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
        this.calculateManufacturingCost();
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
        if (!originalItem) return;

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
        if (item.id) this.deletedItemIds.push(item.id);
        this.lineItems.splice(index, 1);
        this.lineItems = [...this.lineItems];
        this.calculateManufacturingCost();
    }

    handleSaveAndRefresh() {
        if (this.isOilGas) {
            this.saveOilGas(false);
        } else {
            this.saveData(false);
        }
    }

    handleSaveAndExit() {
        if (this.isOilGas) {
            this.saveOilGas(true);
        } else {
            this.saveData(true);
        }
    }


    // ===== Validation Methods for Required Fields Only =====
    validateOilGasForm() {
        let isValid = true;
        let errorMessage = '';

        // Validate Unit Size Ltr - required and must be greater than 0
        if (!this.oilGasExtra.unitSizeLtr || this.oilGasExtra.unitSizeLtr <= 0) {
            errorMessage = 'Unit Size Ltr is required and must be greater than 0';
            isValid = false;
        }

        // Validate Total Drums - required and must be greater than 0
        if (!this.oilGasExtra.totalDrums || this.oilGasExtra.totalDrums <= 0) {
            errorMessage = 'Total Drums is required and must be greater than 0';
            isValid = false;
        }

        // Validate Name in each row - required
        this.oilGasItems.forEach((item, index) => {
            if (!isValid) return; // Skip if already invalid

            if (!item.name || item.name.trim() === '') {
                errorMessage = `Product Name is required for row ${index + 1}`;
                isValid = false;
                return;
            }
        });

        if (!isValid) {
            this.showError('Validation Error', errorMessage);
        }

        return isValid;
    }

    // ===== Validation Methods for Agro & Non-Agro Section =====
    validateAgroForm() {
        let isValid = true;
        let errorMessage = '';

        // Validate Mol Weight of the Product - required
        if (!this.parentMolecularWeight || this.parentMolecularWeight <= 0) {
            errorMessage = 'Mol Weight of the Product is required and must be greater than 0';
            isValid = false;
        }

        // Validate Yield and RMC Change - required
        if (!this.yieldAndRMCChange || this.yieldAndRMCChange <= 0) {
            errorMessage = 'Yield and RMC Change is required and must be greater than 0';
            isValid = false;
        }

        // Validate Overheads Utility Packaging % - required
        if (this.overheadsUtilityPackaging === null || this.overheadsUtilityPackaging === undefined || this.overheadsUtilityPackaging < 0) {
            errorMessage = 'Overheads Utility Packaging % is required and must be 0 or greater';
            isValid = false;
        }

        // Validate Name in each row - required (USE lineItems FOR AGRO)
        this.lineItems.forEach((item, index) => {
            if (!isValid) return; // Skip if already invalid

            if (!item.name || item.name.trim() === '') {
                errorMessage = `Product Name is required for row ${index + 1}`;
                isValid = false;
                return;
            }
        });

        if (!isValid) {
            this.showError('Validation Error', errorMessage);
        }

        return isValid;
    }

    saveData(shouldNavigateAway) {
        // Validate Agro form before saving
        if (!this.validateAgroForm()) {
            return;
        }

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

        saveCostingItems({
            recordId: this.recordId,
            costingItems: JSON.stringify(itemsToSave),
            molecularWeight: this.parentMolecularWeight,
            yieldAndRMCChange: this.yieldAndRMCChange,
            profitExpectedPerKg: this.profitExpectedPerKg,
            lossInBatch: this.lossInBatch,
            overheadsUtilityPackaging: this.overheadsUtilityPackaging
        })
            .then(() => {
                if (this.deletedItemIds.length > 0) {
                    return Promise.all(
                        this.deletedItemIds.map(id => deleteCostingItem({ costingItemId: id }))
                    );
                }
            })
            .then(() => {
                this.showSuccess('Success', 'Records Saved successfully');
                this.deletedItemIds = [];
                if (shouldNavigateAway) this.navigateToNPDRecord();
                else this.refreshCurrentPage();
            })
            .catch(error => {
                this.showError('Save Failed', error.body?.message || error.message);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    // ===== UPDATED: Oil & Gas save with validation =====
    saveOilGas(exitAfter) {
        // Validate form before saving
        if (!this.validateOilGasForm()) {
            return;
        }

        console.log('Current oilGasItems:', JSON.parse(JSON.stringify(this.oilGasItems)));

        const payload = JSON.stringify(this.oilGasItems.map(i => {
            const calculatedTotalPrice = i.totalKg * i.costKg || 0;

            console.log(`Item ${i.name}: totalKg=${i.totalKg}, costKg=${i.costKg}, totalPrice=${i.totalPrice}, calculated=${calculatedTotalPrice}`);

            return {
                Id: i.id,
                Name: i.name,
                SG__c: i.sg,
                Component__c: i.component,
                Cost_Kg__c: i.costKg,
                Kg_Drum__c: i.kgDrum,
                Liter_Drum__c: i.litreDrum,
                For_Total_Drum__c: i.forTotalDrum,
                Loss__c: i.loss,
                Total_KG__c: i.totalKg,
                Total_Price_1__c: calculatedTotalPrice
            };
        }));

        console.log('Final payload being sent:', payload);

        this.isLoading = true;

        saveOilGasCostingItems({
            recordId: this.recordId,
            oilGasItems: payload,
            unitSizeLtr: this.oilGasExtra.unitSizeLtr,
            totalDrums: this.oilGasExtra.totalDrums,
            oh: this.oilGasExtra.oh,
            packing: this.oilGasExtra.packing,
            palletizing: this.oilGasExtra.palletizing,
            margins: this.oilGasExtra.margins
        })
            .then(() => {
                this.showSuccess('Success', 'Oil & Gas records saved');
                this.deletedItemIds = [];

                if (exitAfter) {
                    this.navigateToNPDRecord();
                } else {
                    setTimeout(() => {
                        window.location.reload();
                    }, 1000);
                }
            })
            .catch(e => {
                console.error('Save error:', e);
                this.showError('Save failed', e.body?.message || e.message);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

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
        setTimeout(() => { window.location.reload(); }, 1000);
    }

    validateForm() {
        if (!this.isAgroNonAgro) return true;

        let isValid = true;
        let errorMessage = '';

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

        if (this.lossInBatch !== null && isNaN(this.lossInBatch)) {
            errorMessage = 'Please enter a valid number for Loss in Batch';
            isValid = false;
        }

        if (this.overheadsUtilityPackaging !== null && isNaN(this.overheadsUtilityPackaging)) {
            errorMessage = 'Please enter a valid number for Overheads Utility Packaging %';
            isValid = false;
        }

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
            for (let nf of numericFields) {
                if (nf.field !== null && isNaN(nf.field)) {
                    errorMessage = `Please enter a valid number for ${nf.name} in row ${index + 1}`;
                    isValid = false;
                    return;
                }
            }
        });

        if (!isValid) this.showError('Validation Error', errorMessage);
        return isValid;
    }

    // ===== UPDATED: loadOilGasData to calculate values on load =====
    loadOilGasData() {
        this.isLoading = true;

        getOilGasCostingItems({ recordId: this.recordId })
            .then(result => {
                console.log('Oil & Gas data loaded:', result);
                if (result) {
                    // Reset oilGasItems first
                    this.oilGasItems = [];

                    // Load parent NPD data
                    if (result.npdRecord) {
                        this.oilGasExtra = {
                            ...this.oilGasExtra,
                            unitSizeLtr: result.npdRecord.Unit_Size_Ltr__c || 0,
                            totalDrums: result.npdRecord.Total_Drums__c || 0,
                            unitSizeKg: result.npdRecord.Unit_Size_Kg__c || 0,
                            averageSG: result.npdRecord.Average_SG__c || 0,
                            rmCost: result.npdRecord.RM_Cost__c || 0,
                            oh: result.npdRecord.OH__c || 0,
                            packing: result.npdRecord.Packing__c || 0,
                            palletizing: result.npdRecord.Palletizing__c || 0,
                            margins: result.npdRecord.Margins__c || 0,
                            fgPerKg: result.npdRecord.FG_Per_KG__c || 0,
                            costPerUnit: result.npdRecord.Cost_per_Unit__c || 0,
                            pricePerUnit: result.npdRecord.Price_Per_Unit__c || 0,
                            totalPrice: result.npdRecord.Total_Price__c || 0
                        };
                    }

                    if (result.costingItems && result.costingItems.length) {
                        this.oilGasItems = result.costingItems.map(r => ({
                            key: this.generateId(),
                            id: r.Id,
                            name: r.Name,
                            sg: r.SG__c || 0,
                            component: r.Component__c || 0,
                            costKg: r.Cost_Kg__c || 0,
                            kgDrum: r.Kg_Drum__c || 0,
                            litreDrum: r.Liter_Drum__c || 0,
                            forTotalDrum: r.For_Total_Drum__c || 0,
                            loss: r.Loss__c || 0,
                            totalKg: r.Total_KG__c || 0,
                            totalPrice: r.Total_Price_1__c || 0
                        }));

                        // Recalculate all line items after loading
                        this.oilGasItems.forEach((row, index) => {
                            this.calcOilGasRow(index);
                        });
                    } else {
                        this.addOilGasRow();
                    }

                    // Calculate all values after loading data
                    this.calculateAverageSG();
                    this.calculateAllOilGasValues();
                }
            })
            .catch(e => {
                console.error('Error loading Oil & Gas:', e);
                this.showError('Error loading Oil & Gas', e.body?.message || e.message);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    addOilGasRow() {
        this.oilGasItems = [...this.oilGasItems, {
            key: this.generateId(),
            id: null,
            name: '',
            sg: 0,
            component: 0,
            costKg: 0,
            kgDrum: 0,
            litreDrum: 0,
            forTotalDrum: 0,
            loss: 0,
            totalKg: 0,
            totalPrice: 0
        }];
    }

    calculateAverageSG() {
        let totalWeightedSG = 0;
        let totalComponent = 0;

        this.oilGasItems.forEach(item => {
            if (item.sg && !isNaN(item.sg) && item.sg > 0 && item.component && !isNaN(item.component)) {
                totalWeightedSG += (parseFloat(item.sg) * parseFloat(item.component));
                totalComponent += parseFloat(item.component);
            }
        });

        if (totalComponent > 0) {
            this.oilGasExtra.averageSG = totalWeightedSG / totalComponent;
        } else {
            this.oilGasExtra.averageSG = 0;
        }

        console.log('Weighted Average SG calculated:', this.oilGasExtra.averageSG,
            'from totalWeightedSG:', totalWeightedSG, 'totalComponent:', totalComponent);
    }

    // ===== UPDATED: Calculate Total Price from line items =====
    calculateTotalPrice() {
        let totalPrice = 0;

        this.oilGasItems.forEach(item => {
            if (item.totalPrice && !isNaN(item.totalPrice)) {
                totalPrice += parseFloat(item.totalPrice);
            }
        });

        this.oilGasExtra.totalPrice = totalPrice;
        console.log('Total Price calculated:', this.oilGasExtra.totalPrice, 'from items:', this.oilGasItems.map(i => i.totalPrice));

        // Force reactive update
        this.oilGasExtra = { ...this.oilGasExtra };
    }

    // ===== UPDATED: Oil & Gas field handlers to include real-time calculations =====
    handleOilGasSGChange(e) {
        this.updateOilGasField(e, 'sg', true);
        this.calculateAverageSG();
        this.calculateAllOilGasValues();
    }

    handleOilGasComponentChange(e) {
        this.updateOilGasField(e, 'component', true);
        this.calculateAverageSG();
        this.calculateAllOilGasValues();
    }

    handleOilGasCostChange(e) {
        this.updateOilGasField(e, 'costKg', true);
        this.calculateAllOilGasValues();
    }

    handleOilGasLossChange(e) {
        this.updateOilGasField(e, 'loss', true);
        this.calculateAllOilGasValues();
    }

    handleOilGasNameChange(e) {
        this.updateOilGasField(e, 'name', false);
    }

    updateOilGasField(event, field, recalc) {
        const i = event.target.dataset.index;
        let val = event.detail.value;
        if (field !== 'name') val = parseFloat(val) || 0;
        this.oilGasItems[i][field] = val;
        if (recalc) this.calcOilGasRow(i);
        this.oilGasItems = [...this.oilGasItems];
    }

    calculateAllOilGasValues() {
        console.log('Calculating all Oil & Gas values...');

        // First calculate Unit Size Kg if needed
        if (this.oilGasExtra.unitSizeLtr && this.oilGasExtra.averageSG) {
            this.oilGasExtra.unitSizeKg = this.oilGasExtra.unitSizeLtr * this.oilGasExtra.averageSG;
        }

        // FG Per KG = RM Cost + Packing + Palletizing + OH
        this.oilGasExtra.fgPerKg = (this.oilGasExtra.rmCost || 0) +
            (this.oilGasExtra.packing || 0) +
            (this.oilGasExtra.palletizing || 0) +
            (this.oilGasExtra.oh || 0);

        // Cost per Unit = FG Per KG * Unit Size (Kg)
        this.oilGasExtra.costPerUnit = (this.oilGasExtra.fgPerKg || 0) * (this.oilGasExtra.unitSizeKg || 0);

        // Price Per Unit = Cost per Unit / (1 - Margins/100)
        if (this.oilGasExtra.margins !== null && this.oilGasExtra.margins < 100) {
            this.oilGasExtra.pricePerUnit = (this.oilGasExtra.costPerUnit || 0) / (1 - ((this.oilGasExtra.margins || 0) / 100));
        } else {
            this.oilGasExtra.pricePerUnit = this.oilGasExtra.costPerUnit || 0;
        }

        console.log('Calculated values:', {
            averageSG: this.oilGasExtra.averageSG,
            unitSizeKg: this.oilGasExtra.unitSizeKg,
            rmCost: this.oilGasExtra.rmCost,
            fgPerKg: this.oilGasExtra.fgPerKg,
            costPerUnit: this.oilGasExtra.costPerUnit,
            pricePerUnit: this.oilGasExtra.pricePerUnit
        });

        // Force reactive update
        this.oilGasExtra = { ...this.oilGasExtra };
    }

    calcOilGasRow(i) {
        const row = this.oilGasItems[i];

        // Calculate all values
        row.kgDrum = (this.oilGasExtra.unitSizeKg || 0) * ((row.component || 0) / 100);
        row.litreDrum = (row.kgDrum || 0) / ((row.sg || 0) !== 0 ? row.sg : 1);
        row.forTotalDrum = (row.kgDrum || 0) * (this.oilGasExtra.totalDrums || 0);
        row.totalKg = (row.forTotalDrum || 0) + ((row.forTotalDrum || 0) * ((row.loss || 0) / 100));

        // Calculate totalPrice
        row.totalPrice = (row.totalKg || 0) * (row.costKg || 0);

        console.log(`Calculated row ${i}:`, {
            kgDrum: row.kgDrum,
            litreDrum: row.litreDrum,
            forTotalDrum: row.forTotalDrum,
            totalKg: row.totalKg,
            totalPrice: row.totalPrice
        });

        this.oilGasItems = [...this.oilGasItems];

        // Calculate the header total price after row update
        this.calculateTotalPrice();

        // Trigger additional costing calculations after row update
        this.calculateAllOilGasValues();
    }

    handleAddOilGasItem(e) {
        const idx = parseInt(e.target.dataset.index, 10);
        const newRow = { ...this.oilGasItems[idx], key: this.generateId(), id: null, name: '' };
        this.oilGasItems.splice(idx + 1, 0, newRow);
        this.oilGasItems = [...this.oilGasItems];

        // Calculate total price after adding new row
        this.calculateTotalPrice();
    }

    // ===== UPDATED: handleDeleteOilGasItem to include calculations =====
    handleDeleteOilGasItem(e) {
        const idx = parseInt(e.target.dataset.index, 10);
        if (this.oilGasItems.length > 1) {
            this.oilGasItems.splice(idx, 1);
            this.oilGasItems = [...this.oilGasItems];

            // Recalculate after deleting row
            this.calculateAverageSG();
            this.calculateTotalPrice();
            this.calculateAllOilGasValues();
        }
    }

    // ===== UPDATED: Additional Costing Fields Handlers =====
    handleOHChange(event) {
        this.oilGasExtra.oh = event.detail.value ? parseFloat(event.detail.value) : 0;
        this.calculateAllOilGasValues();
    }

    handlePackingChange(event) {
        this.oilGasExtra.packing = event.detail.value ? parseFloat(event.detail.value) : 0;
        this.calculateAllOilGasValues();
    }

    handlePalletizingChange(event) {
        this.oilGasExtra.palletizing = event.detail.value ? parseFloat(event.detail.value) : 0;
        this.calculateAllOilGasValues();
    }

    handleMarginsChange(event) {
        this.oilGasExtra.margins = event.detail.value ? parseFloat(event.detail.value) : 0;
        this.calculateAllOilGasValues();
    }

    handleUnitSizeLtrChange(event) {
        this.oilGasExtra.unitSizeLtr = event.detail.value ? parseFloat(event.detail.value) : 0;
        this.calculateUnitSizeKg();
        // Recalculate all line items when unit size changes
        this.oilGasItems.forEach((row, index) => {
            this.calcOilGasRow(index);
        });
        this.calculateAllOilGasValues();
    }

    calculateUnitSizeKg() {
        // Unit Size Kg = Unit Size Ltr * Average SG
        this.oilGasExtra.unitSizeKg = (this.oilGasExtra.unitSizeLtr || 0) * (this.oilGasExtra.averageSG || 1);
        console.log('Unit Size Kg calculated:', this.oilGasExtra.unitSizeKg);
        this.oilGasExtra = { ...this.oilGasExtra };
    }

    handleTotalDrumsChange(event) {
        this.oilGasExtra.totalDrums = event.detail.value ? parseFloat(event.detail.value) : 0;
        // Recalculate all line items when total drums change
        this.oilGasItems.forEach((row, index) => {
            this.calcOilGasRow(index);
        });
        this.calculateAllOilGasValues();
    }

    // ---------- helpers ----------
    generateId() {
        return Math.random().toString(36).substring(2, 15);
    }

    showSuccess(title, message) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant: 'success' }));
    }

    showError(title, message) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant: 'error' }));
    }
}