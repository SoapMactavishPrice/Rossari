import { LightningElement,track } from 'lwc';
import getDefualtFiscId from '@salesforce/apex/BookingSummaryController.getDefualtFiscId';
import getDefualtAccount from '@salesforce/apex/BookingSummaryController.getDefualtAccount';
import getExistingData from '@salesforce/apex/BookingSummaryController.getExistingData';
import getProductList from '@salesforce/apex/BookingSummaryController.getProductList';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveToServer from '@salesforce/apex/BookingSummaryController.saveToServer';
import updateOnDemand from '@salesforce/apex/BookingSummaryController.updateOnDemand';
import getAllExistingData from '@salesforce/apex/BookingSummaryController.getAllExistingData';



export default class BookingSummary extends LightningElement {
    @track vData = [];
    @track vAllData = [];
    @track showSpinner = false;
    @track fiscalId = '';
    @track fiscalStartDate = [];
    @track fiscalEndDate = [];
    @track allCustomerData = [];
    @track allProducts = [];
    @track salesEmployeeId = '';
    @track hasDataInTable;

    @track displayTotals = {
    Total_Sales_Quantity: 0,
    Total_Price: '₹0',
    Total_GM_Kg: 0,
    Total_COGS_Value: '₹0',
    Total_COGS_Kg: 0,
    Total_GM_Value: '₹0',
    Total_Sales_Value: '₹0'
};

    connectedCallback() {

        this.getDefualtFiscsId();
        
    }

    getCustomer() {
        getDefualtAccount({ownerId:this.salesEmployeeId}).then(result=>{

            console.log('result-->',JSON.stringify(result));
            this.allCustomerData = JSON.parse(JSON.stringify(result));
           
            
        })
    
    }
    getDefualtFiscsId() {
        getDefualtFiscId().then(result => {
            this.fiscalId = result.Id;
            this.fiscalStartDate = result.FY_Start_Date__c;
            this.fiscalEndDate = result.FY_End_Date__c;
        })
    }

        getGetAllProduct() {
            this.showSpinner = true;
            getProductList().then(result => {
                console.log('result-Product-->', JSON.stringify(result));
                this.allProducts = JSON.parse(JSON.stringify(result));
                //this.getExistingTarget();
                this.vData = this.generateCustomer(this.allCustomerData);
                this.vAllData = this.vData;
            console.log('all data ->', JSON.stringify(this.vAllData));
            
            setTimeout(() => {
                this.showSpinner = false;
    this.hasDataInTable = this.vData.length  > 0;
    console.log('this.hasDataInTable-->',this.hasDataInTable);
    
    //this.showSpinner = false;
    }, 1000);
                //this.updateTotals(this.vAllData);
    
            })
        }

