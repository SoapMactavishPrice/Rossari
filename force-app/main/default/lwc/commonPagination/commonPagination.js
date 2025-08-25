import { LightningElement, api, track } from 'lwc';
import { publish, subscribe, unsubscribe, createMessageContext, releaseMessageContext }
    from 'lightning/messageService';
//import dmccMessageChannel from "@salesforce/messageChannel/DmccMessageChannel__c";

/**
 * reuseable component for pagination
 */
export default class CommonPagination extends LightningElement {
    @api allFilteredClients; //storing all filtered clients data. can be modified
    @api allClients;
    paginatedClientData; //storing array of client data based on limit chunks
    dataToDisplay; // storing only the data that need to be displayed
    pageLimit = '10'; //number of record to display per page
    pages = [{ label: '1', value: '1' }]; //pagination data (total pages)
    selectedPage = '1'; //current selected page
    totalPages; //store total number of pages
    isFisrt = true;
    isLast = false;
    isAsc = true; //sorting logic
    @api totalRecords;
    pageParam;
    dataToDisplay;

    selectedPageList = [];

    subscription = null;
    context = createMessageContext();  //create context
    @api checkboxCmp = false;


    //get options for the limit dropdown
    get pageLimitOptions() {
        return [
            { label: 'Step: 5', value: '5' },
            { label: 'Step: 10', value: '10' },
            { label: 'Step: 25', value: '25' },
            { label: 'Step: 50', value: '50' },
            { label: 'Step: 100', value: '100' },
        ];
    }

    connectedCallback() {
        console.log('checkboxCmp == >', this.checkboxCmp);
        //this.subscribeMC();
    }

    /**
     *
     * @param {*} a - first
     * @param {*} b -
     * @returns
     */
    compare(a, b) {
        // Use toUpperCase() to ignore character casing
        // console.log('compare ',a.Name);

        const bandA = a.Name.toUpperCase();
        const bandB = b.Name.toUpperCase();

        let comparison = 0;
        if (bandA > bandB) {
            comparison = 1;
        } else if (bandA < bandB) {
            comparison = -1;
        }
        // console.log('compare call',comparison);
        return comparison;
    }
    /**
     * purpose is to handle the sort event
     * @param {*} param
     */
    @api
    handleSort(param) {
        this.allClients = param;
        if (this.isAsc) {

            this.allFilteredClients = this.allClients.sort(this.compare);
            // console.log('allFilteredClients ',JSON.stringify(this.allFilteredClients));
            this.isAsc = false;
            // console.log('pagination bich me ');
            this.handlePagination(this.allFilteredClients);
        }
        else {
            // console.log('else ',JSON.stringify(this.allFilteredClients));
            // console.log('else ',JSON.stringify(this.allClients));
            this.allFilteredClients = this.allClients.sort(this.compare).reverse();
            this.isAsc = true;
            this.handlePagination(this.allFilteredClients);
        }

    }
    /**
     * purpose of this method is to give the updated data to display
     * @param {*} param
     */
    @api
    updateDataToDisplay(param) {
        // console.log('allProduct ', JSON.stringify(param));
        this.allClients = param;
        let recs = [];
        for (var i = 0; i < this.allClients.length; i++) {
            // console.log('this.allProduct ',this.allProduct[i].selectedProduct);
            for (var j = 0; j < this.dataToDisplay.length; j++) {
                if (this.allClients[i].Id == this.dataToDisplay[j].Id) {
                    // console.log('if ke undr');
                    let opp = {};
                    var abc = JSON.parse(JSON.stringify(this.allClients[i]));
                    opp = Object.assign(opp, abc);
                    recs.push(opp);
                }
            }
        }

        this.dataToDisplay = recs;
        // console.log('dataToDisplay ', JSON.stringify(this.dataToDisplay));
        this.fireCustomEvent();
    }




