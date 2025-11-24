// import { LightningElement, track, api } from 'lwc';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// export default class UploadForcastReport extends LightningElement {
//     @track tableHeaders = [];
//     @track tableData = [];
//     @track filterFlag = true;
//     @track buttonsFlag = false;
//     @track csvMonthHeaderValue = '';

//     // Filter properties
//     @track selectedYear = '';
//     @track selectedMonth = '';
//     @track selectedMonthName = '';
//     @track yearOptions = [
//         { label: '2025', value: '2025' },
//         { label: '2026', value: '2026' },
//         { label: '2027', value: '2027' },
//         { label: '2028', value: '2028' },
//         { label: '2029', value: '2029' },
//         { label: '2030', value: '2030' }
//     ];
//     @track monthOptions = [
//         { label: 'January', value: '01' },
//         { label: 'February', value: '02' },
//         { label: 'March', value: '03' },
//         { label: 'April', value: '04' },
//         { label: 'May', value: '05' },
//         { label: 'June', value: '06' },
//         { label: 'July', value: '07' },
//         { label: 'August', value: '08' },
//         { label: 'September', value: '09' },
//         { label: 'October', value: '10' },
//         { label: 'November', value: '11' },
//         { label: 'December', value: '12' }
//     ];

//     showToast(title, message, variant) {
//         const evt = new ShowToastEvent({
//             title: title,
//             message: message,
//             variant: variant,
//         });
//         this.dispatchEvent(evt);
//     }

//     handleYearChange(event) {
//         this.selectedYear = event.detail.value;
//         if (this.selectedMonth != '') {
//             this.updateMonthName();
//         }
//         console.log('Selected Year:', this.selectedYear);
//     }

//     handleMonthChange(event) {
//         this.selectedMonth = event.detail.value;
//         console.log('Selected Month:', this.selectedMonth);
//         if (this.selectedYear != '') {
//             this.updateMonthName();
//         }
//     }

//     updateMonthName() {
//         if (this.selectedMonth != '') {
//             const month = this.monthOptions.find(m => m.value === this.selectedMonth);
//             this.selectedMonthName = month ? month.label : '';
//             this.buttonsFlag = true;
//             this.csvMonthHeaderValue = this.selectedMonthName + this.selectedYear;
//             console.log('Updated Month Name:', this.selectedMonthName);
//         }
//     }

//     handleDownload() {
//         try {
//             if (!this.selectedYear || !this.selectedMonth) {
//                 this.showToast('Error', 'Please select both year and month', 'error');
//                 return;
//             }

//             const month = this.monthOptions.find(m => m.value === this.selectedMonth);
//             const monthName = month ? month.label : this.selectedMonth;

//             const headers = [
//                 'Customer Code',
//                 'Customer Name',
//                 'Material',
//                 'Material Description',
//                 'Salesperson Code',
//                 'Salesperson',
//                 'Sales Quantity',
//                 // this.csvMonthHeaderValue,
//                 // 'Remark'
//             ];

//             let csvContent = headers.join(',') + '\r\n';

//             for (let i = 0; i < 5; i++) {
//                 const row = new Array(headers.length).fill('');
//                 csvContent += row.join(',') + '\r\n';
//             }

//             const csvData = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csvContent);

//             const link = document.createElement('a');
//             link.setAttribute('href', csvData);
//             link.setAttribute('download', `Forecast_${monthName}_${this.selectedYear}.csv`);
//             document.body.appendChild(link);

//             link.click();

//             document.body.removeChild(link);

//             this.showToast('Success', 'Template downloaded successfully', 'success');
//         } catch (error) {
//             console.error('Error generating CSV:', error);
//             this.showToast('Error', 'Failed to generate download file', 'error');
//         }
//     }

//     // Handler for Upload Report button
//     handleUpload() {
//         // Add your upload logic here
//         // For example, show a file upload dialog
//         this.template.querySelector('input[type="file"]').click();
//     }

//     // Parse CSV content into rows and columns
//     parseCSV(csvText) {
//         const lines = csvText.split('\n');
//         const headers = lines[0].split(',').map(header => header.trim());
//         const data = [];

//         for (let i = 1; i < lines.length; i++) {
//             if (!lines[i].trim()) continue;

