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
import checkAllowanceEligibilityForDate from '@salesforce/apex/ExpenseController.checkAllowanceEligibilityForDate';
import checkMultipleDatesAllowanceEligibility from '@salesforce/apex/ExpenseController.checkMultipleDatesAllowanceEligibility';
import createExpenseTeamMembers from '@salesforce/apex/ExpenseController.createExpenseTeamMembers';
import getCombinedAllowances from '@salesforce/apex/ExpenseController.getCombinedAllowances';
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
    @track lineItems = [];
    @track filesMap = new Map(); // Store files by line item index
    @track selectedTourId = ''; // Add this
    @track selectedTourName = ''; // Add this
    @track selectedAccounts = []; // Track multiple selected accounts   
    @track visitReportId = '';
    @track visitReportName = '';
    @track isDailyAllowanceEligible = false;
    @track isOutOfPocketEligible = false;
    @track outOfPocket = 0;
    @track specialAllowance = 0;
    @track isFilePreviewModalOpen = false;
    @track currentPreviewFiles = [];
    @track currentPreviewIndex = -1;
    @track selectedTeamMembers = [];
    @track selectedTeamMemberIds = [];
    @track lineItemCombinedLimits = new Map();
    @track lineItemDatesMap = new Map(); 
    @track batchEligibilityLoading = false;

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

    get showDateFieldForLocal() {
        return this.selectedVoucherType === 'Local';
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

    get showKMFields() {
        return this.selectedVoucherType === 'Local' || 
            (this.selectedVoucherType === 'Outstation' && 
                this.lineItems.some(item => 
                    item.outstationTransportMode === 'Car' || 
                    item.outstationTransportMode === 'Bike'
                ));
    }

    get showTollParkingField() {
        return this.selectedVoucherType === 'Local' || 
           (this.selectedVoucherType === 'Outstation' && 
            this.lineItems.some(item => 
                item.outstationTransportMode === 'Car' || 
                item.outstationTransportMode === 'Bike'
            ));
    }

    // Also update showKMOrTollParkingField:
    get showKMOrTollParkingField() {
        return this.selectedVoucherType === 'Local' || 
            (this.selectedVoucherType === 'Outstation' && 
                this.lineItems.some(item => 
                    item.outstationTransportMode === 'Car' || 
                    item.outstationTransportMode === 'Bike' ||
                    item.modeOfTravel === 'Own Vehicle'
                ));
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
    cachedLimitation = false;
    get showLimitation() {
        if (this.cachedLimitation !== (this.isExportOutstation || this.isDomesticOutstation)) {
            this.cachedLimitation = this.isExportOutstation || this.isDomesticOutstation;
        }
        return this.cachedLimitation;
    }   

    get showCityField() {
        return this.salesType === 'Domestic';
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

    // Add currency change handler
    handleCurrencyChange(event) {
        this.selectedCurrency = event.detail.value;
    }

    async handleTeamMembersChange(event) {
        this.selectedTeamMembers = event.detail.selectedUsers;
        this.selectedTeamMemberIds = event.detail.selectedUserIds;
        console.log('Team members selected:', this.selectedTeamMembers);
        console.log('Team member IDs:', this.selectedTeamMemberIds);
        console.log('Expense Owner ID:', this.selectedEmployeeId);
        
        // Clear previous limits
        this.lineItemCombinedLimits.clear();
        
        // Recalculate combined limits for all line items
        await this.calculateAllCombinedLimits();
        
        // Refresh all limitation texts
        this.refreshAllLimitationTexts();
        
        // Show debug info
        console.log('Line Item Combined Limits:', this.lineItemCombinedLimits);
    }

    logCombinedLimitDetails() {
    console.log('=== COMBINED LIMIT CALCULATION DETAILS ===');
    console.log('Expense Owner ID:', this.selectedEmployeeId);
    console.log('Team Member IDs:', this.selectedTeamMemberIds);
    console.log('Total Users:', 1 + (this.selectedTeamMemberIds ? this.selectedTeamMemberIds.length : 0));
    console.log('City Type:', this.selectedCityType);
    console.log('Sales Type:', this.salesType);
    console.log('Line Item Combined Limits Map:', this.lineItemCombinedLimits);
    
    // Log each line item's combined limit
    this.lineItems.forEach((item, index) => {
        const limit = this.lineItemCombinedLimits.get(index) || 0;
        const expenseType = this.typeOfExpenseOptions.find(opt => opt.value === item.typeOfExpenseId);
        console.log(`Line Item ${index} [${expenseType?.label}]: ${this.currencySymbol}${limit}`);
    });
}

    async calculateAllCombinedLimits() {
    // Clear previous limits
        this.lineItemCombinedLimits.clear();
        
        // Calculate for each line item that has food/hotel expense type
        for (let i = 0; i < this.lineItems.length; i++) {
            const item = this.lineItems[i];
            if (item.typeOfExpenseId) {
                await this.calculateCombinedLimitForItem(i);
            }
        }
        this.logCombinedLimitDetails();
    }

    async calculateCombinedLimitForItem(index) {
        const item = this.lineItems[index];
        if (!item.typeOfExpenseId) return;
        
        const expenseType = this.typeOfExpenseOptions.find(opt => opt.value === item.typeOfExpenseId);
        if (!expenseType || !expenseType.label) return;
        
        const label = expenseType.label.toLowerCase();
        const isHotelExpense = label.includes('hotel');
        const isFoodExpense = label.includes('food');
        
        if (!isHotelExpense && !isFoodExpense) {
            this.lineItemCombinedLimits.set(index, 0);
            return;
        }
        
        try {
            const expenseTypeName = isHotelExpense ? 'Hotel' : 'Food';
            
            // Calculate combined limit for ALL users (expense owner + team members)
            const combinedLimit = await getCombinedAllowances({
                expenseOwnerId: this.selectedEmployeeId,
                teamMemberIds: this.selectedTeamMemberIds,
                cityType: this.selectedCityType || 'A Class City',
                salesType: this.salesType,
                expenseType: expenseTypeName
            });
            
            console.log(`Combined limit for line item ${index}:`, combinedLimit);
            console.log('Expense Owner:', this.selectedEmployeeId);
            console.log('Team Members:', this.selectedTeamMemberIds);
            console.log('Total Users:', 1 + this.selectedTeamMemberIds.length);
            
            // Store the combined limit for this line item
            this.lineItemCombinedLimits.set(index, combinedLimit);
            
        } catch (error) {
            console.error('Error calculating combined limit for line item:', error);
            this.lineItemCombinedLimits.set(index, 0);
        }
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
        // Recalculate combined limits with new sales type
        await this.calculateAllCombinedLimits();

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
                // Store the original Out of Pocket and Special Allowance values
                const originalOutOfPocket = this.outOfPocket;
                const originalSpecialAllowance = this.specialAllowance;
                
                // Store ALL rates (both A and B Class)
                this.dailyAllowance = gradeDetails.dailyAllowance || 0;
                this.dailyAllowanceBClass = gradeDetails.dailyAllowanceBClass || gradeDetails.dailyAllowance || 0;
                this.fourWheelerPerKm = gradeDetails.fourWheelerPerKm || 0;
                this.twoWheelerPerKm = gradeDetails.twoWheelerPerKm || 0;
                this.lodgingHotel = gradeDetails.lodgingHotel || 0;
                this.boardingFood = gradeDetails.boardingFood || 0;
                this.lodgingHotelBClass = gradeDetails.lodgingHotelBClass || gradeDetails.lodgingHotel || 0;
                this.boardingFoodBClass = gradeDetails.boardingFoodBClass || gradeDetails.boardingFood || 0;
                this.canEditDailyAllowance = gradeDetails.canEditDailyAllowance || false;

                // PRESERVE Out of Pocket and Special Allowance - only update if not already set
                if (this.outOfPocket === 0 || originalOutOfPocket === 0) {
                    this.outOfPocket = gradeDetails.outOfPocket || 0;
                }
                if (this.specialAllowance === 0 || originalSpecialAllowance === 0) {
                    this.specialAllowance = gradeDetails.specialAllowance || 0;
                }

                console.log('All allowances loaded - Out of Pocket:', this.outOfPocket, 'Special Allowance:', this.specialAllowance);

                // Rest of your existing method remains the same...
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
                this.lineItems = this.lineItems.map((item, index) => {
                    const transportOptions = this.getTransportOptionsForItem(item.typeOfExpenseId);
                    const limitationText = this.computeLimitationText(item);

                    console.log('Updating line item with new grade data from sales type');

                    return {
                        ...item,
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

            this.employeeOptions = await getUsers({ searchTerm: '' });
            this.typeOfExpenseOptions = await getTypeOfExpense({
                searchTerm: '',
                voucherType: null
            });

            // Update line items with grade data and correct transport options
            this.lineItems = this.lineItems.map((item, index) => {
                const transportOptions = this.getTransportOptionsForItem('', this.selectedVoucherType);
                console.log('Initializing line item with transport options:', transportOptions);

                return {
                    ...item,
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

    // UPDATE the getTransportOptionsForItem method:
    getTransportOptionsForItem(typeOfExpenseId, voucherType = this.selectedVoucherType, modeOfTravel = '') {
        console.log('=== getTransportOptionsForItem called ===');
        console.log('Voucher type:', voucherType);
        console.log('Sales Type:', this.salesType);
        console.log('Expense type ID:', typeOfExpenseId);
        console.log('Mode of Travel:', modeOfTravel);

        let baseOptions = [];

        // CRITICAL FIX: For Outstation Domestic - use Mode_of_Outstation_Travel__c from grade
        if (voucherType === 'Outstation' && this.salesType === 'Domestic') {
            console.log('Processing Outstation Domestic voucher type');
            
            // Use Mode_of_Outstation_Travel__c options from grade
            if (this.modeOfOutstationTravelOptions && this.modeOfOutstationTravelOptions.length > 0) {
                baseOptions = this.modeOfOutstationTravelOptions;
                console.log('Using Mode_of_Outstation_Travel__c options:', baseOptions);
            } else {
                // Fallback to all transport modes if no grade-specific options
                baseOptions = this.allTransportModeOptions;
                console.log('Using fallback transport modes for Outstation Domestic');
            }
        }
        // For Outstation Export - use Mode_of_Travel__c from grade with Sales_Type__c = 'Export'
        else if (voucherType === 'Outstation' && this.salesType === 'Export') {
            console.log('Processing Outstation Export voucher type');
            baseOptions = this.gradeTransportModeOptions.length > 0 ? 
                this.gradeTransportModeOptions : this.allTransportModeOptions;
        }
        // For other voucher types (Local, Special, Cash, Misc)
        else {
            baseOptions = this.gradeTransportModeOptions.length > 0 ?
                this.gradeTransportModeOptions : this.allTransportModeOptions;
        }

        console.log('Base options before filtering:', baseOptions);

        // Apply Mode of Travel filtering if specified (for Outstation Domestic)
        if (modeOfTravel && voucherType === 'Outstation' && this.salesType === 'Domestic') {
            if (modeOfTravel === 'Own Vehicle') {
                baseOptions = baseOptions.filter(mode => 
                    mode.value === 'Car' || mode.value === 'Bike' || mode.value === 'Own Vehicle'
                );
                console.log('Filtered for Own Vehicle:', baseOptions);
            } else if (modeOfTravel === 'Public Transport') {
                baseOptions = baseOptions.filter(mode => 
                    mode.value !== 'Bike' && mode.value !== 'Own Vehicle'
                );
                console.log('Filtered for Public Transport:', baseOptions);
            }
        }

        // Apply expense type filtering (only if no mode of travel filtering applied)
        if (!typeOfExpenseId || modeOfTravel) {
            console.log('No expense type ID or mode of travel applied, returning base options');
            return baseOptions;
        }

        const expenseType = this.typeOfExpenseOptions.find(opt => opt.value === typeOfExpenseId);
        if (!expenseType) {
            console.log('Expense type not found, returning base options');
            return baseOptions;
        }

        console.log('Expense type found:', expenseType.name);

        // Only apply expense type filtering for Local vouchers
        if (voucherType === 'Local') {
            if (expenseType.name === 'Public') {
                const publicModes = baseOptions.filter(mode => mode.value === 'Bus');
                console.log('Filtered for Public expense:', publicModes);
                return publicModes;
            } else if (expenseType.name === 'Private') {
                const privateModes = baseOptions.filter(mode => mode.value === 'Car' || mode.value === 'Bike');
                console.log('Filtered for Private expense:', privateModes);
                return privateModes;
            }
        }

        console.log('No specific filtering, returning base options');
        return baseOptions;
    }

    // ENHANCE the openFilePreviewModal method to use stored file names
    openFilePreviewModal(event) {
        const idx = parseInt(event.currentTarget.dataset.index, 10);
        const item = this.lineItems[idx];
        const key = item.key;
        
        if (this.filesMap.has(key)) {
            const documentIds = this.filesMap.get(key);
            console.log('Opening file preview for line item', idx, 'Document IDs:', documentIds);
            
            if (documentIds && documentIds.length > 0) {
                // Use stored file details if available, otherwise create basic file objects
                let fileDetails = [];
                if (this.fileDetailsMap && this.fileDetailsMap.has(key)) {
                    fileDetails = this.fileDetailsMap.get(key);
                } else {
                    // Fallback to basic file objects
                    fileDetails = documentIds.map(docId => ({
                        documentId: docId,
                        name: `File_${docId.substring(0, 8)}`
                    }));
                }
                
                this.currentPreviewFiles = fileDetails;
                this.currentPreviewIndex = idx;
                this.isFilePreviewModalOpen = true;
            } else {
                this.showToast('Info', 'No files to preview', 'info');
            }
        } else {
            this.showToast('Info', 'No files uploaded for this line item', 'info');
        }
    }

    // ADD this method for direct preview from modal:
    handleModalFilePreview(event) {
        const fileId = event.currentTarget.dataset.fileId;
        
        if (fileId) {
            // Use Salesforce file preview page
            this[NavigationMixin.Navigate]({
                type: 'standard__namedPage',
                attributes: {
                    pageName: 'filePreview'
                },
                state: {
                    selectedRecordId: fileId
                }
            });
            
            // Close the modal after opening preview
            this.closeFilePreviewModal();
        }
    }

    // Method to close file preview modal
    closeFilePreviewModal() {
        this.isFilePreviewModalOpen = false;
        this.currentPreviewFiles = [];
        this.currentPreviewIndex = -1;
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
                        this.specialAllowance = gradeDetails.specialAllowance || 0;
                        this.outOfPocket = gradeDetails.outOfPocket || 0;
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
                        this.lineItems = this.lineItems.map((item, index) => {
                            const transportOptions = this.getTransportOptionsForItem(item.typeOfExpenseId);
                            
                            const updatedItem = {
                                ...item,
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

            // Recalculate combined limits with new expense owner
            await this.calculateAllCombinedLimits();
            this.refreshAllLimitationTexts();

            await this.checkAllLineItemsEligibility();
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
    getUpdatedKMRateForItem(item, voucherType = this.selectedVoucherType) {
        const transportMode = voucherType === 'Local' ? 
            item.transportMode : item.outstationTransportMode;
        
        if (transportMode === 'Car') {
            return this.fourWheelerPerKm || 0;
        } else if (transportMode === 'Bike') {
            return this.twoWheelerPerKm || 0;
        }
        return item.kmRate || 0;
    }

    calculateAmountClaimedForOutstation(item) {
        // Only calculate for Car/Bike transport modes
        const transportMode = item.outstationTransportMode;
        
        if (transportMode !== 'Car' && transportMode !== 'Bike') {
            return parseFloat(item.amountClaimed) || 0;
        }
        
        const startKM = parseFloat(item.startKM) || 0;
        const endKM = parseFloat(item.endKM) || 0;
        const kmRate = parseFloat(item.kmRate) || 0;
        const tollParking = parseFloat(item.tollParking) || 0;
        
        // Calculate: (End KM - Start KM) * KM Rate + Toll Parking
        const distance = endKM - startKM;
        if (distance < 0) return 0;
        
        const calculatedAmount = (distance * kmRate) + tollParking;
        return Math.max(0, calculatedAmount);
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

    async handleTypeOfExpenseChange(event) {
        const idx = parseInt(event.currentTarget.dataset.index, 10);
        const value = event.detail.value;

        console.log('Type of expense changed for index:', idx);
        console.log('Selected expense type ID:', value);

        const expenseType = this.typeOfExpenseOptions.find(opt => opt.value === value);
        const isPrivate = expenseType && expenseType.name === 'Private';
        const isPublic = expenseType && expenseType.name === 'Public';
        const isFoodOrHotel = this.isFoodOrHotelExpense(value);
        const isOwnArrangement = expenseType && expenseType.label && expenseType.label.toLowerCase().includes('own arrangement');
        const isMandatory = expenseType && expenseType.isMandatory === 'true';
        

        // Update line item
        this.updateLineItem(idx, 'typeOfExpenseId', value);
        this.updateLineItem(idx, 'isPrivate', isPrivate);
        this.updateLineItem(idx, 'isPublic', isPublic);
        this.updateLineItem(idx, 'isFoodOrHotel', isFoodOrHotel);
        this.updateLineItem(idx, 'isOwnArrangement', isOwnArrangement);
        this.updateLineItem(idx, 'isMandatory', isMandatory);
        this.updateLineItem(idx, 'typeOfExpenseName', expenseType ? expenseType.label : '');

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

        // Auto-set Special Allowance for Own Arrangement expense types when Out of Pocket is eligible
        if (isOwnArrangement) {
            console.log('Own Arrangement expense detected, setting Special Allowance:', this.specialAllowance);
            this.updateLineItem(idx, 'amountClaimed', this.specialAllowance);
        } else if (!isOwnArrangement) {
            // Reset amount claimed if not Own Arrangement (unless user manually entered)
            const currentItem = this.lineItems[idx];
            if (currentItem.amountClaimed === this.specialAllowance) {
                this.updateLineItem(idx, 'amountClaimed', 0);
            }
        }

        // Calculate combined limit for this specific line item
        if (isFoodOrHotel) {
            await this.calculateCombinedLimitForItem(idx);
        }

        // Update limitation text
        const limitationText = this.computeLimitationText({
            ...this.lineItems[idx],
            typeOfExpenseId: value
        }, idx);
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
        
        // Auto-calculate amount for both Local and Outstation
        if (this.selectedVoucherType === 'Local' || this.selectedVoucherType === 'Outstation') {
            const calculatedAmount = this.calculateAmountClaimed({
                ...this.lineItems[idx],
                tollParking: value
            });
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
        
        this.updateLineItem(idx, 'startKM', value);
        
        // Auto-calculate amount for both Local and Outstation
        if (this.selectedVoucherType === 'Local' || this.selectedVoucherType === 'Outstation') {
            const calculatedAmount = this.calculateAmountClaimed({
                ...this.lineItems[idx],
                startKM: value
            });
            this.updateLineItem(idx, 'amountClaimed', calculatedAmount);
        }
    }

    handleEndKMChange(event) {
        const idx = parseInt(event.target.dataset.index, 10);
        const value = parseFloat(event.target.value) || 0;

        this.updateLineItem(idx, 'endKM', value);

        // Auto-calculate amount for BOTH Local AND Outstation
        if (this.selectedVoucherType === 'Local' || this.selectedVoucherType === 'Outstation') {
            const item = this.lineItems[idx];
            const transportMode = this.selectedVoucherType === 'Local' ? 
                item.transportMode : item.outstationTransportMode;
            
            // Only calculate if it's Car or Bike (not Bus/Train/Flight)
            if (transportMode === 'Car' || transportMode === 'Bike') {
                const calculatedAmount = this.calculateAmountClaimed({
                    ...item,
                    endKM: value
                });
                this.updateLineItem(idx, 'amountClaimed', calculatedAmount);
            }
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

    updateLineItem(index, field, value) {
        this.lineItems = this.lineItems.map((item, i) => {
            if (i === index) {
                const updatedItem = { ...item, [field]: value };
                
                // When date changes, reset eligibility and trigger check
                if (field === 'date' || field === 'outstationDate') {
                    updatedItem.isDailyAllowanceEligible = false;
                    updatedItem.isOutOfPocketEligible = false;
                    updatedItem.eligibilityChecked = false;
                    
                    // Schedule eligibility check
                    if (value && this.selectedEmployeeId) {
                        setTimeout(() => {
                            this.checkLineItemDateEligibility(index);
                        }, 100);
                    }
                }
                
                // Recompute disabled states
                if (field === 'disableTransportFields' || field === 'disableTransportMode' || field === 'isFoodOrHotel') {
                    updatedItem.computedTransportDisabled = updatedItem.disableTransportFields || updatedItem.disableTransportMode;
                    updatedItem.computedLocationDisabled = updatedItem.disableTransportFields;
                }
                
                // Recalculate total
                if (field === 'amountClaimed' || field === 'dailyAllowance') {
                    updatedItem.total = this.calculateLineItemTotal(updatedItem);
                }
                
                // Update limitation text
                if (field === 'typeOfExpenseId') {
                    updatedItem.limitationText = this.computeLimitationText(updatedItem);
                }
                
                return updatedItem;
            }
            return item;
        });
    }

    computeLimitationText(item, index) {
        if (!this.showLimitation || !item.typeOfExpenseId) {
            return '';
        }

        const expenseType = this.typeOfExpenseOptions.find(opt => opt.value === item.typeOfExpenseId);
        if (!expenseType || !expenseType.label) {
            return '';
        }

        const label = expenseType.label.toLowerCase();
        const isHotelExpense = label.includes('hotel');
        const isFoodExpense = label.includes('food');
        
        if (!isHotelExpense && !isFoodExpense) {
            return '';
        }

        // Get the combined limit for this line item (SUM of all users)
        const combinedLimit = this.lineItemCombinedLimits.get(index) || 0;
        
        // Calculate total users (expense owner + team members)
        const totalUsers = 1 + (this.selectedTeamMemberIds ? this.selectedTeamMemberIds.length : 0);
        
        // Build limitation text showing TOTAL SUM
        let limitation = `Total Limit: ${this.currencySymbol}${combinedLimit.toFixed(2)}`;
        limitation += ` (${totalUsers} user${totalUsers > 1 ? 's combined' : ''})`;
        
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
                // Recalculate combined limits with new city type
                await this.calculateAllCombinedLimits();

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

                    const originalOutOfPocket = this.outOfPocket;
                    const originalSpecialAllowance = this.specialAllowance;

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

                    this.outOfPocket = originalOutOfPocket;
                    this.specialAllowance = originalSpecialAllowance;

                    console.log('Updated allowances based on city type - A Class:', this.isAClassCity);
                    console.log('Daily Allowance:', this.dailyAllowance);
                    console.log('Lodging Hotel:', this.lodgingHotel);
                    console.log('Boarding Food:', this.boardingFood);

                    // FIXED: Update line items with RESPECT to eligibility
                    this.lineItems = this.lineItems.map((item, index) => {
                        const isFirstItem = index === 0;
                    
                        // Determine correct allowance based on voucher type and eligibility
                        let dailyAllowanceValue = 0;
                        if (this.selectedVoucherType === 'Outstation' && isFirstItem && this.isOutOfPocketEligible) {
                            dailyAllowanceValue = this.outOfPocket || 0;
                        } else if (this.selectedVoucherType === 'Local' && isFirstItem && this.isDailyAllowanceEligible) {
                            dailyAllowanceValue = this.dailyAllowance || 0;
                        }

                        const updatedItem = {
                            ...item,
                            dailyAllowance: dailyAllowanceValue
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

        refreshAllLimitationTexts() {
        this.lineItems = this.lineItems.map((item, index) => {
            const limitationText = this.computeLimitationText(item, index);
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

        // For Outstation, use outstationDate for eligibility check
        if (value && this.selectedEmployeeId) {
            setTimeout(() => {
                this.checkLineItemDateEligibility(idx);
            }, 100);
        }
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

    getKMRateForTransportMode(transportMode) {
        if (transportMode === 'Car') {
            return this.fourWheelerPerKm || 0;
        } else if (transportMode === 'Bike') {
            return this.twoWheelerPerKm || 0;
        }
        return 0; // Bus or other modes have 0 KM rate
    }

    // 2. Unified amount calculation
    calculateAmountClaimed(item) {
        if (this.selectedVoucherType === 'Local') {
            return this.calculateAmountClaimedForLocal(item);
        } else if (this.selectedVoucherType === 'Outstation') {
            return this.calculateAmountClaimedForOutstation(item);
        }
        return parseFloat(item.amountClaimed) || 0;
    }

    // REVISED METHOD - FIX KM rate population
    handleOutstationTransportModeChange(event) {
        const idx = parseInt(event.currentTarget.dataset.index, 10);
        const value = event.detail.value;
        
        // Update transport mode
        this.updateLineItem(idx, 'outstationTransportMode', value);
        
        // Auto-update KM rate FROM GRADE
        let kmRate = 0;
        if (value === 'Car') {
            kmRate = this.fourWheelerPerKm || 0;
        } else if (value === 'Bike') {
            kmRate = this.twoWheelerPerKm || 0;
        }
        
        this.updateLineItem(idx, 'kmRate', kmRate);
        
        // Update KM field states
        const disableKM = (value === 'Bus');
        this.updateLineItem(idx, 'disableKMFields', disableKM);
        
        // Update toll/parking field visibility
        const showTollParking = this.shouldShowTollParking(value);
        this.updateLineItem(idx, 'showTollParking', showTollParking);
        this.updateLineItem(idx, 'disableTollParking', !showTollParking);
        
        // Clear toll/parking if not applicable
        if (!showTollParking) {
            this.updateLineItem(idx, 'tollParking', 0);
        }
        
        // Auto-calculate amount for Outstation
        if (this.selectedVoucherType === 'Outstation') {
            const calculatedAmount = this.calculateAmountClaimedForOutstation({
                ...this.lineItems[idx],
                outstationTransportMode: value,
                kmRate: kmRate
            });
            this.updateLineItem(idx, 'amountClaimed', calculatedAmount);
        }
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
        
        if (type === 'local') {
            this.updateLineItem(index, 'transportMode', transportMode);
        } else {
            this.updateLineItem(index, 'outstationTransportMode', transportMode);
        }
        
        // Update KM rate for both Local AND Outstation
        this.updateLineItem(index, 'kmRate', kmRate);
        
        // Auto-calculate amount claimed based on voucher type
        if (this.selectedVoucherType === 'Local') {
            const calculatedAmount = this.calculateAmountClaimedForLocal({
                ...this.lineItems[index],
                transportMode: transportMode,
                kmRate: kmRate
            });
            this.updateLineItem(index, 'amountClaimed', calculatedAmount);
        } else if (this.selectedVoucherType === 'Outstation') {
            const calculatedAmount = this.calculateAmountClaimedForOutstation({
                ...this.lineItems[index],
                outstationTransportMode: transportMode,
                kmRate: kmRate
            });
            this.updateLineItem(index, 'amountClaimed', calculatedAmount);
        }
        
        // Handle KM field disabling
        const disableKM = (transportMode === 'Bus');
        this.updateLineItem(index, 'disableKMFields', disableKM);
        
        // Toll/Parking visible only for Car/Bike for BOTH Local and Outstation
        const showTollParking = this.shouldShowTollParking(transportMode);
        this.updateLineItem(index, 'showTollParking', showTollParking);
        this.updateLineItem(index, 'disableTollParking', !showTollParking);
        
        if (!showTollParking) {
            this.updateLineItem(index, 'tollParking', 0);
        }
        
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

    addLineItem() {
        const transportOptions = this.getTransportOptionsForItem('', this.selectedVoucherType);
        console.log('Adding new line item with transport options:', transportOptions);

        const defaultDate = this.todayDate;

        // Determine if this line item should have allowances
        const isFirstItem = this.lineItems.length === 0;
        
        // NEW LOGIC: Set allowances based on voucher type and eligibility
        let dailyAllowanceValue = 0;
        if (this.selectedVoucherType === 'Outstation' && isFirstItem && this.isOutOfPocketEligible) {
            dailyAllowanceValue = this.outOfPocket || 0;
        } else if (this.selectedVoucherType === 'Local' && isFirstItem && this.isDailyAllowanceEligible) {
            dailyAllowanceValue = this.dailyAllowance || 0;
        }

        const initialAmountClaimed = 0;
        const initialTotal = initialAmountClaimed + dailyAllowanceValue;

        // Pre-compute disabled states
        const computedTransportDisabled = false;
        const computedLocationDisabled = false;
        const limitationText = ''; // Initialize limitation text

        const newItem = {
            key: this.nextKey++,
            typeOfExpenseId: '',
            amountClaimed: initialAmountClaimed,
            dailyAllowance: 0,
            total: initialTotal,
            reason: '',
            fromLocation: '',
            toLocation: '',
            transportMode: '',
            startKM: '',
            endKM: '',
            tollParking: 0,
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
            date: this.selectedVoucherType === 'Local' ? defaultDate : null,
            outstationDate: this.selectedVoucherType === 'Outstation' ? defaultDate : null,
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
            disableDailyAllowance: true,
            calculatedAmountDisplay: '0.00',
            modeOfTravel: '', // Initialize Mode_of_Travel
            disableTransportFields: false,
            disableTransportMode: false,
            // Pre-computed disabled states
            computedTransportDisabled: computedTransportDisabled,
            computedLocationDisabled: computedLocationDisabled,
            // Add limitation text
            limitationText: limitationText,
            isOwnArrangement: false, // Initialize Own Arrangement flag
            isMandatory: false, // Initialize mandatory flag
            typeOfExpenseName: '',
            isDailyAllowanceEligible: false,
            isOutOfPocketEligible: false,
            eligibilityChecked: false
        };
        this.lineItems = [...this.lineItems, newItem];

        setTimeout(() => {
            this.checkLineItemDateEligibility(this.lineItems.length - 1);
        }, 100);
    }

    async checkLineItemDateEligibility(index) {
        const item = this.lineItems[index];
        // Use the appropriate date field based on voucher type
        const itemDate = this.selectedVoucherType === 'Local' ? item.date : item.outstationDate;
        if (!itemDate || !this.selectedEmployeeId) return;
        
        try {
            // Prepare current page line items data (excluding the current one)
            const currentPageLineItems = this.lineItems.map((li, idx) => ({
                id: idx === index ? null : `temp_${li.key}`, // Null for current item
                date: li.date,
                outstationDate: li.outstationDate,
                voucherType: this.selectedVoucherType,
                dailyAllowance: li.dailyAllowance,
                userId: this.selectedEmployeeId
            })).filter((li, idx) => idx !== index); // Exclude current item
            
            const result = await checkAllowanceEligibilityForDate({
                expenseDate: itemDate,
                userId: this.selectedEmployeeId,
                lineItemId: null, // Will be null for new line items
                currentPageLineItems: currentPageLineItems
            });
            
            console.log('Eligibility result for date', itemDate, ':', result);
            
            // Update line item with eligibility
            this.updateLineItem(index, 'isDailyAllowanceEligible', result.isDailyAllowanceEligible);
            this.updateLineItem(index, 'isOutOfPocketEligible', result.isOutOfPocketEligible);
            this.updateLineItem(index, 'eligibilityChecked', true);
            
            // Show toast messages based on eligibility AND voucher type
            if (this.selectedVoucherType === 'Local') {
                if (!result.isDailyAllowanceEligible && result.hasDailyAllowanceClaimed) {
                    this.showToast('Warning', 'Daily Allowance already claimed for this date', 'warning');
                }
                if (!result.isOutOfPocketEligible && result.hasOutOfPocketClaimed) {
                    this.showToast('Warning', 'Out of Pocket already claimed for this date', 'warning');
                }
            } else if (this.selectedVoucherType === 'Outstation') {
                if (!result.isOutOfPocketEligible && result.hasOutOfPocketClaimed) {
                    this.showToast('Warning', 'Out of Pocket already claimed for this date', 'warning');
                }
                if (!result.isDailyAllowanceEligible && result.hasDailyAllowanceClaimed) {
                    this.showToast('Warning', 'Daily Allowance already claimed for this date', 'warning');
                }
            }
            
            // Update allowances based on eligibility
            this.updateLineItemAllowances(index);
            
        } catch (error) {
            console.error('Error checking line item date eligibility:', error);
            this.showToast('Error', 'Failed to check allowance eligibility for this date', 'error');
        }
    }

    // NEW: Method to check eligibility for all line items at once (optimized)
    async checkAllLineItemsEligibility() {
        const dateUserIdMap = {};
        
        // Build map of date-user combinations
        this.lineItems.forEach((item, index) => {
            const itemDate = this.selectedVoucherType === 'Local' ? item.date : item.outstationDate;
            if (itemDate && this.selectedEmployeeId) {
                const key = `${itemDate}_${this.selectedEmployeeId}`;
                dateUserIdMap[key] = key;
            }
        });
        
        if (Object.keys(dateUserIdMap).length === 0) return;
        
        try {
            this.batchEligibilityLoading = true;
            
            // Prepare current page line items data
            const currentPageLineItems = this.lineItems.map((li, index) => ({
                id: `temp_${li.key}`,
                date: li.date,
                outstationDate: li.outstationDate,
                voucherType: this.selectedVoucherType,
                dailyAllowance: li.dailyAllowance,
                userId: this.selectedEmployeeId
            }));
            
            const results = await checkMultipleDatesAllowanceEligibility({
                dateUserIdMap: dateUserIdMap,
                currentPageLineItems: currentPageLineItems
            });
            
            // Track if we've shown any toast messages
            let hasShownToast = false;
            
            // Update each line item with its eligibility
            this.lineItems = this.lineItems.map((item, index) => {
                const itemDate = this.selectedVoucherType === 'Local' ? item.date : item.outstationDate;
                if (itemDate && this.selectedEmployeeId) {
                    const key = `${itemDate}_${this.selectedEmployeeId}`;
                    const eligibility = results[key];
                    
                    if (eligibility) {
                        // Show toast messages for the first eligible line item
                        if (!hasShownToast) {
                            if (this.selectedVoucherType === 'Local' && !eligibility.isDailyAllowanceEligible && eligibility.hasDailyAllowanceClaimed) {
                                this.showToast('Warning', 'Daily Allowance already claimed for this date', 'warning');
                                hasShownToast = true;
                            } else if (this.selectedVoucherType === 'Outstation' && !eligibility.isOutOfPocketEligible && eligibility.hasOutOfPocketClaimed) {
                                this.showToast('Warning', 'Out of Pocket already claimed for this date', 'warning');
                                hasShownToast = true;
                            }
                        }
                        
                        return {
                            ...item,
                            isDailyAllowanceEligible: eligibility.isDailyAllowanceEligible || false,
                            isOutOfPocketEligible: eligibility.isOutOfPocketEligible || false,
                            eligibilityChecked: true
                        };
                    }
                }
                return item;
            });
            
            // Update allowances for all line items
            this.updateAllLineItemsAllowances();
            
        } catch (error) {
            console.error('Error checking all line items eligibility:', error);
        } finally {
            this.batchEligibilityLoading = false;
        }
    }

    // NEW: Method to update allowances for a specific line item
    updateLineItemAllowances(index) {
        const item = this.lineItems[index];
        
        let dailyAllowanceValue = 0;
        let amountClaimedValue = item.amountClaimed || 0;
        
        // Determine allowances based on voucher type and line item eligibility
        if (this.selectedVoucherType === 'Outstation') {
            // For Outstation, use Out of Pocket if eligible
            if (item.isOutOfPocketEligible) {
                dailyAllowanceValue = this.outOfPocket || 0;
            }
        } else if (this.selectedVoucherType === 'Local') {
            // For Local, use Daily Allowance if eligible
            if (item.isDailyAllowanceEligible) {
                dailyAllowanceValue = this.dailyAllowance || 0;
            }
        }
        
        // Auto-set Special Allowance for Own Arrangement
        if (item.isOwnArrangement && this.outOfPocket > 0) {
            amountClaimedValue = this.specialAllowance || 0;
        } else if (!item.isOwnArrangement && item.typeOfExpenseId === '') {
            amountClaimedValue = 0;
        }
        
        this.updateLineItem(index, 'dailyAllowance', dailyAllowanceValue);
        this.updateLineItem(index, 'amountClaimed', amountClaimedValue);
        this.updateLineItem(index, 'disableDailyAllowance', 
            this.selectedVoucherType === 'Outstation' ? !item.isOutOfPocketEligible : !item.isDailyAllowanceEligible);
    }

    // NEW: Method to update allowances for all line items
    updateAllLineItemsAllowances() {
        this.lineItems = this.lineItems.map((item, index) => {
            const updatedItem = { ...item };
            
            let dailyAllowanceValue = 0;
            let amountClaimedValue = item.amountClaimed || 0;
            
            if (this.selectedVoucherType === 'Outstation') {
                if (item.isOutOfPocketEligible) {
                    dailyAllowanceValue = this.outOfPocket || 0;
                }
            } else if (this.selectedVoucherType === 'Local') {
                if (item.isDailyAllowanceEligible) {
                    dailyAllowanceValue = this.dailyAllowance || 0;
                }
            }
            
            if (item.isOwnArrangement && this.outOfPocket > 0) {
                amountClaimedValue = this.specialAllowance || 0;
            } else if (!item.isOwnArrangement && item.typeOfExpenseId === '') {
                amountClaimedValue = 0;
            }
            
            updatedItem.dailyAllowance = dailyAllowanceValue;
            updatedItem.amountClaimed = amountClaimedValue;
            updatedItem.disableDailyAllowance = 
                this.selectedVoucherType === 'Outstation' ? !item.isOutOfPocketEligible : !item.isDailyAllowanceEligible;
            
            // Recalculate total
            updatedItem.total = this.calculateLineItemTotal(updatedItem);
            
            return updatedItem;
        });
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

    handleDateChange(event) {
        const idx = parseInt(event.target.dataset.index, 10);
        const value = event.target.value;
        
        this.updateLineItem(idx, 'date', value);
        
        // Check eligibility for this date
        if (value && this.selectedEmployeeId) {
            setTimeout(() => {
                this.checkLineItemDateEligibility(idx);
            }, 100);
        }
    }

    async handleModeOfTravelChange(event) {
        const idx = parseInt(event.currentTarget.dataset.index, 10);
        const value = event.detail.value;

        console.log('Mode of Travel changed for index:', idx, 'Value:', value);
        this.updateLineItem(idx, 'modeOfTravel', value);
        
        // For Outstation Domestic, filter transport options based on Mode of Travel
        if (this.selectedVoucherType === 'Outstation' && this.salesType === 'Domestic') {
            await this.filterTransportOptionsByModeOfTravel(idx, value);
        }
    }

    async filterTransportOptionsByModeOfTravel(index, modeOfTravel) {
        let filteredTransportOptions = [];
        
        // Get base options for Outstation Domestic
        const baseOptions = this.getTransportOptionsForItem('', 'Outstation', '');
        
        if (modeOfTravel === 'Own Vehicle') {
            // Show only vehicle options for Own Vehicle
            filteredTransportOptions = baseOptions.filter(mode => 
                mode.value === 'Car' || mode.value === 'Bike' || mode.value === 'Own Vehicle'
            );
            console.log('Filtered transport options for Own Vehicle:', filteredTransportOptions);
        } else if (modeOfTravel === 'Public Transport') {
            // Exclude vehicle options for Public Transport
            filteredTransportOptions = baseOptions.filter(mode => 
                mode.value !== 'Bike' && mode.value !== 'Own Vehicle'
            );
            console.log('Filtered transport options for Public Transport:', filteredTransportOptions);
        } else {
            // Show all available options for the selected mode
            filteredTransportOptions = baseOptions;
            console.log('Showing all transport options for mode:', modeOfTravel, filteredTransportOptions);
        }
        
        // Update the line item with filtered transport options
        this.updateLineItem(index, 'transportOptions', filteredTransportOptions);
        
        // Clear transport mode if it's no longer valid in the filtered options
        const currentTransportMode = this.lineItems[index].outstationTransportMode;
        if (currentTransportMode && !filteredTransportOptions.some(opt => opt.value === currentTransportMode)) {
            this.updateLineItem(index, 'outstationTransportMode', '');
            console.log('Cleared invalid transport mode:', currentTransportMode);
        }
    }

    // UPDATE the handleFileUpload method to store file names
    handleFileUpload(event) {
        const idx = event.target.dataset.index;
        const key = this.lineItems[idx].key;
        const files = event.detail.files;
        
        if (files && files.length > 0) {
            // Store both document IDs and file details
            const fileDetails = files.map(file => ({
                documentId: file.documentId,
                name: file.name,
                contentType: file.contentType
            }));
            
            const documentIds = files.map(file => file.documentId);
            
            // Store file details in a separate map for better organization
            if (!this.fileDetailsMap) {
                this.fileDetailsMap = new Map();
            }
            this.fileDetailsMap.set(key, fileDetails);
            
            // Keep the original filesMap for backward compatibility
            this.filesMap.set(key, documentIds);
            
            // Update file count for the specific line item
            this.updateLineItem(parseInt(idx), 'fileCount', documentIds.length);
            
            this.showToast('Success', `${documentIds.length} file(s) uploaded successfully`, 'success');
            
            // Force re-render to show/hide the eye icon
            this.lineItems = [...this.lineItems];
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

    async handleVoucherTypeChange(event) {
        this.selectedVoucherType = event.detail.value;
        this.selectedTourId = '';
        this.selectedTourName = '';

        if (!(this.selectedVoucherType === 'Local' || this.selectedVoucherType === 'Outstation')) {
            this.visitReportId = '';
            this.visitReportName = '';
        }

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

            // Force update all line items with correct transport options and allowances
            this.lineItems = this.lineItems.map((item, index) => {
                const transportOptions = this.getTransportOptionsForItem('', this.selectedVoucherType);
                console.log('Setting transport options for item:', transportOptions);

                const isFirstItem = index === 0;
                
                // NEW LOGIC: Determine allowances based on voucher type and eligibility
                let dailyAllowanceValue = 0;
                let amountClaimedValue = item.amountClaimed || 0;
                
                if (this.selectedVoucherType === 'Outstation' && isFirstItem && this.isOutOfPocketEligible) {
                    // For Outstation, first item gets Out_of_Pocket in Daily_Allowance field
                    dailyAllowanceValue = this.outOfPocket || 0;
                } else if (this.selectedVoucherType === 'Local' && isFirstItem && this.isDailyAllowanceEligible) {
                    // For Local, first item gets Daily_Allowance
                    dailyAllowanceValue = this.dailyAllowance || 0;
                }
                
                // Reset amount claimed unless it's Own Arrangement
                if (!item.isOwnArrangement) {
                    amountClaimedValue = 0;
                }

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
                    modeOfTravel: '', // Reset mode of travel as it's no longer used for allowance logic
                    disableTransportFields: false,
                    dailyAllowance: dailyAllowanceValue,
                    amountClaimed: amountClaimedValue,
                    disableDailyAllowance: !isFirstItem || 
                        (this.selectedVoucherType === 'Outstation' ? !this.isOutOfPocketEligible : !this.isDailyAllowanceEligible),
                    isOwnArrangement: false,
                    isMandatory: false,
                    typeOfExpenseName: '',
                    date: this.selectedVoucherType === 'Local' ? this.todayDate : null,
                    outstationDate: this.selectedVoucherType === 'Outstation' ? this.todayDate : null,
                    // Reset eligibility flags
                    isDailyAllowanceEligible: false,
                    isOutOfPocketEligible: false,
                    eligibilityChecked: false
                };
            });

            await this.checkAllLineItemsEligibility();

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

    async createExpenseTeamMembers(expenseId) {
        try {
            const teamMembersToCreate = this.selectedTeamMembers.map(member => ({
                Expense__c: expenseId,
                Attendee__c: member.Id
            }));

            // FIX: Call the Apex method, not the same JavaScript method
            const result = await createExpenseTeamMembers({ 
                teamMembers: teamMembersToCreate 
            });
            
            console.log('Expense Team Members created:', result);
            return result;
        } catch (error) {
            console.error('Error creating expense team members:', error);
            throw error;
        }
    }

    async handleSubmit() {
        if (!this.validateForm()) return;

        this.isLoading = true;

        try {
            const customerVisitIds = [];
            const expenseTeamMemberIds = [];

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
                Date__c: this.selectedVoucherType === 'Local' ? item.date : 
                    (this.selectedVoucherType === 'Outstation' ? item.outstationDate : null),
                Reason__c: this.selectedVoucherType === 'Misc' ? item.reason :
                    (this.selectedVoucherType === 'Outstation' ? item.outstationReason : null),
                From_Location__c: this.selectedVoucherType === 'Local' ? item.fromLocation :
                    (this.selectedVoucherType === 'Outstation' ? item.outstationFromLocation : null),
                To_Location__c: this.selectedVoucherType === 'Local' ? item.toLocation :
                    (this.selectedVoucherType === 'Outstation' ? item.outstationToLocation : null),
                Mode_of_Transport__c: this.selectedVoucherType === 'Local' ? item.transportMode :
                    (this.selectedVoucherType === 'Outstation' ? item.outstationTransportMode : null),
                Mode_of_Travel__c: this.showModeOfTravelField ? item.modeOfTravel : null,
                Start_KM__c: (this.selectedVoucherType === 'Local' || 
                     (this.selectedVoucherType === 'Outstation' && 
                      (item.outstationTransportMode === 'Car' || item.outstationTransportMode === 'Bike'))) ? 
                      (item.startKM || null) : null,
        
                End_KM__c: (this.selectedVoucherType === 'Local' || 
                        (this.selectedVoucherType === 'Outstation' && 
                            (item.outstationTransportMode === 'Car' || item.outstationTransportMode === 'Bike'))) ? 
                            (item.endKM || null) : null,
                
                KM_Rate__c: (this.selectedVoucherType === 'Local' || 
                            (this.selectedVoucherType === 'Outstation' && 
                            (item.outstationTransportMode === 'Car' || item.outstationTransportMode === 'Bike'))) ? 
                            item.kmRate : null,
                
                Toll_Parking__c: (this.selectedVoucherType === 'Local' || 
                                (this.selectedVoucherType === 'Outstation' && 
                                (item.outstationTransportMode === 'Car' || item.outstationTransportMode === 'Bike'))) ? 
                                item.tollParking : null,
                // Outstation fields
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

            // Create Expense Team Member records
            if (this.selectedTeamMembers.length > 0 && expenseId) {
                await this.createExpenseTeamMembers(expenseId);
            }

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

        if ((this.selectedVoucherType === 'Local' || this.selectedVoucherType === 'Outstation') && !this.visitReportId) {
            this.showToast('Error', 'Please select a Visit Report for ' + this.selectedVoucherType + ' voucher', 'error');
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
            const hasFiles = this.filesMap.has(item.key) && this.filesMap.get(item.key).length > 0;
            if (item.isMandatory && !hasFiles) {
                const expenseTypeName = item.typeOfExpenseName || 'this expense type';
                this.showToast('Error', `File upload is mandatory for "${expenseTypeName}" in row ${i + 1}`, 'error');
                return false;
            }
            // Validate reason field only for Misc voucher type
            if (this.selectedVoucherType === 'Misc' && (!item.reason || item.reason.trim() === '')) {
                this.showToast('Error', `Enter Reason for Misc expense in row ${i + 1}`, 'error');
                return false;
            }
            // FILE VALIDATION FOR CAR TRANSPORT MODE
            const transportMode = this.selectedVoucherType === 'Local' ? item.transportMode : item.outstationTransportMode;

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
                objectApiName: 'Expense__c',
                actionName: 'view'
            }
        });
    }
}