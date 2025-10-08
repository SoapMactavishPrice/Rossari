({
    init: function (component, event, helper) {
        var pageReference = component.get("v.pageReference");
        component.set("v.refRecordId", pageReference.state.c__refRecordId);
        component.set("v.objectApiName", pageReference.state.c__objectApiName);
        console.log('Loaded for object: ' + pageReference.state.c__objectApiName);
    },
    reInit: function (component, event, helper) {
        console.log('This is fire');
        $A.get('e.force:refreshView').fire();
    }
})