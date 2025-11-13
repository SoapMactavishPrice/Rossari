import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOppLineItems from '@salesforce/apex/QuoteController.getOppLineItems';
import getQuoteInitialData from '@salesforce/apex/QuoteController.getQuoteInitialData';
import createQuoteFromOpportunity from '@salesforce/apex/QuoteController.createQuoteFromOpportunity';
import deleteProductInterested from '@salesforce/apex/QuoteController.deleteProductInterested';
import sendEmailToManagerForQuote from '@salesforce/apex/ManagerEmailSender.sendEmailToManagerForQuote';
import getSalesOrg from '@salesforce/apex/QuoteController.getSalesOrg';
import getDistributionChannel from '@salesforce/apex/QuoteController.getDistributionChannel';
import getDivision from '@salesforce/apex/QuoteController.getDivision';
import getSalesArea from '@salesforce/apex/QuoteController.getSalesArea';
import getRecordTypeFromOpportunity from '@salesforce/apex/Utility.getRecordTypeFromOpportunity';

export default class CreateQuoteFromOpportunity extends NavigationMixin(LightningElement) {
    @api recordId;
    @track oppLineItems = [];
    @track quoteFields = {
        name: '',
        status: '',
        expirationDate: '',
        contactId: '',
        currencyCode: '',
        pricebookId: '',
        incoTerms: '',
        paymentTermId: '',
        transportationCost: 0,
        containerType: ''
    };
    @track showContainerType = false;
    @track paymetTermField = true;
    @track statusOptions = [];
    @track currencyOptions = [];
    @track contacts = [];
    @track paymentTerms = [];
    @track incoTermsOptions = [];
    @track error;
    @track generatedIds = new Set();
    @track isLoading = false;
    @track leadRecordType;
    @track hasProducts = false;

    // Add method to calculate discount
    calculateDiscount(listPrice, salesPrice) {
        if (!listPrice || listPrice <= 0 || !salesPrice || salesPrice <= 0) {
            return 0;
        }

        // Don't calculate discount if sales price is greater than list price
        if (salesPrice > listPrice) {
            return 0;
        }

        // Calculate discount percentage: ((List Price - Sales Price) / List Price) * 100
        const discount = ((listPrice - salesPrice) / listPrice) * 100;

        // Round to 2 decimal places
        return Math.round(discount * 100) / 100;
    }

    // Update handleValueSelectedOnAccount method
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
                const listPrice = selectedRecord.unitPrice || 0;
                const salesPrice = selectedRecord.unitPrice || 0; // Initially set sales price same as list price
                const discount = this.calculateDiscount(listPrice, salesPrice);

                const updatedItem = {
                    ...item,
                    PricebookEntryId: selectedRecord.id,
                    pbeId: selectedRecord.id,
                    UnitPrice: salesPrice,
                    salesPrice: salesPrice,
                    listPrice: listPrice,
                    Product2Id: selectedRecord.proId,
                    prodId: selectedRecord.proId,
                    Description: selectedRecord.description || '',
                    Customer_Target_Price__c: item.Customer_Target_Price__c || 0,
                    Container_Type__c: item.Container_Type__c || '',
                    Customer_Product_Name__c: item.Customer_Product_Name__c || '',
                    Customer_HS_Code__c: item.Customer_HS_Code__c || '',
                    Discount: discount, // Auto-calculate discount
                    Product2: {
                        Id: selectedRecord.proId,
                        Name: selectedRecord.mainField,
                        ProductCode: selectedRecord.subField || '',
                        Description: selectedRecord.description || ''
                    },
                    prodName: selectedRecord.mainField,
                    prodCode: selectedRecord.subField || '',
                    isEdit: true
                };

