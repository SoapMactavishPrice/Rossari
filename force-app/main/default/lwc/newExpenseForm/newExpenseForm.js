import { LightningElement, track } from 'lwc';
import getPendingExpenseApprovals from '@salesforce/apex/NewExpenseApprovalController.getPendingExpenseApprovals';
import getFilterOptions from '@salesforce/apex/NewExpenseApprovalController.getFilterOptions';
import submitApproval from '@salesforce/apex/NewExpenseApprovalController.submitApproval';
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
    @track showModal = false;
    @track currentExpenseId = '';
    @track approvalAction = '';
    @track approvalComments = '';
    @track showDataSection = false;
    @track bulkApprovalEnabled = false;

    // Filter properties
    @track selectedUser = '';
    @track selectedVoucherType = '';
    @track selectedMonth = '';
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

            this.userOptions = options.userOptions || [];
            this.voucherTypeOptions = options.voucherTypeOptions || [];
            this.monthOptions = options.monthOptions || [];

            console.log('User options:', this.userOptions);
            console.log('Voucher type options:', this.voucherTypeOptions);
            console.log('Month options:', this.monthOptions);

        } catch (error) {
            console.error('Error loading filter options:', error);
            this.showToast('Error', 'Failed to load filter options', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // Load all expenses data
    async loadAllExpenses() {
        console.log('Starting to load all expenses...');
        this.isLoading = true;
        try {
            const expenses = await getPendingExpenseApprovals();
            console.log('All expenses received:', expenses);
            console.log('Number of expenses:', expenses ? expenses.length : 0);

            this.allExpenses = expenses.map(exp => {
                console.log('Processing expense:', exp.expenseName, 'with line items:', exp.lineItems);
                return {
                    ...exp,
                    isOutstation: exp.typeOfVoucher === 'Outstation',
                    isRBLRecordType: exp.recordType === 'RBL',
                    isUnitopTristarRecordType: exp.recordType === 'Unitop_Tristar',
                    badgeClass: this.getBadgeClass(exp.currentApprovalLevel),
                    formattedExpenseDate: this.formatDate(exp.expenseDate)
                };
            });

            console.log('Processed all expenses:', this.allExpenses);
            this.error = undefined;

        } catch (error) {
            console.error('Error fetching expenses:', error);
            this.showToast('Error', error.body?.message || 'Failed to load expenses', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // Group expenses by user
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
                    hasPendingWithCurrentUser: false
                };
            }

            // Add expense to user group
            const expenseWithLineItems = {
                ...expense,
                lineItems: expense.lineItems.map((lineItem, index) => ({
                    ...lineItem,
                    isFirstLineItem: index === 0 // Mark first line item for each expense
                }))
            };

            grouped[userName].expenses.push(expenseWithLineItems);
            grouped[userName].expenseCount = grouped[userName].expenses.length;

            // Check if any expense is pending with current user
            if (expense.isPendingWithCurrentUser) {
                grouped[userName].hasPendingWithCurrentUser = true;
            }
        });

        // Convert to array for template iteration
        this.userExpenseGroups = Object.values(grouped);

        console.log('Grouped expenses by user:', grouped);
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
        }
        return 'slds-badge';
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

    // Bulk approval toggle handler
    async handleBulkApprovalToggle(event) {
        this.bulkApprovalEnabled = event.target.checked;
        console.log('Bulk approval toggle:', this.bulkApprovalEnabled);

        if (this.bulkApprovalEnabled && this.filteredExpenses.length > 0) {
            await this.approveAllVisibleRecords();
        }
    }

    // Approve all visible records
    async approveAllVisibleRecords() {
        console.log('Approving all visible records');

        // Get all expense IDs that are pending with current user from filtered expenses
        const expensesPendingWithCurrentUser = this.filteredExpenses.filter(expense => expense.isPendingWithCurrentUser);

        if (expensesPendingWithCurrentUser.length === 0) {
            this.showToast('Info', 'No expenses pending your approval in the current filter view.', 'info');
            this.bulkApprovalEnabled = false;
            return;
        }

        const expenseIds = expensesPendingWithCurrentUser.map(expense => expense.expenseId);
        console.log('Approving all visible expenses. Expense IDs:', expenseIds);

        this.isLoading = true;
        try {
            const result = await submitBulkApproval({
                expenseIds: expenseIds,
                action: 'Approve',
                comments: 'Bulk approval - All visible records approved'
            });

            console.log('Bulk approval submitted successfully:', result);
            this.showToast('Success', `All ${expenseIds.length} visible expenses approved successfully!`, 'success');

            // Reload data after 1 second
            setTimeout(() => {
                console.log('Reloading data after bulk approval');
                this.loadAllExpenses();
                this.handleApplyFilters(); // Re-apply current filters
                this.bulkApprovalEnabled = false; // Reset toggle after approval
            }, 1000);

        } catch (error) {
            console.error('Error submitting bulk approval:', error);
            this.showToast('Error', error.body?.message || 'Failed to approve all expenses', 'error');
            this.bulkApprovalEnabled = false;
            this.isLoading = false;
        }
    }

    // Filter handlers
    handleUserChange(event) {
        this.selectedUser = event.detail.value;
        console.log('User changed to:', this.selectedUser);
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
        console.log('Current filters - User:', this.selectedUser, 'Voucher:', this.selectedVoucherType, 'Month:', this.selectedMonth);

        this.isLoading = true;
        this.showDataSection = true;

        try {
            // Load all expenses if not already loaded
            if (this.allExpenses.length === 0) {
                console.log('No expenses loaded yet, loading all expenses...');
                await this.loadAllExpenses();
            }

            console.log('Applying filters to', this.allExpenses.length, 'expenses');

            let filtered = [...this.allExpenses];

            // Filter by user
            if (this.selectedUser) {
                const originalCount = filtered.length;
                filtered = filtered.filter(expense =>
                    expense.employeeName === this.selectedUser
                );
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
                    const expenseMonth = expenseDate.getMonth() + 1; // JavaScript months are 0-indexed
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

            // Auto-approve if bulk approval is enabled
            if (this.bulkApprovalEnabled && filtered.length > 0) {
                await this.approveAllVisibleRecords();
            } else if (filtered.length === 0) {
                this.showToast('Info', 'No expenses found matching your filters.', 'info');
            } else {
                this.showToast('Success', `Found ${filtered.length} expense(s) across ${this.totalUsers} user(s)`, 'success');
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
        this.selectedUser = '';
        this.selectedVoucherType = '';
        this.selectedMonth = '';
        this.filteredExpenses = [];
        this.groupedExpenses = {};
        this.userExpenseGroups = [];
        this.showDataSection = false;
        this.bulkApprovalEnabled = false;

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

        // Also update filtered expenses and grouped expenses
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

        // Regroup the expenses
        this.groupedExpenses = this.groupExpensesByUser(this.filteredExpenses);

        console.log('Updated expenses after amount change');
    }

    handleApprove(event) {
        const expenseId = event.target.dataset.id;
        console.log('Approve clicked for expense:', expenseId);
        this.currentExpenseId = expenseId;
        this.approvalAction = 'Approve';
        this.showModal = true;
    }

    handleReject(event) {
        const expenseId = event.target.dataset.id;
        console.log('Reject clicked for expense:', expenseId);
        this.currentExpenseId = expenseId;
        this.approvalAction = 'Reject';
        this.showModal = true;
    }

    handleCommentChange(event) {
        this.approvalComments = event.target.value;
    }

    closeModal() {
        console.log('Closing modal');
        this.showModal = false;
        this.approvalComments = '';
        this.currentExpenseId = '';
        this.approvalAction = '';
    }

    // Get current expense's line items
    getCurrentExpenseLineItems() {
        const currentExpense = this.allExpenses.find(exp => exp.expenseId === this.currentExpenseId);
        const lineItems = currentExpense ? currentExpense.lineItems : [];
        console.log('Current expense line items:', lineItems);
        return lineItems;
    }

    async submitApproval() {
        console.log('Submitting approval - Action:', this.approvalAction, 'Expense:', this.currentExpenseId);

        if (!this.approvalComments && this.approvalAction === 'Reject') {
            this.showToast('Warning', 'Please provide comments for rejection.', 'warning');
            return;
        }

        this.isLoading = true;
        try {
            const lineItems = this.getCurrentExpenseLineItems();
            console.log('Submitting approval with line items:', lineItems);

            const result = await submitApproval({
                expenseId: this.currentExpenseId,
                action: this.approvalAction,
                comments: this.approvalComments,
                lineItems: lineItems
            });

            console.log('Approval submitted successfully:', result);
            this.showToast('Success', `Expense ${this.approvalAction.toLowerCase()}d successfully!`, 'success');
            this.closeModal();

            // Reload data after 1 second
            setTimeout(() => {
                console.log('Reloading data after approval');
                this.loadAllExpenses();
                this.handleApplyFilters(); // Re-apply current filters
            }, 1000);

        } catch (error) {
            console.error('Error submitting approval:', error);
            this.showToast('Error', error.body?.message || 'Failed to submit approval', 'error');
            this.isLoading = false;
        }
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

    get modalHeader() {
        return this.approvalAction === 'Approve' ? 'Approve Expense' : 'Reject Expense';
    }

    get modalButtonLabel() {
        return this.approvalAction === 'Approve' ? 'Approve' : 'Reject';
    }

    get modalButtonVariant() {
        return this.approvalAction === 'Approve' ? 'brand' : 'destructive';
    }

    @track showFilesModal = false;
    @track selectedFiles = [];
    @track selectedLineItemName = '';

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