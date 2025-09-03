import { LightningElement, track } from 'lwc';
import getDefualtFiscId from '@salesforce/apex/TargetNewController.getDefualtFiscId';
import getProductList from '@salesforce/apex/TargetNewController.getProductList';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import saveToServer from '@salesforce/apex/TargetNewController.saveToServer';
import updateOnDemand from '@salesforce/apex/TargetNewController.updateOnDemand';

import getExistingData from '@salesforce/apex/TargetNewController.getExistingData';


export default class EmplyoyeeWiseTarget extends LightningElement {
    @track vData = [];
    @track vAllData = [];
    @track showSpinner = false;
    @track fiscalId = '';
    @track fiscalStartDate = [];
    @track fiscalEndDate = [];
    @track salesEmployeeId = '';
    @track hasDataInTable;
    connectedCallback() {

        this.getDefualtFiscsId();
    }
    getDefualtFiscsId() {
        getDefualtFiscId().then(result => {
            this.fiscalId = result.Id;
            this.fiscalStartDate = result.FY_Start_Date__c;
            this.fiscalEndDate = result.FY_End_Date__c;
        })
    }

    getGetAllProduct() {
        getProductList().then(result => {
            console.log('result-->', JSON.stringify(result));

            this.vData = this.generateProductMonthData(result, this.existingTarget);
            this.vAllData = this.vData;
            console.log('all data ->', JSON.stringify(this.vAllData));
            this.updateTotals(this.vAllData);

        })
    }


    handleSalesEmpChange(event) {
        this.salesEmployeeId = event.target.value;
        this.showSpinner = true;
        if (this.salesEmployeeId) {
            if (this.refreshTimeout) {
                clearTimeout(this.refreshTimeout);
            }
            this.getExistingTarget();

            this.refreshTimeout = setTimeout(() => {
                this.getGetAllProduct();
            }, 1000);

        } else {
            this.showSpinner = false;
            this.vData = [];
            this.hasDataInTable = false;
            this.vAllData = [];
        }
    }


    @track existingTarget = [];
    getExistingTarget() {
        getExistingData({ usId: this.salesEmployeeId, fyId: this.fiscalId }).then(result => {
            console.log('result-->', JSON.stringify(result));
            this.existingTarget = JSON.parse(JSON.stringify(result));
        })
    }
    generateProductMonthData(products, existingRecords = []) {

        const startDate = new Date(this.fiscalStartDate);
        const endDate = new Date(this.fiscalEndDate);
        const today = new Date();
        this.showSpinner = true;

        const monthsInRange = [];
        const current = new Date(startDate);

        while (current <= endDate) {
            const monthYear = `${current.toLocaleString('default', { month: 'long' })}-${current.getFullYear()}`;
            monthsInRange.push({
                monthYear,
                isPast: new Date(current.getFullYear(), current.getMonth() + 1, 0) < today
            });
            current.setMonth(current.getMonth() + 1);
        }

        const generateRandomIndex = () => {
            return Math.floor(1000 + Math.random() * 9000).toString();
        };

        const finalData = products.map(product => {

            return {
                ...product,
                iconName: 'utility:chevronright',
                isExpanded: false,
                isChanged: false,
                MonthList: monthsInRange.map(monthObj => {
                    const [monthName, year] = monthObj.monthYear.split('-');

                    // Find matching existing record
                    const existing = existingRecords.find(rec =>
                        rec.Product__c === product.Id &&
                        rec.Month__c === monthName &&
                        String(rec.Year__c) === year
                    );

                    const quantity = existing ? parseFloat(existing.Quantity__c) || 0 : 0;
                    const price = existing ? parseFloat(existing.Amount__c) || 0 : 0;

                    return {
                        index: generateRandomIndex(),
                        MonthName: monthObj.monthYear,
                        disabled: monthObj.isPast,
                        uId: existing?.Id || null,
                        COGS_Kg__c: existing?.Budgeted_COGS__c?.toString() || "0.00",
                        GM_Kg__c: existing?.GM_Kg__c?.toString() || "0.00",
                        GM_Value__c:existing?.Gross_Margin__c?.toString() || "0.00", // You can add if exists in `existing`
                        COGS_Value__c: existing?.COGS_Value__c?.toString() || "0.00",
                        Price__c: price.toFixed(2),
                        Sales_Qauntity__c: quantity,
                        Sales_Value__c: (quantity * price).toFixed(2),
                        month: monthObj
                    };
                })
            };
        });

        setTimeout(() => {
            this.hasDataInTable = products.length > 0;
            this.showSpinner = false;
        }, 2000);

        return finalData;
    }


