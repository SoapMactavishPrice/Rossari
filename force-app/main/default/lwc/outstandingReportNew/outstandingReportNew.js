import { LightningElement, track } from 'lwc';
import getBudget from '@salesforce/apex/BudgetReport.getBudget';
import getBudgetSummary from '@salesforce/apex/BudgetReport.getBudgetSummary';
import getDefualtFiscId from '@salesforce/apex/BudgetReport.getDefualtFiscId';

export default class OutstandingReportNew extends LightningElement {
    @track vData = [];
    @track vAllData = [];
    @track showSpinner = false;
    connectedCallback() {

        this.getDefualtFiscsId();
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

    getDefualtFiscsId() {
        getDefualtFiscId().then(result => {
            this.fiscalId = result;
            this.getBudgetery();
            this.getBudgeterySummary();
        })
    }

    getBudgeterySummary() {
        getBudgetSummary({ userId: this.salesEmployeeId, fiscId: this.fiscalId })
            .then(result => {
                console.log('result -->', result);
                console.log('Before update -->', this.displayTotals);

                this.displayTotals.Total_Sales_Quantity = parseFloat(result.Total_Sales_Quantity).toFixed(2);
                this.displayTotals.Total_Price = this.formatCurrency(result.Total_Price);
                this.displayTotals.Total_GM_Kg = parseFloat(result.Total_GM_Kg).toFixed(2);
                this.displayTotals.Total_COGS_Value = this.formatCurrency(result.Total_COGS_Value);
                this.displayTotals.Total_COGS_Kg = parseFloat(result.Total_COGS_Kg).toFixed(2);
                this.displayTotals.Total_GM_Value = this.formatCurrency(result.Total_GM_Value);
                this.displayTotals.Total_Sales_Value = this.formatCurrency(result.Total_Sales_Value);

                console.log('After update -->', this.displayTotals);
            })
            .catch(error => {
                console.error('Error fetching budget summary:', error);
            });
    }

    // Utility method
    formatCurrency(value) {
        const num = parseFloat(value || 0);
        return `₹${num.toFixed(2)}`;
    }


    @track fiscalId = '';
    @track salesEmployeeId = '';
    handleFiscalChange(event) {
        this.fiscalId = event.target.value;
        if (this.fiscalId != '' && this.fiscalId != null) {
            this.getBudgetery();
            this.getBudgeterySummary();
        } else {
            this.vData = [];
            this.vAllData = [];
        }
    }

    handleSalesEmpChange(event) {
        this.salesEmployeeId = event.target.value;
        if (this.salesEmployeeId != '' && this.salesEmployeeId != null) {
            this.getBudgetery();
            this.getBudgeterySummary();
        } else {
            this.vData = [];
            this.vAllData = [];
        }
    }




    getBudgetery() {
        this.showSpinner = true;
        setTimeout(() => {
            getBudget({ userId: this.salesEmployeeId, fiscId: this.fiscalId }).then(result => {
                this.showSpinner = false;

                this.vData = this.groupByCustomerWithMonth(result);
                this.vAllData = this.groupByCustomerWithMonth(result);
                console.log('vData-->', JSON.stringify(this.vData));
            })
        }, 2000);

    }



    groupByCustomerWithMonth(data) {
        const groupedMap = {};

        data.forEach(row => {
            const customerId = row.Customer_Name__c;
            const customerName = row.Customer_Name__r?.Name || null;
            const salesOrg = row.Sales_Organisations__r?.Name || null;
            const distChannel = row.Distribution_Channel__r?.Name || null;
            const division = row.Division__r?.Name || null;
            const Customer_Code = row.Customer_Code__c || null;
            const month = row.Month__c;
            const year = row.Year__c;
            const monthYearKey = `${month}-${year}`;

            // Create customer entry if not already present
            if (!groupedMap[customerId]) {
                groupedMap[customerId] = {
                    customerId,
                    customerName,
                    Sales_Organisations: salesOrg,
                    Distribution_Channel: distChannel,
                    Division: division,
                    Customer_Code,
                    isExpanded: false,
                    iconName: 'utility:chevronright',
                    monthWiseGroupedCustomers: [] // Initialize array
                };
            }

            const customer = groupedMap[customerId];

            // Find or create the month group inside monthWiseGroupedCustomers
            let monthGroup = customer.monthWiseGroupedCustomers.find(m => m.month === monthYearKey);

            if (!monthGroup) {
                monthGroup = {
                    month: monthYearKey,
                    isExpanded: false,
                    iconName: 'utility:chevronright',
                    totalQuantity: 0,
                    totalPrice: 0,
                    totalGMKg: 0,
                    totalCOGSKg: 0,
                    totalCOGSVal: 0,
                    totalGMVal: 0,
                    totalSalesVal: 0,
                    Material: []
                };
                customer.monthWiseGroupedCustomers.push(monthGroup);
            }

            // Add material record
            monthGroup.Material.push({
                Product_Description__c: row.Product_Description__c,
                COGS_Kg__c: parseFloat(row.COGS_Kg__c).toFixed(2),
                COGS_Value__c: parseFloat(row.COGS_Value__c).toFixed(2),
                GM_Kg__c: parseFloat(row.GM_Kg__c).toFixed(2),
                GM_Value__c: parseFloat(row.GM_Value__c).toFixed(2),
                Price__c: parseFloat(row.Price__c).toFixed(2),
                Sales_Value__c: parseFloat(row.Sales_Value__c).toFixed(2),
                Sales_Quantity__c: parseFloat(row.Sales_Quantity__c || 0),
                Material_Group_Desc__c: row.Material_Group_Desc__c,
                Product_code__c: row.Product_code__c,
                Product_Description: row.Product_Description__r?.Name || null
            });

            // Accumulate totals
            monthGroup.totalQuantity += parseFloat(row.Sales_Quantity__c || 0);
            monthGroup.totalPrice += parseFloat(row.Price__c || 0);
            monthGroup.totalGMKg += parseFloat(row.GM_Kg__c || 0);
            monthGroup.totalCOGSKg += parseFloat(row.COGS_Kg__c || 0);
            monthGroup.totalCOGSVal += parseFloat(row.COGS_Value__c || 0);
            monthGroup.totalGMVal += parseFloat(row.GM_Value__c || 0);
            monthGroup.totalSalesVal += parseFloat(row.Sales_Value__c || 0);
        });

        // Format totals
        Object.values(groupedMap).forEach(customer => {
            customer.monthWiseGroupedCustomers.forEach(monthGroup => {
                monthGroup.totalPrice = monthGroup.totalPrice.toFixed(2);
                monthGroup.totalGMKg = monthGroup.totalGMKg.toFixed(2);
                monthGroup.totalCOGSKg = monthGroup.totalCOGSKg.toFixed(2);
                monthGroup.totalCOGSVal = monthGroup.totalCOGSVal.toFixed(2);
                monthGroup.totalGMVal = monthGroup.totalGMVal.toFixed(2);
                monthGroup.totalSalesVal = monthGroup.totalSalesVal.toFixed(2);
            });
        });

        return Object.values(groupedMap);
    }



    toggleRow(event) {
        const partyName = event.currentTarget.dataset.key;

        const updatedData = this.vData.map(group => {
            const isClicked = group.customerId === partyName;
            const shouldExpand = isClicked ? !group.isExpanded : false;

            return {
                ...group,
                isExpanded: shouldExpand,
                iconName: shouldExpand ? 'utility:chevrondown' : 'utility:chevronright'
            };
        });

        this.vData = [...updatedData]; // Trigger reactivity
    }


    toggleRowMonth(event) {
        const partyName = event.currentTarget.dataset.key;
        const clickedMonth = event.currentTarget.dataset.month;
        console.log(partyName, clickedMonth);


        const updatedData = this.vData.map(group => {
            if (group.customerId === partyName) {
                group.monthWiseGroupedCustomers = group.monthWiseGroupedCustomers.map(monthEntry => {
                    if (monthEntry.month === clickedMonth) {
                        const shouldExpand = !monthEntry.isExpanded;
                        return {
                            ...monthEntry,
                            isExpanded: shouldExpand,
                            iconName: shouldExpand ? 'utility:chevrondown' : 'utility:chevronright'
                        };
                    } else {
                        return {
                            ...monthEntry,
                            isExpanded: false,
                            iconName: 'utility:chevronright'
                        };
                    }
                });
            }
            return group;
        });

        this.vData = [...updatedData]; // Trigger reactivity
    }


    handleSearch() {

    }


    searchCriteria = {
        customerName: '',
        month: ''
    };


    handleSearchChange(event) {
        const searchType = event.target.dataset.type;
        const searchValue = event.target.value.toLowerCase();

        // Update search criteria
        this.searchCriteria[searchType] = searchValue;

        // Apply filtering
        this.vData = this.vAllData
            .filter(customer => {
                const matchesCustomer = customer.customerName?.toLowerCase().includes(this.searchCriteria.customerName);

                const matchesMonth = this.searchCriteria.month
                    ? customer.monthWiseGroupedCustomers?.some(m => m.month?.toLowerCase().includes(this.searchCriteria.month))
                    : true;

                return matchesCustomer && matchesMonth;
            })
            .map(customer => {
                // Clone the customer object
                const newCustomer = { ...customer };

                if (this.searchCriteria.month) {
                    // Filter monthWiseGroupedCustomers to include only the matching month
                    newCustomer.monthWiseGroupedCustomers = customer.monthWiseGroupedCustomers
                        ?.filter(m => m.month?.toLowerCase().includes(this.searchCriteria.month));
                }

                return newCustomer;
            });

        this.updateDisplayTotals(this.vData);
    }

    updateDisplayTotals(data) {
        let totalSalesQty = 0;
        let totalPrice = 0;
        let totalGMKg = 0;
        let totalCOGSVal = 0;
        let totalCOGSKg = 0;
        let totalGMVal = 0;
        let totalSalesVal = 0;

        data.forEach(customer => {
            customer.monthWiseGroupedCustomers.forEach(month => {
                totalSalesQty += parseFloat(month.totalQuantity || 0);
                totalPrice += parseFloat(month.totalPrice || 0);
                totalGMKg += parseFloat(month.totalGMKg || 0);
                totalCOGSVal += parseFloat(month.totalCOGSVal || 0);
                totalCOGSKg += parseFloat(month.totalCOGSKg || 0);
                totalGMVal += parseFloat(month.totalGMVal || 0);
                totalSalesVal += parseFloat(month.totalSalesVal || 0);
            });
        });

        this.displayTotals.Total_Sales_Quantity = totalSalesQty.toFixed(2);
        this.displayTotals.Total_Price = this.formatCurrency(totalPrice);
        this.displayTotals.Total_GM_Kg = totalGMKg.toFixed(2);
        this.displayTotals.Total_COGS_Value = this.formatCurrency(totalCOGSVal);
        this.displayTotals.Total_COGS_Kg = totalCOGSKg.toFixed(2);
        this.displayTotals.Total_GM_Value = this.formatCurrency(totalGMVal);
        this.displayTotals.Total_Sales_Value = this.formatCurrency(totalSalesVal);
    }



}