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
    @track isInitialLoad = true;

    connectedCallback() {
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
                this.displayValue = this.selectedRecord.Name;
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
            this.displayValue = selectedRecord.Name;
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
        // Always load records when input is focused
        if (this.isInitialLoad) {
            this.isInitialLoad = false;
        }

        // Load records based on current state
        if (this.searchTerm && this.searchTerm.length >= 2) {
            // If we have a search term, search normally
            this.searchRecords();
        } else {
            // If no search term or short search term, show available records
            this.searchTerm = '';
            this.searchRecords();
        }
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