import { LightningElement, api } from 'lwc';

export default class CityLookupComponent extends LightningElement {
    @api label = 'City';
    @api required = false;
    @api selectedRecordId = '';
    @api selectedRecordName = '';

    handleChange(event) {
        this.selectedRecordId = event.detail.recordId;
        // Note: record name might not be directly available in event.detail
        // You may need to query it separately
        
        this.dispatchEvent(new CustomEvent('selected', {
            detail: {
                recordId: this.selectedRecordId,
                recordName: '' // You'll need to get this from Apex
            }
        }));
    }

    @api
    clearSelection() {
        this.selectedRecordId = '';
        this.selectedRecordName = '';
        const recordPicker = this.template.querySelector('lightning-record-picker');
        if (recordPicker) {
            recordPicker.value = '';
        }
    }

    @api
    setSelection(recordId, recordName) {
        this.selectedRecordId = recordId;
        this.selectedRecordName = recordName;
        const recordPicker = this.template.querySelector('lightning-record-picker');
        if (recordPicker) {
            recordPicker.value = recordId;
        }
    }
}