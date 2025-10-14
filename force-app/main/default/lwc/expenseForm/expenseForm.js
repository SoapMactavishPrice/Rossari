import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import initializeExpense from '@salesforce/apex/ExpenseController.initializeExpense';
import getUsers from '@salesforce/apex/ExpenseController.getUsers';
import getTypeOfExpense from '@salesforce/apex/ExpenseController.getTypeOfExpense';
import createExpenseWithFiles from '@salesforce/apex/ExpenseController.createExpenseWithFiles';
import getTransportModes from '@salesforce/apex/ExpenseController.getTransportModes';
import createCustomerVisit from '@salesforce/apex/ExpenseController.createCustomerVisit';
import searchTours from '@salesforce/apex/TourLookupController.searchTours';
import getSalesTypeOptions from '@salesforce/apex/ExpenseController.getSalesTypeOptions';
import getDailyAllowanceByGrade from '@salesforce/apex/ExpenseController.getDailyAllowanceByGrade';
import getGradeDetails from '@salesforce/apex/ExpenseController.getGradeDetails';
import { loadStyle } from 'lightning/platformResourceLoader';
import LightningFileUploadHideLabelCss from '@salesforce/resourceUrl/LightningFileUploadHideLabelCss';


export default class ExpenseForm extends NavigationMixin(LightningElement) {
    @track expenseName = '';
    @track todayDate = '';
    @track selectedEmployeeId = '';
    @track division = '';
    @track zone = '';
    @track selectedVoucherType = '';
    @track userCostCenter = '';
    @track costCenterId = '';
    @track salesType = '';
    @track salesTypeOptions = [];
    @track dailyAllowance = 0; // Add daily allowance property
    @track userGrade = ''; // Add user grade property
    @track userGradeName = ''; // Add grade name for display
    @track fourWheelerPerKm = 0;
    @track twoWheelerPerKm = 0;
    @track canEditDailyAllowance = false;

    @track employeeOptions = [];
    @track typeOfExpenseOptions = [];
    @track voucherOptions = [];
    @track allTransportModeOptions = [];
    @track gradeTransportModeOptions = [];
    @track publicTransportModes = [];
    @track privateTransportModes = [];
    @track lineItems = [];
    @track filesMap = new Map(); // Store files by line item index
    @track isPublicExpenseForHeader = false;
    @track selectedTourId = ''; // Add this
    @track selectedTourName = ''; // Add this
    @track selectedCustomerVisitId = ''; // Add this to class properties
    @track selectedAccountId = '';
    @track selectedAccountName = '';
    @track selectedAccounts = []; // Track multiple selected accounts   
    @track visitReportId = '';
    @track visitReportName = '';
    @track selectedCurrency = 'INR';
    @track currencyOptions = [
        { label: 'Indian Rupee (INR)', value: 'INR' },
        { label: 'US Dollar (USD)', value: 'USD' },
        { label: 'Euro (EUR)', value: 'EUR' },
        { label: 'UAE (AED)', value: 'AED' },
        { label: 'Saudi Arabian Riyal (SAR)', value: 'SAR' }
        // Add more currencies as needed
    ];

    acceptedFormats = ['.pdf', '.jpg', '.jpeg', '.png', '.doc', '.docx'];
    nextKey = 0;
    isLoading = false;

    get isNotLoading() {
        return !this.isLoading;
    }

    // Computed property to show/hide reason column
    get showReasonColumn() {
        return this.selectedVoucherType === 'Misc';
    }

    get showDailyAllowanceColumn() {
        return this.selectedVoucherType === 'Local' || this.selectedVoucherType === 'Outstation';
    }

    // Get the label for Daily Allowance column
    get dailyAllowanceColumnLabel() {
        return this.selectedVoucherType === 'Outstation' ? 'Out of Pocket' : 'Daily Allowance';
    }

    get showTotalColumn() {
        return this.selectedVoucherType === 'Local' || this.selectedVoucherType === 'Outstation';
    }

    // Computed property to show/hide local fields
    get showLocalFields() {
        return this.selectedVoucherType === 'Local';
    }

    // Computed property to show/hide KM fields
    get showKMFields() {
        return this.selectedVoucherType === 'Local';
    }

    // Computed property to show/hide Toll/Parking field
    get showTollParkingField() {
        return this.selectedVoucherType === 'Local';
    }

    get showTourLookup() {
        return this.selectedVoucherType === 'Outstation';
    }

    get showOutstationFields() {
        return this.selectedVoucherType === 'Outstation';
    }

    get showCashFields() {
        return this.selectedVoucherType === 'Cash';
    }

    get reactiveCurrency() {
        return this.selectedCurrency;
    }

