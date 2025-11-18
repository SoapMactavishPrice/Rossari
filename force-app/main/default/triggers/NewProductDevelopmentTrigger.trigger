trigger NewProductDevelopmentTrigger on New_Product_Development__c (before insert) {
    NewProductDevelopmentTriggerHandler.handleBeforeInsert(Trigger.new);
}