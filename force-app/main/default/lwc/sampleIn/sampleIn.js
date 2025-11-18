import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import saveSample from '@salesforce/apex/SampleInController.saveSample';
import { loadStyle } from 'lightning/platformResourceLoader';


export default class Lwc_SampleIn extends NavigationMixin(LightningElement) {

    isSaveDisabled = false;
    @track recId;
    @api recordId;
    @track isLoading = false;

    setCurrentPageReference(currentPageReference) {
        // Log the current page reference for debugging
        console.log('Current Page Reference:', JSON.stringify(currentPageReference));

        // Extract the c__refRecordId from the state of the page reference
        if (currentPageReference && currentPageReference.state) {
            // Access the refRecordId from the state object
            this.recId = currentPageReference.state.recordId;

            if (this.recId) {
                console.log('Record ID:', this.recId);
            } else {
                console.log('Record ID is not available in the page reference');
            }
        } else {
            console.log('Page reference or state is not available');
        }
    }
    @track generatedIds = new Set();
    generateRandomNum() {
        let randomId;
        do {
            randomId = Math.floor(Math.random() * 9000) + 1000;
        } while (this.generatedIds.has(randomId));


        this.generatedIds.add(randomId);
        return randomId;

    }

    @track sampleRequest = {};
    @track SampleLine = [{
        'sqNo': this.generateRandomNum(),
        'prodName': '',
        'qty': 0,
        'application': ''
    }
    ];


    // connectedCallback() {
    //     loadStyle(this, modalWidthInLwc)
    //         .then(() => {
    //             console.log('CSS loaded successfully!');
    //         })
    //         .catch(error => {
    //             console.log('Error loading CSS:', error);
    //         });

    //     // this.getLeadInfoUsingCode();
    // }


    @track isModalOpen = true;





    handleSampleChange(event) {
        let label = event.target.dataset.label;
        let value = event.target.value;
        this.sampleRequest[label] = value;
        console.log(JSON.stringify(this.sampleRequest));
    }






    lookupRecord(event) {
        const selectedRecord = event.detail.selectedRecord;
        const eve = event.target.dataset.index;
        let index = this.SampleLine.findIndex(x => x.sqNo == eve);
        console.log('event.detail.-->', index);

        if (!selectedRecord) {
            console.log("No record selected");
            return;
        }

        const selectedCampaign = event.detail;
        const pbe = selectedCampaign.selectedRecord;
        console.log('pbe', pbe);

        if (this.SampleLine && this.SampleLine[index]) {
            this.SampleLine[index] = {
                ...this.SampleLine[index],
                prodId: pbe.Id,
                prodName: pbe.Name,
                Product_Code: pbe.ProductCode,
                Description: pbe.Description,
                price: 0,
                application: ''
            };
            this.SampleLine = [...this.SampleLine];
            //console.log('Updated :', index, JSON.stringify(this.SampleLine[index]));
        } else {
            //console.error('Invalid index or fields array');
        }
    }

    validateData() {
        let validate = true;
        console.log('this.SampleLine-->', JSON.stringify(this.SampleLine));

        for (let element of this.SampleLine) {
            console.log('element-->', element.sqNo, element.prodId, element.Sample_Qty_in_Kgs);

            if (element.prodName == '' || element.prodName == undefined) {
                this.showSuccess('Error', `Please Select Product Name`, 'Error');
                validate = false;
                break;
            } else if (element.qty === '' || element.qty === undefined || element.qty === 0) {
                this.showSuccess('Error', `Please Fill Received Sample Qty (in Kgs) for Product ${element.prodName}`, 'Error');
                validate = false;
                break;
            }
            // else if (element.application === '' || element.application === undefined || element.application === 0) {
            //     this.showSuccess('Error', `Please Fill Application ${element.prodName}`, 'Error');
            //     validate = false;
            //     break;
            // }

        }
        return validate;
    }

