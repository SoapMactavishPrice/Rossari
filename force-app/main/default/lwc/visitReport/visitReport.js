import { LightningElement, track, wire } from 'lwc';
import getContact from '@salesforce/apex/VisitReportController.getContact';
import getUser from '@salesforce/apex/VisitReportController.getUser';
import getContactsByAccount from '@salesforce/apex/VisitReportController.getContactsByAccount';
import saveVisitReport from '@salesforce/apex/VisitReportController.saveVisitReport';
import getCustomerDetails from '@salesforce/apex/VisitReportController.getCustomerDetails';
import getCompetitorDetails from '@salesforce/apex/VisitReportController.getCompetitorDetails';
import getTours from '@salesforce/apex/VisitReportController.getTours';
import createTourRecord from '@salesforce/apex/VisitReportController.createTour';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class VisitReport extends LightningElement {

    @track dataMap = {
        Mode: '',
        Title_of_Meeting: '',
        Start_Date_Time: '',
        End_Date_Time: '',
        Category: '',
        Nature: ''
    };
    @track continentName = '';
    @track accId = '';
    @track contactSearchBy = 'Lead';
     @track currencyCode = '';
     @track location = '';
     @track tourId = '';
     @track sapCustomerCode = '';
    @track recordTypeDevName = '';
    @track customerId;
    @track competitorId;
    @track competitorCode;
    @track visitCategory;
    @track tourOptions = [];
    @track selectedTourId;
    @track isModalOpen = false;
    @track newTourName = '';
    @track newTourStart = '';
    @track newTourEnd = '';
    isTourDisabled = true; // default disabled

    // ✅ Initialize all lists
    @track Attendees = [];
    @track ProductInterestPoint = [];
    @track ActionPoint = [];

     @track isLead = true;
     @track selectedType = 'Lead'

     userTypeOptions = [
        { label: 'New', value: 'New' },
        { label: 'Existing', value: 'Existing' }
    ];

    attendeeTypeOptions = [
        { label: 'Internal Attendee', value: 'Internal Attendee' },
        { label: 'External Attendee', value: 'External Attendee' }
    ];

    handleAccountSelectedForBillTo(event) {
        this.customerId = event.detail.recordId;

        if (this.customerId) {
            // update dataMap so Apex gets it
            this.dataMap['Customer_Name'] = this.customerId;

            getCustomerDetails({ accountId: this.customerId })
                .then(result => {
                    this.sapCustomerCode = result.SAP_Customer_Code__c;
                    this.recordTypeName = result.RecordType;
                })
                .catch(error => {
                    console.error('Error fetching customer details:', error);
                });
                
            // Fetch contacts for selected account
            getContactsByAccount({ accId: this.customerId })
                .then(contactList => {
                    this.accountContacts = contactList.map(c => ({
                        label: c.Name,
                        value: c.Id
                    }));
                })
                .catch(error => {
                    console.error('Error fetching contacts:', error);
                    this.accountContacts = [];
                });

        } else {
            delete this.dataMap['Customer_Name'];
            this.accountContacts = [];
        }
    }

    handleLeadSelectedForBillTo(event) {
        const fieldName = event.target.dataset.label;
        const fieldValue = event.detail.recordId;
        const fieldlocation = event.detail.recordName;
        this.location =event.detail.address;
        this.location += ' '+fieldlocation.split('-')[1]?.trim();

        this.dataMap[fieldName] = fieldValue;
        console.log('OUTPUT : fieldName',fieldlocation,fieldValue);
        if (fieldName == 'lead_Name') {
            if (fieldValue == '') {
                this.continentName = '';
            }
        }
       
    }

//    handleTourChange(event) {
//         this.tourId = event.detail.recordId;   
//         this.dataMap['tourId'] = this.tourId;  // ✅ push into dataMap
//     }

//     handleNewTour() {
//     // Option A: Open new record page
//     this[NavigationMixin.Navigate]({
//         type: 'standard__objectPage',
//         attributes: {
//             objectApiName: 'Tour__c',
//             actionName: 'new'
//         }
//     });

//     // Option B: Open custom modal with lightning-record-edit-form
// }


    //Load existing Tours
    @wire(getTours)
    wiredTours({ error, data }) {
        if (data) {
            this.tourOptions = data.map(t => ({ label: t.Name, value: t.Id }));
            this.tourOptions.push({ label: '➕ Create New Tour', value: 'createNew' });
        } else if (error) {
            console.error('Error fetching tours:', error);
        }
    }

    handleTourChange(event) {
        const value = event.detail.value;
        if (value === 'createNew') {
            this.isModalOpen = true;
        } else {
            this.selectedTourId = value;

            // ✅ Push into dataMap so Save picks it up
            this.dataMap['tourId'] = this.selectedTourId;
        }
    }

    handleTourNameChange(event) {
        this.newTourName = event.target.value;
    }

    handleTourStartChange(event) {
        this.newTourStart = event.target.value;
    }

    handleTourEndChange(event) {
        this.newTourEnd = event.target.value;
    }

    closeModal() {
        this.isModalOpen = false;
        this.newTourName = '';
    }

    async createTour() {
        if (!this.newTourName || !this.newTourStart || !this.newTourEnd) {
            alert('Please fill Tour Name, Start Date, and End Date');
            return;
        }
        try {
            const newTour = await createTourRecord({
                tourName: this.newTourName,
                startDate: this.newTourStart,
                endDate: this.newTourEnd
            });

            // Add new option to combobox
            this.tourOptions.splice(this.tourOptions.length - 1, 0, { 
                label: newTour.Name, 
                value: newTour.Id 
            });

            // Select newly created
            this.selectedTourId = newTour.Id;
            this.dataMap['tourId'] = this.selectedTourId;

            this.closeModal();
        } catch (error) {
            console.error('Error creating tour:', error);
        }
    }

    handleProjectChange(event) {
        this.ProjectId = event.detail.recordId;   
        this.dataMap['ProjectId'] = this.ProjectId;  // ✅ push into dataMap
    }


    // called when user selects Competitor from record picker
    handleCompetitorChange(event) {
        this.competitorId = event.detail.recordId;

        if (this.competitorId) {
            this.dataMap['Competition_Name'] = this.competitorId; // ✅ push into dataMap

            getCompetitorDetails({ competitorId: this.competitorId })
                .then(result => {
                    this.competitorCode = result.Competitor_Code__c;
                })
                .catch(error => {
                    console.error('Error fetching competitor details', error);
                });
        } else {
            delete this.dataMap['Competition_Name'];
            this.competitorCode = '';
        }
    }


    // handles other fields (record-edit-form, inputs, etc.)
    handleVisitChange(event) {
        const fieldName = event.target.dataset.label;
        const fieldValue = event.target.value;

        if (!fieldValue) {
            delete this.dataMap[fieldName];
        } else {
            this.dataMap[fieldName] = fieldValue;
        }

        // ✅ Handle Start_Date_Time__c auto-populating End_Date_Time__c
        if (fieldName === 'Start_Date_Time') {
            if (fieldValue) {
                let startDate = new Date(fieldValue);
                let endDate = new Date(startDate);
                endDate.setHours(endDate.getHours() + 1); // add 1 hour

                // Save in dataMap
                this.dataMap['End_Date_Time'] = endDate.toISOString();

                // Auto update End Date field in UI
                const endDateField = this.template.querySelector(
                    '[data-label="End_Date_Time"]'
                );
                if (endDateField) {
                    endDateField.value = this.dataMap['End_Date_Time'];
                }
            } else {
                delete this.dataMap['End_Date_Time'];
            }
        }

            // ✅ Handle Type_of_Visit__c logic
        if (fieldName === 'Mode') {  
            if (fieldValue === 'Tour') {
                this.isTourDisabled = false;
            } else {
                this.isTourDisabled = true;
                this.selectedTourId = null;
                delete this.dataMap['tourId']; // clear tour when not needed
            }
        }

        // Customer Handling
        if (fieldName === 'Customer_Name') {
            if (!fieldValue) {
                this.sapCustomerCode = '';
                this.customerRecordType = '';
            } else {
                getCustomerDetails({ accountId: fieldValue })
                    .then(result => {
                        if (result) {
                            this.sapCustomerCode = result.SAP_Customer_Code__c;
                            this.customerRecordType = result.RecordTypeName;
                        }
                    })
                    .catch(error => {
                        console.error('Error fetching customer details:', error);
                    });
            }
        }

        // Visit Category Handling
        if (fieldName === 'Category') {
            this.visitCategory = fieldValue;
        }
    }

    // Getters for visit category
    get isCustomerVisit() {
        return this.visitCategory === 'Customer Visit';
    }
    get isCompetitorTracking() {
        return this.visitCategory === 'Competitor Tracking';
    }
    get isInternalMeeting() {
        return this.visitCategory === 'Internal Meeting';
    }
    get isRND() {
        return this.visitCategory === 'RND related Visit';
    }
    get isSeminar() {
        return this.visitCategory === 'Seminar/ Conferences';
    }



    usedCodes = new Set();

    generateUniqueCode() {
        let code;
        do {
            code = Math.floor(1000 + Math.random() * 9000); // 4-digit code
        } while (this.usedCodes.has(code));

        this.usedCodes.add(code);
        return code;
    }

    connectedCallback() {
        this.addAttendeesrow();
        this.addProductInterestrow();
        this.addActionPointrow();
    }
    @track attendeesList = [
        {
            index: 0,
            Attendee_Type__c: '',
            isExist: false,
            First_Name__c: '',
            Last_Name__c: '',
            Email__c: '',
            Designation__c: '',
            Name: '',
            Email: '',
            Designation: ''
        }
    ];


    addAttendeesrow() {
        let temCon2 = {
            "index": this.generateUniqueCode(),
            "isExist": false,
            "Title": "",
            "Name": "",
            "User_Type__c": "",
            "Contact_Name__c": "",
            "First_Name": "",
            "Last_Name": "",
            "Email__c": "",
            "Designation__c": "",
        };
        this.Attendees.push(temCon2);
    }

    handleAttendeeChange(event) {
        const recordIndex = parseInt(event.target.dataset.index, 10); // unique 4-digit code
        const field = event.target.dataset.label;
        const value = event.detail.value;

        let updated = [...this.Attendees];
        const idx = updated.findIndex(a => a.index === recordIndex);

        if (idx !== -1) {
            updated[idx][field] = value;

            // compute flags for conditional rendering
            const type = updated[idx].Attendee_Type__c;
            const userType = updated[idx].User_Type__c;

            updated[idx].isInternalNew = type === 'Internal Attendee' && userType === 'New';
            updated[idx].isInternalExisting = type === 'Internal Attendee' && userType === 'Existing';
            updated[idx].isExternalNew = type === 'External Attendee' && userType === 'New';
            updated[idx].isExternalExisting = type === 'External Attendee' && userType === 'Existing';
        }

        this.Attendees = updated;
    }



    handleCustomerAttenChange(event) {
        const fieldName = event.target.dataset.label;
        const fieldValue = event.target.value;
        const contactCode = parseInt(event.target.dataset.index, 10);

        const contactIndex = this.Attendees.findIndex(
            attendee => attendee.index === contactCode
        );

        if (contactIndex !== -1) {
            if (fieldName === 'Contact_Type') {
                this.Attendees[contactIndex].isExist = (fieldValue === 'Existing');
                this.Attendees[contactIndex].Contact_Name__c = '';
                this.Attendees[contactIndex].Name = '';
                this.Attendees[contactIndex].Email__c = '';
                this.Attendees[contactIndex].Phone = '';
                this.Attendees[contactIndex].Designation__c = '';
            }

            if (fieldName === 'Contact') {
                if (fieldValue) {
                    getContact({ accId: fieldValue })
                        .then(result => {
                            this.Attendees[contactIndex].Name = result.Name;
                            this.Attendees[contactIndex].Email__c = result.Email;
                            this.Attendees[contactIndex].Phone = result.Phone;
                            this.Attendees[contactIndex].Designation__c = result.Title;
                            this.Attendees = [...this.Attendees];
                        })
                        .catch(error => {
                            console.error('Error getting contact', error);
                        });
                } else {
                    this.Attendees[contactIndex].Name = '';
                    this.Attendees[contactIndex].Email__c = '';
                    this.Attendees[contactIndex].Phone = '';
                    this.Attendees[contactIndex].Designation__c = '';
                }
            }

            this.customer_Attendees[contactIndex][fieldName] = fieldValue;
            this.customer_Attendees = [...this.customer_Attendees];
        }
    }

    removeAttendees(event) {
        if (this.Attendees.length > 1) {
            const custCode = parseInt(event.target.dataset.index, 10);
            this.usedCodes.delete(custCode);
            this.Attendees = this.Attendees.filter(
                contact => contact.index !== custCode
            );
        }
    }

    addActionPointrow() {
        let temCon2 =
        {
            "index": this.generateUniqueCode(),
            "Name": "",
            "userId": "",
            "Next_Action_Date": "",
            "Create_Task_Notify": true,
        };
        this.ActionPoint.push(temCon2);
    }


    removeActionPoint(event) {
        if (this.ActionPoint.length > 1) {
            const custCode = parseInt(event.target.dataset.index, 10);
            console.log('Removing contact with code:', custCode);

            // Remove code from the usedCodes set
            this.usedCodes.delete(custCode);

            // Filter out the contact with this index (unique code)
            this.ActionPoint = this.ActionPoint.filter(contact => contact.index !== custCode);
        }
    }

    lookUpAccount(event) {

        const rowIndex = parseInt(event.target.dataset.index, 10); // Unique index
        console.log('rowIndex-->', rowIndex);

        const itemIndex = this.ProductInterestPoint.findIndex(item => item.index === rowIndex);
        console.log('itemIndex-->', itemIndex);

        if (itemIndex === -1) return; // Exit if item not found


        const detail = event.detail;
        console.log(itemIndex, 'detail-->', JSON.stringify(detail));


        if (detail) {
            const tempData = JSON.parse(JSON.stringify(detail));
            this.ProductInterestPoint[itemIndex].prodId = tempData.id || '';

        } else {
            this.ProductInterestPoint[itemIndex].prodId = '';
        }
        this.ProductInterestPoint = [...this.ProductInterestPoint];
        console.log('current index-->', JSON.stringify(this.ProductInterestPoint[itemIndex]));

    }

    addProductInterestrow() {
        let temCon2 =
        {
            "index": this.generateUniqueCode(),
            "prodId": "",
            "qty": "",
            "Price": "",
            "ExpDate": false,
        };
        this.ProductInterestPoint.push(temCon2);
    }


    removeProductInterest(event) {
        if (this.ProductInterestPoint.length > 1) {
            const custCode = parseInt(event.target.dataset.index, 10);
            console.log('Removing contact with code:', custCode);

            // Remove code from the usedCodes set
            this.usedCodes.delete(custCode);

            // Filter out the contact with this index (unique code)
            this.ProductInterestPoint = this.ProductInterestPoint.filter(contact => contact.index !== custCode);
        }
    }


    handleActionPlanChange(event) {
        const fieldName = event.target.dataset.label;
        const fieldValue = event.target.value;
        const contactCode = parseInt(event.target.dataset.index, 10); // 4-digit unique code

        // Find the index of the contact with the matching code
        const contactIndex = this.ActionPoint.findIndex(c => c.index === contactCode);
        if (contactIndex !== -1) {
            // Update the field directly
            this.ActionPoint[contactIndex][fieldName] = fieldValue;

            // Reassign the array to trigger reactivity
            this.ActionPoint = [...this.ActionPoint];

            console.log(`Updated ${fieldName} for contact ${contactCode}:`, fieldValue);
        }
    }

    handleActionCheckboxPlanChange(event) {
        const fieldName = event.target.dataset.label;
        const fieldValue = event.target.checked;
        const contactCode = parseInt(event.target.dataset.index, 10); // 4-digit unique code

        // Find the index of the contact with the matching code
        const contactIndex = this.ActionPoint.findIndex(c => c.index === contactCode);
        if (contactIndex !== -1) {
            // Update the field directly
            this.ActionPoint[contactIndex][fieldName] = fieldValue;

            // Reassign the array to trigger reactivity
            this.ActionPoint = [...this.ActionPoint];

            console.log(`Updated ${fieldName} for contact ${contactCode}:`, fieldValue);
        }
    }

    handleInterestChange(event) {
        const fieldName = event.target.dataset.label;
        const fieldValue = event.target.value;
        const contactCode = parseInt(event.target.dataset.index, 10); // 4-digit unique code

        // Find the index of the contact with the matching code
        const contactIndex = this.ProductInterestPoint.findIndex(c => c.index === contactCode);
        console.log('contactCode-->', contactCode);
        console.log('contactIndex-->', contactIndex);
        if (contactIndex !== -1) {
            // Update the field directly
            this.ProductInterestPoint[contactIndex][fieldName] = fieldValue;

            // Reassign the array to trigger reactivity
            this.ProductInterestPoint = [...this.ProductInterestPoint];

            console.log(`Updated ${fieldName} for contact ${contactCode}:`, fieldValue);
        }
    }

    validateVisitReport() {
        // mapping of your dataMap keys to user-friendly labels
        const fieldLabels = {
            Mode: 'Type of Visit',
            Title_of_Meeting: 'Title of Meeting',
            Start_Date_Time: 'Start Date/Time',
            End_Date_Time: 'End Date/Time',
            Category: 'Visit Category',
            Nature: 'Nature of Visit'
        };

        const requiredFields = Object.keys(fieldLabels);

        let isValid = true;
        let missingFields = [];

        requiredFields.forEach(field => {
            if (!this.dataMap[field]) {
                isValid = false;
                missingFields.push(fieldLabels[field]); // use label mapping
            }
        });

        if (!isValid) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Missing Required Fields',
                    message: `Please fill the following fields: ${missingFields.join(', ')}`,
                    variant: 'error'
                })
            );
        }

        return isValid;
    }


    handleRefresh() {
        window.location.reload();
    }

    @track showSpinner = false;

    handleSave() {
    // 🔎 First validate required fields
        if (!this.validateVisitReport()) {
            return; // ⛔ Stop here if validation fails
        }

        this.showSpinner = true;

        saveVisitReport({
            visit: JSON.stringify(this.dataMap),
            Attendees: JSON.stringify(this.Attendees), // ✅ pass attendees list
            ProductInterestPoint: JSON.stringify(this.ProductInterestPoint),
            ActionPoint: JSON.stringify(this.ActionPoint),
            location: this.location,
            currencyCode: this.currencyCode,
            visitType: this.selectedType
        })
        .then(result => {
            this.showSpinner = false;

            if (result.Message === 'Success') {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success!',
                        message: 'Record has been saved successfully.',
                        variant: 'success',
                        mode: 'dismissable'
                    })
                );
                // open record in new tab
                window.open('/' + result.Id, '_blank');
                // refresh after delay
                setTimeout(() => this.handleRefresh(), 3500);
            } else {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: result.Message,
                        variant: 'error',
                        mode: 'dismissable'
                    })
                );
            }
        })
        .catch(error => {
            this.showSpinner = false;
            console.error('Save error:', error);

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.body?.message || 'Unexpected error occurred',
                    variant: 'error',
                    mode: 'sticky'
                })
            );
        });
    }


}