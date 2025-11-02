import { LightningElement, track, api } from 'lwc';
import getCustomerDetail from '@salesforce/apex/CustomerOnboardingFormController.getCustomerDetail';
import getSalesData from '@salesforce/apex/CustomerOnboardingFormController.getSalesData';
import sendEmailWithAttachment from '@salesforce/apex/CustomerOnboardingFormController.sendEmailWithAttachment';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import sendXlsxEmail from '@salesforce/apex/CustomerOnboardingFormController.sendXlsxEmail';
import deletefile from '@salesforce/apex/CustomerOnboardingFormController.deletefile';
import getDocumentUrl from '@salesforce/apex/CustomerOnboardingFormController.getDocumentUrl';
import getDetails from '@salesforce/apex/CustomerOnboardingFormController.getDetails';
import getRecordTypeFromQuote from '@salesforce/apex/Utility.getRecordTypeFromQuote';


import { NavigationMixin } from 'lightning/navigation';
import xlsxLib from '@salesforce/resourceUrl/xlsx';
import { loadScript } from 'lightning/platformResourceLoader';

import CUSTOMER_ONBOARDING_EMAIL from '@salesforce/label/c.CutomerOnboardingEmail';




export default class CustomerOnboardingForm extends NavigationMixin(LightningElement) {
    @api recordId;
    @track leadRecordType;
    @track activeSection = 'general'; // Default open section

    xlsxLoaded = false;

    renderedCallback() {
        if (this.xlsxLoaded) {
            return;
        }
        this.xlsxLoaded = true;

        loadScript(this, xlsxLib)
            .then(() => {
                console.log('✅ XLSX library loaded');
            })
            .catch(error => {
                console.error('❌ Failed to load XLSX', error);
            });
    }

    handleSectionToggle(event) {
        const openSections = event.detail.openSections;

        // If user closes everything, keep none active
        if (Array.isArray(openSections) && openSections.length > 0) {
            // Take the latest opened section
            this.activeSection = openSections[openSections.length - 1];
        } else {
            this.activeSection = '';
        }
    }



    @track columns = [
        { label: 'Customer Number', fieldName: 'customer_Number' },
        { label: 'BP Role', fieldName: 'BP_Role' }
    ];

    @track companyHeader = [
        { label: 'Customer Number', fieldName: 'customer_Number' },
        { label: 'Company Code', fieldName: 'Company_Code' },
        { label: 'Payment Terms', fieldName: 'Payment_Terms' },
        { label: 'Reconciliation Account', fieldName: 'Reconciliation_Account' }
    ];




    @track outputTaxHeader = [
        { label: 'Customer Number', fieldName: 'customer_Number' },
        { label: 'Country/Region', fieldName: 'Country_Region' },
        { label: 'Tax Category', fieldName: 'Tax_Category' },
        { label: 'Tax Classification', fieldName: 'Tax_Classification' }
    ];

    @track outputTaxdata = [
        { customer_Number: '', Country_Region: 'IN', Tax_Category: 'JOIG', Tax_Classification: '0' },
        { customer_Number: '', Country_Region: 'IN', Tax_Category: 'JOUG', Tax_Classification: '0' },
        { customer_Number: '', Country_Region: 'IN', Tax_Category: 'JOSG', Tax_Classification: '0' },
        { customer_Number: '', Country_Region: 'IN', Tax_Category: 'JOCG', Tax_Classification: '0' },


    ];

    @track TaxHeader = [
        { label: 'Customer Number', fieldName: 'customer_Number' },
        { label: 'Tax Number Category*', fieldName: 'Tax_Number_Category' },
        { label: 'Tax Number', fieldName: 'Tax_Number' },

    ];

    @track Taxdata = [
        { customer_Number: '1999900', Tax_Number_Category: 'IN3', Tax_Number: '27AANCM4754B1ZE' },


    ];

    @track fieldMap = {};   // ✅ Using plain object

    handleCustomerChange(event) {
        const key = event.target.dataset.label;
        const value = event.target.value;

        console.log('Input Changed → Key:', key, ', Value:', value);

        // ✅ Handle blank value → remove key if exists
        if (value === '') {
            if (this.fieldMap.hasOwnProperty(key)) {
                delete this.fieldMap[key];
                console.log(`Removed key "${key}" because value is blank`);
            }
        } else {
            // ✅ Add or update key in object
            this.fieldMap[key] = value;
        }

        // ✅ Debug object
        console.log('Current fieldMap object:', this.fieldMap);
    }

