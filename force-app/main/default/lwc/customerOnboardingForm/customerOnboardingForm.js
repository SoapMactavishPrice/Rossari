import { LightningElement ,track,api} from 'lwc';
import getCustomerDetail from '@salesforce/apex/CustomerOnboardingFormController.getCustomerDetail';
import getSalesData from '@salesforce/apex/CustomerOnboardingFormController.getSalesData';
import sendEmailWithAttachment from '@salesforce/apex/CustomerOnboardingFormController.sendEmailWithAttachment';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';






export default class CustomerOnboardingForm extends LightningElement {
@api recordId;
    @track activeSection = 'general'; // Default open section

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
    { label: 'Customer Number', fieldName: 'customerNumber' },
    { label: 'BP Role', fieldName: 'bpRole' }
];

@track companyHeader = [
    { label: 'Customer Number', fieldName: 'customerNumber' },
    { label: 'Company Code', fieldName: 'ccCode' },
    { label: 'Payment Terms', fieldName: 'ptCode' },
    { label: 'Reconciliation Account', fieldName: 'raRole' }
];

    @track companyHeaderata = [
    { customerNumber: '', ccCode: '1000',ptCode:'C023',raRole:'20701010' },
    { customerNumber: '', ccCode: '3000',ptCode:'C023',raRole:'20701010' }
    
];


@track outputTaxHeader = [
    { label: 'Customer Number', fieldName: 'customerNumber' },
    { label: 'Country/Region', fieldName: 'countRegion' },
    { label: 'Tax Category', fieldName: 'taxCat' },
    { label: 'Tax Classification', fieldName: 'taxClass' }
];

    @track outputTaxdata = [
    { customerNumber: '', countRegion: 'IN',taxCat:'JOIG',taxClass:'0' },
    { customerNumber: '', countRegion: 'IN',taxCat:'JOUG',taxClass:'0' },
    { customerNumber: '', countRegion: 'IN',taxCat:'JOSG',taxClass:'0' },
    { customerNumber: '', countRegion: 'IN',taxCat:'JOCG',taxClass:'0' },
    
    
];

@track TaxHeader = [
    { label: 'Customer Number', fieldName: 'customerNumber' },
    { label: 'Tax Number Category*', fieldName: 'taxCat' },
    { label: 'Tax Number', fieldName: 'taxNum' },
    
];

    @track Taxdata = [
    { customerNumber: '1999900', taxCat: 'IN3',taxNum:'27AANCM4754B1ZE'},
    
    
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

connectedCallback(){
this.handleGetRecordId();
this.loadSalesData();
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


                console.log('Error fetching sales data:', JSON.stringify(this.salesOrgNames),JSON.stringify(this.divisionNames),JSON.stringify(this.distributionChannelNames));
                
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

    getCustomerDetail({Id:this.recordId}).then(result=>{
        let data= JSON.parse(JSON.stringify(result));
        console.log('Current fieldMap:', data);
        this.fieldMap.account_Group = data.Cust_Acct_Group__c|| null;
        this.fieldMap.name = data.Name|| null;
        this.fieldMap.name_2 = data.name_2__c|| null;
        this.fieldMap.title = data.Title__c|| null;
        this.fieldMap.search_Term = data.Search_term__c|| null;
        this.fieldMap.pan_Number = data.Pan_No__c|| null;
        this.fieldMap.postal_Code = data.Post_Code__c|| null;
            this.fieldMap.city = data.city|| null;
        this.fieldMap.country = data.Country_Text__c|| null;
        this.fieldMap.state = data.State1__c|| null;
        this.fieldMap.SAP_Customer_Code =data.SAP_Customer_Code__c || null;
        this.fieldMap.street_2 = data.Street2__c|| null;
            this.fieldMap.street_3 = data.Street3__c|| null;
            this.fieldMap.language = data.language__c|| null;
            this.fieldMap.telephone = data.Phone|| null;
            this.fieldMap.email = data.Email_Id__c|| null;

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
createTableData(){
    this.tableData = this.bpRole.map(role => {
            return {
                customerNumber: this.fieldMap.SAP_Customer_Code,
                bpRole: role
            };
        });


            this.outputTaxdata.forEach(ele=>{
                ele.customerNumber = this.fieldMap.SAP_Customer_Code;
            })


            this.Taxdata.forEach(ele=>{
                ele.customerNumber = this.fieldMap.SAP_Customer_Code;
            })

            this.Taxdata.forEach(ele=>{
                ele.customerNumber = this.fieldMap.SAP_Customer_Code;
            })

            this.companyHeaderata.forEach(ele=>{
                ele.customerNumber = this.fieldMap.SAP_Customer_Code;
            })
            this.addSalesRow();
            this.bypassValidation = false;

    }


    onTaxDataChange(event){
        const index = event.target.dataset.index;
        const field = event.target.dataset.field;
        const value = event.target.value;

        // Update the specific row and field
        this.Taxdata[index][field] = value;

        // Force reactivity in @track array
        this.Taxdata = [...this.Taxdata];

        console.log('Updated Taxdata:', JSON.stringify(this.Taxdata));

    }


    onCompanyDataChange(event){
        const index = event.target.dataset.index;
        const field = event.target.dataset.field;
        const value = event.target.value;

        // Update the specific row and field
        this.companyHeaderata[index][field] = value;

        // Force reactivity in @track array
        this.companyHeaderata = [...this.companyHeaderata];

        console.log('Updated companyHeaderata:', JSON.stringify(this.companyHeaderata));

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
    let isaddValid =  false;
    // if(!this.bypassValidation){
    //   isaddValid = this.validateExistingRows();
       
    // }
    this.bypassValidation = false;
    

      //if(isaddValid){
        const newRow = {
            uniqueId: this.generateUniqueId(),
            Customer_Number: this.fieldMap.SAP_Customer_Code, // example, can be dynamic
            Sales_Organization: '', // example
            Distribution_Channel: '',
            Division: '',
            Customer_Group: '',
            Sales_District: '',
            Order_Probability: '',
            Currency: '',
            Exchange_Rate_Type: '',
            Price_Group: '',
            Price_Procedure_Dterm: '',
            Customer_Statistics_Group: '',
            Delivery_Priority: '',
            Order_Combination: '',
            Shipping_Conditions: '',
            Delivery_Plant: '',
            Incoterms: '',
            Inco_Location1: '',
            Payment_Terms: '',
            Account_Assignment_Group: '',
            Customer_Group1: ''
        };
    


        
        this.salesData = [...this.salesData, newRow];
    //}
    }

    //this.salesOrgNames,this.divisionNames,this.distributionChannelNames
    // Remove specific row
    removeSalesRow(event) {
        if(this.salesData.length > 1){
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

        console.log('Updated Sales Data:', JSON.stringify(this.salesData));
    }

      @track isModalOpen = false;
    @track toEmail = '';
    @track ccEmail = '';
    @track subject = '';
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
        this.toEmail = '';
        this.ccEmail = '';
        this.subject = '';
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
        'account_Group','name','name_2','title','search_Term',
        'pan_Number','street','postal_Code','city','country',
        'state','street_2','street_3','language','telephone','email','SAP_Customer_Code'
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
            toAddresses: 'Rishikesh.Korade@finessedirect.com',
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









}