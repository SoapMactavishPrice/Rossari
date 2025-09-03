import { LightningElement, track } from 'lwc';
import searchTours from '@salesforce/apex/TourLookupController.searchTours';
import createTour from '@salesforce/apex/TourLookupController.createTour';

export default class TourLookupComponent extends LightningElement {
    @track searchKey = '';
    @track searchResults = [];
    @track selectedTour;
    @track showDropdown = false;

    get allowCreate() {
        return this.searchKey && this.searchResults.length === 0;
    }

    handleSearchChange(event) {
        this.searchKey = event.target.value;
        if (this.searchKey.length >= 2) {
            searchTours({ searchKey: this.searchKey })
                .then(result => {
                    this.searchResults = result;
                    this.showDropdown = true;
                })
                .catch(error => {
                    console.error('Error fetching tours:', error);
                });
        } else {
            this.searchResults = [];
            this.showDropdown = false;
        }
    }

    handleSelect(event) {
        const selectedName = event.currentTarget.textContent.trim();
        this.selectedTour = this.searchResults.find(r => r.Name === selectedName);

        this.showDropdown = false;
        this.dispatchEvent(new CustomEvent('tourselected', { 
            detail: { recordId: this.selectedTour.Id, recordName: this.selectedTour.Name }
        }));
    }

    handleCreate() {
        createTour({ tourName: this.searchKey })
            .then(newTour => {
                this.selectedTour = newTour;
                this.showDropdown = false;
                this.dispatchEvent(new CustomEvent('tourselected', { 
                    detail: { recordId: newTour.Id, recordName: newTour.Name }
                }));
            })
            .catch(error => {
                console.error('Error creating tour:', error);
            });
    }
}