    @track label = {
        CUSTOMER_ONBOARDING_EMAIL
    };
    connectedCallback() {
        this.handleGetRecordId();
        this.loadSalesData();
        this.getRecordType();
    }

    getRecordType() {
        getRecordTypeFromQuote({quoteId: this.recordId}).then(result => {
            this.leadRecordType = result;
        }
        ).catch(error => {
            this.showError('Error fetching quote record type', error.body ? error.body.message : error.message);
        })
    }



    @track salesOrgNames = [];
    @track divisionNames = [];
    @track distributionChannelNames = [];

    loadSalesData() {
        getSalesData()
            .then((result) => {
                this.salesOrgNames = result.SalesOrg ? result.SalesOrg.map(item => item.Name) : [];
                this.divisionNames = result.Division ? result.Division.map(item => item.Name) : [];
                this.distributionChannelNames = result.DistributionChannel ? result.DistributionChannel.map(item => item.Name) : [];


                console.log('Error fetching sales data:', JSON.stringify(this.salesOrgNames), JSON.stringify(this.divisionNames), JSON.stringify(this.distributionChannelNames));

            })
            .catch((error) => {
                this.error = error;
                this.salesOrgList = [];
                this.divisionList = [];
                this.distributionChannelList = [];

            });
    }


    handleGetRecordId() {

        console.log('Current fieldMap:', this.recordId);

        getCustomerDetail({ Id: this.recordId }).then(result => {
            let data = JSON.parse(JSON.stringify(result));
            console.log('Current fieldMap:', JSON.parse(JSON.stringify(data)));
            this.fieldMap.SF_Customer_Id = data.AccountId || null;
            this.fieldMap.SFDC_Customer_Code = data.Account?.SFDC_Customer_Code__c || null; //SFDC_Customer_Code__c
            this.fieldMap.account_Group = data.Cust_Acct_Group__c || null;
            this.fieldMap.name = data.Name || null;
            this.fieldMap.name_2 = data.Account?.Account_Name_2__c || null;
            this.fieldMap.title = data.Account?.Title__c || null;
            this.fieldMap.search_Term = data.Account?.Search_term__c || null;
            this.fieldMap.pan_Number = data.Account?.Pan_No__c || null;
            this.fieldMap.postal_Code = data.Account?.Post_Code__c || null;
            this.fieldMap.city = data.Account?.City__c || null;
            this.fieldMap.country = data.Account?.Country__c || null;
            this.fieldMap.state = data.Account?.State1__c || null;
            //this.fieldMap.SAP_Customer_Code =data.SAP_Customer_Code__c || null;
            this.fieldMap.Street = data.Account?.Street1__c || null;
            this.fieldMap.street_2 = data.Account?.Street2__c || null;
            this.fieldMap.street_3 = data.Account?.Street3__c || null;
            this.fieldMap.language = data.Account?.language__c || null;
            this.fieldMap.telephone = data.Account?.Phone || null;
            this.fieldMap.email = data.Account?.Email_Id__c || null;

            console.log('Current fieldMap:', this.fieldMap);

            this.createTableData();

        })
    }


    @track bpRole = ['FLCU00', 'FLCU01'];
    @track tableData = [
        // { customerNumber: '1999900', bpRole: 'FLCU00' },
        // { customerNumber: '1999900', bpRole: 'FLCU01' }
    ];

    @track bypassValidation = false;
    createTableData() {
        this.tableData = this.bpRole.map(role => {
            return {
                Customer_Number: this.fieldMap.SAP_Customer_Code,
                BP_Role: role
            };
        });


        this.outputTaxdata.forEach(ele => {
            ele.customer_Number = this.fieldMap.SAP_Customer_Code;
        })


        this.Taxdata.forEach(ele => {
            ele.customer_Number = this.fieldMap.SAP_Customer_Code;
        })

        this.addSalesRow();
        this.bypassValidation = false;

    }


