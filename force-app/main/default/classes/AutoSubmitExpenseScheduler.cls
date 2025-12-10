global class AutoSubmitExpenseScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        // Run batch with chunk size 100 (tune as needed)
        Database.executeBatch(new AutoSubmitExpenseForApprovalBatch(), 100);
    }
}