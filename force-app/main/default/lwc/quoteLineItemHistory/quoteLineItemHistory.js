import { LightningElement, track, api } from 'lwc';
import getQuoteLineItemHistory from '@salesforce/apex/QuoteLineItemHistoryController.getQuoteLineItemHistory';

export default class QuoteLineItemHistory extends LightningElement {
    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
        this.fetchData();
    }

    @track groupedItems = [];
    @track error;
    intervalId;

    connectedCallback() {
        this.fetchData();

        this.intervalId = setInterval(() => {
            this.fetchData();
        }, 60000);
    }

    disconnectedCallback() {
        if (this.intervalId) {
            clearInterval(this.intervalId);
        }
    }

    fetchData() {
        if (!this.recordId) {
            this.error = 'Quote ID is not provided';
            return;
        }

        getQuoteLineItemHistory({ quoteId: this.recordId })
            .then(data => {
                const qliMap = new Map();
                const isNotBlank = value => value !== null && value !== undefined && value !== '';

                data.forEach(record => {
                    const qliId = record.quoteLineItemId;
                    const formattedDate = this.formatDateTime(record.modifiedDate);

                    let formattedPrice = null;
                    let formattedQuantity = null;

                    if (record.field === 'UnitPrice' && isNotBlank(record.newValue)) {
                        formattedPrice = new Intl.NumberFormat('en-IN', {
                            style: 'currency',
                            currency: 'INR'
                        }).format(record.newValue);
                    }

                    if (record.field === 'Quantity' && isNotBlank(record.newValue)) {
                        formattedQuantity = new Intl.NumberFormat('en-IN').format(record.newValue);
                    }

                    if (!qliMap.has(qliId)) {
                        qliMap.set(qliId, {
                            product: record.productName,
                            items: []
                        });
                    }

                    const group = qliMap.get(qliId);
                    let existing = group.items.find(i => i.modifiedDate === formattedDate);

                    if (existing) {
                        // Set only the field that changed
                        if (record.field === 'UnitPrice') {
                            existing.salesPrice = formattedPrice;
                        }
                        if (record.field === 'Quantity') {
                            existing.quantity = formattedQuantity;
                        }
                    } else {
                        // Set only the correct field and leave the other blank
                        const item = {
                            id: record.id,
                            modifiedDate: formattedDate,
                            product: record.productName,
                            salesPrice: record.field === 'UnitPrice' ? formattedPrice : null,
                            quantity: record.field === 'Quantity' ? formattedQuantity : null
                        };
                        group.items.push(item);
                    }
                });

                this.groupedItems = Array.from(qliMap.values());
                this.error = null;
            })
            .catch(error => {
                this.error = error?.body?.message || 'Unknown error occurred';
                console.error(error);
            });
    }

    handleRefresh() {
        this.fetchData();
    }

    formatDateTime(dateTimeStr) {
        const date = new Date(dateTimeStr);
        const options = {
            year: 'numeric',
            month: 'short',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit',
            hour12: true
        };
        return new Intl.DateTimeFormat('en-US', options).format(date);
    }
}