//             const values = lines[i].split(',');
//             const row = {};

//             headers.forEach((header, index) => {
//                 row[header] = values[index] ? values[index].trim() : '';
//             });

//             data.push(row);
//         }

//         return { headers, data };
//     }

//     // Display data column-wise
//     displayColumnWiseData(headers, data) {
//         console.log('--- Column-wise Data ---');

//         // Create a map to store column data
//         const columnData = new Map();
//         headers.forEach(header => columnData.set(header, []));

//         // Populate column data
//         data.forEach(row => {
//             headers.forEach(header => {
//                 columnData.get(header).push(row[header] || '');
//             });
//         });

//         // Log column-wise data
//         columnData.forEach((values, columnName) => {
//             console.log(`Column: ${columnName}`);
//             console.log('Values:', values);
//             console.log('---');
//         });
//     }

//     // Handle file selection
//     handleFileUpload(event) {
//         const fileInput = event.target;
//         const file = fileInput.files[0];

//         if (!file) return;

//         // Check file type
//         const validExtensions = ['xlsx', 'xls', 'csv'];
//         const fileExtension = file.name.split('.').pop().toLowerCase();

//         if (!validExtensions.includes(fileExtension)) {
//             this.showToast('Error', 'Please upload only Excel (.xlsx, .xls) or CSV (.csv) files', 'error');
//             fileInput.value = '';  // Reset the input
//             return;
//         }

//         // console.log('File details:', {
//         //     name: file.name,
//         //     type: file.type,
//         //     size: file.size,
//         //     lastModified: new Date(file.lastModified).toLocaleString()
//         // });

//         const reader = new FileReader();

//         reader.onload = (e) => {
//             try {
//                 if (fileExtension === 'csv') {
//                     const csvContent = e.target.result;
//                     this.processCSVData(csvContent);
//                 } else {
//                     // For Excel files
//                     console.log('Excel file loaded. Processing...');
//                     // Add Excel processing logic here if needed
//                     this.showToast('Success', 'Excel file loaded', 'success');
//                 }
//             } catch (error) {
//                 console.error('Error processing file:', error);
//                 this.showToast('Error', `Error processing ${fileExtension.toUpperCase()} file`, 'error');
//             } finally {
//                 fileInput.value = '';  // Reset the input after processing
//             }
//         };

//         if (fileExtension === 'csv') {
//             reader.readAsText(file);
//         } else {
//             reader.readAsArrayBuffer(file);
//         }
//     }

//     processCSVData(csvContent) {
//         const lines = csvContent.split(/\r\n|\n/);
//         if (lines.length < 2) {
//             this.showToast('Error', 'CSV file is empty or invalid', 'error');
//             return;
//         }

//         // Get headers from first line
//         const headers = lines[0].split(',').map(header => header.trim().replace(/[\s-]+/g, ''));

//         this.tableHeaders = headers;
//         console.log(this.tableHeaders);

//         // Process data rows
//         const data = [];
//         for (let i = 1; i < lines.length; i++) {
//             if (!lines[i].trim()) continue;

//             const values = lines[i].split(',').map(val => val.trim());
//             const row = { id: `row-${i}` };

//             headers.forEach((header, index) => {
//                 row[header] = values[index] !== undefined ? values[index] : '';
//             });

//             data.push(row);
//         }

//         this.tableData = data;
//         console.log(this.tableData);

//         this.showToast('Success', `Successfully loaded ${data.length} records`, 'success');
//     }
// }

import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveForecastRecords from '@salesforce/apex/ForecastController.saveForecastRecords';
import getExistingForecastData from '@salesforce/apex/ForecastController.getExistingForecastData';
import saveUpdatedForecastRecords from '@salesforce/apex/ForecastController.saveUpdatedForecastRecords';

export default class UploadForcastReport extends LightningElement {
    @track tableData = [];
    @track existingForecastData = [];
    @track forecastDataUpdate = [];
    @track filterFlag = true;
    @track buttonsFlag = false;
    @track csvMonthHeaderValue = '';
    @track showTable = false;
    @track uploadedFileName = '';
    @track isSaving = false;