    get currencySymbol() {
        const map = {
            'INR': '₹',
            'USD': '$',
            'EUR': '€',
            'AED': 'د.إ',
            'SAR': '﷼'
        };
        return map[this.selectedCurrency] || this.selectedCurrency;
    }

    forceCurrencyUpdate() {
        // Create a deep copy to force re-render
        this.lineItems = this.lineItems.map(item => ({ ...item }));
    }

    // Add currency change handler
    handleCurrencyChange(event) {
        this.selectedCurrency = event.detail.value;
        //this.forceCurrencyUpdate();
    }

    handleVisitReportSelected(event) {
        this.visitReportId = event.detail.recordId;
        this.visitReportName = event.detail.recordName;
        console.log('Visit Report selected:', this.visitReportId, this.visitReportName);
    }

    connectedCallback() {
        this.todayDate = new Date().toISOString().split('T')[0];
        this.initializeData();
        this.addLineItem();
        this.loadSalesTypeOptions();

        // loadStyle(this, LightningFileUploadHideLabelCss);
    }

    loadSalesTypeOptions() {
        // You'll need to create an Apex method to get these picklist values
        getSalesTypeOptions()
            .then(result => {
                this.salesTypeOptions = result;
            })
            .catch(error => {
                console.error('Error loading sales type options:', error);
            });
    }

    // Add handler for sales type change
    handleSalesTypeChange(event) {
        this.salesType = event.detail.value;
    }

