import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getSampleRequestData from '@salesforce/apex/SampleOutController.getSampleRequestData';
import saveSampleOut from '@salesforce/apex/SampleOutController.saveSampleOut';
import getAddressDataByPin from '@salesforce/apex/SampleOutController.getAddressDataByPin';
import getPicklistValues from '@salesforce/apex/SampleOutController.getPicklistValues';
import getCurrencyFromRequest from '@salesforce/apex/SampleOutController.getCurrencyFromRequest';
import { CurrentPageReference } from 'lightning/navigation';

export default class SampleOutForm extends NavigationMixin(LightningElement) {
    @api recordId;
    @track sampleOut = {
        SampleRequest: null,
        SampleSentByFactoryToHO: new Date().toISOString().split('T')[0],
        SAPSampleDocumentType: '',
        IncoTerms: '',
        CurrencyIsoCode: '',
        SampleReceivedByEndPerson: ''
    };
    @track sampleOutLines = [];
    @track plants = [];
    @track isLoading = false;
    @track showSpinner = false;
    @track selectedPinCode = '';
    @track selectedCityId = '';
    @track selectedStateId = '';
    @track selectedCountryId = '';
    @track selectedRegion = '';
    @track selectedZone = '';
    @track isPinCodeLoading = false;
    @track sapSampleDocOptions = [];
    @track incoTermsOptions = [];
    @track currencyOptions = [];
    @track Selected = true;

    connectedCallback() {
        if (this.recordId) {
            this.sampleOut.SampleRequest = this.recordId;
            this.loadData();
            this.loadPicklistValues();
            this.fetchCurrencyFromRequest();
        } else {
            console.error('No recordId provided');
            this.showError('Error', 'No Sample Request specified');
        }
    }

    fetchCurrencyFromRequest() {
        getCurrencyFromRequest({ sampleRequestId: this.recordId })
            .then(result => {
                this.selectedCurrency = result;
                this.sampleOut.CurrencyIsoCode = result;

                // If you need to support multiple currencies, you could load them here
                // This example assumes single currency from the request
                this.currencyOptions = [{
                    label: result,
                    value: result
                }];
            })
            .catch(error => {
                console.error('Error fetching currency:', error);
                this.showError('Error', 'Failed to load currency information');
            });
    }

    loadPicklistValues() {
        getPicklistValues({})
            .then(result => {
                this.sapSampleDocOptions = result.sapSampleDocOptions.map(item => ({
                    label: item.label,
                    value: item.value
                }));
                this.incoTermsOptions = result.incoTermsOptions.map(item => ({
                    label: item.label,
                    value: item.value
                }));
            })
            .catch(error => {
                console.error('Error loading picklist values:', error);
                this.showError('Error', 'Failed to load picklist values');
            });
    }

    handlePinCodeChange(event) {
        const pinCodeId = event.detail.recordId;
        this.selectedPinCode = pinCodeId;

        if (pinCodeId) {
            this.isPinCodeLoading = true;
            getAddressDataByPin({ pinCodeId })
                .then(result => {
                    this.sampleOut = {
                        ...this.sampleOut,
                        PinCode: pinCodeId,
                        City: result.cityId || null,
                        State: result.stateId || null,
                        Country: result.countryId || null,
                        // You can store region and zone in extra fields if needed
                    };
                })
                .catch(error => {
                    console.error('Error:', error);
                })
                .finally(() => {
                    this.isPinCodeLoading = false;
                });
        } else {
            this.sampleOut = {
                ...this.sampleOut,
                PinCode: null,
                City: null,
                State: null,
                Country: null
            };
        }
    }