    onTaxDataChange(event) {
        const index = event.target.dataset.index;
        const field = event.target.dataset.field;
        const value = event.target.value;

        this.Taxdata[index][field] = value;
        this.Taxdata = [...this.Taxdata];

        console.log('Updated Taxdata:', JSON.stringify(this.Taxdata));

    }


    onCompanyDataChange(event) {
        const uniqueId = event.target.dataset.index; // use uniqueId from dataset
        const field = event.target.dataset.field;
        const value = event.target.value;

        // Find index dynamically using uniqueId
        const cIndex = this.companyHeaderData.findIndex(ele => ele.uniqueId === uniqueId);
        console.log('cIndex-->', cIndex);

        if (cIndex !== -1) {
            this.companyHeaderData[cIndex][field] = value;
            this.companyHeaderData = [...this.companyHeaderData]; // trigger reactivity

            console.log('✅ Updated companyHeaderData:', JSON.stringify(this.companyHeaderData));
        } else {
            console.warn('❌ UniqueId not found in companyHeaderData:', uniqueId);
        }
    }



    usedIds = new Set();
    @track salesData = [];

    generateUniqueId() {
        let newId;
        do {
            newId = Math.floor(1000 + Math.random() * 9000).toString();
        } while (this.usedIds.has(newId));

        this.usedIds.add(newId);
        return newId;
    }


    get isMoreThanOneRow() {
        return this.salesData.length > 1;
    }


    // validateExistingRows() {
    //     const invalidRows = this.salesData.filter(row => {
    //         const isSalesOrgValid = this.salesOrgNames.includes(row.Sales_Organization);
    //         const isDivisionValid = this.divisionNames.includes(row.Division);
    //         const isDistChannelValid = this.distributionChannelNames.includes(row.Distribution_Channel);

    //         return !isSalesOrgValid || !isDivisionValid || !isDistChannelValid;
    //     });

    //     return invalidRows; // return the array of invalid rows
    // }


    //  validateExistingRows() {

    //         let isValid = true;

    //         this.salesData.forEach((row, index) => {
    //             const inputs = this.template.querySelectorAll(`[data-index="${index}"]`);


    //             inputs.forEach(input => {
    //                  console.log('input-->',JSON.stringify(input));
    //                 const field = input.dataset.field;
    //                 let valid = true;
    //                 let errorMsg = '';

    //                 if (field === 'Sales_Organization' && !this.salesOrgNames.includes(row.Sales_Organization)) {
    //                     valid = false;
    //                     errorMsg = 'Invalid Sales Organization';
    //                 }
    //                 else if (field === 'Division' && !this.divisionNames.includes(row.Division)) {
    //                     valid = false;
    //                     errorMsg = 'Invalid Division';
    //                 }
    //                 else if (field === 'Distribution_Channel' && !this.distributionChannelNames.includes(row.Distribution_Channel)) {
    //                     valid = false;
    //                     errorMsg = 'Invalid Distribution Channel';
    //                 }

    //                 if (!valid) {
    //                     isValid = false;
    //                     input.setCustomValidity(errorMsg);
    //                 } else {
    //                     input.setCustomValidity('');
    //                 }

    //                 input.reportValidity();
    //             });
    //         });

    //         return isValid;
    //     }


    addSalesRow() {
        this.bypassValidation = false;

        const customerNumber = this.fieldMap.SAP_Customer_Code || '';

        // Create new sales row
        const newRow = {
            uniqueId: this.generateUniqueId(),
            Customer_Number: customerNumber,
            Sales_Organization: '', // can be set dynamically later
            Distribution_Channel: '',
            Division: '',
            Customer_Group: '',
            Sales_District: '',
            Order_Probability: '100',
            Currency: 'INR',
            Exchange_Rate_Type: '',
            Price_Group: '01',
            Price_Procedure_Dterm: '1',
            Customer_Statistics_Group: '',
            Delivery_Priority: '01',
            Order_Combination: 'X',
            Shipping_Conditions: '01',
            Delivery_Plant: '',
            Incoterms: '',
            Inco_Location1: '',
            Payment_Terms: '',
            Account_Assignment_Group: '01',
            Customer_Group1: ''
        };


        this.salesData = [...this.salesData, newRow];
        setTimeout(() => {
            if (this.salesData.length == 1) {
                this.makeCompanyHeaderData();
                this.makeSalesData();
            }

        }, 4000);





    }
    @track salesManualData = [];



