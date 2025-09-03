import { LightningElement, track } from 'lwc';
import getBudget from '@salesforce/apex/BudgetReport.getBudget';

export default class BudgetReport extends LightningElement {

    @track vData = [];
    @track showSpinner = false;
    connectedCallBack() {
        this.getBudgetery();
    }

    @track fiscalId = '';
    @track salesEmployeeId = '';
    handleFiscalChange(event) {
        this.fiscalId = event.target.value;
        if (this.fiscalId != '' && this.fiscalId != null) {
            this.getBudgetery();
        } else {
            this.vData = [];
        }
    }

    handleSalesEmpChange(event) {
        this.salesEmployeeId = event.target.value;
        if (this.salesEmployeeId != '' && this.salesEmployeeId != null) {
            this.getBudgetery();
        } else {
            this.vData = [];
        }
    }

    getBudgetery() {
        this.showSpinner = true;

        setTimeout(() => {
            getBudget({ userId: this.salesEmployeeId, fiscId: this.fiscalId }).then(result => {
                this.showSpinner = false;

                this.vData = this.groupByCustomerWithTotals(result);
                console.log('vData-->', JSON.stringify(this.vData));
            })
        }, 2000);

    }

    handleOpen(event) {
        let id = event.target.dataset.id = event.target.dataset.id;
        let index = this.vData.findIndex(x => x.Customer_Name__c == id);
        if (index != -1) {
            this.vData[index].isOpen = false;
            this.vData[index].isClose = true;
        }
    }

    handleClose(event) {
        let id = event.target.dataset.id = event.target.dataset.id;
        let index = this.vData.findIndex(x => x.Customer_Name__c == id);
        if (index != -1) {
            this.vData[index].isOpen = true;
            this.vData[index].isClose = false;
        }


    }


    groupByCustomerWithTotals(data) {
        const result = {};

        data.forEach(item => {
            const customerId = item.Customer_Name__c;

            if (!result[customerId]) {
                result[customerId] = {
                    ...item,
                    isOpen: true,
                    customerName: item.Customer_Name__r ? item.Customer_Name__r.Name : null,
                    Sales_Organisations: item.Sales_Organisations__r ? item.Sales_Organisations__r.Name : null,
                    Distribution_Channel: item.Distribution_Channel__r ? item.Distribution_Channel__r.Name : null,
                    Division: item.Division__r ? item.Division__r.Name : null,
                    isClose: false, // default collapsed
                    Sub_Total_Sales_Quantity__c: 0,
                    Sub_Total_Price__c: 0,
                    Sub_Total_GM_Kg__c: 0,
                    Sub_Total_COGS_Kg__c: 0,
                    Sub_Total_COGS_Value__c: 0,
                    Sub_Total_GM_Value__c: 0,
                    Sub_Total_Sales_Value__c: 0,
                    Products: []
                };
            }

            // Add product entry
            result[customerId].Products.push({
                Product_Description__c: item.Product_Description__c,
                COGS_Kg__c: item.COGS_Kg__c.toFixed(2),
                COGS_Value__c: item.COGS_Value__c.toFixed(2),

                GM_Kg__c: item.GM_Kg__c.toFixed(2),
                GM_Value__c: item.GM_Value__c.toFixed(2),
                Price__c: item.Price__c.toFixed(2),
                Sales_Value__c: item.Sales_Value__c.toFixed(2),

                Sales_Quantity__c: item.Sales_Quantity__c,


                Material_Group_Desc__c: item.Material_Group_Desc__c,
                Product_code__c: item.Product_code__c,
                Product_Description: item.Product_Description__r ? item.Product_Description__r.Name : null,

            });



            result[customerId].Sub_Total_Sales_Quantity__c += item.Sales_Qauntity__c || 0;


            let tempTotal_GM_Kg = result[customerId].Sub_Total_GM_Kg__c;
            tempTotal_GM_Kg = Number(tempTotal_GM_Kg) + Number(item.GM_Kg__c);
            result[customerId].Sub_Total_GM_Kg__c = Number(tempTotal_GM_Kg).toFixed(2);


            //result[customerId].Sub_Total_COGS_Kg__c += item.COGS_Kg__c || 0;


            let tempTotal_COGS_Kg = result[customerId].Sub_Total_COGS_Kg__c;
            tempTotal_COGS_Kg = Number(tempTotal_COGS_Kg) + Number(item.COGS_Kg__c);
            result[customerId].Sub_Total_COGS_Kg__c = Number(tempTotal_COGS_Kg).toFixed(2);



            let tempPriceVal = result[customerId].Sub_Total_Price__c;
            tempPriceVal = Number(tempPriceVal) + Number(item.Price__c);


            result[customerId].Sub_Total_Price__c = Number(tempPriceVal).toFixed(2);


            let tempTotal_COGSVal = result[customerId].Sub_Total_COGS_Value__c;
            tempTotal_COGSVal = Number(tempTotal_COGSVal) + Number(item.COGS_Value__c);


            result[customerId].Sub_Total_COGS_Value__c = Number(tempTotal_COGSVal).toFixed(2) || 0;


            let tempTotal_GM_Val = result[customerId].Sub_Total_GM_Value__c;
            tempTotal_GM_Val = Number(tempTotal_GM_Val) + Number(item.GM_Value__c);


            result[customerId].Sub_Total_GM_Value__c = Number(tempTotal_GM_Val).toFixed(2) || 0;

            let tempSalesPriceVal = result[customerId].Sub_Total_Sales_Value__c;
            tempSalesPriceVal = Number(tempSalesPriceVal) + Number(item.Sales_Value__c);
            result[customerId].Sub_Total_Sales_Value__c = Number(tempSalesPriceVal).toFixed(2);
        });

        // Return an array for LWC iteration
        return Object.values(result);
    }


}