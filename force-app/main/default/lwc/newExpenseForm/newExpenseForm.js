import { LightningElement, track } from 'lwc';
import getPendingExpenseApprovals from '@salesforce/apex/NewExpenseApprovalController.getPendingExpenseApprovals';
import getFilterOptions from '@salesforce/apex/NewExpenseApprovalController.getFilterOptions';
import submitBulkApproval from '@salesforce/apex/NewExpenseApprovalController.submitBulkApproval';
import getLineItemFiles from '@salesforce/apex/NewExpenseApprovalController.getLineItemFiles';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class NewExpenseForm extends NavigationMixin(LightningElement) {
    @track allExpenses = [];
    @track filteredExpenses = [];
    @track groupedExpenses = {};
    @track userExpenseGroups = [];
    @track isLoading = false;
    @track showFilesModal = false;
    @track selectedFiles = [];
    @track selectedLineItemName = '';
    @track showDataSection = false;

    // Filter properties
    @track selectedUser = '';
    @track selectedVoucherType = '';
    @track selectedMonth = '';
    @track userTypeOptions = [];
    @track userOptions = [];
    @track voucherTypeOptions = [];
    @track monthOptions = [];

    // Load filter options on component initialization
    connectedCallback() {
        console.log('Component initialized - loading filter options');
        this.loadFilterOptions();
    }

    // Load filter options from Apex
    async loadFilterOptions() {
        console.log('Starting to load filter options...');
        this.isLoading = true;
        try {
            const options = await getFilterOptions();
            console.log('Filter options received:', options);

            // Set user type options
            this.userTypeOptions = options.userTypeOptions || [];
            console.log('User type options:', this.userTypeOptions);

            // Store all users and create filtered list
            this.allUserOptions = options.userOptions || [];
            console.log('All user options:', this.allUserOptions);
            
            // Initialize filtered users (show all initially)
            this.filteredUserOptions = this.getFilteredUsersByType('');
            
            // Set other options
            this.voucherTypeOptions = options.voucherTypeOptions || [];
            this.monthOptions = options.monthOptions || [];

            console.log('User options after filtering:', this.filteredUserOptions);
            console.log('Voucher type options:', this.voucherTypeOptions);
            console.log('Month options:', this.monthOptions);

        } catch (error) {
            console.error('Error loading filter options:', error);
            this.showToast('Error', 'Failed to load filter options', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    getFilteredUsersByType(userType) {
        if (!userType || userType === '') {
            // Show all users with "All Users" option
            return [
                { label: '-- All Users --', value: '' },
                ...this.allUserOptions.map(user => ({
                    label: user.userName,
                    value: user.value,
                    userType: user.userType
                }))
            ];
        } else {
            // Filter users by selected user type
            const filteredUsers = this.allUserOptions
                .filter(user => user.userType === userType)
                .map(user => ({
                    label: user.userName,
                    value: user.value,
                    userType: user.userType
                }));
            
            // Add "All Users" option at the beginning
            return [
                { label: '-- All Users --', value: '' },
                ...filteredUsers
            ];
        }
    }

    // Load all expenses data - Show ALL records (pending and approved)
    async loadAllExpenses() {
        console.log('Starting to load all expenses...');
        this.isLoading = true;
        try {
            const expenses = await getPendingExpenseApprovals();
            console.log('All expenses received:', expenses);
            console.log('Number of expenses:', expenses ? expenses.length : 0);

            // Show ALL expense records (no filtering)
            this.allExpenses = expenses.map(exp => {
                console.log('Processing expense:', exp.expenseName, 'with line items:', exp.lineItems);
                return {
                    ...exp,
                    isOutstation: exp.typeOfVoucher === 'Outstation',
                    isRBLRecordType: exp.recordType === 'RBL',
                    isUnitopTristarRecordType: exp.recordType === 'Unitop_Tristar',
                    badgeClass: this.getBadgeClass(exp.currentApprovalLevel),
                    formattedExpenseDate: this.formatDate(exp.expenseDate),
                    // Convert status to display text for UI
                    statusDisplay: this.convertStatusToDisplay(exp.status, exp.isPendingWithCurrentUser, exp.currentApprover),
                    statusBadgeClass: this.getStatusBadgeClass(exp.status, exp.isPendingWithCurrentUser)
                };
            });

            console.log('Processed ALL expenses:', this.allExpenses);
            this.error = undefined;

        } catch (error) {
            console.error('Error fetching expenses:', error);
            this.showToast('Error', error.body?.message || 'Failed to load expenses', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // Convert status to display text for UI
    convertStatusToDisplay(status, isPendingWithCurrentUser, currentApprover) {
        if (isPendingWithCurrentUser) {
            return 'Pending Your Approval';
        } else if (status) {
            // Convert full status text to abbreviated display text
            if (status === 'Approved By Customer Success Incharge') {
                return 'Apr. by CSI';
            } else if (status === 'Approved by Business HOD') {
                return 'Apr. by Bus. HOD';
            } else if (status === 'Approved by Zonal Head') {
                return 'Apr. by Zonal Head';
            } else if (status === 'Rejected by Customer Success Incharge') {
                return 'Rej. by CSI';
            } else if (status === 'Rejected by Business HOD') {
                return 'Rej. by Bus. HOD';
            } else if (status === 'Rejected by Zonal Head') {
                return 'Rej. by Zonal Head';
            }
            // Return original status if no conversion needed
            return status;
        } else {
            // If no status but not pending with current user
            return currentApprover && currentApprover.includes('L1') ?
                `Pending with ${currentApprover.replace('L1 - ', '')}` :
                (currentApprover || 'Pending');
        }
    }


    // Group expenses by user - handle both pending and approved expenses
    groupExpensesByUser(expenses) {
        const grouped = {};

        expenses.forEach(expense => {
            const userName = expense.employeeName;

            if (!grouped[userName]) {
                grouped[userName] = {
                    userId: this.generateUserId(userName),
                    userName: userName,
                    expenses: [],
                    expenseCount: 0,
                    hasPendingWithCurrentUser: false,
                    pendingCount: 0,
                    approvedCount: 0,
                    isAllApproved: false,
                    hasMixedStatus: false
                };
            }

            // Add expense to user group
            const expenseWithLineItems = {
                ...expense,
                lineItems: expense.lineItems.map((lineItem, index) => ({
                    ...lineItem,
                    isFirstLineItem: index === 0
                }))
            };

            grouped[userName].expenses.push(expenseWithLineItems);
            grouped[userName].expenseCount = grouped[userName].expenses.length;

            // Count pending and approved expenses
            if (expense.isPendingWithCurrentUser) {
                grouped[userName].pendingCount++;
                grouped[userName].hasPendingWithCurrentUser = true;
            } else {
                grouped[userName].approvedCount++;
            }

            // Check if user has mixed status expenses
            grouped[userName].hasMixedStatus =
                grouped[userName].pendingCount > 0 && grouped[userName].approvedCount > 0;

            // Check if all expenses are approved
            grouped[userName].isAllApproved = grouped[userName].pendingCount === 0 && grouped[userName].expenseCount > 0;
        });

        // Convert to array for template iteration
        this.userExpenseGroups = Object.values(grouped);

        console.log('Grouped ALL expenses by user:', grouped);
        console.log('User expense groups array:', this.userExpenseGroups);

        return grouped;
    }

    // Generate a simple user ID for tracking
    generateUserId(userName) {
        return userName.replace(/\s+/g, '-').toLowerCase();
    }

    // Get badge class based on approval level
    getBadgeClass(approvalLevel) {
        if (approvalLevel === 'Level 1') {
            return 'slds-badge level1-badge';
        } else if (approvalLevel === 'Level 2') {
            return 'slds-badge level2-badge';
        } else if (approvalLevel === 'Completed') {
            return 'slds-badge slds-badge_success';
        }
        return 'slds-badge';
    }

    // Get status display text - Fixed to show actual approval status
    getStatusDisplay(status, isPendingWithCurrentUser, currentApprover) {
        if (isPendingWithCurrentUser) {
            return 'Pending Your Approval';
        } else if (status && (status.includes('Apr.') || status.includes('Rej.'))) {
            return status; // Show actual status like "Apr. by CSI", "Apr. by Bus. HOD", etc.
        } else if (status && status.includes('Approved')) {
            // Handle any remaining full status texts and convert to abbreviated
            if (status.includes('Customer Success Incharge')) {
                return 'Apr. by CSI';
            } else if (status.includes('Business HOD')) {
                return 'Apr. by Bus. HOD';
            } else if (status.includes('Zonal Head')) {
                return 'Apr. by Zonal Head';
            }
            return status;
        } else {
            // If no specific status but not pending with current user, show the current approver info
            return currentApprover && currentApprover.includes('L1') ?
                `Pending with ${currentApprover.replace('L1 - ', '')}` :
                (currentApprover || 'Pending');
        }
    }

    // Get status badge class
    // Get status badge class - Use original status for logic
    getStatusBadgeClass(status, isPendingWithCurrentUser) {
        if (isPendingWithCurrentUser) {
            return 'slds-badge slds-badge_warning';
        } else if (status && (status.includes('Approved') || status === 'Approved by Customer Success Incharge' || status === 'Approved by Business HOD' || status === 'Approved by Zonal Head')) {
            return 'slds-badge slds-badge_success';
        } else if (status && (status.includes('Rejected') || status === 'Rejected by Customer Success Incharge' || status === 'Rejected by Business HOD' || status === 'Rejected by Zonal Head')) {
            return 'slds-badge slds-badge_error';
        }
        return 'slds-badge slds-badge_lightest';
    }

    // Format date for display
    formatDate(dateString) {
        if (!dateString) return '';
        try {
            const date = new Date(dateString);
            return date.toLocaleDateString('en-IN', {
                day: '2-digit',
                month: 'short',
                year: 'numeric'
            });
        } catch (error) {
            return dateString;
        }
    }

    // Getter for total expenses count
    get totalExpenses() {
        return this.filteredExpenses.length;
    }

    // Getter for total users count
    get totalUsers() {
        return this.userExpenseGroups.length;
    }

    // Getter to check if we have grouped expenses
    get hasGroupedExpenses() {
        return this.userExpenseGroups.length > 0;
    }

    // Getter for pending approval count
    get pendingApprovalCount() {
        return this.filteredExpenses.filter(expense => expense.isPendingWithCurrentUser).length;
    }

    // Getter to check if there are any pending approvals
    get hasPendingApprovals() {
        return this.pendingApprovalCount > 0;
    }

    // Bulk toggle approval handler
    async handleBulkToggleApproval(event) {
        const userName = event.target.dataset.userName;
        const isApproved = event.target.checked;

        console.log('Bulk toggle approval for user:', userName, 'Approved:', isApproved);

        if (isApproved) {
            await this.approveAllUserExpenses(userName);
        } else {
            // Don't allow unchecking - once approved, it should stay approved
            event.target.checked = true;
        }
    }

    // Approve all expenses for a user
    async approveAllUserExpenses(userName) {
        console.log('Approving all expenses for user:', userName);

        const userGroup = this.userExpenseGroups.find(group => group.userName === userName);
        if (!userGroup || userGroup.expenses.length === 0) {
            this.showToast('Error', 'No expenses found for this user', 'error');
            return;
        }

        // Get only pending expense IDs for this user
        const pendingExpenseIds = userGroup.expenses
            .filter(expense => expense.isPendingWithCurrentUser)
            .map(expense => expense.expenseId);

        if (pendingExpenseIds.length === 0) {
            this.showToast('Info', 'No pending expenses found for this user', 'info');

            // Reset the toggle if no pending expenses
            const toggle = this.template.querySelector(`[data-user-name="${userName}"]`);
            if (toggle) {
                toggle.checked = false;
            }
            return;
        }

        console.log('Approving pending expenses for user:', userName, 'Expense IDs:', pendingExpenseIds);

        this.isLoading = true;

        // Add loading state to the user container
        const userContainer = this.template.querySelector(`[key="${userGroup.userId}"]`);
        if (userContainer) {
            userContainer.classList.add('approving');
        }

        try {
            const result = await submitBulkApproval({
                expenseIds: pendingExpenseIds,
                action: 'Approve',
                comments: 'Bulk approval - All pending expenses approved at once'
            });

            console.log('Bulk approval submitted successfully:', result);
            this.showToast('Success', `${pendingExpenseIds.length} expenses for ${userName} approved successfully!`, 'success');

            // Update UI immediately without page refresh
            await this.updateUIAfterBulkApproval(userName, pendingExpenseIds);

        } catch (error) {
            console.error('Error submitting bulk approval:', error);
            this.showToast('Error', error.body?.message || 'Failed to approve expenses', 'error');

            // Reset the toggle on error
            const toggle = this.template.querySelector(`[data-user-name="${userName}"]`);
            if (toggle) {
                toggle.checked = false;
            }
        } finally {
            this.isLoading = false;
            // Remove loading state
            if (userContainer) {
                userContainer.classList.remove('approving');
            }
        }
    }

    async updateUIAfterBulkApproval(userName, approvedExpenseIds) {
        try {
            // Update allExpenses array
            this.allExpenses = this.allExpenses.map(expense => {
                if (approvedExpenseIds.includes(expense.expenseId)) {
                    const updatedStatus = this.getUpdatedOriginalStatus(expense);
                    return {
                        ...expense,
                        isPendingWithCurrentUser: false,
                        status: updatedStatus, // Store original status
                        statusDisplay: this.convertStatusToDisplay(updatedStatus, false, expense.currentApprover), // Convert to display text
                        statusBadgeClass: this.getStatusBadgeClass(updatedStatus, false),
                        currentApprovalLevel: 'Completed',
                        badgeClass: this.getBadgeClass('Completed'),
                        canEditAmountPassed: false
                    };
                }
                return expense;
            });

            // Update filteredExpenses array
            this.filteredExpenses = this.filteredExpenses.map(expense => {
                if (approvedExpenseIds.includes(expense.expenseId)) {
                    const updatedStatus = this.getUpdatedOriginalStatus(expense);
                    return {
                        ...expense,
                        isPendingWithCurrentUser: false,
                        status: updatedStatus, // Store original status
                        statusDisplay: this.convertStatusToDisplay(updatedStatus, false, expense.currentApprover), // Convert to display text
                        statusBadgeClass: this.getStatusBadgeClass(updatedStatus, false),
                        currentApprovalLevel: 'Completed',
                        badgeClass: this.getBadgeClass('Completed'),
                        canEditAmountPassed: false
                    };
                }
                return expense;
            });

            // Re-group expenses
            this.groupedExpenses = this.groupExpensesByUser(this.filteredExpenses);
            this.userExpenseGroups = [...this.userExpenseGroups];

        } catch (error) {
            console.error('Error updating UI after bulk approval:', error);
            await this.reloadExpensesData();
        }
    }

    // Get updated original status (picklist value)
    getUpdatedOriginalStatus(expense) {
        const recordType = expense.recordType;
        const approvalLevel = expense.currentApprovalLevel;

        if (recordType === 'RBL') {
            if (approvalLevel === 'Level 1') {
                return 'Approved by Zonal Head';
            } else if (approvalLevel === 'Level 2') {
                return 'Approved by Business HOD';
            }
        } else if (recordType === 'Unitop_Tristar') {
            if (approvalLevel === 'Level 1') {
                return 'Approved by Customer Success Incharge';
            } else if (approvalLevel === 'Level 2') {
                return 'Approved by Business HOD';
            }
        }
        return 'Approved';
    }

    // Get updated original status (picklist value)
    getUpdatedOriginalStatus(expense) {
        const recordType = expense.recordType;
        const approvalLevel = expense.currentApprovalLevel;

        if (recordType === 'RBL') {
            if (approvalLevel === 'Level 1') {
                return 'Approved by Zonal Head'; // Original picklist value
            } else if (approvalLevel === 'Level 2') {
                return 'Approved by Business HOD'; // Original picklist value
            }
        } else if (recordType === 'Unitop_Tristar') {
            if (approvalLevel === 'Level 1') {
                return 'Approved by Customer Success Incharge'; // Original picklist value
            } else if (approvalLevel === 'Level 2') {
                return 'Approved by Business HOD'; // Original picklist value
            }
        }
        return 'Approved';
    }

    // Get updated status after approval
    getUpdatedStatus(expense) {
        const recordType = expense.recordType;
        const approvalLevel = expense.currentApprovalLevel;

        if (recordType === 'RBL') {
            if (approvalLevel === 'Level 1') {
                return 'Apr. by Zonal Head';
            } else if (approvalLevel === 'Level 2') {
                return 'Apr. by Bus. HOD';
            }
        } else if (recordType === 'Unitop_Tristar') {
            if (approvalLevel === 'Level 1') {
                return 'Apr. by CSI';
            } else if (approvalLevel === 'Level 2') {
                return 'Apr. by Bus. HOD';
            }
        }
        return 'Approved';
    }

    // Reload expenses data from server (fallback)
    async reloadExpensesData() {
        this.isLoading = true;
        try {
            // Clear current data
            this.allExpenses = [];
            this.filteredExpenses = [];
            this.userExpenseGroups = [];

            // Reload all expenses from server
            await this.loadAllExpenses();

            // Re-apply current filters if any
            if (this.selectedUser || this.selectedVoucherType || this.selectedMonth) {
                await this.handleApplyFilters();
            } else if (this.showDataSection) {
                this.filteredExpenses = [...this.allExpenses];
                this.groupedExpenses = this.groupExpensesByUser(this.filteredExpenses);
            }

        } catch (error) {
            console.error('Error reloading expenses data:', error);
            this.showToast('Error', 'Failed to refresh expenses data', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // Filter handlers
    handleUserTypeChange(event) {
        this.selectedUserType = event.detail.value;
        console.log('User Type changed to:', this.selectedUserType);
        
        // Filter user dropdown based on selected user type
        this.filteredUserOptions = this.getFilteredUsersByType(this.selectedUserType);
        
        // Reset user selection if the selected user doesn't match the new type
        if (this.selectedUser) {
            const selectedUserData = this.allUserOptions.find(user => user.value === this.selectedUser);
            if (selectedUserData && selectedUserData.userType !== this.selectedUserType && this.selectedUserType !== '') {
                this.selectedUser = '';
                console.log('User selection reset due to user type filter');
            }
        }
    }

    // Handle user change
    handleUserChange(event) {
        this.selectedUser = event.detail.value;
        console.log('User changed to:', this.selectedUser);
        
        // If a specific user is selected, you might want to show their user type
        if (this.selectedUser) {
            const selectedUserData = this.allUserOptions.find(user => user.value === this.selectedUser);
            if (selectedUserData && !this.selectedUserType) {
                // Optionally set user type based on selected user
                // this.selectedUserType = selectedUserData.userType;
            }
        }
    }

    handleVoucherTypeChange(event) {
        this.selectedVoucherType = event.detail.value;
        console.log('Voucher type changed to:', this.selectedVoucherType);
    }

    handleMonthChange(event) {
        this.selectedMonth = event.detail.value;
        console.log('Month changed to:', this.selectedMonth);
    }

    // Apply filters
    async handleApplyFilters() {
        console.log('Apply filters clicked');
        console.log('Current filters - User Type:', this.selectedUserType, 
                    'User:', this.selectedUser, 
                    'Voucher:', this.selectedVoucherType, 
                    'Month:', this.selectedMonth);

        this.isLoading = true;
        this.showDataSection = true;

        try {
            if (this.allExpenses.length === 0) {
                console.log('No expenses loaded yet, loading all expenses...');
                await this.loadAllExpenses();
            }

            console.log('Applying filters to', this.allExpenses.length, 'expenses');

            let filtered = [...this.allExpenses];

            // Filter by user type (if selected)
            if (this.selectedUserType) {
                const originalCount = filtered.length;
                filtered = filtered.filter(expense => {
                    // Find the user data to check user type
                    const userData = this.allUserOptions.find(user => 
                        user.userName === expense.employeeName
                    );
                    return userData && userData.userType === this.selectedUserType;
                });
                console.log(`User Type filter: ${originalCount} -> ${filtered.length} expenses`);
            }

            // Filter by user (if selected)
            if (this.selectedUser) {
                const originalCount = filtered.length;
                filtered = filtered.filter(expense => {
                    // Get user name from selected user ID
                    const selectedUserData = this.allUserOptions.find(user => 
                        user.value === this.selectedUser
                    );
                    return selectedUserData && expense.employeeName === selectedUserData.userName;
                });
                console.log(`User filter: ${originalCount} -> ${filtered.length} expenses`);
            }

            // Filter by voucher type
            if (this.selectedVoucherType) {
                const originalCount = filtered.length;
                filtered = filtered.filter(expense =>
                    expense.typeOfVoucher === this.selectedVoucherType
                );
                console.log(`Voucher filter: ${originalCount} -> ${filtered.length} expenses`);
            }

            // Filter by month
            if (this.selectedMonth) {
                const originalCount = filtered.length;
                filtered = filtered.filter(expense => {
                    if (!expense.expenseDate) return false;
                    const expenseDate = new Date(expense.expenseDate);
                    const expenseMonth = expenseDate.getMonth() + 1;
                    const expenseYear = expenseDate.getFullYear();
                    const [selectedYear, selectedMonth] = this.selectedMonth.split('-');

                    return expenseMonth === parseInt(selectedMonth) &&
                        expenseYear === parseInt(selectedYear);
                });
                console.log(`Month filter: ${originalCount} -> ${filtered.length} expenses`);
            }

            this.filteredExpenses = filtered;
            this.groupedExpenses = this.groupExpensesByUser(filtered);

            console.log('Final filtered expenses:', this.filteredExpenses);
            console.log('Grouped expenses:', this.groupedExpenses);

            if (filtered.length === 0) {
                this.showToast('Info', 'No expenses found matching your filters.', 'info');
            } else {
                const pendingCount = filtered.filter(expense => expense.isPendingWithCurrentUser).length;
                const approvedCount = filtered.length - pendingCount;

                let message = `Found ${filtered.length} expense(s) across ${this.totalUsers} user(s)`;
                if (pendingCount > 0) {
                    message += ` - ${pendingCount} pending approval`;
                }
                if (approvedCount > 0) {
                    message += ` - ${approvedCount} approved`;
                }

                this.showToast('Success', message, 'success');
            }

        } catch (error) {
            console.error('Error applying filters:', error);
            this.showToast('Error', 'Failed to apply filters', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // Clear filters
    handleClearFilters() {
        console.log('Clearing all filters');
        this.selectedUserType = '';
        this.selectedUser = '';
        this.selectedVoucherType = '';
        this.selectedMonth = '';
        this.filteredExpenses = [];
        this.groupedExpenses = {};
        this.userExpenseGroups = [];
        this.showDataSection = false;

        this.filteredUserOptions = this.getFilteredUsersByType('');

        this.showToast('Info', 'All filters cleared', 'info');
    }

    handleAmountPassedChange(event) {
        const lineItemId = event.target.dataset.lineitemId;
        const expenseId = event.target.dataset.expenseId;
        const newValue = parseFloat(event.target.value) || 0;

        console.log('Amount passed changed - LineItem:', lineItemId, 'Expense:', expenseId, 'Value:', newValue);

        // Update the local data
        this.allExpenses = this.allExpenses.map(expense => {
            if (expense.expenseId === expenseId) {
                const updatedLineItems = expense.lineItems.map(item => {
                    if (item.lineItemId === lineItemId) {
                        return { ...item, amountPassed: newValue };
                    }
                    return item;
                });

                const totalAmountPassed = updatedLineItems.reduce((total, item) =>
                    total + (item.amountPassed || 0), 0);

                return {
                    ...expense,
                    lineItems: updatedLineItems,
                    totalAmountPassed: totalAmountPassed
                };
            }
            return expense;
        });

        this.filteredExpenses = this.filteredExpenses.map(expense => {
            if (expense.expenseId === expenseId) {
                const updatedLineItems = expense.lineItems.map(item => {
                    if (item.lineItemId === lineItemId) {
                        return { ...item, amountPassed: newValue };
                    }
                    return item;
                });

                const totalAmountPassed = updatedLineItems.reduce((total, item) =>
                    total + (item.amountPassed || 0), 0);

                return {
                    ...expense,
                    lineItems: updatedLineItems,
                    totalAmountPassed: totalAmountPassed
                };
            }
            return expense;
        });

        this.groupedExpenses = this.groupExpensesByUser(this.filteredExpenses);
        console.log('Updated expenses after amount change');
    }

    showToast(title, message, variant) {
        console.log(`Toast: ${title} - ${message} (${variant})`);
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    async handleViewAttachments(event) {
        const lineItemId = event.currentTarget.dataset.lineitemId;
        const lineItemName = event.currentTarget.dataset.lineitemName;
        console.log('View attachments for line item:', lineItemId, lineItemName);

        this.isLoading = true;
        try {
            const files = await getLineItemFiles({ lineItemId });
            console.log('Files received:', files);
            this.selectedFiles = files.map(f => ({
                id: f.ContentDocumentId,
                name: f.ContentDocument.Title,
                fileType: f.ContentDocument.FileType
            }));
            this.selectedLineItemName = lineItemName;
            this.showFilesModal = true;
        } catch (error) {
            console.error('Error fetching files:', error);
            this.showToast('Error', error.body?.message || 'Failed to load files', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handlePreviewFile(event) {
        const documentId = event.currentTarget.dataset.docid;
        console.log('Preview file:', documentId);
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                selectedRecordId: documentId
            }
        });
    }

    closeFilesModal() {
        console.log('Closing files modal');
        this.showFilesModal = false;
        this.selectedFiles = [];
        this.selectedLineItemName = '';
    }
}