    loadData() {
        this.showSpinner = true;
        getSampleRequestData({ sampleRequestId: this.recordId })
            .then(result => {
                if (result) {
                    this.plants = result.plants.map(plant => ({
                        label: plant.Name,
                        value: plant.Id
                    }));

                    this.sampleOut.CurrencyIsoCode = result.currencyIsoCode;

                    if (result.lineItems && result.lineItems.length > 0) {
                        this.sampleOutLines = result.lineItems.map(item => ({
                            Id: this.generateId(),
                            Selected: true,
                            Product: item.Product__c,
                            Product_Name: item.Product__r.Name,
                            Product_Code: item.Product__r.ProductCode,
                            Description: item.Description__c || '',
                            SampleRequestLine: item.Id,
                            SampleQtyInKgs: item.Sample_Qty_in_Kgs__c || 0,
                            SampleOutPlant: item.Sample_Request_To_Plant__c,
                            Price: item.Price__c || 0
                        }));
                    } else {
                        this.showError('No Products', 'No line items found for this Sample Request');
                        this.addEmptyRow();
                    }
                }
            })
            .catch(error => {
                console.error('Error loading data:', error);
                this.showError('Error Loading Data', error.body?.message || error.message);
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }

    addEmptyRow() {
        this.sampleOutLines = [{
            Id: this.generateId(),
            Selected: true,
            Product: null,
            Product_Name: '',
            Product_Code: '',
            Description: '',
            SampleRequestLine: null,
            SampleQtyInKgs: 0,
            SampleOutPlant: null,
            Price: 0
        }];
    }

    handleCheckboxChange(event) {
        const index = parseInt(event.target.dataset.index, 10);
        const checked = event.target.checked;

        this.sampleOutLines = this.sampleOutLines.map((line, i) => {
            if (i === index) {
                return { ...line, Selected: checked };
            }
            return line;
        });
    }


    handleProductSelection(event) {
        const selectedRecord = event.detail;
        const index = parseInt(event.target.dataset.index, 10);

        this.sampleOutLines = this.sampleOutLines.map((item, idx) => {
            if (idx === index) {
                if (!selectedRecord || !selectedRecord.id) {

                    return {
                        ...item,
                        Product: null,
                        Product_Name: '',
                        Product_Code: '',
                        Description: '',
                        SampleOutPlant: null
                    };
                } else {
                    // Product selected
                    return {
                        ...item,
                        Product: selectedRecord.id,
                        Product_Name: selectedRecord.mainField,
                        Product_Code: selectedRecord.subField || '',
                        Description: selectedRecord.description || '',
                        SampleOutPlant: selectedRecord.productPlant || ''
                    };
                }
            }
            return item;
        });

        this.sampleOutLines = [...this.sampleOutLines];
    }



    handleAddProduct() {
        const newLine = {
            Id: this.generateId(),
            Selected: true,
            Product: null,
            Product_Name: '',
            Product_Code: '',
            Description: '',
            SampleRequestLine: null,
            SampleQtyInKgs: 0,
            SampleOutPlant: null,
            Price: 0
        };
        this.sampleOutLines = [...this.sampleOutLines, newLine];
    }

    handleDelete(event) {
        const index = parseInt(event.target.dataset.index, 10);
        if (this.sampleOutLines.length > 1) {
            this.sampleOutLines.splice(index, 1);
            this.sampleOutLines = [...this.sampleOutLines];
        } else {
            this.showError('Cannot Delete', 'At least one product line is required');
        }
    }


    handleFieldChange(event) {
        const field = event.target.dataset.field;
        const value = event.target.value;  // <-- always use target.value
        this.sampleOut = { ...this.sampleOut, [field]: value };
    }


    handleSampleOutChange(event) {
        const field = event.target.dataset.id;
        const value = event.detail ? event.detail.value : event.target.value;
        this.sampleOut = { ...this.sampleOut, [field]: value };
    }


    handleAddressChange(event) {
        const field = event.target.dataset.field;
        const value = event.detail.recordId;
        this.sampleOut = { ...this.sampleOut, [field]: value };
    }

    handleLineChange(event) {
        const index = parseInt(event.target.dataset.index, 10);
        const field = event.target.dataset.field;
        let value = event.detail.value;

        if (field === 'SampleQtyInKgs' || field === 'Price') {
            value = value !== undefined && value !== null ? parseFloat(value) : 0;
        }

        this.sampleOutLines = this.sampleOutLines.map((line, i) => {
            if (i === index) {
                return { ...line, [field]: value };
            }
            return line;
        });
    }

    handleSave() {
        if (!this.validateForm()) return;

        const selectedLines = this.sampleOutLines.filter(line => line.Selected);

        if (selectedLines.length === 0) {
            this.showError('Validation Error', 'Please select at least one Product row to save.');
            return;
        }

        this.isLoading = true;

        const sampleOutToSend = {
            SampleRequest: this.sampleOut.SampleRequest,
            SampleSentByFactoryToHO: this.sampleOut.SampleSentByFactoryToHO,
            DeliveryDate: this.sampleOut.DeliveryDate,
            Country: this.sampleOut.Country,
            State: this.sampleOut.State,
            City: this.sampleOut.City,
            PinCode: this.sampleOut.PinCode,
            Street1: this.sampleOut.Street1,
            Street2: this.sampleOut.Street2,
            Street3: this.sampleOut.Street3,
            SAPSampleDocumentType: this.sampleOut.SAPSampleDocumentType,
            IncoTerms: this.sampleOut.IncoTerms,
            CurrencyIsoCode: this.sampleOut.CurrencyIsoCode,
            SampleReceivedByEndPerson: this.sampleOut.SampleReceivedByEndPerson
        };

        const linesToSend = selectedLines.map(line => ({
            Product: line.Product,
            SampleRequestLine: line.SampleRequestLine,
            SampleQtyInKgs: line.SampleQtyInKgs,
            SampleOutPlant: line.SampleOutPlant,
            Price: line.Price,
            Description: line.Description
        }));


        saveSampleOut({
            sampleOutJson: JSON.stringify(sampleOutToSend),
            sampleOutLinesJson: JSON.stringify(linesToSend)
        })

            .then(result => {
                this.showSuccess('Sample Out created successfully');
                this.navigateToRecord(result);
            })
            .catch(error => {
                let errorMessage = 'An unexpected error occurred';
                if (error.body) {
                    try {
                        const errorBody = JSON.parse(error.body.message);
                        errorMessage = errorBody.message || error.body.message;
                    } catch (e) {
                        errorMessage = error.body.message || error.message;
                    }
                } else {
                    errorMessage = error.message;
                }
                this.showError('Error saving sample out', errorMessage);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    validateForm() {
        // Validate Sample Out main fields
        if (!this.sampleOut.SAPSampleDocumentType) {
            this.showError('Missing Required Field', 'Please select SAP Sample Document Type');
            return false;
        }

        if (!this.sampleOut.IncoTerms) {
            this.showError('Missing Required Field', 'Please select Inco Term');
            return false;
        }

        if (!this.sampleOut.DeliveryDate) {
            this.showError('Missing Required Field', 'Please select Delivery Date');
            return false;
        }

        if (!this.sampleOut.PinCode) {
            this.showError('Missing Required Field', 'Please select Pin Code');
            return false;
        }

        if (!this.sampleOut.City) {
            this.showError('Missing Required Field', 'Please select City');
            return false;
        }

        if (!this.sampleOut.State) {
            this.showError('Missing Required Field', 'Please select State');
            return false;
        }

        if (!this.sampleOut.Country) {
            this.showError('Missing Required Field', 'Please select Country');
            return false;
        }

        if (!this.sampleOut.Street1 || this.sampleOut.Street1.trim() === '') {
            this.showError('Missing Required Field', 'Please enter Street 1');
            return false;
        }

        // Validate Sample Out Line Items
        for (let i = 0; i < this.sampleOutLines.length; i++) {
            const line = this.sampleOutLines[i];


            if (!line.Product || line.Product === '' || line.Product === null) {
                this.showError('Validation Error', 'Please select a Product for all rows');
                return false;
            }

            if (!line.SampleOutPlant || line.SampleOutPlant === '' || line.SampleOutPlant === null) {
                this.showError('Validation Error', 'Please select Plant for all rows');
                return false;
            }

            if (!line.SampleQtyInKgs || isNaN(line.SampleQtyInKgs) || parseFloat(line.SampleQtyInKgs) <= 0) {
                this.showError('Validation Error', 'Please enter valid Quantity for all rows');
                return false;
            }

            if (!line.Price || isNaN(line.Price) || parseFloat(line.Price) <= 0) {
                this.showError('Validation Error', 'Please enter valid Price for all rows');
                return false;
            }
        }

        return true;
    }



    generateId() {
        return Math.random().toString(36).substring(2, 15);
    }

    showSuccess(message) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Success',
            message: message,
            variant: 'success'
        }));
    }

    showError(title, message) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: 'error'
        }));
    }

    navigateToRecord(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
    }

    handleCancel() {
        if (this.recordId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    actionName: 'view'
                }
            });
        } else {
            this.showError('Navigation Error', 'No Sample Request ID found to navigate back.');
        }
    }

}