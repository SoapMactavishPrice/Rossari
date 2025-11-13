import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAllQuotations from '@salesforce/apex/SalesPriceApprovalForQuotation.getAllQuotations';
import updateQuoteLineItem from '@salesforce/apex/SalesPriceApprovalForQuotation.updateQuoteLineItem';
import USER_ID from '@salesforce/user/Id';
import { NavigationMixin } from 'lightning/navigation';

export default class QuoteSalesPriceApproval extends NavigationMixin(LightningElement) {
    @track quotes;
    @track updatedLineItems = new Map();
    @track isSaveDisabled = false;

    userId = USER_ID;

    @track statusOptions = [
        { label: 'Pending', value: 'Pending' },
        { label: 'Approved', value: 'Approved' },
        { label: 'Rejected', value: 'Rejected' }
    ];
    error;

    connectedCallback() {
        this.fetchQuotes();
    }

    fetchQuotes() {
        getAllQuotations()
            .then(result => {
                this.quotes = result.map(q => {
                    return {
                        ...q,
                        disableFields: q.disableFields
                    };
                });
                
                this.quotes.forEach(quote => {
                    quote.quoteLineItems.forEach(item => {
                        item.approvalLevelClass = this.getApprovalLevelClass(item.approvalLevel);
                        if (item.disableFields === undefined) {
                            item.disableFields = quote.disableFields;
                        }
                    });
                });
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
                this.redirectToHome();
                setTimeout(() => { window.location.reload(); }, 2500);
            });
    }

    getApprovalLevelClass(level) {
        switch(level) {
            case 'L2':
                return 'slds-theme_warning';
            case 'L3':
                return 'slds-theme_error';
            default:
                return 'slds-theme_default';
        }
    }

    getIsDisabled(quote, item) {
        return quote.disableFields || item.disableFields;
    }

    handleLineItemChanges(event) {
        const field = event.target.dataset.field;
        const lineItemId = event.target.dataset.id;
        const parentId = event.target.dataset.parent;
        const value = event.target.value;

        let specificQuote = this.quotes.find(quote => quote.quoteId == parentId);
        let specificQuoteLineItem = specificQuote.quoteLineItems.find(quoteLineItem => quoteLineItem.quoteLineItemId == lineItemId);

        const fieldMap = {
            'approvalstatus': 'approvalStatus',
            'approvalcomments': 'approvalComments'
        };
        
        const actualField = fieldMap[field] || field;
        specificQuoteLineItem[actualField] = value;
        specificQuoteLineItem['updated'] = true;
        specificQuote['updated'] = true;
    }

    saveChanges() {
        this.isSaveDisabled = true;
        
        console.log('Final Quote List', JSON.parse(JSON.stringify(this.quotes)));

        updateQuoteLineItem({quotationListStringObject: JSON.stringify(this.quotes)}).then((result) => {
            if (result == 'Success') {
                this.showToast('Success', 'Quotation Line Items updated successfully', 'success');
                this.redirectToHome();
                setTimeout(()=>{
                    window.location.reload();
                }, 1500)
            } else {
                this.showToast('Error', result, 'error');
            }
        }).catch((error)=>{
            this.isSaveDisabled = false;
            this.showToast('Error', error.body.message, 'error');
        })
    }

    redirectToHome() {
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'home'
            }
        });
    }

    showToast(title, msg, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant
        });
        this.dispatchEvent(evt);
    }
}