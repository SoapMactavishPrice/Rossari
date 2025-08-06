import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

import getUsers from '@salesforce/apex/CompanyUserController.getUsers';
import getBusinessUnits from '@salesforce/apex/CompanyUserController.getBusinessUnits';
import getDivisions from '@salesforce/apex/CompanyUserController.getDivisions';
import getProductGroups from '@salesforce/apex/CompanyUserController.getProductGroups';
import getCompanyUsers from '@salesforce/apex/CompanyUserController.getCompanyUsers';
import saveCompanyUsers from '@salesforce/apex/CompanyUserController.saveCompanyUsers';

export default class CompanyUserManager extends NavigationMixin(LightningElement) {
    @track showSpinner = false;
    @track companyUsers = [];
    @track userOptions = [];
    @track businessUnitOptions = [];
    @track divisionOptions = [];
    @track productGroupOptions = [];

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

    initializeData() {
        this.showSpinner = true;
        Promise.all([
            getUsers(),
            getBusinessUnits(),
            getDivisions(),
            getProductGroups(),
            getCompanyUsers({ companyId: this._recordId })
        ])
            .then(([users, units, divs, groups, existing]) => {
                this.userOptions = users.map(u => ({ label: u.Name, value: u.Id }));
                this.businessUnitOptions = units.map(b => ({ label: b.Name, value: b.Id }));
                this.divisionOptions = divs.map(d => ({ label: d.Name, value: d.Id }));
                this.productGroupOptions = groups.map(p => ({ label: p.Name, value: p.Id }));

                if (existing.length) {
                    this.companyUsers = existing.map(rec => ({
                        id: rec.Id,
                        User__c: rec.User__c,
                        Business_Unit__c: rec.Business_Unit__c,
                        Division__c: rec.Division__c,
                        Product_Group__c: rec.Product_Group__c,
                    }));
                } else {
                    this.addNewRow();
                }
            })
            .catch(error => {
                this.showError(error);
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }

    addNewRow() {
        this.companyUsers = [...this.companyUsers, {
            id: this.generateId(),
            User__c: '',
            Business_Unit__c: '',
            Division__c: '',
            Product_Group__c: ''
        }];
    }

    generateId() {
        return Math.random().toString(36).substring(2, 15);
    }

    handleChange(event) {
        const index = parseInt(event.target.dataset.index, 10);
        const field = event.target.dataset.field;
        const value = event.detail.value;

        this.companyUsers = this.companyUsers.map((row, i) => {
            if (i === index) {
                return { ...row, [field]: value };
            }
            return row;
        });
    }


    removeRow(event) {
        const index = parseInt(event.currentTarget.dataset.index, 10);
        const rec = this.companyUsers[index];
        if (rec.id && rec.id.length === 18) {
            this.deletedRecordIds.push(rec.id);
        }
        this.companyUsers.splice(index, 1);
        this.companyUsers = [...this.companyUsers];
    }

    async handleSave() {
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
            this.showToast('Success', 'Company users saved', 'success');
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this._recordId,
                    objectApiName: 'Company__c',
                    actionName: 'view'
                }
            });
        } catch (err) {
            this.showError(err);
        } finally {
            this.showSpinner = false;
        }
        setTimeout(() => {
            window.location.reload();
        }, 1500);
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
    }

    showToast(title, msg, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message: msg, variant }));
    }

    showError(error) {
        const msg = error.body?.message || error.message || JSON.stringify(error);
        this.showToast('Error', msg, 'error');
    }
}