({
    init: function (component, event, helper) {
        var pageReference = component.get("v.pageReference");
        component.set("v.refRecordId", pageReference.state.c__refRecordId);
        // component.set("v.sObjectName", pageReference.state.c__refsObjectName);
    },
    reInit: function (component, event, helper) {
        console.log('This is fire');
        $A.get('e.force:refreshView').fire();
    }
})