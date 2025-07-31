import { LightningElement, wire, track, api } from 'lwc';
import getProductData from '@salesforce/apex/SendTDSFile.getProductData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getFiledDisplay from '@salesforce/apex/SendTDSFile.getFiledDisplay';
import getDocumentUrl from '@salesforce/apex/SendTDSFile.getDocumentUrl';
import getEmailDetails from '@salesforce/apex/SendTDSFile.getEmailDetails';
import sendMailToCustomer from '@salesforce/apex/SendTDSFile.sendMailToCustomer';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';

export default class AttachTdsMsdsOnLead extends NavigationMixin(LightningElement) {
    @api rId;
    @track linkIdSet = [];
    @track subject = 'Rossari Biotech TDS/MSDS Files';
    @track ToAddress = '';
    @track ccAddress = '';
    @track commnetBody = 'Dear Sir/Madam,<br/><br/>Please find attached Rossari Biotech TDS/MSDS Files.';
    @track OpenModal = false;
    @track isLoading = false;
    @track tableData = [];
    @track isSendDisabled = false;
    filesData = [];

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.rId = currentPageReference.state.c__recordId || currentPageReference.attributes.c__recordId;
            this.getProduct();
            this.getLeadDetail();
        }
    }

    connectedCallback() {
        this.getProduct();
        this.getLeadDetail();
    }

    getLeadDetail() {
        getEmailDetails({ leadId: this.rId }).then(data => {
            if (data != null) {
                this.ToAddress = data;
            } else {
                this.showToast('Error', 'Error', 'Lead Contact Email not found');
            }
        });
    }

    handleToAddressChange(event) {
        this.ToAddress = event.target.value;
    }

    handleCCAddressChange(event) {
        this.ccAddress = event.target.value;
    }

    handleSubChange(event) {
        this.subject = event.target.value;
    }

    handleBodyChange(event) {
        this.commnetBody = event.target.value;
    }

    handleSendMail() {
        if (!this.ToAddress) {
            this.showToast('Subject', 'Error', 'Please fill To Address');
        } else if (!this.subject) {
            this.showToast('Subject', 'Error', 'Please fill Subject');
        } else if (!this.commnetBody) {
            this.showToast('Email body', 'Error', 'Please fill Email body');
        } else if (this.linkIdSet.length === 0 && this.filesData.length === 0) {
            this.showToast('Error', 'Error', 'Please select at least one file');
        } else {
            this.sendMail();
        }
    }

    handleFileChange(event) {
        const files = event.target.files;
        if (files.length === 0) return;

        const allowedTypes = ['application/pdf', 'image/jpeg', 'image/jpg'];
        const validFiles = [...files].filter(file => allowedTypes.includes(file.type));

        if (validFiles.length === 0) {
            this.showToast('Error', 'error', 'Only PDF, JPG, and JPEG files are allowed.');
            return;
        }

        const fileReadPromises = validFiles.map(file => {
            return new Promise((resolve) => {
                const reader = new FileReader();
                reader.onload = () => {
                    resolve({
                        filename: file.name,
                        base64: reader.result.split(',')[1]
                    });
                };
                reader.readAsDataURL(file);
            });
        });

        Promise.all(fileReadPromises)
            .then(results => {
                this.filesData = [...(this.filesData || []), ...results];
            })
            .catch(error => {
                console.error('File reading failed:', error);
            });
    }

    async sendMail() {
        if (this.isSendDisabled) return;
        this.isSendDisabled = true;

        try {
            let ccArray = [];
            if (this.ccAddress) {
                ccArray = this.ccAddress.split(',').map(email => email.trim());
            }

            const result = await sendMailToCustomer({
                toAdd: this.ToAddress,
                cc: ccArray,
                subject: this.subject,
                body: this.commnetBody,
                fileId: JSON.stringify(this.linkIdSet),
                attachmentsFromUploadFile: this.filesData
            });

            let data = JSON.parse(result);
            if (data.Success) {
                this.showToast('Success', 'Success', 'Email sent Successfully');
                this.OpenModal = false;
                this.goBackToLead();
            } else if (data.error) {
                this.showToast('Error', 'Error', data.error);
            }
        } catch (error) {
            this.showToast('Error', 'Error', error.body?.message || error.message);
        } finally {
            this.isSendDisabled = false;
        }
    }

    hideModalBox() {
        this.OpenModal = false;
    }

    getProduct() {
        this.tableData = [];
        this.isLoading = true;

        getProductData({ leadId: this.rId }).then(data => {
            this.isLoading = false;
            if (data != null) {
                try {
                    this.tableData = JSON.parse(data);
                } catch (error) {
                    console.error('Error parsing data:', error);
                    this.showToast('Error', 'Error', 'Invalid data format received');
                }
            } else {
                this.showToast('Error', 'Error', 'No Data Found');
            }
        }).catch(error => {
            this.isLoading = false;
            this.showToast('Error', 'Error', error.body?.message || error.message);
        });
    }

    goBackToLead() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.rId,
                objectApiName: 'Lead',
                actionName: 'view'
            }
        });
    }

    openModaltoSend() {
        if (this.linkIdSet.length > 0 || this.filesData.length > 0) {
            this.OpenModal = true;
        } else {
            this.showToast('Error', 'Error', 'Please select at least one file');
        }
    }

    handleOpenChild(event) {
        const id = event.target.dataset.id;
        const level = event.target.dataset.level;
        const action = event.target.dataset.action;

        if (level === 'product') {
            this.toggleProductSection(id, action);
        } else if (level === 'document') {
            this.toggleDocumentSection(id, action);
        }
    }

    // toggleProductSection(productId, action) {
    //     const productIndex = this.tableData.findIndex(item => item.Id === productId);
    //     if (productIndex === -1) return;

    //     if (action === 'open') {
    //         this.tableData[productIndex].openFiles = false;
    //         this.tableData[productIndex].closeFiles = true;
    //         this.tableData[productIndex].showChildData = true;
    //     } else {
    //         this.tableData[productIndex].openFiles = true;
    //         this.tableData[productIndex].closeFiles = false;
    //         this.tableData[productIndex].showChildData = false;
    //         this.unselectAllFilesInProduct(productId);
    //     }
    //     this.tableData = [...this.tableData];
    // }

    toggleProductSection(productId, action) {
        const productIndex = this.tableData.findIndex(item => item.Id === productId);
        if (productIndex === -1) return;

        const product = this.tableData[productIndex];

        // Check if product has any document records when trying to expand
        if (action === 'open' && (!product.dataChildFiles || product.dataChildFiles.length === 0)) {
            this.showToast(
                'Warning',
                'No Documents',
                `Product "${product.Name}" (${product.ProductCode}) doesn't have any associated documents.`
            );
            return; // Don't proceed with expansion
        }

        if (action === 'open') {
            product.openFiles = false;
            product.closeFiles = true;
            product.showChildData = true;
        } else {
            product.openFiles = true;
            product.closeFiles = false;
            product.showChildData = false;
            this.unselectAllFilesInProduct(productId);
        }
        this.tableData = [...this.tableData];
    }

    toggleDocumentSection(docId, action) {
        for (let product of this.tableData) {
            const docIndex = product.dataChildFiles.findIndex(doc => doc.Id === docId);
            if (docIndex !== -1) {
                if (action === 'open') {
                    product.dataChildFiles[docIndex].openFiles = false;
                    product.dataChildFiles[docIndex].closeFiles = true;
                    product.dataChildFiles[docIndex].showChildData = true;
                    this.getFileDetail(product.dataChildFiles[docIndex]);
                } else {
                    product.dataChildFiles[docIndex].openFiles = true;
                    product.dataChildFiles[docIndex].closeFiles = false;
                    product.dataChildFiles[docIndex].showChildData = false;
                    this.unselectAllFilesInDocument(docId);
                }
                break;
            }
        }
        this.tableData = [...this.tableData];
    }

    getFileDetail(docWrapper) {
        if (docWrapper.dataChildFiles.length > 0) return;

        getFiledDisplay({ docId: docWrapper.Id }).then(data => {
            if (data != null) {
                docWrapper.dataChildFiles = JSON.parse(data);
                this.tableData = [...this.tableData];
            } else {
                this.showToast('Error', 'Error', 'Files Not Found');
            }
        });
    }

    unselectAllFilesInProduct(productId) {
        const product = this.tableData.find(item => item.Id === productId);
        if (!product) return;

        for (let doc of product.dataChildFiles) {
            for (let file of doc.dataChildFiles) {
                file.selectFile = false;
            }
        }
        this.linkIdSet = this.linkIdSet.filter(id =>
            !product.dataChildFiles.some(doc =>
                doc.dataChildFiles.some(file => file.Id === id)
            )
        );
    }

    unselectAllFilesInDocument(docId) {
        for (let product of this.tableData) {
            const doc = product.dataChildFiles.find(d => d.Id === docId);
            if (doc) {
                for (let file of doc.dataChildFiles) {
                    file.selectFile = false;
                }
                this.linkIdSet = this.linkIdSet.filter(id =>
                    !doc.dataChildFiles.some(file => file.Id === id)
                );
                break;
            }
        }
    }

    handleFileSelect(event) {
        const isChecked = event.target.checked;
        const fileId = event.target.dataset.id;

        if (isChecked) {
            if (!this.linkIdSet.includes(fileId)) {
                this.linkIdSet.push(fileId);
            }
        } else {
            this.linkIdSet = this.linkIdSet.filter(id => id !== fileId);
        }
    }

    removeFile(event) {
        const index = event.target.dataset.index;
        this.filesData = this.filesData.filter((_, i) => i != index);
    }

    showToast(title, variant, msg) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message: msg,
            variant
        }));
    }

    viewFile(event) {
        const fileId = event.target.dataset.id;
        getDocumentUrl({ Id: fileId }).then(result => {
            if (result) {
                this[NavigationMixin.Navigate]({
                    type: 'standard__namedPage',
                    attributes: {
                        pageName: 'filePreview'
                    },
                    state: {
                        selectedRecordId: result
                    }
                });
            }
        });
    }

    backTorecord() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.rId,
                objectApiName: 'Lead',
                actionName: 'view'
            }
        });
    }
}