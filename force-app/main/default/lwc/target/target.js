import { LightningElement, track } from 'lwc';
import getAllProducts from '@salesforce/apex/TargetController.getAllProducts';
import getExistingTargets from '@salesforce/apex/TargetController.getExistingTargets';
import saveTargets from '@salesforce/apex/TargetController.saveTargets';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPicklistValues from '@salesforce/apex/TargetController.getPicklistValues';

export default class TargetEntry extends LightningElement {
    @track selectedFY;
    @track selectedEmployee;
    @track showTable = false;

    @track tableData = [];

    @track monthOptions = [];  // <-- Add these
    @track yearOptions = [];   // <-- Add these

    connectedCallback() {
        this.loadPicklistValues();
    }

    async loadPicklistValues() {
        try {
            const result = await getPicklistValues();
            this.monthOptions = result.monthOptions;
            this.yearOptions = result.yearOptions;
        } catch (error) {
            this.showToast('Error', 'Failed to load picklist values', 'error');
            console.error(error);
        }
    }

    handleFYChange(event) {
        this.selectedFY = event.target.value;
        this.loadDataIfReady();
    }

    handleEmployeeChange(event) {
        this.selectedEmployee = event.target.value;
        this.loadDataIfReady();
    }

    async loadDataIfReady() {
        if (this.selectedFY && this.selectedEmployee) {
            try {
                const products = await getAllProducts();
                const existingTargets = await getExistingTargets({
                    fyId: this.selectedFY,
                    employeeId: this.selectedEmployee
                });

                const targetMap = new Map();
                existingTargets.forEach(t => targetMap.set(t.Product__c, t));

                this.tableData = products.map(prod => {
                    const existing = targetMap.get(prod.Id);
                    return {
                        id: existing ? existing.Id : `new-${prod.Id}`,
                        Product__c: prod.Id,
                        ProductName: prod.Name,
                        Month__c: existing ? existing.Month__c : '',
                        Year__c: existing ? existing.Year__c : '',
                        Quantity__c: existing ? existing.Quantity__c : 0,
                        Amount__c: existing ? existing.Amount__c : 0,
                        isModified: false  // add this flag here
                    };
                });


                this.showTable = true;
            } catch (error) {
                this.showToast('Error', 'Failed to load data', 'error');
                console.error(error);
            }
        } else {
            this.showTable = false;
            this.tableData = [];
        }
    }

    handleFieldChange(event) {
        const productId = event.target.dataset.id;
        const fieldName = event.target.dataset.field;
        const value = event.target.value;

        this.tableData = this.tableData.map(product => {
            if (product.id === productId) {
                return { ...product, [fieldName]: value, isModified: true };
            }
            return product;
        });
    }


    handleSaveClick() {
        const targetsToSave = this.tableData
            .filter(row => row.isModified)  // only modified
            .map(row => ({
                Id: row.id.startsWith('new-') ? null : row.id,
                FY__c: this.selectedFY,
                Sales_Employee__c: this.selectedEmployee,
                Product__c: row.Product__c,
                Month__c: row.Month__c,
                Year__c: row.Year__c,
                Quantity__c: row.Quantity__c,
                Amount__c: row.Amount__c
            }));

        if (targetsToSave.length === 0) {
            this.showToast('Info', 'No changes to save', 'info');
            return;
        }

        saveTargets({ targets: targetsToSave })
            .then(() => {
                this.showToast('Success', 'Targets saved successfully', 'success');
                this.loadDataIfReady(); // reload after save
            })
            .catch(error => {
                this.showToast('Error', error.body?.message || 'Error saving targets', 'error');
                console.error(error);
            });
    }


    handleCancel() {
        this.loadDataIfReady();
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}