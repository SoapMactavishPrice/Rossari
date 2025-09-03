import { LightningElement, track, api } from 'lwc';
import searchAccounts from '@salesforce/apex/LeadLookupController.searchAccounts';

export default class CustomAccountLookup extends LightningElement {
    @api placeholder = 'Search...';
    @api type;

    @track searchKey = '';
    @track searchResults = [];
    @track selectedRecord;

    isDropdownVisible = false;

    handleInputChange(event) {
        this.searchKey = event.target.value;

        if (this.searchKey.length >= 2) {
            searchAccounts({ keyword: this.searchKey, type: this.type })
                .then(result => {
                    this.searchResults = result;
                    this.isDropdownVisible = result.length > 0;
                })
                .catch(error => {
                    console.error('Error in searchAccounts:', error);
                    this.searchResults = [];
                    this.isDropdownVisible = false;
                });
        } else {
            this.searchResults = [];
            this.isDropdownVisible = false;
        }
    }

    handleSelect(event) {
        const recordId = event.currentTarget.dataset.id;
        this.selectedRecord = this.searchResults.find(record => record.Id === recordId);

        this.isDropdownVisible = false;
        this.searchResults = [];
        this.searchKey = this.selectedRecord.Name;

        const selectedEvent = new CustomEvent('recordselected', {
            detail: {
                recordId: this.selectedRecord.Id,
                recordName: this.selectedRecord.Name,
                address: this.selectedRecord.billToaddress
            }
        });
        this.dispatchEvent(selectedEvent);
    }

    clearSelection() {
        this.selectedRecord = null;
        this.searchKey = '';
        this.searchResults = [];
        this.isDropdownVisible = false;
    }
}