import { LightningElement, wire, track, api } from 'lwc';
import getProductData from '@salesforce/apex/SendTDSFileFromOpportunity.getProductData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getFiledDisplay from '@salesforce/apex/SendTDSFileFromOpportunity.getFiledDisplay';
import getDocumentUrl from '@salesforce/apex/SendTDSFileFromOpportunity.getDocumentUrl';
import getEmailDetails from '@salesforce/apex/SendTDSFileFromOpportunity.getEmailDetails';
import sendMailToCustomer from '@salesforce/apex/SendTDSFileFromOpportunity.sendMailToCustomer';
import getLead from '@salesforce/apex/SendTDSFileFromOpportunity.getLead';
import requestApproval from '@salesforce/apex/SendTDSFileFromOpportunity.requestApproval';
import updateApproversAndSendEmails from '@salesforce/apex/DocumentApprovalHandlerForOpp.updateApproversAndSendEmails';
import isRequestDocumentSubmitted from '@salesforce/apex/DocumentApprovalHandlerForOpp.isRequestDocumentSubmitted';
import getDocumentModel from '@salesforce/apex/DocumentApprovalHandlerForOpp.getDocumentModel';
import uploadDocuments from '@salesforce/apex/DocumentApprovalHandlerForOpp.uploadDocuments';
import sendLeadDocumentEmail from '@salesforce/apex/DocumentApprovalHandlerForOpp.sendLeadDocumentEmail';
import savePreviousViewType from '@salesforce/apex/DocumentApprovalHandlerForOpp.savePreviousViewType';
import getPreviousViewType from '@salesforce/apex/DocumentApprovalHandlerForOpp.getPreviousViewType';
import saveRemarks from '@salesforce/apex/DocumentApprovalHandlerForOpp.saveRemarks';


import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';

export default class AttachTdsMsdsOnLead extends NavigationMixin(LightningElement) {
    @api rId;
    @track linkIdSet = [];
    @track subject = 'Rossari Biotech TDS/MSDS/Tech Doc/COA Doc Files';
    @track ToAddress = '';
    @track ccAddress = '';
    @track commnetBody = 'Dear Sir/Madam,<br/><br/>Please find attached Rossari Biotech TDS/MSDS/Tech Doc/COA Doc Files.';
    @track OpenModal = false;
    @track isLoading = false;
    @track tableData = [];
    @track isSendDisabled = false;
    @track isSaveDisabled = false;

    @track isRequestDocumentSubmittedFlag = false;

    @track approverModel = {};

    @track viewType = '';

    @track leadDetail = {};

    @track documentModel = {};

    @track uploadedFiles = {
        tdsSampleFiles: [],
        msdsSampleFiles: [],
        techDocSampleFiles: [],
        coaSampleFiles: []
    };

    filesData = [];

    get isViewTypeProduct() {
        return this.viewType === 'product';
    }

    get isViewTypeCustomer() {
        return this.viewType === 'customer';
    }

    get isRequestDocumentButtonDisabled() {
        return !this.approverModel.tdsApproverId && !this.approverModel.msdsApproverId && !this.approverModel.technicalDocApproverId && !this.approverModel.coaDocApproverId;
    }

    get tdsRemarkDisabled() {
        return !this.approverModel.tdsApproverId;
    }
    get msdsRemarkDisabled() {
        return !this.approverModel.msdsApproverId;
    }
    get techDocRemarkDisabled() {
        return !this.approverModel.technicalDocApproverId;
    }
    get coaRemarkDisabled() {
        return !this.approverModel.coaDocApproverId;
    }

    @track viewTypeOptions = [
        { label: 'Product Specific', value: 'product' },
        { label: 'Customer Specific', value: 'customer' }
    ];

    handleViewtypeChange(event) {
        this.viewType = event.target.value;


        if (this.viewType === 'customer') {
            this.getProduct();
            this.getLeadDetail();
            this.getLeadInformation();
            this.checkIfRequestDocumentSubmitted();
            this.getDocumentDetails();

        } else if (this.viewType === 'product') {
            this.getProduct();
            this.getLeadDetail();
            this.getLeadInformation();
        }

        this.saveViewType();
    }

    getViewType() {
        console.log('getViewType leadId', this.rId)
        getPreviousViewType({leadId: this.rId}).then((result)=>{
            this.viewType = result;
        }).catch((error)=>{
            this.showToast('Error', 'error', error?.body?.message);
        })
    }

