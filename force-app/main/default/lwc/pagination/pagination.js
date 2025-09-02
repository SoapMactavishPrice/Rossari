import { LightningElement, api } from 'lwc';

export default class Pagination extends LightningElement {
    @api recordSize = 0;
    @api pageSize = 10;
    totalPages = 0;
    currentPage = 1;

    get records() {
        return this.visibleRecords;
    }

    @api 
    set records(data) {
        if (data) {
            this.totalRecords = data;
            this.recordSize = data.length;
            this.totalPages = Math.ceil(data.length / this.pageSize);
            this.updateRecords();
        }
    }

    get disablePrevious() { 
        return this.currentPage <= 1;
    }

    get disableNext() { 
        return this.currentPage >= this.totalPages;
    }

    previousHandler() {
        if (this.currentPage > 1) {
            this.currentPage = this.currentPage - 1;
            this.updateRecords();
        }
    }

    nextHandler() {
        if (this.currentPage < this.totalPages) {
            this.currentPage = this.currentPage + 1;
            this.updateRecords();
        }
    }

    updateRecords() {
        const start = (this.currentPage - 1) * this.pageSize;
        const end = this.pageSize * this.currentPage;
        this.visibleRecords = this.totalRecords.slice(start, end);
        this.dispatchEvent(new CustomEvent('paginatorchange', { 
            detail: {
                records: this.visibleRecords
            }
        }));
    }
}
