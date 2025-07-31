import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import getAddressDataByPin from '@salesforce/apex/LeadAddressHelper.getAddressDataByPin';
import getCountriesByRegion from '@salesforce/apex/LeadAddressHelper.getCountriesByRegion';
import getRegionOptions from '@salesforce/apex/LeadAddressHelper.getRegionOptions';
import getZoneOptions from '@salesforce/apex/LeadAddressHelper.getZoneOptions';
import updateLeadAddressFields from '@salesforce/apex/LeadAddressHelper.updateLeadAddressFields';

const FIELDS = [
    'Lead.Pin_Code__c',
    'Lead.City__c',
    'Lead.State__c',
    'Lead.Country__c',
    'Lead.Region__c',
    'Lead.Zone__c'
];

export default class LeadAddressUpdater extends NavigationMixin(LightningElement) {
    @api recordId;

    @track cityId = '';
    @track stateId = '';
    @track countryId = '';
    @track regionValue = '';
    @track zoneValue = '';
    @track currentPinCodeId = '';
    @track isPinCodeLoading = false;
    @track preserveRegionCountry = false;

    @track regionOptions = [];
    @track zoneOptions = [];
    @track countryOptions = [];

    @track street1 = '';
    @track street2 = '';
    @track street3 = '';


    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredLead({ error, data }) {
        if (data) {
            this.currentPinCodeId = getFieldValue(data, 'Lead.Pin_Code__c') || '';
            this.cityId = getFieldValue(data, 'Lead.City__c') || '';
            this.stateId = getFieldValue(data, 'Lead.State__c') || '';
            this.countryId = getFieldValue(data, 'Lead.Country__c') || '';
            this.regionValue = getFieldValue(data, 'Lead.Region__c') || '';
            this.zoneValue = getFieldValue(data, 'Lead.Zone__c') || '';

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

    handleInputChange(event) {
        const field = event.target.dataset.id;
        const value = event.detail.recordId || event.detail.value;

        switch (field) {
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
        }
    }

    handleSuccess() {
        updateLeadAddressFields({
            leadId: this.recordId,
            pinCodeId: this.currentPinCodeId,
            cityId: this.cityId,
            stateId: this.stateId,
            countryId: this.countryId,
            region: this.regionValue,
            zone: this.zoneValue
        }).then(() => {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    objectApiName: 'Lead',
                    actionName: 'view'
                }
            });
        }).catch(error => {
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