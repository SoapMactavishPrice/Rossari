import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getCityDetails from '@salesforce/apex/ExpenseController.getCityDetails';

export default class CityLookupComponent extends LightningElement {
    @api label = 'City';
    @api required = false;
    @api selectedRecordId = '';
    @api selectedRecordName = '';
    @api cityType = ''; // Add this to store city type

    handleChange(event) {
        this.selectedRecordId = event.detail.recordId;
        
        if (this.selectedRecordId) {
            // Call Apex to get city details including name and type
            this.getCityDetailsApex(this.selectedRecordId);
        } else {
            // Clear selection
            this.selectedRecordName = '';
            this.cityType = '';
            this.dispatchSelectionEvent();
        }
    }

    getCityDetailsApex(cityId) {
        getCityDetails({ cityId: cityId })
            .then(result => {
                if (result.success) {
                    this.selectedRecordName = result.cityName;
                    this.cityType = result.cityType;
                    this.dispatchSelectionEvent();
                } else {
                    console.error('Error fetching city details:', result.message);
                    this.selectedRecordName = '';
                    this.cityType = '';
                    this.dispatchSelectionEvent();
                }
            })
            .catch(error => {
                console.error('Error:', error);
                this.selectedRecordName = '';
                this.cityType = '';
                this.dispatchSelectionEvent();
            });
    }

    dispatchSelectionEvent() {
        this.dispatchEvent(new CustomEvent('selected', {
            detail: {
                recordId: this.selectedRecordId,
                recordName: this.selectedRecordName,
                cityType: this.cityType,
                isAClassCity: this.cityType === 'A Class City'
            }
        }));
    }

    @api
    clearSelection() {
        this.selectedRecordId = '';
        this.selectedRecordName = '';
        this.cityType = '';
        const recordPicker = this.template.querySelector('lightning-record-picker');
        if (recordPicker) {
            recordPicker.value = '';
        }
        this.dispatchSelectionEvent();
    }

    @api
    setSelection(recordId, recordName, cityType) {
        this.selectedRecordId = recordId;
        this.selectedRecordName = recordName;
        this.cityType = cityType || '';
        const recordPicker = this.template.querySelector('lightning-record-picker');
        if (recordPicker) {
            recordPicker.value = recordId;
        }
        this.dispatchSelectionEvent();
    }
}