    showSuccess(title, msg, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant
        });
        this.dispatchEvent(evt);
    }

    handleAdd() {
        console.log('goes to add-->');
        let validate = this.validateData();
        if (validate) {

            const newRow = {
                'sqNo': this.generateRandomNum(),
                'prodName': '',
                'qty': 0,
                'application': ''
            };



            //const newRow = { ...this.SampleLine, sqNo: this.generateRandomNum() };
            this.SampleLine = [...this.SampleLine, newRow];
        }

    }

    handleDelete(event) {
        console.log(JSON.stringify(this.SampleLine));
        let eveId = event.target.dataset.index;
        let index = this.SampleLine.findIndex(x => x.sqNo == eveId);
        console.log('index-->', index);
        if (index !== -1 && this.SampleLine.length > 1) {
            this.SampleLine.splice(index, 1);
            this.SampleLine = [...this.SampleLine];
        }
    }


    handleSampleLineChange(event) {
        let label = event.target.dataset.label;
        let value = event.target.value;
        let key = event.target.dataset.index;
        let index = this.SampleLine.findIndex(x => x.sqNo == key);

        this.SampleLine[index][label] = value;
        console.log(JSON.stringify(this.sampleRequest));
    }

    validateSample() {
        let validate = true;
        console.log('this.SampleLine-->', JSON.stringify(this.sampleRequest));

        // Validation for Request_Date
        if (!this.sampleRequest.Competitor_Name) {
            this.showSuccess('Error', `Please Fill Competitor Name`, 'Error');
            validate = false;
        }
        // Validation for Sample_Expected_Date
        else if (!this.sampleRequest.Sample_Sent_To_Unit) {
            this.showSuccess('Error', `Please Fill Sample Sent To Unit`, 'Error');
            validate = false;
        }
        // Validation for Sample_Sent_To_Plant
        else if (!this.sampleRequest.Sample_Received_Date) {
            this.showSuccess('Error', `Please Fill Sample Received Date`, 'Error');
            validate = false;
        }
        // Validation for Follow_Up_Reminder
        else if (!this.sampleRequest.Sample_Sent_To_Factory_From_HO) {
            this.showSuccess('Error', `Please Fill Sample Sent To Factory From HO`, 'Error');
            validate = false;
        }
        else if (!this.sampleRequest.Courier_Name) {
            this.showSuccess('Error', `Please Fill Courier Name`, 'Error');
            validate = false;
        }
        // else if (!this.sampleRequest.Courier_Tracking_No) {
        //     this.showSuccess('Error', `Please Fill Courier Tracking No`, 'Error');
        //     validate = false;
        // }

        return validate;
    }



    saveDetails() {
        if (this.isSaveDisabled) { return; }
        this.isSaveDisabled = true;
        this.isLoading = true;
        let validate = this.validateSample();
        if (validate) {
            validate = this.validateData();
        }
        if (!validate) {
            this.isSaveDisabled = false;
            return;
        }

        saveSample({
            leadId: this.recordId,
            sampleJs: JSON.stringify(this.sampleRequest),
            sampleLine: JSON.stringify(this.SampleLine)
        })
            .then(result => {
                if (result && typeof result === 'string') { // Check if it's a valid record ID
                    this.showSuccess('Success', 'Sample In is Created Successfully', 'success');
                    // Navigate to the new Sample In record
                    this.navigateToRecordView(result);
                } else {
                    this.isSaveDisabled = false;
                    this.showSuccess('Error', result || 'Unknown error occurred', 'error');
                }
            })
            .catch(error => {
                this.isSaveDisabled = false;
                this.showSuccess('Error', error.body?.message || error.message, 'error');
            });
    }

    navigateToRecordView(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: 'Sample_In__c',
                actionName: 'view'
            }
        });
    }

    handleCancel() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,   // Parent Sample Request Id
                objectApiName: 'Sample_Request__c',
                actionName: 'view'
            }
        });
    }


    //saveSample
    goBackToRecord() {
        this.isSaveDisabled = true;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recId,
                objectApiName: 'Sample_Request__c',
                actionName: 'view',

            }
        });
        setTimeout(() => {
            window.location.reload();
        }, 1200);
    }
}