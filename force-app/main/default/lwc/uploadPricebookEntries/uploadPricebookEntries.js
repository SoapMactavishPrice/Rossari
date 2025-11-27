import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript } from 'lightning/platformResourceLoader';

import SHEETJS from '@salesforce/resourceUrl/sheetjs';

import processPriceChunk from '@salesforce/apex/UploadPricebookEntriesController.processPriceChunk';



const CHUNK_SIZE = 10;



export default class UploadPricebookEntries extends LightningElement {

    @track showSpinner;

    @track fullRows = [];
    @track displayedRows = [];
    @track hasMoreData = false;
    @track isParsing = false;
    @track isUploading = false;
    @track progressPercent = 0;
    @track statusMessage = '';

    loadBatchSize = 50;
    sheetJsInitialized = false;

    columns = [
        { label: 'Material', fieldName: 'Material' },
        { label: 'Material Description', fieldName: 'MaterialDescription' },
        { label: 'DOM Price', fieldName: 'DomesticPrice', type: 'number' },
        { label: 'Conv Rate Dollar', fieldName: 'ConvDollar', type: 'number' },
        { label: 'EXP Price Dollar', fieldName: 'ExportDollar', type: 'number' },
        { label: 'Conv Rate Euro', fieldName: 'ConvEuro', type: 'number' },
        { label: 'EXP Price Euro', fieldName: 'ExportEuro', type: 'number' },
        // status columns appended to preview
        { label: 'Message', fieldName: 'Message' },
        { label: 'Status', fieldName: 'Status' }

    ];


    renderedCallback() {
        if (this.sheetJsInitialized) return;
        this.sheetJsInitialized = true;
        // loadScript(this, SHEETJS + '/xlsx.full.min.js')
        loadScript(this, SHEETJS)
            .then(() => {
                // sheetjs available as window.XLSX
                console.log('XLSX loaded');

            })
            .catch(error => {
                this.showToast('Error', 'Unable to load XLSX', 'error', error);
            });
    }

    downloadXlsx() {
        this.downloadTemplate('xlsx');
    }

    downloadCsv() {
        this.downloadTemplate('csv');
    }

    downloadTemplate(format) {
        const headers = [
            'Material',
            'Material Description',
            'Domestic Price',
            'Conversion Rate Dollar',
            'Export Price Dollar',
            'Conversion Rate Euro',
            'Export Price Euro'
        ];

        // helper to convert ArrayBuffer/Uint8Array to base64
        const arrayBufferToBase64 = (buffer) => {
            let binary = '';
            const bytes = new Uint8Array(buffer);
            const len = bytes.byteLength;
            for (let i = 0; i < len; i++) {
                binary += String.fromCharCode(bytes[i]);
            }
            return window.btoa(binary);
        };

        // If user asked for XLSX and SheetJS is available, produce .xlsx
        if (format === 'xlsx' && window.XLSX) {
            try {
                const ws = window.XLSX.utils.aoa_to_sheet([headers]);
                const wb = window.XLSX.utils.book_new();
                window.XLSX.utils.book_append_sheet(wb, ws, 'Template');
                // produce array (ArrayBuffer-like / Uint8Array)
                const wbout = window.XLSX.write(wb, { bookType: 'xlsx', type: 'array' });
                const uint8 = new Uint8Array(wbout);
                const blob = new Blob([uint8], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' });

                // Try createObjectURL first
                try {
                    if (window.navigator && window.navigator.msSaveOrOpenBlob) {
                        window.navigator.msSaveOrOpenBlob(blob, 'price_template.xlsx');
                        return;
                    }
                    const url = URL.createObjectURL(blob);
                    const link = document.createElement('a');
                    link.href = url;
                    link.setAttribute('download', 'price_template.xlsx');
                    link.style.display = 'none';
                    document.body.appendChild(link);
                    link.click();
                    document.body.removeChild(link);
                    URL.revokeObjectURL(url);
                    return;
                } catch (e) {
                    // fallback to data URI
                    console.warn('createObjectURL failed for xlsx, falling back to base64 data URI', e);
                    const base64 = arrayBufferToBase64(uint8);
                    const href = 'data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,' + base64;
                    const link = document.createElement('a');
                    link.href = href;
                    link.setAttribute('download', 'price_template.xlsx');
                    link.style.display = 'none';
                    document.body.appendChild(link);
                    link.click();
                    document.body.removeChild(link);
                    return;
                }
            } catch (e) {
                console.warn('XLSX generation failed, falling back to CSV', e);
                this.showToast('Warning', 'Could not create .xlsx, falling back to .csv', 'warning', e);
                format = 'csv';
            }
        }

        // CSV fallback
        if (format === 'csv') {
            const csv = headers.join(',') + '\r\n';
            try {
                const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
                if (window.navigator && window.navigator.msSaveOrOpenBlob) {
                    window.navigator.msSaveOrOpenBlob(blob, 'price_template.csv');
                    return;
                }
                const url = URL.createObjectURL(blob);
                const link = document.createElement('a');
                link.href = url;
                link.setAttribute('download', 'price_template.csv');
                link.style.display = 'none';
                document.body.appendChild(link);
                link.click();
                document.body.removeChild(link);
                URL.revokeObjectURL(url);
            } catch (err) {
                const data = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csv);
                const link = document.createElement('a');
                link.href = data;
                link.setAttribute('download', 'price_template.csv');
                link.style.display = 'none';
                document.body.appendChild(link);
                link.click();
                document.body.removeChild(link);
            }
        }
    }


