import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';

import Order from '@salesforce/schema/Order';
import Pricing_Status__c from '@salesforce/schema/Order.Pricing_Status__c';
import COGS_Status__c from '@salesforce/schema/Order.COGS_Status__c';
import Credit_Status__c from '@salesforce/schema/Order.Credit_Status__c';

import getOrderData from '@salesforce/apex/FullfillmentPlanningController.getOrderData';
import getCustomerSchedules from '@salesforce/apex/FullfillmentPlanningController.getCustomerSchedules';
import saveCustomerSchedules from '@salesforce/apex/FullfillmentPlanningController.saveCustomerSchedules';
import removeRowScheduleData from '@salesforce/apex/FullfillmentPlanningController.removeRowScheduleData';
import removeAllCustomerSchedules from '@salesforce/apex/FullfillmentPlanningController.removeAllCustomerSchedules';
import getOrderPicklistOptions from '@salesforce/apex/FullfillmentPlanningController.getOrderPicklistOptions';
import getFilteredOrderData from '@salesforce/apex/FullfillmentPlanningController.getFilteredOrderData';
import saveHeader from '@salesforce/apex/FullfillmentPlanningController.saveHeader';

export default class FulfillmentPlanning extends NavigationMixin(LightningElement) {
    @track plannedOrders = 0;
    @track unplannedOrders = 0;
    @track todayDispatch = 0;
    @track nextDayDispatch = 0;
    @track dayAfterDispatch = 0;
    @track otherDispatch = 0;
    @track dueToday = 0;
    @track scheduleMissed = 0;

    @track orders = [];
    @track displayOrders = [];
    @track orderHeaders = [];

    @track isModalOpen = false;
    @track customerSchedules = [];
    selectedOrderId;
    selectedOrderLineId;
    selectedLineId;
    confirmedQty;
    dispatchPopupHeading;

    @track totalLineNumber = 0;

    @track pricingStatusOptions = [];
    @track cogsStatusOptions = [];
    @track creditStatusOptions = [];

    @track showFilterSection = false;

    @track filterOption;

    @track filterObject = {};

    @wire(getObjectInfo, { objectApiName: Order })
    formObjectInfo;