    // Filter properties
    @track selectedYear = '2025';
    @track selectedMonth = '';
    @track selectedMonthName = '';
    @track yearOptions = [
        { label: '2025', value: '2025' },
        { label: '2026', value: '2026' },
        { label: '2027', value: '2027' },
        { label: '2028', value: '2028' },
        { label: '2029', value: '2029' },
        { label: '2030', value: '2030' }
    ];
    @track monthOptions = [
        { label: 'January', value: 'January' },
        { label: 'February', value: 'February' },
        { label: 'March', value: 'March' },
        { label: 'April', value: 'April' },
        { label: 'May', value: 'May' },
        { label: 'June', value: 'June' },
        { label: 'July', value: 'July' },
        { label: 'August', value: 'August' },
        { label: 'September', value: 'September' },
        { label: 'October', value: 'October' },
        { label: 'November', value: 'November' },
        { label: 'December', value: 'December' }
    ];

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

    connectedCallback() {
        this.getExistingForecastData();
    }

    getExistingForecastData() {
        getExistingForecastData().then(result => {
            console.log(result);
            this.existingForecastData = result;

        }).catch(error => {
            console.error('Error fetching existing forecast data:', error);
            this.showToast('Error', 'Failed to fetch existing forecast data', 'error');
        });
    }

    handleMonthValueChange(event) {
        const materialId = event.target.dataset.materialid;
        const customerId = event.target.dataset.customerid;
        const month = event.target.dataset.month;
        const monthValue = event.target.value;
        // console.log('Month value changed for materialId:', materialId);
        // console.log('Month value changed for customerId:', customerId);
        // console.log('Month value changed for month:', month);

        let forecastObj = {
            materialId: materialId,
            customerId: customerId,
            month: month,
            monthValue: monthValue
        }

        // Find index of existing entry with same materialId, customerId, and month
        const existingIndex = this.forecastDataUpdate.findIndex(item =>
            item.materialId === materialId &&
            item.customerId === customerId &&
            item.month === month
        );

        if (existingIndex !== -1) {
            // Update existing entry
            this.forecastDataUpdate[existingIndex] = forecastObj;
        } else {
            // Add new entry
            this.forecastDataUpdate.push(forecastObj);
        }
        console.log('Updated forecast data:', this.forecastDataUpdate);

        const existingDataCustomerIndex = this.existingForecastData.findIndex(item =>
            item.customerId === customerId
        );
        // console.log('Existing Customer index:', existingDataCustomerIndex);

        const existingCustomerData = this.existingForecastData[existingDataCustomerIndex];
        console.log('existingCustomerData:', existingCustomerData);

        const existingProductsData = existingCustomerData.products;
        console.log('existingProductsData:', existingProductsData);

        const existingDataMaterialIndex = existingProductsData.findIndex(item =>
            item.materialId === materialId
        );
        // console.log('Existing material index:', existingDataMaterialIndex);
        const existingMaterialData = existingProductsData[existingDataMaterialIndex];
        console.log('existingMaterialData:', existingMaterialData);

        this.existingForecastData[existingDataCustomerIndex].products[existingDataMaterialIndex].monthValues[month] = monthValue;
        console.log('Updated existing forecast data:', this.existingForecastData);
    }

    handlerSaveUpdatedForecast() {
        if (this.forecastDataUpdate.length > 0) {
            saveUpdatedForecastRecords({
                forecastData: this.forecastDataUpdate
            }).then(result => {
                console.log(result);
                this.showToast('Success', 'Forecast records updated successfully', 'success');
                this.forecastDataUpdate = [];
                this.getExistingForecastData();
            }).catch(error => {
                console.error('Error updating forecast records:', error);
                this.showToast('Error', 'Failed to update forecast records', 'error');
            });
        } else {
            this.showToast('Please update at least one record', '', 'info');
        }
    }

    // ----------------- Filter selection -----------------
    handleYearChange(event) {
        this.selectedYear = event.detail.value;
        if (this.selectedMonth !== '') {
            this.updateMonthName();
        }
    }

    handleMonthChange(event) {
        this.selectedMonth = event.detail.value;
        if (this.selectedYear !== '') {
            this.updateMonthName();
        }
    }

    updateMonthName() {
        if (this.selectedMonth !== '') {
            const month = this.monthOptions.find(m => m.value === this.selectedMonth);
            this.selectedMonthName = month ? month.label : '';
            this.buttonsFlag = true;
            this.csvMonthHeaderValue = this.selectedMonthName + this.selectedYear;
        }
    }

