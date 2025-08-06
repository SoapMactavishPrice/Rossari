import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import updateOpportunityStatus from '@salesforce/apex/OpportunityTriggerHandler.updateOpportunityStatus';
import getLostReasonPicklist from '@salesforce/apex/OpportunityTriggerHandler.getLostReasonPicklist';

export default class OpportunityClosedLost extends NavigationMixin(LightningElement) {
    @api recordId;
    @api isModal = false;
    isLoading = false;

    // Form field values
    @track lostReason = '';
    @track competitorLostTo = '';
    @track competitorPrice = '';
    @track competitorProduct = '';
    @track otherReasons = '';
    @track note = '';
    @track nextFollowUp = '';

    @track reasonOptions = [];

    connectedCallback() {
        this.fetchPicklistValues();
    }

    fetchPicklistValues() {
        getLostReasonPicklist()
            .then(data => {
                this.reasonOptions = data.map(value => ({ label: value, value }));
            })
            .catch(error => {
                this.showToast('Error', 'Failed to load reason options: ' + error.body?.message || error.message, 'error');
            });
    }

    get showCompetitorFields() {
        return this.lostReason === 'Lost to Competitor';
    }

    get showOtherReasonField() {
        return this.lostReason === 'Others';
    }

    handleReasonChange(event) {
        this.lostReason = event.detail.value;
        if (this.lostReason !== 'Lost to Competitor') {
            this.competitorLostTo = '';
            this.competitorPrice = '';
            this.competitorProduct = '';
        }
        if (this.lostReason !== 'Others') {
            this.otherReasons = '';
        }
    }

    handleInputChange(event) {
        this[event.target.name] = event.detail.value;
    }

    validateForm() {
        if (!this.lostReason) {
            this.showToast('Error', 'Please select a Closed/Lost Reason', 'error');
            return false;
        }

        if (!this.nextFollowUp) {
            this.showToast('Error', 'Next Follow Up Date is required', 'error');
            return false;
        }

        if (!this.note) {
            this.showToast('Error', 'Notes are required', 'error');
            return false;
        }

        if (this.lostReason === 'Lost to Competitor') {
            if (!this.competitorLostTo || !this.competitorPrice || !this.competitorProduct) {
                this.showToast('Error', 'All competitor fields are required', 'error');
                return false;
            }
        }

        if (this.lostReason === 'Others' && !this.otherReasons) {
            this.showToast('Error', 'Please provide detailed reasons for "Others"', 'error');
            return false;
        }

        return true;
    }

    async handleSubmit() {
        if (!this.validateForm()) return;

        this.isLoading = true;
        try {
            const opportunityData = {
                opportunityId: this.recordId,
                lostReason: this.lostReason,
                note: this.note,
                closeDate: new Date().toISOString().split('T')[0],
                competitorLostTo: this.competitorLostTo,
                competitorPrice: this.competitorPrice,
                competitorProduct: this.competitorProduct,
                nextFollowUp: this.nextFollowUp,
                otherReasons: this.otherReasons
            };

            await updateOpportunityStatus({ opportunityData });
            this.showToast('Success', 'Opportunity marked as Closed Lost', 'success');
            this.navigateToOpportunityRecord();
            this.isModal = false;

        } catch (error) {
            this.showToast('Error', error.body?.message || error.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleCancel() {
        this.navigateToOpportunityRecord();
    }

    navigateToOpportunityRecord() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Opportunity',
                actionName: 'view'
            }
        });
        setTimeout(() => {
            window.location.reload();
        }, 2000);
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}