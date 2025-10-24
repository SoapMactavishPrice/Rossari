import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
//import getQuoteLineItems from '@salesforce/apex/EditSalesPriceQuoteController.getQuoteLineItems';
//import updateQuoteLineItems from '@salesforce/apex/EditSalesPriceQuoteController.updateQuoteLineItems';
import QUOTE_LINE_ITEM_OBJECT from '@salesforce/schema/QuoteLineItem';
import APPROVAL_STATUS_FIELD from '@salesforce/schema/QuoteLineItem.Approval_Status__c';

const QUOTE_FIELDS = ['Quote.Name', 'Quote.OwnerId', 'Quote.Owner.Email', 'Quote.Owner.Name', 'Quote.Link__c'];

export default class EditSalesPriceQuote extends NavigationMixin(LightningElement) {
    @api recordId;
    @track quoteLineItems = [];
    @track quote;
    @track isLoading = false;
    @track error;
    @track approvalStatusOptions = [];
    objectInfo;

    // Load object info for picklist options
    @wire(getObjectInfo, { objectApiName: QUOTE_LINE_ITEM_OBJECT })
    wiredObjectInfo({ data, error }) {
        if (data) {
            this.objectInfo = data;
            this.loadPicklistValues(); // Only call this here once objectInfo is ready
        } else if (error) {
            console.error('Error loading object info:', error);
            this.showToast('Error', 'Failed to load object info for Quote Line Item.', 'error');
        }
    }

    loadPicklistValues() {
        try {
            if (this.objectInfo && this.objectInfo.fields) {
                const fieldInfo = this.objectInfo.fields[APPROVAL_STATUS_FIELD.fieldApiName];
                if (fieldInfo && fieldInfo.picklistValues) {
                    this.approvalStatusOptions = fieldInfo.picklistValues.map(option => ({
                        label: option.label,
                        value: option.value
                    }));
                    console.log('✅ Approval Status Options:', this.approvalStatusOptions);
                } else {
                    console.warn('⚠️ No picklist values found for Approval_Status__c');
                }
            }
        } catch (e) {
            console.error('Error in loadPicklistValues:', e);
        }
    }

    // Load Quote data
    @wire(getRecord, { recordId: '$recordId', fields: QUOTE_FIELDS })
    wiredQuote({ error, data }) {
        if (data) {
            this.quote = {
                Name: getFieldValue(data, 'Quote.Name'),
                OwnerId: getFieldValue(data, 'Quote.OwnerId'),
                OwnerEmail: getFieldValue(data, 'Quote.Owner.Email'),
                OwnerName: getFieldValue(data, 'Quote.Owner.Name'),
                Link: getFieldValue(data, 'Quote.Link__c')
            };
            this.loadQuoteLineItems();
        } else if (error) {
            this.error = error;
            this.showToast('Error', error.body.message, 'error');
        }
    }

    loadQuoteLineItems() {
        this.isLoading = true;
        getQuoteLineItems({ quoteId: this.recordId })
            .then(result => {
                this.quoteLineItems = result.map(item => ({
                    ...item,
                    Approval_Status__c: item.Approval_Status__c || ''
                }));
                console.log('🔄 Loaded Quote Line Items:', this.quoteLineItems);
                this.isLoading = false;
            })
            .catch(error => {
                this.error = error;
                this.showToast('Error', error.body.message, 'error');
                this.isLoading = false;
            });
    }

    handleInputChange(event) {
        const index = event.target.dataset.index;
        const field = event.target.dataset.field;
        const value = event.target.value;

        this.quoteLineItems = this.quoteLineItems.map((item, i) => {
            if (i == index) {
                return { ...item, [field]: value };
            }
            return item;
        });
    }

    handleSave() {
        this.isLoading = true;
        const itemsToUpdate = this.quoteLineItems;

        updateQuoteLineItems({
            quoteLineItems: itemsToUpdate,
            quoteId: this.recordId
        })
            .then(() => {
                this.showToast('Success', 'Quote line items updated successfully', 'success');
                this.navigateToQuote();
            })
            .catch(error => {
                this.error = error;
                this.showToast('Error', error.body.message, 'error');
                this.isLoading = false;
            });
    }

    navigateToQuote() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view'
            }
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        }));
    }
}