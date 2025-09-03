import { LightningElement, track, api, wire } from 'lwc';
//import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from 'lightning/navigation';
import saveProductInterested from '@salesforce/apex/addProductIntrested.saveProductInterested';
import deleteProductInterested from '@salesforce/apex/addProductIntrested.deleteProductInterested';
//import isFetchdata from '@salesforce/apex/lwcAssessmentAnswerController.isFetchdata';
import getPicklistValues from '@salesforce/apex/addProductIntrested.getPicklistValues';
import getExistingProducts from '@salesforce/apex/addProductIntrested.getExistingProducts';
import getProdInterest from '@salesforce/apex/addProductIntrested.getProdInterest';


export default class LwcProductIntrestedPage extends NavigationMixin(LightningElement) {
    @api recordId;


    @track currencyCode = '';
    options = [];
    @track frequencyOptions = [];

    @wire(getPicklistValues)
    wiredPicklist({ error, data }) {
        if (data) {
            console.log('Picklist data:', JSON.stringify(data));

            // Safely handle product family options
            if (Array.isArray(data.productFamily)) {
                this.options = data.productFamily.map(item => ({
                    label: item.label,
                    value: item.value
                }));
            } else {
                this.options = [];
            }

            // Safely handle frequency options
            if (Array.isArray(data.frequency)) {
                this.frequencyOptions = data.frequency.map(item => ({
                    label: item.label,
                    value: item.value
                }));
            } else {
                this.frequencyOptions = [];
            }
        } else if (error) {
            console.error('Error in wiredPicklist:', error);
        }
    }


    @track where = '';
    @track Exist = [];
    getExisting() {
        getExistingProducts({ Id: this.recordId }).then(result => {
            if (result.length > 0) {
                this.Exist = result;
            }
            else {
                this.Exist = [];
            }

            this.where = `'Id NOT IN : '${this.Exist}'`;

        })
    }

    lookupRecord(event) {
        const selectedRecord = event.detail.selectedRecord;
        const index = event.target.dataset.index;
        console.log('event.detail.-->', selectedRecord);

        if (!selectedRecord) {
            console.log("No record selected");
            return;
        }
        this.addAnswer[index].prodId = selectedRecord.proId;
        this.addAnswer[index].pbeId = selectedRecord.Id;
        this.addAnswer[index].prodName = selectedRecord.Name;
        this.addAnswer[index].prodCode = selectedRecord.productCode;
        this.addAnswer[index].unitPrice = selectedRecord.unitPrice;
        this.addAnswer[index].prodFamily = selectedRecord.familyField;
        console.log('Updated Field:', index, JSON.stringify(this.addAnswer[index].prodCode));

    }

    @track tempIndex = 0;
    @track addAnswer = [];



    connectedCallback() {
        this.getProd();
        this.getExisting();

        getPicklistValues()
            .then(result => {

                this.frequencyOptions = result.frequency;

            })
            .catch(error => {
                console.error('Error loading picklists:', error);
            });

    }
    @track showSpinner = false;


    getProd() {
        this.showSpinner = true;
        getProdInterest({ Id: this.recordId }).then(result => {
            console.log('result--<>>>---', JSON.stringify(result));
            let data = JSON.parse(JSON.stringify(result));
            this.currencyCode = data.currencyCode;

            if (!data.currencyCode) {
                this.showSuccess('Error', 'Please fill Currency', 'Error');
                this.handleCancel();
                setTimeout(() => {
                    window.location.reload();
                }, 1000);
                return;
            }

            let tempData = data.piList;
            this.addAnswer = []; // Clear existing data

            if (tempData && tempData.length > 0) {
                tempData.forEach((ele, index) => {
                    let temp = {
                        index: index,
                        Id: this.recordId,
                        inId: ele.Id,
                        lineName: ele.Name,
                        prodId: ele.Product__c,
                        prodCode: ele.Product_Code__c,
                        price: ele.Expected_Price__c,
                        volume: ele.Quantity_in_Kgs__c,
                        // Add_In_Opty: ele.Add_in_Opportunity__c,
                        Add_In_Opty: ele.Add_in_Opportunity__c ?? true,
                        New_Product: ele.New_Product__c,
                        New_Product_Name: ele.New_Product_Name__c,
                        //   prodFamily: ele.Product_Family__c,
                        isEdit: true,
                        frequency: ele.Quantity_Frequency__c,
                        pbeId: ele.Price_book_Entry_Id__c,
                        unitPrice: parseFloat(ele.List_Price__c || 0),
                        prodName: ele.Product__r?.Name || '' // Use optional chaining and provide default value
                    };
                    this.addAnswer.push(temp);
                });
                this.tempIndex = this.addAnswer.length - 1;
            } else {
                // Add empty record if no products exist
                this.addAnswer = [{
                    index: 0,
                    Id: this.recordId,
                    inId: '',
                    lineName: '',
                    prodId: '',
                    pbeId: '',
                    New_Product: false,
                    New_Product_Name: '',
                    unitPrice: 0,
                    prodCode: '',
                    price: 0,
                    volume: 0,
                    frequency: '',
                    Add_In_Opty: true,
                    prodFamily: '',
                    isEdit: false,
                    prodName: ''
                }];
            }
            this.showSpinner = false;
        }).catch(error => {
            console.error('Error loading product interest:', error);
            this.showSpinner = false;
        });
    }