    //Method call when all checkbox is clicked
    @api
    handleAAllColumnCheckboxChange(event, param) {
        // console.log('pagination handleAAllColumnCheckboxChange call',JSON.stringify(param));
        this.allClients = param;
        this.showSelectedCheckbox(event);
        let recs = [];
        let Prodrecs = [];
        for (var i = 0; i < this.allClients.length; i++) {
            let prodopp = {};
            var prodabc = JSON.parse(JSON.stringify(this.allClients[i]));
            for (var j = 0; j < this.dataToDisplay.length; j++) {
                if (this.allClients[i].Id == this.dataToDisplay[j].Id) {
                    prodabc.selectedProduct = event.target.checked;

                    let opp = {};
                    var abc = JSON.parse(JSON.stringify(this.allClients[i]));
                    abc.selectedProduct = event.target.checked;
                    opp = Object.assign(opp, abc);
                    recs.push(opp);
                }
            }
            prodopp = Object.assign(prodopp, prodabc);
            Prodrecs.push(prodopp);
        }

        this.dataToDisplay = recs;
        this.allClients = Prodrecs;
        //    console.log('dataToDisplay ', JSON.stringify(this.dataToDisplay));
        this.fireCustomEvent();
    }
    /**
     * purpose of this method to show only those records if record is selected on various page
     * @param {*} event
     */
    showSelectedCheckbox(event) {
        // console.log('showSelectedCheckbox call',event.target.checked);
        // console.log('showSelectedCheckbox call',event.target.checked);
        if (event.target.checked) {
            this.allChecked = true;
            this.selectedPageList.push(this.selectedPage);
        } else {
            this.allChecked = false;
            //    console.log('==>', this.arrayRemove(this.selectedPageList,this.selectedPage));
            this.selectedPageList = this.arrayRemove(this.selectedPageList, this.selectedPage);
        }

        //    console.log('==>',this.selectedPageList);
        //    this.fireCustomEvent();
    }

    /**
     * purpose of this method is get all records if specified condtion is matched
     * @param {*} arr  - all records
     * @param {*} value  - record
     * @returns  filter records
     */
    arrayRemove(arr, value) {

        return arr.filter(function (ele) {
            return ele != value;
        });
    }
    /**
     * purpose of this method is to set the pagination logic, validate buttons first and last and call the custom event
     * @param {*} event
     */
    handleLimitChange(event) {
        this.pageLimit = event.detail.value;
        this.selectedPage = '1';
        this.isLast = false;
        this.isFirst = true;
        this.handlePagination(this.allFilteredClients); //invoking the pagination logic
        this.validatePagination();
        this.fireCustomEvent();
    }
    /**
     * purpose of this method is call the pagination logic whenever any list is loaded
     * @param {*} param - all records
     */
    @api
    handlePagination(param) {
        this.allFilteredClients = param;
        //  console.log('handlePagination ',JSON.stringify(param));
        //  console.log('handlePagination ',JSON.stringify(this.pageLimit));
        this.pages = [];
        this.totalPages = Math.ceil(this.allFilteredClients.length / parseInt(this.pageLimit));
        // console.log(this.totalPages);
        for (var i = 1; i <= this.totalPages; i++)
            this.pages.push({ label: 'Page: ' + i.toString(), value: i.toString() });
        var perChunk = parseInt(this.pageLimit) // items per chunk
        var inputArray = this.allFilteredClients;
        var result = inputArray.reduce((resultArray, item, index) => {
            const chunkIndex = Math.floor(index / perChunk)
            if (!resultArray[chunkIndex]) {
                resultArray[chunkIndex] = [] // start a new chunk
            }
            resultArray[chunkIndex].push(item)
            return resultArray
        }, [])

        this.paginatedClientData = result;

        // this.dataToDisplay=this.paginatedClientData[parseInt(this.selectedPage)-1];  //previous logic
        this.dataToDisplay = this.paginatedClientData[0]; //new logic

        // console.log('this.dataToDisplay ', JSON.stringify(this.dataToDisplay));
        this.fireCustomEvent();
    }
    /**
     * Purpose of this method is to handle next click  button
     */
    handleNext() {
        if (!this.isLast)
            console.log('this.selectedPage ', this.selectedPage);
        this.selectedPage = (parseInt(this.selectedPage) + 1).toString();
        this.dataToDisplay = this.paginatedClientData[parseInt(this.selectedPage) - 1];

        //  console.log('this.dataToDisplay ',JSON.stringify(this.dataToDisplay));
        this.validatePagination();

        if (this.checkboxCmp) {
            this.updateDataToDisplay(this.allClients);
            if (this.selectedPageList.includes(this.selectedPage)) {
                this.allChecked = true;
            } else {
                this.allChecked = false;
            }
        } else {
            this.fireCustomEvent();
        }
    }
    /**
  * Purpose of this method is to handle next click button
  */
    handlePrev() {
        if (!this.isFirst)
            this.selectedPage = (parseInt(this.selectedPage) - 1).toString();
        this.dataToDisplay = this.paginatedClientData[parseInt(this.selectedPage) - 1];
        this.validatePagination();

        if (this.checkboxCmp) {
            this.updateDataToDisplay(this.allClients);
            if (this.selectedPageList.includes(this.selectedPage)) {
                this.allChecked = true;
            } else {
                this.allChecked = false;
            }
        } else {
            this.fireCustomEvent();
        }
    }