    // makeSalesData() {
    //     if (!this.salesData || this.salesData.length === 0) return;

    //     console.log('this.salesData-->', JSON.stringify(this.salesData));
    //     const uniqueSalesOrg = [
    //         ...new Set(this.salesData.map(row => row.Sales_Organization).filter(Boolean))
    //     ];
    //     // Step 1: Extract unique Divisions and Distribution Channels
    //     const uniqueDivisions = [
    //         ...new Set(this.salesData.map(row => row.Division).filter(Boolean))
    //     ];

    //     const uniqueDistChannels = [
    //         ...new Set(this.salesData.map(row => row.Distribution_Channel).filter(Boolean))
    //     ];

    //     // Step 2: Define fixed partner function pairs
    //     const partnerPairs = ['RE', 'WE', 'AG', 'VE', 'RG'];


    //     // Step 3: Generate all combinations
    //     const combinations = [];
    //     console.log('uniqueDivisions', uniqueDivisions);
    //     console.log('uniqueDistChannels', uniqueDistChannels);
    //     uniqueSalesOrg.forEach(org => {
    //         uniqueDivisions.forEach(div => {
    //             uniqueDistChannels.forEach(dist => {
    //                 partnerPairs.forEach(pair => {
    //                     combinations.push({
    //                         customer_Number: this.fieldMap.SAP_Customer_Code,

    //                         Sales_Organization: org,
    //                         Distribution_Channel: dist,
    //                         Division: div,
    //                         Partner_Function: pair,
    //                         Employee_Id: null,
    //                         uniqueId: this.generateUniqueId(),
    //                     });
    //                 });
    //             });
    //         });
    //     });

    //     // Step 4: Store in component variable (reactive)
    //     this.salesManualData = combinations;

    //     console.log('--> All Combinations -->', JSON.stringify(this.salesManualData));
    // }

    makeSalesData() {
        if (!this.salesData || this.salesData.length === 0) return;

        console.log('this.salesData-->', JSON.stringify(this.salesData));
        const partnerPairs = ['RE', 'WE', 'AG', 'VE', 'RG'];

        const seenCombinations = new Map();
        const combinations = [];

        this.salesData.forEach((row, index) => {
            if (row.Sales_Organization && row.Division && row.Distribution_Channel) {
                const comboKey = `${row.Sales_Organization}-${row.Division}-${row.Distribution_Channel}`;

                if (!seenCombinations.has(comboKey)) {
                    seenCombinations.set(comboKey, true);
                    partnerPairs.forEach(pair => {
                        combinations.push({
                            customer_Number: this.fieldMap.SAP_Customer_Code,
                            Sales_Organization: row.Sales_Organization,
                            Distribution_Channel: row.Distribution_Channel,
                            Division: row.Division,
                            Partner_Function: pair,
                            isVE: pair === 'VE',
                            Employee_Id: null,
                            uniqueId: this.generateUniqueId(),
                            // originalIndex: index, // Track which index created this
                            // comboKey: comboKey    // Track the combination
                        });
                    });
                } else {
                    console.log(`Index ${index}: Skipping duplicate combo: ${comboKey}`);
                }
            }
        });

        this.salesManualData = combinations;

        console.log('--> Index-wise Unique Combinations -->', JSON.stringify(this.salesManualData));
        console.log(`Total unique combinations: ${seenCombinations.size}`);
        console.log(`Total records created: ${combinations.length}`);
    }




    @track companyHeaderData = [];
    makeCompanyHeaderData() {
        if (!this.salesData || this.salesData.length === 0) return;

        const customerNumber = this.salesData[0]?.customer_Number || '';

        // Get unique Sales Organizations
        const uniqueSalesOrgs = [
            ...new Set(
                this.salesData
                    .filter(row => row.Sales_Organization)
                    .map(row => row.Sales_Organization)
            )
        ];

        // Filter out already existing company codes
        const newHeaders = uniqueSalesOrgs
            .filter(org =>
                !this.companyHeaderData?.some(row => row.Company_Code === org)
            )
            .map(org => ({
                uniqueId: this.generateUniqueId(),
                customer_Number: this.fieldMap.SAP_Customer_Code,
                Company_Code: org,
                Payment_Terms: 'C023',
                Reconciliation_Account: '20701010'
            }));

        // Append new headers if any
        if (newHeaders.length > 0) {
            this.companyHeaderData = [
                ...(this.companyHeaderData || []),
                ...newHeaders
            ];
        }

        console.log('-->JSON-->', JSON.stringify(this.companyHeaderData));
    }




