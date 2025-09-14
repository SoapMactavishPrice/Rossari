import { LightningElement, api } from 'lwc';
import searchVisitReports from '@salesforce/apex/VisitReportLookupController.searchVisitReports';

export default class VisitReportLookup extends LightningElement {
    @api label = 'Visit Report';
    @api required = false;
    
    @api selectedRecordId;
    @api selectedRecordName;
    @api disabled = false;
    selectedVisitReportId = '';
    selectedVisitReportName = '';
    searchResults = [];
    isLoading = false;
    hasError = false;
    isDropdownOpen = false;
    searchTerm = '';
    showNoResults = false;

    handleSearchChange(event) {
        this.searchTerm = event.target.value;
        this.searchVisitReports();
    }

    toggleDropdown() {
        this.isDropdownOpen = true;
        if (this.searchTerm === '' && this.searchResults.length === 0) {
            this.searchVisitReports();
        }
    }

    handleBlur() {
        // Close dropdown after a short delay to allow for selection
        setTimeout(() => {
            this.isDropdownOpen = false;
        }, 300);
    }

    connectedCallback() {
        if (this.selectedRecordId && this.selectedRecordName) {
            this.selectedVisitReportId = this.selectedRecordId;
            this.selectedVisitReportName = this.selectedRecordName;
            this.searchTerm = this.selectedRecordName;
        }
    }

    async searchVisitReports() {
        this.isLoading = true;
        this.hasError = false;
        this.showNoResults = false;

        try {
            this.searchResults = await searchVisitReports({ 
                searchTerm: this.searchTerm || ''   // pass empty string when nothing typed
            });
            console.log('searchTerm:', this.searchTerm);
            console.log('searchResults:', this.searchResults);

            this.showNoResults = this.searchResults.length === 0;
            this.isDropdownOpen = this.searchResults.length > 0 || this.showNoResults;

        } catch (error) {
            console.error('Error searching visit reports:', error);
            this.hasError = true;
            this.searchResults = [];
        } finally {
            this.isLoading = false;
        }
    }


    // New method to handle option click
    handleOptionClick(event) {
        const id = event.currentTarget.dataset.id;
        const selectedReport = this.searchResults.find(report => report.Id === id);
        
        if (selectedReport) {
            this.handleSelect(selectedReport);
        }
    }

    handleSelect(report) {
        this.selectedVisitReportId = report.Id;
        this.selectedVisitReportName = report.Name;
        this.searchTerm = report.Name ;
        this.isDropdownOpen = false;
        this.searchResults = [];

        this.dispatchEvent(new CustomEvent('selected', {
            detail: {
                recordId: report.Id,
                recordName: report.Name,
                title: report.Title_of_Meeting__c
            }
        }));
    }


    // Public method to clear selection
    @api
    clearSelection() {
        this.selectedVisitReportId = '';
        this.selectedVisitReportName = '';
        this.searchTerm = '';
        this.searchResults = [];
        this.isDropdownOpen = false;
        
        const input = this.template.querySelector('input');
        if (input) {
            input.value = '';
        }
    }
}