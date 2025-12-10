import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

import createProformaInvoice from '@salesforce/apex/ProformaInvoiceControllerLWC.createProformaInvoice';
import getQuoteDetails from '@salesforce/apex/ProformaInvoiceControllerLWC.getQuoteDetails';

// Quote fields
const QUOTE_FIELDS = [
    'Quote.Name',
    'Quote.Status',
    'Quote.Account.Name',
    'Quote.Opportunity.Name',
    'Quote.GrandTotal',
    'Quote.TotalPrice'
];

export default class ProformaInvoiceCreator extends NavigationMixin(LightningElement) {
    @api recordId;

    @track lineItems = [];
    @track isLoading = false;
    @track noQtyError = false;
    @track error = '';

    quoteName;
    quoteStatus;
    accountName;
    opportunityName;

    @wire(getRecord, { recordId: '$recordId', fields: QUOTE_FIELDS })
    wiredQuote({ error, data }) {
        if (data) {
            this.quoteName = getFieldValue(data, 'Quote.Name');
            this.quoteStatus = getFieldValue(data, 'Quote.Status');
            this.accountName = getFieldValue(data, 'Quote.Account.Name');
            this.opportunityName = getFieldValue(data, 'Quote.Opportunity.Name');

            this.loadLineItems();
        } else if (error) {
            this.error = error.body.message;
        }
    }

    async loadLineItems() {
        try {
            this.isLoading = true;
            const response = await getQuoteDetails({ quoteId: this.recordId });

            if (response.success) {
                this.lineItems = response.lineItems.map(item => {
                    const originalRemaining = Math.max(0, item.quoteQuantity - (item.piQuantity || 0));
                    return {
                        ...item,
                        id: item.quoteLineItemId,
                        remainingQuantity: originalRemaining,
                        originalRemainingQuantity: originalRemaining,
                        piQuantity: 0,
                        isFullyInvoiced: originalRemaining === 0
                    };
                });
            } else {
                this.error = response.error;
            }
        } catch (e) {
            this.error = e.message;
        } finally {
            this.isLoading = false;
        }
    }

    handleQuantityChange(event) {
        const id = event.target.dataset.id;
        const newQty = parseInt(event.target.value || 0);

        this.lineItems = this.lineItems.map(item => {
            if (item.id === id) {
                const maxQty = item.originalRemainingQuantity;
                const validQty = Math.min(newQty, maxQty);

                return {
                    ...item,
                    piQuantity: validQty,
                    remainingQuantity: maxQty - validQty
                };
            }
            return item;
        });
    }

    get isCreateDisabled() {
        return this.lineItems.every(item => item.piQuantity === 0);
    }

    async handleCreatePI() {
        try {
            const selectedItems = this.lineItems.filter(item => item.piQuantity > 0);

            if (selectedItems.length === 0) {
                this.noQtyError = true;
                return;
            }
            this.noQtyError = false;

            // Validation fix: Compare against original remaining, not updated one
            const invalidItems = this.lineItems.filter(
                i => i.piQuantity > i.originalRemainingQuantity
            );

            if (invalidItems.length > 0) {
                this.showToast('Error', 'PI Qty exceeds remaining quantity', 'error');
                return;
            }

            this.isLoading = true;

            const payload = selectedItems.map(item => ({
                quoteLineItemId: item.id,
                quantity: item.piQuantity,
                productId: item.productId,
                unitPrice: item.unitPrice
            }));

            const result = await createProformaInvoice({
                quoteId: this.recordId,
                lineItemsData: payload,
                referenceNumber: '',
                piDate: new Date().toISOString().split('T')[0],
                notes: ''
            });

            if (!result.success) {
                this.showToast('Error', result.error, 'error');
                return;
            }

            this.showToast('Success', 'Proforma Invoice created successfully!', 'success');

            // 🚀 Redirect to newly created Proforma Invoice
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: result.proformaInvoiceId,
                    objectApiName: 'Proforma_Invoice__c',
                    actionName: 'view'
                }
            });

        } catch (error) {
            this.showToast('Error', error.body?.message || error.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    handleCancel() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Quote',
                actionName: 'view'
            }
        });
    }
}