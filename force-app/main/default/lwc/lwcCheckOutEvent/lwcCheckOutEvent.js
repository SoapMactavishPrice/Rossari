import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import getEventById from '@salesforce/apex/lwcEventCheckInOutController.getEventById';
import updateCheckOut from '@salesforce/apex/lwcEventCheckInOutController.updateCheckOut';

export default class LwcEventCheckOut extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;

    @track Description = '';
    @track checkoutStatus = false; // Flag to track if checkout has already occurred

    // Wire the Apex method to fetch Event record dynamically by recordId
    @wire(getEventById, { recordId: '$recordId' })
    wiredEvent({ error, data }) {
        if (data) {
            console.log('Event data received:', data);
            this.Description = data.Description;

            // Check if the event has already been checked out
            if (data.Check_Out_Time__c) {
                this.checkoutStatus = true;
            }
        } else if (error) {
            console.error('Error fetching event data:', error);
        }
    }

    getLatLongAndUpdate() {
        // Check if the event is already checked out
        if (this.checkoutStatus) {
            this.showToast('Error', 'This event has already been checked out.', 'error');
            return;
        }

        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(
                position => {
                    // Get the Latitude and Longitude from Geolocation API
                    const latitude = position.coords.latitude;
                    const longitude = position.coords.longitude;

                    console.log('Latitude:', latitude, 'Longitude:', longitude);

                    // Call the Apex method to update the event with the geolocation data and other fields
                    updateCheckOut({
                        recordId: this.recordId,
                        latitude: latitude,
                        longitude: longitude,
                        Description: this.Description
                        
                    })
                        .then(() => {
                            this.showToast('Success', 'Checkout successful.', 'success');
                            this.redirectToRecordPage(this.recordId);
                        })
                        .catch((error) => {
                            this.showToastOnError(error);
                        });
                },
                error => {
                    console.error('Geolocation error:', error);
                    this.showToast('Error', 'Unable to fetch geolocation. Please check your browser permissions.', 'error');
                }
            );
        } else {
            this.showToast('Error', 'Geolocation is not supported by this browser.', 'error');
        }
    }

    // Redirect to the record page after checkout
    redirectToRecordPage(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
    }

    // Show toast notifications
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        }));
    }

    // Handle error during checkout or geolocation fetch
    showToastOnError(error) {
        let msg = error.message || (error.body ? error.body.message : error);
        this.showToast('Error', msg, 'error');
    }

    // Handle input field changes
    handleInputChange(event) {
        const fieldName = event.target.dataset.id;
        this[fieldName] = event.target.value;
    }

    // Handle save (checkout) button click
    handleSave(event) {
        this.getLatLongAndUpdate();
    }

    // Handle reset button click (cancel checkout)
    handleReset(event) {
        this.dispatchEvent(new CloseActionScreenEvent());
        this.redirectToRecordPage(this.recordId);
    }
}