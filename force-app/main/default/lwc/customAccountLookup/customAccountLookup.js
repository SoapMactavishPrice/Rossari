import { LightningElement, track, api } from 'lwc';
import searchAccounts from '@salesforce/apex/AccountLookupController.searchAccounts';

export default class CustomAccountLookup extends LightningElement {
    @api placeholder = 'Search...';
    @api type;

    @api recordId;   // 👈 from parent
    @api recordName; // 👈 from parent

    @track searchKey = '';
    @track searchResults = [];
    @track selectedRecord = null;
    isDropdownVisible = false;

    connectedCallback() {
        // 👇 When component loads, if recordId/recordName passed, preselect
        if (this.recordId && this.recordName) {
            this.selectedRecord = {
                Id: this.recordId,
                Name: this.recordName
            };
            this.searchKey = this.recordName;
        }
    }

    handleInputChange(event) {
        const value = event.target.value;
        this.searchKey = value;

        if (value.length >= 2) {
            searchAccounts({ keyword: value, type: this.type })
                .then(result => {
                    this.searchResults = result;
                    this.isDropdownVisible = result.length > 0;
                })
                .catch(error => {
                    console.error('Error in searchAccounts:', error);
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
    }
}