    @wire(getPicklistValues, { recordTypeId: '$formObjectInfo.data.defaultRecordTypeId', fieldApiName: Pricing_Status__c })
    wiredPricingStatus({ data, error }) {
        if (data) {
            this.pricingStatusOptions = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));

        } else if (error) {
            console.error('Error fetching picklist values', error);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$formObjectInfo.data.defaultRecordTypeId', fieldApiName: COGS_Status__c })
    wiredCogsStatus({ data, error }) {
        if (data) {
            this.cogsStatusOptions = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));

        } else if (error) {
            console.error('Error fetching picklist values', error);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$formObjectInfo.data.defaultRecordTypeId', fieldApiName: Credit_Status__c })
    wiredCreditStatus({ data, error }) {
        if (data) {
            this.creditStatusOptions = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));

        } else if (error) {
            console.error('Error fetching picklist values', error);
        }
    }

    connectedCallback() {
        this.loadData();
        this.loadOrderPicklistValues();
    }

    loadData() {
        getOrderData({ orderRecordType: 'Domestic' }).then((result)=>{
            console.log('Fetched Orders:', result);
            this.orders = result;
            this.displayOrders = result;

            this.totalLineNumber = 0;
            for (let order of this.orders) {
                this.totalLineNumber += order.orderSchedulingLine.length;
            }
        }).catch((error)=>{
            this.showToast('System Error', error, 'error');
        })
    }

    loadOrderPicklistValues() {
        getOrderPicklistOptions({orderRecordType: 'Domestic'}).then((result)=>{
            console.log('Picklist Options:', result);
            this.filterOption = result;
        }).catch((error)=>{
            this.showToast('System Error', error, 'error');
        })
    }

    handleFilterChanges(event) {
        let field = event.target.dataset.id;
        let value = event.target.value;
        
        this.filterObject[field] = value;

        console.log(JSON.parse(JSON.stringify(this.filterObject)));
    }

    handleReset() {
        this.filterObject = {};
        this.loadData();
    }

    handleSearch() {
        getFilteredOrderData({orderRecordType: 'Domestic', filterStringObj: JSON.stringify(this.filterObject)}).then((result)=>{
            console.log('Filtered Orders:', result);
            this.orders = result;
            this.displayOrders = result;

            this.totalLineNumber = 0;
            for (let order of this.orders) {
                this.totalLineNumber += order.orderSchedulingLine.length;
            }

        }).catch((error)=>{
            this.showToast('System Error', error, 'error');
        })
    }

    toggleExpand(event) {
        const orderId = event.currentTarget.dataset.id;
        this.orders = this.orders.map(o => {
            return { ...o, isExpanded: o.orderId === orderId ? !o.isExpanded : o.isExpanded };
        });
    }

    toggleFilterSection() {
        this.showFilterSection = !this.showFilterSection;
    }

    handleOrderFieldChange(event) {
        const orderId = event.currentTarget.dataset.id;
        const field = event.currentTarget.dataset.field;
        const value = event.target.value;


        let orderObject = this.orderHeaders.find(o => o.id === orderId);
        if (orderObject) {
            orderObject[field] = value;
            console.log('Updated Order Object:', orderObject);
        } else {
            this.orderHeaders.push({
                id: orderId,
                [field]: value
            })
        }
    }

    saveHeaderChanges() {
        console.log('Saving Order Headers:', JSON.parse(JSON.stringify(this.orderHeaders)));

        if (this.orderHeaders.length === 0) {
            this.showToast('Error', 'No changes to save.', 'error');
            return;
        }

        saveHeader({headerStringObj: JSON.stringify(this.orderHeaders)}).then((result)=>{
            if (result == 'Success') {
                this.showToast('Success', 'Order headers saved successfully', 'success');
                this.orderHeaders = [];
                this.loadData();
            }
        }).catch((error)=>{
            this.showToast('System Error', error, 'error');
        })
    }

    openCustomerModal(event) {
        this.selectedOrderId = event.currentTarget.dataset.orderid;
        this.selectedLineId = event.currentTarget.dataset.lineid;
        this.selectedOrderLineId = event.currentTarget.dataset.orderline;
        this.confirmedQty = event.currentTarget.dataset.confirmedqty ? event.currentTarget.dataset.confirmedqty : 0;
        this.dispatchPopupHeading = 'Plan your dispatch for ' + this.confirmedQty + ' Qty';
        console.log('Selected Order ID:', this.selectedOrderId, 'Line ID:', this.selectedLineId);
        getCustomerSchedules({orderId: this.selectedOrderId, orderProductLineId: this.selectedOrderLineId, orderSchedulingLineItemId: this.selectedLineId}).then((result)=>{
            this.customerSchedules = result && result.length > 0
                ? JSON.parse(JSON.stringify(result))
                : [{ name: '', customerScheduledQuantity: null, customerScheduledDate: null, productionScheduledDate: null, productionRevisedDate: null, remarksForProductionPlanner: '', isNew: true }];
            this.customerSchedules = this.customerSchedules.map(item => ({
                ...item,
                tempId: Date.now().toString() + '-' + Math.random().toString(36).substring(2,7).toUpperCase()
            }));

            console.log('customerSchedules', JSON.parse(JSON.stringify(this.customerSchedules)));
            this.isModalOpen = true;
        }).catch((error)=>{
            this.showToast('System Error', error, 'error');
        })
    }

    saveCustomerScheduleLine() {
        if (!this.validateCustomerSchedules()) {
            return;
        }

        console.log('Saving schedules:', JSON.parse(JSON.stringify(this.customerSchedules)));

        console.log('Selected Order ID:', this.selectedOrderId, 'Line ID:', this.selectedLineId, 'Order Line ID:', this.selectedOrderLineId);

        this.customerSchedules = this.customerSchedules.map(item => ({
            ...item,
            orderId: this.selectedOrderId,
            orderProductId: this.selectedOrderLineId,
            orderSchedulingLineItemId: this.selectedLineId
        }));

        console.log('while save customerSchedules', JSON.parse(JSON.stringify(this.customerSchedules)));

        saveCustomerSchedules({customerScheduleStringObj: JSON.stringify(this.customerSchedules)}).then((result)=>{
            if (result == 'Success') {
                this.showToast('Success', 'Customer schedules saved successfully', 'success');
                this.closeCustomerModal();
            }
        }).catch((error)=>{
            this.showToast('System Error', error, 'error');
            this.closeCustomerModal();
        })
    }

    closeCustomerModal() {
        this.isModalOpen = false;
        this.customerSchedules = [];
    }

    handleCustomerChange(event) {
        const index = event.currentTarget.dataset.index;
        const field = event.currentTarget.dataset.field;
        const value = event.detail.value;
        this.customerSchedules[index][field] = value;
    }

    addCustomerRow() {
        if (!this.validateCustomerSchedules()) {
            return;
        }
        this.customerSchedules = [...this.customerSchedules, { tempId: Date.now().toString() + '-' + Math.random().toString(36).substring(2,7).toUpperCase(), name: '', customerScheduledQuantity: null, customerScheduledDate: null, productionScheduledDate: null, productionRevisedDate: null, remarksForProductionPlanner: '', isNew: true }];
    }

    deleteCustomerRow(event) {
        const index = event.currentTarget.dataset.index;
        let toRemoveItem = this.customerSchedules[index];
        if (toRemoveItem.isNew) {
            this.customerSchedules.splice(index, 1);
            this.customerSchedules = [...this.customerSchedules];
            if (this.customerSchedules.length === 0) {
                this.customerSchedules = [{ name: '', customerScheduledQuantity: null, customerScheduledDate: null, productionScheduledDate: null, productionRevisedDate: null, remarksForProductionPlanner: '', isNew: true }];
            }
        } else {
            console.log('Delete schedule with ID:', toRemoveItem.recordId);
            removeRowScheduleData({customerOrderScheduleId: toRemoveItem.recordId}).then((result)=>{
                if (result == 'Success') {
                    this.showToast('Success', 'Customer schedule deleted successfully', 'success');
                    this.customerSchedules.splice(index, 1);
                    this.customerSchedules = [...this.customerSchedules];
                    if (this.customerSchedules.length === 0) {
                        this.customerSchedules = [{ name: '', customerScheduledQuantity: null, customerScheduledDate: null, productionScheduledDate: null, productionRevisedDate: null, remarksForProductionPlanner: '', isNew: true }];
                    }
                }
            }).catch((error)=>{
                this.showToast('System Error', error, 'error');
            })
        }
    }

    deleteAllCustomerRows() {
        console.log('Deleting all schedules for Order ID:', this.selectedOrderId, 'Line ID:', this.selectedLineId, 'Order Line ID:', this.selectedOrderLineId);
        removeAllCustomerSchedules({orderId: this.selectedOrderId, orderProductLineId: this.selectedOrderLineId, orderSchedulingLineItemId: this.selectedLineId}).then((result)=>{
            if (result == 'Success') {
                this.showToast('Success', 'All customer schedules deleted successfully', 'success');
                this.customerSchedules = [{ name: '', customerScheduledQuantity: null, customerScheduledDate: null, productionScheduledDate: null, productionRevisedDate: null, remarksForProductionPlanner: '', isNew: true }];
            }
        }).catch((error)=>{
            this.showToast('System Error', error, 'error');
        })
    }

    validateCustomerSchedules() {
        let totalScheduledQty = 0;

        for (let each of this.customerSchedules) {
            if (each.customerScheduledQuantity == null || each.customerScheduledQuantity === '' || isNaN(each.customerScheduledQuantity) || parseFloat(each.customerScheduledQuantity) <= 0) {
                this.showToast('Error', 'Please enter a valid Customer Scheduled Quantity greater than 0.', 'error');
                return false;
            }
            if (each.customerScheduledDate == null || each.customerScheduledDate === '') {
                this.showToast('Error', 'Please enter a valid Customer Scheduled Date.', 'error');
                return false;
            }

            totalScheduledQty += each.customerScheduledQuantity ? parseFloat(each.customerScheduledQuantity) : 0;
        }

        if (totalScheduledQty > parseFloat(this.confirmedQty)) {
            this.showToast('Error', 'Total scheduled quantity exceeds confirmed quantity.', 'error');
            return false;
        }
        return true;
    }

    showToast(title, message, variant) {

        if (title == 'System Error') {
            console.error('Error: ', message);
            message = message.body.message;
        }

        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }

    navigateToRecord(event) {
        let recordId = event.target.dataset.id;
        let baseUrl = window.location.origin;
        let recordUrl = `${baseUrl}/${recordId}`;
        window.open(recordUrl, '_blank');
    }

    handlePaginationChange(event) {
        this.displayOrders = event.detail.records;
    }

}