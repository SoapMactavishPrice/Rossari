import { LightningElement, wire, track } from 'lwc';
import getPendingExpenseApprovals from '@salesforce/apex/ExpenseApprovalController.getPendingExpenseApprovals';
import submitApproval from '@salesforce/apex/ExpenseApprovalController.submitApproval';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ExpenseApproval extends LightningElement {
    @track expenses = [];
    @track isLoading = false;
    @track showModal = false;
    @track currentExpenseId = '';
    @track approvalAction = '';
    @track approvalComments = '';

    @wire(getPendingExpenseApprovals)
    wiredExpenses({ error, data }) {
        if (data) {
            console.log('Received expenses data:', data);
            this.expenses = data.map(exp => {
                console.log('Processing expense:', exp.expenseName, 'with line items:', exp.lineItems);
                return {
                    ...exp,
                    isOutstation: exp.typeOfVoucher === 'Outstation',
                    isRBLRecordType: exp.recordType === 'RBL',
                    isUnitopTristarRecordType: exp.recordType === 'Unitop_Tristar'
                };
            });
            this.error = undefined;
        } else if (error) {
            console.error('Error fetching expenses:', error);
            this.showToast('Error', error.body.message, 'error');
        }
    }

    // Getter for dynamic badge class
    get badgeClass() {
        if (!this.expenses || this.expenses.length === 0) return 'slds-badge';
        
        // This will be applied to all badges, individual styling is handled in CSS
        return 'slds-badge approval-badge';
    }

    // Get badge class for specific expense
    getBadgeClass(expense) {
        if (expense.currentApprovalLevel === 'Level 1') {
            return 'slds-badge level1-badge';
        } else if (expense.currentApprovalLevel === 'Level 2') {
            return 'slds-badge level2-badge';
        }
        return 'slds-badge';
    }

    handleAmountPassedChange(event) {
        const lineItemId = event.target.dataset.lineitemId;
        const expenseId = event.target.dataset.expenseId;
        const newValue = parseFloat(event.target.value) || 0;

        console.log('Amount passed changed - LineItem:', lineItemId, 'Expense:', expenseId, 'Value:', newValue);

        // Update the local data
        this.expenses = this.expenses.map(expense => {
            if (expense.expenseId === expenseId) {
                const updatedLineItems = expense.lineItems.map(item => {
                    if (item.lineItemId === lineItemId) {
                        return { ...item, amountPassed: newValue };
                    }
                    return item;
                });
                
                // Recalculate total amount passed
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

        console.log('Updated expenses:', this.expenses);
    }

    handleApprove(event) {
        this.currentExpenseId = event.target.dataset.id;
        this.approvalAction = 'Approve';
        this.showModal = true;
    }

    handleReject(event) {
        this.currentExpenseId = event.target.dataset.id;
        this.approvalAction = 'Reject';
        this.showModal = true;
    }

    handleCommentChange(event) {
        this.approvalComments = event.target.value;
    }

    closeModal() {
        this.showModal = false;
        this.approvalComments = '';
        this.currentExpenseId = '';
        this.approvalAction = '';
    }

    // Get current expense's line items
    getCurrentExpenseLineItems() {
        const currentExpense = this.expenses.find(exp => exp.expenseId === this.currentExpenseId);
        const lineItems = currentExpense ? currentExpense.lineItems : [];
        console.log('Current expense line items:', lineItems);
        return lineItems;
    }

    // Calculate total claimed amount
    get totalClaimedAmount() {
        const lineItems = this.getCurrentExpenseLineItems();
        return lineItems.reduce((total, item) => total + (item.amountClaimed || 0), 0);
    }

    // Calculate total passed amount
    get totalPassedAmount() {
        const lineItems = this.getCurrentExpenseLineItems();
        return lineItems.reduce((total, item) => total + (item.amountPassed || 0), 0);
    }

    // Show amount summary only for approval and when there are line items
    get showAmountSummary() {
        return this.approvalAction === 'Approve' && this.getCurrentExpenseLineItems().length > 0;
    }

    async submitApproval() {
        if (!this.approvalComments && this.approvalAction === 'Reject') {
            this.showToast('Warning', 'Please provide comments for rejection.', 'warning');
            return;
        }

        this.isLoading = true;
        try {
            // Get line items for the current expense
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
            
            // Reload page after 1 second
            setTimeout(() => {
                window.location.reload();
            }, 1000);
            
        } catch (error) {
            console.error('Error submitting approval:', error);
            this.showToast('Error', error.body.message, 'error');
            this.isLoading = false;
        }
    }

    showToast(title, message, variant) {
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
}