    // Handler for Download Template button
    handleDownload() {
        try {
            if (!this.selectedYear || !this.selectedMonth) {
                this.showToast('Error', 'Please select both year and month', 'error');
                return;
            }

            const month = this.monthOptions.find(m => m.value === this.selectedMonth);
            const monthName = month ? month.label : this.selectedMonth;

            const headers = [
                'customerCode',
                'customerName',
                'materialCode',
                'materialDescription',
                'salespersonCode',
                'salesperson',
                'salesQuantity'
            ];

            let csvContent = headers.join(',') + '\r\n';

            // Add empty rows
            // for (let i = 0; i < 5; i++) {
            //     const row = new Array(headers.length).fill('');
            //     csvContent += row.join(',') + '\r\n';
            // }

            const csvData = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csvContent);
            const link = document.createElement('a');
            link.setAttribute('href', csvData);
            link.setAttribute('download', `Forecast_${monthName}_${this.selectedYear}.csv`);
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);

            this.showToast('Success', 'Template downloaded successfully', 'success');
        } catch (error) {
            console.error('Error generating CSV:', error);
            this.showToast('Error', 'Failed to generate download file', 'error');
        }
    }

    // Handler for Upload Report button
    handleUpload() {
        this.template.querySelector('input[type="file"]').click();
    }

    // Handle file selection
    handleFileUpload(event) {
        const fileInput = event.target;
        const file = fileInput.files[0];

        if (!file) return;

        const validExtensions = ['xlsx', 'xls', 'csv'];
        const fileExtension = file.name.split('.').pop().toLowerCase();

        if (!validExtensions.includes(fileExtension)) {
            this.showToast('Error', 'Please upload only Excel (.xlsx, .xls) or CSV (.csv) files', 'error');
            fileInput.value = '';
            return;
        }

        this.uploadedFileName = file.name;

        const reader = new FileReader();

        reader.onload = (e) => {
            try {
                if (fileExtension === 'csv') {
                    const csvContent = e.target.result;
                    this.processCSVData(csvContent);
                } else {
                    this.showToast('Error', 'Excel file upload requires additional setup. Please use CSV format.', 'error');
                    fileInput.value = '';
                }
            } catch (error) {
                console.error('Error processing file:', error);
                this.showToast('Error', `Error processing ${fileExtension.toUpperCase()} file`, 'error');
                fileInput.value = '';
            } finally {
                // Reset file input so same file can be selected again if needed
                try { fileInput.value = ''; } catch (e) { /* ignore */ }
            }
        };

        if (fileExtension === 'csv') {
            reader.readAsText(file);
        } else {
            reader.readAsArrayBuffer(file);
        }
    }

    processCSVData(csvContent) {
        try {
            const lines = csvContent.split(/\r\n|\n/).filter(line => line.trim() !== '');

            // Validation: Check if file has at least 2 lines (header + 1 data row)
            if (lines.length < 2) {
                this.showToast('Error', 'File must contain at least 1 data record (excluding header). Please upload a valid file.', 'error');
                this.showTable = false;
                this.tableData = [];
                return;
            }

            // Get headers from first line
            const headers = lines[0].split(',').map(header =>
                header.trim().replace(/\s+/g, '')
            );

            console.log('📋 Parsed Headers:', headers);

            // Process data rows
            const data = [];
            for (let i = 1; i < lines.length; i++) {
                if (!lines[i].trim()) continue;

                const values = lines[i].split(',').map(val => val.trim());
                const row = { id: `row-${i}` };

                // Map headers to row properties
                headers.forEach((header, index) => {
                    row[header] = values[index] !== undefined ? values[index] : '';
                });

                // Debug each row
                console.log(`📄 Row ${i}:`, row);

                // Only skip if ALL fields are blank
                const hasData = Object.values(row).some(value =>
                    value && value.toString().trim() !== '' &&
                    value.toString().trim() !== 'CustomerCode' // Skip header if accidentally included
                );

                if (hasData) {
                    data.push(row);
                } else {
                    console.log(`⏭️ Skipping completely blank row ${i}`);
                }
            }

            this.tableData = data;
            this.showTable = true;

            console.log('💾 Final tableData:', this.tableData);
            console.log('🔢 Total records to save:', data.length);

            if (data.length > 0) {
                this.showToast('Success', `Successfully loaded ${data.length} records.`, 'success');
            } else {
                this.showToast('Warning', 'No valid data found in the file.', 'warning');
                this.showTable = false;
            }
        } catch (error) {
            console.error('❌ Error processing CSV:', error);
            this.showToast('Error', 'Error processing file: ' + error.message, 'error');
        }
    }

    // Optional helper (not used for filtering now) — kept for reference
    isRowBlank(row) {
        return (!row.customerCode || row.customerCode.trim() === '') &&
            (!row.customerName || row.customerName.trim() === '') &&
            (!row.materialCode || row.materialCode.trim() === '') &&
            (!row.materialDescription || row.materialDescription.trim() === '') &&
            (!row.salespersonCode || row.salespersonCode.trim() === '') &&
            (!row.salesperson || row.salesperson.trim() === '') &&
            (!row.salesQuantity || row.salesQuantity.trim() === '');
    }

    // Save records to Salesforce
    // Save records to Salesforce
    async saveRecords() {
        try {
            if (this.tableData.length === 0) {
                this.showToast('Error', 'No data to save. Please upload a file first.', 'error');
                return;
            }

            if (!this.selectedMonth || !this.selectedYear) {
                this.showToast('Error', 'Please select both month and year before saving.', 'error');
                return;
            }

            this.isSaving = true;
            this.showToast('Info', 'Saving records...', 'info');

            // DEBUG: Check what's in tableData
            console.log('📊 tableData contents:', JSON.parse(JSON.stringify(this.tableData)));

            // Check first few rows to see actual data
            for (let i = 0; i < Math.min(3, this.tableData.length); i++) {
                console.log(`🔍 Row ${i}:`, this.tableData[i]);
            }

            // Prepare data for Apex - ensure property names match Apex wrapper
            const forecastData = this.tableData.map((row, index) => {
                // Debug each row
                console.log(`📝 Processing row ${index}:`, row);

                const forecastRecord = {
                    customerCode: row.customerCode || '',
                    customerName: row.customerName || '',
                    materialCode: row.materialCode || '',
                    materialDescription: row.materialDescription || '',
                    salespersonCode: row.salespersonCode || '',
                    salesperson: row.salesperson || '',
                    salesQuantity: row.salesQuantity || '0'
                };

                console.log(`✅ Prepared record ${index}:`, forecastRecord);
                return forecastRecord;
            });

            console.log('🚀 Sending to Apex:', {
                forecastData: forecastData,
                month: this.selectedMonth,
                year: this.selectedYear
            });

            // Call Apex method
            const result = await saveForecastRecords({
                forecastData: forecastData,
                month: this.selectedMonth,
                year: this.selectedYear
            });

            console.log('📨 Apex response:', result);
            this.showToast('Success', result, 'success');

            // Reset form after successful save
            this.resetForm();

        } catch (error) {
            console.error('❌ Error saving records:', error);
            console.error('Error details:', error.body?.message || error.message);
            this.showToast('Error', 'Error saving records: ' + (error.body?.message || error.message), 'error');
        } finally {
            this.isSaving = false;
        }
    }

    // Reset form
    resetForm() {
        this.tableData = [];
        this.showTable = false;
        this.uploadedFileName = '';
        // Don't reset year and month as user might want to upload another file for same period
        this.isSaving = false;

        const fileInput = this.template.querySelector('input[type="file"]');
        if (fileInput) {
            try { fileInput.value = ''; } catch (e) { /* ignore */ }
        }
    }

    // Cancel upload and hide table
    cancelUpload() {
        this.resetForm();
    }

    toggleRow(event) {
        const partyName = event.currentTarget.dataset.key;

        const updatedData = this.existingForecastData.map(row => {
            const isClicked = row.customerId === partyName;
            const shouldExpand = isClicked ? !row.isExpanded : false;

            return {
                ...row,
                isExpanded: shouldExpand,
                iconName: shouldExpand ? 'utility:chevrondown' : 'utility:chevronright'
            };
        });

        this.existingForecastData = [...updatedData]; // Trigger reactivity
    }

}