import { LightningElement, track } from 'lwc';
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
        getDefualtAccount({ ownerId: this.salesEmployeeId }).then(result => {

            console.log('result-->', JSON.stringify(result));
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
            console.log('=== RAW PRODUCT DATA FROM APEX ===');
            result.forEach((product, index) => {
                console.log(`${index + 1}. ${product.Name} - Item_Group__c: ${product.Item_Group__c}, Item_Group__r:`, product.Item_Group__r);
            });

            this.allProducts = JSON.parse(JSON.stringify(result));

            // Ensure products have proper Item Group structure
            this.allProducts = this.allProducts.map(product => ({
                ...product,
                Item_Group__c: product.Item_Group__c || null,
                Item_Group__r: product.Item_Group__r || { Name: '' }
            }));

            console.log('=== AFTER PROCESSING ===');
            this.allProducts.forEach((product, index) => {
                console.log(`${index + 1}. ${product.Name} - Item_Group__c: ${product.Item_Group__c}, Item_Group__r.Name: ${product.Item_Group__r?.Name}`);
            });

            this.vData = this.generateCustomer(this.allCustomerData);
            this.vAllData = this.vData;

            console.log('=== FINAL CUSTOMER DATA ===');
            this.vAllData.forEach(customer => {
                console.log(`Customer: ${customer.Name} - Products: ${customer.Products.length}`);
                customer.Products.forEach(product => {
                    console.log(`  - ${product.Name}: Item_Group__c=${product.Item_Group__c}`);
                });
            });

            setTimeout(() => {
                this.showSpinner = false;
                this.hasDataInTable = this.vData.length > 0;
            }, 1000);
        });
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

            // 🚨 CRITICAL FIX: Assign actual products to customers
            const customerProducts = this.allProducts.map(product => ({
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

            return {
                ...customer,
                isExpanded: false,
                iconName: 'utility:chevronright',
                Products: customerProducts, // 🚨 This was empty before!
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
        console.log('customerId -->', customerId);

        const updatedData = this.vData.map(group => {
            const isClicked = group.Id === customerId;
            const shouldExpand = isClicked ? !group.isExpanded : false;

            console.log('isClicked -->', isClicked);
            console.log('shouldExpand -->', shouldExpand);
            console.log('group.Products -->', group.Products.length);

            // Only enrich and group if expanding and no products loaded yet
            if (isClicked && shouldExpand && group.Products.length === 0) {
                console.log('🔄 Loading products for customer:', customerId);

                // Enrich all products with default values
                const enrichedProducts = this.allProducts.map(product => ({
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

                // Group enriched products by Item_Group__c (but skip products without Item_Group__c)
                const productGroupMap = {};

                enrichedProducts.forEach(product => {
                    const groupKey = product.Item_Group__c?.trim(); // Avoid null/undefined/empty strings

                    if (groupKey) {
                        if (!productGroupMap[groupKey]) {
                            productGroupMap[groupKey] = [];
                        }
                        productGroupMap[groupKey].push(product);
                    }
                });

                // Convert the map to an array of group objects
                const groupedProducts = Object.keys(productGroupMap).map(groupName => ({
                    groupName,
                    isGroup: true,
                    isExpanded: true,
                    iconName: 'utility:chevrondown',
                    Products: productGroupMap[groupName]
                }));

                return {
                    ...group,
                    Products: groupedProducts,
                    isExpanded: true,
                    iconName: 'utility:chevrondown'
                };
            }

            // Just toggle the expansion state for clicked row
            if (isClicked) {
                return {
                    ...group,
                    isExpanded: shouldExpand,
                    iconName: shouldExpand ? 'utility:chevrondown' : 'utility:chevronright'
                };
            }

            return group;
        });

        this.vData = [...updatedData];
        this.vAllData = [...updatedData];

        console.log('📊 Updated vData:', JSON.stringify(this.vData));
    }


    async toggleRowProduct(event) {
        const productId = event.currentTarget.dataset.key;
        const customerId = event.currentTarget.dataset.parentId;

        const existingTarget = await this.getExistingTarget(customerId);
        console.log('Existing Data-->', existingTarget.length);

        const updatedData = this.vData.map(customer => {
            if (customer.Id === customerId) {
                const updatedProducts = customer.Products.map(product => {
                    const isClickedProduct = product.Id === productId;
                    const shouldExpand = isClickedProduct ? !product.isExpanded : false;

                    let monthList = product.MonthList;

                    if (isClickedProduct && shouldExpand && (!monthList || monthList.length === 0)) {
                        const startDate = new Date(this.fiscalStartDate);
                        const endDate = new Date(this.fiscalEndDate);
                        const today = new Date();

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

                        // 💡 Apply search filter by month (if provided)
                        let filteredMonthsInRange = monthsInRange;
                        const searchMonth = this.searchCriteria?.month?.toLowerCase();
                        if (searchMonth) {
                            filteredMonthsInRange = filteredMonthsInRange.filter(m =>
                                m.monthYear?.toLowerCase().includes(searchMonth)
                            );
                        }

                        monthList = filteredMonthsInRange.map(monthObj => {
                            const [monthName, year] = monthObj.monthYear.split('-');

                            let existing = null;
                            if (existingTarget.length > 0) {
                                existing = existingTarget.find(rec =>
                                    rec.Product__c === product.Id &&
                                    rec.Account__c === customer.Id &&
                                    rec.Month__c === monthName &&
                                    String(rec.Year__c) === year
                                );

                                console.log(product.Id, customer.Id, monthName, year + ' e->re->', existing);
                            }

                            const quantity = existing ? parseFloat(existing.Sales_Quantity__c) || 0 : 0;
                            const price = existing ? parseFloat(existing.Budget_Rate__c) || 0 : 0;

                            return {
                                index: generateRandomIndex(),
                                MonthName: monthObj.monthYear,
                                disabled: monthObj.isPast,
                                uId: existing?.Id || null,
                                COGS_Kg__c: existing?.COGS_Rate__c?.toString() || "0.00",
                                GM_Kg__c: existing?.GM_Kg__c?.toString() || "0.00",
                                GM_Value__c: existing?.Gross_Margin__c?.toString() || "0.00",
                                COGS_Value__c: existing?.COGS_Value__c?.toString() || "0.00",
                                Price__c: price.toFixed(2),
                                Sales_Qauntity__c: quantity,
                                Sales_Value__c: (quantity * price).toFixed(2),
                                month: monthObj
                            };
                        });
                    }

                    return {
                        ...product,
                        isExpanded: shouldExpand,
                        iconName: shouldExpand ? 'utility:chevrondown' : 'utility:chevronright',
                        MonthList: monthList || []
                    };
                });

                return {
                    ...customer,
                    Products: updatedProducts
                };
            }

            return customer;
        });

        this.vData = [...updatedData];
        this.vAllData = [...updatedData];

        this.updateTotals(this.vAllData);
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
        console.log('updated sub total-->', JSON.stringify(this.vData));

        this.computeGrandTotals();
    }



    ValChange(event) {
        const pId = event.target.dataset.id; // productId
        const cId = event.target.dataset.parentId; // customerId

        const monthIndex = event.target.dataset.index;
        const field = event.target.dataset.label;
        const uId = event.target.dataset.valId;
        const value = parseFloat(event.target.value) || 0;

        // Step 1: Find customer by cId
        const customerIndex = this.vAllData.findIndex(c => c.Id === cId);
        if (customerIndex === -1) return;

        const customer = this.vAllData[customerIndex];

        // Step 2: Find product by pId under customer
        const productIndex = customer.Products.findIndex(p => p.Id === pId);
        if (productIndex === -1) return;

        const product = customer.Products[productIndex];

        // Step 3: Find month by index
        const month = product.MonthList.find(m => m.index === monthIndex);
        if (!month) return;

        // Mark product as changed if no existing uId
        if (!uId) {
            product.isChanged = true;
        }

        // Update the field value
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

        // Debounced Apex update
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

        // 🧮 Recalculate subtotals for filtered months
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

        // 🧠 Sync back to this.vData (filtered view)
        const vDataCustomerIndex = this.vData.findIndex(c => c.Id === cId);
        if (vDataCustomerIndex !== -1) {
            const productInVDataIndex = this.vData[vDataCustomerIndex].Products.findIndex(p => p.Id === pId);
            if (productInVDataIndex !== -1) {
                this.vData[vDataCustomerIndex].Products[productInVDataIndex].subTotal = product.subTotal;
            }
        }

        // 🔄 Recompute grand totals
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
        productName: '',
        materialGroupDesc: ''
    };

    handleSearchChange(event) {
        const searchType = event.target.dataset.type;
        const searchValue = event.target.value?.toLowerCase() || '';

        console.log(`🔍 Search Changed: [${searchType}] = "${searchValue}"`);

        // Update the appropriate search criteria
        this.searchCriteria[searchType] = searchValue;

        console.log('📌 Current Search Criteria:', JSON.stringify(this.searchCriteria));

        this.vData = this.vAllData
            .map(customer => {
                const customerNameMatch = customer.Name?.toLowerCase().includes(this.searchCriteria.customerName || '');

                const filteredProducts = customer.Products
                    .map(product => {
                        const productNameMatch = product.Name?.toLowerCase().includes(this.searchCriteria.productName || '');
                        const productCodeMatch = product.ProductCode?.toLowerCase().includes(this.searchCriteria.productName || '');
                        const itemGroupValue = product.Item_Group__c?.toLowerCase() || '';
                        const materialGroupMatch = itemGroupValue.includes(this.searchCriteria.materialGroupDesc || '');

                        const matchesProduct = (productNameMatch || productCodeMatch || materialGroupMatch);

                        if (!matchesProduct) return null;

                        // Filter MonthList
                        let filteredMonthList = product.MonthList;
                        if (this.searchCriteria.month) {
                            filteredMonthList = filteredMonthList?.filter(month =>
                                month.MonthName?.toLowerCase().includes(this.searchCriteria.month)
                            );
                        }

                        if (!filteredMonthList || filteredMonthList.length === 0) return null;

                        console.log(`🧪 Product Check: ${product.Name} | Name Match: ${productNameMatch}, Code Match: ${productCodeMatch}, Group Match: ${materialGroupMatch} => ${matchesProduct}`);
                        console.log(`   Item_Group__c: "${product.Item_Group__c}", Searching for: "${this.searchCriteria.materialGroupDesc}"`);

                        return {
                            ...product,
                            MonthList: filteredMonthList
                        };
                    })
                    .filter(p => p !== null);

                if (customerNameMatch || filteredProducts.length > 0) {
                    console.log(`✅ Including Customer: ${customer.Name} with ${filteredProducts.length} products`);
                    return {
                        ...customer,
                        Products: filteredProducts
                    };
                }

                console.log(`❌ Excluding Customer: ${customer.Name}`);
                return null;
            })
            .filter(c => c !== null);

        console.log('📊 Filtered Data:', this.vData);
        this.updateTotals(this.vData);
    }



}