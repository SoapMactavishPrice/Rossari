import { LightningElement, api, track } from 'lwc';
import searchUsers from '@salesforce/apex/ExpenseController.getUsers';

export default class UserMultiSelectLookup extends LightningElement {
    @api label = 'Team Members';
    @api placeholder = 'Search team members...';
    @api maxResults = 5;
    @api required = false;
    @api selectedUserIds = [];

    @track searchTerm = '';
    @track searchResults = [];
    @track selectedUsers = [];
    @track isDropdownOpen = false;
    @track isLoading = false;

    // Public method to get selected users
    @api getSelectedUsers() {
        return this.selectedUsers;
    }

    // Public method to clear selection
    @api clearSelection() {
        this.selectedUsers = [];
        this.selectedUserIds = [];
        this.dispatchSelectionChange();
    }
    
    get showDropdown() {
        return this.isDropdownOpen && this.searchResults.length > 0;
    }

    
    get showNoResults() {
        return this.isDropdownOpen && this.searchResults.length === 0 && this.searchTerm;
    }


    // Computed property for dropdown classes
    get dropdownClass() {
        return `slds-dropdown slds-dropdown_length-${this.maxResults} slds-dropdown_fluid`;
    }

    handleSearch(event) {
        this.searchTerm = event.target.value;
        this.debounceSearch();
    }

    debounceTimer;
    debounceSearch() {
        clearTimeout(this.debounceTimer);
        this.debounceTimer = setTimeout(() => {
            this.performSearch();
        }, 300);
    }

    async performSearch() {
        if (!this.searchTerm || this.searchTerm.length < 2) {
            console.log('Search term too short:', this.searchTerm);
            this.searchResults = [];
            this.isDropdownOpen = false;
            return;
        }

        this.isLoading = true;
        try {
            console.log('Calling Apex with search term:', this.searchTerm);
            const results = await searchUsers({ searchTerm: this.searchTerm });
            console.log('Apex returned results - FULL STRUCTURE:', JSON.stringify(results, null, 2));
            
            // Log first result to see the structure
            if (results && results.length > 0) {
                console.log('First result structure:', results[0]);
                console.log('Available properties:', Object.keys(results[0]));
            }
            
            // Filter out already selected users
            this.searchResults = results.filter(user => 
                !this.selectedUsers.some(selected => selected.Id === user.value)
            );
            
            console.log('Filtered results:', this.searchResults);
            this.isDropdownOpen = true;
        } catch (error) {
            console.error('Error searching users:', error);
            this.searchResults = [];
        } finally {
            this.isLoading = false;
        }
    }

    handleUserSelect(event) {
        const userId = event.currentTarget.dataset.userId;
        const user = this.searchResults.find(u => u.value === userId);
        
        if (user && !this.selectedUsers.some(selected => selected.Id === userId)) {
            this.selectedUsers = [
                ...this.selectedUsers,
                {
                    Id: user.value,
                    Name: user.label,
                    Grades__c: user.grade
                }
            ];
            
            this.dispatchSelectionChange();
        }
        
        this.clearSearch();
    }

    handleRemoveUser(event) {
        const userId = event.currentTarget.dataset.userId;
        this.selectedUsers = this.selectedUsers.filter(user => user.Id !== userId);
        this.dispatchSelectionChange();
    }

    handleFocus() {
        if (this.searchTerm && this.searchResults.length > 0) {
            this.isDropdownOpen = true;
        }
    }

    handleKeyDown(event) {
        if (event.key === 'Escape') {
            this.isDropdownOpen = false;
        }
    }

    clearSearch() {
        this.searchTerm = '';
        this.searchResults = [];
        this.isDropdownOpen = false;
    }

    dispatchSelectionChange() {
        this.dispatchEvent(new CustomEvent('selectionchange', {
            detail: {
                selectedUsers: this.selectedUsers,
                selectedUserIds: this.selectedUsers.map(user => user.Id)
            }
        }));
    }

    // Close dropdown when clicking outside
    handleClickOutside(event) {
        if (!this.template.contains(event.target)) {
            this.isDropdownOpen = false;
        }
    }

    connectedCallback() {
        document.addEventListener('click', this.handleClickOutside.bind(this));
    }

    disconnectedCallback() {
        document.removeEventListener('click', this.handleClickOutside.bind(this));
    }
}