    //this.salesOrgNames,this.divisionNames,this.distributionChannelNames
    // Remove specific row
    removeSalesRow(event) {
        if (this.salesData.length > 1) {
            const id = event.target.dataset.id;
            this.salesData = this.salesData.filter(row => row.uniqueId !== id);
        }
    }

    // Handle input changes
    handleSalesRowChange(event) {
        const id = event.target.dataset.id;
        const field = event.target.dataset.field;
        const value = event.target.value;

        this.salesData = this.salesData.map(row => {
            if (row.uniqueId === id) {
                return { ...row, [field]: value };
            }
            return row;
        });


        if (field == 'Sales_Organization') {
            setTimeout(() => {

                this.makeCompanyHeaderData();
                this.makeSalesData();

            }, 4000);


        }

        if (field == 'Distribution_Channel' || field == 'Division') {
            setTimeout(() => {

                this.makeSalesData();
                //this.makeSalesData();

            }, 1000);
        }

        ///console.log('Updated Sales Data:', JSON.stringify(this.salesData));
    }

    @track isModalOpen = false;
    @track toEmail = this.label.CUSTOMER_ONBOARDING_EMAIL;
    @track ccEmail = '';
    @track subject = 'Customer Onboarding Form';
    @track body = ''

    openModal() {
        this.isModalOpen = true;
    }



    handleSave() {
        if (!this.validateRequired()) return;
        // 👉 Here you can save as draft in Salesforce or local storage
        this.showToast('Success', 'Email draft saved successfully', 'success');
    }

    handleSaveAndSend() {
        if (!this.validateRequired()) return;

        // ⚡ Example Apex call if needed
        /*
        sendEmailApex({
            toEmail: this.toEmail,
            ccEmail: this.ccEmail,
            subject: this.subject,
            body: this.body
        })
        .then(() => {
            this.showToast('Success', 'Email sent successfully', 'success');
            this.closeModal();
        })
        .catch(error => {
            this.showToast('Error', error.body.message, 'error');
        });
        */

        // Temporary success toast
        this.showToast('Success', `Email sent to ${this.toEmail}`, 'success');
        this.closeModal();
    }

    formatHeader(header) {
        if (!header) return '';
        // Replace underscores with spaces
        let formatted = header.replace(/_/g, ' ');
        // Lowercase everything first
        formatted = formatted.toLowerCase();
        // Capitalize first letter
        formatted = formatted.charAt(0).toUpperCase() + formatted.slice(1);
        return formatted;
    }


