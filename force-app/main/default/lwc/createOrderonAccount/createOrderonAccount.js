import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getExistingOrdersForAccount from '@salesforce/apex/CreateOrderFromAccount.getExistingOrdersForAccount';
import getOrderHeader from '@salesforce/apex/CreateOrderFromAccount.getOrderHeader';
import getOrderItems from '@salesforce/apex/CreateOrderFromAccount.getOrderItems';
import createOrderFromExisting from '@salesforce/apex/CreateOrderFromAccount.createOrderFromExisting';
import getPicklistValues from '@salesforce/apex/CreateOrderFromAccount.getPicklistValues';
import getContactsForAccount from '@salesforce/apex/CreateOrderFromAccount.getContactsForAccount';
import getAccountCurrency from '@salesforce/apex/CreateOrderFromAccount.getAccountCurrency';
import getInitialData from '@salesforce/apex/CreateOrderFromAccount.getInitialData';

export default class CreateOrderFromAccount extends NavigationMixin(LightningElement) {
    @api recordId;

    @track showModeSelection = true;
    @track showOrderSelection = false;
    @track showForm = false;

    @track selectedMode = 'new';
    modeOptions = [
        { label: 'New', value: 'new' },
        { label: 'Existing', value: 'existing' }
    ];

    @track existingOrders = [];
    @track selectedOrderId;

    @track orderFields = {
        status: 'Draft',
        effectiveDate: '',
        customerAuthorizedById: '',
        currencyCode: '',
        pricebookId: ''
    };

    @track statusOptions = [];
    @track currencyOptions = [];
    @track contacts = [];

    @track orderLineItems = [];
    @track isLoading = false;
    @track noExistingOrders = false;


    connectedCallback() {
        this.loadPicklists();
        this.loadContacts();

        if (this.selectedMode === 'new') {
            this.loadInitialData();
        }
    }

    loadPicklists() {
        getPicklistValues({ objectName: 'Order', fieldName: 'Status' })
            .then(res => this.statusOptions = res)
            .catch();
        getPicklistValues({ objectName: 'Order', fieldName: 'CurrencyIsoCode' })
            .then(res => this.currencyOptions = res)
            .catch();
    }

    loadContacts() {
        getContactsForAccount({ accountId: this.recordId })
            .then(data =>
                this.contacts = data.map(c => ({ label: c.Name, value: c.Id }))
            )
            .catch(() => this.showToast('Error', 'Cannot load contacts', 'error'));
    }

    get isExistingMode() {
        return this.selectedMode === 'existing';
    }


    handleModeChange(evt) {
        this.selectedMode = evt.detail.value;
        this.selectedOrderId = null;
        this.showForm = false;

        if (this.selectedMode === 'new') {
            this.loadInitialData();
        } else if (this.selectedMode === 'existing') {
            this.loadExistingOrders();
        }
    }


    loadExistingOrders() {
        this.isLoading = true;
        getExistingOrdersForAccount({ accountId: this.recordId })
            .then(res => {
                this.existingOrders = res;

                if (res.length === 0) {
                    // Show error toast message
                    this.showToast('No Orders', 'No existing orders found for this account.', 'error');

                    // Navigate back to mode selection
                    this.showOrderSelection = false;
                    this.showModeSelection = true;
                }
            })
            .catch(() => {
                this.showToast('Error', 'Cannot fetch existing orders.', 'error');
                this.showOrderSelection = false;
                this.showModeSelection = true;
            })
            .finally(() => {
                this.isLoading = false;
            });
    }


    handleOrderSelection(evt) {
        this.selectedOrderId = evt.detail.value;
        if (this.selectedOrderId) {
            this.loadSelectedOrder(this.selectedOrderId);
        }
    }