    handleLoadMore(event) {
        if (!this.hasMoreData) {
            return;
        }

        // reference the datatable element explicitly (event.target can be undefined in some environments)
        const dt = this.template.querySelector('lightning-datatable');
        if (dt && typeof dt.isLoading !== 'undefined') {
            try { dt.isLoading = true; } catch (e) { /* ignore */ }
        }

        // load next batch asynchronously to allow UI update
        setTimeout(() => {
            const current = this.displayedRows.length;
            const remaining = Math.max(0, this.fullRows.length - current);
            if (remaining <= 0) {
                this.hasMoreData = false;
                if (dt && typeof dt.isLoading !== 'undefined') {
                    try { dt.isLoading = false; } catch (e) { /* ignore */ }
                }
                return;
            }

            const toLoad = Math.min(this.loadBatchSize, remaining);
            const next = this.fullRows.slice(current, current + toLoad);
            // append
            this.displayedRows = this.displayedRows.concat(next);
            this.hasMoreData = this.fullRows.length > this.displayedRows.length;

            if (dt && typeof dt.isLoading !== 'undefined') {
                try { dt.isLoading = false; } catch (e) { /* ignore */ }
            }
        }, 100);
    }


    handleFile(evt) {
        const file = evt.target.files[0];
        if (!file) return;
        this.isParsing = true;
        const ext = file.name.split('.').pop().toLowerCase();
        const reader = new FileReader();

        reader.onload = (e) => {
            const data = e.target.result;
            setTimeout(() => {
                try {
                    if (ext === 'xlsx') {
                        const workbook = window.XLSX.read(data, { type: 'array' });
                        const firstSheetName = workbook.SheetNames[0];
                        const sheet = workbook.Sheets[firstSheetName];
                        const json = window.XLSX.utils.sheet_to_json(sheet, { defval: null });
                        this.handleParsedRows(json);
                    } else if (ext === 'csv' || ext === 'txt') {
                        const wb = window.XLSX.read(data, { type: 'binary' });
                        const sname = wb.SheetNames[0];
                        const sj = window.XLSX.utils.sheet_to_json(wb.Sheets[sname], { defval: null });
                        this.handleParsedRows(sj);
                    } else {
                        this.showToast('Error', 'Unsupported file type. Please upload .xlsx or .csv', 'error');
                        this.statusMessage = 'Unsupported file type. Please upload .xlsx or .csv';
                    }
                } catch (err) {
                    this.showToast('Error', 'Error parsing file', 'error', err);
                    this.statusMessage = 'Error parsing file: ' + (err.message || err);
                } finally {
                    this.isParsing = false;
                }
            }, 50);
        };

        if (ext === 'xlsx') {
            reader.readAsArrayBuffer(file);
        } else {
            reader.readAsBinaryString(file);
        }
    }

    handleParsedRows(rows) {
        // Normalize columns and map to our column keys
        const mapped = rows.map((r, idx) => {
            return {
                __rowIndex: idx + 1,
                Material: r['Material'] || r['material'] || r['MATERIAL'] || r['Material '],
                MaterialDescription: r['Material Description'] || r['MaterialDescription'] || r['Description'],
                DomesticPrice: r['Domestic Price'] || r['Domestic Price'] || r['DomesticPrice'] || null,
                ConvDollar: r['Conversion Rate Dollar'] || r['ConversionRateDollar'] || null,
                ExportDollar: r['Export Price Dollar'] || r['ExportPriceDollar'] || null,
                ConvEuro: r['Conversion Rate Euro'] || null,
                ExportEuro: r['Export Price Euro'] || null,
                // placeholders for status
                Status: '',
                Message: ''
            };
        });
        // Basic validation - require Material and at least one price
        mapped.forEach(row => {
            row.__valid = !!(row.Material && (row.DomesticPrice || row.ExportDollar || row.ExportEuro));
            if (!row.__valid) {
                row.Status = 'Invalid';
                row.Message = 'Missing Material / Price';
            }
        });
        this.fullRows = mapped;
        // initialize displayedRows with first batch
        this.displayedRows = this.fullRows.slice(0, this.loadBatchSize);
        this.hasMoreData = this.fullRows.length > this.displayedRows.length;
        this.progressPercent = 0;
        this.statusMessage = ''
    }