    handlefrequencyChange(event) {
        let index = event.target.dataset.index;
        this.addAnswer[index].frequency = event.target.value;
    }

    handleCheckboxChange(event) {
        const index = event.target.dataset.index;
        const isChecked = event.target.checked;

        this.addAnswer[index] = {
            ...this.addAnswer[index],
            New_Product: isChecked,
            //  Add_In_Opty: isChecked ? false : true,
            prodId: isChecked ? '' : this.addAnswer[index].prodId,
            prodName: isChecked ? '' : this.addAnswer[index].prodName,
            unitPrice: isChecked ? 1 : this.addAnswer[index].unitPrice,

            prodCode: isChecked ? '' : this.addAnswer[index].prodCode,
            New_Product_Name: isChecked ? this.addAnswer[index].New_Product_Name : '',
        };
        // Force UI update
        this.addAnswer = [...this.addAnswer];
    }


    handleTextInputChange(event) {
        const index = event.target.dataset.index;
        this.addAnswer[index] = {
            ...this.addAnswer[index],
            New_Product_Name: event.target.value
        };
    }


    addAnswerItem() {
        let validate = this.validateData(); // Call validateData to validate the data
        console.log('validate--> Item', validate);

        if (validate) {
            // Increment tempIndex
            this.tempIndex = this.tempIndex + 1;
            const newAnswer = {
                index: this.tempIndex,
                Id: this.recordId,
                inId: '',
                lineName: '',
                prodId: '',
                prodCode: '',
                price: '',
                volume: '',
                frequency: '',
                New_Product: false,
                New_Product_Name: '',
                Add_In_Opty: true,
                prodFamily: '',
                pbeId: '',
                unitPrice: 0,
                isEdit: false,
                prodName: ''
            };

            // Adding the new answer to the top of the array
            this.addAnswer.push(newAnswer); // Use unshift to add at the beginning

            console.log('addAnswer after adding item:', this.addAnswer);
        } else {
            console.log('Validation failed');
        }
    }



    removeAnswer(event) {
        let indexToRemove = event.target.dataset.index;
        let isEditOrNot = event.target.dataset.edit;
        let id = event.target.dataset.inid;
        console.log('OUTPUT : ', isEditOrNot, indexToRemove);
        if (isEditOrNot == "true") {
            deleteProductInterested({ Id: id }).then(result => {
                this.showSuccess('Success', result, 'Success');
                this.addAnswer = this.addAnswer.filter(answer => answer.index != parseInt(indexToRemove, 10));
                console.log('addAnswer before remove:', JSON.stringify(this.addAnswer));

                this.arrangeIndex();
                this.tempIndex = this.addAnswer.length - 1;
            })
        }
        else if (this.addAnswer.length > 1) {
            this.addAnswer = this.addAnswer.filter(answer => answer.index != parseInt(indexToRemove, 10));
            this.arrangeIndex();
            console.log('addAnswer after remove:', JSON.stringify(this.addAnswer));
            this.tempIndex = this.addAnswer.length - 1;
        }

    }