                console.log('Updated item - List Price:', updatedItem.listPrice, 'Sales Price:', updatedItem.salesPrice, 'Discount:', updatedItem.Discount);
                return updatedItem;
            }
            return item;
        });

        this.oppLineItems = [...this.oppLineItems];
    }

    // Update handlePriceChange method to auto-calculate discount
    handlePriceChange(event) {
        const index = parseInt(event.target.dataset.index, 10);
        const newPrice = parseFloat(event.target.value) || 0;

        this.oppLineItems = this.oppLineItems.map(item => {
            if (item.index === index) {
                const listPrice = item.listPrice || 0;
                const discount = this.calculateDiscount(listPrice, newPrice);

                return {
                    ...item,
                    salesPrice: newPrice,
                    UnitPrice: newPrice,
                    Discount: discount // Auto-calculate discount when price changes
                };
            }
            return item;
        });
    }

    // Remove the handleDiscountChange method since discount is now read-only
    // handleDiscountChange(event) {
    //     const index = parseInt(event.target.dataset.index, 10);
    //     const newDiscount = parseFloat(event.target.value) || 0;

    //     this.oppLineItems = this.oppLineItems.map(item =>
    //         item.index === index ? {
    //             ...item,
    //             Discount: newDiscount,
    //         } : item
    //     );
    // }

    // Update addAnswerItem method to calculate discount for new items
    addAnswerItem(event) {
        const index = parseInt(event.target.dataset.index, 10);
        const originalItem = this.oppLineItems.find(item => item.index === index);

        if (!originalItem) {
            console.error('Item not found for index:', index);
            return;
        }

        const listPrice = originalItem.listPrice || 0;
        const salesPrice = originalItem.salesPrice || 0;
        const discount = this.calculateDiscount(listPrice, salesPrice);

        const newItem = {
            ...originalItem,
            index: this.generateRandomNum(),
            tempId: Date.now().toString() + Math.random().toString(16).slice(2),
            Id: null,
            isEdit: false,
            isNew: true,
            Quantity: 1,
            salesPrice: salesPrice,
            UnitPrice: salesPrice,
            listPrice: listPrice,
            Discount: discount, // Set calculated discount
            Description: originalItem.Description,
            Customer_Target_Price__c: originalItem.Customer_Target_Price__c || 0,
            Container_Type__c: originalItem.Container_Type__c || '',
            Customer_Product_Name__c: originalItem.Customer_Product_Name__c || '',
            Customer_HS_Code__c: originalItem.Customer_HS_Code__c || '',
            selected: true,
        };

        const originalIndex = this.oppLineItems.findIndex(item => item.index === index);
        this.oppLineItems.splice(originalIndex + 1, 0, newItem);
        this.oppLineItems = [...this.oppLineItems];
    }

    // Update loadOppLineItems method to calculate discount for existing items
    loadOppLineItems() {
        getOppLineItems({ opportunityId: this.recordId })
            .then(result => {
                console.log('>>> Opp Line Items Raw Result:', result);
                if (result && result.length > 0) {
                    this.hasProducts = true;
                    this.oppLineItems = result.map(item => {
                        const listPrice = item.PricebookEntry?.UnitPrice || item.UnitPrice || 0;
                        const salesPrice = item.UnitPrice || 0;
                        const discount = this.calculateDiscount(listPrice, salesPrice);

                        return {
                            ...item,
                            index: this.generateRandomNum(),
                            tempId: Date.now().toString() + Math.random().toString(16).slice(2),
                            isEdit: !!item.Id,
                            isNew: !item.Id,
                            salesPrice: salesPrice,
                            listPrice: listPrice,
                            Discount: discount, // Set calculated discount
                            pbeId: item.PricebookEntryId,
                            prodId: item.Product2Id,
                            prodName: item.Product2?.Name || '',
                            prodCode: item.Product2?.ProductCode || '',
                            Description: item.Product2?.Description,
                            selected: true,
                            Customer_Target_Price__c: 0,
                            Container_Type__c: '',
                            Customer_Product_Name__c: '',
                            Customer_HS_Code__c: '',
                            Product2: {
                                Id: item.Product2Id,
                                Name: item.Product2?.Name || '',
                                ProductCode: item.Product2?.ProductCode || '',
                                Description: item.Description || '',
                            }
                        };
                    });
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

    // Rest of your existing methods remain exactly the same...
    handleContactClick() {
        if (this.contacts.length === 0) {
            this.showToast('Warning', 'No contacts available for Account. Please Create a Contact.', 'warning');
        }
    }

    handleCustomerTargetPriceChange(event) {
        const index = parseInt(event.target.dataset.index, 10);
        const newTargetPrice = parseFloat(event.target.value) || 0;

        this.oppLineItems = this.oppLineItems.map(item =>
            item.index === index ? {
                ...item,
                Customer_Target_Price__c: newTargetPrice
            } : item
        );
    }

    handleContainerTypeChange(event) {
        let newContainerType = event.target.value;

        // Remove any numbers and special characters, convert to uppercase
        newContainerType = newContainerType.replace(/[^A-Za-z\s]/g, '').toUpperCase();

        // Check if it's a line item (has data-index attribute)
        const index = event.target.dataset.index;

        if (index) {
            // It's a line item container type
            const itemIndex = parseInt(index, 10);
            this.oppLineItems = this.oppLineItems.map(item =>
                item.index === itemIndex ? {
                    ...item,
                    Container_Type__c: newContainerType
                } : item
            );
        } else {
            // It's the header container type
            this.quoteFields = {
                ...this.quoteFields,
                containerType: newContainerType
            };
        }

        // Update the input value to reflect the cleaned-up version
        event.target.value = newContainerType;
    }

    handleProductNameChange(event) {
        const index = parseInt(event.target.dataset.index, 10);
        const newProductName = event.target.value;

        this.oppLineItems = this.oppLineItems.map(item =>
            item.index === index ? {
                ...item,
                Customer_Product_Name__c: newProductName
            } : item
        );
    }

    handleHSCodeChange(event) {
        const index = parseInt(event.target.dataset.index, 10);
        const newHSCode = event.target.value;

        this.oppLineItems = this.oppLineItems.map(item =>
            item.index === index ? {
                ...item,
                Customer_HS_Code__c: newHSCode
            } : item
        );
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

    handlePaymentTermSelected(event) {
        console.log('=== DEBUG: handlePaymentTermSelected triggered ===');
        const selectedRecordId = event.detail.recordId;

        if (selectedRecordId) {
            this.quoteFields = {
                ...this.quoteFields,
                paymentTermId: selectedRecordId
            };
            console.log('Selected Payment Term ID:', this.quoteFields.paymentTermId);
        } else {
            // Clear selection if no record selected
            this.quoteFields = {
                ...this.quoteFields,
                paymentTermId: ''
            };
        }
    }

    handleIncoTermsChange(event) {
        const field = event.target.dataset.field;
        const newValue = event.detail.value;

        this.quoteFields = {
            ...this.quoteFields,
            [field]: newValue
        };

        // Show container type only when CIF is selected
        // this.showContainerType = newValue === 'CIF';

        this.showContainerType = true;

        // Optional: Clear container type when CIF is not selected
        if (!this.showContainerType) {
            this.quoteFields.containerType = '';
        }

        console.log('Inco Terms changed to:', newValue, 'Show Container Type:', this.showContainerType);
    }

    handleFieldChange(event) {
        const field = event.target.dataset.field;

        // Skip handling for incoTerms as it's now handled by handleIncoTermsChange
        if (field === 'incoTerms' || field === 'paymentTermId') return;

        this.quoteFields = {
            ...this.quoteFields,
            [field]: event.detail.value
        };

        // Your existing currency change logic
        if (field === 'currencyCode') {
            console.log('Currency changed to:', this.quoteFields.currencyCode);
        }

        // Your existing sales area logic
        if (field === 'salesOrg') {
            this.salesOrgValue = event.detail.value;
            console.log('salesOrg:', this.salesOrgValue);
            this.distChOptions = [];
            this.distChValue = '';
            this.divisionOptions = [];
            this.divisionValue = '';
            this.handleGetDistributionChannel();
        }
        if (field === 'distCh') {
            this.distChValue = event.detail.value;
            console.log('distCh:', this.distChValue);
            this.divisionOptions = [];
            this.divisionValue = '';
            this.handleGetDivision();
        }
        if (field === 'division') {
            this.divisionValue = event.detail.value;
            console.log('division:', this.divisionValue);
            this.handleGetSalesArea();
        }
    }

    validateData(itemsToValidate = this.oppLineItems) {
        let isValid = true;

        if (!this.quoteFields.name) {
            this.showToast('Error', 'Please enter a quote name', 'error');
            return false;
        }

        if (!this.quoteFields.contactId) {
            this.showToast('Error', 'Please select a Contact', 'error');
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

    handleTransportationCostChange(event) {
        this.quoteFields = {
            ...this.quoteFields,
            transportationCost: parseFloat(event.target.value) || 0
        };
    }

    // handleContainerTypeChange(event) {
    //     this.quoteFields = {
    //         ...this.quoteFields,
    //         containerType: event.target.value
    //     };
    // }

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

        // Prepare line items using wrapper structure
        const lineItemsWithNewFields = selectedItems.map(item => ({
            Id: item.Id,
            Product2Id: item.Product2Id,
            Product2Name: item.prodName,
            PricebookEntryId: item.PricebookEntryId,
            UnitPrice: item.salesPrice,
            Quantity: item.Quantity,
            Discount: item.Discount,
            Description: item.Description,
            CustomerTargetPrice: item.Customer_Target_Price__c || 0,
            ContainerType: item.Container_Type__c || '',
            CustomerProductName: item.Customer_Product_Name__c,
            CustomerHsCode: item.Customer_HS_Code__c
        }));

        createQuoteFromOpportunity({
            opportunityId: this.recordId,
            lineItems: lineItemsWithNewFields,
            quoteName: this.quoteFields.name,
            status: this.quoteFields.status,
            expirationDate: this.quoteFields.expirationDate,
            currencyCode: this.quoteFields.currencyCode,
            contactId: this.quoteFields.contactId,
            pricebookId: this.quoteFields.pricebookId,
            incoTerms: this.quoteFields.incoTerms,
            paymentTermId: this.quoteFields.paymentTermId,
            transportationCost: this.quoteFields.transportationCost,
            containerType: this.quoteFields.containerType
        })
            .then(quoteId => {
                this.showToast('Success', 'Quote created successfully', 'success');

                setTimeout(() => {
                    sendEmailToManagerForQuote({ quoteId: quoteId })
                        .then(() => {
                            console.log('Manager email check executed successfully.');
                        })
                        .catch(error => {
                            console.error('Error sending manager email:', error);
                        });
                }, 1000);

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

    generateRandomNum() {
        let randomId;
        do {
            randomId = Math.floor(Math.random() * 9000) + 1000;
        } while (this.generatedIds.has(randomId));
        this.generatedIds.add(randomId);
        return randomId;
    }

    connectedCallback() {
        this.loadInitialData();
        this.handleGetSalesOrg();
        this.getRecordType();
    }

    getRecordType() {
        getRecordTypeFromOpportunity({ opportunityId: this.recordId }).then(result => {
            this.leadRecordType = result;
        }).catch(error => {
            this.showError('Error fetching lead record type', error.body ? error.body.message : error.message);
        });
    }

    loadInitialData() {
        this.isLoading = true;
        getQuoteInitialData({ opportunityId: this.recordId })
            .then(result => {
                this.quoteFields = {
                    ...this.quoteFields,
                    name: result.opportunityName,
                    currencyCode: result.defaultCurrency,
                    pricebookId: result.pricebookId,
                    incoTerms: result.opportunityIncoTerms || '',
                    paymentTermId: result.opportunityPaymentTermId || ''
                };

                this.statusOptions = result.statusOptions;
                this.currencyOptions = result.currencyOptions;
                this.contacts = result.contacts.map(contact => ({
                    label: contact.Name,
                    value: contact.Id
                }));
                this.paymentTerms = result.paymentTerms;
                this.incoTermsOptions = result.incoTermsOptions;

                if (result.defaultContact) {
                    this.quoteFields.contactId = result.defaultContact.value;
                }

                if (this.statusOptions.length > 0) {
                    this.quoteFields.status = this.statusOptions[0].value;
                }

                const date = new Date();
                date.setDate(date.getDate() + 30);
                this.quoteFields.expirationDate = date.toISOString().split('T')[0];

                //  this.showContainerType = this.quoteFields.incoTerms === 'CIF';

                this.showContainerType = true;

                console.log('Opportunity Inco Terms:', result.opportunityIncoTerms);
                console.log('Opportunity Payment Term ID:', result.opportunityPaymentTermId);

                this.loadOppLineItems();
            })
            .catch(error => {
                this.error = error.body.message;
                this.showToast('Error', this.error, 'error');
                this.isLoading = false;
            });
    }

    // ------------------------- HA Changes -----------------------

    @track salesOrgOptions = [];
    @track salesOrgValue = '';
    @track distChOptions = [];
    @track distChValue = '';
    @track divisionOptions = [];
    @track divisionValue = '';

    handleGetSalesOrg() {
        getSalesOrg({
            oppId: this.recordId
        }).then(result => {
            console.log('>>> Sales Org Result:', result);
            if (result != '') {
                this.salesOrgOptions = JSON.parse(result);
            }
        }).catch(error => {
            this.showToast('Error', error.body?.message || 'Failed to fetch Sales Org', 'error');
        });
    }

    handleGetDistributionChannel() {
        getDistributionChannel({
            oppId: this.recordId,
            soId: this.salesOrgValue
        }).then(result => {
            console.log('>>> Distribution Channel Result:', result);
            if (result != '') {
                this.distChOptions = JSON.parse(result);
            }
        }).catch(error => {
            this.showToast('Error', error.body?.message || 'Failed to fetch Distribution Channel', 'error');
        });
    }

    handleGetDivision() {
        getDivision({
            oppId: this.recordId,
            soId: this.salesOrgValue,
            dcId: this.distChValue
        }).then(result => {
            console.log('>>> Division Result:', result);
            if (result != '') {
                this.divisionOptions = JSON.parse(result);
            }
        }).catch(error => {
            this.showToast('Error', error.body?.message || 'Failed to fetch Division', 'error');
        });
    }

    handleGetSalesArea() {
        getSalesArea({
            oppId: this.recordId,
            soId: this.salesOrgValue,
            dcId: this.distChValue,
            divId: this.divisionValue
        }).then(result => {
            if (result != '') {
                console.log('>>> SalesArea Result:', JSON.parse(result));
                let parsedResult = JSON.parse(result);
                if (parsedResult[0].Payment_Term__c != null) {
                    this.quoteFields.paymentTermId = parsedResult[0].Payment_Term__c;
                }
                if (parsedResult[0].Incoterm_1__c != null) {
                    this.quoteFields.incoTerms = parsedResult[0].Incoterm_1__c;
                }
            }
        }).catch(error => {
            this.showToast('Error', error.body?.message || 'Failed to fetch SalesArea', 'error');
        });
    }
}