    // File: pricebookUploader.js (startUpload method only)
    async startUpload() {
        console.log('=== START UPLOAD ===');
        if (!this.fullRows.length) return;

        const rowsToProcess = this.fullRows.filter(r => r.__valid);
        console.log('Valid rows to process:', rowsToProcess.length);
        console.log('Sample row data:', JSON.parse(JSON.stringify(rowsToProcess[0])));

        if (!rowsToProcess.length) {
            this.showToast('Warning', 'No valid rows to upload', 'warning');
            this.statusMessage = 'No valid rows to upload.';
            return;
        }

        this.isUploading = true;
        this.progressPercent = 0;
        this.statusMessage = 'Preparing upload...';

        const expanded = [];
        rowsToProcess.forEach((r) => {
            const base = {
                __rowIndex: r.__rowIndex,
                Material: r.Material,
                ConvDollar: r.ConvDollar,
                ConvEuro: r.ConvEuro
            };
            console.log('Base object for row:', base);

            if (r.DomesticPrice != null)
                expanded.push({ ...base, Currency: 'INR', UnitPrice: r.DomesticPrice, SourceLabel: 'Domestic' });
            if (r.ExportDollar != null)
                expanded.push({ ...base, Currency: 'USD', UnitPrice: r.ExportDollar, SourceLabel: 'USD' });
            if (r.ExportEuro != null)
                expanded.push({ ...base, Currency: 'EUR', UnitPrice: r.ExportEuro, SourceLabel: 'EUR' });
        });

        console.log('Expanded data to send to Apex:', expanded);

        const total = expanded.length;
        let processed = 0;

        // process chunks sequentially
        for (let i = 0; i < expanded.length; i += CHUNK_SIZE) {
            const chunk = expanded.slice(i, i + CHUNK_SIZE);
            const chunkStart = i;
            this.statusMessage = `Uploading rows ${i + 1} to ${i + chunk.length}...`;

            // yield for UI update
            await new Promise((res) => setTimeout(res, 50));

            try {
                const result = await processPriceChunk({ rowsJson: JSON.stringify(chunk) });

                // aggregate results per global __rowIndex
                const agg = new Map();
                result.forEach((r, idx) => {
                    const globalIdx = r.__rowIndex !== undefined && r.__rowIndex !== null
                        ? Number(r.__rowIndex)
                        : (chunkStart + idx);
                    if (!agg.has(globalIdx)) agg.set(globalIdx, { statuses: new Set(), messages: new Set() });
                    const entry = agg.get(globalIdx);
                    if (r.Status) entry.statuses.add(r.Status);
                    if (r.Message) entry.messages.add(r.Message);
                });

                // write aggregated results to UI
                agg.forEach((val, globalIdx) => {
                    const pr = this.fullRows.find(p => Number(p.__rowIndex) === Number(globalIdx));
                    if (!pr) return;

                    const statuses = Array.from(val.statuses);
                    let finalStatus = 'Processed';
                    if (statuses.includes('Failed')) finalStatus = 'Failed';
                    else if (statuses.length === 1) finalStatus = statuses[0];
                    else if (statuses.length > 1) finalStatus = statuses.join(' / ');

                    const messages = Array.from(val.messages).filter(m => m && m !== '');
                    const finalMessage = messages.length ? messages.join(' | ') : '';

                    pr.Status = finalStatus;
                    pr.Message = finalMessage;

                    // reassign arrays so LWC detects changes and re-renders
                    this.fullRows = this.fullRows.map(x => x);

                    const dispIdx = this.displayedRows.findIndex(p => Number(p.__rowIndex) === Number(globalIdx));
                    if (dispIdx !== -1) {
                        this.displayedRows[dispIdx].Status = pr.Status;
                        this.displayedRows[dispIdx].Message = pr.Message;
                        // reassign to trigger rerender
                        this.displayedRows = this.displayedRows.map(x => x);
                    }
                });

                processed += chunk.length;
                this.progressPercent = Math.round((processed / total) * 100);

            }

            catch (err) {
                const msg = err.body ? (err.body.message || JSON.stringify(err.body)) : String(err);
                chunk.forEach(c => {
                    const globalIdx = c.__rowIndex !== undefined && c.__rowIndex !== null ? Number(c.__rowIndex) : null;
                    const pr = this.fullRows.find(p => Number(p.__rowIndex) === Number(globalIdx));
                    if (pr) {
                        pr.Status = 'Failed';
                        pr.Message = msg;
                        const dispIdx = this.displayedRows.findIndex(p => Number(p.__rowIndex) === Number(globalIdx));
                        if (dispIdx !== -1) {
                            this.displayedRows[dispIdx].Status = 'Failed';
                            this.displayedRows[dispIdx].Message = msg;
                        }
                    }
                });

                processed += chunk.length;
                this.progressPercent = Math.round((processed / total) * 100);
            }
        }

        this.isUploading = false;
        this.statusMessage = 'Upload finished';
    }



    showToast(title, message, variant, error) {
        let msg = message;
        if (error) {
            msg = error.body ? error.body.message : error;
        }
        const showToast = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant
        });
        this.dispatchEvent(showToast);
    }

}