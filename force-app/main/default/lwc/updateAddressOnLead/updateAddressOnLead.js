import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import getAddressDataByPin from '@salesforce/apex/LeadAddressHelper.getAddressDataByPin';
import getCountriesByRegion from '@salesforce/apex/LeadAddressHelper.getCountriesByRegion';
import getRegionOptions from '@salesforce/apex/LeadAddressHelper.getRegionOptions';
import getZoneOptions from '@salesforce/apex/LeadAddressHelper.getZoneOptions';
import updateLeadAddressFields from '@salesforce/apex/LeadAddressHelper.updateLeadAddressFields';

const FIELDS = [
    // Billing
    'Lead.Pin_Code__c',
    'Lead.City__c',
    'Lead.State__c',
    'Lead.Country__c',
    'Lead.Region__c',
    'Lead.Zone__c',
    'Lead.Street_1__c',
    'Lead.Street_2__c',
    'Lead.Street_3__c',

    // Shipping
    'Lead.Shipping_Pin_Code__c',
    'Lead.Shipping_City__c',
    'Lead.Shipping_State__c',
    'Lead.Shipping_Country__c',
    'Lead.Shipping_Region__c',
    'Lead.Shipping_Zone__c',
    'Lead.Shipping_Street_1__c',
    'Lead.Shipping_Street_2__c',
    'Lead.Shipping_Street_3__c',

    // Checkbox
    'Lead.Copy_Bill_to_To_Ship_to__c'
];



export default class LeadAddressUpdater extends NavigationMixin(LightningElement) {
    @api recordId;

    // Billing Fields
    @track cityId = '';
    @track stateId = '';
    @track countryId = '';
    @track regionValue = '';
    @track zoneValue = '';
    @track currentPinCodeId = '';
    @track street1 = '';
    @track street2 = '';
    @track street3 = '';
    @track isPinCodeLoading = false;
    @track preserveRegionCountry = false;

    // Shipping Fields
    @track shippingStreet1 = '';
    @track shippingStreet2 = '';
    @track shippingStreet3 = '';
    @track shippingPinCodeId = '';
    @track shippingCityId = '';
    @track shippingStateId = '';
    @track shippingCountryId = '';
    @track shippingRegionValue = '';
    @track shippingZoneValue = '';

    // UI Options
    @track regionOptions = [];
    @track zoneOptions = [];
    @track countryOptions = [];

    // Checkbox
    @track copyBillingToShipping = false;

    // Initial data load
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredLead({ error, data }) {
        if (data) {
            // Billing fields
            this.currentPinCodeId = getFieldValue(data, 'Lead.Pin_Code__c') || '';
            this.cityId = getFieldValue(data, 'Lead.City__c') || '';
            this.stateId = getFieldValue(data, 'Lead.State__c') || '';
            this.countryId = getFieldValue(data, 'Lead.Country__c') || '';
            this.regionValue = getFieldValue(data, 'Lead.Region__c') || '';
            this.zoneValue = getFieldValue(data, 'Lead.Zone__c') || '';
            this.street1 = getFieldValue(data, 'Lead.Street_1__c') || '';
            this.street2 = getFieldValue(data, 'Lead.Street_2__c') || '';
            this.street3 = getFieldValue(data, 'Lead.Street_3__c') || '';

            // Shipping fields
            this.shippingPinCodeId = getFieldValue(data, 'Lead.Shipping_Pin_Code__c') || '';
            this.shippingCityId = getFieldValue(data, 'Lead.Shipping_City__c') || '';
            this.shippingStateId = getFieldValue(data, 'Lead.Shipping_State__c') || '';
            this.shippingCountryId = getFieldValue(data, 'Lead.Shipping_Country__c') || '';
            this.shippingRegionValue = getFieldValue(data, 'Lead.Shipping_Region__c') || '';
            this.shippingZoneValue = getFieldValue(data, 'Lead.Shipping_Zone__c') || '';
            this.shippingStreet1 = getFieldValue(data, 'Lead.Shipping_Street_1__c') || '';
            this.shippingStreet2 = getFieldValue(data, 'Lead.Shipping_Street_2__c') || '';
            this.shippingStreet3 = getFieldValue(data, 'Lead.Shipping_Street_3__c') || '';

            // Load country options if region is available
            if (this.regionValue) {
                this.loadCountriesByRegion(this.regionValue);
            }
        } else if (error) {
            console.error('Error fetching Lead data:', error);
        }
    }


    connectedCallback() {
        this.loadRegionOptions();
        this.loadZoneOptions();
    }

    loadRegionOptions() {
        getRegionOptions()
            .then(result => {
                this.regionOptions = result.map(r => ({ label: r, value: r }));
            })
            .catch(error => {
                console.error('Error loading region options:', error);
            });
    }

