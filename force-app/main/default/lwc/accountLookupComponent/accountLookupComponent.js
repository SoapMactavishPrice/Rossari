import { LightningElement, api, track } from 'lwc';
import getAccountsForTour from '@salesforce/apex/TourLookupController.getAccountsForTour';
import searchAccounts from '@salesforce/apex/TourLookupController.searchAccounts';

export default class AccountLookupComponent extends LightningElement {
    @api tourId;

    @track selectedAccounts = [];
    @track searchResults = [];
    @track searchKey = '';
    @track showDropdown = false;

    connectedCallback() {
        if (this.tourId) {
            this.fetchExistingAccounts();
        }
    }

    @api
    set selectedTourId(value) {
        if (value) {
            this.tourId = value;
            this.fetchExistingAccounts();
        }
    }

    get selectedTourId() {
        return this.tourId;
    }

    fetchExistingAccounts() {
        getAccountsForTour({ tourId: this.tourId })
            .then(result => {
                this.selectedAccounts = result;
            })
            .catch(error => {
                console.error('Error loading accounts for tour:', error);
            });
    }

    handleKeyChange(event) {
        this.searchKey = event.target.value;
        if (this.searchKey.length >= 2) {
            searchAccounts({ searchKey: this.searchKey })
                .then(result => {
                    this.searchResults = result;
                    this.showDropdown = true;
                })
                .catch(error => {
                    console.error('Search error:', error);
                });
        } else {
            this.showDropdown = false;
            this.searchResults = [];
        }
    }

    handleSelect(event) {
        const selectedId = event.currentTarget?.dataset?.id;
        const selectedName = event.currentTarget?.dataset?.name;
        if (!selectedId || !selectedName) return;

        // Check if account is already selected
        if (!this.selectedAccounts.find(acc => acc.Id === selectedId)) {
            this.selectedAccounts = [
                ...this.selectedAccounts,
                { Id: selectedId, Name: selectedName }
            ];
        }

        this.searchKey = '';
        this.searchResults = [];
        this.showDropdown = false;

        // Dispatch event with all selected accounts
        this.dispatchEvent(new CustomEvent('selected', {
            detail: {
                recordId: selectedId,
                recordName: selectedName,
                selectedAccounts: this.selectedAccounts
            }
        }));
    }

    handleRemove(event) {
        const removeId = event.currentTarget.dataset.id;
        this.selectedAccounts = this.selectedAccounts.filter(acc => acc.Id !== removeId);

        // Dispatch event after removal
        this.dispatchEvent(new CustomEvent('removed', {
            detail: { recordId: removeId }
        }));
    }
}