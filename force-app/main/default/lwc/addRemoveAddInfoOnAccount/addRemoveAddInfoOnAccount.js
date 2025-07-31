import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { deleteRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';

import getAddressesByAccount from '@salesforce/apex/AccountAddressHelper.getAddressesByAccount';
import getAddressDataByPin from '@salesforce/apex/AccountAddressHelper.getAddressDataByPin';
import getCountriesByRegion from '@salesforce/apex/AccountAddressHelper.getCountriesByRegion';
import getRegionOptions from '@salesforce/apex/AccountAddressHelper.getRegionOptions';
import getZoneOptions from '@salesforce/apex/AccountAddressHelper.getZoneOptions';
import getRecordTypeId from '@salesforce/apex/AccountAddressHelper.getRecordTypeId';

export default class AccountAddressManager extends NavigationMixin(LightningElement) {
    @api recordId; // Account ID

    @track currentAddressType = 'Bill To';
    @track currentRecordTypeId;
    @track addresses = [];
    @track currentAddressId = null;
    @track isFormOpen = false;
    @track formVisible = false;


    // Address fields
    @track cityId = '';
    @track stateId = '';
    @track countryId = '';
    @track regionValue = '';
    @track zoneValue = '';
    @track currentPinCodeId = '';
    @track isPinCodeLoading = false;
    @track isSaving = false;
    @track cityName = '';

    // Options
    @track regionOptions = [];
    @track zoneOptions = [];
    @track countryOptions = [];
    @track isAddingAddress = false;

    get billToTabClass() {
        return this.currentAddressType === 'Bill To'
            ? 'slds-tabs_default__item slds-is-active'
            : 'slds-tabs_default__item';
    }

    get shipToTabClass() {
        return this.currentAddressType === 'Ship To'
            ? 'slds-tabs_default__item slds-is-active'
            : 'slds-tabs_default__item';
    }


    connectedCallback() {
        this.loadRegionOptions();
        this.loadZoneOptions();
        this.loadRecordTypeId();
    }

    loadRecordTypeId() {
        getRecordTypeId({ objectApiName: 'Address_Information__c', recordTypeName: 'Bill_To' })
            .then(result => {
                this.currentRecordTypeId = result;
                this.loadAddresses();
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            });
    }

    loadAddresses() {
        if (!this.currentRecordTypeId) return;

        getAddressesByAccount({
            accountId: this.recordId,
            recordTypeName: this.currentAddressType.replace(' ', '_')
        })
            .then(result => {
                this.addresses = result.map(addr => ({
                    ...addr,
                    CityName: addr.City__r?.Name || '',
                    StateName: addr.State__r?.Name || '',
                    CountryName: addr.Country__r?.Name || '',
                    PinCodeName: addr.Pin_Code__r?.Name || ''
                }));
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            });
    }

    loadRegionOptions() {
        getRegionOptions()
            .then(result => {
                this.regionOptions = result.map(r => ({ label: r, value: r }));
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            });
    }

    loadZoneOptions() {
        getZoneOptions()
            .then(result => {
                this.zoneOptions = result.map(z => ({ label: z, value: z }));
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            });
    }

    handleTabChange(event) {
        this.currentAddressType = event.target.dataset.type === 'Bill_To' ? 'Bill To' : 'Ship To';
        getRecordTypeId({
            objectApiName: 'Address_Information__c',
            recordTypeName: this.currentAddressType.replace(' ', '_')
        }).then(result => {
            this.currentRecordTypeId = result;
            this.loadAddresses();
        });
    }

    handleAddNew() {
        this.currentAddressId = null;
        this.resetFormFields();
        this.isFormOpen = true;
    }

    handleAddNewClick() {
        if (this.isAddingAddress) {
            this.handleCancel1(); // Call cancel logic
        } else {
            this.handleAddNew(); // Call add logic
        }
        this.isAddingAddress = !this.isAddingAddress; // Toggle state

        this.isFormOpen = true;
        this.formVisible = true;
    }


    handleEditAddress(event) {
        // Get the ID from the closest button element
        const buttonElement = event.currentTarget.closest('lightning-button-icon');
        const addressId = buttonElement.dataset.id;

        this.currentAddressId = addressId;
        const address = this.addresses.find(addr => addr.Id === addressId);

        if (address) {
            this.cityId = address.City__c;
            this.stateId = address.State__c;
            this.countryId = address.Country__c;
            this.regionValue = address.Region__c;
            this.zoneValue = address.Zone__c;
            this.currentPinCodeId = address.Pin_Code__c;
            this.cityName = address.CityName;
        }
        this.isFormOpen = true;
        this.formVisible = true;
    }

    async handleDeleteAddress(event) {
        // Get the ID from the closest button element
        const buttonElement = event.currentTarget.closest('lightning-button-icon');
        const addressId = buttonElement.dataset.id;

        try {
            this.isSaving = true;
            await deleteRecord(addressId);
            this.showToast('Success', 'Address deleted Successfully', 'success');

            // Refresh the view
            setTimeout(() => {
                window.location.reload();
            }, 1000);
        } catch (error) {
            this.showToast('Error', error.body.message, 'error');
        } finally {
            this.isSaving = false;
        }
        this.isFormOpen = true;
        this.formVisible = true;
    }

    handleRegionChange(event) {
        this.regionValue = event.detail.value;
        this.countryId = '';
        this.loadCountriesByRegion(this.regionValue);
    }

    handleCountryChange(event) {
        this.countryId = event.detail.value;
    }

    handleZoneChange(event) {
        this.zoneValue = event.detail.value;
    }

    handlePinCodeChange(event) {
        this.currentPinCodeId = event.detail.recordId;
        if (this.currentPinCodeId) {
            this.isPinCodeLoading = true;
            getAddressDataByPin({ pinCodeId: this.currentPinCodeId })
                .then(result => {
                    this.cityId = result.cityId || '';
                    this.stateId = result.stateId || '';
                    this.countryId = result.countryId || '';
                    this.regionValue = result.region || '';
                    this.zoneValue = result.zone || '';

                    // Get the city name if available
                    if (result.cityName) {
                        this.cityName = result.cityName;
                    } else if (this.cityId) {
                        // Optionally fetch city name if not returned
                        this.fetchCityName(this.cityId);
                    }

                    if (this.regionValue) {
                        this.loadCountriesByRegion(this.regionValue);
                    }
                    this.isPinCodeLoading = false;
                })
                .catch(error => {
                    this.showToast('Error', error.body.message, 'error');
                    this.isPinCodeLoading = false;
                });
        }
    }

    // Add this helper method if needed
    fetchCityName(cityId) {
        getCityName({ cityId })
            .then(result => {
                this.cityName = result;
            })
            .catch(error => {
                console.error('Error fetching city name:', error);
            });
    }

    handleCityChange(event) {
        this.cityId = event.detail.recordId;
        // You might want to fetch the city name here if needed
    }

    handleStateChange(event) {
        this.stateId = event.detail.recordId;
    }

    loadCountriesByRegion(region) {
        if (region) {
            getCountriesByRegion({ region })
                .then(result => {
                    this.countryOptions = result.map(country => ({
                        label: country.Name,
                        value: country.Id
                    }));
                })
                .catch(error => {
                    this.showToast('Error', error.body.message, 'error');
                });
        }
    }

    // Modified handleSubmit
    // handleSubmit(event) {
    //     event.preventDefault();
    //     const fields = event.detail.fields;

    //     // Set required fields
    //     fields.Account__c = this.recordId;
    //     fields.RecordTypeId = this.currentRecordTypeId;

    //     // Set the name in "Bill To - City Name" format
    //     const prefix = this.currentAddressType;
    //     const cityPart = this.cityName || 'New Address';
    //     fields.Name = `${prefix} - ${cityPart}`.substring(0, 80);

    //     // Set other address fields
    //     fields.Pin_Code__c = this.currentPinCodeId;
    //     fields.City__c = this.cityId;
    //     fields.State__c = this.stateId;
    //     fields.Country__c = this.countryId;
    //     fields.Region__c = this.regionValue;
    //     fields.Zone__c = this.zoneValue;

    //     this.template.querySelector('lightning-record-edit-form').submit(fields);
    // }

    handleSubmit(event) {
        event.preventDefault();
        const fields = event.detail.fields;

        fields.Account__c = this.recordId;
        fields.RecordTypeId = this.currentRecordTypeId;

        const prefix = this.currentAddressType;
        const cityPart = this.cityName || 'New Address';
        fields.Name = `${prefix} - ${cityPart}`.substring(0, 80);

        fields.Pin_Code__c = this.currentPinCodeId;
        fields.City__c = this.cityId;
        fields.State__c = this.stateId;
        fields.Country__c = this.countryId;
        fields.Region__c = this.regionValue;
        fields.Zone__c = this.zoneValue;

        const missingFields = [];
        if (!fields.Street_1__c || fields.Street_1__c.trim() === '') {
            missingFields.push('Street 1');
        }
        if (!fields.Pin_Code__c) missingFields.push('Pin Code');
        if (!fields.City__c) missingFields.push('City');
        if (!fields.State__c) missingFields.push('State');
        if (!fields.Country__c) missingFields.push('Country');
        if (!fields.Region__c) missingFields.push('Region');
        if (!fields.Zone__c) missingFields.push('Zone');

        if (missingFields.length > 0) {
            this.showToast('Missing Required Fields', `Please fill: ${missingFields.join(', ')}`, 'error');
            return;
        }

        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    // Modified handleSuccess
    handleSuccess(event) {
        this.showToast('Success', 'Address saved Successfully', 'success');
        this.refreshPage(); // Force full page refresh
    }

    // New method to refresh the entire page
    refreshPage() {
        // Close the form if open
        this.isFormOpen = false;

        // Force a full page refresh
        setTimeout(() => {
            window.location.reload();
        }, 1000);
    }

    handleError(event) {
        this.showToast('Error', event.detail.message, 'error');
        this.isSaving = false;
    }

    handleCancel() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Account',
                actionName: 'view'
            }
        });

        this.formVisible = true;
    }

    handleCancel1() {
        this.isFormOpen = false;
        this.resetFormFields();
        this.formVisible = false;
    }

    resetFormFields() {
        this.cityId = '';
        this.stateId = '';
        this.countryId = '';
        this.regionValue = '';
        this.zoneValue = '';
        this.currentPinCodeId = '';
        this.cityName = '';
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant
        }));
    }

    get formClass() {
        return this.isFormOpen ? '' : 'slds-hidden';
    }

    get saveButtonLabel() {
        return this.currentAddressId ? 'Update' : 'Save';
    }

    get formTitle() {
        return this.currentAddressId ? 'Edit Address' : 'Add New Address';
    }
}