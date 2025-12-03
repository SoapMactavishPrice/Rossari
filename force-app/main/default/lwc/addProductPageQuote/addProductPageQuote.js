import { LightningElement, wire, track } from 'lwc';
import findProducts from '@salesforce/apex/AddProductPageQuote.findProduct';
import saveProducts from '@salesforce/apex/AddProductPageQuote.saveProducts';
import getQuotationDetails from '@salesforce/apex/AddProductPageQuote.getQuotationDetails';
import getproductfamily from '@salesforce/apex/AddProductPageQuote.getproductfamily';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { RefreshEvent } from 'lightning/refresh';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';

const DELAY = 300;

export default class AddProductPage extends NavigationMixin(LightningElement) {
    // Base columns for datatable
    baseCols = [
        { label: 'Product Name', fieldName: 'purl', type: 'url', typeAttributes: { label: { fieldName: 'Name' } } },
        { label: 'Product Code', fieldName: 'ProductCode', type: 'text' },
        { label: 'Product Category', fieldName: 'Family', type: 'text' },
        { label: 'List Price', fieldName: 'Price', type: 'currency', cellAttributes: { alignment: 'left' } },
        { label: 'Product Description', fieldName: 'Description', type: 'text' }
    ];

    @track recId;
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        if (currentPageReference && currentPageReference.state.c__refRecordId) {
            this.recId = currentPageReference.state.c__refRecordId;
            console.log('Quote Id', this.recId);
        }
    }

    get listOfData() {
        return this.SelectedProductData;
    }

    @track SelectedRecordCount = 0;
    @track isModalOpen = false;
    @track ShowSelected = true;
    @track PriceBook = '';
    @track ShowTableData = [];
    @track selectedProductCode = [];
    @track AllProductData = [];
    @track SelectedProductData = [];
    @track lstResult = [];
    @track hasRecords = true;
    @track searchKey = '';
    @track isSearchLoading = false;
    @track delayTimeout;
    @track isFirstPage = true;
    @track isSecondPage = false;
    @track selectedRows = [];
    @track ShowViewAll = false;
    @track datafilterval = false;
    @track prodfamilylst = [];
    @track FilterForm = { "ProductCode": "", "ProductFamily": [] };
    @track isProductSelect = true;
    @track showErrorMsg = false;
    @track filteredData = [];
    @track DisableNext = true;
    @track showSpinner = false;

    // Sales Org details
    @track selectedSalesArea = '';
    @track selectedDistributionChannel = '';
    @track selectedDivision = '';

    // Conditional column flags - only for second page
    @track shouldShowCustomerMaterialPrice = false;
    @track shouldShowLastSellingPrice = false;

    // Pagination variables
    @track paginationDataList;
    @track page = 1;
    @track items = [];
    @track data = [];
    @track startingRecord = 1;
    @track endingRecord = 0;
    @track pageSize = 10;
    @track totalRecountCount = 0;
    @track totalPage = 0;

    // Maps for storing input values
    mapIdQuantity = new Map();
    mapIdSalesPrice = new Map();
    mapIdDate = new Map();
    mapIdDiscount = new Map();
    mapIdLineDescription = new Map();

    @track tempEvent;
    @track dupSelectedRecordDound = [];
    @track disabledApplayButton = true;
    @track startTime = performance.now();
    @track timeoutId;

    connectedCallback() {
        this.mapIdQuantity = new Map();
        this.mapIdSalesPrice = new Map();
        this.mapIdDate = new Map();
        this.mapIdDiscount = new Map();
        this.mapIdLineDescription = new Map();

        this.ShowTableData = [];
        this.selectedProductCode = [];
        this.AllProductData = [];
        this.SelectedProductData = [];
        this.isModalOpen = true;
        console.log('connected call back called');

        this.handleQuotationDetails();
    }

    // Computed property for dynamic columns - FIRST PAGE COLUMNS
    get columns() {
        // First page only shows base columns
        let cols = [...this.baseCols];

        // Remove Customer Material Price and Last Selling Price from first page
        // These will only appear on second page
        return cols;
    }

    // Computed property for second page columns
    get secondPageColumns() {
        let cols = [
            { label: 'Product Name', fieldName: 'purl', type: 'url', typeAttributes: { label: { fieldName: 'Name' } } },
            { label: 'Product Code', fieldName: 'ProductCode', type: 'text' }
        ];

        // Add Customer Material Price column if Sales Org is 1000 AND Division is 10,11,22
        if (this.shouldShowCustomerMaterialPrice) {
            cols.push({
                label: 'Customer Material Price',
                fieldName: 'customerMaterialPrice',
                type: 'currency',
                cellAttributes: { alignment: 'left' },
                typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' } }
            });
        }

        cols.push({
            label: 'List Price',
            fieldName: 'ListPrice',
            type: 'currency',
            cellAttributes: { alignment: 'left' },
            typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' } }
        });

        // Add Last Selling Price column if Sales Org is 3000/4000
        if (this.shouldShowLastSellingPrice) {
            cols.push({
                label: 'Last Selling Price',
                fieldName: 'lastSellingPrice',
                type: 'currency',
                cellAttributes: { alignment: 'left' },
                typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' } }
            });
        }

        // Add input columns
        cols.push(
            { label: 'Quantity', fieldName: 'Quantity', type: 'number', editable: true },
            {
                label: 'Sales Price', fieldName: 'Price', type: 'currency', editable: true,
                typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' } }
            },
            { label: 'Discount %', fieldName: 'Discount', type: 'percent', editable: false }
        );

        return cols;
    }

    handleQuotationDetails() {
        getQuotationDetails({
            recordId: this.recId
        }).then(result => {
            let data = JSON.parse(result);
            console.log('getQuotationDetails = ', data);
            this.selectedSalesArea = data.salesOrg;
            this.selectedDistributionChannel = data.distributionChannel;
            this.selectedDivision = data.division;

            // Set flags for conditional columns based on business rules
            const allowedDivisions = ['10', '11', '22'];
            this.shouldShowCustomerMaterialPrice = (this.selectedSalesArea === '1000' && allowedDivisions.includes(this.selectedDivision));
            this.shouldShowLastSellingPrice = (this.selectedSalesArea === '3000' || this.selectedSalesArea === '4000');

            console.log('Sales Org:', this.selectedSalesArea);
            console.log('Division:', this.selectedDivision);
            console.log('Should show Customer Material Price (2nd page):', this.shouldShowCustomerMaterialPrice);
            console.log('Should show Last Selling Price (2nd page):', this.shouldShowLastSellingPrice);

            this.handlerFetchProductList();
        }).catch(error => {
            console.error('Error fetching quotation details:', error);
            this.showToast('Error', 'Failed to load quotation details', 'error');
        });
    }

    handlerFetchProductList() {
        this.showSpinner = true;
        findProducts({
            recordId: this.recId,
            productFamily: [],
            salesOrg: this.selectedSalesArea,
            distributionChannel: this.selectedDistributionChannel,
            division: this.selectedDivision
        }).then(result => {
            let dataObj = JSON.parse(result);
            this.AllProductData = dataObj.productList.map(item => ({
                ...item,
                CurrencyIsoCode: 'INR' // Set default currency - adjust as needed
            }));
            this.ShowTableData = [...this.AllProductData];
            this.PriceBook = dataObj.priceBook;

            console.log('Products loaded:', this.AllProductData.length);
            console.log('Sample product:', this.AllProductData[0]);

            this.paginiateData(JSON.stringify(this.AllProductData));
            this.showSpinner = false;
        }).catch(error => {
            console.error('Error fetching products:', error);
            this.showToast('Error', 'Failed to load products', 'error');
            this.showSpinner = false;
        });
    }

    getproductfamily() {
        getproductfamily().then(result => {
            console.log('ProductFamily' + JSON.stringify(result));
            this.prodfamilylst = result;
        });
    }

    get options() {
        return this.prodfamilylst.map(item => ({
            label: item.label,
            value: item.value
        }));
    }

    handleChange(event) {
        console.log('name', event.target.name);
        console.log('value', event.detail.value);

        this.FilterForm[event.target.name] = event.detail.value;
        console.log('this.FilterForm', JSON.stringify(this.FilterForm));

        // Enable Apply button if any filter is set
        if ((this.FilterForm["ProductCode"] && this.FilterForm["ProductCode"].trim() !== '') ||
            (this.FilterForm["ProductFamily"] && this.FilterForm["ProductFamily"].length > 0)) {
            this.disabledApplayButton = false;
        } else {
            this.disabledApplayButton = true;
        }
    }

    handleShowSelected() {
        this.ShowSelected = false;
        console.log('handleShowSelected called...');
        this.ShowTableData = this.AllProductData;
        this.ShowViewAll = true;
        this.fillselectedRows();
        this.RecalculateselectedProductCode();
        this.paginiateData(JSON.stringify(this.AllProductData));
        this.page = 1;
    }

    handleviewAll(event) {
        this.ShowSelected = true;
        this.ShowViewAll = false;
        if (this.tempEvent) {
            this.SelectedProduct(this.tempEvent);
        }
        this.fillselectedRows();
        this.RecalculateselectedProductCode();

        console.log('method view all');
        this.paginiateData(JSON.stringify(this.AllProductData));
        this.page = 1;
    }

    fillselectedRows() {
        this.selectedRows = []
        for (let i = 0; i < this.ShowTableData.length; i++) {
            if (this.selectedProductCode.includes(this.ShowTableData[i].Id)) {
                this.selectedRows.push(this.ShowTableData[i]);
            }
        }
    }

    RecalculateselectedProductCode() {
        this.selectedProductCode = [];
        for (let i = 0; i < this.SelectedProductData.length; i++) {
            if (this.SelectedProductData[i].Id) {
                this.selectedProductCode.push(this.SelectedProductData[i].Id);
            }
        }
    }

    SelectedProduct(event) {
        this.tempEvent = event;
        const selRows = event.detail.selectedRows;

        // Clear and rebuild selectedProductCode from selected rows
        this.selectedProductCode = selRows.map(row => row.Id);

        // Clear and rebuild selectedRows
        this.selectedRows = [...selRows];

        // Clear and rebuild SelectedProductData
        this.SelectedProductData = [];
        for (let i = 0; i < this.selectedProductCode.length; i++) {
            for (let j = 0; j < this.AllProductData.length; j++) {
                if (this.selectedProductCode[i] === this.AllProductData[j].Id) {
                    this.SelectedProductData.push(this.AllProductData[j]);
                    break;
                }
            }
        }

        // Remove duplicates
        this.SelectedProductData = this.removeDuplicates(this.SelectedProductData, 'Id');

        this.SelectedRecordCount = this.selectedProductCode.length;

        if (this.selectedProductCode.length > 0) {
            this.DisableNext = false;
        } else {
            this.DisableNext = true;
        }

        this.isProductSelect = true;
    }

    removeDuplicates(array, key) {
        const seen = new Set();
        return array.filter(item => {
            const duplicate = seen.has(item[key]);
            seen.add(item[key]);
            return !duplicate;
        });
    }

    goBackToRecord() {
        this.isFirstPage = true;
        this.isSecondPage = false;
        this.SelectedProductData = [];
        this.selectedProductCode = [];

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recId,
                objectApiName: 'Quote',
                actionName: 'view',
            }
        });
    }

    closeModal() {
        this.isModalOpen = false;
        this.SelectedRecordCount = 0;
        this.PriceBook = '';
        this.ShowTableData = [];
        this.selectedProductCode = [];
        this.AllProductData = [];
        this.SelectedProductData = [];
        this.lstResult = [];
        this.hasRecords = true;
        this.searchKey = '';
        this.isSearchLoading = false;
        this.isFirstPage = true;
        this.isSecondPage = false;
        this.selectedRows = [];
        this.ShowViewAll = false;
        this.ShowSelected = true;
        this.showErrorMsg = false;
        this.filteredData = [];
        this.FilterForm = { "ProductCode": "", "ProductFamily": [] };
        this.datafilterval = false;
        this.DisableNext = true;
        this.shouldShowCustomerMaterialPrice = false;
        this.shouldShowLastSellingPrice = false;
    }

    nextDetails() {
        if (this.selectedProductCode.length === 0) {
            this.showToast('Error', 'Please select at least one product.', 'error');
            return;
        }

        this.isFirstPage = false;
        this.isSecondPage = true;

        // Build SelectedProductData from selected products
        this.SelectedProductData = [];
        for (let j = 0; j < this.AllProductData.length; j++) {
            if (this.selectedProductCode.includes(this.AllProductData[j].Id)) {
                this.SelectedProductData.push({
                    ...this.AllProductData[j],
                    Quantity: 1, // Default quantity
                    Price: '', // Empty sales price initially
                    Discount: 0 // Default discount
                });
            }
        }

        this.SelectedProductData = this.removeDuplicates(this.SelectedProductData, 'Id');

        console.log('Selected products count:', this.SelectedProductData.length);
        console.log('Should show Customer Material Price (2nd page):', this.shouldShowCustomerMaterialPrice);
        console.log('Should show Last Selling Price (2nd page):', this.shouldShowLastSellingPrice);

        clearTimeout(this.timeoutId);
        this.timeoutId = setTimeout(this.updateIndex.bind(this), 1000);
    }

    updateIndex() {
        // Update index if needed
    }

    datafilter() {
        this.datafilterval = !this.datafilterval;
    }

    hadleDelete(event) {
        this.template.querySelectorAll('tr').forEach(ele => {
            if (ele.id.includes(event.target.value)) {
                ele.classList.add('slds-hide')
            }
        });
    }

    saveDetails() {
        var deletedProducts = [];
        this.template.querySelectorAll('tr').forEach(ele => {
            if (ele.classList.value.includes('slds-hide') && !ele.id.includes('firstRow')) {
                var temp = ele.id.split('-');
                if (temp.length > 0) {
                    deletedProducts.push(temp[0]);
                }
            }
        });

        // Update product data with user inputs from maps
        for (var i = 0; i < this.SelectedProductData.length; i++) {
            var obj = this.SelectedProductData[i];
            var id = obj.Id;

            if (this.mapIdQuantity.has(id)) {
                obj.Quantity = parseFloat(this.mapIdQuantity.get(id)) || 0;
            }
            if (this.mapIdSalesPrice.has(id)) {
                obj.Price = parseFloat(this.mapIdSalesPrice.get(id)) || 0;
            }
            if (this.mapIdDate.has(id)) {
                obj.PDate = this.mapIdDate.get(id);
            }
            if (this.mapIdLineDescription.has(id)) {
                obj.LineDescription = this.mapIdLineDescription.get(id);
            }
            if (this.mapIdDiscount.has(id)) {
                obj.Discount = parseFloat(this.mapIdDiscount.get(id)) || 0;
            }

            this.SelectedProductData[i] = obj;
        }

        // Filter out deleted products
        var DataToSave = this.SelectedProductData.filter(product =>
            !deletedProducts.includes(product.Id)
        );

        var isValidate = true;
        var validationMessage = '';

        // Validate quantity and sales price
        for (var i = 0; i < DataToSave.length; i++) {
            var product = DataToSave[i];

            if (!product.Quantity || product.Quantity <= 0) {
                isValidate = false;
                validationMessage = 'Quantity should be greater than 0 for all products';
                break;
            }

            if (!product.Price || product.Price <= 0) {
                isValidate = false;
                validationMessage = 'Sales Price is required and should be greater than 0 for all products';
                break;
            }
        }

        if (isValidate) {
            this.showSpinner = true;
            let str = JSON.stringify(DataToSave);

            saveProducts({
                recordData: str,
                recId: this.recId
            }).then(result => {
                if (result == 'success' || result.includes('success')) {
                    this.showToast('Success', 'Products added successfully', 'success');
                    this.dispatchEvent(new RefreshEvent());
                    this.goBackToRecord();
                } else {
                    this.showToast('Error', 'Failed to add products: ' + result, 'error');
                }
            }).catch(error => {
                console.error('Error saving products:', error);
                this.showToast('Error', 'Failed to save products: ' + (error.body?.message || error.message), 'error');
            }).finally(() => {
                this.showSpinner = false;
            });
        } else {
            this.showToast('Error', validationMessage, 'error');
        }
    }

    handleback() {
        this.ShowSelected = true;
        this.isFirstPage = true;
        this.isSecondPage = false;

        this.mapIdQuantity.clear();
        this.mapIdSalesPrice.clear();
        this.mapIdDate.clear();
        this.mapIdDiscount.clear();
        this.mapIdLineDescription.clear();

        this.fillselectedRows();
        this.RecalculateselectedProductCode();
        this.paginiateData(JSON.stringify(this.AllProductData));
        this.page = 1;
    }

    showFilteredProducts(event) {
        if (event.keyCode === 13) {
            this.handleKeyChange(event);
        } else {
            this.handleKeyChange(event);
            const searchBoxWrapper = this.template.querySelector('.lookupContainer');
            if (searchBoxWrapper) {
                searchBoxWrapper.classList.add('slds-show');
                searchBoxWrapper.classList.remove('slds-hide');
            }
        }
    }

    handleKeyChange(event) {
        this.isSearchLoading = true;
        this.searchKey = event.target.value;
        var data = [];

        for (var i = 0; i < this.AllProductData.length; i++) {
            if (this.AllProductData[i] &&
                (this.AllProductData[i].Name?.toLowerCase().includes(this.searchKey.toLowerCase()) ||
                    this.AllProductData[i].ProductCode?.toLowerCase().includes(this.searchKey.toLowerCase()))) {
                data.push(this.AllProductData[i]);
            }
        }

        this.paginiateData(JSON.stringify(data));
        this.page = 1;
    }

    toggleResult(event) {
        console.log('toggleResult called...');
        const lookupInputContainer = this.template.querySelector('.lookupInputContainer');
        if (!lookupInputContainer) return;

        const clsList = lookupInputContainer.classList;
        const whichEvent = event.target.getAttribute('data-source');

        switch (whichEvent) {
            case 'searchInputField':
                clsList.add('slds-is-open');
                break;
            case 'lookupContainer':
                clsList.remove('slds-is-open');
                break;
        }
    }

    handelSelectedRecord(event) {
        var objId = event.target.dataset.recid;
        const searchBoxWrapper = this.template.querySelector('.lookupContainer');
        if (searchBoxWrapper) {
            searchBoxWrapper.classList.remove('slds-show');
            searchBoxWrapper.classList.add('slds-hide');
        }

        const selectedRecord = this.lstResult.find(data => data.Id === objId);
        if (selectedRecord && !this.selectedProductCode.includes(selectedRecord.Id)) {
            this.selectedProductCode.push(selectedRecord.Id);
            this.SelectedRecordCount += 1;
            this.ShowTableData.push(selectedRecord);
            this.handleShowSelected();
        }
    }

    handleQuantityChange(event) {
        var selectedRow = event.currentTarget;
        var key = selectedRow.dataset.targetId;
        var value = parseFloat(event.target.value) || 0;
        this.mapIdQuantity.set(key, value);

        // Update SelectedProductData array for immediate UI update
        const index = this.SelectedProductData.findIndex(p => p.Id === key);
        if (index !== -1) {
            this.SelectedProductData[index].Quantity = value;
        }
    }

    handleSalesPriceChange(event) {
        const selectedRow = event.currentTarget;
        const key = selectedRow.dataset.targetId;
        const newSalesPrice = parseFloat(event.target.value) || 0;

        // Find the matching product in SelectedProductData
        let productIndex = this.SelectedProductData.findIndex(p => p.Id === key);
        if (productIndex === -1) return;

        let product = this.SelectedProductData[productIndex];

        // Get list price
        const listPrice = parseFloat(product.ListPrice || 0);

        // Calculate discount only if both prices are valid
        let discount = 0;
        if (listPrice > 0 && newSalesPrice > 0 && newSalesPrice <= listPrice) {
            discount = ((listPrice - newSalesPrice) / listPrice) * 100;
            discount = Math.round(discount * 100) / 100;
        }

        // Update maps
        this.mapIdSalesPrice.set(key, newSalesPrice);
        this.mapIdDiscount.set(key, discount);

        // Update arrays
        this.SelectedProductData[productIndex] = {
            ...product,
            Price: newSalesPrice,
            Discount: discount
        };

        // Force refresh
        this.SelectedProductData = [...this.SelectedProductData];
    }

    handleDateChange(event) {
        var selectedRow = event.currentTarget;
        var key = selectedRow.dataset.targetId;
        this.mapIdDate.set(key, event.target.value);
    }

    handleLineDescriptionChange(event) {
        var selectedRow = event.currentTarget;
        var key = selectedRow.dataset.targetId;
        this.mapIdLineDescription.set(key, event.target.value);
    }

    ApplyFilter() {
        console.log('ApplyFilter called');
        this.showSpinner = true;

        findProducts({
            recordId: this.recId,
            productFamily: this.FilterForm["ProductFamily"] || [],
            salesOrg: this.selectedSalesArea,
            distributionChannel: this.selectedDistributionChannel,
            division: this.selectedDivision
        }).then(result => {
            let dataObj = JSON.parse(result);
            this.filteredData = dataObj.productList;
            this.AllProductData = [...this.filteredData]; // Update AllProductData with filtered results

            // Apply additional client-side filters
            let filteredProductData = [];
            for (let i = 0; i < this.filteredData.length; i++) {
                let passesFilter = true;

                // Product Code filter
                if (this.FilterForm["ProductCode"] && this.FilterForm["ProductCode"].trim() !== '') {
                    if (!this.filteredData[i].ProductCode ||
                        !this.filteredData[i].ProductCode.toLowerCase().includes(this.FilterForm["ProductCode"].toLowerCase())) {
                        passesFilter = false;
                    }
                }

                // Search key filter
                if (passesFilter && this.searchKey && this.searchKey.trim() !== '') {
                    if (!this.filteredData[i].Name?.toLowerCase().includes(this.searchKey.toLowerCase()) &&
                        !this.filteredData[i].ProductCode?.toLowerCase().includes(this.searchKey.toLowerCase())) {
                        passesFilter = false;
                    }
                }

                if (passesFilter) {
                    filteredProductData.push(this.filteredData[i]);
                }
            }

            this.showErrorMsg = false;
            this.ShowTableData = filteredProductData;
            this.isProductSelect = false;

            // Clear selection since data changed
            this.selectedProductCode = [];
            this.selectedRows = [];
            this.SelectedProductData = [];
            this.SelectedRecordCount = 0;
            this.DisableNext = true;

            this.fillselectedRows();
            this.RecalculateselectedProductCode();
            this.paginiateData(JSON.stringify(this.ShowTableData));
            this.page = 1;
            this.showSpinner = false;
        }).catch(error => {
            console.error('Error applying filter:', error);
            this.showToast('Error', 'Failed to apply filters', 'error');
            this.showSpinner = false;
        });

        this.datafilterval = false;
    }

    clearFilter() {
        this.FilterForm = { "ProductCode": "", "ProductFamily": [] };
        this.disabledApplayButton = true;
        this.datafilterval = false;
        this.searchKey = '';

        // Reload all products
        this.handlerFetchProductList();
    }

    paginiateData(results) {
        let data = JSON.parse(results);
        this.paginationDataList = data;
        this.totalRecountCount = data.length;
        this.totalPage = Math.ceil(this.totalRecountCount / this.pageSize);
        this.ShowTableData = this.paginationDataList.slice(0, this.pageSize);
        this.endingRecord = this.pageSize;
        this.error = undefined;
        this.showSpinner = false;
    }

    get bDisableFirst() {
        return this.page == 1;
    }

    get bDisableLast() {
        return this.page == this.totalPage;
    }

    firstPage() {
        this.page = 1;
        this.recordPerPage(this.page);
    }

    previousHandler() {
        if (this.page > 1) {
            this.page = this.page - 1;
            this.recordPerPage(this.page);
        }
    }

    nextHandler() {
        if ((this.page < this.totalPage) && this.page !== this.totalPage) {
            this.page = this.page + 1;
            this.recordPerPage(this.page);
        }
    }

    lastPage() {
        this.page = this.totalPage;
        if (this.page > 1) {
            this.recordPerPage(this.page);
        }
    }

    recordPerPage(page) {
        let tempdata = this.paginationDataList || [];
        this.startingRecord = ((page - 1) * this.pageSize);
        this.endingRecord = (this.pageSize * page);
        this.endingRecord = (this.endingRecord > this.totalRecountCount) ? this.totalRecountCount : this.endingRecord;

        this.ShowTableData = tempdata.slice(this.startingRecord, this.endingRecord);
        this.startingRecord = this.startingRecord + 1;

        this.fillselectedRows();
        this.RecalculateselectedProductCode();

        if (this.template.querySelector('[data-id="datatable"]')) {
            this.template.querySelector('[data-id="datatable"]').selectedRows = this.selectedProductCode;
        }
    }

    // Helper method to show toast messages
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        }));
    }
}