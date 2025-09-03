import { LightningElement, api, track } from 'lwc';
import searchRecords from '@salesforce/apex/ExpenseLookupController.searchRecords';

export default class ExpenseLookup extends LightningElement {
    @api objectApiName;
    @api selectedRecordId;
    @api selectedRecordName = '';
    @api placeholder = 'Search...';
    @api index;

    @track searchResults = [];
    @track showDropdown = false;

    searchTerm = '';
    searchTimeout;

    // Helper method to check if we should show user details
    shouldShowUserDetails(record) {
        return this.objectApiName === 'User' && record.Division;
    }

    get displayValue() {
        return this.selectedRecordName || this.searchTerm;
    }

    handleSearchChange(event) {
        this.searchTerm = event.target.value;
        this.selectedRecordId = null;
        this.selectedRecordName = '';

        clearTimeout(this.searchTimeout);

        if (this.searchTerm.length >= 2) {
            this.searchTimeout = setTimeout(() => this.performSearch(this.searchTerm), 300);
        } else {
            this.searchResults = [];
            this.showDropdown = false;
        }
    }

    async performSearch(searchTerm) {
        try {
            const results = await searchRecords({
                objectApiName: this.objectApiName,
                searchTerm: searchTerm
            });

            console.log('Search results received:', JSON.parse(JSON.stringify(results)));

            // Process results to ensure they're plain objects
            const processedResults = results ? results.map(record => ({
                Id: record.Id,
                Name: record.Name,
                Division: record.Division,
                Zone__c: record.Zone__c
            })) : [];

            this.searchResults = processedResults;
            this.showDropdown = this.searchResults.length > 0;

            console.log('Processed results:', JSON.parse(JSON.stringify(this.searchResults)));
            console.log('Show dropdown:', this.showDropdown);

        } catch (error) {
            console.error('Search error:', error);
            this.searchResults = [];
            this.showDropdown = false;
        }
    }

    handleResultSelect(event) {
        event.preventDefault();
        const recordId = event.currentTarget.dataset.id;
        const recordName = event.currentTarget.dataset.name;

        this.selectedRecordId = recordId;
        this.selectedRecordName = recordName;
        this.searchTerm = '';
        this.searchResults = [];
        this.showDropdown = false;

        const eventDetail = { 
            recordId: recordId, 
            recordName: recordName, 
            index: this.index
        };

        if (this.objectApiName === 'User') {
            const record = this.searchResults.find(r => r.Id === recordId);
            if (record) {
                eventDetail.division = record.Division;
                eventDetail.zone = record.Zone__c;
            }
        }

        this.dispatchEvent(new CustomEvent('recordselected', {
            detail: eventDetail,
            bubbles: true,
            composed: true
        }));
    }

    handleInputClick() {
        if (this.searchResults.length > 0) {
            this.showDropdown = true;
        } else if (this.searchTerm && this.searchTerm.length >= 2) {
            this.performSearch(this.searchTerm);
        }
    }

    handleInputBlur() {
        setTimeout(() => { 
            this.showDropdown = false; 
        }, 300);
    }

    @api
    clearSelection() {
        this.selectedRecordId = null;
        this.selectedRecordName = '';
        this.searchTerm = '';
        this.searchResults = [];
        this.showDropdown = false;
    }
}