    // generateProductMonthData(products) {
    //     const startDate = new Date(this.fiscalStartDate);
    //     const endDate = new Date(this.fiscalEndDate);
    //     const today = new Date(); // Current date for comparison

    //     const monthsInRange = [];
    //     const current = new Date(startDate);

    //     while (current <= endDate) {
    //         const monthYear = `${current.toLocaleString('default', { month: 'long' })}-${current.getFullYear()}`;
    //         monthsInRange.push({
    //             monthYear,
    //             isPast: new Date(current.getFullYear(), current.getMonth() + 1, 0) < today // end of the month < today
    //         });
    //         current.setMonth(current.getMonth() + 1);
    //     }

    //     const generateRandomIndex = () => {
    //         return Math.floor(1000 + Math.random() * 9000).toString();
    //     };

    //     const finalData = products.map(product => {
    //         return {
    //             ...product,
    //              iconName: 'utility:chevronright',
    //              isExpanded:false,
    //             MonthList: monthsInRange.map(monthObj => ({
    //                 index: generateRandomIndex(),
    //                 MonthName: monthObj.monthYear,
    //                 disabled: monthObj.isPast,
    //                 uId:null,
    //                 month:monthObj,
    //                 COGS_Kg__c: "0.00",
    //                 COGS_Value__c: "0.00",
    //                 GM_Kg__c: "0.00",
    //                 GM_Value__c: "0.00",
    //                 Price__c: "0.00",
    //                 Sales_Value__c: "0.00",
    //                 Sales_Qauntity__c: 0
    //             }))
    //         };
    //     });

    //     return finalData;
    // }

    toggleRow(event) {
        if (event.currentTarget && event.currentTarget.dataset && event.currentTarget.dataset.key) {
            const clickedId = event.currentTarget.dataset.key;

            const updatedData = this.vData.map(group => {
                const isClicked = group.Id === clickedId;

                return {
                    ...group,
                    isExpanded: isClicked ? !group.isExpanded : false,
                    iconName: isClicked
                        ? (group.isExpanded ? 'utility:chevronright' : 'utility:chevrondown')
                        : 'utility:chevronright'
                };
            });

            this.vData = [...updatedData];
        }
    }



