import { LightningElement, api } from 'lwc';
import fetchRecords from '@salesforce/apex/ReusableLookupController.fetchRecords';
/** The delay used when debouncing event handlers before invoking Apex. */
const DELAY = 500;

export default class ReusableLookup extends LightningElement {
    @api helpText = "custom search lookup";
    @api label = "Parent Account";
    @api required;
    @api selectedIconName = "standard:account";
    @api objectLabel = "PricebookEntry";
    recordsList = [];
    @api currencyCode;
    selectedRecordName;

    @api objectApiName = "PricebookEntry";
    @api fieldApiName = "Product2Id,Product2.Name,Product2.ProductCode";
    @api otherFieldApiName = "";
    @api searchString = "";
    @api selectedRecordId = "";
    @api parentRecordId;
    @api parentFieldApiName;
    @api leadRecordType;




    preventClosingOfSerachPanel = false;

    get methodInput() {
        return {
            objectApiName: this.objectApiName,
            fieldApiName: this.fieldApiName,
            otherFieldApiName: this.otherFieldApiName,
            searchString: this.searchString,
            selectedRecordId: this.selectedRecordId,
            parentRecordId: this.parentRecordId,
            parentFieldApiName: this.parentFieldApiName,
            leadRecordType: this.leadRecordType
        };
    }

    get showRecentRecords() {
        if (!this.recordsList) {
            return false;
        }
        return this.recordsList.length > 0;
    }

    //getting the default selected record
    connectedCallback() {
        if (this.selectedRecordId) {
            this.fetchSobjectRecords(true);
        }
    }

    //call the apex method
    fetchSobjectRecords(loadEvent) {
        fetchRecords({
            inputWrapper: this.methodInput,
            currencyCode: this.currencyCode
        }).then(result => {
            if (loadEvent && result) {
                this.selectedRecordName = result[0].mainField;
            } else if (result) {
                this.recordsList = JSON.parse(JSON.stringify(result));
            } else {
                this.recordsList = [];
            }
        }).catch(error => {
            console.log(error);
        })
    }

    get isValueSelected() {
        return this.selectedRecordId;
    }

    //handler for calling apex when user change the value in lookup
    handleChange(event) {
        this.searchString = event.target.value;
        this.fetchSobjectRecords(false);
    }

    //handler for clicking outside the selection panel
    handleBlur() {
        this.recordsList = [];
        this.preventClosingOfSerachPanel = false;
    }

    //handle the click inside the search panel to prevent it getting closed
    handleDivClick() {
        this.preventClosingOfSerachPanel = true;
    }

    //handler for deselection of the selected item
    handleCommit() {
        this.selectedRecordId = "";
        this.selectedRecordName = "";
    }

    //handler for selection of records from lookup result list
    handleSelect(event) {
        console.log('event.currentTarget ', event.currentTarget);
        let selectedRecord = {
            mainField: event.currentTarget.dataset.mainfield,
            subField: event.currentTarget.dataset.subfield,
            familyField: event.currentTarget.dataset.familyField,
            unitPrice: event.currentTarget.dataset.unitprice,
            proId: event.currentTarget.dataset.proid,
            uom: event.currentTarget.dataset.uom,
            productPlant: event.currentTarget.dataset.productPlant,
            id: event.currentTarget.dataset.id,
            description: event.currentTarget.dataset.description
        };
        this.selectedRecordId = selectedRecord.id;
        this.selectedRecordName = selectedRecord.mainField;
        this.recordsList = [];

        console.log('OUTPUT :in reuasable cmp ', selectedRecord);
        // Creates the event
        const selectedEvent = new CustomEvent('valueselected', {
            detail: selectedRecord
        });
        //dispatching the custom event
        this.dispatchEvent(selectedEvent);
    }

    //to close the search panel when clicked outside of search input
    handleInputBlur(event) {
        // Debouncing this method: Do not actually invoke the Apex call as long as this function is
        // being called within a delay of DELAY. This is to avoid a very large number of Apex method calls.
        window.clearTimeout(this.delayTimeout);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.delayTimeout = setTimeout(() => {
            if (!this.preventClosingOfSerachPanel) {
                this.recordsList = [];
            }
            this.preventClosingOfSerachPanel = false;
        }, DELAY);
    }

}