    async initializeData() {
        try {
            this.isLoading = true;
            const result = await initializeExpense();

            console.log('Initialization result:', result);

            if (result.currentUser) {
                const user = result.currentUser;
                this.selectedEmployeeId = user.Id;
                this.division = user.Division || '';
                this.zone = user.Zone__c || '';
                this.userCostCenter = user.Cost_Center__c || '';
                this.userGrade = user.Grades__c || '';
                this.userGradeName = user.Grades__c || '';
                this.dailyAllowance = result.dailyAllowance || 0;
                this.fourWheelerPerKm = result.fourWheelerPerKm || 0;
                this.twoWheelerPerKm = result.twoWheelerPerKm || 0;
                this.canEditDailyAllowance = result.canEditDailyAllowance || false;

                console.log('User Grade:', this.userGrade);
                console.log('Daily Allowance:', this.dailyAllowance);
                console.log('Four Wheeler Rate:', this.fourWheelerPerKm);
                console.log('Two Wheeler Rate:', this.twoWheelerPerKm);
                console.log('Can Edit DA:', this.canEditDailyAllowance);

                // Convert mode of travel options to combobox format
                if (result.modeOfTravelOptions && result.modeOfTravelOptions.length > 0) {
                    this.gradeTransportModeOptions = result.modeOfTravelOptions.map(mode => ({
                        label: mode,
                        value: mode
                    }));
                    console.log('Grade Transport Modes:', this.gradeTransportModeOptions);
                } else {
                    console.log('No transport modes found in grade');
                }
            }

            this.costCenterId = result.costCenterId || '';
            this.voucherOptions = result.voucherOptions || [];

            // Load transport modes
            this.allTransportModeOptions = await getTransportModes();
            this.publicTransportModes = this.allTransportModeOptions.filter(mode => mode.value === 'Bus');
            this.privateTransportModes = this.allTransportModeOptions.filter(mode => mode.value === 'Car' || mode.value === 'Bike');

            this.employeeOptions = await getUsers({ searchTerm: '' });
            this.typeOfExpenseOptions = await getTypeOfExpense({
                searchTerm: '',
                voucherType: null
            });

            // Update line items with grade data
            this.lineItems = this.lineItems.map(item => ({
                ...item,
                dailyAllowance: this.dailyAllowance,
                disableDailyAllowance: !this.canEditDailyAllowance,
                transportOptions: this.gradeTransportModeOptions.length > 0 ? 
                                this.gradeTransportModeOptions : this.allTransportModeOptions
            }));

        } catch (error) {
            console.error('Initialization error:', error);
            this.showToast('Error', error?.body?.message || error.message || 'Initialization failed', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // Get transport options based on expense type name
    getTransportOptionsForItem(typeOfExpenseId, voucherType = this.selectedVoucherType) {
        // Always use grade-specific transport modes if available
        const availableModes = this.gradeTransportModeOptions.length > 0 ? 
                            this.gradeTransportModeOptions : this.allTransportModeOptions;

        console.log('Available transport modes:', availableModes);
        console.log('Voucher type:', voucherType);
        console.log('Expense type ID:', typeOfExpenseId);

        // For Outstation and Local voucher types, filter by grade-specific modes
        if (voucherType === 'Outstation' || voucherType === 'Local') {
            // If grade has specific modes, use only those
            if (this.gradeTransportModeOptions.length > 0) {
                return this.gradeTransportModeOptions;
            }
            // Otherwise, return all modes
            return this.allTransportModeOptions;
        }

        // For other voucher types, apply expense type filtering
        if (!typeOfExpenseId) return availableModes;

        const expenseType = this.typeOfExpenseOptions.find(opt => opt.value === typeOfExpenseId);
        if (!expenseType) return availableModes;

        // Filter based on expense type name
        if (expenseType.name === 'Public') {
            return availableModes.filter(mode => mode.value === 'Bus');
        } else if (expenseType.name === 'Private') {
            return availableModes.filter(mode => mode.value === 'Car' || mode.value === 'Bike');
        }
        
        return availableModes;
    }

    // Check if expense type is private
    isPrivateExpense(typeOfExpenseId) {
        if (!typeOfExpenseId) return false;
        const expenseType = this.typeOfExpenseOptions.find(opt => opt.value === typeOfExpenseId);
        return expenseType && expenseType.name === 'Private';
    }

    // Check if expense type is public
    isPublicExpense(typeOfExpenseId) {
        if (!typeOfExpenseId) return false;
        const expenseType = this.typeOfExpenseOptions.find(opt => opt.value === typeOfExpenseId);
        return expenseType && expenseType.name === 'Public';
    }

    // Check if transport mode shows toll/parking field
    shouldShowTollParking(transportMode) {
        return transportMode === 'Car' || transportMode === 'Bike';
    }

    async handleEmployeeChange(event) {
        const empId = event.detail.value;
        this.selectedEmployeeId = empId;
        const emp = this.employeeOptions.find(e => e.value === empId);
        
        if (emp) {
            this.division = emp.division;
            this.zone = emp.zone;
            this.userGradeName = emp.grade || '';
            
            console.log('Selected employee grade:', emp.grade);
            
            if (emp.grade) {
                try {
                    const gradeDetails = await getGradeDetails({ gradeName: emp.grade });
                    
                    console.log('Grade details received:', gradeDetails);
                    
                    this.dailyAllowance = gradeDetails.dailyAllowance || 0;
                    this.fourWheelerPerKm = gradeDetails.fourWheelerPerKm || 0;
                    this.twoWheelerPerKm = gradeDetails.twoWheelerPerKm || 0;
                    this.canEditDailyAllowance = gradeDetails.canEditDailyAllowance || false;
                    
                    // Update transport modes from grade
                    if (gradeDetails.modeOfTravelOptions && gradeDetails.modeOfTravelOptions.length > 0) {
                        this.gradeTransportModeOptions = gradeDetails.modeOfTravelOptions.map(mode => ({
                            label: mode,
                            value: mode
                        }));
                        console.log('Updated grade transport modes:', this.gradeTransportModeOptions);
                    } else {
                        this.gradeTransportModeOptions = [];
                        console.log('No transport modes found in grade');
                    }
                    
                    // Update all line items with new transport options
                    this.lineItems = this.lineItems.map(item => ({
                        ...item,
                        dailyAllowance: this.dailyAllowance,
                        disableDailyAllowance: !this.canEditDailyAllowance,
                        transportOptions: this.getTransportOptionsForItem(item.typeOfExpenseId),
                        // Auto-update KM rate if transport mode is set
                        kmRate: this.getUpdatedKMRateForItem(item)
                    }));
                    
                    console.log('Updated line items with new grade data');
                    
                } catch (error) {
                    console.error('Error fetching grade details:', error);
                    this.dailyAllowance = 0;
                    this.canEditDailyAllowance = false;
                    this.gradeTransportModeOptions = [];
                }
            } else {
                console.log('No grade found for selected employee');
                this.dailyAllowance = 0;
                this.canEditDailyAllowance = false;
                this.gradeTransportModeOptions = [];
            }
        }
    }

    // Helper method to update KM rate when grade changes
    getUpdatedKMRateForItem(item) {
        const transportMode = item.transportMode || item.outstationTransportMode;
        if (transportMode === 'Car') {
            return this.fourWheelerPerKm;
        } else if (transportMode === 'Bike') {
            return this.twoWheelerPerKm;
        }
        return item.kmRate || 0;
    }

    // Add this getter to dynamically determine header text based on transport mode
    get kmRateHeaderText() {
        if (this.lineItems.length === 0) return 'KM Rate/ Fare';

        // Check if any line item has Bus as transport mode
        const hasBusTransport = this.lineItems.some(item =>
            item.transportMode === 'Bus'
        );

        return hasBusTransport ? 'Fare' : 'KM Rate';
    }

    // Add this method to check if expense type contains 'Food'
    isFoodExpense(typeOfExpenseId) {
        if (!typeOfExpenseId) return false;
        const expenseType = this.typeOfExpenseOptions.find(opt => opt.value === typeOfExpenseId);
        return expenseType && expenseType.label && expenseType.label.toLowerCase().includes('food');
    }

    handleTypeOfExpenseChange(event) {
        const idx = parseInt(event.currentTarget.dataset.index, 10);
        const value = event.detail.value;

        const expenseType = this.typeOfExpenseOptions.find(opt => opt.value === value);
        const isPrivate = expenseType && expenseType.name === 'Private';
        const isPublic = expenseType && expenseType.name === 'Public';
        const isFood = this.isFoodExpense(value);

        // Update line item
        this.updateLineItem(idx, 'typeOfExpenseId', value);
        this.updateLineItem(idx, 'isPrivate', isPrivate);
        this.updateLineItem(idx, 'isPublic', isPublic);
        this.updateLineItem(idx, 'isFood', isFood);
        
        // Pass voucher type to get proper transport options
        this.updateLineItem(idx, 'transportOptions', this.getTransportOptionsForItem(value, this.selectedVoucherType));

        // Store GL Code information for the selected expense type
        if (expenseType) {
            this.updateLineItem(idx, 'glCodeId', expenseType.glCodeId || '');
            this.updateLineItem(idx, 'glCodeName', expenseType.glCodeName || '');
        }

        // Reset invalid transportMode if needed
        const currentTransportMode = this.lineItems[idx].transportMode;
        const validTransportModes = this.getTransportOptionsForItem(value, this.selectedVoucherType).map(opt => opt.value);
        if (currentTransportMode && !validTransportModes.includes(currentTransportMode)) {
            this.updateLineItem(idx, 'transportMode', '');
        }

        // If it's a food expense, disable transport mode
        if (isFood) {
            this.updateLineItem(idx, 'transportMode', ''); // Clear transport mode
            this.updateLineItem(idx, 'disableTransportMode', true); // Disable the field
        } else {
            this.updateLineItem(idx, 'disableTransportMode', false); // Enable the field
        }

        // Force refresh to update the header text
        this.lineItems = [...this.lineItems];
    }

    updateLineItemTotal(index) {
        const item = this.lineItems[index];
        const amountClaimed = parseFloat(item.amountClaimed) || 0;
        const dailyAllowance = parseFloat(item.dailyAllowance) || 0;
        const total = amountClaimed + dailyAllowance;
        
        this.updateLineItem(index, 'total', total);
    }

    // Update your change handlers to call updateLineItemTotal
    handleAmountClaimedChange(event) {
        const idx = parseInt(event.target.dataset.index, 10);
        const value = parseFloat(event.target.value) || 0;
        this.updateLineItem(idx, 'amountClaimed', value);
        this.updateLineItemTotal(idx); // Add this line
    }

    handleReasonChange(event) {
        const idx = parseInt(event.target.dataset.index, 10);
        const value = event.target.value;
        this.updateLineItem(idx, 'reason', value);
    }

    handleFromLocationChange(event) {
        const idx = parseInt(event.target.dataset.index, 10);
        const value = event.target.value;
        this.updateLineItem(idx, 'fromLocation', value);
    }

    handleToLocationChange(event) {
        const idx = parseInt(event.target.dataset.index, 10);
        const value = event.target.value;
        this.updateLineItem(idx, 'toLocation', value);
    }

    handleTollParkingChange(event) {
        const idx = parseInt(event.target.dataset.index, 10);
        const value = parseFloat(event.target.value) || 0;
        this.updateLineItem(idx, 'tollParking', value);
    }

    handleTransportModeChange(event) {
        const idx = parseInt(event.currentTarget.dataset.index, 10);
        const value = event.detail.value;
        this.updateTransportModeAndRate(idx, value, 'local');
    }

    handleStartKMChange(event) {
        const idx = parseInt(event.target.dataset.index, 10);
        const value = parseFloat(event.target.value) || 0;
        this.updateLineItem(idx, 'startKM', value);
    }

    handleEndKMChange(event) {
        const idx = parseInt(event.target.dataset.index, 10);
        const value = parseFloat(event.target.value) || 0;
        this.updateLineItem(idx, 'endKM', value);
    }

    handleKMRateChange(event) {
        const idx = parseInt(event.target.dataset.index, 10);
        const value = parseFloat(event.target.value) || 0;
        this.updateLineItem(idx, 'kmRate', value);
    }

    updateLineItem(index, field, value) {
        this.lineItems = this.lineItems.map((item, i) =>
            i === index ? { ...item, [field]: value } : item
        );
    }

    handleTourSelected(event) {
        this.selectedTourId = event.detail.recordId;
        this.selectedTourName = event.detail.recordName;
    }

    // Add these new change handlers
    handleOutstationDateChange(event) {
        const idx = parseInt(event.target.dataset.index, 10);
        const value = event.target.value;
        this.updateLineItem(idx, 'outstationDate', value);
    }

    handleOutstationFromLocationChange(event) {
        const idx = parseInt(event.target.dataset.index, 10);
        const value = event.target.value;
        this.updateLineItem(idx, 'outstationFromLocation', value);
    }

    handleOutstationToLocationChange(event) {
        const idx = parseInt(event.target.dataset.index, 10);
        const value = event.target.value;
        this.updateLineItem(idx, 'outstationToLocation', value);
    }

    handleOutstationTransportModeChange(event) {
        const idx = parseInt(event.currentTarget.dataset.index, 10);
        const value = event.detail.value;
        this.updateTransportModeAndRate(idx, value, 'outstation');
    }

    updateTransportModeAndRate(index, transportMode, type) {
        console.log(`Setting ${type} transport mode to:`, transportMode);
        console.log('Available rates - Four Wheeler:', this.fourWheelerPerKm, 'Two Wheeler:', this.twoWheelerPerKm);

        // Auto-set KM rate based on transport mode
        let kmRate = 0;
        if (transportMode === 'Car') {
            kmRate = this.fourWheelerPerKm || 0;
        } else if (transportMode === 'Bike') {
            kmRate = this.twoWheelerPerKm || 0;
        }
        
        console.log('Setting KM rate to:', kmRate);

        // Update the appropriate transport mode field
        if (type === 'local') {
            this.updateLineItem(index, 'transportMode', transportMode);
            this.updateLineItem(index, 'kmRate', kmRate);
        } else {
            this.updateLineItem(index, 'outstationTransportMode', transportMode);
            // For outstation, you might want to store the rate differently or use the same field
            this.updateLineItem(index, 'kmRate', kmRate);
        }

        // Handle KM field disabling (for Local only)
        if (type === 'local') {
            const disableKM = (transportMode === 'Bus');
            this.updateLineItem(index, 'disableKMFields', disableKM);

            // Toll/Parking visible only for Car/Bike
            const showTollParking = this.shouldShowTollParking(transportMode);
            this.updateLineItem(index, 'showTollParking', showTollParking);
            this.updateLineItem(index, 'disableTollParking', !showTollParking);

            if (!showTollParking) {
                this.updateLineItem(index, 'tollParking', 0);
            }
        }

        // Force re-render to update totals
        this.lineItems = [...this.lineItems];
    }

    handleTicketBookedChange(event) {
        const idx = parseInt(event.target.dataset.index, 10);
        const value = event.target.checked;
        this.updateLineItem(idx, 'ticketBookedByCompany', value);
    }

    handleOutstationDescriptionChange(event) {
        const idx = parseInt(event.target.dataset.index, 10);
        const value = event.target.value;
        this.updateLineItem(idx, 'outstationDescription', value);
    }

    handleOutstationReasonChange(event) {
        const idx = parseInt(event.target.dataset.index, 10);
        const value = event.target.value;
        this.updateLineItem(idx, 'outstationReason', value);
    }

    handleCashDescriptionChange(event) {
        const idx = parseInt(event.target.dataset.index, 10);
        const value = event.target.value;
        this.updateLineItem(idx, 'cashDescription', value);
    }


    handleAccountSelected(event) {
        const accountId = event.detail?.recordId;
        const accountName = event.detail?.recordName;

        if (!this.selectedTourId) {
            this.showToast('Error', 'Please select a Tour before selecting an Account.', 'error');
            return;
        }

        // Check if account is already selected
        if (!this.selectedAccounts.find(acc => acc.Id === accountId)) {
            // Add to selected accounts (but don't create Customer Visit yet)
            this.selectedAccounts = [
                ...this.selectedAccounts,
                { Id: accountId, Name: accountName }
            ];

            //  this.showToast('Success', `Added ${accountName} to customer visits`, 'success');
        } else {
            this.showToast('Info', `${accountName} is already added`, 'info');
        }
    }


    handleAccountRemoved(event) {
        const removedId = event.detail.recordId;
        this.selectedAccounts = this.selectedAccounts.filter(acc => acc.Id !== removedId);
    }


    get showRemarkColumn() {
        return this.selectedVoucherType === 'Special';
    }

    // Add this handler method
    handleRemarkChange(event) {
        const idx = parseInt(event.target.dataset.index, 10);
        const value = event.target.value;
        this.updateLineItem(idx, 'remark', value);
    }

    // Calculate total for each line item
    get lineItemsWithTotals() {
        return this.lineItems.map(item => {
            const amountClaimed = parseFloat(item.amountClaimed) || 0;
            const dailyAllowance = parseFloat(item.dailyAllowance) || 0;
            const total = amountClaimed + dailyAllowance;
            
            return {
                ...item,
                total: total
            };
        });
    }

    // Update the grand total getter to use the new computed property
    get grandTotal() {
        return this.lineItemsWithTotals.reduce((sum, item) => {
            return sum + (parseFloat(item.total) || 0);
        }, 0);
    }

    // Add handler for total display
    handleTotalDisplay(event) {
        // This method can be used if you need to handle total changes
        const idx = parseInt(event.target.dataset.index, 10);
        // Total is calculated automatically, so no need to update
    }

    addLineItem() {
        const newItem = {
            key: this.nextKey++,
            typeOfExpenseId: '',
            amountClaimed: 0,
            dailyAllowance: this.dailyAllowance || 0,
            total: this.dailyAllowance || 0, // Initialize with daily allowance
            reason: '',
            fromLocation: '',
            toLocation: '',
            transportMode: '',
            startKM: '',
            endKM: '',
            kmRate: 0,
            fileCount: 0,
            isPrivate: false,
            isPublic: false,
            isFood: false,
            transportOptions: this.getTransportOptionsForItem('', this.selectedVoucherType), // Pass voucher type
            disableKMFields: false,
            showTollParking: false,
            disableTollParking: true,
            outstationDate: this.todayDate,
            outstationFromLocation: '',
            outstationToLocation: '',
            outstationTransportMode: '',
            ticketBookedByCompany: false,
            outstationDescription: '',
            outstationReason: '',
            cashDescription: '',
            glCodeId: '',
            glCodeName: '',
            remark: '',
            disableDailyAllowance: !this.canEditDailyAllowance
        };
        this.lineItems = [...this.lineItems, newItem];
    }

    deleteLineItem(event) {
        const idx = parseInt(event.currentTarget.dataset.index, 10);
        if (this.lineItems.length > 1) {
            const key = this.lineItems[idx].key;
            this.filesMap.delete(key);
            this.lineItems.splice(idx, 1);
            this.lineItems = [...this.lineItems];
        } else {
            this.showToast('Info', 'At least one line item is required', 'info');
        }
    }

    handleFileUpload(event) {
        const key = this.lineItems[event.target.dataset.index].key;
        const files = event.detail.files;
        if (files && files.length > 0) {
            const documentIds = files.map(file => file.documentId);
            this.filesMap.set(key, documentIds);
            this.updateLineItem(event.target.dataset.index, 'fileCount', documentIds.length);
            this.showToast('Success', `${documentIds.length} file(s) uploaded successfully`, 'success');
        }
    }

    // Add handler for daily allowance change
    handleDailyAllowanceChange(event) {
        const idx = parseInt(event.target.dataset.index, 10);
        const value = parseFloat(event.target.value) || 0;
        this.updateLineItem(idx, 'dailyAllowance', value);
        this.updateLineItemTotal(idx); // Add this line
    }


    async handleVoucherTypeChange(event) {
        this.selectedVoucherType = event.detail.value;
        this.selectedTourId = '';
        this.selectedTourName = '';

        try {
            this.isLoading = true;
            this.typeOfExpenseOptions = await getTypeOfExpense({
                searchTerm: '',
                voucherType: this.selectedVoucherType
            });

            // Clear line items but preserve relevant fields
            this.lineItems = this.lineItems.map(item => ({
                ...item,
                typeOfExpenseId: '',
                reason: '',
                fromLocation: '',
                toLocation: '',
                transportOptions: this.getTransportOptionsForItem('', this.selectedVoucherType),
                transportMode: '',
                startKM: '',
                endKM: '',
                kmRate: 0,
                tollParking: 0,
                showTollParking: false,
                outstationFromLocation: '',
                outstationToLocation: '',
                outstationTransportMode: '',
                ticketBookedByCompany: false,
                outstationDescription: '',
                outstationReason: '',
                cashDescription: '',
                glCodeId: '',
                glCodeName: '',
                remark: '',
                // Preserve daily allowance for Local and Outstation vouchers
                dailyAllowance: (this.selectedVoucherType === 'Local' || this.selectedVoucherType === 'Outstation') ? 
                               (item.dailyAllowance || this.dailyAllowance) : 0,
                disableDailyAllowance: !this.canEditDailyAllowance
            }));

        } catch (error) {
            this.showToast('Error', 'Failed to load expense types for selected voucher', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleNameChange(event) {
        this.expenseName = event.target.value;
    }

    handleDateChange(event) {
        this.todayDate = event.target.value;
    }

    async handleSubmit() {
        if (!this.validateForm()) return;

        this.isLoading = true;

        try {
            const customerVisitIds = [];

            if (this.selectedVoucherType === 'Outstation' && this.selectedTourId && this.selectedAccounts.length > 0) {
                for (const account of this.selectedAccounts) {
                    try {
                        const customerVisitId = await createCustomerVisit({
                            tourId: this.selectedTourId,
                            accountId: account.Id
                        });

                        customerVisitIds.push(customerVisitId);
                        //   this.showToast('Success', `Customer Visit created for ${account.Name}`, 'success');

                    } catch (visitError) {
                        console.error('Customer Visit creation error for account:', account.Name, visitError);
                        this.showToast('Error', `Failed to create Customer Visit for ${account.Name}`, 'error');
                    }
                }
            }

            const expense = {
                // Name: this.expenseName,
                Date__c: this.todayDate,
                Employee_Name__c: this.selectedEmployeeId,
                Type_of_Voucher__c: this.selectedVoucherType,
                Division__c: this.division,
                Zone__c: this.zone,
                Sales_Type__c: this.salesType,
                Tour__c: this.selectedTourId,
                Customer_Visited__c: customerVisitIds.length > 0 ? customerVisitIds[0] : null,
                Visit_Report__c: this.visitReportId,
                Cost_Center__c: this.costCenterId,
                CurrencyIsoCode: this.selectedCurrency
            };

            const lineItemsToSend = this.lineItems.map(item => ({
                Type_of_Expense__c: item.typeOfExpenseId,
                Amount_Claimed__c: item.amountClaimed,
                Daily_Allowance__c: (this.selectedVoucherType === 'Local' || this.selectedVoucherType === 'Outstation') ? item.dailyAllowance : null,
                Reason__c: this.selectedVoucherType === 'Misc' ? item.reason :
                    (this.selectedVoucherType === 'Outstation' ? item.outstationReason : null),
                From_Location__c: this.selectedVoucherType === 'Local' ? item.fromLocation :
                    (this.selectedVoucherType === 'Outstation' ? item.outstationFromLocation : null),
                To_Location__c: this.selectedVoucherType === 'Local' ? item.toLocation :
                    (this.selectedVoucherType === 'Outstation' ? item.outstationToLocation : null),
                Mode_of_Transport__c: this.selectedVoucherType === 'Local' ? item.transportMode :
                    (this.selectedVoucherType === 'Outstation' ? item.outstationTransportMode : null),
                Start_KM__c: this.selectedVoucherType === 'Local' ? (item.startKM || null) : null,
                End_KM__c: this.selectedVoucherType === 'Local' ? (item.endKM || null) : null,
                KM_Rate__c: this.selectedVoucherType === 'Local' ? item.kmRate : null,
                Toll_Parking__c: this.selectedVoucherType === 'Local' ? item.tollParking : null,
                // Outstation fields
                Date__c: this.selectedVoucherType === 'Outstation' ? item.outstationDate : null,
                Ticket_Booked_By_Company__c: this.selectedVoucherType === 'Outstation' ? item.ticketBookedByCompany : false,
                Description__c: this.selectedVoucherType === 'Outstation' ? item.outstationDescription :
                    (this.selectedVoucherType === 'Cash' ? item.cashDescription : null),
                CurrencyIsoCode: this.selectedCurrency,
                Remark__c: this.selectedVoucherType === 'Special' ? item.remark : null
            }));

            // FIXED: Create filesPerLineItem using the correct structure
            const filesPerLineItem = {};
            this.lineItems.forEach((item, index) => {
                if (this.filesMap.has(item.key)) {
                    filesPerLineItem[String(index)] = this.filesMap.get(item.key);
                }
            });

            console.log('Submitting files:', JSON.stringify(filesPerLineItem));

            const expenseId = await createExpenseWithFiles({
                expense,
                lineItems: lineItemsToSend,
                filesPerLineItem: filesPerLineItem
            });

            this.showToast('Success', 'Expense claim submitted successfully with all attachments', 'success');
            setTimeout(() => window.location.reload(), 1000);
            this.navigateToRecord(expenseId);

        } catch (error) {
            console.error('Submission error:', error);
            this.showToast('Error', error?.body?.message || error.message || 'Submission failed', 'error');
        } finally {
            this.isLoading = false;
        }
    }


    validateForm() {
        const allFields = this.template.querySelectorAll('lightning-input, lightning-combobox');
        let isValid = true;

        allFields.forEach(field => {
            if (!field.disabled && !field.reportValidity()) {
                isValid = false;
            }
        });

        // if (!this.expenseName) {
        //     this.showToast('Error', 'Enter Voucher No', 'error');
        //     return false;
        // }

        if (!this.todayDate) {
            this.showToast('Error', 'Select Expense Date', 'error');
            return false;
        }
        if (!this.selectedEmployeeId) {
            this.showToast('Error', 'Select Employee', 'error');
            return false;
        }
        if (!this.selectedVoucherType) {
            this.showToast('Error', 'Select Type of Voucher', 'error');
            return false;
        }

        if (!this.salesType) {
            this.showToast('Error', 'Please select Sales Type', 'error');
            return false;
        }

        if (this.selectedVoucherType === 'Outstation' && !this.selectedTourId) {
            this.showToast('Error', 'Please select a Tour for Outstation expense', 'error');
            return false;
        }

        for (let i = 0; i < this.lineItems.length; i++) {
            const item = this.lineItems[i];
            const isPrivate = this.isPrivateExpense(item.typeOfExpenseId);
            const isPublic = this.isPublicExpense(item.typeOfExpenseId);
            if (!item.typeOfExpenseId) {
                this.showToast('Error', `Select Type of Expense for row ${i + 1}`, 'error');
                return false;
            }
            if (!item.amountClaimed || item.amountClaimed <= 0) {
                this.showToast('Error', `Enter valid Amount Claimed for row ${i + 1}`, 'error');
                return false;
            }
            // Validate reason field only for Misc voucher type
            if (this.selectedVoucherType === 'Misc' && (!item.reason || item.reason.trim() === '')) {
                this.showToast('Error', `Enter Reason for Misc expense in row ${i + 1}`, 'error');
                return false;
            }
            // FILE VALIDATION FOR CAR TRANSPORT MODE
            const transportMode = this.selectedVoucherType === 'Local' ? item.transportMode : item.outstationTransportMode;
            const hasFiles = this.filesMap.has(item.key) && this.filesMap.get(item.key).length > 0;

            if (transportMode === 'Car' && !hasFiles) {
                this.showToast('Error', `Meter Photo upload is mandatory for Car transport mode in row ${i + 1}`, 'error');
                return false;
            }
            // Validate transport mode for local vouchers
            if (this.selectedVoucherType === 'Local' && !this.isFoodExpense(item.typeOfExpenseId)) {
                if (!item.transportMode) {
                    this.showToast('Error', `Select Mode of Transport for Local expense in row ${i + 1}`, 'error');
                    return false;
                }

                // Validate transport mode based on expense type
                if (isPublic && item.transportMode !== 'Bus') {
                    this.showToast('Error', `Public expense must use Bus transport in row ${i + 1}`, 'error');
                    return false;
                }

                if (isPrivate && item.transportMode === 'Bus') {
                    this.showToast('Error', `Private expense cannot use Bus transport in row ${i + 1}`, 'error');
                    return false;
                }

                // Validate KM Rate is required for all Local vouchers
                if (!item.kmRate || item.kmRate <= 0) {
                    this.showToast('Error', `Enter valid KM Rate/Bus Fare for row ${i + 1}`, 'error');
                    return false;
                }

                // Validate KM fields for private transport
                if (isPrivate) {
                    if (!item.startKM || item.startKM <= 0) {
                        this.showToast('Error', `Enter valid Start KM for private transport in row ${i + 1}`, 'error');
                        return false;
                    }
                    if (!item.endKM || item.endKM <= 0) {
                        this.showToast('Error', `Enter valid End KM for private transport in row ${i + 1}`, 'error');
                        return false;
                    }
                    if (item.endKM <= item.startKM) {
                        this.showToast('Error', `End KM must be greater than Start KM in row ${i + 1}`, 'error');
                        return false;
                    }
                }
            }

            // Add outstation validation
            if (this.selectedVoucherType === 'Outstation') {
                for (let i = 0; i < this.lineItems.length; i++) {
                    const item = this.lineItems[i];
                    const isFood = this.isFoodExpense(item.typeOfExpenseId);

                    if (!item.outstationDate) {
                        this.showToast('Error', `Select Date for Outstation expense in row ${i + 1}`, 'error');
                        return false;
                    }
                    if (!item.outstationFromLocation || item.outstationFromLocation.trim() === '') {
                        this.showToast('Error', `Enter From Location for Outstation expense in row ${i + 1}`, 'error');
                        return false;
                    }
                    if (!item.outstationToLocation || item.outstationToLocation.trim() === '') {
                        this.showToast('Error', `Enter To Location for Outstation expense in row ${i + 1}`, 'error');
                        return false;
                    }
                    if (!isFood && !item.outstationTransportMode) {
                        this.showToast('Error', `Select Transport Mode for Outstation expense in row ${i + 1}`, 'error');
                        return false;
                    }

                    // If it's a food expense, clear any transport mode value
                    if (isFood && item.outstationTransportMode) {
                        this.updateLineItem(i, 'outstationTransportMode', '');
                    }
                }
            }
        }
        return isValid;
    }

    handleCancel() {

        window.history.back();

        this.dispatchEvent(new CustomEvent('close'));
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    get totalAmount() {
        return this.lineItems.reduce((sum, item) => sum + (item.amountClaimed || 0), 0);
    }

    navigateToRecord(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: 'Expense__c', // Add this line
                actionName: 'view'
            }
        });
    }
}