    saveViewType() {
        savePreviousViewType({leadId: this.rId, viewType: this.viewType}).then((result)=>{
            console.log('View Type Saved', result);
        }).catch((error)=>{
            this.showToast('Error', 'error', error?.body?.message);
        })
    }

    // Generic upload handler for all types
    handleSampleUpload(event) {
        const type = event.target.dataset.type;

        const input = document.createElement('input');
        input.type = 'file';
        input.multiple = true;

        input.onchange = () => {
            const files = Array.from(input.files);

            files.forEach(file => {
                const reader = new FileReader();
                reader.onload = () => {
                    const base64 = reader.result.split(',')[1]; // remove "data:*/*;base64,"
                    if (!this.uploadedFiles[type]) this.uploadedFiles[type] = [];
                    this.uploadedFiles[type].push({
                        fileName: file.name,
                        base64Data: base64
                    });
                };
                reader.readAsDataURL(file);
            });
        };

        input.click();
    }

    // Remove a file from the JSON object
    handleRemoveFile(event) {
        const type = event.target.dataset.type;
        const fileName = event.target.dataset.name;

        this.uploadedFiles[type] = this.uploadedFiles[type].filter(f => f.name !== fileName);
    }

    sendLeadDocument() {
        let toAddresses = this.ToAddress ? this.ToAddress.split(',').map(email => email.trim()) : [];
        let ccAddresses = this.ccAddress ? this.ccAddress.split(',').map(email => email.trim()) : [];
        sendLeadDocumentEmail({leadId: this.rId, toAddresses: toAddresses, ccAddresses: ccAddresses, subject: this.subject, body: this.commnetBody}).then((result)=>{
            if (result == 'Email sent successfully.') {
                this.showToast('Success', 'success', 'Email sent successfully');
                this.backTorecord();
            } else {
                this.showToast('Error', 'error', result);
            }
        }).catch((error)=>{
            this.showToast('Error', 'error', error.body.message);
        })
    }

    getDocumentDetails() {
        getDocumentModel({leadId: this.rId}).then((result)=>{
            console.log('Document Model', result);
            this.documentModel = result;
            this.isSaveDisabled = this.documentModel.isSaveDisabled;
        }).catch((error)=>{
            this.showToast('Error', 'error', error.body.message);
        })
    }

    handleRemarkChange(event) {
        let value = event.target.value;
        let field = event.target.dataset.id;

        this.documentModel[field] = value;
    }

    triggerFileInput(type) {
        this.template.querySelector(`input[data-type="${type}"]`).click();
    }

    // Upload button handlers
    handleTdsUpload() {
        this.triggerFileInput('tds');
    }
    handleMsdsUpload() {
        this.triggerFileInput('msds');
    }
    handleTechnicalDocUpload() {
        this.triggerFileInput('tech');
    }
    handleCoaDocUpload() {
        this.triggerFileInput('coa');
    }

    handleTdsFiles(event) {
        const files = event.target.files;

        if (!this.documentModel.tdsFiles) this.documentModel.tdsFiles = [];
        if (!this.documentModel.tdsFileNames) this.documentModel.tdsFileNames = [];

        Array.from(files).forEach(file => {
            const reader = new FileReader();

            reader.onload = () => {
                const base64 = reader.result.split(',')[1];

                // Append to tdsFiles (base64 for Apex)
                this.documentModel.tdsFiles = [
                    ...this.documentModel.tdsFiles,
                    {
                        fileName: file.name,
                        base64: base64
                    }
                ];

                // Append to tdsFileNames (for display)
                this.documentModel.tdsFileNames = [
                    ...this.documentModel.tdsFileNames,
                    file.name
                ];

                console.log('Updated tdsFiles:', this.documentModel.tdsFiles);
                console.log('Updated tdsFileNames:', this.documentModel.tdsFileNames);
            };

            reader.readAsDataURL(file);
        });
    }
    handleMsdsFiles(event) {
        const files = event.target.files;

        if (!this.documentModel.msdsFiles) this.documentModel.msdsFiles = [];
        if (!this.documentModel.msdsFileNames) this.documentModel.msdsFileNames = [];

        Array.from(files).forEach(file => {
            const reader = new FileReader();

            reader.onload = () => {
                const base64 = reader.result.split(',')[1];

                // Append to msdsFiles (base64 for Apex)
                this.documentModel.msdsFiles = [
                    ...this.documentModel.msdsFiles,
                    {
                        fileName: file.name,
                        base64: base64
                    }
                ];

                // Append to msdsFileNames (for display)
                this.documentModel.msdsFileNames = [
                    ...this.documentModel.msdsFileNames,
                    file.name
                ];

                console.log('Updated msdsFiles:', this.documentModel.msdsFiles);
                console.log('Updated msdsFileNames:', this.documentModel.msdsFileNames);
            };

            reader.readAsDataURL(file);
        });
    }

