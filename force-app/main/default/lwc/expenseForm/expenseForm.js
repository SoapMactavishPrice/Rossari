import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import initializeExpense from '@salesforce/apex/ExpenseController.initializeExpense';
import getUsers from '@salesforce/apex/ExpenseController.getUsers';
import getTypeOfExpense from '@salesforce/apex/ExpenseController.getTypeOfExpense';
import createExpenseWithFiles from '@salesforce/apex/ExpenseController.createExpenseWithFiles';

export default class ExpenseForm extends LightningElement {
    @track expenseName = '';
    @track todayDate = '';
    @track selectedEmployeeId = '';
    @track division = '';
    @track zone = '';
    @track selectedVoucherType = '';

    @track employeeOptions = [];
    @track typeOfExpenseOptions = [];
    @track voucherOptions = [];
    @track lineItems = [];
    @track filesPerLineItem = {}; // key = lineItem index, value = array of ContentDocument Ids

    acceptedFormats = ['.pdf', '.jpg', '.jpeg', '.png', '.doc', '.docx'];
    nextKey = 0;

    connectedCallback() {
        this.initializeData();
        this.addLineItem();
    }

    async initializeData() {
        try {
            const result = await initializeExpense();
            if (result.currentUser) {
                const user = result.currentUser;
                this.selectedEmployeeId = user.Id;
                this.division = user.Division || '';
                this.zone = user.Zone__c || '';
            }
            this.voucherOptions = result.voucherOptions || [];
            this.todayDate = result.todayDate || '';

            this.employeeOptions = await this.formatUsers(await getUsers({ searchTerm: '' }));
            this.typeOfExpenseOptions = await this.formatTypeOfExpense(await getTypeOfExpense({ searchTerm: '' }));

        } catch (error) {
            this.showToast('Error', error?.body?.message || error.message || 'Initialization failed', 'error');
        }
    }

    getLineItemFilesCount(index) {
        if (this.filesPerLineItem[index]) {
            return this.filesPerLineItem[index].length;
        }
        return 0;
    }


    formatUsers(users) {
        return users.map(u => ({
            label: u.label || u.Name,
            value: u.value || u.Id,
            division: u.division || '',
            zone: u.zone || ''
        }));
    }

    formatTypeOfExpense(expenses) {
        return expenses.map(e => ({
            label: e.label || e.Name,
            value: e.value || e.Id
        }));
    }

    handleEmployeeChange(event) {
        const empId = event.detail.value;
        this.selectedEmployeeId = empId;
        const emp = this.employeeOptions.find(e => e.value === empId);
        if (emp) {
            this.division = emp.division;
            this.zone = emp.zone;
        }
    }

    async handleEmployeeSearch(event) {
        const searchKey = event.target.value || '';
        const users = await getUsers({ searchTerm: searchKey });
        this.employeeOptions = this.formatUsers(users);
    }

    async handleTypeOfExpenseSearch(event) {
        const searchKey = event.target.value || '';
        const expenses = await getTypeOfExpense({ searchTerm: searchKey });
        this.typeOfExpenseOptions = this.formatTypeOfExpense(expenses);
    }

    handleTypeOfExpenseChange(event) {
        const idx = parseInt(event.currentTarget.dataset.index, 10);
        const value = event.detail.value;
        this.lineItems = this.lineItems.map((item, i) => i === idx ? { ...item, typeOfExpenseId: value } : item);
    }

    handleAmountClaimedChange(event) {
        const idx = parseInt(event.target.dataset.index, 10);
        const value = parseFloat(event.target.value) || 0;
        this.lineItems = this.lineItems.map((item, i) => i === idx ? { ...item, amountClaimed: value } : item);
    }

    addLineItem() {
        const newItem = {
            key: this.nextKey++,
            typeOfExpenseId: '',
            amountClaimed: 0,
            recordId: null // will hold uploaded file parentId
        };
        this.lineItems = [...this.lineItems, newItem];
    }

    deleteLineItem(event) {
        const idx = parseInt(event.currentTarget.dataset.index, 10);
        if (this.lineItems.length > 1) {
            this.lineItems.splice(idx, 1);
            this.lineItems = [...this.lineItems];
        } else {
            this.showToast('Info', 'At least one line item is required', 'info');
        }
    }

    handleFileUpload(event) {
        const idx = parseInt(event.target.dataset.index, 10);
        const files = event.detail.files;
        if (files && files.length > 0) {
            this.filesPerLineItem[idx] = files.map(f => f.documentId);
            this.lineItems[idx].filesCount = files.length;
        } else {
            this.filesPerLineItem[idx] = [];
            this.lineItems[idx].filesCount = 0;
        }
        // Trigger reactivity
        this.lineItems = [...this.lineItems];
    }


    handleVoucherTypeChange(event) {
        this.selectedVoucherType = event.detail.value;
    }

    handleNameChange(event) {
        this.expenseName = event.target.value;
    }

    async handleSubmit() {
        if (!this.validateForm()) return;

        try {
            const expense = {
                Name: this.expenseName,
                Date__c: this.todayDate,
                Employee_Name__c: this.selectedEmployeeId,
                Type_of_Voucher__c: this.selectedVoucherType,
                Division__c: this.division,
                Zone__c: this.zone
            };

            const lineItemsToSend = this.lineItems.map(item => ({
                Type_of_Expense__c: item.typeOfExpenseId,
                Amount_Claimed__c: item.amountClaimed
            }));

            const result = await createExpenseWithFiles({ 
                            expense, 
                            lineItems: lineItemsToSend,
                            filesPerLineItem: this.filesPerLineItem
                        });

            this.showToast('Success', 'Expense claim submitted successfully', 'success');
            this.resetForm();
        } catch (error) {
            this.showToast('Error', error?.body?.message || error.message || 'Submission failed', 'error');
        }
    }

    validateForm() {
        if (!this.expenseName) { this.showToast('Error', 'Enter Voucher No', 'error'); return false; }
        if (!this.todayDate) { this.showToast('Error', 'Select Expense Date', 'error'); return false; }
        if (!this.selectedEmployeeId) { this.showToast('Error', 'Select Employee', 'error'); return false; }
        if (!this.selectedVoucherType) { this.showToast('Error', 'Select Type of Voucher', 'error'); return false; }
        for (let i = 0; i < this.lineItems.length; i++) {
            const item = this.lineItems[i];
            if (!item.typeOfExpenseId) { this.showToast('Error', `Select Type of Expense for row ${i+1}`, 'error'); return false; }
            if (!item.amountClaimed) { this.showToast('Error', `Enter Amount Claimed for row ${i+1}`, 'error'); return false; }
        }
        return true;
    }

    resetForm() {
        this.expenseName = '';
        this.lineItems = [];
        this.selectedVoucherType = '';
        this.addLineItem();
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}