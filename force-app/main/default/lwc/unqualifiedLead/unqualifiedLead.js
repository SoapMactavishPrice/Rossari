import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import updateLeadStatus from '@salesforce/apex/LeadAddressHelper.updateLeadStatus';
import getUnqualifiedReasons from '@salesforce/apex/LeadAddressHelper.getUnqualifiedReasons';

export default class UnqualifiedLead extends NavigationMixin(LightningElement) {
    @api recordId;
    isLoading = false;

    @track unqualifiedReason = '';
    @track competitorLostTo = '';
    @track competitorPrice = '';
    @track competitorProduct = '';
    @track otherReasons = '';
    @track nextFollowUp = '';
    @track note = '';

    @track reasonOptions = [];

    connectedCallback() {
        this.loadPicklistValues();
    }

    loadPicklistValues() {
        getUnqualifiedReasons()
            .then(data => {
                this.reasonOptions = data.map(val => ({ label: val, value: val }));
            })
            .catch(error => {
                this.showToast('Error', 'Failed to load picklist values', 'error');
                console.error(error);
            });
    }

    get showCompetitorFields() {
        return this.unqualifiedReason === 'Lost to Competitor';
    }

    get showOtherReasonField() {
        return this.unqualifiedReason === 'Others';
    }

    handleReasonChange(event) {
        this.unqualifiedReason = event.detail.value;
        if (this.unqualifiedReason !== 'Lost to Competitor') {
            this.competitorLostTo = '';
            this.competitorPrice = '';
            this.competitorProduct = '';
        }
        if (this.unqualifiedReason !== 'Others') {
            this.otherReasons = '';
        }
    }

    handleInputChange(event) {
        this[event.target.name] = event.detail.value;
    }

    validateForm() {
        if (!this.unqualifiedReason) {
            this.showToast('Error', 'Please select an Unqualified Reason', 'error');
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

        if (this.unqualifiedReason === 'Lost to Competitor') {
            if (!this.competitorLostTo || !this.competitorPrice || !this.competitorProduct) {
                this.showToast('Error', 'All competitor fields are required', 'error');
                return false;
            }
        }

        if (this.unqualifiedReason === 'Others' && !this.otherReasons) {
            this.showToast('Error', 'Please provide Other Reasons', 'error');
            return false;
        }

        return true;
    }

    async handleSubmit() {
        if (!this.validateForm()) return;

        this.isLoading = true;

        try {
            const leadData = {
                leadId: this.recordId,
                status: 'Unqualified',
                unqualifiedReason: this.unqualifiedReason,
                nextFollowUp: this.nextFollowUp,
                note: this.note
            };

            if (this.unqualifiedReason === 'Lost to Competitor') {
                leadData.competitorLostTo = this.competitorLostTo;
                leadData.competitorPrice = this.competitorPrice;
                leadData.competitorProduct = this.competitorProduct;
            } else if (this.unqualifiedReason === 'Others') {
                leadData.otherReasons = this.otherReasons;
            }

            await updateLeadStatus({ leadData });
            this.showToast('Success', 'Lead marked as unqualified', 'success');
            this.navigateToLeadRecord();

        } catch (error) {
            this.showToast('Error', error.body?.message || error.message, 'error');
            console.error(error);
        } finally {
            this.isLoading = false;
        }
    }

    handleCancel() {
        this.navigateToLeadRecord();
    }

    navigateToLeadRecord() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Lead',
                actionName: 'view'
            }
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}