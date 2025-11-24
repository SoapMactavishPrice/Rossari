import { LightningElement, track, wire } from 'lwc';
import getContact from '@salesforce/apex/VisitReportController.getContact';
import getUser from '@salesforce/apex/VisitReportController.getUser';
import getContactsByAccount from '@salesforce/apex/VisitReportController.getContactsByAccount';
import saveVisitReport from '@salesforce/apex/VisitReportController.saveVisitReport';
import getCustomerDetails from '@salesforce/apex/VisitReportController.getCustomerDetails';
import getCompetitorDetails from '@salesforce/apex/VisitReportController.getCompetitorDetails';
import getTours from '@salesforce/apex/VisitReportController.getTours';
import createTourRecord from '@salesforce/apex/VisitReportController.createTour';
import getVisitReportDetails from '@salesforce/apex/VisitReportController.getVisitReportDetails';
import getVisitReportAttendees from '@salesforce/apex/VisitReportController.getVisitReportAttendees';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import NAME_FIELD from '@salesforce/schema/User.Name';
import ENTITY_CODE_FIELD from '@salesforce/schema/User.Entity_Code_1__c';
import ENTITY_CODE_2_FIELD from '@salesforce/schema/User.Entity_Code_2__c';
import ENTITY_CODE_3_FIELD from '@salesforce/schema/User.Entity_Code_3__c';
import DIVISION_CODE_FIELD from '@salesforce/schema/User.Division_Code__c';
import USER_TYPE_FIELD from '@salesforce/schema/User.User_Type__c';

import { NavigationMixin } from 'lightning/navigation';
import getExistingFiles from '@salesforce/apex/VisitReportController.getExistingFiles';

// Combine all fields into one array
const USER_FIELDS = [
    NAME_FIELD,
    ENTITY_CODE_FIELD,
    ENTITY_CODE_2_FIELD,
    ENTITY_CODE_3_FIELD,
    DIVISION_CODE_FIELD,
    USER_TYPE_FIELD
];

export default class VisitReport extends NavigationMixin(LightningElement) {

    @track uploadedFiles = [];
    @track isFilePreviewModalOpen = false;
    @track uploadedFileIds = []; // Store ContentDocumentIds
    @track uploadedFileIds2 = []; // Store ContentDocumentIds