    arrangeIndex() {
        this.addAnswer = this.addAnswer.map((answer, newIndex) => {
            console.log('newIndex', newIndex);

            return { ...answer, index: newIndex }; // Update the index to be sequential
        });
    }

    showSuccess(title, msg, varinat) {
        const evt = new ShowToastEvent({
            title: title,
            message: msg,
            variant: varinat,
        });
        this.dispatchEvent(evt);

    }

    handleScoreChange(event) {
        let label = event.target.dataset.label;
        let index = event.target.dataset.index;
        this.addAnswer[index][label] = event.target.value;

        console.log('index-->', index, label, event.target.value);

        if (label == 'prodFamily') {
            this.addAnswer[index] = { ...this.addAnswer[index], prodId: '', prodName: '', prodCode: '' };  // This ensures the view updates
            console.log('family get changed->', JSON.stringify(this.addAnswer));
        }
        /* // this.callResetChildMethod(index);*/

    }

    // handleSelectChange(event) {
    //     let label = event.target.dataset.label;
    //     let index = event.target.dataset.index;
    //     this.addAnswer[index][label] = event.target.checked;
    // }

    handleSelectChange(event) {
        const label = event.target.dataset.label;
        const index = event.target.dataset.index;
        const checked = event.target.checked;

        if (label === 'Add_In_Opty') {
            this.addAnswer[index].Add_In_Opty = checked; // Allow user to change
        } else {
            this.addAnswer[index][label] = checked;
        }
    }

    validateData() {
        let validate = true;
        for (let element of this.addAnswer) {
            console.log('ele--', JSON.stringify(element));

            if (!element.New_Product && (element.prodName === '' || element.prodName === undefined || element.prodName === 0)) {
                this.showSuccess('Error', `Please Select a Product`, 'Error');
                console.log('index at prodName', element.index);

                validate = false;
                break;
            }
            else if (element.New_Product && (element.New_Product_Name === '' || element.New_Product_Name === undefined || element.New_Product_Name === 0)) {
                this.showSuccess('Error', `Please Enter New Product Name`, 'Error');
                console.log('index at prodName', element.index);

                validate = false;
                break;
            }
            else if (element.volume === '' || element.volume === undefined || element.volume <= 0) {
                this.showSuccess('Error', `Please Fill Quantity (greater than 0) in kgs for Product ${element.prodName}`, 'Error');
                console.log('index at volume', element.index);
                validate = false;
                break;
            }

        }
        return validate;

    }

    @api
    getChildComponent() {
        return this.template.querySelector('c-look-up-component');
    }

    callResetChildMethod(index) {
        const child = this.getChildComponent();
        console.log('child->', child);

        if (child) {
            child.removeRecordOnLookup(index);  // Call the method in the child
        }
    }


    save() {
        let validate = this.validateData();
        console.log('validate--> inside save', validate);

        if (validate) {
            //let isDupliacte  =this.validateAnswers();
            //if (isDupliacte) {
            saveProductInterested({ Id: this.recordId, JS: JSON.stringify(this.addAnswer) }).then(result => {
                console.log('result-->', result);
                if (result.message == 'success') {
                    this.showSuccess('success', 'Record Created Successfully !!!', 'Success');
                    this.handleCancel();

                    setTimeout(() => {
                        window.location.reload();
                    }, 1000);
                } else {
                    this.showSuccess('Error', result.message, 'error');
                }
            })
        }

    }


    validateAnswers() {
        console.log('JSON-->', this.existAnswer);
        let duplicateFound = true;
        this.addAnswer.forEach(element => {
            let name = element.Assessment_Score;

            if (this.existAnswer.has(name)) {
                duplicateFound = false;  // Set flag to true if a duplicate is found

                this.showSuccess('Error', 'Assesment Answer Score Already Exist ' + name, 'Error');
            }

            if ([...this.addAnswer].filter(ele => ele.Assessment_Score === name).length > 1) {
                duplicateFound = false;  // Set flag to true if a duplicate is found within `this.addAnswer`
                this.showSuccess('Error', 'Duplicate Assessment Answer Score Found : ' + name, 'Error');
            }
        })
        return duplicateFound;
    }

    handleCancel() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view',
            },
        });



    }

}