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
    @track paymetTermField = true;
    @track statusOptions = [];
    @track currencyOptions = [];
    @track contacts = [];
    @track paymentTerms = [];
    @track incoTermsOptions = [];
    @track error;
    @track generatedIds = new Set();
    @track isLoading = false;
    @track hasProducts = false;

    connectedCallback() {
        this.loadInitialData();
        this.handleGetSalesOrg();
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
                this.paymentTerms = result.paymentTerms; // Add this
                this.incoTermsOptions = result.incoTermsOptions; // Add this

                // Set default contact if available from Apex
                if (result.defaultContact) {
                    this.quoteFields.contactId = result.defaultContact.value;
                }


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

    handlePaymentTermSelected(event) {
        const selectedRecord = event.detail;
        if (selectedRecord) {
            this.quoteFields.paymentTermId = selectedRecord.id;
        }
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
        const index = parseInt(event.target.dataset.index, 10);
        const newContainerType = event.target.value;

        this.oppLineItems = this.oppLineItems.map(item =>
            item.index === index ? {
                ...item,
                Container_Type__c: newContainerType
            } : item
        );
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
                        Customer_Target_Price__c: 0,  // Initialize with default value
                        Container_Type__c: '',  // Initialize with default value
                        Customer_Product_Name__c: '',
                        Customer_HS_Code__c: '',
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
                    Customer_Target_Price__c: item.Customer_Target_Price__c || 0,
                    Container_Type__c: item.Container_Type__c || '',
                    Customer_Product_Name__c: item.Customer_Product_Name__c || '',
                    Customer_HS_Code__c: item.Customer_HS_Code__c || '',
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

    handleFieldChange(event) {
        const field = event.target.dataset.field;

        // Don't handle paymentTermId here as it's handled by the lookup component
        if (field === 'paymentTermId') return;

        this.quoteFields = {
            ...this.quoteFields,
            [field]: event.detail.value
        };

        // If currency changes, we may want to refresh prices
        if (field === 'currencyCode') {
            console.log('Currency changed to:', this.quoteFields.currencyCode);
        }

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

    // handleFieldChange(event) {
    //     const field = event.target.dataset.field;
    //     this.quoteFields = {
    //         ...this.quoteFields,
    //         [field]: event.detail.value
    //     };

    //     // If currency changes, we may want to refresh prices
    //     if (field === 'currencyCode') {
    //         // You could add logic here to refresh prices if needed
    //         console.log('Currency changed to:', this.quoteFields.currencyCode);
    //     }
    // }

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

        // if (this.salesOrgValue == '') {
        //     this.showToast('Error', 'Please select a Sales Organization', 'error');
        //     return false;
        // }

        // if (this.distChValue == '') {
        //     this.showToast('Error', 'Please select a Distribution Channel', 'error');
        //     return false;
        // }

        // if (this.divisionValue == '') {
        //     this.showToast('Error', 'Please select a Division', 'error');
        //     return false;
        // }


        // Incoterms validation
        if (!this.quoteFields.incoTerms || this.quoteFields.incoTerms.trim() === '') {
            this.showToast('Error', 'Please select Inco terms', 'error');
            return false;
        }

        // Payment Term validation
        if (!this.quoteFields.paymentTermId || this.quoteFields.paymentTermId.trim() === '') {
            this.showToast('Error', 'Please select a Payment Terms', 'error');
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

    handleContainerTypeChange(event) {
        this.quoteFields = {
            ...this.quoteFields,
            containerType: event.target.value
        };
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
            CustomerTargetPrice: item.Customer_Target_Price__c || 0, // Change to wrapper field name
            ContainerType: item.Container_Type__c || '',// Change to wrapper field name
            CustomerProductName: item.Customer_Product_Name__c,
            CustomerHsCode: item.Customer_HS_Code__c
        }));

        createQuoteFromOpportunity({
            opportunityId: this.recordId,
            lineItems: lineItemsWithNewFields, // This now matches the wrapper structure
            quoteName: this.quoteFields.name,
            status: this.quoteFields.status,
            expirationDate: this.quoteFields.expirationDate,
            currencyCode: this.quoteFields.currencyCode,
            contactId: this.quoteFields.contactId,
            pricebookId: this.quoteFields.pricebookId,
            incoTerms: this.quoteFields.incoTerms,
            paymentTermId: this.quoteFields.paymentTermId,
            transportationCost: this.quoteFields.transportationCost, // Add this
            containerType: this.quoteFields.containerType // Add this
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
            Description: originalItem.Description,
            Customer_Target_Price__c: originalItem.Customer_Target_Price__c || 0, // Preserve this field
            Container_Type__c: originalItem.Container_Type__c || '', // Preserve this field
            Customer_Product_Name__c: originalItem.Customer_Product_Name__c || '', // Preserve this field
            Customer_HS_Code__c: originalItem.Customer_HS_Code__c || '', // Preserve this field
            selected: true,
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
                // this.quoteFields.salesArea = JSON.parse(result);
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