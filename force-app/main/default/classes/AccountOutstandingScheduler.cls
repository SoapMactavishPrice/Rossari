global class AccountOutstandingScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        // Example: Last 1 year outstanding
        // Date fd = Date.today().addYears(-1);
        Date fd = Date.today().addDays(-1);
        Date td = Date.today().addDays(-1);

        Database.executeBatch(new AccountOutstandingBatch(fd, td), 1);
    }
}