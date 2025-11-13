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
import getGradeDetails from '@salesforce/apex/ExpenseController.getGradeDetails';
import getGradeDetailsWithSalesType from '@salesforce/apex/ExpenseController.getGradeDetailsWithSalesType';
import getModeOfTravelOptions from '@salesforce/apex/ExpenseController.getModeOfTravelOptions';
import getExportTransportModes from '@salesforce/apex/ExpenseController.getExportTransportModes';
import getCityDetails from '@salesforce/apex/ExpenseController.getCityDetails';
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
    @track lodgingHotel = 0;
    @track boardingFood = 0;
    @track dailyAllowanceBClass = 0;
    @track lodgingHotelBClass = 0;
    @track boardingFoodBClass = 0;

    @track lodgingHotelBClass = 0;
    @track boardingFoodBClass = 0;
    @track selectedCityId = '';
    @track selectedCityName = ''; // Add this
    @track selectedCityType = ''; // Add this
    @track isAClassCity = false; // Add this

    @track employeeOptions = [];
    @track typeOfExpenseOptions = [];
    @track voucherOptions = [];
    @track allTransportModeOptions = [];
    @track gradeTransportModeOptions = [];
    @track modeOfTravelOptions = []; // Add this for Mode_of_Travel picklist
    @track modeOfOutstationTravelOptions = []; // Add this for outstation transport modes
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
    @track lineItems = [];

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

    get showModeOfTravelField() {
        return this.selectedVoucherType === 'Outstation' && this.salesType === 'Domestic';
    }

    // NEW: Computed property for Export Outstation
    get isExportOutstation() {
        return this.selectedVoucherType === 'Outstation' && this.salesType === 'Export';
    }

    // NEW: Computed property for Domestic Outstation
    get isDomesticOutstation() {
        return this.selectedVoucherType === 'Outstation' && this.salesType === 'Domestic';
    }

    // NEW: Computed property to show limitation
    get showLimitation() {
        return this.isExportOutstation || this.isDomesticOutstation;
    }

    get showCityField() {
        return this.salesType === 'Domestic';
    }

    get showKMOrTollParkingField() {
        return this.selectedVoucherType === 'Local' || this.selectedVoucherType === 'Outstation' && this.lineItems.some(item => item.modeOfTravel === 'Own Vehicle');
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

    get salesTypeDebug() {
        console.log('Sales Type Updated:', this.salesType, 'Show City Field:', this.showCityField);
        return this.salesType;
    }

    // Add this getter to your main component
    get debugInfo() {
        return {
            salesType: this.salesType,
            showCityField: this.showCityField,
            salesTypeOptions: this.salesTypeOptions,
            selectedCityId: this.selectedCityId,
            selectedCityName: this.selectedCityName
        };
    }

    // Add this to renderedCallback
    renderedCallback() {
        console.log('=== DEBUG INFO ===');
        console.log('Sales Type:', this.salesType);
        console.log('Show City Field:', this.showCityField);
        console.log('Sales Type Options:', this.salesTypeOptions);
        console.log('Selected City ID:', this.selectedCityId);
        console.log('Selected City Name:', this.selectedCityName);

        // Check if city field element exists
        const cityField = this.template.querySelector('c-city-lookup-component');
        console.log('City Field in DOM:', !!cityField);
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
        getSalesTypeOptions()
            .then(result => {
                this.salesTypeOptions = result;
                console.log('Sales Type Options loaded:', this.salesTypeOptions);

                // Auto-select Domestic if available
                const domesticOption = this.salesTypeOptions.find(option => option.value === 'Domestic');
                if (domesticOption && !this.salesType) {
                    this.salesType = 'Domestic';
                    console.log('Auto-selected Domestic sales type:', this.salesType);
                }
            })
            .catch(error => {
                console.error('Error loading sales type options:', error);
            });
    }

    // Update handler for sales type change
    async handleSalesTypeChange(event) {
        this.salesType = event.detail.value;

        console.log('Sales Type changed to:', this.salesType);

        // Reset City when sales type changes to non-Domestic
        if (this.salesType !== 'Domestic') {
            this.selectedCityId = '';
            this.selectedCityName = '';
            this.selectedCityType = '';
            this.isAClassCity = false;

            // For non-Domestic, use default A Class rates
            if (this.userGradeName) {
                await this.updateGradeDetailsWithSalesType(this.userGradeName, this.salesType);
            }
        } else {
            // For Domestic, if city is already selected, update allowances based on city
            if (this.selectedCityId) {
                await this.updateAllowancesBasedOnCity();
            } else if (this.userGradeName) {
                // If no city selected but Domestic, use default grade details
                await this.updateGradeDetailsWithSalesType(this.userGradeName, this.salesType);
            }
        }

        // Auto-change currency
        if (this.salesType === 'Export') {
            this.selectedCurrency = 'USD';
        } else if (this.salesType === 'Domestic') {
            this.selectedCurrency = 'INR';
        }

        // Update transport modes for Export Outstation
        if (this.isExportOutstation) {
            await this.updateExportTransportModes();
        }

        // Refresh all limitation texts
        this.refreshAllLimitationTexts();
    }

    // NEW: Update transport modes for Export
    async updateExportTransportModes() {
        try {
            if (this.userGradeName) {
                const exportTransportModes = await getExportTransportModes({ gradeName: this.userGradeName });
                console.log('Export transport modes loaded:', exportTransportModes);

                // Update all line items with export transport modes
                this.lineItems = this.lineItems.map(item => ({
                    ...item,
                    transportOptions: exportTransportModes
                }));
            }
        } catch (error) {
            console.error('Error updating export transport modes:', error);
        }
    }

    async updateGradeDetailsWithSalesType(gradeName, salesType) {
        try {
            console.log('Updating grade details with sales type:', gradeName, salesType);

            const gradeDetails = await getGradeDetailsWithSalesType({
                gradeName: gradeName,
                salesType: salesType
            });

            console.log('Grade details with sales type received:', gradeDetails);

            if (gradeDetails.success) {
                // Store ALL rates (both A and B Class)
                this.dailyAllowance = gradeDetails.dailyAllowance || 0;
                this.dailyAllowanceBClass = gradeDetails.dailyAllowanceBClass || gradeDetails.dailyAllowance || 0; // Add this
                this.fourWheelerPerKm = gradeDetails.fourWheelerPerKm || 0;
                this.twoWheelerPerKm = gradeDetails.twoWheelerPerKm || 0;
                this.specialAllowance = gradeDetails.specialAllowance || 0;
                this.outOfPocket = gradeDetails.outOfPocket || 0;
                this.lodgingHotel = gradeDetails.lodgingHotel || 0;
                this.boardingFood = gradeDetails.boardingFood || 0;
                this.lodgingHotelBClass = gradeDetails.lodgingHotelBClass || gradeDetails.lodgingHotel || 0; // Add this
                this.boardingFoodBClass = gradeDetails.boardingFoodBClass || gradeDetails.boardingFood || 0; // Add this
                this.canEditDailyAllowance = gradeDetails.canEditDailyAllowance || false;

                console.log('All allowances loaded - A Class DA:', this.dailyAllowance, 'B Class DA:', this.dailyAllowanceBClass);
                console.log('A Class Lodging:', this.lodgingHotel, 'B Class Lodging:', this.lodgingHotelBClass);
                console.log('A Class Boarding:', this.boardingFood, 'B Class Boarding:', this.boardingFoodBClass);

                // For Domestic sales type, update allowances based on city if selected
                if (salesType === 'Domestic' && this.selectedCityId) {
                    await this.updateAllowancesBasedOnCity();
                }

                // Update transport modes from grade
                if (gradeDetails.modeOfTravelOptions && gradeDetails.modeOfTravelOptions.length > 0) {
                    this.gradeTransportModeOptions = gradeDetails.modeOfTravelOptions.map(mode => ({
                        label: mode,
                        value: mode
                    }));
                    console.log('Updated grade transport modes with sales type:', this.gradeTransportModeOptions);
                } else {
                    this.gradeTransportModeOptions = [];
                    console.log('No transport modes found in grade for sales type:', salesType);
                }

                // Update outstation travel modes
                if (gradeDetails.modeOfOutstationTravelOptions && gradeDetails.modeOfOutstationTravelOptions.length > 0) {
                    this.modeOfOutstationTravelOptions = gradeDetails.modeOfOutstationTravelOptions.map(mode => ({
                        label: mode,
                        value: mode
                    }));
                    console.log('Updated mode of outstation travel options:', this.modeOfOutstationTravelOptions);
                }

                // Update all line items with new transport options, rates, and limitation texts
                this.lineItems = this.lineItems.map(item => {
                    const transportOptions = this.getTransportOptionsForItem(item.typeOfExpenseId);
                    const limitationText = this.computeLimitationText(item);

                    console.log('Updating line item with new grade data from sales type');

                    return {
                        ...item,
                        dailyAllowance: this.dailyAllowance,
                        disableDailyAllowance: !this.canEditDailyAllowance,
                        transportOptions: transportOptions,
                        limitationText: limitationText,
                        // Auto-update KM rate if transport mode is set
                        kmRate: this.getUpdatedKMRateForItem(item)
                    };
                });

                if (gradeDetails.fallback) {
                    this.showToast('Info', `Using default grade configuration for ${gradeName}`, 'info');
                } else {
                    this.showToast('Success', `Grade configuration loaded for ${salesType}`, 'success');
                }
            } else {
                this.showToast('Warning', gradeDetails.message || 'No grade configuration found', 'warning');
            }

        } catch (error) {
            console.error('Error updating grade details with sales type:', error);
            this.showToast('Error', 'Failed to load grade configuration', 'error');
        }
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
                this.specialAllowance = result.specialAllowance || 0; // Initialize
                this.outOfPocket = result.outOfPocket || 0; // Initialize
                this.canEditDailyAllowance = result.canEditDailyAllowance || false;

                console.log('User Grade:', this.userGrade);
                console.log('Daily Allowance:', this.dailyAllowance);
                console.log('Special Allowance:', this.specialAllowance);
                console.log('Out of Pocket:', this.outOfPocket);

                // Convert mode of travel options to combobox format
                if (result.modeOfTravelOptions && result.modeOfTravelOptions.length > 0) {
                    this.gradeTransportModeOptions = result.modeOfTravelOptions.map(mode => ({
                        label: mode,
                        value: mode
                    }));
                    console.log('Grade Transport Modes loaded:', this.gradeTransportModeOptions);
                } else {
                    console.log('No transport modes found in grade during initialization');
                    this.gradeTransportModeOptions = [];
                }

                // Initialize Mode_of_Outstation_Travel options
                if (result.modeOfOutstationTravelOptions && result.modeOfOutstationTravelOptions.length > 0) {
                    this.modeOfOutstationTravelOptions = result.modeOfOutstationTravelOptions.map(mode => ({
                        label: mode,
                        value: mode
                    }));
                    console.log('Mode of Outstation Travel Options loaded:', this.modeOfOutstationTravelOptions);
                }
            }

            this.costCenterId = result.costCenterId || '';
            this.voucherOptions = result.voucherOptions || [];

            // Load all transport modes
            this.allTransportModeOptions = await getTransportModes();
            console.log('All transport modes loaded:', this.allTransportModeOptions);

            // Load Mode_of_Travel picklist options
            this.modeOfTravelOptions = await getModeOfTravelOptions();
            console.log('Mode of Travel options loaded:', this.modeOfTravelOptions);

            this.publicTransportModes = this.allTransportModeOptions.filter(mode => mode.value === 'Bus');
            this.privateTransportModes = this.allTransportModeOptions.filter(mode => mode.value === 'Car' || mode.value === 'Bike');

            this.employeeOptions = await getUsers({ searchTerm: '' });
            this.typeOfExpenseOptions = await getTypeOfExpense({
                searchTerm: '',
                voucherType: null
            });

            // Update line items with grade data and correct transport options
            this.lineItems = this.lineItems.map(item => {
                const transportOptions = this.getTransportOptionsForItem('', this.selectedVoucherType);
                console.log('Initializing line item with transport options:', transportOptions);

                return {
                    ...item,
                    dailyAllowance: this.dailyAllowance,
                    disableDailyAllowance: !this.canEditDailyAllowance,
                    transportOptions: transportOptions,
                    modeOfTravel: '', // Initialize Mode_of_Travel
                    disableTransportFields: false // Initialize disable flag
                };
            });

        } catch (error) {
            console.error('Initialization error:', error);
            this.showToast('Error', error?.body?.message || error.message || 'Initialization failed', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // Get transport options based on expense type name and voucher type
    getTransportOptionsForItem(typeOfExpenseId, voucherType = this.selectedVoucherType) {
        console.log('=== getTransportOptionsForItem called ===');
        console.log('Voucher type:', voucherType);
        console.log('Sales Type:', this.salesType);
        console.log('Expense type ID:', typeOfExpenseId);

        // For Outstation Export - use Mode_of_Travel__c from grade with Sales_Type__c = 'Export'
        if (voucherType === 'Outstation' && this.salesType === 'Export') {
            console.log('Processing Outstation Export voucher type');

            if (this.gradeTransportModeOptions.length > 0) {
                console.log('Using export-specific modes:', this.gradeTransportModeOptions);
                return this.gradeTransportModeOptions;
            } else {
                console.log('No export-specific modes found, returning all modes');
                return this.allTransportModeOptions;
            }
        }

        // For Outstation Domestic - use Mode_of_Outstation_Travel__c from grade
        if (voucherType === 'Outstation' && this.salesType === 'Domestic') {
            console.log('Processing Outstation Domestic voucher type');

            if (this.modeOfOutstationTravelOptions.length > 0) {
                console.log('Using outstation-specific modes:', this.modeOfOutstationTravelOptions);
                return this.modeOfOutstationTravelOptions;
            } else {
                console.log('No outstation-specific modes found, returning all modes');
                return this.allTransportModeOptions;
            }
        }

        // For other voucher types - apply expense type filtering
        console.log('Processing other voucher type:', voucherType);
        const availableModes = this.gradeTransportModeOptions.length > 0 ?
            this.gradeTransportModeOptions : this.allTransportModeOptions;

        if (!typeOfExpenseId) {
            console.log('No expense type ID, returning available modes');
            return availableModes;
        }

        const expenseType = this.typeOfExpenseOptions.find(opt => opt.value === typeOfExpenseId);
        if (!expenseType) {
            console.log('Expense type not found, returning available modes');
            return availableModes;
        }

        console.log('Expense type found:', expenseType.name);

        if (expenseType.name === 'Public') {
            const publicModes = availableModes.filter(mode => mode.value === 'Bus');
            console.log('Filtered for Public expense:', publicModes);
            return publicModes;
        } else if (expenseType.name === 'Private') {
            const privateModes = availableModes.filter(mode => mode.value === 'Car' || mode.value === 'Bike');
            console.log('Filtered for Private expense:', privateModes);
            return privateModes;
        }

        console.log('No specific filtering, returning all available modes');
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
                // Use sales type if available, otherwise use default grade details
                if (this.salesType) {
                    await this.updateGradeDetailsWithSalesType(emp.grade, this.salesType);
                } else {
                    // Fallback to original method without sales type
                    try {
                        const gradeDetails = await getGradeDetails({ gradeName: emp.grade });

                        console.log('Grade details received (without sales type):', gradeDetails);

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
                            console.log('No transport modes found in grade for employee:', emp.grade);
                        }

                        // Update all line items with new transport options and recalculate totals
                        this.lineItems = this.lineItems.map(item => {
                            const transportOptions = this.getTransportOptionsForItem(item.typeOfExpenseId);
                            const updatedItem = {
                                ...item,
                                dailyAllowance: this.dailyAllowance,
                                disableDailyAllowance: !this.canEditDailyAllowance,
                                transportOptions: transportOptions,
                                // Auto-update KM rate if transport mode is set
                                kmRate: this.getUpdatedKMRateForItem(item)
                            };

                            // Recalculate total with new daily allowance
                            updatedItem.total = this.calculateLineItemTotal(updatedItem);

                            return updatedItem;
                        });

                        console.log('Updated line items with new grade data');

                    } catch (error) {
                        console.error('Error fetching grade details:', error);
                        this.dailyAllowance = 0;
                        this.canEditDailyAllowance = false;
                        this.gradeTransportModeOptions = [];
                    }
                }
            } else {
                console.log('No grade found for selected employee');
                this.dailyAllowance = 0;
                this.canEditDailyAllowance = false;
                this.gradeTransportModeOptions = [];
            }
        }
    }

    calculateAmountClaimedForLocal(item) {
        if (this.selectedVoucherType !== 'Local') {
            return item.amountClaimed || 0;
        }

        const startKM = parseFloat(item.startKM) || 0;
        const endKM = parseFloat(item.endKM) || 0;
        const kmRate = parseFloat(item.kmRate) || 0;
        const tollParking = parseFloat(item.tollParking) || 0;

        // Calculate: (End KM - Start KM) * KM Rate + Toll Parking
        const distance = endKM - startKM;
        if (distance < 0) return 0; // Invalid if end KM is less than start KM

        const calculatedAmount = (distance * kmRate) + tollParking;
        return Math.max(0, calculatedAmount); // Ensure non-negative
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

    isFoodOrHotelExpense(typeOfExpenseId) {
        if (!typeOfExpenseId) return false;
        const expenseType = this.typeOfExpenseOptions.find(opt => opt.value === typeOfExpenseId);
        if (expenseType && expenseType.label) {
            const label = expenseType.label.toLowerCase();
            return label.includes('food') || label.includes('hotel');
        }
        return false;
    }

    handleTypeOfExpenseChange(event) {
        const idx = parseInt(event.currentTarget.dataset.index, 10);
        const value = event.detail.value;

        console.log('Type of expense changed for index:', idx);
        console.log('Selected expense type ID:', value);

        const expenseType = this.typeOfExpenseOptions.find(opt => opt.value === value);
        const isPrivate = expenseType && expenseType.name === 'Private';
        const isPublic = expenseType && expenseType.name === 'Public';
        const isFoodOrHotel = this.isFoodOrHotelExpense(value);

        // Update line item
        this.updateLineItem(idx, 'typeOfExpenseId', value);
        this.updateLineItem(idx, 'isPrivate', isPrivate);
        this.updateLineItem(idx, 'isPublic', isPublic);
        this.updateLineItem(idx, 'isFoodOrHotel', isFoodOrHotel);

        // Update disable flags
        this.updateLineItem(idx, 'disableTransportFields', isFoodOrHotel);

        // Get and apply transport options
        const transportOptions = this.getTransportOptionsForItem(value, this.selectedVoucherType);
        console.log('Applying transport options:', transportOptions);
        this.updateLineItem(idx, 'transportOptions', transportOptions);

        // Store GL Code information for the selected expense type
        if (expenseType) {
            this.updateLineItem(idx, 'glCodeId', expenseType.glCodeId || '');
            this.updateLineItem(idx, 'glCodeName', expenseType.glCodeName || '');
        }

        // Update limitation text
        const limitationText = this.computeLimitationText({
            ...this.lineItems[idx],
            typeOfExpenseId: value
        });
        this.updateLineItem(idx, 'limitationText', limitationText);

        // If it's a food/hotel expense, clear transport mode values
        if (isFoodOrHotel) {
            console.log('Food/Hotel expense detected, clearing transport fields');
            this.updateLineItem(idx, 'transportMode', '');
            this.updateLineItem(idx, 'outstationTransportMode', '');
            this.updateLineItem(idx, 'fromLocation', '');
            this.updateLineItem(idx, 'toLocation', '');
            this.updateLineItem(idx, 'outstationFromLocation', '');
            this.updateLineItem(idx, 'outstationToLocation', '');
        }

        // Force refresh to update the header text
        this.lineItems = [...this.lineItems];
    }

    handleModeOfTravelChange(event) {
        const idx = parseInt(event.currentTarget.dataset.index, 10);
        const value = event.detail.value;

        console.log('Mode of Travel changed for index:', idx);
        console.log('Selected Mode of Travel:', value);

        this.selectedModeOfTravel = value;


        // Update the field
        this.updateLineItem(idx, 'modeOfTravel', value);

        // Update Daily Allowance based on Mode_of_Travel selection
        let newDailyAllowance = 0;
        if (value === 'Own Vehicle') {
            newDailyAllowance = this.specialAllowance || 0;
        } else if (value === 'Public Transport') {
            newDailyAllowance = this.outOfPocket || 0;
        }

        console.log('Setting daily allowance to:', newDailyAllowance);
        this.updateLineItem(idx, 'dailyAllowance', newDailyAllowance);

        // Recalculate total
        this.updateLineItemTotal(idx);
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

        // This will automatically trigger total calculation in updateLineItem
        this.updateLineItem(idx, 'amountClaimed', value);

        // For Local vouchers, also update the calculated amount display
        if (this.selectedVoucherType === 'Local') {
            this.updateCalculatedAmountDisplay(idx);
        }
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

        // Auto-calculate amount for Local voucher
        if (this.selectedVoucherType === 'Local') {
            const calculatedAmount = this.calculateAmountClaimedForLocal(this.lineItems[idx]);
            this.updateLineItem(idx, 'amountClaimed', calculatedAmount);
        }
    }

    handleTransportModeChange(event) {
        const idx = parseInt(event.currentTarget.dataset.index, 10);
        const value = event.detail.value;
        this.updateTransportModeAndRate(idx, value, 'local');
    }

    handleStartKMChange(event) {
        const idx = parseInt(event.target.dataset.index, 10);
        const value = parseFloat(event.target.value) || 0;

        // Update the field
        this.updateLineItem(idx, 'startKM', value);

        // Auto-calculate amount for Local voucher
        if (this.selectedVoucherType === 'Local') {
            const calculatedAmount = this.calculateAmountClaimedForLocal(this.lineItems[idx]);
            this.updateLineItem(idx, 'amountClaimed', calculatedAmount);
            this.updateCalculatedAmountDisplay(idx);
        }
    }

    handleEndKMChange(event) {
        const idx = parseInt(event.target.dataset.index, 10);
        const value = parseFloat(event.target.value) || 0;

        // Update the field
        this.updateLineItem(idx, 'endKM', value);

        // Auto-calculate amount for Local voucher
        if (this.selectedVoucherType === 'Local') {
            const calculatedAmount = this.calculateAmountClaimedForLocal(this.lineItems[idx]);
            this.updateLineItem(idx, 'amountClaimed', calculatedAmount);
            this.updateCalculatedAmountDisplay(idx);
        }
    }

    handleKMRateChange(event) {
        const idx = parseInt(event.target.dataset.index, 10);
        const value = parseFloat(event.target.value) || 0;

        // Update the field
        this.updateLineItem(idx, 'kmRate', value);

        // Auto-calculate amount for Local voucher
        if (this.selectedVoucherType === 'Local') {
            const calculatedAmount = this.calculateAmountClaimedForLocal(this.lineItems[idx]);
            this.updateLineItem(idx, 'amountClaimed', calculatedAmount);
            this.updateCalculatedAmountDisplay(idx);
        }
    }

    calculateLineItemTotal(item) {
        const amountClaimed = parseFloat(item.amountClaimed) || 0;
        const dailyAllowance = parseFloat(item.dailyAllowance) || 0;
        return amountClaimed + dailyAllowance;
    }

    // MODIFIED: Update line item method to recalculate total
    updateLineItem(index, field, value) {
        this.lineItems = this.lineItems.map((item, i) => {
            if (i === index) {
                const updatedItem = { ...item, [field]: value };

                // Recompute disabled states when relevant fields change
                if (field === 'disableTransportFields' || field === 'disableTransportMode' || field === 'isFoodOrHotel') {
                    updatedItem.computedTransportDisabled = updatedItem.disableTransportFields || updatedItem.disableTransportMode;
                    updatedItem.computedLocationDisabled = updatedItem.disableTransportFields;
                }

                // Recalculate total whenever amountClaimed or dailyAllowance changes
                if (field === 'amountClaimed' || field === 'dailyAllowance') {
                    updatedItem.total = this.calculateLineItemTotal(updatedItem);
                }

                // Update limitation text when expense type changes
                if (field === 'typeOfExpenseId') {
                    updatedItem.limitationText = this.computeLimitationText(updatedItem);
                }

                return updatedItem;
            }
            return item;
        });
    }

    //  Compute limitation text with City logic
    computeLimitationText(item) {
        if (!this.showLimitation || !item.typeOfExpenseId) {
            return '';
        }

        const expenseType = this.typeOfExpenseOptions.find(opt => opt.value === item.typeOfExpenseId);
        if (!expenseType || !expenseType.label) {
            return '';
        }

        const label = expenseType.label.toLowerCase();
        let limitation = '';

        // For Domestic sales type, use City-based logic
        if (this.salesType === 'Domestic') {
            if (label.includes('hotel')) {
                limitation = `Limit: ${this.currencySymbol}${this.lodgingHotel}`;
            } else if (label.includes('food')) {
                limitation = `Limit: ${this.currencySymbol}${this.boardingFood}`;
            }
        }
        // For Export sales type, use existing logic (no city type dependency)
        else if (this.salesType === 'Export') {
            if (label.includes('hotel')) {
                limitation = `Limit: ${this.currencySymbol}${this.lodgingHotel}`;
            } else if (label.includes('food')) {
                limitation = `Limit: ${this.currencySymbol}${this.boardingFood}`;
            }
        }

        return limitation;
    }


    async handleCitySelected(event) {
        this.selectedCityId = event.detail.recordId;

        // Get city details including city type
        try {
            const cityDetails = await getCityDetails({ cityId: this.selectedCityId });

            if (cityDetails.success) {
                this.selectedCityName = cityDetails.cityName;
                this.selectedCityType = cityDetails.cityType || '';
                this.isAClassCity = cityDetails.isAClassCity || false;

                console.log('City selected:', this.selectedCityName, 'Type:', this.selectedCityType, 'Is A Class:', this.isAClassCity);

                // Update allowances based on city type for Domestic sales type
                if (this.salesType === 'Domestic') {
                    await this.updateAllowancesBasedOnCity();
                }

                // Refresh limitation texts for all line items
                this.refreshAllLimitationTexts();

                this.showToast('Success', `City ${this.selectedCityName} selected`, 'success');
            } else {
                this.showToast('Error', cityDetails.message || 'Failed to load city details', 'error');
            }
        } catch (error) {
            console.error('Error getting city details:', error);
            this.showToast('Error', 'Failed to load city details', 'error');
        }
    }

    // NEW: Update all allowances based on city type
    async updateAllowancesBasedOnCity() {
        if (this.salesType === 'Domestic' && this.userGradeName) {
            try {
                const gradeDetails = await getGradeDetailsWithSalesType({
                    gradeName: this.userGradeName,
                    salesType: 'Domestic'
                });

                if (gradeDetails.success) {
                    // Update ALL allowances based on city type
                    if (this.isAClassCity) {
                        // Use A Class city rates
                        this.dailyAllowance = gradeDetails.dailyAllowance || 0;
                        this.lodgingHotel = gradeDetails.lodgingHotel || 0;
                        this.boardingFood = gradeDetails.boardingFood || 0;
                    } else {
                        // Use B Class city rates
                        this.dailyAllowance = gradeDetails.dailyAllowanceBClass || gradeDetails.dailyAllowance || 0;
                        this.lodgingHotel = gradeDetails.lodgingHotelBClass || gradeDetails.lodgingHotel || 0;
                        this.boardingFood = gradeDetails.boardingFoodBClass || gradeDetails.boardingFood || 0;
                    }

                    console.log('Updated allowances based on city type - A Class:', this.isAClassCity);
                    console.log('Daily Allowance:', this.dailyAllowance);
                    console.log('Lodging Hotel:', this.lodgingHotel);
                    console.log('Boarding Food:', this.boardingFood);

                    // Update all line items with new daily allowance
                    this.lineItems = this.lineItems.map(item => {
                        const updatedItem = {
                            ...item,
                            dailyAllowance: this.dailyAllowance
                        };

                        // Recalculate total
                        updatedItem.total = this.calculateLineItemTotal(updatedItem);

                        // Update limitation text
                        updatedItem.limitationText = this.computeLimitationText(updatedItem);

                        return updatedItem;
                    });
                }
            } catch (error) {
                console.error('Error updating allowances based on city:', error);
            }
        }
    }

    // NEW: Refresh all limitation texts
    refreshAllLimitationTexts() {
        this.lineItems = this.lineItems.map(item => {
            const limitationText = this.computeLimitationText(item);
            return {
                ...item,
                limitationText: limitationText
            };
        });
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

        // Auto-set KM rate based on transport mode
        let kmRate = 0;
        if (transportMode === 'Car') {
            kmRate = this.fourWheelerPerKm || 0;
        } else if (transportMode === 'Bike') {
            kmRate = this.twoWheelerPerKm || 0;
        }

        // Update the appropriate transport mode field
        if (type === 'local') {
            this.updateLineItem(index, 'transportMode', transportMode);
            this.updateLineItem(index, 'kmRate', kmRate);

            // Auto-calculate amount claimed for Local voucher
            if (this.selectedVoucherType === 'Local') {
                const calculatedAmount = this.calculateAmountClaimedForLocal({
                    ...this.lineItems[index],
                    transportMode: transportMode,
                    kmRate: kmRate
                });
                this.updateLineItem(index, 'amountClaimed', calculatedAmount);
                this.updateCalculatedAmountDisplay(index);
            }
        } else {
            this.updateLineItem(index, 'outstationTransportMode', transportMode);
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
        const transportOptions = this.getTransportOptionsForItem('', this.selectedVoucherType);
        console.log('Adding new line item with transport options:', transportOptions);

        const initialAmountClaimed = 0;
        const initialDailyAllowance = this.dailyAllowance || 0;
        const initialTotal = initialAmountClaimed + initialDailyAllowance;

        // Pre-compute disabled states
        const computedTransportDisabled = false;
        const computedLocationDisabled = false;
        const limitationText = ''; // Initialize limitation text

        const newItem = {
            key: this.nextKey++,
            typeOfExpenseId: '',
            amountClaimed: initialAmountClaimed,
            dailyAllowance: initialDailyAllowance,
            total: initialTotal,
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
            isFoodOrHotel: false,
            transportOptions: transportOptions,
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
            disableDailyAllowance: !this.canEditDailyAllowance,
            calculatedAmountDisplay: '0.00',
            modeOfTravel: '',
            disableTransportFields: false,
            disableTransportMode: false,
            // Pre-computed disabled states
            computedTransportDisabled: computedTransportDisabled,
            computedLocationDisabled: computedLocationDisabled,
            // Add limitation text
            limitationText: limitationText
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

        // This will automatically trigger total calculation in updateLineItem
        this.updateLineItem(idx, 'dailyAllowance', value);
    }

    updateCalculatedAmountDisplay(index) {
        const item = this.lineItems[index];
        if (this.selectedVoucherType === 'Local') {
            const calculatedAmount = this.calculateAmountClaimedForLocal(item);
            const calculatedAmountDisplay = calculatedAmount.toFixed(2);
            this.updateLineItem(index, 'calculatedAmountDisplay', calculatedAmountDisplay);
        }
    }

    getLimitationText(item) {
        if (!this.showLimitation || !item.typeOfExpenseId) {
            return '';
        }

        const expenseType = this.typeOfExpenseOptions.find(opt => opt.value === item.typeOfExpenseId);
        if (!expenseType || !expenseType.label) {
            return '';
        }

        const label = expenseType.label.toLowerCase();
        let limitation = '';

        if (label.includes('hotel')) {
            limitation = `Limit: ${this.currencySymbol}${this.lodgingHotel}`;
        } else if (label.includes('food')) {
            limitation = `Limit: ${this.currencySymbol}${this.boardingFood}`;
        }

        return limitation;
    }

    async handleVoucherTypeChange(event) {
        this.selectedVoucherType = event.detail.value;
        this.selectedTourId = '';
        this.selectedTourName = '';

        // Reset currency if not Export
        if (this.salesType !== 'Export') {
            this.selectedCurrency = 'INR';
        }

        try {
            this.isLoading = true;
            this.typeOfExpenseOptions = await getTypeOfExpense({
                searchTerm: '',
                voucherType: this.selectedVoucherType
            });

            console.log('=== Voucher type changed to:', this.selectedVoucherType);

            // Update transport modes for Export if applicable
            if (this.isExportOutstation) {
                await this.updateExportTransportModes();
            }

            // Force update all line items with correct transport options
            this.lineItems = this.lineItems.map(item => {
                const transportOptions = this.getTransportOptionsForItem('', this.selectedVoucherType);
                console.log('Setting transport options for item:', transportOptions);

                return {
                    ...item,
                    typeOfExpenseId: '',
                    reason: '',
                    fromLocation: '',
                    toLocation: '',
                    transportOptions: transportOptions,
                    transportMode: '',
                    outstationTransportMode: '',
                    startKM: '',
                    endKM: '',
                    kmRate: 0,
                    tollParking: 0,
                    showTollParking: false,
                    outstationFromLocation: '',
                    outstationToLocation: '',
                    ticketBookedByCompany: false,
                    outstationDescription: '',
                    outstationReason: '',
                    cashDescription: '',
                    glCodeId: '',
                    glCodeName: '',
                    remark: '',
                    modeOfTravel: '',
                    disableTransportFields: false,
                    // Preserve daily allowance for Local and Outstation vouchers
                    dailyAllowance: (this.selectedVoucherType === 'Local' || this.selectedVoucherType === 'Outstation') ?
                        (item.dailyAllowance || this.dailyAllowance) : 0,
                    disableDailyAllowance: !this.canEditDailyAllowance
                };
            });

        } catch (error) {
            console.error('Error in handleVoucherTypeChange:', error);
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
                CurrencyIsoCode: this.selectedCurrency,
                City__c: this.selectedCityId
            };

            const lineItemsToSend = this.lineItems.map(item => ({
                Type_of_Expense__c: item.typeOfExpenseId,
                Amount_Claimed__c: item.amountClaimed,
                Amount_Passed__c: item.amountClaimed,
                Daily_Allowance__c: (this.selectedVoucherType === 'Local' || this.selectedVoucherType === 'Outstation') ? item.dailyAllowance : null,
                Reason__c: this.selectedVoucherType === 'Misc' ? item.reason :
                    (this.selectedVoucherType === 'Outstation' ? item.outstationReason : null),
                From_Location__c: this.selectedVoucherType === 'Local' ? item.fromLocation :
                    (this.selectedVoucherType === 'Outstation' ? item.outstationFromLocation : null),
                To_Location__c: this.selectedVoucherType === 'Local' ? item.toLocation :
                    (this.selectedVoucherType === 'Outstation' ? item.outstationToLocation : null),
                Mode_of_Transport__c: this.selectedVoucherType === 'Local' ? item.transportMode :
                    (this.selectedVoucherType === 'Outstation' ? item.outstationTransportMode : null),
                Mode_of_Travel__c: this.showModeOfTravelField ? item.modeOfTravel : null,
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
                    // if (!item.outstationFromLocation || item.outstationFromLocation.trim() === '') {
                    //     this.showToast('Error', `Enter From Location for Outstation expense in row ${i + 1}`, 'error');
                    //     return false;
                    // }
                    // if (!item.outstationToLocation || item.outstationToLocation.trim() === '') {
                    //     this.showToast('Error', `Enter To Location for Outstation expense in row ${i + 1}`, 'error');
                    //     return false;
                    // }
                    // if (!isFood && !item.outstationTransportMode) {
                    //     this.showToast('Error', `Select Transport Mode for Outstation expense in row ${i + 1}`, 'error');
                    //     return false;
                    // }

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