   ValChange(event) {
    const pId = event.target.dataset.id;
    const monthIndex = event.target.dataset.index;
    const field = event.target.dataset.label;
    const uId = event.target.dataset.valId;
    const value = parseFloat(event.target.value) || 0;

    const productIndex = this.vAllData.findIndex(p => p.Id === pId);
    if (productIndex === -1) return;

    const product = this.vAllData[productIndex];
    const month = product.MonthList.find(m => m.index === monthIndex);
    if (!month) return;

    if (!uId) {
        product.isChanged = true;
    }

    // Update the changed field
    month[field] = value;

    const quantity = parseFloat(month.Sales_Qauntity__c) || 0;
    const price = parseFloat(month.Price__c) || 0;
    const cogsKg = parseFloat(month.COGS_Kg__c) || 0;
    const gmKg = price - cogsKg;

    // Update calculated fields
    month.GM_Kg__c = gmKg.toFixed(2);
    month.Sales_Value__c = (quantity * price).toFixed(2);
    month.COGS_Value__c = (quantity * cogsKg).toFixed(2);
    month.GM_Value__c = gmKg !== 0 ? (quantity / gmKg).toFixed(2) : "0.00";

    // Debounced Apex update if record already exists
    if (this.valChangeTimeout) {
        clearTimeout(this.valChangeTimeout);
    }

    this.valChangeTimeout = setTimeout(() => {
        if (uId) {
            updateOnDemand({ Id: uId, feild: field, value: value })
                .then(result => {
                    console.log('Update result:', result);
                })
                .catch(error => {
                    console.error('Update error:', error);
                });
        }
    }, 500);

    // 🧠 Recalculate subtotal based on visible months (filtered)
    let totalQty = 0, totalSales = 0, totalGM = 0, totalCOGS = 0;

    const monthFilter = this.searchCriteria?.month?.toLowerCase();

    const monthsToConsider = monthFilter
        ? product.MonthList.filter(m => m.MonthName?.toLowerCase().includes(monthFilter))
        : product.MonthList;

    for (let m of monthsToConsider) {
        totalQty += parseFloat(m.Sales_Qauntity__c) || 0;
        totalSales += parseFloat(m.Sales_Value__c) || 0;
        totalGM += parseFloat(m.GM_Kg__c) || 0;
        totalCOGS += parseFloat(m.COGS_Value__c) || 0;
    }

    product.subTotal = {
        quantity: totalQty.toFixed(2),
        salesValue: totalSales.toFixed(2),
        gmValue: totalGM.toFixed(2),
        cogsValue: totalCOGS.toFixed(2)
    };

    // Update the corresponding product in filtered data as well
    const vDataIndex = this.vData.findIndex(p => p.Id === pId);
    if (vDataIndex !== -1) {
        this.vData[vDataIndex].subTotal = product.subTotal;
    }
    this.computeGrandTotals();
}




    updateTotals(data) {
        for (let product of data) {
            let quantity = 0;
            let salesValue = 0;
            let gmValue = 0;
            let cogsValue = 0;

            for (let month of product.MonthList) {
                const qty = parseFloat(month.Sales_Qauntity__c) || 0;
                const salesVal = parseFloat(month.Sales_Value__c) || 0;
                const gmVal = parseFloat(month.GM_Kg__c) || 0;
                const cogsVal = parseFloat(month.COGS_Value__c) || 0;

                quantity += qty;
                salesValue += salesVal;
                gmValue += gmVal;
                cogsValue += cogsVal;
            }

            // Attach subtotal fields to the product directly
                product.subTotal = {
                quantity: quantity.toFixed(2),
                salesValue: salesValue.toFixed(2),
                gmValue: gmValue.toFixed(2),
                cogsValue: cogsValue.toFixed(2)
            };
        }

        this.vData = data;
        console.log('vData-->', JSON.stringify(this.vData));
        this.computeGrandTotals();
    }

    @track displayTotals = {
    Total_Sales_Quantity: 0,
    Total_Price: '₹0',
    Total_GM_Kg: 0,
    Total_COGS_Value: '₹0',
    Total_COGS_Kg: 0,
    Total_GM_Value: '₹0',
    Total_Sales_Value: '₹0'
};

computeGrandTotals() {
    let totalQty = 0;
    let totalPrice = 0;
    let totalGMKg = 0;
    let totalCOGSKg = 0;
    let totalSalesVal = 0;
    let totalGMVal = 0;
    let totalCOGSVal = 0;

    for (let product of this.vAllData) {
        for (let month of product.MonthList) {
            totalQty += parseFloat(month.Sales_Qauntity__c) || 0;
            totalGMKg += parseFloat(month.GM_Kg__c) || 0;
            totalSalesVal += parseFloat(month.Sales_Value__c) || 0;
            totalCOGSVal += parseFloat(month.COGS_Value__c) || 0;
        }
    }

    this.displayTotals = {
        Total_Sales_Quantity: totalQty.toFixed(2),
        Total_Price: `₹${totalPrice.toFixed(2)}`,
        Total_GM_Kg: totalGMKg.toFixed(2),
        Total_COGS_Kg: totalCOGSKg.toFixed(2),
        Total_Sales_Value: `₹${totalSalesVal.toFixed(2)}`,
        Total_GM_Value: `₹${totalGMVal.toFixed(2)}`,
        Total_COGS_Value: `₹${totalCOGSVal.toFixed(2)}`
    };
}

    
    searchCriteria = {
        customerName: '',
        month: ''
    };