    handleTechnicalDocFiles(event) {
        const files = event.target.files;

        if (!this.documentModel.technicalDocumentFiles) this.documentModel.technicalDocumentFiles = [];
        if (!this.documentModel.technicalDocumentFileNames) this.documentModel.technicalDocumentFileNames = [];

        Array.from(files).forEach(file => {
            const reader = new FileReader();

            reader.onload = () => {
                const base64 = reader.result.split(',')[1];

                // Append to technicalDocumentFiles (base64 for Apex)
                this.documentModel.technicalDocumentFiles = [
                    ...this.documentModel.technicalDocumentFiles,
                    {
                        fileName: file.name,
                        base64: base64
                    }
                ];

                // Append to technicalDocumentFileNames (for display)
                this.documentModel.technicalDocumentFileNames = [
                    ...this.documentModel.technicalDocumentFileNames,
                    file.name
                ];

                console.log('Updated technicalDocumentFiles:', this.documentModel.technicalDocumentFiles);
                console.log('Updated technicalDocumentFileNames:', this.documentModel.technicalDocumentFileNames);
            };

            reader.readAsDataURL(file);
        });
    }

    handleCoaDocFiles(event) {
        const files = event.target.files;

        if (!this.documentModel.coaDocumentFiles) this.documentModel.coaDocumentFiles = [];
        if (!this.documentModel.coaDocumentFileNames) this.documentModel.coaDocumentFileNames = [];

        Array.from(files).forEach(file => {
            const reader = new FileReader();

            reader.onload = () => {
                const base64 = reader.result.split(',')[1];

                // Append to coaDocumentFiles (base64 for Apex)
                this.documentModel.coaDocumentFiles = [
                    ...this.documentModel.coaDocumentFiles,
                    {
                        fileName: file.name,
                        base64: base64
                    }
                ];

                // Append to coaDocumentFileNames (for display)
                this.documentModel.coaDocumentFileNames = [
                    ...this.documentModel.coaDocumentFileNames,
                    file.name
                ];

                console.log('Updated coaDocumentFiles:', this.documentModel.coaDocumentFiles);
                console.log('Updated coaDocumentFileNames:', this.documentModel.coaDocumentFileNames);
            };

            reader.readAsDataURL(file);
        });
    }


    uploadFilesToRecord() {
        if (this.isSaveDisabled) return;
        this.isSaveDisabled = true;
        console.log('Uploading files:', JSON.parse(JSON.stringify(this.documentModel)));
        uploadDocuments({tdsFiles: this.documentModel.tdsFiles, msdsFiles: this.documentModel.msdsFiles, technicalDocumentFiles: this.documentModel.technicalDocumentFiles, coaDocumentFiles: this.documentModel.coaDocumentFiles, leadId: this.rId}).then((result)=>{
            if (result == 'Success') {
                this.showToast('Success', 'success', 'Files uploaded successfully');
                this.backTorecord();
            }
        }).catch((error)=>{
            this.isSaveDisabled = false;
            this.showToast('Error', 'error', error.body.message);
        })
    }

    removeTdsFile(event) {
        const index = event.currentTarget.dataset.index;
        const file = this.documentModel.tdsFiles[index];
        if (file) {
            this.documentModel.tdsFiles = this.documentModel.tdsFiles.filter((_, i) => i != index);
            this.documentModel.tdsFileNames = this.documentModel.tdsFileNames.filter((_, i) => i != index);
        }
    }

    removeMsdsFile(event) {
        const index = event.currentTarget.dataset.index;
        const file = this.documentModel.msdsFiles[index];
        if (file) {
            this.documentModel.msdsFiles = this.documentModel.msdsFiles.filter((_, i) => i != index);
            this.documentModel.msdsFileNames = this.documentModel.msdsFileNames.filter((_, i) => i != index);
        }
    }