    /**
     * purpose of this method to handle the page change event
     * @param {*} event
     */
    handlePageChange(event) {
        this.selectedPage = event.detail.value;
        this.dataToDisplay = this.paginatedClientData[parseInt(this.selectedPage) - 1];
        this.validatePagination();
        this.fireCustomEvent();
    }
    /**
     * purpose of this method to handle when first button is clicked
     */
    handleFirst() {
        this.selectedPage = '1';
        this.isFirst = true;
        this.isLast = false;
        this.dataToDisplay = this.paginatedClientData[parseInt(this.selectedPage) - 1];
        this.validatePagination();
        this.fireCustomEvent();
    }
    /**
     * purpose of this method to handle when last button is clicked
     */
    handleLast() {
        this.selectedPage = this.totalPages.toString();
        this.isFirst = false;
        this.isLast = true;
        this.dataToDisplay = this.paginatedClientData[parseInt(this.selectedPage) - 1];
        this.validatePagination();

        this.fireCustomEvent();
    }
    /**
     * global method - purpose of this method to validate the buttons when pagination calls
     */
    @api
    validatePagination() {
        if (parseInt(this.selectedPage) == 1) {
            this.isFirst = true;
            this.isLast = false;
        }
        else if (parseInt(this.selectedPage) == parseInt(this.totalPages)) {
            this.isFirst = false;
            this.isLast = true;
        }
        else {
            this.isFirst = false;
            this.isLast = false;
        }
        var end = (parseInt(this.selectedPage) * parseInt(this.pageLimit)) > this.totalRecords ? this.totalRecords : (parseInt(this.selectedPage) * parseInt(this.pageLimit));
        this.pageParam = (parseInt(this.selectedPage) * parseInt(this.pageLimit) - (parseInt(this.pageLimit) - 1)) + ' to ' + end;
    }

    /**
     * purpose of this method to fire the custom event to parent component
     */
    fireCustomEvent() {
        // console.log('event firing');
        const passEventr = new CustomEvent("paginationevent", {
            detail: {
                dataToDisplay: this.dataToDisplay,
                allProduct: this.allClients,
                allChecked: this.allChecked,
                isAsc: this.isAsc
            }
        });
        this.dispatchEvent(passEventr);
        //   console.log('event fired');
    }

    /**
    * purpose of this method to unsubscribe the event first
    * @returns
    */
    unsubscribeMC() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    disconnectedCallback() {
        releaseMessageContext(this.context);
    }
}