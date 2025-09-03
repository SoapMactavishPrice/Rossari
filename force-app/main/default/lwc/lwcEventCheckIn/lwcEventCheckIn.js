import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import updateCheckIn from '@salesforce/apex/lwcEventCheckInOutController.updateCheckIn';

export default class LwcEventCheckIn extends LightningElement {

    @api recordId;

    connectedCallback() {
        console.log('recordId', this.recordId);
        this.getLatLongAndUpdate();
    }

    getLatLongAndUpdate() {
        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(position => {
                // Get the Latitude and Longitude from Geolocation API
                var latitude = position.coords.latitude;
                var longitude = position.coords.longitude;
                console.log('Latitude:', latitude, 'Longitude:', longitude);

                // Call the Apex method to handle the check-in
                updateCheckIn({
                    recordId: this.recordId,
                    latitude: latitude,
                    longitude: longitude
                })
                .then((result) => {
                    if (result === 'Already Checked In') {
                        // Show error toast indicating already checked-in status
                        this.showErrorToast('Event already checked in');
                        // After showing the error toast, redirect back to the previous page
                        this.redirectToPreviousPageAfterDelay();
                    } else {
                        // Show success message using a toast
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Success',
                            message: 'Checked In Successfully',
                            variant: 'success',
                            duration: 3000, // Show toast for 3 seconds
                            mode: 'dismissable' // The toast will automatically disappear after 3 seconds
                        }));
                        // Redirect to previous page after successful check-in
                        this.redirectToPreviousPageAfterDelay();
                    }
                })
                .catch((error) => {
                    // Handle errors during the Apex call
                    this.showToastOnError(error);
                });

            });
        } else {
            // Handle case when geolocation is not available or denied
            this.showToastOnError('Location permission is not available');
        }
    }

    // Show error toast for already checked in status
    showErrorToast(message) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: message,
            variant: 'error',
            duration: 3000, // Show toast for 3 seconds
            mode: 'dismissable' // The toast will automatically disappear after 3 seconds
        }));
    }

    // Redirect to the previous page after a 3-second delay
    redirectToPreviousPageAfterDelay() {
        setTimeout(() => {
            window.history.back(); // Redirect to previous page after 3 seconds
        }, 3000); // 3000 milliseconds = 3 seconds
    }

    showToastOnError(error) {
        console.warn(error);

        let msg;
        if (error.message)
            msg = error.message;
        else if (error.body.message)
            msg = error.body.message;
        else
            msg = error;

        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: msg,
            variant: 'error',
            duration: 3000, // Show toast for 3 seconds
            mode: 'dismissable' // The toast will automatically disappear after 3 seconds
        }));
    }
}