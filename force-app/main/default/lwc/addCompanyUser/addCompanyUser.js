import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

import getUsers from '@salesforce/apex/CompanyUserController.getUsers';
import getCompanyUsers from '@salesforce/apex/CompanyUserController.getCompanyUsers';
import saveCompanyUsers from '@salesforce/apex/CompanyUserController.saveCompanyUsers';

export default class AddCompanyUser extends NavigationMixin(LightningElement) {
    @track showSpinner = false;
    @track companyUsers = [];
    @track userOptions = [];

    deletedRecordIds = [];
    _recordId;

    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
        if (value) {
            this.initializeData();
        }
    }

    async initializeData() {
        this.showSpinner = true;
        try {
            const [users, existingRecords] = await Promise.all([
                getUsers(),
                getCompanyUsers({ companyId: this._recordId })
            ]);

            this.userOptions = users.map(u => ({ label: u.Name, value: u.Id }));

            if (existingRecords && existingRecords.length > 0) {
                this.companyUsers = existingRecords.map(rec => ({
                    id: rec.Id,
                    User__c: rec.User__c,
                    Business_Unit__c: rec.Business_Unit__c,
                    Division__c: rec.Division__c,
                    Product_Group__c: rec.Product_Group__c,
                    divisionFilter: {},
                    productGroupFilter: {}
                }));
            } else {
                this.companyUsers = [{
                    id: this.generateId(),
                    User__c: '',
                    Business_Unit__c: '',
                    Division__c: '',
                    Product_Group__c: '',
                    divisionFilter: {},
                    productGroupFilter: {}
                }];
            }

            this.updateFilters();

        } catch (error) {
            this.showError(error);
        } finally {
            this.showSpinner = false;
        }
    }

    generateId() {
        return Math.random().toString(36).substring(2, 15);
    }

    updateFilters() {
        this.companyUsers = this.companyUsers.map((user, index) => {
            let divisionFilter = {};
            let productGroupFilter = {};

            if (user.Business_Unit__c) {
                divisionFilter = { plantId: user.Business_Unit__c };
            }

            if (user.Business_Unit__c && user.Division__c) {
                productGroupFilter = {
                    plantId: user.Business_Unit__c,
                    divisionId: user.Division__c
                };
            }

            // Update the lookup components with new filters
            setTimeout(() => {
                const divisionLookup = this.template.querySelector(`[data-index="${index}"][data-field="Division__c"]`);
                const productGroupLookup = this.template.querySelector(`[data-index="${index}"][data-field="Product_Group__c"]`);

                if (divisionLookup) {
                    divisionLookup.updateFilterParams(divisionFilter);
                }
                if (productGroupLookup) {
                    productGroupLookup.updateFilterParams(productGroupFilter);
                }
            }, 0);

            return {
                ...user,
                divisionFilter,
                productGroupFilter
            };
        });
    }

    handleLookupChange(event) {
        const index = parseInt(event.target.dataset.index, 10);
        const field = event.target.dataset.field;
        const value = event.detail.value;
        const oldValue = this.companyUsers[index][field];

        this.companyUsers = this.companyUsers.map((row, i) => {
            if (i === index) {
                const updatedRow = { ...row, [field]: value };

                // Clear dependent fields when parent field changes or is cleared
                if (field === 'Business_Unit__c') {
                    // If Business Unit is cleared or changed
                    if (!value || value !== oldValue) {
                        updatedRow.Division__c = '';
                        updatedRow.Product_Group__c = '';

                        // Reset filters
                        updatedRow.divisionFilter = {};
                        updatedRow.productGroupFilter = {};

                        // Clear the dependent lookup components
                        this.clearDependentLookups(index, ['Division__c', 'Product_Group__c']);
                    } else {
                        // Business Unit is set, update division filter
                        updatedRow.divisionFilter = { plantId: value };
                    }
                } else if (field === 'Division__c') {
                    // If Division is cleared or changed
                    if (!value || value !== oldValue) {
                        updatedRow.Product_Group__c = '';
                        updatedRow.productGroupFilter = {};

                        // Clear the product group lookup
                        this.clearDependentLookups(index, ['Product_Group__c']);
                    } else if (row.Business_Unit__c) {
                        // Division is set and Business Unit exists, update product group filter
                        updatedRow.productGroupFilter = {
                            plantId: row.Business_Unit__c,
                            divisionId: value
                        };
                    }
                }

                return updatedRow;
            }
            return row;
        });

        this.updateFilters();
    }

    // Helper method to clear dependent lookup components
    clearDependentLookups(index, fields) {
        setTimeout(() => {
            fields.forEach(field => {
                const lookupComponent = this.template.querySelector(`[data-index="${index}"][data-field="${field}"]`);
                if (lookupComponent) {
                    lookupComponent.clearSelection();
                }
            });
        }, 0);
    }

    addNewRow() {
        this.companyUsers = [...this.companyUsers, {
            id: this.generateId(),
            User__c: '',
            Business_Unit__c: '',
            Division__c: '',
            Product_Group__c: '',
            divisionFilter: {},
            productGroupFilter: {}
        }];
        this.updateFilters();
    }

    removeRow(event) {
        const index = parseInt(event.currentTarget.dataset.index, 10);
        const rec = this.companyUsers[index];
        if (rec.id && rec.id.length === 18) {
            this.deletedRecordIds.push(rec.id);
        }
        this.companyUsers.splice(index, 1);
        this.companyUsers = [...this.companyUsers];
        this.updateFilters();
    }

    async handleSave() {
        if (!this.validateRecords()) {
            return;
        }

        this.showSpinner = true;
        const records = this.companyUsers.map(r => ({
            Id: r.id && r.id.length === 18 ? r.id : null,
            User__c: r.User__c,
            Business_Unit__c: r.Business_Unit__c,
            Division__c: r.Division__c,
            Product_Group__c: r.Product_Group__c,
            Company__c: this._recordId
        }));

        try {
            await saveCompanyUsers({
                companyId: this._recordId,
                companyUsers: records,
                deletedRecordIds: this.deletedRecordIds
            });
            this.showToast('Success', 'Company users saved successfully', 'success');

            setTimeout(() => {
                this.handleCancel();
            }, 1000);

        } catch (err) {
            this.showError(err);
        } finally {
            this.showSpinner = false;
        }
    }

    validateRecords() {
        let isValid = true;
        const errorMessages = new Set();
        const uniqueCombinations = new Set();
        let hasMissingFields = false;

        // Check for required fields
        this.companyUsers.forEach((row, index) => {
            if (!row.User__c) {
                errorMessages.add('Please select User for all rows');
                hasMissingFields = true;
                isValid = false;
            }
            if (!row.Business_Unit__c) {
                errorMessages.add('Please select Business Unit for all rows');
                hasMissingFields = true;
                isValid = false;
            }
            if (row.Business_Unit__c && !row.Division__c) {
                errorMessages.add('Please select Division for all rows');
                hasMissingFields = true;
                isValid = false;
            }
            if (row.Business_Unit__c && row.Division__c && !row.Product_Group__c) {
                errorMessages.add('Please select Product Group for all rows');
                hasMissingFields = true;
                isValid = false;
            }
        });

        if (hasMissingFields) {
            this.showToast('Validation Error', Array.from(errorMessages).join('\n'), 'error');
            return isValid;
        }

        // Check for duplicate combinations
        this.companyUsers.forEach((row) => {
            if (row.User__c && row.Business_Unit__c && row.Division__c && row.Product_Group__c) {
                const combinationKey = `${row.User__c}-${row.Business_Unit__c}-${row.Division__c}-${row.Product_Group__c}`;

                if (uniqueCombinations.has(combinationKey)) {
                    errorMessages.add('Cannot Create Duplicate records with same combinations');
                    isValid = false;
                } else {
                    uniqueCombinations.add(combinationKey);
                }
            }
        });

        if (errorMessages.size > 0) {
            this.showToast('Validation Error', Array.from(errorMessages).join('\n'), 'error');
        }

        return isValid;
    }

    handleCancel() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this._recordId,
                objectApiName: 'Company__c',
                actionName: 'view'
            }
        });
        // setTimeout(() => {
        //     window.location.reload();
        // }, 2000);
    }

    showToast(title, msg, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message: msg, variant }));
    }

    showError(error) {
        const msg = error.body?.message || error.message || JSON.stringify(error);
        this.showToast('Error', msg, 'error');
    }
}