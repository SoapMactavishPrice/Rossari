import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';

import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import OBJECT_OrderItem from '@salesforce/schema/OrderItem';
import OBJECT_Order from '@salesforce/schema/Order';
import getSOData from '@salesforce/apex/Snop.getSOData';
import getSOLineItem from '@salesforce/apex/Snop.getSOLineItem';
import SBU__c from '@salesforce/schema/Order.SBU__c';
import FIELD_Status from '@salesforce/schema/Order.Status';
// // import getSchedulingLineItem from '@salesforce/apex/Snop.getSchedulingLineItem';
import saveline from '@salesforce/apex/Snop.saveline';
// import getPicklistFieldValues from '@salesforce/apex/NewEnquiryController.GetPicklistFieldValues';
// // import getPicklistFieldValuesByQuery from '@salesforce/apex/NewEnquiryController.GetPicklistFieldValuesByQuery';
// import getShipToAccount from "@salesforce/apex/NewEnquiryController.getShipToAccount";
import FORM_FACTOR from '@salesforce/client/formFactor';

import savePartialDisptach from '@salesforce/apex/Snop.savePartialDisptach';
import getScheduledOrder from '@salesforce/apex/Snop.getScheduledOrder';
import removeALlPartialData from '@salesforce/apex/Snop.removeALlPartialData';
import removeRowPartialData from '@salesforce/apex/Snop.removeRowPartialData';

import saveHeader from '@salesforce/apex/Snop.saveHeader';
import getOrderPicklistOptions from '@salesforce/apex/Snop.getOrderPicklistOptions';
import getFilteredOrders from '@salesforce/apex/Snop.getFilteredOrders';

export default class FullfillmentPlanningExport extends NavigationMixin(LightningElement) {

    processing = true;
    noData = false;

    @api rId;
    @api fromPage;
    @track recordList = null;
    @track isDialogVisible = false;
    @track txtBarcode = '';
    @track flag_no_of_pallete = false;
    @track hasRendered = true
    @track delayreasonOption = [];
    @track soStatus = [];
    @track toggleClick = 2;
    @track isSONumberSort=false;
    @track isSODateSort=false;
    @track isDivisionSort=false;
    @track sbuOptions=[];
    @track filterObject={};
    @track filterOption={};
    sortedDirection = 'asc';
    sortedColumn;

    sortSoNumber(event) {
        this.isSONumberSort = true;
        this.isSODateSort=false;
        this.isDivisionSort=false;
        this.sortData(event.currentTarget.dataset.id);
    }
    sortSoDate(event){
        this.isSONumberSort = false;
        this.isSODateSort=true;
        this.isDivisionSort=false;
        this.sortData(event.currentTarget.dataset.id);
    }
    sortDivision(event){
        this.isSONumberSort = false;
        this.isSODateSort=false;
        this.isDivisionSort=true;
        this.sortData(event.currentTarget.dataset.id);
    }
    sortData(sortColumnName) {
        // check previous column and direction
        if (this.sortedColumn === sortColumnName) {
            this.sortedDirection = this.sortedDirection === 'asc' ? 'desc' : 'asc';
        } 
        else {
            this.sortedDirection = 'asc';
        }

        // check arrow direction
        if (this.sortedDirection === 'asc') {
            this.isAsc = true;
            this.isDsc = false;
        } 
        else {
            this.isAsc = false;
            this.isDsc = true;
        }

        // check reverse direction
        let isReverse = this.sortedDirection === 'asc' ? 1 : -1;

        this.sortedColumn = sortColumnName;

        // sort the data
        this.recordList = JSON.parse(JSON.stringify(this.recordList)).sort((a, b) => {
            a = a[sortColumnName] ? a[sortColumnName].toLowerCase() : ''; // Handle null values
            b = b[sortColumnName] ? b[sortColumnName].toLowerCase() : '';

            return a > b ? 1 * isReverse : -1 * isReverse;
        });;
    }

    @wire(getObjectInfo, { objectApiName: OBJECT_Order })
    formObjectInfo;

