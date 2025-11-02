import { LightningElement, track, wire, api } from "lwc";
import findRecords from "@salesforce/apex/lookupComponentController.findRecords";
import fetchDefaultRecord from "@salesforce/apex/lookupComponentController.fetchDefaultRecord";

export default class LookUpComponent extends LightningElement {
    @track recordsList;
    @api family = '';
    @track searchKey = "";
    @api selectedValue;
    @api selectedData = {};
    @api selectedRecordId;
    @api objectApiName;
    @api currencyCode;
    @api fieldName;
    @api returnFields;
    @api displayFields;
    @api queryFields = null;
    @api filter = '';
    @api sortColumn = '';
    @api maxResults = '';
    @api iconName;
    @api industryId;
    @api deptId;
    @api showIcon = false;
    @api lookupLabel;
    @track message;
    @api recdataid;
    @api defaultRecordId = '';
    @api disabled = false;
    @api searchWithMiddle = false;
    @api leadRecordType;
    @track displayFieldsList = [];

    @api
    getFilter(ispigment) {
        console.log('ispigment checked ', ispigment);
        this.isPigmenttrue = ispigment;
    }

    @api
    getFilterdept(isdept) {
        console.log('ispigment checked ', isdept);
        this.isdepttrue = isdept;
    }

    connectedCallback() {
        console.log('connectedCallback');
        console.log('this.defaultRecordId=-=>', this.defaultRecordId);

        if (this.displayFields != null && this.displayFields != '') {
            this.displayFieldsList = this.displayFields.split(',');
        }

        if (this.defaultRecordId != '') {
            fetchDefaultRecord({ recordId: this.defaultRecordId, 'sObjectApiName': this.objectApiName, returnFields: this.returnFields })
                .then((result) => {
                    if (result != null) {
                        let vdata = JSON.parse(result);
                        this.selectedRecordId = vdata.Id;
                        this.selectedValue = vdata.Name;
                        this.selectedData = vdata;
                        this.searchKey = "";
                        this.onSeletedRecordUpdate();
                    }
                })
                .catch((error) => {
                    this.error = error;
                    this.selectedRecord = {};
                });
        } else {
            console.log('blank else connected');
            this.removeRecordOnLookup();
        }
    }

    @api
    showMessage(strString) {
        console.log('showmessage');
        this.defaultRecordId = strString;
        console.log('defaultRecordId', this.defaultRecordId);
        this.connectedCallback();
    }

    renderedCallback() {
        console.log('This is From child component rendered callback');
    }

    onLeave(event) {
        setTimeout(() => {
            this.searchKey = "";
            this.recordsList = null;
        }, 300);
    }

    onRecordSelection(event) {
        // Get the closest element with data attributes
        const targetElement = event.target.closest('[data-key]');
        if (targetElement) {
            this.selectedRecordId = targetElement.dataset.key;
            this.selectedValue = targetElement.dataset.name;
            this.selectedData = this.recordsList.find(item => item.Id === this.selectedRecordId) || {};
            this.searchKey = "";
            this.onSeletedRecordUpdate();
        }
    }

    handleKeyChange(event) {
        const searchKey = event.target.value;
        this.searchKey = searchKey;
        this.getLookupResult();
    }

    handleIconClick(event) {
        console.log('handleIconClick');
        this.searchKey = '';
        this.getLookupResult();
    }

    @api index;

    @api
    removeRecordOnLookup(index) {
        console.log('removed index update v-->', index);
        this.searchKey = "";
        this.selectedValue = null;
        this.selectedRecordId = null;
        this.selectedData = null;
        this.recordsList = null;
        this.onSeletedRecordUpdate();
    }

    getLookupResult() {
        findRecords({
            indusId: this.industryId,
            deptId: this.deptId,
            searchKey: this.searchKey,
            objectName: this.objectApiName,
            recdataid: this.recdataid,
            returnFields: this.returnFields,
            queryFields: this.queryFields,
            displayFields: this.displayFields,
            filter: this.filter,
            sortColumn: this.sortColumn,
            maxResults: this.maxResults,
            searchWithMiddle: (this.searchWithMiddle == 'true'),
            family: this.family,
            currencyCode: this.currencyCode,
            leadRecordType: this.leadRecordType
        })
            .then(result => {
                let vData = JSON.parse(result);
                if (vData.length === 0) {
                    this.recordsList = [];
                    this.message = "No Records Found";
                } else {
                    console.log('OUTPUT : ', JSON.stringify(vData));
                    if (this.displayFields != null && this.displayFields != '') {
                        let vDf = this.displayFields.split(',').map(e => e.trim());
                        vData.forEach((e, i) => {
                            e.c__col1 = e[vDf[0]];
                            e.c__col2 = e[vDf[1]];
                            e.c__col3 = e[vDf[2]];
                            e.c__col4 = e[vDf[3]];
                            e.c__col5 = e[vDf[4]];
                        });
                    }
                    this.recordsList = vData;
                    this.message = "";
                }
                this.error = undefined;
            })
            .catch(error => {
                this.error = error;
                this.recordsList = undefined;
            });
    }

    onSeletedRecordUpdate() {
        const passEventr = new CustomEvent("recordselection", {
            detail: {
                selectedRecordId: this.selectedRecordId,
                selectedValue: this.selectedValue,
                selectedRecord: this.selectedData,
                index: this.index
            }
        });
        this.dispatchEvent(passEventr);
    }
}