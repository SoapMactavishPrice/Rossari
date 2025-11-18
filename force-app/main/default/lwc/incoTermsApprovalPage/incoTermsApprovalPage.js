import { LightningElement, track } from 'lwc';
import getQuotesWithChangedIncoTerms from '@salesforce/apex/IncoTermsApprovalController.getQuotesWithChangedIncoTerms';
import updateIncoApproval from '@salesforce/apex/IncoTermsApprovalController.updateIncoApproval';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import USER_ID from '@salesforce/user/Id';

export default class IncoTermsApprovalPage extends LightningElement {
    @track quotes = [];
    @track currentUserId = USER_ID;

    @track statusOptions = [
        { label: 'Approved', value: 'Approved' },
        { label: 'Rejected', value: 'Rejected' }
    ];

    connectedCallback() {
        this.loadQuotes();
    }
    
    get hasQuotes() {
        return this.quotes && this.quotes.length > 0;
    }

    loadQuotes() {
        getQuotesWithChangedIncoTerms({ currentUserId: this.currentUserId })
            .then(result => {
                this.quotes = result.map(q => ({
                    ...q,
                    isDisabled: q.HOD_of_Sales_Department__c !== this.currentUserId
                }));
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            });
    }


    handleChange(event) {
        const field = event.target.dataset.field;
        const quoteId = event.target.dataset.id;
        const value = event.target.value;

        let quote = this.quotes.find(q => q.Id === quoteId);
        if (quote) {
            quote[field] = value;
        }
    }

    submitApproval() {
        updateIncoApproval({ updatedQuotes: this.quotes })
            .then(result => {
                if (result === 'Success') {
                    this.showToast('Success', 'Inco approval updated and emails sent.', 'success');
                    setTimeout(() => window.location.reload(), 1000);
                    this.loadQuotes();
                } else {
                    this.showToast('Error', result, 'error');
                }
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    

}