        handleSalesEmpChange(event) {
    this.salesEmployeeId = event.target.value;
    //this.showSpinner = true;
    if (this.salesEmployeeId) {
        if (this.refreshTimeout) {
            clearTimeout(this.refreshTimeout);
        }
        this.getCustomer();
        this.getAllExistingDatav1(); //getExistingTarget();
        console.log('existingAllTarget-->', JSON.stringify(this.existingAllTarget));
        
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

  


generateCustomer(customers) {
    if (!Array.isArray(customers)) return [];

    return customers.map(customer => {
        // Ensure existingAllTarget is an array
        const customerTargets = Array.isArray(this.existingAllTarget)
            ? this.existingAllTarget.filter(
                target => target.Account__c === customer.Id
            )
            : [];

        // Calculate subtotals
        let quantity = 0;
        let salesValue = 0;
        let gmKg = 0;
        let cogsValue = 0;

        customerTargets.forEach(target => {
            quantity += parseFloat(target.Sales_Quantity__c) || 0;
            salesValue += parseFloat(target.Sales_Value__c) || 0;
            gmKg += parseFloat(target.GM_Kg__c) || 0;
            cogsValue += parseFloat(target.COGS_Value__c) || 0;
        });

        return {
            ...customer,
            isExpanded: false,
            iconName: 'utility:chevronright',
            Products: [],
            subTotal: {
                quantity: quantity.toFixed(2),
                salesValue: salesValue.toFixed(2),
                gmKg: gmKg.toFixed(2),
                cogsValue: cogsValue.toFixed(2)
            }
        };
    });
}






generateCustomerProductMonthData(customers, products, existingRecords = []) {
    const startDate = new Date(this.fiscalStartDate);
    const endDate = new Date(this.fiscalEndDate);
    const today = new Date();
    //this.showSpinner = true;

    // Generate the list of months in range
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

    const generateRandomIndex = () => Math.floor(1000 + Math.random() * 9000).toString();

    // Enrich products with 12 months data
    const enrichProduct = (product) => {
        const monthList = monthsInRange.map(monthObj => {
            const [monthName, year] = monthObj.monthYear.split('-');

            const existing = existingRecords.find(rec =>
                rec.Product__c === product.Id &&
                rec.Month__c === monthName &&
                String(rec.Year__c) === year
            );

            const quantity = existing ? parseFloat(existing.Sales_Quantity__c) || 0 : 0;
            const price = existing ? parseFloat(existing.Budget_Rate__c) || 0 : 0;

            return {
                index: generateRandomIndex(),
                MonthName: monthObj.monthYear,
                // disabled: monthObj.isPast,
                disabled: false,
                uId: existing?.Id || null,
                COGS_Kg__c: existing?.Budgeted_COGS__c?.toString() || "0.00",
                GM_Kg__c: existing?.GM_Kg__c?.toString() || "0.00",
                GM_Value__c: existing?.Gross_Margin__c?.toString() || "0.00",
                COGS_Value__c: existing?.COGS_Value__c?.toString() || "0.00",
                Price__c: price.toFixed(2),
                Sales_Qauntity__c: quantity,
                Sales_Value__c: (quantity * price).toFixed(2),
                month: monthObj
            };
        });

        return {
            ...product,
            iconName: 'utility:chevronright',
            isExpanded: false,
            isChanged: false,
            MonthList: monthList
        };
    };

    // Attach enriched product list to each customer
    const finalData = customers.map(customer => {
        const enrichedProducts = products.map(p => enrichProduct(p));
        return {
            ...customer,
            Products: enrichedProducts
        };
    });

    // Simulate delay and update state
    setTimeout(() => {
        this.hasDataInTable = finalData.length > 0;
        //this.showSpinner = false;
    }, 1000);

    return finalData;
}


toggleRow(event) {
    const customerId = event.currentTarget.dataset.key;
    console.log('customerId -->', customerId,JSON.stringify(this.vAllData));

    const updatedData = this.vAllData.map(group => {
        const isClicked = group.Id === customerId;
        const shouldExpand = true;
        console.log('isClicked -->', isClicked);

        if (isClicked) {
            // 🔍 Find existing full customer record in vAllData
            const existingCustomer = this.vAllData.find(c => c.Id === customerId);

            // Ensure we always retain existing data
            let enrichedProducts = [];

            if (existingCustomer && (!existingCustomer.Products || existingCustomer.Products.length === 0)) {
                // Products not initialized yet — use allProducts
                enrichedProducts = this.allProducts.map(product => ({
                    ...product,
                    uId: null,
                    Sales_Quantity__c: 0,
                    Budget_Rate__c: 0,
                    Sales_Value__c: "0.00",
                    isExpanded: false,
                    iconName: 'utility:chevronright',
                    isChanged: false,
                    MonthList: []
                }));
            } else if (existingCustomer) {
                // Products already exist — enrich by syncing with `this.allProducts` in case any new product was added
                enrichedProducts = this.allProducts.map(baseProduct => {
                    const existingProduct = existingCustomer.Products.find(p => p.Id === baseProduct.Id);

                    return existingProduct
                        ? { ...baseProduct,isExpanded: false,iconName: 'utility:chevronright', ...existingProduct,isExpanded: false,iconName: 'utility:chevronright' } // Keep full state from existing
                        : {
                            ...baseProduct,
                            uId: null,
                            Sales_Quantity__c: 0,
                            Budget_Rate__c: 0,
                            Sales_Value__c: "0.00",
                            isExpanded: false,
                            iconName: 'utility:chevronright',
                            isChanged: false,
                            MonthList: []
                        };
                });
            }

            return {
                ...group,
                Products: enrichedProducts,
                isExpanded: shouldExpand,
                iconName: shouldExpand ? 'utility:chevrondown' : 'utility:chevronright'
            };
        }

        return group;
    });

    this.vData = [...updatedData];
    this.vAllData = [...updatedData];
    this.updateTotals(this.vAllData);
}


async toggleRowProduct(event) {
    const productId = event.currentTarget.dataset.key;
    const customerId = event.currentTarget.dataset.parentId;

    const existingTarget = await this.getExistingTarget(customerId);
    console.log('Existing Data -->', existingTarget.length);

    // Clone and update vAllData
    const updatedAllData = this.vAllData.map(customer => {
        if (customer.Id !== customerId) return customer;

        const updatedProducts = customer.Products.map(product => {
            if (product.Id !== productId) return product;

            const shouldExpand = !product.isExpanded;
            const existingMonthList = product.MonthList || [];
            const usedMonthKeys = new Set(existingMonthList.map(m => m.MonthName));
            const usedIndexes = new Set(existingMonthList.map(m => m.index));

            // Step 1: Build all fiscal months
            const monthsInRange = [];
            const current = new Date(this.fiscalStartDate);
            const endDate = new Date(this.fiscalEndDate);
            const today = new Date();

            while (current <= endDate) {
                const month = current.getMonth();
                const year = current.getFullYear();
                const monthName = current.toLocaleString('default', { month: 'long' });
                const monthYear = `${monthName}-${year}`;

                monthsInRange.push({
                    key: monthYear,
                    month,
                    year,
                    monthName,
                    monthYear,
                    isPast: new Date(year, month + 1, 0) < today
                });

                current.setMonth(current.getMonth() + 1);
            }

            // Step 2: Add missing months only
            const generateRandomIndex = () => {
                let index;
                do {
                    index = Math.floor(1000 + Math.random() * 9000).toString();
                } while (usedIndexes.has(index));
                usedIndexes.add(index);
                return index;
            };

            const updatedMonthList = [...existingMonthList]; // preserve existing months

            for (const monthObj of monthsInRange) {
                const { monthYear, month, year, isPast } = monthObj;

                if (!usedMonthKeys.has(monthYear)) {
                    const existing = existingTarget.find(rec => {
                        const recMonthIndex = new Date(`${rec.Month__c} 1, ${rec.Year__c}`).getMonth();
                        return (
                            rec.Product__c === product.Id &&
                            rec.Account__c === customer.Id &&
                            recMonthIndex === month &&
                            String(rec.Year__c) === String(year)
                        );
                    });

                    const quantity = existing ? parseFloat(existing.Sales_Quantity__c) || 0 : 0;
                    const price = existing ? parseFloat(existing.Budget_Rate__c) || 0 : 0;

                    updatedMonthList.push({
                        index: generateRandomIndex(),
                        MonthName: monthYear,
                        disabled: isPast,
                        uId: existing?.Id || null,
                        COGS_Kg__c: existing?.COGS_Rate__c?.toString() || "0.00",
                        GM_Kg__c: existing?.GM_Kg__c?.toString() || "0.00",
                        GM_Value__c: existing?.Gross_Margin__c?.toString() || "0.00",
                        COGS_Value__c: existing?.COGS_Value__c?.toString() || "0.00",
                        Price__c: price.toFixed(2),
                        Sales_Qauntity__c: quantity,
                        Sales_Value__c: (quantity * price).toFixed(2),
                        month: monthObj
                    });

                    usedMonthKeys.add(monthYear);
                }
            }

            return {
                ...product,
                isExpanded: shouldExpand,
                iconName: shouldExpand ? 'utility:chevrondown' : 'utility:chevronright',
                MonthList: updatedMonthList
            };
        });

        return {
            ...customer,
            Products: updatedProducts
        };
    });

    this.vAllData = [...updatedAllData];

    // Build filtered view for UI (vData)
    this.vData = updatedAllData.map(customer => {
        const filteredProducts = customer.Products.map(product => {
            const filteredMonthList = this.searchCriteria?.month
                ? (product.MonthList || []).filter(m =>
                    m.MonthName.toLowerCase().includes(this.searchCriteria.month.toLowerCase())
                )
                : product.MonthList;

            return {
                ...product,
                MonthList: filteredMonthList
            };
        });

        return {
            ...customer,
            Products: filteredProducts
        };
    });

    this.updateTotals(this.vData);
}



  @track existingAllTarget = [];
 getAllExistingDatav1() {
    getAllExistingData({ usId: this.salesEmployeeId, fyId: this.fiscalId })
        .then(result => {
            console.log('result Existing-All->', JSON.stringify(result));
            
            if (Array.isArray(result) && result.length > 0) {
                //return JSON.parse(JSON.stringify(result));
                this.existingAllTarget = JSON.parse(JSON.stringify(result));
            }
            //return [];
        })
        .catch(error => {
            console.error('Error fetching existing data:', error);
            this.existingAllTarget = [];
        });
}

  @track existingTarget = [];
    getExistingTarget(accId) {
    return getExistingData({ usId: this.salesEmployeeId, fyId: this.fiscalId, accId })
        .then(result => {
            console.log('result Existing-->', JSON.stringify(result));
            
            if (Array.isArray(result) && result.length > 0) {
                return JSON.parse(JSON.stringify(result));
            }
            return [];
        })
        .catch(error => {
            console.error('Error fetching existing data:', error);
            return [];
        });
}



updateTotals(data) {
    for (let customer of data) {
        let customerQty = 0;
        let customerSalesVal = 0;
        let customerGMVal = 0;
        let customerCOGSVal = 0;

        for (let product of customer.Products) {
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

            product.subTotal = {
                quantity: quantity.toFixed(2),
                salesValue: salesValue.toFixed(2),
                gmValue: gmValue.toFixed(2),
                cogsValue: cogsValue.toFixed(2)
            };

            // Add to customer-level totals
            customerQty += quantity;
            customerSalesVal += salesValue;
            customerGMVal += gmValue;
            customerCOGSVal += cogsValue;
        }

        customer.subTotal = {
            quantity: customerQty.toFixed(2),
            salesValue: customerSalesVal.toFixed(2),
            gmValue: customerGMVal.toFixed(2),
            cogsValue: customerCOGSVal.toFixed(2)
        };
    }

    this.vData = [...data];
    console.log('updated sub total-->',JSON.stringify(this.vData));
    
    this.computeGrandTotals();
}


ValChange(event) {
    const pId = event.target.dataset.id; // productId
    const cId = event.target.dataset.parentId; // customerId
    const monthIndex = event.target.dataset.index;
    const field = event.target.dataset.label;
    const uId = event.target.dataset.valId;
    const value = parseFloat(event.target.value) || 0;

    // Find customer and product in vAllData
    const customerIndex = this.vAllData.findIndex(c => c.Id === cId);
    if (customerIndex === -1) return;

    const customer = this.vAllData[customerIndex];

    const productIndex = customer.Products.findIndex(p => p.Id === pId);
    if (productIndex === -1) return;

    const product = customer.Products[productIndex];

    // 🔍 Update the matching month (by index) in vAllData
    const fullMonth = product.MonthList.find(m => m.index === monthIndex);
    if (!fullMonth) return;

    // Mark product as changed
    if (!uId) {
        product.isChanged = true;
    }

    // ✅ Update field value and recalculate derived fields
    fullMonth[field] = value;

    const quantity = parseFloat(fullMonth.Sales_Qauntity__c) || 0;
    const price = parseFloat(fullMonth.Price__c) || 0;
    const cogsKg = parseFloat(fullMonth.COGS_Kg__c) || 0;

    const gmKg = price - cogsKg;

    fullMonth.GM_Kg__c = gmKg.toFixed(2);
    fullMonth.Sales_Value__c = (quantity * price).toFixed(2);
    fullMonth.COGS_Value__c = (quantity * cogsKg).toFixed(2);
    fullMonth.GM_Value__c = gmKg !== 0 ? (quantity / gmKg).toFixed(2) : "0.00";

    // 🔁 Update value in backend (debounced)
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

    // 🧮 Recalculate product subtotal (for filtered month view)
    const monthFilter = this.searchCriteria?.month?.toLowerCase();
    const filteredMonthList = monthFilter
        ? product.MonthList.filter(m => m.MonthName?.toLowerCase().includes(monthFilter))
        : product.MonthList;

    let totalQty = 0, totalSales = 0, totalGM = 0, totalCOGS = 0;

    for (let m of filteredMonthList) {
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

    // 🔁 Sync subTotal and Month data to filtered vData if visible
    const vDataCustomerIndex = this.vData.findIndex(c => c.Id === cId);
    if (vDataCustomerIndex !== -1) {
        const vDataProductIndex = this.vData[vDataCustomerIndex].Products.findIndex(p => p.Id === pId);
        if (vDataProductIndex !== -1) {
            // Update subtotal in filtered view
            this.vData[vDataCustomerIndex].Products[vDataProductIndex].subTotal = product.subTotal;

            // Also update matching month in filtered view (if it's shown)
            const visibleMonth = this.vData[vDataCustomerIndex].Products[vDataProductIndex].MonthList?.find(m => m.index === monthIndex);
            if (visibleMonth) {
                Object.assign(visibleMonth, fullMonth); // shallow merge
            }
        }
    }

    // 🔄 Recompute grand totals (filtered view)
    this.computeGrandTotals();
}



computeGrandTotals() {
    let grandTotalQty = 0;
    let grandTotalGMKg = 0;
    let grandTotalSalesVal = 0;
    let grandTotalCOGSVal = 0;

    // Optional: Store per-customer subtotals
    this.vAllData.forEach(customer => {
        let customerTotalQty = 0;
        let customerTotalGMKg = 0;
        let customerTotalSalesVal = 0;
        let customerTotalCOGSVal = 0;

        customer.Products.forEach(product => {
            product.MonthList.forEach(month => {
                const qty = parseFloat(month.Sales_Qauntity__c) || 0;
                const gmKg = parseFloat(month.GM_Kg__c) || 0;
                const salesVal = parseFloat(month.Sales_Value__c) || 0;
                const cogsVal = parseFloat(month.COGS_Value__c) || 0;

                customerTotalQty += qty;
                customerTotalGMKg += gmKg;
                customerTotalSalesVal += salesVal;
                customerTotalCOGSVal += cogsVal;
            });
        });

        // Add to grand totals
        grandTotalQty += customerTotalQty;
        grandTotalGMKg += customerTotalGMKg;
        grandTotalSalesVal += customerTotalSalesVal;
        grandTotalCOGSVal += customerTotalCOGSVal;

        // Optional: Store per-customer subtotal if needed in UI
        customer.subTotal = {
            quantity: customerTotalQty.toFixed(2),
            gmKg: customerTotalGMKg.toFixed(2),
            salesValue: customerTotalSalesVal.toFixed(2),
            cogsValue: customerTotalCOGSVal.toFixed(2)
        };
    });

    this.displayTotals = {
        Total_Sales_Quantity: grandTotalQty.toFixed(2),
        Total_GM_Kg: grandTotalGMKg.toFixed(2),
        Total_Sales_Value: `₹${grandTotalSalesVal.toFixed(2)}`,
        Total_COGS_Value: `₹${grandTotalCOGSVal.toFixed(2)}`,

        // Removed unused totals unless you really need them
        Total_Price: `₹0.00`,
        Total_GM_Value: `₹0.00`,
        Total_COGS_Kg: `0.00`
    };
}


saveRecords() {
    let recordsToSave = [];
    this.saveDisabled = true;
    this.showSpinner = true;

    this.vAllData.forEach(customer => {
        customer.Products.forEach(product => {
            if (product.isChanged) {
                product.MonthList.forEach(month => {
                    if (
                        !month.disabled &&
                        month.uId === null &&
                        Number(month.Sales_Qauntity__c) > 0
                    ) {
                        recordsToSave.push({
                            CustomerId: customer.Id,
                            ProductId: product.Id,
                            ProductName: product.Name,
                            ProductCode: product.ProductCode,
                            Description: product.Description,
                            MonthName: month.MonthName,
                            Sales_Qauntity__c: Number(month.Sales_Qauntity__c),
                            Price__c: Number(month.Price__c),
                            Sales_Value__c: Number(month.Sales_Value__c),
                            COGS_Kg__c: Number(month.COGS_Kg__c)
                        });
                    }
                });
            }
        });
    });

    if (recordsToSave.length === 0) {
        this.saveDisabled = false;
        this.showSpinner = false;
        console.log('No records to save.');
        this.f_msg('Info', 'No new records to save.', 'info');
        return;
    }

    // Call Apex method
    saveToServer({
        js: JSON.stringify(recordsToSave),
        userId: this.salesEmployeeId,
        fyId: this.fiscalId
    })
        .then(result => {
            this.showSpinner = false;
            this.saveDisabled = false;
            this.monthVal = null;

            if (result === 'Success') {
                this.f_msg('Success', 'Records saved successfully', 'success');
                this.handleCancel(); // clear form or refresh UI
            } else {
                this.f_msg('Error', result, 'error');
            }
        })
        .catch(error => {
            console.error('Error saving:', error);
            this.showSpinner = false;
            this.saveDisabled = false;
            this.f_msg('Error', 'Something went wrong while saving.', 'error');
        });
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
            
            // this.getExistingTarget();

            this.refreshTimeout = setTimeout(() => {
                window.location.reload();
            }, 1000);
        }
    }

get shouldShowFooter() {
    return this.vAllData.some(customer =>
        customer.Products.some(product =>
            product.isChanged &&
            product.MonthList.some(month => month.uId == null)
        )
    );
}


    searchCriteria = {
        customerName: '',
        month: '',
        productName:''
    };

handleSearchChange(event) {
    const searchType = event.target.dataset.type;
    const searchValue = event.target.value?.toLowerCase() || '';

    // Update the appropriate search criteria
    this.searchCriteria[searchType] = searchValue;

    // Extract search filters
    const searchCustomer = this.searchCriteria.customerName || '';
    const searchMonth = this.searchCriteria.month || '';

    // Generate filtered vData from full vAllData
    this.vData = this.vAllData
        .map(customer => {
            const customerNameMatch = customer.Name?.toLowerCase().includes(searchCustomer);

            const filteredProducts = customer.Products
                .map(product => {
                    const fullMonthList = product.MonthList || [];

                    // Filter by month (if given)
                    let filteredMonthList = fullMonthList;
                    if (searchMonth) {
                        filteredMonthList = fullMonthList.filter(month =>
                            month.MonthName?.toLowerCase().includes(searchMonth)
                        );
                    }

                    // Exclude product if no matching months
                    if (!filteredMonthList || filteredMonthList.length === 0) return null;

                    return {
                        ...product,
                        isExpanded: false,
                        iconName: 'utility:chevronright',
                        MonthList: filteredMonthList
                    };
                })
                .filter(p => p !== null);

            // Include customer only if name matches or has filtered products
            if (customerNameMatch || filteredProducts.length > 0) {
                return {
                    ...customer,
                    isExpanded: false,
                    iconName: 'utility:chevronright',
                    Products: filteredProducts
                };
            }

            return null;
        })
        .filter(c => c !== null);

    // Recalculate totals
    this.updateTotals(this.vData);
}






}