    loadSelectedOrder(orderId) {
        this.isLoading = true;
        Promise.all([
            getOrderHeader({ orderId }),
            getOrderItems({ orderId })
        ])
            .then(([h, items]) => {
                this.orderFields = {
                    status: h.Status,
                    effectiveDate: h.EffectiveDate,
                    customerAuthorizedById: h.CustomerAuthorizedById,
                    currencyCode: h.CurrencyIsoCode,
                    pricebookId: h.Pricebook2Id
                };
                this.orderLineItems = items.map(it => ({
                    index: this.generateRandomNum(),
                    tempId: this.generateTempId(),
                    prodName: it.Product2?.Name || '',
                    prodCode: it.Product2?.ProductCode || '',
                    PricebookEntryId: it.PricebookEntryId,
                    UnitPrice: it.UnitPrice,
                    listPrice: it.UnitPrice,
                    Quantity: it.Quantity,
                    Discount: it.Discount || 0,
                    selected: true
                }));
                this.showOrderSelection = false;
                this.showForm = true;
            })
            .catch(() => this.showToast('Error', 'Error loading order', 'error'))
            .finally(() => this.isLoading = false);
    }

    loadInitialData() {
        this.isLoading = true;
        getInitialData({ accountId: this.recordId })
            .then(result => {
                this.orderFields = {
                    status: 'Draft',
                    effectiveDate: this.getDefaultEffectiveDate(),
                    customerAuthorizedById: result.defaultContactId || '',
                    currencyCode: result.account.CurrencyIsoCode,
                    pricebookId: result.pricebook2Id
                };

                this.statusOptions = result.statusOptions;
                this.currencyOptions = result.currencyOptions;
                this.contacts = result.contacts.map(contact => ({
                    label: contact.Name,
                    value: contact.Id
                }));

                // Initialize with a single blank line item
                this.orderLineItems = [this.createEmptyLineItem()];
                this.showForm = true;
            })
            .catch(error => {
                this.showToast('Error', error.body?.message || 'Failed to load data', 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    getDefaultEffectiveDate() {
        const date = new Date();
        date.setDate(date.getDate() + 30);
        return date.toISOString().split('T')[0];
    }

    generateRandomNum() {
        return Math.floor(Math.random() * 9000) + 1000;
    }

    generateTempId() {
        return Date.now().toString(36) + Math.random().toString(36).substring(2);
    }

    handleFieldChange(evt) {
        const f = evt.target.dataset.field;
        this.orderFields[f] = evt.detail.value;
    }

    handleValueSelectedOnAccount(evt) {
        const sel = evt.detail;
        const idx = parseInt(evt.target.dataset.index, 10);
        if (!sel) return this.showToast('Error', 'No product selected', 'error');

        this.orderLineItems = this.orderLineItems.map(item =>
            item.index === idx ? {
                ...item,
                PricebookEntryId: sel.id,
                Product2Id: sel.productId || sel.proId,
                UnitPrice: sel.unitPrice || 0,
                listPrice: sel.unitPrice || 0,
                prodName: sel.mainField,
                prodCode: sel.subField || '',
                selected: true
            } : item
        );
    }

    handleCheckboxChange(event) {
        const idx = parseInt(event.target.dataset.index, 10);

    }

    handleCheckboxChange(event) {
        try {
            const idx = parseInt(event.target.dataset.index, 10);
            if (isNaN(idx)) {
                throw new Error('Invalid data-index on checkbox');
            }

            const isChecked = event.target.checked;

            this.orderLineItems = this.orderLineItems.map(item => {
                if (item.index === idx) {
                    return { ...item, selected: isChecked };
                }
                return item;
            });
        } catch (error) {
            console.error('Error in handleCheckboxChange:', error);
            this.showToast('Error', 'An error occurred while selecting line item', 'error');
        }
    }


    handleUnitPriceChange(evt) {
        const idx = parseInt(evt.target.dataset.index, 10);
        const val = parseFloat(evt.detail.value) || 0;
        this.orderLineItems = this.orderLineItems.map(i =>
            i.index === idx ? { ...i, UnitPrice: val } : i
        );
    }

    handleQuantityChange(evt) {
        const idx = parseInt(evt.target.dataset.index, 10);
        const val = parseFloat(evt.detail.value) || 0;
        this.orderLineItems = this.orderLineItems.map(i =>
            i.index === idx ? { ...i, Quantity: val } : i
        );
    }

    handleDiscountChange(evt) {
        const idx = parseInt(evt.target.dataset.index, 10);
        const val = parseFloat(evt.detail.value) || 0;
        this.orderLineItems = this.orderLineItems.map(i =>
            i.index === idx ? { ...i, Discount: val } : i
        );
    }

    addAnswerItem() {
        this.orderLineItems = [...this.orderLineItems, this.createEmptyLineItem()];
    }

    removeLineItem(evt) {
        const idx = evt.target.dataset.index;
        if (this.orderLineItems.length > 1) {
            this.orderLineItems = this.orderLineItems.filter(i => i.index != idx);
        }
    }

    createEmptyLineItem() {
        const idx = this.generateRandomNum();
        return {
            index: idx,
            tempId: this.generateTempId(),
            PricebookEntryId: '',
            prodName: '',
            UnitPrice: 0,
            listPrice: 0,
            Quantity: 1,
            Discount: 0,
            selected: true
        };
    }

    validateOrder() {
        // Validate contact
        // if (!this.orderFields.customerAuthorizedById) {
        //     this.showToast('Error', 'Please select a Contact', 'error');
        //     return false;
        // }

        const selectedItems = this.orderLineItems.filter(i => i.selected);
        if (!selectedItems.length) {
            this.showToast('Error', 'Select at least one product', 'error');
            return false;
        }

        for (const item of selectedItems) {
            if (!item.prodName) {
                this.showToast('Error', 'Product is required for all selected items', 'error');
                return false;
            }
            if (!(item.UnitPrice > 0)) {
                this.showToast('Error', `Unit Price must be greater than 0 for product ${item.prodName}`, 'error');
                return false;
            }
            if (!(item.Quantity > 0)) {
                this.showToast('Error', `Quantity must be greater than 0 for product ${item.prodName}`, 'error');
                return false;
            }
        }

        return true; // all good
    }


    createOrder() {

        if (!this.validateOrder()) {
            return; // stop if invalid
        }

        const sel = this.orderLineItems.filter(i => i.selected);
        console.log('createOrder: Selected line items:', sel);
        if (!sel.length) {
            console.warn('createOrder: No line items selected');
            return this.showToast('Error', 'Select at least one item', 'error');
        }

        this.isLoading = true;
        console.log('createOrder: Creating order with data:', {
            orderId: this.selectedMode === 'existing' ? this.selectedOrderId : null,
            orderItems: sel.map(i => ({
                Product2Id: i.Product2Id,
                PricebookEntryId: i.PricebookEntryId,
                UnitPrice: i.UnitPrice,
                Quantity: i.Quantity,
                Discount: i.Discount
            })),
            status: this.orderFields.status,
            effectiveDate: this.orderFields.effectiveDate,
            customerAuthorizedById: this.orderFields.customerAuthorizedById,
            currencyCode: this.orderFields.currencyCode,
            pricebookId: this.orderFields.pricebookId,
            accountId: this.recordId
        });

        createOrderFromExisting({
            orderId: this.selectedMode === 'existing' ? this.selectedOrderId : null,
            orderItems: sel.map(i => ({
                Product2Id: i.Product2Id,
                PricebookEntryId: i.PricebookEntryId,
                UnitPrice: i.UnitPrice,
                Quantity: i.Quantity,
                Discount: i.Discount
            })),
            status: this.orderFields.status,
            effectiveDate: this.orderFields.effectiveDate,
            customerAuthorizedById: this.orderFields.customerAuthorizedById,
            currencyCode: this.orderFields.currencyCode,
            pricebookId: this.orderFields.pricebookId,
            accountId: this.recordId
        })
            .then(newId => {
                console.log('createOrder: Order created successfully with Id:', newId);
                this.showToast('Success', 'Order created', 'success');
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: { recordId: newId, objectApiName: 'Order', actionName: 'view' }
                });
            })
            .catch(err => {
                console.error('createOrder: Error creating order:', err);
                this.showToast('Error', err.body?.message || 'Error', 'error');
            })
            .finally(() => {
                this.isLoading = false;
                console.log('createOrder: Finished create order operation');
            });
    }
    showToast(title, msg, variant = 'error') {
        this.dispatchEvent(new ShowToastEvent({ title, message: msg, variant }));
    }

    handleBack() {
        this.showForm = false;
        this.showOrderSelection = false;
        this.showModeSelection = true;
    }


    handleCancel() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: { recordId: this.recordId, objectApiName: 'Account', actionName: 'view' }
        });
    }
}