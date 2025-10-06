import { LightningElement, track, api } from 'lwc';
import getUsers from '@salesforce/apex/UserLookupController.getUsers';

export default class UserLookup extends LightningElement {
    @api label;

    @track users = [];
    @track filteredUsers = [];
    @track selectedUser = null;
    @track isDropdownOpen = false;
    @track inputValue = '';

    connectedCallback() {
        getUsers()
            .then(result => {
                this.users = result;
                this.filteredUsers = result;
            })
            .catch(error => console.error(error));
    }

    handleFocus() {
        this.isDropdownOpen = true;
        this.filterUsers(this.inputValue);
    }

    handleBlur() {
        setTimeout(() => {
            this.isDropdownOpen = false;
        }, 200);
    }

    handleInput(event) {
        this.inputValue = event.target.value;
        this.filterUsers(this.inputValue);
        this.isDropdownOpen = true;
    }

    filterUsers(searchKey) {
        const key = searchKey ? searchKey.toLowerCase() : '';
        this.filteredUsers = this.users.filter(user => user.Name.toLowerCase().includes(key));
    }

    handleSelectUser(event) {
        const id = event.currentTarget.dataset.id;
        const name = event.currentTarget.dataset.name;

        this.selectedUser = { Id: id, Name: name };
        this.inputValue = name;
        this.isDropdownOpen = false;

        this.dispatchEvent(new CustomEvent('userselect', { detail: this.selectedUser }));
    }

    handleClear() {
        this.selectedUser = null;
        this.inputValue = '';
        this.filteredUsers = this.users;
        this.isDropdownOpen = false;

        this.dispatchEvent(new CustomEvent('userselect', { detail: null }));
    }

    // Compute the combobox class here
    get comboboxClass() {
        return this.isDropdownOpen
            ? 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open'
            : 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    }

    get showClearButton() {
        return !!this.selectedUser;
    }

    get showDropdown() {
        return this.isDropdownOpen && this.filteredUsers.length > 0;
    }
}