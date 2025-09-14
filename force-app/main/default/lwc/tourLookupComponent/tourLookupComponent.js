import { LightningElement, track } from 'lwc';
import searchTours from '@salesforce/apex/TourLookupController.searchTours';

export default class TourLookupComponent extends LightningElement {
    @track searchKey = '';
    @track searchResults = [];
    @track showDropdown = false;
    @track selectedTourName = '';
    @track selectedTourId = '';

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
                    this.showDropdown = false;
                });
        } else {
            this.searchResults = [];
            this.showDropdown = false;
        }
    }

    handleTourSelect(event) {
        const tourId = event.currentTarget.dataset.tourId;
        const tourName = event.currentTarget.dataset.tourName;

        this.selectedTourName = tourName;
        this.selectedTourId = tourId;
        this.showDropdown = false;
        this.searchKey = '';

        this.dispatchEvent(new CustomEvent('selected', {
            detail: {
                recordId: tourId,
                recordName: tourName
            }
        }));
    }

    handleRemove() {
        this.selectedTourId = '';
        this.selectedTourName = '';
        this.searchKey = '';
        this.searchResults = [];
        this.showDropdown = false;

        this.dispatchEvent(new CustomEvent('selected', {
            detail: {
                recordId: '',
                recordName: ''
            }
        }));
    }
}