    removeTechnicalDocFile(event) {
        const index = event.currentTarget.dataset.index;
        const file = this.documentModel.technicalDocumentFiles[index];
        if (file) {
            this.documentModel.technicalDocumentFiles = this.documentModel.technicalDocumentFiles.filter((_, i) => i != index);
            this.documentModel.technicalDocumentFileNames = this.documentModel.technicalDocumentFileNames.filter((_, i) => i != index);
        }
    }

    removeCoaDocFile(event) {
        const index = event.currentTarget.dataset.index;
        const file = this.documentModel.coaDocumentFiles[index];
        if (file) {
            this.documentModel.coaDocumentFiles = this.documentModel.coaDocumentFiles.filter((_, i) => i != index);
            this.documentModel.coaDocumentFileNames = this.documentModel.coaDocumentFileNames.filter((_, i) => i != index);
        }
    }

    checkIfRequestDocumentSubmitted() {
        if (this.rId) {
            isRequestDocumentSubmitted({leadId: this.rId}).then((result)=>{
                this.isRequestDocumentSubmittedFlag = result;
            }).catch((error)=>{
                this.showToast('Error', 'error', error.body.message);
            })
        }
    }

    handleApproverChange(event) {
        console.log(JSON.parse(JSON.stringify(event)));
        let field = event.target.dataset.id;
        this.approverModel[field] = event.detail?.Id;
    }

    handleRequestDocument() {
        this.isLoading = true;
        saveRemarks({tdsRemark: this.documentModel.tdsApproverRemark, msdsRemark: this.documentModel.msdsApproverRemark, techDocRemark: this.documentModel.technicalDocApproverRemark, coaDocRemark: this.documentModel.coaDocApproverRemark, leadId: this.rId}).then((result)=>{
            if (result == 'Success') {
                console.log('uploadedFiles', JSON.parse(JSON.stringify(this.uploadedFiles)));
                updateApproversAndSendEmails({ approverStringObject: JSON.stringify(this.approverModel), sampleDocumentStringObj: JSON.stringify(this.uploadedFiles), leadId: this.rId }).then((result)=>{
                    if (result == 'Success') {
                        this.showToast('Success', 'success', 'Request for approval sent successfully');
                        this.backTorecord();
                    }
                }).catch((error)=>{
                    this.showToast('Error', 'error', error.body.message);
                })
            }
        }).catch((error)=>{
            this.isLoading = false;
            this.showToast('Error', 'error', error.body.message);
        })
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.rId = currentPageReference.state.c__recordId || currentPageReference.attributes.c__recordId;
            this.getProduct();
            this.getLeadDetail();
        }
    }

    get isLevel1ApprovalPersonSelected() {
        return !this.leadDetail.level1User;
    }

    get isSendEmailDisabled() {
        return !this.leadDetail.enableSendEmail;
    }

    connectedCallback() {
        console.log('leadId', this.rId);
        Promise.all([
            this.getViewType()
        ])

        setTimeout(() => {
            if (this.viewType == 'customer') {
                this.getProduct();
                this.getLeadDetail();
                this.getLeadInformation();
                this.checkIfRequestDocumentSubmitted();
                this.getDocumentDetails();
            } else if (this.viewType == 'product') {
                this.getProduct();
                this.getLeadDetail();
                this.getLeadInformation();
            }
        }, 1500);

    }

    getLeadDetail() {
        getEmailDetails({ leadId: this.rId }).then(data => {
            if (data != null) {
                this.ToAddress = data.Email;
                this.ccAddress = data.Owner.Email;
            } else {
                this.showToast('Error', 'Error', 'Lead Contact Email not found');
            }
        });
    }

    getLeadInformation() {
        getLead({leadId: this.rId}).then((result)=>{
            console.log('lead Info', result);
            this.leadDetail = result;
        }).catch((error)=>{
            this.showToast('Error', error.body.message, 'error');
        })
    }

    handleCoaApprovalStatus(event) {
        let field = event.target.dataset.field;

        this.leadDetail[field] = event.detail.recordId;
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

    handleRequestApproval() {
        requestApproval({leadStringObject: JSON.stringify(this.leadDetail)}).then((result)=>{
            if (result == 'Success') {
                this.showToast('Success', 'success', 'Request for approval sent successfully');
                this.backTorecord();
            }
        }).catch((error)=>{
            this.showToast('Error', 'error', error.body.message);
        })
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
        if (this.isViewTypeCustomer || (this.linkIdSet.length > 0 || this.filesData.length > 0)) {
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