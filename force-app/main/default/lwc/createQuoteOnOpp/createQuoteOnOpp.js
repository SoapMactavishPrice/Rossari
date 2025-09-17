import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOppLineItems from '@salesforce/apex/QuoteController.getOppLineItems';
import getQuoteInitialData from '@salesforce/apex/QuoteController.getQuoteInitialData';
import createQuoteFromOpportunity from '@salesforce/apex/QuoteController.createQuoteFromOpportunity';
import deleteProductInterested from '@salesforce/apex/QuoteController.deleteProductInterested';
import sendEmailToManagerForQuote from '@salesforce/apex/ManagerEmailSender.sendEmailToManagerForQuote';
export default class CreateQuoteFromOpportunity extends NavigationMixin(LightningElement) {
    @api recordId;
    @track oppLineItems = [];
    @track quoteFields = {
        name: '',
        status: '',
        expirationDate: '',
        contactId: '',
        currencyCode: '',
        pricebookId: ''
    };
    @track statusOptions = [];
    @track currencyOptions = [];
    @track contacts = [];
    @track error;
    @track generatedIds = new Set();
    @track isLoading = false;
    @track hasProducts = false;

    connectedCallback() {
        this.loadInitialData();
    }

    loadInitialData() {
        this.isLoading = true;
        getQuoteInitialData({ opportunityId: this.recordId })
            .then(result => {
                this.quoteFields = {
                    ...this.quoteFields,
                    name: result.opportunityName,
                    currencyCode: result.defaultCurrency,
                    pricebookId: result.pricebookId
                };
                this.statusOptions = result.statusOptions;
                this.currencyOptions = result.currencyOptions;
                this.contacts = result.contacts.map(contact => ({
                    label: contact.Name,
                    value: contact.Id
                }));

                if (this.statusOptions.length > 0) {
                    this.quoteFields.status = this.statusOptions[0].value;
                }

                const date = new Date();
                date.setDate(date.getDate() + 30);
                this.quoteFields.expirationDate = date.toISOString().split('T')[0];

                this.loadOppLineItems();
            })
            .catch(error => {
                this.error = error.body.message;
                this.showToast('Error', this.error, 'error');
                this.isLoading = false;
            });
    }


    handleDiscountChange(event) {
        const index = parseInt(event.target.dataset.index, 10);
        const newDiscount = parseFloat(event.target.value) || 0;

        this.oppLineItems = this.oppLineItems.map(item =>
            item.index === index ? {
                ...item,
                Discount: newDiscount,
                //  salesPrice: item.UnitPrice * (1 - (newDiscount / 100))
            } : item
        );
    }

    handleContactClick() {
        if (this.contacts.length === 0) {
            this.showToast('Warning', 'No contacts available for this Opportunity\'s Account.', 'warning');
        }
    }