    //@track monthVal = null;

    handleSearchChange(event) {
        const searchType = event.target.dataset.type;
        const searchValue = event.target.value?.toLowerCase() || '';

        this.searchCriteria[searchType] = searchValue;
        //this.monthVal = this.searchCriteria.month;

        this.vData = this.vAllData
            .filter(customer => {
                const nameMatch = customer.Name?.toLowerCase().includes(this.searchCriteria.customerName || '');
                const codeMatch = customer.ProductCode?.toLowerCase().includes(this.searchCriteria.customerName || '');
                const matchesCustomer = nameMatch || codeMatch;

                const matchesMonth = this.searchCriteria.month
                    ? customer.MonthList?.some(m => m.MonthName?.toLowerCase().includes(this.searchCriteria.month))
                    : true;

                return matchesCustomer && matchesMonth;
            })
            .map(customer => {
                const newCustomer = { ...customer };

                if (this.searchCriteria.month) {
                    newCustomer.MonthList = customer.MonthList
                        ?.filter(m => m.MonthName?.toLowerCase().includes(this.searchCriteria.month));
                }

                return newCustomer;
            });

        // Optionally update totals or view here
        this.updateTotals(this.vData);
    }








    @track saveDisabled = false;

    saveRecords() {
        let recordsToSave = [];
        this.saveDisabled = true;
        this.showSpinner = true;

        // Loop through each product
        this.vAllData.forEach(product => {
            if (product.isChanged) {
                console.log('total  mont of -->', product.MonthList.length);

                product.MonthList.forEach(month => {
                    if (
                        !month.disabled &&
                        month.uId == null &&
                        Number(month.Sales_Qauntity__c) > 0
                    ) {
                        console.log();

                        // Push relevant data only
                        recordsToSave.push({
                            ProductId: product.Id,
                            ProductName: product.Name,
                            ProductCode: product.ProductCode,
                            Description: product.Description,
                            MonthName: month.MonthName,
                            Sales_Qauntity__c: Number(month.Sales_Qauntity__c),
                            Price__c: Number(month.Price__c),
                            Sales_Value__c: Number(month.Sales_Value__c),
                            COGS_Kg__c:Number(month.COGS_Kg__c)
                        });
                    }
                });
            }
        });

        if (recordsToSave.length === 0) {
            this.saveDisabled = false;
            this.showSpinner = false;
            console.log('recordsToSave.length-->', recordsToSave.length);
            return;
        }

        if (recordsToSave.length > 0) {
            // Call Apex method with recordsToSave
            saveToServer({ js: JSON.stringify(recordsToSave), userId: this.salesEmployeeId, fyId: this.fiscalId })
                .then(result => {
                    this.showSpinner = false;
                    this.saveDisabled = false;
                    this.monthVal = null;
                    console.log('Save successful:', result);
                    if (result == 'Success') {
                        this.f_msg('Success', 'Records saved successfully', 'success');
                        this.handleCancel();
                    } else {

                        this.f_msg('Error', result, 'error');
                    }




                })
                .catch(error => {
                    // handle error
                    console.error('Error saving:', error);
                });
        }
    }


    f_msg(p_tittle, p_msg, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: p_tittle,
                message: p_msg,
                variant: variant
            })
        );
    }

    handleCancel() {
        if (this.salesEmployeeId) {
            if (this.refreshTimeout) {
                clearTimeout(this.refreshTimeout);
            }
            this.getExistingTarget();

            this.refreshTimeout = setTimeout(() => {
                this.getGetAllProduct();
            }, 1000);
        }
    }


    get shouldShowFooter() {
        return this.vAllData.some(product =>
            product.isChanged &&
            product.MonthList.some(month => month.uId == null)
        );
    }


}