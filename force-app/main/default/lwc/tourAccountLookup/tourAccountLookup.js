import { LightningElement, track, api } from 'lwc';
import searchAccounts from '@salesforce/apex/AccountLookupController.searchAccounts';

export default class TourAccountLookup extends LightningElement {
    @track searchKey = '';
    @track searchResults = [];
    @track selectedRecords = [];
    @track isDropdownVisible = false;
    @track message = '';
    searchTimeout;

    handleKeyChange(event) {
        this.searchKey = event.target.value;
        this.getLookupResult();
    }

    get comboboxClass() {
        return `slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click ${this.isDropdownVisible ? 'slds-is-open' : ''}`;
    }


    getLookupResult() {
        if (this.searchTimeout) {
            clearTimeout(this.searchTimeout);
        }

        this.searchTimeout = setTimeout(() => {
            if (this.searchKey.length >= 2) {
                searchAccounts({ 
                    keyword: this.searchKey, 
                    type: null 
                })
                .then(result => {
                    console.log('Accounts from Apex:', result);
                    if (result && result.length > 0) {
                        this.searchResults = result.map(record => {
                            const isSelected = this.isRecordSelected(record.Id);
                            return {
                                ...record,
                                isSelected,
                                iconName: isSelected ? 'utility:check' : 'utility:add',
                                iconClass: isSelected ? 'slds-icon-text-success' : 'slds-icon-text-default'
                            };
                        });
                        this.isDropdownVisible = true; // This should show the dropdown
                        this.message = '';
                    } else {
                        this.searchResults = [];
                        this.isDropdownVisible = true; // Show dropdown even for empty results
                        this.message = 'No accounts found';
                    }
                })
                .catch(error => {
                    console.error('Error searching accounts:', error);
                    this.message = 'Error searching accounts';
                    this.isDropdownVisible = false;
                });
            } else {
                this.searchResults = [];
                this.isDropdownVisible = false;
                this.message = '';
            }
        }, 300);
    }

    onLeave(event) {
        setTimeout(() => {
            this.searchResults = [];
            this.isDropdownVisible = false;
            this.message = '';
        }, 200);
    }

    handleSelect(event) {
        const recordId = event.currentTarget.dataset.id;
        const record = this.searchResults.find(r => r.Id === recordId);
        
        if (record && !this.isRecordSelected(recordId)) {
            this.selectedRecords = [...this.selectedRecords, record];
            this.updateSearchResultsSelection();
            this.dispatchSelectionChange();
        }
        
        this.searchKey = '';
        this.searchResults = [];
        this.isDropdownVisible = false;
    }

    handleRemoveRecord(event) {
        const recordId = event.currentTarget.dataset.id;
        this.selectedRecords = this.selectedRecords.filter(r => r.Id !== recordId);
        this.updateSearchResultsSelection();
        this.dispatchSelectionChange();
    }

    updateSearchResultsSelection() {
        this.searchResults = this.searchResults.map(record => {
            const isSelected = this.isRecordSelected(record.Id);
            return {
                ...record,
                isSelected,
                iconName: isSelected ? 'utility:check' : 'utility:add',
                iconClass: isSelected ? 'slds-icon-text-success' : 'slds-icon-text-default'
            };
        });
    }

    isRecordSelected(recordId) {
        return this.selectedRecords.some(r => r.Id === recordId);
    }

    dispatchSelectionChange() {
        this.dispatchEvent(new CustomEvent('selectionchange', {
            detail: { 
                selectedRecords: this.selectedRecords,
                selectedRecordIds: this.selectedRecords.map(r => r.Id)
            }
        }));
    }

    @api
    clearSelection() {
        this.selectedRecords = [];
        this.searchResults = [];
        this.searchKey = '';
        this.isDropdownVisible = false;
        this.message = '';
        this.dispatchSelectionChange();
    }

    @api
    getSelectedRecords() {
        return this.selectedRecords;
    }

    @api
    setSelectedRecords(records) {
        this.selectedRecords = records || [];
        this.updateSearchResultsSelection();
        this.dispatchSelectionChange();
    }
}