    handleSendEmail() {
        console.log('fieldMap -->', JSON.stringify(this.fieldMap));
        console.log('salesData -->', JSON.stringify(this.salesData));
        console.log('tableData -->', JSON.stringify(this.tableData));
        console.log('companyHeaderData -->', JSON.stringify(this.companyHeaderData));
        console.log('outputTaxdata -->', JSON.stringify(this.outputTaxdata));
        console.log('Taxdata -->', JSON.stringify(this.Taxdata));

        if (typeof XLSX === 'undefined') {
            console.error('❌ XLSX not loaded yet!');
            return;
        }

        const workbook = XLSX.utils.book_new();

        // ✅ Helper function to format headers
        const formatHeader = (header) => {
            if (!header) return '';
            let formatted = header.replace(/_/g, ' ');
            formatted = formatted.toLowerCase();
            formatted = formatted.charAt(0).toUpperCase() + formatted.slice(1);
            return formatted;
        };

        // ✅ Helper function to format sheet headers from JSON array
        const createFormattedSheet = (data) => {
            if (!data || data.length === 0) return null;
            // Get original headers
            const originalHeaders = Object.keys(data[0]);
            // Map to formatted headers
            const formattedHeaders = originalHeaders.map(formatHeader);
            // Convert to sheet
            const sheet = XLSX.utils.json_to_sheet(data, { header: originalHeaders });
            // Replace header row with formatted names
            XLSX.utils.sheet_add_aoa(sheet, [formattedHeaders], { origin: 'A1' });
            return sheet;
        };

        // 🧾  FIELD MAP → Key/Value table with formatted headers
        if (this.fieldMap) {
            const keys = Object.keys(this.fieldMap);
            const formattedKeys = keys.map(formatHeader);
            const values = Object.values(this.fieldMap);

            const fieldMapRows = [formattedKeys, values];
            const fieldMapSheet = XLSX.utils.aoa_to_sheet(fieldMapRows);
            XLSX.utils.book_append_sheet(workbook, fieldMapSheet, 'General Data');
        }


        // 🧾 BP ROLE DATA
        const bpSheet = createFormattedSheet(this.tableData);
        if (bpSheet) {
            XLSX.utils.book_append_sheet(workbook, bpSheet, 'BP Role');
        }

        // 🧾  SALES DATA

        const cleansalesData = this.salesData.map(({ uniqueId, ...rest }) => rest);
        const salesSheet = createFormattedSheet(cleansalesData);
        if (salesSheet) {
            XLSX.utils.book_append_sheet(workbook, salesSheet, 'Sales Data');
        }

        // 🧾 COMPANY Saless Partner

        const cleanSalesPartnerData = this.salesManualData.map(({ uniqueId, isVE, ...rest }) => rest);

        const SalessPartnerSheet = createFormattedSheet(cleanSalesPartnerData);
        if (SalessPartnerSheet) {
            XLSX.utils.book_append_sheet(workbook, SalessPartnerSheet, 'Sales Partner');
        }


        const cleancompanySheetData = this.companyHeaderData.map(({ uniqueId, ...rest }) => rest);
        // 🧾 COMPANY HEADER DATA
        const companySheet = createFormattedSheet(cleancompanySheetData);
        if (companySheet) {
            XLSX.utils.book_append_sheet(workbook, companySheet, 'Company Data');
        }

        // 🧾  OUTPUT TAX
        const outputTaxSheet = createFormattedSheet(this.outputTaxdata);
        if (outputTaxSheet) {
            XLSX.utils.book_append_sheet(workbook, outputTaxSheet, 'Output Tax');
        }

        const cleanTaxdata = this.Taxdata.map(({ uniqueId, ...rest }) => rest);
        // 🧾 6️⃣ TAX DATA
        const taxSheet = createFormattedSheet(cleanTaxdata);
        if (taxSheet) {
            XLSX.utils.book_append_sheet(workbook, taxSheet, 'Tax Numbers');
        }

        // 📎 Generate XLSX binary
        const wbout = XLSX.write(workbook, { bookType: 'xlsx', type: 'array' });

        // 🧠 Convert to Base64
        let binary = '';
        const bytes = new Uint8Array(wbout);
        const chunkSize = 0x8000;
        for (let i = 0; i < bytes.length; i += chunkSize) {
            const chunk = bytes.subarray(i, i + chunkSize);
            binary += String.fromCharCode.apply(null, chunk);
        }
        const base64File = btoa(binary);

        let uploadedFileIds = this.uploadedFiles.map(f => f.id);
        console.log('uploadedFileIds-->', JSON.stringify(uploadedFileIds));

        // 📤 Send to Apex
        sendXlsxEmail({
            fileName: 'Customer_Onboarding_Data.xlsx',
            base64Data: base64File,
            recipientEmail: this.toEmail,
            body: this.body,
            subject: this.subject,
            ccEmail: this.ccEmail,
            contentDocumentIds: uploadedFileIds
        })
            .then(() => {
                this.showToast('Success', 'Email Send !!!', 'Success');
                setTimeout(() => {
                    this.handleNavigateToRecord();
                }, 1000);
                console.log('✅ Excel with formatted headers emailed successfully!');
            })
            .catch(error => {
                console.error('❌ Error sending email', error);
            });
    }