    loadZoneOptions() {
        getZoneOptions()
            .then(result => {
                this.zoneOptions = result.map(z => ({ label: z, value: z }));
            })
            .catch(error => {
                console.error('Error loading zone options:', error);
            });
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
                    console.error('Error fetching countries:', error);
                });
        } else {
            this.countryOptions = [];
        }
    }

    handleCheckboxChange(event) {
        this.copyBillingToShipping = event.target.checked;

        if (this.copyBillingToShipping) {
            // Copy Billing values to Shipping
            this.shippingStreet1 = this.street1;
            this.shippingStreet2 = this.street2;
            this.shippingStreet3 = this.street3;
            this.shippingPinCodeId = this.currentPinCodeId;
            this.shippingCityId = this.cityId;
            this.shippingStateId = this.stateId;
            this.shippingCountryId = this.countryId;
            this.shippingRegionValue = this.regionValue;
            this.shippingZoneValue = this.zoneValue;
        } else {
            // Clear ALL Shipping fields including lookups
            this.shippingStreet1 = null;
            this.shippingStreet2 = null;
            this.shippingStreet3 = null;
            this.shippingPinCodeId = null;
            this.shippingCityId = null;
            this.shippingStateId = null;
            this.shippingCountryId = null;
            this.shippingRegionValue = null;
            this.shippingZoneValue = null;
        }
    }



    handleRegionChange(event) {
        this.regionValue = event.detail.value;
        this.countryId = '';
        this.loadCountriesByRegion(this.regionValue);
        this.preserveRegionCountry = true;
    }

    handleZoneChange(event) {
        this.zoneValue = event.detail.value;
    }

    handleCountryChange(event) {
        this.countryId = event.detail.value;
        this.preserveRegionCountry = true;
    }

    handleInputChange(event) {
        const field = event.target.dataset.id;
        let value = event.detail?.recordId || event.detail?.value || event.target?.value;

        if (typeof value === 'object' && value !== null && value.Id) {
            value = value.Id;
        }

        switch (field) {
            // Billing fields
            case 'pincode':
                this.currentPinCodeId = value;
                if (value) {
                    this.isPinCodeLoading = true;
                    getAddressDataByPin({ pinCodeId: value })
                        .then(result => {
                            this.cityId = result.cityId || '';
                            this.stateId = result.stateId || '';
                            this.zoneValue = result.zone || '';

                            if (!this.preserveRegionCountry) {
                                this.countryId = result.countryId || '';
                                this.regionValue = result.region || '';
                                if (this.regionValue) {
                                    this.loadCountriesByRegion(this.regionValue);
                                }
                            }

                            this.isPinCodeLoading = false;
                        })
                        .catch(error => {
                            console.error('Error fetching address data:', error);
                            this.isPinCodeLoading = false;
                        });
                } else {
                    this.cityId = '';
                    this.stateId = '';
                    this.zoneValue = '';
                    if (!this.preserveRegionCountry) {
                        this.countryId = '';
                        this.regionValue = '';
                        this.countryOptions = [];
                    }
                    this.isPinCodeLoading = false;
                }
                break;

            case 'cityId':
                this.cityId = value;
                break;

            case 'stateId':
                this.stateId = value;
                break;

            case 'countryId':
                this.countryId = value;
                this.preserveRegionCountry = true;
                break;

            case 'street1':
                this.street1 = value;
                break;

            case 'street2':
                this.street2 = value;
                break;

            case 'street3':
                this.street3 = value;
                break;

            // Shipping fields
            case 'shippingStreet1':
                this.shippingStreet1 = value;
                break;

            case 'shippingStreet2':
                this.shippingStreet2 = value;
                break;

            case 'shippingStreet3':
                this.shippingStreet3 = value;
                break;

            case 'shippingPincode':
                this.shippingPinCodeId = value;
                if (value) {
                    this.isPinCodeLoading = true;
                    getAddressDataByPin({ pinCodeId: value })
                        .then(result => {
                            this.shippingCityId = result.cityId || '';
                            this.shippingStateId = result.stateId || '';
                            this.shippingZoneValue = result.zone || '';

                            // Set country and region if not manually set
                            if (!this.preserveRegionCountry) {
                                this.shippingCountryId = result.countryId || '';
                                this.shippingRegionValue = result.region || '';
                                if (this.shippingRegionValue) {
                                    this.loadCountriesByRegion(this.shippingRegionValue);
                                }
                            }

                            this.isPinCodeLoading = false;
                        })
                        .catch(error => {
                            console.error('Error fetching shipping address data:', error);
                            this.isPinCodeLoading = false;
                        });
                } else {
                    this.shippingCityId = '';
                    this.shippingStateId = '';
                    this.shippingZoneValue = '';
                    if (!this.preserveRegionCountry) {
                        this.shippingCountryId = '';
                        this.shippingRegionValue = '';
                    }
                    this.isPinCodeLoading = false;
                }
                break;


            case 'shippingCityId':
                this.shippingCityId = value;
                break;

            case 'shippingStateId':
                this.shippingStateId = value;
                break;

            case 'shippingCountryId':
                this.shippingCountryId = value;
                break;

            case 'shippingRegion':
                this.shippingRegionValue = value;
                break;

            case 'shippingZone':
                this.shippingZoneValue = value;
                break;
        }
    }
    handleSuccess() {
        const fieldsToUpdate = {
            leadId: this.recordId,
            // Billing fields
            pinCodeId: this.currentPinCodeId,
            cityId: this.cityId,
            stateId: this.stateId,
            countryId: this.countryId,
            region: this.regionValue,
            zone: this.zoneValue,
            street1: this.street1,
            street2: this.street2,
            street3: this.street3,
            // Shipping fields - explicitly pass null when empty
            shippingStreet1: this.shippingStreet1 || null,
            shippingStreet2: this.shippingStreet2 || null,
            shippingStreet3: this.shippingStreet3 || null,
            shippingPinCodeId: this.shippingPinCodeId || null,
            shippingCityId: this.shippingCityId || null,
            shippingStateId: this.shippingStateId || null,
            shippingCountryId: this.shippingCountryId || null,
            shippingRegion: this.shippingRegionValue || null,
            shippingZone: this.shippingZoneValue || null,
            copyBillingToShipping: this.copyBillingToShipping
        };

        updateLeadAddressFields(fieldsToUpdate)
            .then(() => {
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: this.recordId,
                        objectApiName: 'Lead',
                        actionName: 'view'
                    }
                });
            })
            .catch(error => {
                console.error('Error updating lead fields:', error);
            });
    }
    handleCancel() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Lead',
                actionName: 'view'
            }
        });
    }
}