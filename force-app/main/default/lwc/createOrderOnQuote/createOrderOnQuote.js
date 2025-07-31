import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getInitialData from '@salesforce/apex/CreateOrderonQuote.getInitialData';
import createOrderFromQuote from '@salesforce/apex/CreateOrderonQuote.createOrderFromQuote';
import deleteQuoteLineItem from '@salesforce/apex/CreateOrderonQuote.deleteQuoteLineItem';

export default class CreateOrderFromQuote extends NavigationMixin(LightningElement) {
    @api recordId;
    @track orderFields = {
        status: 'Draft',
        effectiveDate: this.getDefaultEffectiveDate(),
        customerAuthorizedById: '',
        currencyCode: '',
        pricebookId: ''
    };
    @track statusOptions = [];
    @track currencyOptions = [];
    @track contacts = [];
    @track quoteLineItems = [];
    @track error;
    @track isLoading = false;

    connectedCallback() {
        this.loadInitialData();
    }

    getDefaultEffectiveDate() {
        const date = new Date();
        date.setDate(date.getDate() + 30); // Default to 30 days from now
        return date.toISOString().split('T')[0];
    }

    loadInitialData() {
        this.isLoading = true;
        getInitialData({ quoteId: this.recordId })
            .then(result => {
                this.orderFields = {
                    ...this.orderFields,
                    status: 'Draft',
                    effectiveDate: this.getDefaultEffectiveDate(),
                    customerAuthorizedById: result.quote.ContactId,
                    currencyCode: result.quote.CurrencyIsoCode,
                    pricebookId: result.quote.Pricebook2Id
                };
                this.statusOptions = result.statusOptions;
                this.currencyOptions = result.currencyOptions;
                this.contacts = result.contacts.map(contact => ({
                    label: contact.Name,
                    value: contact.Id
                }));

                this.quoteLineItems = result.lineItems.map(item => ({
                    ...item,
                    index: this.generateRandomNum(),
                    tempId: this.generateTempId(),
                    selected: true,
                    salesPrice: item.UnitPrice,
                    listPrice: item.PricebookEntry?.UnitPrice || item.UnitPrice,
                    Discount: item.Discount || 0,
                    Product2Id: item.Product2Id,
                    pbeId: item.PricebookEntryId,
                    prodName: item.Product2?.Name,
                    prodCode: item.Product2?.ProductCode,
                    Quantity: item.Quantity || 1,
                    Description: item.Description || ''
                }));
            })
            .catch(error => {
                this.error = error.body?.message || 'Failed to load initial data';
                this.showToast('Error', this.error, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    generateRandomNum() {
        return Math.floor(Math.random() * 9000) + 1000;
    }

    generateTempId() {
        return Date.now().toString(36) + Math.random().toString(36).substring(2);
    }

    handleFieldChange(event) {
        const field = event.target.dataset.field;
        this.orderFields = {
            ...this.orderFields,
            [field]: event.detail.value
        };
    }

    handleCheckboxChange(event) {
        const index = parseInt(event.target.dataset.index, 10);
        const isChecked = event.target.checked;

        this.quoteLineItems = this.quoteLineItems.map(item => {
            if (item.index === index) {
                return { ...item, selected: isChecked };
            }
            return item;
        });
    }

    handleValueSelectedOnAccount(event) {
        const { detail: selectedRecord, target } = event;
        const index = parseInt(target.dataset.index, 10);

        if (!selectedRecord) {
            this.showToast('Error', 'No product selected', 'error');
            return;
        }

        this.quoteLineItems = this.quoteLineItems.map(item =>
            item.index === index ? {
                ...item,
                PricebookEntryId: selectedRecord.id,
                pbeId: selectedRecord.id,
                UnitPrice: selectedRecord.unitPrice || 0,
                salesPrice: selectedRecord.unitPrice || 0,
                listPrice: selectedRecord.unitPrice || 0,
                Product2Id: selectedRecord.proId,
                prodId: selectedRecord.proId,
                Product2: {
                    Id: selectedRecord.proId,
                    Name: selectedRecord.mainField,
                    ProductCode: selectedRecord.subField || ''
                },
                prodName: selectedRecord.mainField,
                prodCode: selectedRecord.subField || '',
                isEdit: true,
                Discount: 0
            } : item
        );
        this.quoteLineItems = [...this.quoteLineItems];
    }

    handlePriceChange(event) {
        const index = parseInt(event.target.dataset.index, 10);
        const newPrice = parseFloat(event.target.value) || 0;

        this.quoteLineItems = this.quoteLineItems.map(item =>
            item.index === index ? {
                ...item,
                salesPrice: newPrice,
                UnitPrice: newPrice,
                // Reset discount when price is manually changed
                Discount: 0
            } : item
        );
    }

    handleQuantityChange(event) {
        const index = parseInt(event.target.dataset.index, 10);
        const newQuantity = parseFloat(event.target.value) || 0;

        this.quoteLineItems = this.quoteLineItems.map(item =>
            item.index === index ? { ...item, Quantity: newQuantity } : item
        );
    }

    handleDiscountChange(event) {
        const index = parseInt(event.target.dataset.index, 10);
        const newDiscount = parseFloat(event.target.value) || 0;

        this.quoteLineItems = this.quoteLineItems.map(item =>
            item.index === index ? {
                ...item,
                Discount: newDiscount,
                //   salesPrice: item.UnitPrice * (1 - (newDiscount / 100)) // Apply discount to UnitPrice
            } : item
        );
    }

    validateData() {
        const selectedItems = this.quoteLineItems.filter(item => item.selected);

        if (selectedItems.length === 0) {
            this.showToast('Error', 'Please select at least one product', 'error');
            return false;
        }

        for (let item of selectedItems) {
            if (!item.Product2Id) {
                this.showToast('Error', 'Please select a product for all selected rows', 'error');
                return false;
            }
            if (item.Quantity <= 0 || isNaN(item.Quantity)) {
                this.showToast('Error', `Enter valid quantity for ${item.Product2?.Name || 'product'}`, 'error');
                return false;
            }
            if (item.salesPrice <= 0 || isNaN(item.salesPrice)) {
                this.showToast('Error', `Enter valid price for ${item.Product2?.Name || 'product'}`, 'error');
                return false;
            }
            if (item.Discount < 0 || item.Discount > 100) {
                this.showToast('Error', `Discount must be between 0-100% for ${item.Product2?.Name || 'product'}`, 'error');
                return false;
            }
        }
        return true;
    }

    createOrder() {
        if (!this.validateData()) return;

        // Add specific status validation
        if (this.orderFields.status !== 'Draft') {
            this.showToast('Error', 'Order status must be Draft when creating a new order.');
            return;
        }

        this.isLoading = true;
        const selectedItems = this.quoteLineItems
            .filter(item => item.selected)
            .map(item => ({
                Product2Id: item.Product2Id,
                PricebookEntryId: item.PricebookEntryId,
                UnitPrice: item.UnitPrice,
                Quantity: item.Quantity,
                listPrice: item.listPrice,
                Discount: item.Discount,
                Description: item.Description || ''
            }));

        createOrderFromQuote({
            quoteId: this.recordId,
            lineItems: selectedItems,
            status: this.orderFields.status,
            effectiveDate: this.orderFields.effectiveDate,
            customerAuthorizedById: this.orderFields.customerAuthorizedById,
            currencyCode: this.orderFields.currencyCode,
            pricebookId: this.orderFields.pricebookId
        })
            .then(orderId => {
                this.showToast('Success', 'Order created successfully', 'success');
                this.navigateToRecord(orderId, 'Order');
            })
            .catch(error => {
                this.showToast('Error', error.body?.message || 'Order creation failed', 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    addAnswerItem(event) {
        const index = parseInt(event.target.dataset.index, 10);
        const originalItem = this.quoteLineItems.find(item => item.index === index);

        if (!originalItem) {
            console.error('Item not found for index:', index);
            return;
        }

        const newItem = {
            ...originalItem,
            index: this.generateRandomNum(),
            tempId: this.generateTempId(),
            Id: null,
            isEdit: false,
            isNew: true,
            Quantity: 1,
            salesPrice: originalItem.salesPrice,
            UnitPrice: originalItem.salesPrice,
            listPrice: originalItem.listPrice,
            Discount: originalItem.Discount
        };

        const originalIndex = this.quoteLineItems.findIndex(item => item.index === index);
        this.quoteLineItems.splice(originalIndex + 1, 0, newItem);
        this.quoteLineItems = [...this.quoteLineItems];
    }

    removeAnswer(event) {
        const index = parseInt(event.target.dataset.index, 10);
        const item = this.quoteLineItems.find(item => item.index === index);

        if (!item) {
            console.error('Item not found for index:', index);
            return;
        }

        if (item.Id) {
            this.isLoading = true;
            deleteQuoteLineItem({ Id: item.Id })
                .then(() => {
                    this.quoteLineItems = this.quoteLineItems.filter(i => i.index !== index);
                    this.quoteLineItems = [...this.quoteLineItems];
                    this.showToast('Success', 'Product removed successfully', 'success');
                })
                .catch(error => {
                    this.showToast('Error', error.body?.message || 'Failed to remove product', 'error');
                })
                .finally(() => {
                    this.isLoading = false;
                });
        } else {
            this.quoteLineItems = this.quoteLineItems.filter(i => i.index !== index);
            this.quoteLineItems = [...this.quoteLineItems];
            this.showToast('Success', 'Product removed successfully', 'success');
        }
    }

    navigateToRecord(recordId, objectApiName) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId,
                objectApiName,
                actionName: 'view'
            }
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    handleCancel() {
        this.navigateToRecord(this.recordId, 'Quote');
    }
}