    handleEmpChange(event) {
        console.log('temp-->', JSON.stringify(event.detail));
        const data = JSON.parse(JSON.stringify(event.detail));
        console.log('data-->', data.subField, event.currentTarget.dataset.uniqueid);

        let index = this.salesManualData.findIndex(ele => ele.uniqueId == event.currentTarget.dataset.uniqueid);
        console.log('index-->', index);

        if (index != -1) {
            this.salesManualData[index].Employee_Id = data.subField;
            console.log('data--1->', JSON.stringify(this.salesManualData[index]));
        }




    }


    validateRequired() {
        if (!this.toEmail) {
            this.showToast('Error', 'To Email is required', 'error');
            return false;
        }

        // Optional: validate cc comma-separated emails
        if (this.ccEmail) {
            const ccList = this.ccEmail.split(',').map(email => email.trim());
            const invalid = ccList.some(email => !this.validateEmail(email));
            if (invalid) {
                this.showToast('Error', 'One or more CC emails are invalid', 'error');
                return false;
            }
        }
        return true;
    }

    validateEmail(email) {
        const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return regex.test(email);
    }


    closeModal() {
        this.isModalOpen = false;
    }


    handleChange(event) {
        const field = event.target.dataset.field;
        this[field] = event.target.value;
    }

    handleRefresh() {
        this.ccEmail = '';
        this.body = '';
        this.showToast('Refreshed', 'All fields cleared', 'info');
    }


    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }


    @track General_Data = [
        'account_Group', 'name', 'name_2', 'title', 'search_Term',
        'pan_Number', 'street', 'postal_Code', 'city', 'country',
        'state', 'street_2', 'street_3', 'language', 'telephone', 'email', 'SAP_Customer_Code'
    ];

    sendXlsEmail() {
        const sheetsXml = [];

        // Convert fieldMap object to array of values
        const fieldArray = this.General_Data.map(header => this.fieldMap[header] || '');
        const dataRows = [fieldArray]; // wrap in array of arrays for buildWorksheetXml

        // Build worksheet
        sheetsXml.push(this.buildWorksheetXml('General Data', this.General_Data, dataRows));

        // Build workbook XML
        const workbookXml = this.buildWorkbookXml(sheetsXml);

        // Convert to Base64
        const base64Content = btoa(unescape(encodeURIComponent(workbookXml)));

        // Call Apex to send email
        sendEmailWithAttachment({
            toAddresses: 'praveen@finessedirect.com',
            ccAddresses: null,
            subject: 'Excel File Attachment',
            body: 'Please find attached the exported Excel file.',
            fileName: 'ExportedData.xml', // XML is safe for Excel
            base64Content: base64Content
        })
            .then(() => {
                console.log('Email sent successfully');
            })
            .catch(error => {
                console.error('Error sending email', error);
            });
    }

    // Build a single worksheet with header + data rows
    buildWorksheetXml(sheetName, headers, dataRows) {
        let rowsXml = '';

        // Header row
        rowsXml += '<Row>';
        headers.forEach(header => {
            const safeHeader = String(header)
                .replace(/&/g, '&amp;')
                .replace(/</g, '&lt;')
                .replace(/>/g, '&gt;')
                .replace(/"/g, '&quot;')
                .replace(/'/g, '&apos;');
            rowsXml += `<Cell ss:StyleID="Header"><Data ss:Type="String">${safeHeader}</Data></Cell>`;
        });
        rowsXml += '</Row>';

        // Data rows
        dataRows.forEach(row => {
            rowsXml += '<Row>';
            row.forEach(cell => {
                const safeCell = String(cell || '')
                    .replace(/&/g, '&amp;')
                    .replace(/</g, '&lt;')
                    .replace(/>/g, '&gt;')
                    .replace(/"/g, '&quot;')
                    .replace(/'/g, '&apos;');
                rowsXml += `<Cell><Data ss:Type="String">${safeCell}</Data></Cell>`;
            });
            rowsXml += '</Row>';
        });

        return `<Worksheet ss:Name="${sheetName}"><Table>${rowsXml}</Table></Worksheet>`;
    }

    // Build workbook with all sheets
    buildWorkbookXml(sheetsXml) {
        return `<?xml version="1.0"?>
<?mso-application progid="Excel.Sheet"?>
<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"
          xmlns:o="urn:schemas-microsoft-com:office:office"
          xmlns:x="urn:schemas-microsoft-com:office:excel"
          xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"
          xmlns:html="http://www.w3.org/TR/REC-html40">
    ${sheetsXml.join('')}
</Workbook>`;
    }




    @track isFileUpload = false;
    @track uploadedFiles = [];
    uploadFile() {
        this.isFileUpload = true;
    }


    closeFileModal() {
        this.isFileUpload = false;
    }

    @track uploadedFiles = [];

    handleFilesChange(event) {
        const files = event.target.files;
        for (let i = 0; i < files.length; i++) {
            const file = files[i];

            // Avoid duplicates by name
            if (!this.uploadedFiles.find(f => f.name === file.name)) {
                this.uploadedFiles = [
                    ...this.uploadedFiles,
                    {
                        index: this.generateUniqueId(),
                        id: file.name,
                        name: file.name,
                        type: file.type,
                        file: file, // store original File object
                        url: URL.createObjectURL(file)
                    }
                ];
            }
        }
    }


    handleRemoveFile(event) {
        const fileId = event.target.dataset.id;


        deletefile({ prodId: fileId }).then(result => {

            if (result) {
                this.uploadedFiles = this.uploadedFiles.filter(f => f.id !== fileId);
                this.showToast('Success', `File Deleted Successfully`, 'success');
            }
        })
    }

    handleSelectFile(event) {
        const fileId = event.target.dataset.id;
        const file = this.uploadedFiles.find(f => f.id === fileId);
        if (file) {
            this.showToast('Selected', `Selected file: ${file.name}`);
            // Implement selection logic if needed
        }
    }

    handleUpload() {
        // Implement upload logic (e.g., Apex call or Files API)
        this.showToast('Upload', `${this.uploadedFiles.length} file(s) ready to upload`);
        this.closeModal();
    }

    showToast(title, message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: 'success'
            })
        );
    }

    viewFile(event) {
        let contentDocumentId = event.target.dataset.id; // this should be the 069C... ID
        console.log('ContentDocumentId:', contentDocumentId);

        getDocumentUrl({ Id: contentDocumentId }).then(result => {
            if (result) {
                console.log('Result from Apex:', result);

                this[NavigationMixin.Navigate]({
                    type: 'standard__namedPage',
                    attributes: {
                        pageName: 'filePreview'
                    },
                    state: {
                        selectedRecordId: result // pass the ContentDocumentId here
                    }
                });
            }
        }).catch(error => {
            console.error('Error fetching file URL:', error);
        });
    }

    deleteFile(event) {
        let fileIds = event.target.dataset.id;
        deletefile({ prodId: fileIds }).then(result => {
            if (result) {
                this.showToast('Success', `File Deleted Successfully`, 'success');
                this.fileViewdata = this.fileViewdata.filter(file => file.Id !== fileIds);
                if (this.fileViewdata.length == 0) {
                    this.isOpenFileView = false;
                }
            }
        })

    }

    get acceptedFormats() {
        return ['.pdf', '.png', '.jpg', '.jpeg', '.xls', '.xlsx'];
    }


    handleUploadFinished(event) {
        const uploaded = event.detail.files;


        uploaded.forEach(file => {
            // Avoid duplicates by ID
            console.log('file.documentId-->', JSON.stringify(file));
            if (!this.uploadedFiles.find(f => f.id === file.documentId)) {
                this.uploadedFiles = [
                    ...this.uploadedFiles,
                    {
                        id: file.documentId,
                        name: file.name,
                        type: this.getFileType(file.name),
                        url: `/sfc/servlet.shepherd/document/download/${file.documentId}` // direct preview URL
                    }
                ];
            }
        });

        this.showToast('Success', `${uploaded.length} file(s) uploaded`);
    }

    getFileType(fileName) {
        const ext = fileName.split('.').pop().toLowerCase();
        if (['png', 'jpg', 'jpeg'].includes(ext)) return 'Image';
        if (ext === 'pdf') return 'PDF';
        if (['xls', 'xlsx'].includes(ext)) return 'Excel';
        return 'Other';
    }





    handleNavigateToRecord() {

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view'       // view / edit / clone
            }
        });
    }





}