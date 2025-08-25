import {LightningElement, api} from 'lwc';

export default class DialogOk extends LightningElement {
    @api visible;
    @api title; 
    @api name; 
    @api message;
    @api confirmLabel; 
    //@api cancelLabel; 
    @api originalMessage;
    @api visiblecancel;

    handleClick(event){
        let finalEvent = {
            originalMessage: this.originalMessage,
            status: event.target.name
        };
        this.dispatchEvent(new CustomEvent('click', {detail: finalEvent}));
    }
    /* f_cd_clk_1(event){
        //when user clicks outside of the dialog area, the event is dispatched with detail value  as 1
        if(event.detail !== 1) {
            //gets the detail message published by the child component
            //this.displayMessage = 'Status: ' + event.detail.status + '. Event detail: ' + JSON.stringify(event.detail.originalMessage) + '.';

            if(event.detail.status === 'confirm') {
                this.boolVisible = true;
                this.f_Next_Page(); 
            }
            else if(event.detail.status === 'cancel'){
            }
        }
        this.isDialogVisible = false;
    } */
}