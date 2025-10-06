import { LightningElement, api, track } from 'lwc';
import searchRecords from '@salesforce/apex/CustomSalesAreaLookupController.searchRecords';

export default class CustomSalesAreaLookup extends LightningElement {
    @api objectApiName;
    @api fieldApiName;
    @api placeholder = 'Search...';
    @api value = '';
    @api filterParams = {};

    @track searchTerm = '';
    @track records = [];
    @track showDropdown = false;
    @track selectedRecord = {};
    @track displayValue = '';
    @track hasSearched = false;
    @track recordSelectedFromList = false;
    @track showNoRecords = false;

    connectedCallback() {
        // Load selected record only if a value exists
        if (this.value) {
            this.loadSelectedRecord();
        }
    }

    async loadSelectedRecord() {
        try {
            const results = await searchRecords({
                searchTerm: '',
                objectApiName: this.objectApiName,
                filterParams: JSON.stringify({}),
                recordId: this.value
            });

            if (results && results.length > 0) {
                this.selectedRecord = results[0];
                this.displayValue = this.getDisplayValue(this.selectedRecord);
            }
        } catch (error) {
            console.error('Error loading selected record:', error);
        }
    }

    handleSearchChange(event) {
        this.searchTerm = event.target.value;
        this.displayValue = this.searchTerm;
        this.hasSearched = true;
        this.recordSelectedFromList = false;
        this.showNoRecords = false;

        clearTimeout(this.searchTimeout);
        this.searchTimeout = setTimeout(() => {
            this.searchRecords();
        }, 300);
    }

    async searchRecords() {
        try {
            const effectiveFilterParams = this.filterParams || {};

            this.records = await searchRecords({
                searchTerm: this.searchTerm || '',
                objectApiName: this.objectApiName,
                filterParams: JSON.stringify(effectiveFilterParams),
                recordId: null
            });

            // Process records to add display value
            this.records = this.records.map(record => ({
                ...record,
                displayValue: this.getDisplayValue(record)
            }));

            this.showDropdown = true;
            this.showNoRecords = this.records.length === 0;

        } catch (error) {
            this.records = [];
            this.showDropdown = true;
            this.showNoRecords = true;
            console.error('Error searching records:', error);
        }
    }

    handleRecordSelect(event) {
        const recordId = event.currentTarget.dataset.id;
        const selectedRecord = this.records.find(record => record.Id === recordId);

        if (selectedRecord) {
            this.selectedRecord = selectedRecord;
            this.displayValue = this.getDisplayValue(selectedRecord);
            this.searchTerm = '';
            this.records = [];
            this.showDropdown = false;
            this.showNoRecords = false;
            this.hasSearched = false;
            this.recordSelectedFromList = true;

            this.dispatchEvent(new CustomEvent('change', {
                detail: {
                    value: selectedRecord.Id,
                    selectedRecord: selectedRecord
                }
            }));
        }
    }

    getDisplayValue(record) {
        if (this.objectApiName === 'Product_Group__c') {
            return record.Item_Group_Description__c || '';
        } else {
            return record.Name || '';
        }
    }

    @api
    clearSelection() {
        this.selectedRecord = {};
        this.searchTerm = '';
        this.displayValue = '';
        this.records = [];
        this.showDropdown = false;
        this.showNoRecords = false;
        this.hasSearched = false;
        this.recordSelectedFromList = false;

        this.dispatchEvent(new CustomEvent('change', {
            detail: {
                value: '',
                selectedRecord: {}
            }
        }));
    }

    handleFocus() {
        // If already selected record exists, do nothing (don't open dropdown)
        if (this.selectedRecord && this.selectedRecord.Id) {
            return;
        }

        // If field is empty, show dropdown on click
        this.searchRecords();
    }

    handleBlur() {
        setTimeout(() => {
            this.showDropdown = false;

            if (this.hasSearched && !this.recordSelectedFromList && !this.selectedRecord.Id) {
                this.searchTerm = '';
                this.displayValue = '';
                this.hasSearched = false;
                this.showNoRecords = false;
            }
        }, 200);
    }

    @api
    updateFilterParams(newParams) {
        this.filterParams = newParams;
        // Reload records if dropdown is open to apply new filters
        if (this.showDropdown) {
            this.searchRecords();
        }
    }
}