    get hasNoFiles() {
        return !this.uploadedFiles || this.uploadedFiles.length === 0;
    }

    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        uploadedFiles.forEach(file => {
            this.uploadedFiles.push({
                documentId: file.documentId,
                name: file.name,
                contentVersionId: file.contentVersionId
            });
            this.uploadedFileIds.push(file.documentId);
            this.uploadedFileIds2.push(file.documentId);
        });

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: uploadedFiles.length + ' file(s) uploaded successfully',
                variant: 'success'
            })
        );
    }

    openFilePreviewModal() {
        if (this.uploadedFiles && this.uploadedFiles.length > 0) {
            this.isFilePreviewModalOpen = true;
        }
    }

    closeFilePreviewModal() {
        this.isFilePreviewModalOpen = false;
    }

    handleFilePreview(event) {
        const fileId = event.currentTarget.dataset.fileId;
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                selectedRecordId: fileId
            }
        });
    }

    @track dataMap = {
        Mode: '',
        Title_of_Meeting: '',
        Start_Date_Time: '',
        End_Date_Time: '',
        Category: '',
        Nature: ''
    };

    // User fields
    userType;
    userEntityCode1;
    userEntityCode2;
    userEntityCode3;
    userDivisionCode;
    currentUserName;

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
    @track selectedTourAccounts = [];
    @track currentUserId = USER_ID;
    @track currentUserName;
    @track natureOptions = [];

    // ✅ Initialize all lists
    @track Attendees = [];
    @track ProductInterestPoint = [];
    @track ActionPoint = [];

    @track visitReportTypeOptions = [
        { label: 'Planned', value: 'New' },
        { label: 'Unplanned', value: 'Unplanned' },
        { label: 'Existing Visit', value: 'Existing' }


    ];
    @track disableExistingVisitReport = true;
    @track selectedVisitReportType = 'New';
    @track selectedExistingVisitReportId;
    @track isExistingVisitReport = false;
    @track isFormDisabled = false;
    @track showRemainingSections = false;
    @track customer_Attendees = []
    @track showExistingCustomerFields = false;
    @track showNewCustomerField = false;
    @track recordTypeName = '';
    @track accountContacts = [];
    @track ProjectId = '';
    @track selectedExistingVisitReportName = '';
    @track customerRecordType = '';
    @track showSpinner = false;

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


    // ✅ UPDATED wire for user data with User_Type__c
    @wire(getRecord, { recordId: USER_ID, fields: USER_FIELDS })
    wiredUser({ error, data }) {
        if (data) {
            console.log('User record data:', JSON.stringify(data));

            // Extract user fields
            this.currentUserName = data.fields.Name.value;
            this.userType = data.fields.User_Type__c?.value; // Get User_Type__c
            this.userDivisionCode = data.fields.Division_Code__c?.value;

            console.log('User Details - Name:', this.currentUserName,
                'User Type:', this.userType,
                'Division Code:', this.userDivisionCode);

            // If category is already selected, filter nature options
            if (this.visitCategory) {
                this.filterNatureOptions();
            }

        } else if (error) {
            console.error('Error fetching user data:', error);
            this.userType = undefined;
            this.userDivisionCode = undefined;
        }
    }


    // ✅ UPDATED mapping based on User_Type__c
    visitNatureMapping = {
        'Customer Visit': {
            // Textile user type
            'TEXTILE': ['Distributor Visit', 'B2B Visit', 'B2C Visit', 'Industry Visit', 'Technician'],

            // AHN user type  
            'AHN': ['Distributor Visit', 'B2B Customer Visit', 'Farm Visit', 'Consultant', 'Farmer Meeting'],

            // Synthetic user type
            'SYNTHETIC': ['Distributor Visit', 'B2B Visit', 'B2C Visit'],

            // Default for other user types
            'DEFAULT': ['Distributor Visit', 'B2B Customer Visit']
        },
        'Competitor Tracking': {
            'TEXTILE': ['Competitor Distributor', 'Competition Visit'],
            'AHN': ['Competitor Distributor', 'Competition Visit'],
            'SYNTHETIC': ['Competitor Distributor', 'Competition Visit'],
            'DEFAULT': ['Competitor Distributor', 'Competition Visit']
        },
        'Internal Meeting': {
            'TEXTILE': ['HO Meeting', 'Zonal Meeting'],
            'AHN': ['HO Meeting', 'Zonal Meeting'],
            'SYNTHETIC': ['HO Meeting'],
            'DEFAULT': ['HO Meeting']
        },
        'R&D related Visit': {
            'TEXTILE': ['External Lab Visit', 'University Visit', 'Lab Trial'],
            'AHN': ['External Lab Testing', 'University Trial', 'Field Trial – Existing Product'],
            'SYNTHETIC': ['External Lab Visit', 'University Visit', 'Lab Trial'],
            'DEFAULT': ['External Lab Visit', 'University Visit', 'Lab Trial']
        },
        'Seminar/ Conferences': {
            'TEXTILE': ['Conferences'],
            'AHN': ['Conferences', 'Technical Seminar'],
            'SYNTHETIC': ['Conferences'],
            'DEFAULT': ['Conferences']
        }
    };


    filterNatureOptions() {
        console.log('➡️ filterNatureOptions called');
        console.log('visitCategory:', this.visitCategory);
        console.log('User Type:', this.userType, 'Division:', this.userDivisionCode);

        // Reset if no category selected
        if (!this.visitCategory) {
            this.natureOptions = [];
            console.warn('No category selected, resetting natureOptions');
            return;
        }

        // Wait for user data to load
        if (this.userType === undefined || this.userDivisionCode === undefined) {
            console.log('Waiting for user data to load...');
            return;
        }

        const mapping = this.visitNatureMapping[this.visitCategory];
        if (!mapping) {
            this.natureOptions = [];
            console.warn('No mapping found for category:', this.visitCategory);
            return;
        }

        let values = [];

        // Determine the mapping key based on User_Type__c
        let mappingKey = this.determineMappingKey();
        console.log('Determined mapping key:', mappingKey);

        values = mapping[mappingKey] || mapping['DEFAULT'] || [];

        // Convert to options format
        this.natureOptions = values.map(v => ({ label: v, value: v }));
        console.log('Available natureOptions:', JSON.stringify(this.natureOptions));
    }


    // ✅ UPDATED METHOD: Include APPLICATION user type with same options as SYNTHETIC
    determineMappingKey() {
        if (!this.userType) {
            return 'DEFAULT';
        }

        // Convert user type to uppercase for consistent matching
        const userTypeUpper = this.userType.toUpperCase();

        // Map user types to keys
        if (userTypeUpper === 'TEXTILE') {
            return 'TEXTILE';
        } else if (userTypeUpper === 'AHN') {
            return 'AHN';
        } else if (userTypeUpper === 'SYNTHETIC' || userTypeUpper === 'APPLICATION') {
            return 'SYNTHETIC'; // Both SYNTHETIC and APPLICATION use the same options
        }

        // Default case for other user types
        return 'DEFAULT';
    }


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
        this.location = event.detail.address;
        this.location += ' ' + fieldlocation.split('-')[1]?.trim();

        this.dataMap[fieldName] = fieldValue;
        console.log('OUTPUT : fieldName', fieldlocation, fieldValue);
        if (fieldName == 'lead_Name') {
            if (fieldValue == '') {
                this.continentName = '';
            }
        }
    }


    handleLeadSelectedForBillTo(event) {
        const fieldName = event.target.dataset.label;
        const fieldValue = event.detail.recordId;
        const fieldlocation = event.detail.recordName;
        this.location = event.detail.address;
        this.location += ' ' + fieldlocation.split('-')[1]?.trim();

        this.dataMap[fieldName] = fieldValue;
        console.log('OUTPUT : fieldName', fieldlocation, fieldValue);
        if (fieldName == 'lead_Name') {
            if (fieldValue == '') {
                this.continentName = '';
            }
        }

    }

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

    // handleTourEndChange(event) {
    //     this.newTourEnd = event.target.value;
    // }

    handleTourEndChange(event) {
        const selectedEndDate = event.target.value;

        if (this.newTourStart && selectedEndDate < this.newTourStart) {
            // Show error message
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Invalid Date',
                    message: 'Tour end date cannot be before the start date.',
                    variant: 'error',
                    mode: 'dismissable'
                })
            );

            // Clear the invalid date
            this.newTourEnd = '';
            event.target.value = '';
        } else {
            this.newTourEnd = selectedEndDate;
        }
    }

    closeModal() {
        this.isModalOpen = false;
        this.newTourName = '';
    }

    handleAccountSelection(event) {
        this.selectedTourAccounts = event.detail.selectedRecords;
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
                endDate: this.newTourEnd,
                accountIds: this.selectedTourAccounts.map(acc => acc.Id)
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

    handleCustomerTypeChange(event) {
        const customerType = event.detail.value;
        this.dataMap.Customer_Type = customerType;

        // Show/hide fields based on customer type
        if (customerType === 'Existing') {
            this.showExistingCustomerFields = true;
            this.showNewCustomerField = false;
            // Clear new customer field when switching to existing
            this.dataMap.New_Customer = '';
            this.dataMap.Location = '';
        } else if (customerType === 'New') {
            this.showExistingCustomerFields = false;
            this.showNewCustomerField = true;
            // Clear existing customer fields when switching to new
            this.dataMap.Customer_Name = '';
            this.dataMap.Customer_Name_Display = '';
            this.sapCustomerCode = '';
            this.recordTypeName = '';
            this.customerId = '';
        } else {
            // If no selection, hide both
            this.showExistingCustomerFields = false;
            this.showNewCustomerField = false;
        }

        console.log('Customer Type changed to:', customerType);
    }

    // handles other fields (record-edit-form, inputs, etc.)
    handleVisitChange(event) {
        const fieldName = event.target.dataset.label;
        const fieldValue = event.detail.value;

        console.log('➡️ handleVisitChange called');
        console.log('Field:', fieldName, 'Value:', fieldValue);

        // Handle Customer_Type separately
        if (fieldName === 'Customer_Type') {
            this.handleCustomerTypeChange(event);
            return;
        }

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

                this.dataMap['End_Date_Time'] = endDate.toISOString();

                console.log('Auto-set End_Date_Time:', this.dataMap['End_Date_Time']);

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
            if (fieldValue === 'Export') {
                this.isTourDisabled = false;
            } else {
                this.isTourDisabled = true;
                this.selectedTourId = null;
                delete this.dataMap['tourId'];
            }
            console.log('isTourDisabled:', this.isTourDisabled);
        }

        // Customer Handling
        if (fieldName === 'Customer_Name') {
            if (!fieldValue) {
                this.sapCustomerCode = '';
                this.recordTypeName = '';
            } else {
                getCustomerDetails({ accountId: fieldValue })
                    .then(result => {
                        if (result) {
                            this.sapCustomerCode = result.SAP_Customer_Code__c;
                            this.recordTypeName = result.RecordType;
                            console.log('Fetched Customer Details:', result);
                        }
                    })
                    .catch(error => {
                        console.error('Error fetching customer details:', error);
                    });
            }
        }

        // Handle Category change
        if (fieldName === 'Category') {
            this.visitCategory = fieldValue;
            console.log('Selected Category:', this.visitCategory);

            // Filter nature options based on new category
            this.filterNatureOptions();

            // Clear Nature when Category changes
            this.dataMap.Nature = '';
        }

        // ✅ When Nature changes → store properly
        if (fieldName === 'Nature') {
            this.dataMap.Nature = fieldValue;
            console.log('Selected Nature:', this.dataMap.Nature);
        }

        console.log('Current dataMap:', JSON.stringify(this.dataMap));
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
        return this.visitCategory === 'R&D related Visit';
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
            "Mobile_No__c": "",
            "Designation__c": "",
        };
        this.Attendees.push(temCon2);
    }


    handleAttendeeChange(event) {
        const recordIndex = parseInt(event.target.dataset.index, 10);
        const field = event.target.dataset.label;
        let value = event.detail.value;

        // For lookup fields, extract the ID if it's an array
        if (field === 'User__c' && Array.isArray(value) && value.length > 0) {
            value = value[0];
        }

        let updated = [...this.Attendees];
        const idx = updated.findIndex(a => a.index === recordIndex);

        if (idx !== -1) {
            // Check if user is trying to add themselves as an attendee
            if (field === 'User__c' && value === this.currentUserId) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Invalid Selection',
                        message: 'You cannot add yourself as an attendee.',
                        variant: 'error',
                        mode: 'dismissable'
                    })
                );

                // Clear the selection
                updated[idx][field] = '';
                this.Attendees = updated;

                // Reset the lookup field
                setTimeout(() => {
                    const lookupField = this.template.querySelector(`[data-index="${recordIndex}"][data-label="User__c"]`);
                    if (lookupField) {
                        lookupField.value = '';
                        // Dispatch change event to ensure the field is properly reset
                        lookupField.dispatchEvent(new CustomEvent('change', {
                            detail: { value: '' }
                        }));
                    }
                }, 100);

                return;
            }

            updated[idx][field] = value;

            // Compute flags for conditional rendering
            const type = updated[idx].Attendee_Type__c;
            const userType = updated[idx].User_Type__c;

            updated[idx].isInternalNew = type === 'Internal Attendee' && userType === 'New';
            updated[idx].isInternalExisting = type === 'Internal Attendee' && userType === 'Existing';
            updated[idx].isExternalNew = type === 'External Attendee' && userType === 'New';
            updated[idx].isExternalExisting = type === 'External Attendee' && userType === 'Existing';

            // Handle contact lookup for external attendees
            if (field === 'Contact_Name__c' && value && type === 'External Attendee' && userType === 'Existing') {
                // You might want to fetch contact details here if needed
                console.log('Contact selected:', value);
            }

            // Handle user lookup for internal attendees
            if (field === 'User__c' && value && type === 'Internal Attendee' && userType === 'Existing') {
                console.log('User selected:', value);
            }

            // Reset fields when attendee type changes
            if (field === 'Attendee_Type__c' || field === 'User_Type__c') {
                if (field === 'Attendee_Type__c') {
                    // Reset all fields when attendee type changes
                    updated[idx].User__c = '';
                    updated[idx].Contact_Name__c = '';
                    updated[idx].First_Name__c = '';
                    updated[idx].Last_Name__c = '';
                    updated[idx].Email__c = '';
                    updated[idx].Designation__c = '';
                }

                // Recompute flags after reset
                const newType = updated[idx].Attendee_Type__c;
                const newUserType = updated[idx].User_Type__c;

                updated[idx].isInternalNew = newType === 'Internal Attendee' && newUserType === 'New';
                updated[idx].isInternalExisting = newType === 'Internal Attendee' && newUserType === 'Existing';
                updated[idx].isExternalNew = newType === 'External Attendee' && newUserType === 'New';
                updated[idx].isExternalExisting = newType === 'External Attendee' && newUserType === 'Existing';
            }
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

    get isNewVisitReport() {
        return this.selectedVisitReportType === 'New' && !this.selectedExistingVisitReportId;
    }

    // Add this getter for Unplanned logic
    get isUnplannedVisitReport() {
        return this.selectedVisitReportType === 'Unplanned';
    }

    // Handle Visit Report Type Change
    handleVisitReportTypeChange(event) {
        const previousType = this.selectedVisitReportType;
        this.selectedVisitReportType = event.detail.value;

        // Disable Existing Visit Report lookup if type = New
        this.disableExistingVisitReport = (this.selectedVisitReportType !== 'Existing');
        this.showRemainingSections = (this.selectedVisitReportType === 'Existing' || this.selectedVisitReportType === 'Unplanned');

        // ✅ FIX: Reload page when switching FROM Existing or Unplanned TO any other type
        if ((previousType === 'Existing' || previousType === 'Unplanned') &&
            (this.selectedVisitReportType === 'New' || this.selectedVisitReportType === 'Unplanned')) {
            console.log('Reloading page due to type change from', previousType, 'to', this.selectedVisitReportType);
            window.location.reload();
            return;
        }

        if (this.selectedVisitReportType === 'Existing') {
            // Clear form when switching to existing
            this.clearForm();
            this.isFormDisabled = true; // Disable basic fields initially
        } else if (this.selectedVisitReportType === 'Unplanned') {
            // For Unplanned, clear form but keep fields enabled
            this.clearForm();
            this.isFormDisabled = false;
            this.selectedExistingVisitReportId = null;

            // Clear any existing visit report selection
            const lookupCmp = this.template.querySelector('c-visit-report-lookup');
            if (lookupCmp) {
                lookupCmp.clearSelection();
            }

        } else {
            // 👉 If switching back from Existing → New, reload the page
            if (previousType === 'Existing' || previousType === 'Unplanned') {
                window.location.reload();
                return; // stop here, reload takes over
            }

            // Otherwise (first load or already New → New), just clear
            this.clearForm();
            this.isFormDisabled = false;
            this.selectedExistingVisitReportId = null;
            this.showRemainingSections = false;

            const lookupCmp = this.template.querySelector('c-visit-report-lookup');
            if (lookupCmp) {
                lookupCmp.clearSelection();
            }
        }
    }



    // Handle Existing Visit Report Selection
    async handleExistingVisitReportChange(event) {
        this.selectedExistingVisitReportId = event.detail.recordId;
        this.selectedExistingVisitReportName = event.detail.recordName;

        if (this.selectedExistingVisitReportId) {
            await this.loadExistingVisitReportData();
            await this.loadExistingFiles(); // Load existing files
            this.isFormDisabled = false;
            this.showRemainingSections = true;
        }
    }

    async loadExistingFiles() {
        try {
            const files = await getExistingFiles({ recordId: this.selectedExistingVisitReportId });

            this.uploadedFiles = files.map(file => ({
                documentId: file.ContentDocumentId,
                name: file.ContentDocument.Title + '.' + file.ContentDocument.FileExtension,
                contentVersionId: file.Id
            }));

            this.uploadedFileIds = files.map(file => file.ContentDocumentId);
            this.uploadedFileIds2 = files.map(file => file.ContentDocumentId + ' - dummy');

            console.log('Loaded existing files:', this.uploadedFiles);
        } catch (error) {
            console.error('Error loading existing files:', error);
        }
    }

    // Add this method to load attendees
    async loadAttendees(visitReportId) {
        try {
            // You'll need to create an Apex method to get attendees
            const attendees = await getVisitReportAttendees({ visitReportId });

            this.Attendees = attendees.map(att => ({
                index: this.generateUniqueCode(),
                Attendee_Type__c: att.Attendee_Type__c,
                User_Type__c: att.User_Type__c,
                User__c: att.User__c,
                Contact_Name__c: att.Contact_Name__c,
                First_Name__c: att.First_Name__c,
                Last_Name__c: att.Last_Name__c,
                Email__c: att.Email__c,
                Mobile_No__c: att.Mobile_No__c,
                Designation__c: att.Designation__c,
                isInternalNew: att.Attendee_Type__c === 'Internal Attendee' && att.User_Type__c === 'New',
                isInternalExisting: att.Attendee_Type__c === 'Internal Attendee' && att.User_Type__c === 'Existing',
                isExternalNew: att.Attendee_Type__c === 'External Attendee' && att.User_Type__c === 'New',
                isExternalExisting: att.Attendee_Type__c === 'External Attendee' && att.User_Type__c === 'Existing'
            }));
        } catch (error) {
            console.error('Error loading attendees:', error);
        }
    }

    // Add this method to load existing visit report data
    async loadExistingVisitReportData() {
        try {
            this.showSpinner = true;

            // Query the existing visit report
            const visitReport = await getVisitReportDetails({
                visitReportId: this.selectedExistingVisitReportId
            });
            console.log('Visit Report:', visitReport);

            // 👇 ensure accountContacts are loaded first
            if (visitReport.Customer_Name__c) {
                const contactList = await getContactsByAccount({ accId: visitReport.Customer_Name__c });
                this.accountContacts = contactList.map(c => ({
                    label: c.Name,
                    value: c.Id
                }));
            }

            // Populate the basic fields with existing data
            this.populateBasicFields(visitReport);

            // Load attendees
            await this.loadAttendees(this.selectedExistingVisitReportId);

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Visit Report data loaded successfully. Please complete the remaining sections.',
                    variant: 'success'
                })
            );
        } catch (error) {
            console.error('Error loading visit report:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Failed to load Visit Report data',
                    variant: 'error'
                })
            );
        } finally {
            this.showSpinner = false;
        }
    }

    formatLocalDateTime(dateString) {
        if (!dateString) return '';
        const dt = new Date(dateString);

        // Format into yyyy-MM-ddThh:mm (local time, not UTC)
        const year = dt.getFullYear();
        const month = String(dt.getMonth() + 1).padStart(2, '0');
        const day = String(dt.getDate()).padStart(2, '0');
        const hours = String(dt.getHours()).padStart(2, '0');
        const minutes = String(dt.getMinutes()).padStart(2, '0');

        return `${year}-${month}-${day}T${hours}:${minutes}`;
    }


    // Populate Basic Fields
    populateBasicFields(visitReport) {
        // Convert DateTime fields to ISO string format for input fields
        const startDateTime = this.formatLocalDateTime(visitReport.Start_Date_Time__c);
        const endDateTime = this.formatLocalDateTime(visitReport.End_Date_Time__c);

        this.dataMap = {
            Mode: visitReport.Type_of_Visit__c || '',
            Title_of_Meeting: visitReport.Title_of_Meeting__c || '',
            Start_Date_Time: startDateTime,
            End_Date_Time: endDateTime,
            Category: visitReport.Visit_Category__c || '',
            Nature: visitReport.Nature_of_Visit__c || '',

            Customer_Type: visitReport.Customer_Type__c || '',
            New_Customer: visitReport.New_Customer_Name__c || '',
            Location: visitReport.Location__c || '',
            //  New_Customer: visitReport.New_Customer__c || '',
            // For lookups store both Id + Name
            Customer_Name: visitReport.Customer_Name__c || '',
            Customer_Name_Display: visitReport.Customer_Name__r ? visitReport.Customer_Name__r.Name : '',

            Competition_Name: visitReport.Competition_Name__c || '',
            Competition_Name_Display: visitReport.Competition_Name__r ? visitReport.Competition_Name__r.Name : '',

            tourId: visitReport.Name_of_the_Tour__c || '',
            ProjectId: visitReport.Name_of_the_Project__c || '',

            Reason: visitReport.Reason__c || '',
            Seminar: visitReport.Name_of_the_Conference_Seminar__c || '',
            Discussion_Details_from_the_Meeting: visitReport.Discussion_Details_from_the_Meeting__c || '',
            Next_Meeting_Date_agreed_with_Customer: visitReport.Next_Meeting_Date_agreed_with_Customer__c || ''
        };

        // Set other properties for UI display
        this.visitCategory = visitReport.Visit_Category__c;
        this.customerId = visitReport.Customer_Name__c;
        console.log('Visit Category:', this.visitCategory);
        console.log('Customer ID:', this.customerId);

        this.competitorId = visitReport.Competition_Name__c;
        this.selectedTourId = visitReport.Name_of_the_Tour__c;
        this.ProjectId = visitReport.Name_of_the_Project__c;

        // ✅ Handle Customer Type UI visibility
        if (visitReport.Customer_Type__c) {
            this.dataMap.Customer_Type = visitReport.Customer_Type__c;

            // ✅ FIXED: Properly show/hide fields based on customer type
            if (visitReport.Customer_Type__c === 'Existing') {
                this.showExistingCustomerFields = true;
                this.showNewCustomerField = false;
            } else if (visitReport.Customer_Type__c === 'New') {
                this.showExistingCustomerFields = false;
                this.showNewCustomerField = true;
            } else {
                this.showExistingCustomerFields = false;
                this.showNewCustomerField = false;
            }

            console.log('Customer Type loaded:', visitReport.Customer_Type__c);
            console.log('showNewCustomerField:', this.showNewCustomerField);
            console.log('showExistingCustomerFields:', this.showExistingCustomerFields);
        }

        // ✅ FIX: Wait for user data to be available before filtering nature options
        this.waitForUserDataAndFilterNature(visitReport.Nature_of_Visit__c);

        // Update customer details if customer exists
        if (visitReport.Customer_Name__c) {
            this.sapCustomerCode = visitReport.Customer_Name__r?.SAP_Customer_Code__c || '';
        }

        // Update competitor code if competitor exists
        if (visitReport.Competition_Name__c && visitReport.Competition_Name__r) {
            this.competitorCode = visitReport.Competition_Name__r.Competitor_Code__c || '';
        }

        // Update UI fields manually since they might not react to dataMap changes
        this.updateUIFields();
    }

    // Add this method to update UI fields
    updateUIFields() {
        // Use setTimeout to ensure DOM is rendered
        setTimeout(() => {
            // Update all input fields based on dataMap
            Object.keys(this.dataMap).forEach(fieldName => {
                const fieldElement = this.template.querySelector(`[data-label="${fieldName}"]`);
                if (fieldElement && this.dataMap[fieldName]) {
                    fieldElement.value = this.dataMap[fieldName];
                }
            });
        }, 100);
    }



    // ✅ UPDATED: Wait for user data to load before filtering nature options
    waitForUserDataAndFilterNature(existingNatureValue) {
        const maxWaitTime = 5000; // 5 seconds max
        const interval = 100; // Check every 100ms
        let elapsed = 0;

        const waitForData = setInterval(() => {
            // Check if user data is loaded (user type and division code are available)
            if (this.userType !== undefined && this.userDivisionCode !== undefined) {
                clearInterval(waitForData);
                console.log('User data loaded, filtering nature options...');

                // Now filter nature options
                this.filterNatureOptions();

                // Set the existing nature value after options are populated
                if (existingNatureValue) {
                    // Use setTimeout to ensure the combobox is rendered with options
                    setTimeout(() => {
                        this.dataMap.Nature = existingNatureValue;
                        console.log('Set existing Nature value:', existingNatureValue);
                    }, 100);
                }
            } else if (elapsed >= maxWaitTime) {
                clearInterval(waitForData);
                console.warn('Timeout waiting for user data, using default nature options');
                // Fallback: set default nature options
                this.setDefaultNatureOptions(existingNatureValue);
            }
            elapsed += interval;
        }, interval);
    }



    setDefaultNatureOptions(existingNatureValue) {
        const mapping = this.visitNatureMapping[this.visitCategory];
        if (mapping && mapping['DEFAULT']) {
            this.natureOptions = mapping['DEFAULT'].map(v => ({ label: v, value: v }));
            if (existingNatureValue) {
                this.dataMap.Nature = existingNatureValue;
            }
        } else {
            this.natureOptions = [];
        }
    }

    // Add this method to clear the form
    clearForm() {
        this.dataMap = {
            Mode: '',
            Title_of_Meeting: '',
            Start_Date_Time: '',
            End_Date_Time: '',
            Category: '',
            Nature: '',
            Customer_Type: '',
            New_Customer: '',
            Location: '',
            //  New_Customer: '',
            Customer_Name: '',
            Competition_Name: '',
            tourId: '',
            ProjectId: '',
            Reason: '',
            Seminar: '',
            Discussion_Details_from_the_Meeting: '',
            Next_Meeting_Date_agreed_with_Customer: '',
        };
        this.Attendees = [{
            index: this.generateUniqueCode(),
            Attendee_Type__c: '',
            User_Type__c: '',
            User__c: '',
            Contact_Name__c: '',
            First_Name__c: '',
            Last_Name__c: '',
            Email__c: '',
            Mobile_No__c: '',
            Designation__c: '',
            isInternalNew: false,
            isInternalExisting: false,
            isExternalNew: false,
            isExternalExisting: false
        }];

        // Clear files
        this.uploadedFiles = [];
        this.uploadedFileIds = [];
        this.uploadedFileIds2 = [];
        this.isFilePreviewModalOpen = false;

        // Clear other properties
        this.showExistingCustomerFields = false;
        this.showNewCustomerField = false;
        this.customerId = '';
        this.competitorId = '';
        this.selectedTourId = '';
        this.ProjectId = '';
        this.sapCustomerCode = '';
        this.recordTypeName = '';
        this.competitorCode = '';
        this.visitCategory = '';
        this.accountContacts = [];
        this.selectedExistingVisitReportId = null;
        this.selectedExistingVisitReportName = '';
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

    async handleSave() {
        if (!this.validateVisitReport()) {
            return;
        }

        this.showSpinner = true;

        try {
            let validFiles = [];
            for (let fileId of this.uploadedFileIds2) {
                if (!fileId.includes('dummy')) {
                    validFiles.push(fileId);
                }
            }
            const saveData = {
                visit: JSON.stringify(this.dataMap),
                Attendees: JSON.stringify(this.Attendees),
                ProductInterestPoint: JSON.stringify(this.ProductInterestPoint),
                ActionPoint: JSON.stringify(this.ActionPoint),
                location: this.location,
                currencyCode: this.currencyCode,
                visitType: this.selectedVisitReportType,
                existingVisitReportId: this.selectedExistingVisitReportId,
                fileIds: JSON.stringify(validFiles) // Pass file IDs
            };

            console.log('Saving data:', saveData);

            const result = await saveVisitReport(saveData);

            if (result.Message === 'Success') {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success!',
                        message: 'Record has been saved successfully.',
                        variant: 'success',
                        mode: 'dismissable'
                    })
                );

                window.open('/' + result.Id, '_blank');

                setTimeout(() => {
                    window.location.reload();
                }, 2000);

            } else {
                throw new Error(result.Message || 'Unknown error occurred');
            }
        } catch (error) {
            console.error('Error saving visit report:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error!',
                    message: 'Failed to save record: ' + error.message,
                    variant: 'error',
                    mode: 'dismissable'
                })
            );
        } finally {
            this.showSpinner = false;
        }
    }
}