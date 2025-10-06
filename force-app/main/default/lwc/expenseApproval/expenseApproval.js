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
            this.expenses = data.map(exp => {
                return {
                    ...exp,
                    isOutstation: exp.typeOfVoucher === 'Outstation',
                    isRBLRecordType: exp.recordType === 'RBL',
                    isUnitopTristarRecordType: exp.recordType === 'Unitop_Tristar'
                };
            });
            this.error = undefined;
        } else if (error) {
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

    async submitApproval() {
        if (!this.approvalComments && this.approvalAction === 'Reject') {
            this.showToast('Warning', 'Please provide comments for rejection.', 'warning');
            return;
        }

        this.isLoading = true;
        try {
            await submitApproval({
                expenseId: this.currentExpenseId,
                action: this.approvalAction,
                comments: this.approvalComments
            });

            this.showToast('Success', `Expense ${this.approvalAction.toLowerCase()}d successfully!`, 'success');
            this.closeModal();
            
            // Reload page after 1 second
            setTimeout(() => {
                window.location.reload();
            }, 1000);
            
        } catch (error) {
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