    loadOppLineItems() {
        getOppLineItems({ opportunityId: this.recordId })
            .then(result => {
                console.log('>>> Opp Line Items Raw Result:', result);
                if (result && result.length > 0) {
                    this.hasProducts = true;
                    this.oppLineItems = result.map(item => ({
                        ...item,
                        index: this.generateRandomNum(),
                        tempId: Date.now().toString() + Math.random().toString(16).slice(2),
                        isEdit: !!item.Id,
                        isNew: !item.Id,
                        salesPrice: item.UnitPrice,
                        listPrice: item.PricebookEntry?.UnitPrice || item.UnitPrice,
                        pbeId: item.PricebookEntryId,
                        prodId: item.Product2Id,
                        prodName: item.Product2?.Name || '',
                        prodCode: item.Product2?.ProductCode || '',
                        Description: item.Product2?.Description,
                        Discount: item.Discount || 0,
                        selected: true,
                        Product2: {
                            Id: item.Product2Id,
                            Name: item.Product2?.Name || '',
                            ProductCode: item.Product2?.ProductCode || '',
                            Description: item.Description || '',
                        }
                    }));
                } else {
                    this.hasProducts = false;
                    this.showToast('Warning',
                        'No products available in Opportunity. Please add products before creating a Quote.',
                        'warning');
                }
            })
            .catch(error => {
                this.error = error.body.message;
                this.showToast('Error', this.error, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    get disableCreateButton() {

        return this.isLoading || this.oppLineItems.length === 0 || !this.hasProducts;
    }

    generateRandomNum() {
        let randomId;
        do {
            randomId = Math.floor(Math.random() * 9000) + 1000;
        } while (this.generatedIds.has(randomId));
        this.generatedIds.add(randomId);
        return randomId;
    }

    handleCheckboxChange(event) {
        const index = parseInt(event.target.dataset.index, 10);
        const isChecked = event.target.checked;

        this.oppLineItems = this.oppLineItems.map(item => {
            if (item.index === index) {
                return { ...item, selected: isChecked };
            }
            return item;
        });
    }

    handleValueSelectedOnAccount(event) {
        console.log('=== DEBUG: handleValueSelectedOnAccount triggered ===');
        console.log('Event detail:', JSON.stringify(event.detail));

        const selectedRecord = event.detail;
        const index = parseInt(event.target.dataset.index, 10);

        if (!selectedRecord) {
            console.log("No record selected");
            return;
        }

        console.log('Selected record description:', selectedRecord.description);

        this.oppLineItems = this.oppLineItems.map((item) => {
            if (item.index === index) {
                const updatedItem = {
                    ...item,
                    PricebookEntryId: selectedRecord.id,
                    pbeId: selectedRecord.id,
                    UnitPrice: selectedRecord.unitPrice || 0,
                    salesPrice: selectedRecord.unitPrice || 0,
                    listPrice: selectedRecord.unitPrice || 0,
                    Product2Id: selectedRecord.proId,
                    prodId: selectedRecord.proId,
                    Description: selectedRecord.description || '', // Get description from selected product
                    Product2: {
                        Id: selectedRecord.proId,
                        Name: selectedRecord.mainField,
                        ProductCode: selectedRecord.subField || '',
                        Description: selectedRecord.description || '' // Get description from selected product
                    },
                    prodName: selectedRecord.mainField,
                    prodCode: selectedRecord.subField || '',
                    isEdit: true
                };

                console.log('Updated item description:', updatedItem.Description);
                return updatedItem;
            }
            return item;
        });

        this.oppLineItems = [...this.oppLineItems];
    }



    handlePriceChange(event) {
        const index = parseInt(event.target.dataset.index, 10);
        const newPrice = parseFloat(event.target.value) || 0;

        this.oppLineItems = this.oppLineItems.map(item => {
            if (item.index === index) {
                return {
                    ...item,
                    salesPrice: newPrice,
                    UnitPrice: newPrice,
                    Discount: 0 // Reset discount when price is manually changed
                };
            }
            return item;
        });
    }

    handleQuantityChange(event) {
        const index = parseInt(event.target.dataset.index, 10);
        const newQuantity = parseFloat(event.target.value) || 0;

        this.oppLineItems = this.oppLineItems.map(item => {
            if (item.index === index) {
                return {
                    ...item,
                    Quantity: newQuantity
                };
            }
            return item;
        });
    }

    handleFieldChange(event) {
        const field = event.target.dataset.field;
        this.quoteFields = {
            ...this.quoteFields,
            [field]: event.detail.value
        };

        // If currency changes, we may want to refresh prices
        if (field === 'currencyCode') {
            // You could add logic here to refresh prices if needed
            console.log('Currency changed to:', this.quoteFields.currencyCode);
        }
    }

    validateData(itemsToValidate = this.oppLineItems) {
        let isValid = true;

        if (!this.quoteFields.name) {
            this.showToast('Error', 'Please enter a quote name', 'error');
            return false;
        }

        if (!this.quoteFields.expirationDate) {
            this.showToast('Error', 'Please select an expiration date', 'error');
            return false;
        }

        for (let item of itemsToValidate) {
            if (!item.Product2Id || item.Product2Id === '') {
                this.showToast('Error', 'Please select a product for all selected rows.', 'error');
                isValid = false;
                break;
            }

            if (item.Quantity <= 0 || isNaN(item.Quantity)) {
                this.showToast('Error', `Please enter valid quantity for ${item.Product2?.Name || 'product'}`, 'error');
                isValid = false;
                break;
            }

            if (item.salesPrice <= 0 || isNaN(item.salesPrice)) {
                this.showToast('Error', `Please enter valid sales price for ${item.Product2?.Name || 'product'}`, 'error');
                isValid = false;
                break;
            }

            if (item.Discount < 0 || item.Discount > 100) {
                this.showToast('Error', `Discount must be between 0-100% for ${item.Product2?.Name || 'product'}`, 'error');
                isValid = false;
                break;
            }
        }

        return isValid;
    }

    createQuote() {
        const selectedItems = this.oppLineItems.filter(item => item.selected);

        if (selectedItems.length === 0) {
            this.showToast('Error', 'Please select at least one product to create the quote.', 'error');
            return;
        }

        if (!this.validateData(selectedItems)) {
            return;
        }

        this.isLoading = true;

        createQuoteFromOpportunity({
            opportunityId: this.recordId,
            lineItems: selectedItems.map(item => ({
                ...item,
                UnitPrice: item.salesPrice // Use the discounted price
            })),
            quoteName: this.quoteFields.name,
            status: this.quoteFields.status,
            expirationDate: this.quoteFields.expirationDate,
            currencyCode: this.quoteFields.currencyCode,
            contactId: this.quoteFields.contactId,
            pricebookId: this.quoteFields.pricebookId
        })


            .then(quoteId => {
                // First show success toast
                this.showToast('Success', 'Quote created successfully', 'success');

                // Add slight delay before calling Apex method
                setTimeout(() => {
                    sendEmailToManagerForQuote({ quoteId: quoteId })
                        .then(() => {
                            console.log('Manager email check executed successfully.');
                        })
                        .catch(error => {
                            console.error('Error sending manager email:', error);
                        });
                }, 1000); // 1-second delay


                // Navigate to the new quote record
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: quoteId,
                        objectApiName: 'Quote',
                        actionName: 'view'
                    }
                });
                setTimeout(() => {
                    window.location.reload();
                }, 2000);
            })


            .catch(error => {
                this.showToast('Error', error.body?.message || 'Failed to create quote', 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    addAnswerItem(event) {
        const index = parseInt(event.target.dataset.index, 10);
        const originalItem = this.oppLineItems.find(item => item.index === index);

        if (!originalItem) {
            console.error('Item not found for index:', index);
            return;
        }

        const newItem = {
            ...originalItem,
            index: this.generateRandomNum(),
            tempId: Date.now().toString() + Math.random().toString(16).slice(2),
            Id: null,
            isEdit: false,
            isNew: true,
            Quantity: 1,
            salesPrice: originalItem.salesPrice,
            UnitPrice: originalItem.salesPrice,
            Description: originalItem.Description
        };

        const originalIndex = this.oppLineItems.findIndex(item => item.index === index);
        this.oppLineItems.splice(originalIndex + 1, 0, newItem);
        this.oppLineItems = [...this.oppLineItems];
    }

    removeAnswer(event) {
        const index = parseInt(event.target.dataset.index, 10);
        const item = this.oppLineItems.find(item => item.index === index);

        if (!item) {
            console.error('Item not found for index:', index);
            return;
        }

        if (item.Id) {
            this.isLoading = true;
            deleteProductInterested({ Id: item.Id })
                .then(() => {
                    this.showToast('Success', 'Product removed successfully', 'success');
                    this.oppLineItems = this.oppLineItems.filter(i => i.index !== index);
                    this.oppLineItems = [...this.oppLineItems];
                })
                .catch(error => {
                    this.showToast('Error', error.body?.message || 'Failed to remove product', 'error');
                })
                .finally(() => {
                    this.isLoading = false;
                });
        } else {
            this.oppLineItems = this.oppLineItems.filter(i => i.index !== index);
            this.oppLineItems = [...this.oppLineItems];
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        }));
    }

    handleCancel() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Opportunity',
                actionName: 'view'
            }
        });
    }
}