    @wire(getPicklistValues, { recordTypeId: '$formObjectInfo.data.defaultRecordTypeId', fieldApiName: SBU__c })
    wiredSBU({ data, error }) {
        if (data) {
            this.sbuOptions = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));

        } else if (error) {
            //console.error('Error fetching picklist values', error);
        }
    }

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        /* this.currentPageReference = currentPageReference;
        if (this.currentPageReference) {
            this.rId = this.currentPageReference.state.c__rId;
            this.fromPage = this.currentPageReference.state.c__fromPage;
        } */
    }

    @wire(getObjectInfo, { objectApiName: OBJECT_OrderItem })
    obj_Orderitem;


    @wire(getObjectInfo, { objectApiName: OBJECT_Order })
    obj_Order;
    @wire(getPicklistValues, { recordTypeId: '$obj_Order.data.defaultRecordTypeId', fieldApiName: FIELD_Status })
    wiredData({ error, data }) {
        if (data) {
            this.soStatus = [{ label: 'None', value: '' }, ...data.values.map(objPL => {
                return {
                    label: `${objPL.label}`,
                    value: `${objPL.value}`
                };
            })];
            console.log('soStatus' + JSON.stringify(this.soStatus));
        } else if (error) {
            //console.error(JSON.stringify(error));
        }
    }

    get pageVisible1() {
        return true;
    }

    f_msg_error(p_tittle, p_msg) {
        //console.error('p_msg', p_msg);
        this.dispatchEvent(
            new ShowToastEvent({
                title: p_tittle,
                message: p_msg,
                variant: 'error'
            })
        );
    }
    f_msg_success(p_tittle, p_msg) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: p_tittle,
                message: p_msg,
                variant: 'success'
            })
        );
    }

    connectedCallback() {
        setTimeout(() => {
            console.log('connected callback rId -> ' + this.rId);
        }, 3000);

        this.f_getSOData();
        this.getFilterOptions();
        // this.fetchPicklistFields('Order', 'SBU1__c');
        // this.fetchPicklistFields('Order', 'Sales_District__c');
        // this.fetchPicklistFields('Order', 'BillingStateCode');
        // this.fetchPicklistFields('Product2', 'Material_Group_3__c');
        // this.fetchPicklistFieldsByQuery('Account', 'City__c');
        // this.getShipToAccount();
        this.formatDate();
        console.log('this.FORM_FACTOR', FORM_FACTOR);
        this.value='Credit Check passed';
        // this.mobileData();
    }

    getFilterOptions() {
        getOrderPicklistOptions({orderRecordType: 'Export'}).then((result)=>{
            console.log('getOrderPicklistOptions', result);
            this.filterOption = result;
        }).catch((error)=>{
            this.f_msg_error('Error', error.body.message);
        })
    }


    handleClick() {
        this.filterObject = {};
        this.totalLineItem = 0;
        const filterSection = this.template.querySelector('.filter-section');
        if (filterSection) {
            const inputFields = this.template.querySelectorAll('lightning-input-field');
            if (inputFields) {
                inputFields.forEach(element => {
                    if (filterSection.contains(element)) {
                        console.log('contains input-field');
                        element.reset();
                        element.value = '';
                    }
                })
            }

            const inputs = filterSection.querySelectorAll('lightning-input');
            if (inputs) {
                inputs.forEach(element => {
                    element.value = '';
                })
            }
            const combobox = filterSection.querySelectorAll('lightning-combobox');
            if (combobox) {
                combobox.forEach(element => {
                    element.value = '';
                })
            }

            const lookupComponents = filterSection.querySelectorAll('c-look-up-component');
            if (lookupComponents) {
                lookupComponents.forEach(element => {
                    element.reset();
                })
            }

            const searchableComboboxes = filterSection.querySelectorAll('c-searchable-combobox');
            if (searchableComboboxes) {
                searchableComboboxes.forEach(element => {
                    element.reset();
                })
            }
        }


        this.f_getSOData();
    }

    @track ShipToaccountOptions = ''
    getShipToAccount() {
        // this.showSpinner = true;

        // getShipToAccount({
        //     salesOrg: '',
        //     distribChannel: '',
        //     division: ''
        // }).then((data) => {
        //     this.ShipToaccountOptions = JSON.parse(data);
        //     this.showSpinner = false;
        // }).catch((error) => {
        //     console.log("Error 4");
        // })
    }



    @track SBUPicklistValues = '';
    @track REGPicklistValues = '';
    @track STATEPicklistValues = '';
    @track MaterialPicklistValues = '';
    @track CityPicklistValues = '';
    fetchPicklistFields(objectApiName, fieldApiName) {
        // getPicklistFieldValues({
        //     objectName: objectApiName,
        //     fieldName: fieldApiName,
        // })
        //     .then((result) => {
        //         // console.log('fetchPicklistFields', result);
        //         if (fieldApiName == 'SBU1__c') {
        //             this.SBUPicklistValues = [
        //                 {
        //                     "label": "--None--",
        //                     "value": ""
        //                 },
        //                 ...result
        //             ];
        //         }


        //         if (fieldApiName == 'Sales_District__c') {
        //             this.REGPicklistValues = [
        //                 {
        //                     "label": "--None--",
        //                     "value": ""
        //                 },
        //                 ...result
        //             ];
        //         }

        //         if (fieldApiName == 'BillingStateCode') {
        //             this.STATEPicklistValues = [
        //                 {
        //                     "label": "--None--",
        //                     "value": ""
        //                 },
        //                 ...result
        //             ];
        //         }

        //         if (fieldApiName == 'Material_Group_3__c') {
        //             this.MaterialPicklistValues = [
        //                 {
        //                     "label": "--None--",
        //                     "value": ""
        //                 },
        //                 ...result
        //             ];
        //         }
        //         if (fieldApiName == 'City__c') {
        //             this.CityPicklistValues = [
        //                 {
        //                     "label": "--None--",
        //                     "value": ""
        //                 },
        //                 ...result
        //             ];
        //         }
        //     })
        //     .catch((error) => {
        //         //console.error(error);
        //     });
    }
    // fetchPicklistFieldsByQuery(objectApiName, fieldApiName) {
    //     getPicklistFieldValuesByQuery({
    //         objectName: objectApiName,
    //         fieldName: fieldApiName,
    //     })
    //         .then((result) => {
    //             // console.log('fetchPicklistFields', result);




    //             if (fieldApiName == 'City__c') {
    //                 this.CityPicklistValues = [
    //                     {
    //                         "label": "--None--",
    //                         "value": ""
    //                     },
    //                     ...result
    //                 ];
    //             }
    //         })
    //         .catch((error) => {
    //             //console.error(error);
    //         });
    // }

    handleFilterChanges(event) {
        let field = event.target.dataset.id;
        let value = event.target.value;
        
        this.filterObject[field] = value;

        console.log(JSON.parse(JSON.stringify(this.filterObject)));
    }

    @track headerObjects = [];

    handleHeaderChange(event) {
        let recordId = event.target.dataset.id;
        let fieldName = event.target.dataset.fieldname;
        let value = event.target.value;

        // find if record already exists in headerObjects
        let existingIndex = this.headerObjects.findIndex(obj => obj.Id === recordId);

        if (existingIndex !== -1) {
            // record exists → update the field
            this.headerObjects[existingIndex][fieldName] = value;
        } else {
            // record does not exist → create new object and add
            let newObj = { Id: recordId };
            newObj[fieldName] = value;
            this.headerObjects = [...this.headerObjects, newObj];
        }

        console.log('headerObjects ==> ', JSON.parse(JSON.stringify(this.headerObjects)));
    }


    handleEvent(messageFromEvt) {
        // window.console.log('event handled ',messageFromEvt);
        console.log(' messageFromEvt.rId', messageFromEvt.rId);
        this.rId = messageFromEvt.rId;
        this.f_getWOid();
    }


    openStockInventoryPage() {
        const vfPageUrl = '/apex/StockInventoryB2B';
        window.location.href = vfPageUrl;
    }
    // 24-05-2024 making function date formated
    formatDate(dateString) {
        const date = new Date(dateString);
        const monthNames = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];
        const day = date.getDate();
        const monthIndex = date.getMonth();
        const year = date.getFullYear();
        const monthName = monthNames[monthIndex];
        return `${day}-${monthName}-${year}`;
    }



    f_getSOData() {
        console.log('f_getData -> ' + this.rId);
        this.noData = false;
        this.processing = true;

        getSOData({ orderRecordType: 'Export' })
            .then((result) => {

                //this.setDelay();

                console.log('woid-->> ', JSON.parse(JSON.stringify(result)));
                if (result.length>0) {
                    this.recordList = JSON.parse(JSON.stringify(result));
                    console.log('length', this.recordList.length);
                    this.recordList.forEach((element) => {
                        element['edit_record'] = false;
                        element['dupeId'] = element['Id'] + 'second';
                        if (element.Order_Header_Text__r != null) {
                            element['internal_remark'] = element.Order_Header_Text__r[0].Text_Description__c;
                        } else {
                            element['internal_remark'] = '';
                        }

                         // 24-05-2024 date format changes rohit
                         const EffectiveDate = this.formatDate(element.EffectiveDate);
                         element.EffectiveDate = EffectiveDate;
                         if (element.Order_Clearance_Date__c) {
                             const OrderClearanceDate = this.formatDate(element.Order_Clearance_Date__c);
                             element.Order_Clearance_Date__c = OrderClearanceDate;
                         }
                         
                        if (element.Status == 'Sale Order Created') {
                            element.statusCheck = 'status_created'
                            element.isCreated = true;
                        } else if (element.Status == 'Draft') {
                            element.statusCheck = 'status_draft';
                            element.isDraft = true;
                        } else if (element.status == 'Credit Check passed') {
                            element.statusCheck = 'status_credit_check';
                            element.isCreditCheck = true;
                        } else {
                            element.isother = true;
                        }

                    });

                    /* let recs = [];
                    for (let i = 0; i < result.length; i++) {
                        let opp = {};
                        opp = Object.assign(opp, result[i]);
                        opp.Pick_Loose_Quantity__c = '';
                        opp.Loose_Gross_Weight__c = '';
                        opp.Loose_Net_Weight__c = '';
                        recs.push(opp);
                        console.log('recs ', recs);
                    }
                    this.recordList = recs; */
                    if (this.recordList.length > 0) {
                        // this.searchButton();
                        this.f_getSOLineItem();
                        // this.getSchLineItem();


                        /* if (this.recordList[0].Work_Order_Line_Item__r.hasOwnProperty('Stock_Transfer_Line_Items__c') 
                            &&  this.recordList[0].Work_Order_Line_Item__r.Stock_Transfer_Line_Items__c != null) {
                            this.flag_no_of_pallete = true;
                        } */
                    }
                    // console.log("recordList--->", JSON.stringify(this.recordList));
                    // console.log("recordList-->", JSON.stringify(this.recordList.length));
                } else {
                    new ShowToastEvent({ title: 'No Records', message: 'No Records', variant: 'info' });
                    this.processing=false;
                }
            })
            .catch(error => {
                this.setDelay();
                //console.error('error', error);
                this.f_msg_error('Error', error);
            });

    }
    getSearchSODataJS(filterValue) {
        this.processing = true;
        var ids = this.allClients.map(item => item.Id);
        getSearchSOData({
            pData: ids,
            filters: JSON.stringify(filterValue)
        })
            .then((result) => {
                //this.setDelay();
                if (result.length == 0) {
                    this.totalRecords = 0;
                }
                this.todayItem = 0;
                this.pendingItem = 0;
                this.moreplanningItem = 0;
                this.lessplanningItem = 0;
                this.blankdispatchdate = 0;
                this.filldispatchdate = 0;
                console.log('qwertyuio', result, result.length);
                console.log('woid :  ', JSON.stringify(result));
                if (result) {
                    this.recordList = JSON.parse(JSON.stringify(result));
                    this.recordList.forEach((element) => {
                        element['edit_record'] = false;
                        if (element.Order_Header_Text__r != null) {
                            element['internal_remark'] = element.Order_Header_Text__r[0].Text_Description__c;
                        } else {
                            element['internal_remark'] = '';
                        }
                        // 24-05-2024 date format changes rohit
                        const EffectiveDate = this.formatDate(element.EffectiveDate);
                        element.EffectiveDate = EffectiveDate;
                        console.log('element.EffectiveDate ',element.EffectiveDate);
                        if (element.Order_Clearance_Date__c) {
                            const OrderClearanceDate = this.formatDate(element.Order_Clearance_Date__c);
                            element.Order_Clearance_Date__c = OrderClearanceDate;
                        }
                        if (element.Status == 'Sale Order Created') {
                            element.statusCheck = 'status_created';
                            element.isCreated = true;
                        } else if (element.Status == 'Draft') {
                            element.statusCheck = 'status_draft';
                            element.isDraft = true;
                        } else if (element.status == 'Credit Check passed') {
                            element.statusCheck = 'status_credit_check';
                            element.isCreditCheck = true;
                        } else {
                            element.isother = true;
                        }
                    });

                    if (this.recordList.length > 0) {
                        this.f_getSOLineItem();
                    }
                    else {
                        this.processing = false;
                        this.noData = true;




                    }
                    // console.log("recordList->", JSON.stringify(this.recordList));
                    // console.log("recordList-->", JSON.stringify(this.recordList.length));
                } else {
                    new ShowToastEvent({ title: 'No Records', message: 'No Records', variant: 'info' });

                }

            })
            .catch(error => {
                this.setDelay();
                //console.error('error', error);
                this.f_msg_error('Error', error);
            });
    }
    @track todayCount = [];
    @track pendingCount = [];
    @track moreCount = [];
    @track lessCount = [];
    @track blankPlanningReady = [];
    @track planningready = [];
    @track todayItem=0;
    @track pendingItem=0;
    @track moreplanningItem=0;
    @track lessplanningItem=0;
    @track blankdispatchdate=0;
    @track filldispatchdate=0;

    @track todayDispatch=0;
    @track NextDayDispatch=0;
    @track DayAfterTommorrowDisptach=0;
    @track OtherDisptach=0;
    @track dueforTodayCount=0;
    @track scheduleMissed=0;

    f_getSOLineItem() {
        this.processing = true;
        var ids = this.recordList.map(item => item.Id);
        getSOLineItem({ pdata:ids }).then(data => {
            this.setDelay();
            console.log("f_getSOLineItem data-->", JSON.stringify(data));
            if (data) {
                let v_linelist = JSON.parse(JSON.stringify(data));
                getDisptachList({lineItem:JSON.stringify(data)})
                .then((result)=>{
                    let currentDate = new Date().toJSON().slice(0, 10);
                   

                    console.log('getDisptachList ',JSON.stringify(result));
                    

                    v_linelist.forEach(element => {
                        let filteredArray = result.filter(function (item) {
                            return item.Order_Product__c == element.Id;
                        });
                        // console.log('filteredArray ',JSON.stringify(filteredArray));
                        filteredArray.forEach(element => {
                            if (element.Planning_Ready_by_Date__c) {
                                this.filldispatchdate=this.filldispatchdate+1;
                            }
                        });
                       
                        if(filteredArray.length>0){
                            element.background_icon='status_today_icon';
                       }
                        if(element.First_Date__c == this.formatDate(currentDate) && filteredArray.length ==0){
                            element.background_icon='status_less_icon';
                            this.dueforTodayCount=this.dueforTodayCount+1;
                        }

                        let disptachPlan=result.filter(function (item) {
                            return item.Planning_Ready_by_Date__c < currentDate && item.Order_Product__c == element.Id;
                        });
                        console.log('disptachPlan.length ',disptachPlan.length);
                        if(disptachPlan.length>0){
                            console.log('inside aaya ');
                            element.background_icon='status_pending_icon';
                            this.scheduleMissed=this.scheduleMissed+1
                        }

                        if(element.background_icon =='status_today_icon' || element.background_icon =='status_pending_icon'){
                            element.isplannedStaus='is-planned';
                        }else{
                            element.isplannedStaus='is-not-planned';
                        }
                    });
                    // console.log('==> ',JSON.stringify(v_linelist));
                    this.blankdispatchdate=this.totalLineItem-this.filldispatchdate;
                    this.todayDispatch=0;
                    this.NextDayDispatch=0;
                    this.DayAfterTommorrowDisptach=0;
                    this.OtherDisptach=0;

                    result.forEach(element => {
                        if (element.Planning_Ready_by_Date__c == currentDate) {
                            this.todayDispatch=this.todayDispatch+1;
                        }
                         else if (element.Planning_Ready_by_Date__c == this.tommorrow()) {
                            this.NextDayDispatch=this.NextDayDispatch+1;
                        }

                        else if (element.Planning_Ready_by_Date__c == this.DAT()) {
                            this.DayAfterTommorrowDisptach=this.DayAfterTommorrowDisptach+1;
                        }else if(element.Planning_Ready_by_Date__c > currentDate && element.Planning_Ready_by_Date__c > this.tommorrow()&& element.Planning_Ready_by_Date__c> this.DAT()){
                            this.OtherDisptach=this.OtherDisptach+1;
                        }

                    });
                })
                v_linelist.forEach((ele, i) => {
                    ele['Name'] = ele.Product2.Name + ' (' + ele.Product2.ProductCode + ')';
                    // if (!ele.Planning_Ready_by_Date__c) {
                    //     ele['isPlanYourDisptachAvailable'] = false;
                    // }
                    // if (ele.Planning_Ready_by_Date__c) {
                    //     ele['isPlanYourDisptachAvailable'] = true;
                    // }
                });
               
                this.recordList.forEach((ele, i) => {
                    let filteredArray = v_linelist.filter(function (item) {
                        return item.OrderId == ele.Id;
                    });
                    // console.log('filteredArray', filteredArray);
                    // console.log('filteredArray', filteredArray.length);
                    // 23-05-2024
                    let currentDate = new Date().toJSON().slice(0, 10);
                    // console.log(currentDate);
                    filteredArray.forEach(element => {
                        let currentDate = new Date().toJSON().slice(0, 10);

                        if (element.Planning_Ready_by_Date__c == '' || element.Planning_Ready_by_Date__c == undefined) {
                            element.background_icon = 'background-icon';
                        }

                        if (element.First_Date__c) {
                            const FirstDate = this.formatDate(element.First_Date__c);
                            element.First_Date__c = FirstDate;
                        }
                        if (element.Cust_ETA__c) {
                            const Cust_ETA = this.formatDate(element.Cust_ETA__c);
                            element.Cust_ETA__c = Cust_ETA;
                        }
                    });
                    // 

                    ele.item_list = filteredArray;
                    this.getSOlineItemLength(ele.item_list);
                
                    ele.styleHistory = "display:none";
                    // ele.styleHistory = "";
                    if (ele.item_list.length == 0) {
                        ele.flagHistory = false;
                    } else {
                        ele.flagHistory = true;
                    }
                    if (ele.First_Date__c) {
                        const FirstDate2 = this.formatDate(ele.First_Date__c);
                        filteredArray.First_Date__c = FirstDate2;
                        console.log('filteredArray4', ele.First_Date__c);
                    }

                    if (ele.Cust_ETA__c) {
                        const Cust_ETA = this.formatDate(ele.Cust_ETA__c);
                        filteredArray.Cust_ETA__c = Cust_ETA;
                        // console.log('filteredArray4', ele.Cust_ETA__c);
                    }
                });
                this.totalRecords = this.recordList.length;
                if (this.recordList.length) {
                    this.noData = false;
                }
                if (this.totalRecords == 0 || '') {
                    this.totalRecords = 0;
                    console.log('length2', this.totalRecords);
                }
                console.log('length2', this.totalRecords);
                this.allClients = this.recordList;
                this.allFilteredClients = this.recordList;
                setTimeout(() => {
                    this.template.querySelector('c-common-pagination').handlePagination(this.allFilteredClients);
                    this.template.querySelector('c-common-pagination').validatePagination();
                }, 1000);
                // console.log("recordList data-->", JSON.stringify(this.recordList));
                this.processing = false;
            }
        })
            .catch(error => {
                this.setDelay();
                //console.error('error', error);
                this.f_msg_error('Error', error);
            });
    }
    tommorrow(){
        // Creating the date instance 
        let d = new Date(); 
      
        // Adding one date to the present date 
        d.setDate(d.getDate() + 1); 
      
        let year = d.getFullYear() 
        let month = String(d.getMonth() + 1) 
        let day = String(d.getDate()) 
      
        // Adding leading 0 if the day or month 
        // is one digit value 
        month = month.length == 1 ?  
            month.padStart('2', '0') : month; 
      
        day = day.length == 1 ?  
            day.padStart('2', '0') : day; 
      
        // Printing the present date 
        console.log(`${year}-${month}-${day}`); 
        return `${year}-${month}-${day}`;
    } 

    DAT(){
        // Creating the date instance 
        let d = new Date(); 
      
        // Adding one date to the present date 
        d.setDate(d.getDate() + 2); 
      
        let year = d.getFullYear() 
        let month = String(d.getMonth() + 1) 
        let day = String(d.getDate()) 
      
        // Adding leading 0 if the day or month 
        // is one digit value 
        month = month.length == 1 ?  
            month.padStart('2', '0') : month; 
      
        day = day.length == 1 ?  
            day.padStart('2', '0') : day; 
      
        // Printing the present date 
        console.log(`${year}-${month}-${day}`); 
        return `${year}-${month}-${day}`;
    } 
    handlecheckbox(event) {
        const { value, checked } = event.target;
        const { index } = event.currentTarget.dataset;
        // console.log(event.currentTarget.dataset.index);
        this.recordList[index].ischecked = checked;
        console.log('ischecked', this.recordList[index].ischecked);
        // console.log('index', event.currentTarget.dataset);
        // console.log('checked', event.target.checked);
    }

    saveline(event) {
        // console.log('get json---', JSON.stringify(this.recordList));
        let v_data = [];
        let currentDate = new Date().toJSON().slice(0, 10);

        v_data = this.recordList.filter(function (element) {
            // return element.edit_record == true && ischecked == checked;
            return element.edit_record == true;
        })
        console.log('v_data', JSON.stringify(v_data));
         var isBackDatedDisptachPlanDate=false;

        this.recordList.forEach(e => {
            // // v_data.forEach(e => {
            // if (e.ischecked == true) {
            isBackDatedDisptachPlanDate = e.item_list.filter(function (ele) {
                return ele.Planning_Ready_by_Date__c < currentDate && ele.edit_record == true;
            });
                console.log('ischeck1', e.ischecked);
                let t_data = e.item_list.filter(function (ele) {
                    return ele.edit_record == true
                });
                console.log('ischeck2', e.ischecked);
                if (t_data.length > 0) {
                    v_data = v_data.concat(t_data);
                }
            // }
        });
        console.log('v_data2', v_data);
        // 
        // this.recordList.forEach(element => {
        //     if (element.edit_record && element.ischeck) {
        //         v_data.push(element);
        //     }

        //     element.item_list.forEach(ele => {
        //         if (ele.edit_record && ele.ischeck) {
        //             v_data.push(ele);
        //         }
        //     });
        // });

        // 
        console.log('length', v_data.length);
        if (v_data.length == 0 && this.headerObjects.length == 0) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error Updating record',
                    message: 'No Record have updated',
                    variant: 'error'
                })
            );
            return false;
        }

        console.log('OUTPUT : ',isBackDatedDisptachPlanDate.length);
        if(isBackDatedDisptachPlanDate.length >0){
            console.log('OUTPUT : isBackDatedDisptachPlanDate ',isBackDatedDisptachPlanDate);
           this.f_msg_error('Error', 'Back dated dispatch plan date is not allowed');
           return false;
       }

        this.processing = true;

        if (this.headerObjects.length > 0) {
            saveHeader({headerStringObj: JSON.stringify(this.headerObjects)}).then((result)=>{
                if (result == 'Success') {
                    this.f_msg_success('Success', 'Header saved successfully');
                    this.processing = false;
                } else {
                    this.f_msg_error('Error', result);
                    this.processing = false;
                }
            }).catch((error)=>{
                this.processing = false;
                this.f_msg_error('Error', error.body.message);
            })
        }

        if (v_data.length > 0) {
            saveline({ lineItem: JSON.stringify(v_data) })
                .then((result) => {
                    console.log('result : ', JSON.stringify(result));
                    this.setDelay();
    
                    let vData = JSON.parse(result);
                    console.log('vData', JSON.parse(JSON.stringify(result)));
                    // v_data.forEach((ele, i) => {
                    //     console.log('ele');
                    //     v_data[i].ischecked = false;
                    //     console.log('ischecked', v_data[i].ischecked);
                    // });
                    // 
                    if (!vData.status) {
                        this.f_msg_error('Error', vData.msg);
                    }
                    else {
                        this.recordList.forEach(record => {
                            record.ischecked = false;
                            record.item_list.forEach(item => {
                                item.ischecked = false;
                            });
                        });
                        this.f_msg_success('Success', vData.msg);
                        this.f_getSOLineItem();
                    }
                    // 
    
                    // if (!vData.status) {
                    //     this.f_msg_error('Error', vData.msg);
                    // }
                    // else {
                    //     this.f_msg_success('Success', vData.msg);
                    //     //this.isDialogVisible=true;
                    // }
                    this.processing = false;
                })
                .catch(error => {
                    this.processing = false;
                    this.setDelay();
                    //console.error('error', error);
                    this.f_msg_error('Error', error);
                });
        }
    }




    f_getWOid() {
        console.log('f_getWOid -> ' + this.rId);
        this.processing = true;

        getWOid({ woid: this.rId })
            .then((result) => {

                this.setDelay();

                console.log('woid :  ', JSON.stringify(result));
                if (result) {
                    this.recordList = JSON.parse(JSON.stringify(result));
                    this.recordList.forEach((element) => {
                        element['customQuantity'] = null;
                        element['No_of_Pallete'] = null;
                    });

                    /* let recs = [];
                    for (let i = 0; i < result.length; i++) {
                        let opp = {};
                        opp = Object.assign(opp, result[i]);
                        opp.Pick_Loose_Quantity__c = '';
                        opp.Loose_Gross_Weight__c = '';
                        opp.Loose_Net_Weight__c = '';
                        recs.push(opp);
                        console.log('recs ', recs);
                    }
                    this.recordList = recs; */
                    if (this.recordList.length > 0) {
                        this.f_get_Pick_Line_Item();

                        if (this.recordList[0].Work_Order_Line_Item__r.hasOwnProperty('Stock_Transfer_Line_Items__c')
                            && this.recordList[0].Work_Order_Line_Item__r.Stock_Transfer_Line_Items__c != null) {
                            this.flag_no_of_pallete = true;
                        }
                    }
                    // console.log("recordList---->", JSON.stringify(this.recordList));
                } else {
                    new ShowToastEvent({ title: 'No Records', message: 'No Records', variant: 'info' });
                }
            })
            .catch(error => {
                this.setDelay();
                //console.error('error', error);
                this.f_msg_error('Error', error);
            });

    }

    f_dok_save(event) {
        if (event.detail !== 1) {
            if (event.detail.status === 'confirm') {
                this.f_getWOid();
            }
            else if (event.detail.status === 'cancel') {
            }
        }
        console.log('f_dok_save');
        console.log('Event firing');

        let message = {
            "rId": this.rId
        }
        console.log('Event Fired ');

        this.isDialogVisible = false;
    }

    handleQtyChange(event) {
        this.recordList[event.target.dataset.index].customQuantity = event.currentTarget.value;
    }

    handle_No_of_Pallete(event) {
        this.recordList[event.target.dataset.index].No_of_Pallete = event.currentTarget.value;
    }

    handleCustomControlChange(event) {
        var inputFieldValue = event.detail.value;
        var inputFieldName = event.target.name;
        var inputFieldNameRecordEdit = event.currentTarget.dataset.fieldname;
        let currentDate = new Date().toJSON().slice(0, 10);

        console.log('inputFieldValue', inputFieldValue);
        console.log('inputFieldName', inputFieldName);
        

        if (inputFieldName == 'Planning_Ready_by_Date__c') {
            this.recordList[event.target.dataset.index].item_list[event.target.dataset.yindex].Planning_Ready_by_Date__c = inputFieldValue;
             if(inputFieldValue!='' && inputFieldValue < currentDate){
                this.f_msg_error('Error', 'Back dated dispatch plan date is not allowed');
            }else{
                if(inputFieldValue!=''){
                    this.recordList[event.target.dataset.index].item_list[event.target.dataset.yindex].isPlanYourDisptachAvailable =true;
                }else{
                    this.recordList[event.target.dataset.index].item_list[event.target.dataset.yindex].isPlanYourDisptachAvailable =false;
                }
            }
        }
        /* if (inputFieldName == 'Planning_Delay_Reason__c') {
            // this.recordList[this.getIndex(event.currentTarget.dataset.id)].Planning_Delay_Reason__c = inputFieldValue;
            this.recordList[event.target.dataset.index].item_list[event.target.dataset.yindex].Planning_Delay_Reason__c = inputFieldValue;
        } */
        if (inputFieldName == 'Planning_Dispatch_Remark__c') {
            // this.recordList[this.getIndex(event.currentTarget.dataset.id)].Planning_Dispatch_Remark__c = inputFieldValue;
            this.recordList[event.target.dataset.index].item_list[event.target.dataset.yindex].Planning_Dispatch_Remark__c = inputFieldValue;
        }
        if (inputFieldName == 'Planning_Remark__c') {
            // this.recordList[this.getIndex(event.currentTarget.dataset.id)].Planning_Remark__c = inputFieldValue;
            this.recordList[event.target.dataset.index].item_list[event.target.dataset.yindex].Planning_Remark__c = inputFieldValue;
        }
        if (inputFieldName == 'Logistics_Vehicle_Placement_Date__c') {
            // this.recordList[this.getIndex(event.currentTarget.dataset.id)].Logistics_Vehicle_Placement_Date__c = inputFieldValue;
            this.recordList[event.target.dataset.index].item_list[event.target.dataset.yindex].Logistics_Vehicle_Placement_Date__c = inputFieldValue;
        }
        if (inputFieldName == 'Logistics_Vehicle_Delay_Reason__c') {
            // this.recordList[this.getIndex(event.currentTarget.dataset.id)].Logistics_Vehicle_Delay_Reason__c = inputFieldValue;
            this.recordList[event.target.dataset.index].item_list[event.target.dataset.yindex].Logistics_Vehicle_Delay_Reason__c = inputFieldValue;
        }
        if (inputFieldName == 'Logistics_Remark__c') {
            // this.recordList[this.getIndex(event.currentTarget.dataset.id)].Logistics_Remark__c = inputFieldValue;
            this.recordList[event.target.dataset.index].item_list[event.target.dataset.yindex].Logistics_Remark__c = inputFieldValue;
        }
        if (inputFieldNameRecordEdit == 'Planning_RM_Confirmation__c') {
            // this.recordList[this.getIndex(event.currentTarget.dataset.id)].Logistics_Remark__c = inputFieldValue;
            this.recordList[event.target.dataset.index].item_list[event.target.dataset.yindex].Planning_RM_Confirmation__c = inputFieldValue;
            console.log('recordList', this.recordList);
        }
         if (inputFieldName == 'Deviation_Reason__c') {
            this.recordList[event.target.dataset.index].item_list[event.target.dataset.yindex].Deviation_Reason__c = inputFieldValue;
        }

        if (inputFieldName == 'Lead_time__c') {
            this.recordList[event.target.dataset.index].item_list[event.target.dataset.yindex].Lead_time__c = inputFieldValue;
        }
        // this.recordList[this.getIndex(event.currentTarget.dataset.id)].edit_record = true;
        this.recordList[event.target.dataset.index].item_list[event.target.dataset.yindex].edit_record = true;
    }

    handleChange(event) {
        // this.recordList[event.target.dataset.index].Planning_Delay_Reason__c =  event.currentTarget.value;
        // this.recordList[event.target.dataset.index].edit_record =  true;

      //  this.recordList[event.target.dataset.index].item_list[event.target.dataset.yindex].Planning_Delay_Reason__c = inputFieldValue;
        this.recordList[event.target.dataset.index].item_list[event.target.dataset.yindex].edit_record = true;
    }

    /**
     * get position of matched record
     */
    getIndex(param) {
        const filterIndex = this.recordList.findIndex((element, index) => {
            if (element.Id === param) {
                return true;
            }
        })
        return filterIndex;
    }

    saveline1(event) {
        console.log('get json---', JSON.stringify(this.recordList));
        let v_data = [];

        v_data = this.recordList.filter(function (element) {
            return parseInt(element.customQuantity) > 0;
        });

        if (v_data.length == 0) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error Updating record',
                    message: 'Enter Pick Quantity',
                    variant: 'error'
                })
            );
            return false;
        }

        let v_flag = true;
        v_data.forEach((e, i) => {
            if (e.Pending_Pick_Quantity__c < e.customQuantity) {
                v_flag = false;
            }
        });

        if (!v_flag) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error Updating record',
                    message: 'Cannot enter more than Pending Quantity',
                    variant: 'error'
                })
            );
            return false;
        }

        this.processing = true;

        savePickLineDetails({ wolineItem: JSON.stringify(v_data) })
            .then((result) => {
                console.log('result : ', JSON.stringify(result));
                this.setDelay();

                let vData = JSON.parse(result);

                if (!vData.status) {
                    this.f_msg_error('Error', vData.msg);
                }
                else {
                    this.f_msg_success('Success', vData.msg);
                    this.isDialogVisible = true;
                }
            })
            .catch(error => {
                this.setDelay();
                //console.error('error', error);
                this.f_msg_error('Error', error);
            });
    }

    f_get_Pick_Line_Item() {
        getPickLineItem({ pdata: JSON.stringify(this.recordList) }).then(data => {
            console.log("f_get_Pick_Line_Item data-->", JSON.stringify(data));
            if (data) {
                let v_linelist = JSON.parse(JSON.stringify(data));
                v_linelist.forEach((ele, i) => {
                    ele['CreatedDate'] = ele.CreatedDate.substr(0, 10).split("-").reverse().join("-");
                    /*  if (!ele.hasOwnProperty('Aisle__r')) {
                         ele.Aisle__r = {"Name":"","Id":""};
                     }
                     if (!ele.hasOwnProperty('Rack__r')) {
                         ele.Rack__r = {"Name":"","Id":""};
                     }
                     if (!ele.hasOwnProperty('Pallete__r')) {
                         ele.Pallete__r = {"Name":"","Id":""};
                     } */
                });

                this.recordList.forEach((ele, i) => {
                    let filteredArray = v_linelist.filter(function (item) {
                        item['stylePickDelete'] = true;
                        if (item.Quantity__c > 0) {
                            item['stylePickDelete'] = false;
                        }
                        return item.Work_Order_Pick_Line_Item__c == ele.Id;
                    });
                    ele.item_list = filteredArray;
                    this.getSOlineItemLength(ele.item_list);

                    ele.styleHistory = "display:none";
                    if (ele.item_list.length == 0) {
                        ele.flagHistory = false;
                    } else {
                        ele.flagHistory = true;
                    }

                    console.log("ele.item_list-->", JSON.stringify(ele.item_list));
                });
                console.log("recordList data-->", JSON.stringify(this.recordList));

                //resolve();
            }
        })
            .catch(error => {
                this.setDelay();
                //console.error('error', error);
                this.f_msg_error('Error', error);
            });
    }

    f_delete_Work_Order_Pick_Item(event) {

        this.processing = true;

        let v_id = event.target.dataset.id;
        deleteWorkOrderPickItem({ pid: v_id })
            .then((result) => {

                this.setDelay();

                console.log('result---', result);

                this.isDialogVisible = true;
            })
    }

    f_flag_showhide(event) {
        console.log('Input index->', event.target.dataset.index);
        console.log("recordList>", JSON.parse(JSON.stringify(this.recordList)));

        if (this.recordList[event.target.dataset.index].styleHistory == "display:none") {
            this.recordList[event.target.dataset.index].styleHistory = "";
        }
        else {
            this.recordList[event.target.dataset.index].styleHistory = "display:none";
        }
    }
    f_flag_styleShowHide(event) {
        console.log('Input index->', event.target.dataset.index);
        console.log("recordList-->", JSON.parse(JSON.stringify(this.recordList)));
        console.log('log--->', this.recordList[event.target.dataset.index].styleShowHide);

        if (this.recordList[event.target.dataset.index].styleShowHide == "display:none") {
            console.log('log2--->', this.recordList[event.target.dataset.index].styleShowHide);
            this.recordList[event.target.dataset.index].styleShowHide = "";
        }
        else {
            this.recordList[event.target.dataset.index].styleShowHide = "display:none";
            console.log('log3--->', this.recordList[event.target.dataset.index].styleShowHide);

        }
    }


    handleCancel(event) {
        /* this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.rId,
                // objectApiName: 'Warehouse__c',
                actionName: 'view'
            },
        }); */

        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: this.fromPage
            },
            state: {
                c__rId: event.currentTarget.dataset.clid,
                // c__refsObjectName: '',
            }
        });
    }

    handleScanBarcode(event) {
        this.txtBarcode = event.currentTarget.value;
    }

    handleKeypressBarcode(component, event, helper) {
        let vFlag = false;
        let vFlag1 = false;
        let vFlag2 = false;

        if (component.which == 13) {
            this.recordList.forEach((e, i) => {
                e.styleItem = "";

                /* if(e.Work_Order_Line_Item__r.GRN_Line_Item__c.toUpperCase() == this.txtBarcode.toUpperCase() && !vFlag) { */
                if ((e.SKU_Code__c.toUpperCase() == this.txtBarcode.toUpperCase()
                    || e.SKU_Code__r.Name.toUpperCase() == this.txtBarcode.toUpperCase()) && !vFlag) {
                    vFlag1 = true;
                    e.styleItem = "background-color: #f4a1a1;";

                    if (e.Pending_Pick_Quantity__c > 0 && e.Pending_Pick_Quantity__c > e.customQuantity) {
                        //e.customQuantity = (e.customQuantity * 1) + 1;
                        e.customQuantity = (e.Pending_Pick_Quantity__c * 1);
                        vFlag2 = true;
                        vFlag = true;
                        e.styleItem = "background-color: lightgreen;";
                    }
                }
            })
            this.txtBarcode = "";

            if (!vFlag1) {
                this.f_msg_error('Error', 'Item Not Found');
                return false;
            }

            if (!vFlag2) {
                this.f_msg_error('Error', 'Item Found But Quantity are Over Flow');
                return false;
            }
        }
    }

    setDelay() {
        let timer = window.setTimeout(() => {
            this.processing = false;
            window.clearTimeout(timer);
        }, 300);
    }
    /*----------------------------------------For Paginaction------------------------------*/

    /**
     * description this event is calling from pagniation component 
     * @param {*} event 
     */
    handlePaginationEvent(event) {
        // console.log('handlePaginationEvent ', JSON.stringify(event.detail));
        this.recordList = event.detail.dataToDisplay;
        // console.log('handlePaginationEvent ', JSON.stringify(this.recordList.length));
    }


    /**
     * Purpose of this method is to show asending & descending ASN list 
     */
    handleSort() {
        this.template.querySelector('c-common-pagination').handleSort(this.recordList);
    }

    /**
     * Purpose of this method is to filter records base on user input in search box.
     * @param {*} event 
     */
    handleFilter(event) {
        this.allFilteredClients = event.detail.allFilteredClients;
    }


    // 
    onHandleFilterChange(event) {
        let fieldValue = event.target.value;
        let fieldName = event.currentTarget.dataset.fieldname;

        console.log('fieldValue-->', fieldValue);
        console.log('fieldName-->', fieldName);

    }
    searchButton() {
        this.totalLineItem = 0;
        getFilteredOrders({filterStringObj: JSON.stringify(this.filterObject), orderType: 'Export'}).then((result)=>{
            console.log('getFilteredOrders', result);
            this.recordList = result;

            this.f_getSOLineItem()
        }).catch((error)=>{
            this.f_msg_error('Error', error.body.message);
        })
    }

    filterValues(v_linelist) {
        // console.log('v_linelist ',v_linelist.length);
        // console.log('v_linelist ',JSON.stringify(v_linelist));
        var filterCount = 0;
        v_linelist.forEach((ele, i) => {
            ele['Name'] = ele.Product2.Name + ' (' + ele.Product2.ProductCode + ')';
        });

        this.allClients.forEach((ele, i) => {
            // console.log('ele Id ',ele.Id);
            let filteredArray = v_linelist.filter(function (item) {
                return item.OrderId == ele.Id;
            });
            // console.log('filteredArray ',JSON.stringify(filteredArray));
            ele.item_list = filteredArray;
            this.getSOlineItemLength(ele.item_list);
            ele.styleHistory = "display:none";
            // ele.styleHistory = "";
            if (ele.item_list.length == 0) {
                ele.flagHistory = false;
            } else {
                ele.flagHistory = true;
                filterCount = filterCount + 1;
            }
            //console.log("ele.item_list-->", JSON.stringify(ele.item_list));
        });
        // console.log('filterCount ', this.allClients.length);
        this.totalRecords = this.allClients.length;
        this.allClients = this.allClients;
        this.allFilteredClients = this.allClients;
        setTimeout(() => {
            this.template.querySelector('c-common-pagination').handlePagination(this.allFilteredClients);
            this.template.querySelector('c-common-pagination').validatePagination();
        }, 1000);
        // console.log("recordList data-->", JSON.stringify(this.recordList));
        // console.log("recordList data-->", JSON.stringify(this.recordList));
    }
    collapse() {
        // console.log('click collapse');
        if (this.toggleClick == 1) {


            if (FORM_FACTOR == 'Small') {
                this.template.querySelector('.custom-left-side-section').classList.remove('mobileview');
            } else {
                this.template.querySelector('.stage-left').classList.remove('open');
                this.template.querySelector('.stage-left').classList.add('close');
            }
            this.template.querySelector('.custom-lightning-accordion').classList.add('lightning-accordion-hide');
            this.template.querySelector('.custom-lightning-accordion').classList.remove('lightning-accordion-show');
            // window.clearTimeout(timer);

            // let timer = window.setTimeout(() => {

            //     console.log('timeout');
            // }, 500);

            this.toggleClick = 2;
        } else if (this.toggleClick == 2) {


            if (FORM_FACTOR == 'Small') {
                this.template.querySelector('.custom-left-side-section').classList.add('mobileview');
                const scrollOptions = {
                    left: 0,
                    top: 0,
                    behavior: 'smooth'
                }
                window.scrollTo(scrollOptions);
            } else {
                this.template.querySelector('.stage-left').classList.remove('close');
                this.template.querySelector('.stage-left').classList.add('open');
            }

            let timer = window.setTimeout(() => {
                this.template.querySelector('.custom-lightning-accordion').classList.remove('lightning-accordion-hide');
                this.template.querySelector('.custom-lightning-accordion').classList.add('lightning-accordion-show');
                window.clearTimeout(timer);
            }, 500);
            this.toggleClick = 1;
        }




    }
    navigateToRecord(event) {
        const recordId = event.currentTarget.dataset.id;

        this[NavigationMixin.GenerateUrl]({
           type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        }).then(url => {
            window.open(url, "_blank");
        });
    }
    navigateToRecords(event) {
        const recordId = event.currentTarget.dataset.id;

       this[NavigationMixin.GenerateUrl]({
           type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        }).then(url => {
            window.open(url, "_blank");
        });

    }

    @track totalLineItem=0;
    getSOlineItemLength(lineItemList){
        this.totalLineItem += lineItemList.length;
    }

    orderId='';
    orderLinteItemId='';
    pendingQty=0;
    parentIndex=0;
    childIndex=0;
    openDisptachPlanningPopup(event){
        this.orderId=event.target.dataset.orderid
        this.orderLinteItemId=event.target.dataset.orderlineitem;
        this.pendingQty=parseInt(event.target.dataset.pendingqty);
        this.listOfPartialAccount = [];
        this.isShowModal=true;
        
        this.parentIndex=event.target.dataset.index
        this.childIndex=event.target.dataset.yindex
        getScheduledOrder({orderId:this.orderId,orderLineItemId:this.orderLinteItemId})
        .then((result)=>{
            let res=result;
            if(res.length ==0){
                this.addNewRow();
            }else{
                var index=0
                res.forEach(element => {
                    element.index =index+1
                    console.log('element.index ',element.index);
                    index++
                });
                this.listOfPartialAccount=res;
            }
        })
       
    }
    hideModalBox(){
        this.isShowModal=false;
    }

    @track listOfPartialAccount=[];
    @track isShowModal=false;
    /**
     * Adds a new row
     */
    addNewRow() {
        console.log('addNewRow ');
        this.createRow(this.listOfPartialAccount);
      
    }

    createRow(listOfPartialAccount) {
        let partialDispatch = {};
        if(listOfPartialAccount.length > 0) {
            partialDispatch.index = listOfPartialAccount[listOfPartialAccount.length - 1].index + 1;
        } else {
            partialDispatch.index = 1;
        }
        partialDispatch.Id='create'+'-'+partialDispatch.index ;
        partialDispatch.Disptach_Qty__c = null;
        partialDispatch.Planning_Ready_by_Date__c = null;
        partialDispatch.Planning_Dispatch_Remark__c = null;
        this.listOfPartialAccount.push(partialDispatch);
        console.log('this.listOfPartialAccount ',JSON.stringify(this.listOfPartialAccount));
    }
    /**
     * Removes the selected row
     */
    removeRow(event) {
        let toBeDeletedRowIndex = event.target.name;
        let toBeDeletedRowId = event.target.dataset.id;
        console.log('toBeDeletedRowId ',toBeDeletedRowId);
        if(!toBeDeletedRowId.includes('create')){
            removeRowPartialData({dispatchId:toBeDeletedRowId})
            .then((res)=>{
                if(res){
                    this.f_msg_success('Success','Deleted');
                }else{
                    this.f_msg_error('Error','Something went wrong!');
                }
            })
        }
        let listOfPartialAccount = [];
        for(let i = 0; i < this.listOfPartialAccount.length; i++) {
            let tempRecord = Object.assign({}, this.listOfPartialAccount[i]); //cloning object
            if(tempRecord.index !== toBeDeletedRowIndex) {
                listOfPartialAccount.push(tempRecord);
            }
        }
        for(let i = 0; i < listOfPartialAccount.length; i++) {
            listOfPartialAccount[i].index = i + 1;
        }
        this.listOfPartialAccount = listOfPartialAccount;
    }
    /**
     * Removes all rows
     */
    removeAllRows() {
        let listOfPartialAccount = [];
        this.createRow(listOfPartialAccount);
        this.listOfPartialAccount = listOfPartialAccount;
        removeALlPartialData({orderId:this.orderId,orderLineItemId:this.orderLinteItemId})
        .then((result)=>{
            if(result){
                this.f_msg_success('Success','Removed all plan , please plan again');
            }
        })

    }
    handleInputChange(event) {
        let index = event.target.dataset.id;
        let fieldName = event.target.name;
        let value = event.target.value;
        for(let i = 0; i < this.listOfPartialAccount.length; i++) {
            if(this.listOfPartialAccount[i].index === parseInt(index)) {
                this.listOfPartialAccount[i][fieldName] = value;
            }
        }
        if(fieldName=='Planning_Ready_by_Date__c'){
            let currentDate = new Date().toJSON().slice(0, 10);
            if(value < currentDate){
                this.f_msg_error('Error', 'Back dated dispatch plan date is not allowed');
            }else{
                 this.recordList[this.parentIndex].item_list[this.childIndex].Planning_Ready_by_Date__c = value;
                 this.recordList[this.parentIndex].item_list[this.childIndex].edit_record = true;
            }
           
        }

         if(fieldName=='Planning_Dispatch_Remark__c'){
            this.recordList[this.parentIndex].item_list[this.childIndex].Planning_Dispatch_Remark__c = value;
            this.recordList[this.parentIndex].item_list[this.childIndex].edit_record = true;
        }
        
        if(fieldName=='Deviation_Reason__c'){
            this.recordList[this.parentIndex].item_list[this.childIndex].Deviation_Reason__c = value;
            this.recordList[this.parentIndex].item_list[this.childIndex].edit_record = true;
        }
    }
    save(event){
        
        let currentDate = new Date().toJSON().slice(0, 10);
        var isBackDatedDisptachPlanDate=false;
        let qty=0
        this.listOfPartialAccount.forEach(element => {
            qty=qty+parseFloat(element.Disptach_Qty__c);
            if(element.Planning_Ready_by_Date__c < currentDate){
                isBackDatedDisptachPlanDate=true;
            }
       });
       if(qty>this.pendingQty){
        this.f_msg_error('Error', 'Disptach qty should not be greater then your pending volume');
       }else if(isBackDatedDisptachPlanDate){
           this.f_msg_error('Error', 'Back dated dispatch plan date is not allowed');
       }
        else{
            savePartialDisptach({orderId:this.orderId,orderLineItemId:this.orderLinteItemId,dataList:JSON.stringify(this.listOfPartialAccount)})
            .then((result)=>{
                if(result){
                    this.f_msg_success('Success', 'Done');
                    this.recordList[this.parentIndex].item_list[this.childIndex].background_icon = 'status_today_icon';
                    this.recordList[this.parentIndex].item_list[this.childIndex].isplannedStaus='is-planned';
                    this.isShowModal=false;
                }else{
                    this.f_msg_error('Error ', 'Something went wrong');
                }
            })
        }
       
        
    }




}