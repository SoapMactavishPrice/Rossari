@RestResource(urlMapping = '/UpsertAccountMaster/*')
global class AccountMaster_API {

    public static Map < String, Account > accountMap = new Map < String, Account > ();
    public static Map < String, Account > accountIdMap = new Map < String, Account > ();
    public static Map < String, City__c > cityMap = new Map < String, City__c > ();
    public static map < String, Contact > mapContaccTemp = new map < String, Contact > ();
    public static map < String, Bank_Information__c > bankInfoMap = new map < String, Bank_Information__c > ();
    public static Map < String, Pin_Code__c > postalCodeMap = new Map < String, Pin_Code__c > ();
    public static Map < String, Sales_Organisation__c > soMap = new Map < String, Sales_Organisation__c > ();
    public static Map < String, Distribution_Channel__c > dcMap = new Map < String, Distribution_Channel__c > ();
    public static Map < String, Division__c > diMap = new Map < String, Division__c > ();
    public static Map < String, Company__c > cmMap = new Map < String, Company__c > ();
    public static Map < String, Customer_Sales_Area__c > csaMap = new Map < String, Customer_Sales_Area__c > ();
    public static Map<String, Id> sapCodeToIdMap = new Map<String, Id>();
    public static List<AccountMasterRequest> accountRequests = new List<AccountMasterRequest> ();
    public static Map<String, Payment_Term__c> ptMap = new Map<String, Payment_Term__c>();
    public static Map<String, Sales_District__c> sdMap = new Map<String, Sales_District__c>();
    public static Set < String > custNumberSet = new Set < String > ();
    public static Set < String > customerSFIDSet = new Set < String > ();
    
    @HttpPost
    global static void upsertAccountMaster() {
        // Get the request body
        RestRequest request;
        RestResponse res;
        request = RestContext.request;
        res = RestContext.response;
        String requestBody = request.requestBody.toString().trim();
        if (String.isBlank(requestBody)) {
            throw new CustomException('No Customer data found');
        }

        ResponseWrapper response = new ResponseWrapper();
        Savepoint sp = Database.setSavepoint();

        API_log__c apiLog = new API_log__c();
        apiLog.Name = 'AccountMaster_API';
        
        try {
            
            // Deserialize the JSON into a list of AccountMasterRequest objects
            accountRequests = (List<AccountMasterRequest>) JSON.deserialize(requestBody, List<AccountMasterRequest>.class);
            
            apiLog.Request__c = requestBody;

            // Process all accounts first
            List<Account> accountsToUpsert = new List<Account>();
            Map<String, List<Contact>> accountContactsMap = new Map<String, List<Contact>>();
            Map<String, List<Bank_Information__c>> accountBankDetailsMap = new Map<String, List<Bank_Information__c>>();
            Map<String, List<Customer_Sales_Area__c>> accountSalesAreasMap = new Map<String, List<Customer_Sales_Area__c>>();

            // ! ========================================== Start (Get Existing Data) ========================================== ! //
            
            // Set < String > custNumberSet = new Set < String > ();
            Set < String > cityNameSet = new Set < String > ();
            Set < String > postalCodeSet = new Set < String > ();
            Set < String > salesOrgSet = new Set < String > ();
            Set < String > distChannelSet = new Set < String > ();
            Set < String > divisionSet = new Set < String > ();
            Set < String > companyCodeSet = new Set < String > ();

            for (AccountMasterRequest accMaster : accountRequests) {
                customerSFIDSet.add(accMaster.SFDC_ID);
                custNumberSet.add(accMaster.CUSTOMER_NO);
                cityNameSet.add(accMaster.CITY);
                for (SalesArea sa : accMaster.SALES_AREA) {
                    salesOrgSet.add(sa.SALES_ORG);
                    distChannelSet.add(sa.DISTR_CHL);
                    divisionSet.add(sa.DIVISION);
                    companyCodeSet.add(sa.DIVISION);
                    for (PartnerFunction pf : sa.PARTNER_FUNCTIONS) {
                        cityNameSet.add(pf.CITY0072);
                        cityNameSet.add(pf.CITY1);
                        custNumberSet.add(pf.CUSTOMR_NO);
                    }
                }
                if (accMaster.CONTACT != null && !accMaster.CONTACT.isEmpty()) {
                    for (ContactData con : accMaster.CONTACT) {
                        cityNameSet.add(con.CONTACT_CITY);
                        postalCodeSet.add(con.CONTACT_POSTCODE);
                    }
                }
            }

            // Get Existing Account list
            List < Account > accountList = new List < Account > ();
            List < Account > accountList2 = new List < Account > ();
            accountList = [
                SELECT Id, Name, SAP_Customer_Code__c, SFDC_Customer_Code__c
                FROM Account
                WHERE SAP_Customer_Code__c IN: custNumberSet
            ];
            accountList2 = [
                SELECT Id, Name, SAP_Customer_Code__c, SFDC_Customer_Code__c
                FROM Account
                WHERE SFDC_Customer_Code__c IN: customerSFIDSet
            ];

            // Map < String, Account > accountMap = new Map < String, Account > ();
            for (Account va: accountList) {
                accountMap.put(va.SAP_Customer_Code__c, va);
                // accountIdMap.put(va.SFDC_Customer_Code__c, va);
            }
            for (Account va: accountList) {
                // accountMap.put(va.SAP_Customer_Code__c, va);
                accountIdMap.put(va.SFDC_Customer_Code__c, va);
            }



            // Get Existing City list
            List < City__c > cityList = new List < City__c > ();
            cityList = [SELECT ID, Name FROM City__c WHERE Name IN: cityNameSet];

            // Map < String, City__c > cityMap = new Map < String, City__c > ();
            for (City__c va: cityList) {
                cityMap.put(va.Name, va);
            }

            // Get Existing Contact List
            List < Contact > contList = new List < Contact > ();
            contList = [
                SELECT Id, name, account.Name, account.SAP_Customer_Code__c, External_Id__c
                FROM contact
                WHERE account.SAP_Customer_Code__c IN :custNumberSet
            ];

            // map < String, Contact > mapContaccTemp = new map < String, Contact > ();
            for (Contact cn: contList) {
                mapContaccTemp.put(cn.External_Id__c, cn);
            }

            // Get Existing Contact List
            List < Bank_Information__c > bankInfoList = new List < Bank_Information__c > ();
            bankInfoList = [
                SELECT Id, Name, Account_Name__r.Name, Account_Name__r.SAP_Customer_Code__c, External_Id__c
                FROM Bank_Information__c
                WHERE Account_Name__r.SAP_Customer_Code__c IN :custNumberSet
            ];

            // map < String, Bank_Information__c > bankInfoMap = new map < String, Bank_Information__c > ();
            for (Bank_Information__c cn: bankInfoList) {
                bankInfoMap.put(cn.External_Id__c, cn);
            }

            // Get Existing Postal list
            List < Pin_Code__c > postalCodeList = new List < Pin_Code__c > ();
            postalCodeList = [SELECT ID, Name FROM Pin_Code__c WHERE Name IN: postalCodeSet];

            // Map < String, Pin_Code__c > postalCodeMap = new Map < String, Pin_Code__c > ();
            for (Pin_Code__c va: postalCodeList) {
                postalCodeMap.put(va.Name, va);
            }

            // Get Existing Sales Org
            List < Sales_Organisation__c > soList = new List < Sales_Organisation__c > ();
            soList = [SELECT ID, Name FROM Sales_Organisation__c WHERE Name IN: salesOrgSet];

            // Map < String, Sales_Organisation__c > soMap = new Map < String, Sales_Organisation__c > ();
            for (Sales_Organisation__c va: soList) {
                soMap.put(va.Name, va);
            }

            // Get Existing Distribution Channel
            List < Distribution_Channel__c > dcList = new List < Distribution_Channel__c > ();
            dcList = [SELECT Id, Distribution_Code__c FROM Distribution_Channel__c WHERE Distribution_Code__c IN: distChannelSet];

            // Map < String, Distribution_Channel__c > dcMap = new Map < String, Distribution_Channel__c > ();
            for (Distribution_Channel__c va: dcList) {
                dcMap.put(va.Distribution_Code__c, va);
            }

            // Get Existing Division
            List < Division__c > diList = new List < Division__c > ();
            diList = [SELECT Id, Division_Code__c FROM Division__c WHERE Division_Code__c IN: divisionSet];

            // Map < String, Division__c > diMap = new Map < String, Division__c > ();
            for (Division__c va: diList) {
                diMap.put(va.Division_Code__c, va);
            }

            // Get existing Company Code
            List < Company__c > cmList = new List < Company__c > ();
            cmList = [SELECT Id, SAP_Code__c FROM Company__c WHERE SAP_Code__c IN: companyCodeSet];

            Map < String, Company__c > cmMap = new Map < String, Company__c > ();
            for (Company__c va: cmList) {
                cmMap.put(va.SAP_Code__c, va);
            }

            // Get existing Customer Sales Area
            List < Customer_Sales_Area__c > csaList = new List < Customer_Sales_Area__c > ();
            csaList = [
                SELECT Id, Comapany_Code__c, Comapany_Code__r.SAP_Customer_Code__c,Sales_Organisation__c, Division__c,
                Sales_Organisation__r.Name, Distribution_Channel__c, Distribution_Channel__r.Distribution_Code__c, Division__r.Division_Code__c
                FROM Customer_Sales_Area__c
                WHERE Sales_Organisation__c != null
                AND Distribution_Channel__c != null
                AND Division__c != null
                AND Comapany_Code__r.SAP_Customer_Code__c IN :custNumberSet
            ];

            // Map < String, Customer_Sales_Area__c > csaMap = new Map < String, Customer_Sales_Area__c > ();
            for (Customer_Sales_Area__c va: csaList) {
                String mapKeyStr = va.Comapany_Code__r.SAP_Customer_Code__c+'-'+va.Sales_Organisation__r.Name+'-'+va.Distribution_Channel__r.Distribution_Code__c+'-'+va.Division__r.Division_Code__c;
                csaMap.put(mapKeyStr, va);
            }

            // Get Existing Payment Term
            List<Payment_Term__c> paymentTermList = [
                SELECT Id, Name, Payment_Term_Code__c
                FROM Payment_Term__c
            ];

            // Map<String, Payment_Term__c> ptMap = new Map<String, Payment_Term__c>();
            for (Payment_Term__c pt : paymentTermList) {
                ptMap.put(pt.Payment_Term_Code__c, pt);
            }

            // Get Existing Sales District
            List<Sales_District__c> salesDistrictList = [
                SELECT Id, Name, Sales_District_Code__c
                FROM Sales_District__c
            ];

            // Map<String, Sales_District__c> sdMap = new Map<String, Sales_District__c>();
            for (Sales_District__c pt : salesDistrictList) {
                sdMap.put(pt.Sales_District_Code__c, pt);
            }

            // ! ========================================== End (Get Existing Data) ========================================== ! //
            
            // Prepare all data for bulk processing
            for (AccountMasterRequest accMaster : accountRequests) {
                // Process Account
                Account acc = new Account();
                if (String.isNotBlank(accMaster.SFDC_ID)) {
                    if (accountIdMap.containsKey(accMaster.SFDC_ID)) {
                        acc.Id = accountIdMap.get(accMaster.SFDC_ID).id;    
                    } else {
                        if (accountMap.containsKey(accMaster.CUSTOMER_NO)) {
                            acc.Id = accountMap.get(accMaster.CUSTOMER_NO).id;    
                        }
                    }
                } else {
                    if (accountMap.containsKey(accMaster.CUSTOMER_NO)) {
                        acc.Id = accountMap.get(accMaster.CUSTOMER_NO).id;    
                    }
                }
                // Map fields from request to Account object
                // acc.SAP_Customer_Code__c = accMaster.Account_ID; //NTC
                // acc.SAP_Customer_Code__c = accMaster.ADDRESS;
                acc.GST_No__c = accMaster.TAXNO3;
                acc.Pan_No__c = accMaster.PAN_NO;
                acc.Mobile_Number__c = accMaster.MOBILE_NO;
                
                acc.Name = accMaster.CUST_NAME;
                acc.SAP_Customer_Code__c = accMaster.CUSTOMER_NO;
                acc.Cust_Acct_Group__c = accMaster.CUST_ACCT_GROUP;
                acc.Account_Group__c = accMaster.ACCOUNT_GROUP_C;
                acc.Title__c = accMaster.TITLE;
                acc.Landline_No_1__c = accMaster.C_TELEPHONE1;
                acc.Landline_No_2__c = accMaster.C_TELEPHONE2;
                acc.Email_Id__c = accMaster.EMAIL1;
                acc.Email_Id_2__c = accMaster.EMAIL2;
                acc.Email_Id_3__c = accMaster.EMAIL3;
                acc.Email_Id_4__c = accMaster.EMAIL4;
                acc.Email_Id_5__c = accMaster.EMAIL5;
                acc.Street1__c = accMaster.C_STREET;
                acc.Street2__c = accMaster.STREET2;
                acc.BillingStreet = accMaster.STREET;
                acc.Street__c = accMaster.HOUSE_NO;
                acc.Post_Code__c = accMaster.POST_CODE;
                acc.State1__c = accMaster.REGION;
                acc.RECON_ACCT__c = accMaster.RECON_ACCT;
                acc.City1__c = accMaster.CITY;  
                if (String.isNotBlank(accMaster.CITY)) {
                    if (cityMap.containsKey(accMaster.CITY)) {
                        acc.City__c = cityMap.get(accMaster.CITY).id;    
                    }
                }
                acc.Country_Text__c = accMaster.COUNTRY;
                acc.GST_Type__c = accMaster.GST_TYPE_C;
                acc.Industry = accMaster.INDUSTRY;
                acc.Recon_Account__c = accMaster.RECON_ACCOUNT;
                acc.Exch_Rate_Type_Code__c = accMaster.EXRATETYPE;
                acc.Exch_Rate_Type__c = accMaster.EXCH_RATE_TYPE_C;
                acc.CurrencyIsoCode = String.isNotBlank(accMaster.CURRNCY) ? accMaster.CURRNCY : 'INR';
                if (String.isNotBlank(accMaster.CRED_LIMIT)) {
                    String cl = accMaster.CRED_LIMIT.replace(',', '');
                    cl = cl.replace(' ', '');
                    // acc.Balance_Credit_Limit__c = String.isNotBlank(accMaster.CRED_LIMIT) ? Decimal.valueOf(cl) : null;
                    acc.Credit_Limit__c = String.isNotBlank(accMaster.CRED_LIMIT) ? Decimal.valueOf(cl) : null;
                }
                accountsToUpsert.add(acc);
            }
            
            // Bulk upsert accounts
            Database.UpsertResult[] accountResults = Database.upsert(
                accountsToUpsert, 
                Account.Fields.SAP_Customer_Code__c, 
                false
            );
            
            // Process results
            Map<Id, Account> successAccounts = new Map<Id, Account>();
            // Map<String, Id> sapCodeToIdMap = new Map<String, Id>();
            for (Integer i = 0; i < accountResults.size(); i++) {
                if (accountResults[i].isSuccess()) {
                    Account acc = accountsToUpsert[i];
                    successAccounts.put(accountResults[i].getId(), accountsToUpsert[i]);
                    sapCodeToIdMap.put(acc.SAP_Customer_Code__c, accountResults[i].getId());
                } else {
                    for (Database.Error err : accountResults[i].getErrors()) {
                        response.errors.add('Account ' + accountsToUpsert[i].SAP_Customer_Code__c + ' error: ' + err.getMessage());
                    }
                }
            }
            
            // Process related records for successful accounts
            if (!successAccounts.isEmpty()) {

                for (AccountMasterRequest accMaster : accountRequests) {
                    // Process Contacts
                    Account acc = successAccounts.get(sapCodeToIdMap.get(accMaster.CUSTOMER_NO));
                    if (accMaster.CONTACT != null && !accMaster.CONTACT.isEmpty()) {
                        if (sapCodeToIdMap.containsKey(accMaster.CUSTOMER_NO)) {
                            accountContactsMap.put(accMaster.CUSTOMER_NO, prepareContacts(accMaster.CONTACT, acc));
                        }
                    }
                    
                    // Process Bank Details
                    if (accMaster.BANK != null && !accMaster.BANK.isEmpty()) {
                        if (sapCodeToIdMap.containsKey(accMaster.CUSTOMER_NO)) {
                            accountBankDetailsMap.put(accMaster.CUSTOMER_NO, prepareBankDetails(accMaster.BANK, acc));
                        }
                    }
                    
                    // Process Sales Areas
                    if (accMaster.SALES_AREA != null && !accMaster.SALES_AREA.isEmpty()) {
                        if (sapCodeToIdMap.containsKey(accMaster.CUSTOMER_NO)) {
                            accountSalesAreasMap.put(accMaster.CUSTOMER_NO, prepareSalesAreas(accMaster.SALES_AREA, acc));
                        }
                    }
                }

                // Process contacts
                processAllContacts(successAccounts, accountContactsMap, response);
                
                // Process bank details
                processAllBankDetails(successAccounts, accountBankDetailsMap, response);
                
                // Process sales areas
                processAllSalesAreas(successAccounts, accountSalesAreasMap, response);
            }
            
            // Prepare response data
            if (!response.errors.isEmpty()) {
                response.status = 'fail';
                response.message = 'Something went wrong';
                // response.status = 'partial_success';
                // response.message = 'Completed with some errors';
            }
            
            response.data.put('processedAccounts', successAccounts.size());
            response.data.put('totalAccounts', accountRequests.size());

            apiLog.Status__c = 'Success';
            apiLog.Response__c = JSON.serialize(response);
            res.responseBody = Blob.valueOf(JSON.serialize(response));
            
        } catch (Exception e) {
            Database.rollback(sp);
            apiLog.Exception_Description__c = e.getMessage() + ' : ' + e.getCause() + ' : ' + e.getStackTraceString() + ' at ' + e.getLineNumber();
            apiLog.Status__c = 'Failed';
            response.status = 'error';
            response.message = 'Error processing request';
            // response.errors.add(e.getMessage() + ' at ' + e.getLineNumber());
            response.errors.add(apiLog.Exception_Description__c);
            res.statusCode = 400;
            res.responseBody = Blob.valueOf(JSON.serialize(response));
        } finally {

            insert apiLog;
        }
        
        // return response;
    }
    
    // Prepare contacts for bulk processing
    public static List<Contact> prepareContacts(List<ContactData> contacts, Account acc) {
        List<Contact> contactsToUpsert = new List<Contact>();
        
        for (ContactData conData : contacts) {
            Contact con = new Contact();
            con.AccountId = acc.Id;
            con.FirstName = String.isNotBlank(conData.FIRST_NAME0109) ? conData.FIRST_NAME0109 : '';
            con.LastName = String.isNotBlank(conData.LAST_NAME0110) ? conData.LAST_NAME0110 : 'Contact';
            con.Phone = conData.TELEPHONE_1;
            con.MobilePhone = conData.MOBILE;
            con.Email = conData.EMAIL_ID;
            con.Role_Function__c = conData.ROLE_FUNCTION;
            con.Title = conData.TITLE0114;
            con.Department = conData.DEPARTMENT;
            // con.Email = conData.PERSONALEMAIL;
            // con.DOB__c = Date.valueOf(conData.DOB);
            con.Street_1__c = conData.CONTACT_ADDRESS;
            // con.MailingCity = conData.CONTACT_CITY;
            // con.MailingState = conData.CONTACT_STATE;
            // con.MailingCountry = conData.CONTACT_COUNTRY;
            if (postalCodeMap.containsKey(conData.CONTACT_POSTCODE)) {
                con.Pin_Code__c = postalCodeMap.get(conData.CONTACT_POSTCODE).id;    
            }
            // con.MailingPostalCode = conData.CONTACT_ZIP;

            // In the prepareContacts method, modify the External_Id__c assignment:
            String contactKey = acc.SAP_Customer_Code__c + '-' + conData.EMAIL_ID;
            if (mapContaccTemp.containsKey(contactKey)) {
                con.Id = mapContaccTemp.get(contactKey).Id;
            }
            // Always set External_Id__c, whether it's a new or existing contact
            con.External_Id__c = contactKey;
            
            contactsToUpsert.add(con);
        }
        
        return contactsToUpsert;
    }
    
    // Process all contacts in bulk
    public static void processAllContacts(Map<Id, Account> successAccounts, Map<String, List<Contact>> accountContactsMap, ResponseWrapper response) {
        List<Contact> allContacts = new List<Contact>();
        
        // Collect all contacts for bulk upsert
        for (Account acc : successAccounts.values()) {
            if (accountContactsMap.containsKey(acc.SAP_Customer_Code__c)) {
                allContacts.addAll(accountContactsMap.get(acc.SAP_Customer_Code__c));
            }
        }
        
        if (!allContacts.isEmpty()) {
            Database.UpsertResult[] results = Database.upsert(
                allContacts, 
                Contact.Fields.External_Id__c, 
                false
            );
            
            // Handle results
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    for (Database.Error err : results[i].getErrors()) {
                        response.errors.add('Contact error: ' + err.getMessage() + ' for fields ' + err.getFields());
                    }
                }
            }
        }
    }
    
    // Prepare bank details for bulk processing
    public static List<Bank_Information__c> prepareBankDetails(List<BankData> bankDetails, Account acc) {
        List<Bank_Information__c> bankAccounts = new List<Bank_Information__c>();
        
        for (BankData bankData : bankDetails) {
            // Skip if essential data is missing
            if (String.isBlank(bankData.BANK_ACC_NO) && String.isBlank(bankData.BANKL)) {
                continue;
            }
            
            // Create a unique external ID for the bank account
            String externalId = bankData.CUSTOMER_NO0126 + '-' + bankData.BANK_ACC_NO;
            
            Bank_Information__c bankAccount = new Bank_Information__c();
            if (bankInfoMap.containsKey(externalId)) {
                bankAccount.Id = bankInfoMap.get(externalId).Id;
            }
            bankAccount.Account_Name__c = acc.Id;
            bankAccount.BANK_KEY__c = bankData.BANK_KEY;
            bankAccount.Bank_A_C_No__c = bankData.BANK_ACC_NO;
            bankAccount.Name = bankData.BANKNAME;
            bankAccount.Branch__c = bankData.BANKBRANCH;
            bankAccount.BANKL__c = bankData.BANKL;
            bankAccount.External_Id__c = externalId;
            
            bankAccounts.add(bankAccount);
        }
        
        return bankAccounts;
    }
    
    // Process all bank details in bulk
    public static void processAllBankDetails(Map<Id, Account> successAccounts,
                                           Map<String, List<Bank_Information__c>> accountBankDetailsMap,
                                           ResponseWrapper response) {
        List<Bank_Information__c> allBankAccounts = new List<Bank_Information__c>();
        
        // Collect all bank accounts for bulk upsert
        for (Account acc : successAccounts.values()) {
            if (accountBankDetailsMap.containsKey(acc.SAP_Customer_Code__c)) {
                allBankAccounts.addAll(accountBankDetailsMap.get(acc.SAP_Customer_Code__c));
            }
        }
        
        if (!allBankAccounts.isEmpty()) {
            Database.UpsertResult[] results = Database.upsert(
                allBankAccounts,
                Bank_Information__c.Fields.External_Id__c,
                false
            );
            
            // Handle results
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    for (Database.Error err : results[i].getErrors()) {
                        response.errors.add('Bank Account error: ' + err.getMessage() + 
                                         ' for account: ' + allBankAccounts[i].Bank_A_C_No__c);
                    }
                }
            }
        }
    }
    
    // // Prepare sales areas for bulk processing
    public static List<Customer_Sales_Area__c> prepareSalesAreas(List<SalesArea> salesAreas, Account acc) {
        List<Customer_Sales_Area__c> salesAreasToUpsert = new List<Customer_Sales_Area__c>();
        
        for (SalesArea saData : salesAreas) {
            // Create a unique external ID for the sales area
            String csaKey = acc.SAP_Customer_Code__c + '-' + saData.SALES_ORG + '-' + saData.DISTR_CHL + '-' +saData.DIVISION;
            String externalId = acc.SAP_Customer_Code__c + '-' + saData.SALES_ORG + '-' + saData.DISTR_CHL + '-' + saData.DIVISION;
            
            Customer_Sales_Area__c salesArea = new Customer_Sales_Area__c();
            if (csaMap.containsKey(csaKey)) {
                salesArea.Id = csaMap.get(csaKey).Id;
            } else {
                salesArea.Comapany_Code__c = acc.Id;
                salesArea.Name = saData.SALES_ORG + '/' + saData.DISTR_CHL + '/' + saData.DIVISION;
            }
            if (soMap.containsKey(saData.SALES_ORG)) {
                salesArea.Sales_Organisation__c = soMap.get(saData.SALES_ORG).Id;
            }
            if (dcMap.containsKey(saData.DISTR_CHL)) {
                salesArea.Distribution_Channel__c = dcMap.get(saData.DISTR_CHL).Id;
            }
            if (diMap.containsKey(saData.DIVISION)) {
                salesArea.Division__c = diMap.get(saData.DIVISION).Id;
            }
            if (cmMap.containsKey(saData.COCODE)) {
                salesArea.Company__c = cmMap.get(saData.COCODE).Id;
            }
            salesArea.Incoterm_2__c = saData.INCOTERMS;
            salesArea.Incoterm_1__c = saData.INCO_TERM_1_C;
            salesArea.Incoterm_3__c = saData.INCOTERMS2;
            salesArea.Customer_Code__c = acc.SAP_Customer_Code__c;
            // salesArea.Delivery_Plant__c = saData.DELIVERY_PLANT;
            salesArea.Payment_Term_Code__c = saData.PAYT_TERMS;
            if (ptMap.containsKey(saData.PAYT_TERMS)) {
                salesArea.Payment_Term__c = ptMap.get(saData.PAYT_TERMS).Id;
            }
            // salesArea.Payment_Terms__c = saData.PAYT_TERMS;
            salesArea.Sales_District_Code__c = saData.SALES_DISTRICT;
            if (sdMap.containsKey(saData.SALES_DISTRICT)) {
                salesArea.Sales_District__c = sdMap.get(saData.SALES_DISTRICT).Id;
            }
            // salesArea.Sales_Office_Code__c = saData.SALES_OFF;
            // salesArea.Sales_Office__c = saData.SALES_OFFICE_C;
            // salesArea.Sales_Group_Code__c = saData.SALES_GRP;
            // salesArea.Sales_Group__c = saData.SALES_GROUP_C;
            salesArea.Customer_Group__c = saData.CUSTGROUP;
            salesArea.Customer_Price_Group__c = saData.CUST_PRICE_GROUP_C;
            // salesArea.ABC_Classification__c = saData.ABC_CLASS;
            salesArea.Price_Group__c = saData.PRICE_GROUP_C;
            salesArea.Price_Group_Code__c = saData.PRICEGRP;
            // salesArea.Pricelist__c = saData.PRICE_LIST;
            salesArea.Price_List__c = saData.PRICE_LIST;
            salesArea.Cust_Stat_Gr__c = saData.CUSTSTATGR;
            salesArea.INVOIC_DAT__c = saData.INVOIC_DAT;
            salesArea.INVLISTSCH__c = saData.INVLISTSCH;
            if (String.isNotBlank(saData.CRED_LIMIT)) {
                String cl = saData.CRED_LIMIT.replace(',', '');
                cl = cl.replace(' ', '');
                salesArea.Credit_Limit__c = String.isNotBlank(saData.CRED_LIMIT) ? Decimal.valueOf(cl) : null;
            }
            salesArea.CurrencyIsoCode = String.isNotBlank(saData.CURR) ? saData.CURR : 'INR';

            salesArea.External_Id__c = externalId;
            
            salesAreasToUpsert.add(salesArea);
        }
        
        return salesAreasToUpsert;
    }
    
    // Process all sales areas in bulk
    public static void processAllSalesAreas(Map<Id, Account> successAccounts, Map<String, List<Customer_Sales_Area__c>> accountSalesAreasMap, ResponseWrapper response) {
        List<Customer_Sales_Area__c> allSalesAreas = new List<Customer_Sales_Area__c>();
        Map<String, List<PartnerFunction>> salesAreaPartnerFunctions = new Map<String, List<PartnerFunction>>();
        
        // Collect all sales areas for bulk upsert and gather partner functions
        for (Account acc : successAccounts.values()) {
            if (accountSalesAreasMap.containsKey(acc.SAP_Customer_Code__c)) {
                List<Customer_Sales_Area__c> salesAreas = accountSalesAreasMap.get(acc.SAP_Customer_Code__c);
                allSalesAreas.addAll(salesAreas);
                
                // Store partner functions for processing after sales area upsert
                for (AccountMasterRequest accMaster : accountRequests) {
                    for (SalesArea sa : accMaster.SALES_AREA) {
                        String csaKey = accMaster.CUSTOMER_NO + '-' + sa.SALES_ORG + '-' + sa.DISTR_CHL + '-' +sa.DIVISION;
                        salesAreaPartnerFunctions.put(csaKey, sa.PARTNER_FUNCTIONS);
                        System.debug('csaKey::> ' +csaKey);
                        // for (PartnerFunction pf : sa.PARTNER_FUNCTIONS) {
                        //     String csaKey = accMaster.CUSTOMER_NO + '-' + sa.SALES_ORG + '-' + sa.DISTR_CHL + '-' +sa.DIVISION + '-' +pf.PARTNERFN;
                        //     salesAreaPartnerFunctions.put(csaKey, sa.PARTNER_FUNCTIONS);
                        // }
                    }
                }
            }
        }
        
        if (!allSalesAreas.isEmpty()) {
            // First upsert sales areas
            Database.UpsertResult[] results = Database.upsert(
                allSalesAreas,
                Customer_Sales_Area__c.Fields.External_Id__c,
                false
            );
            
            // Handle results and collect successful sales area IDs
            Map<String, Id> salesAreaMap = new Map<String, Id>();
            Set<String> salesAreaIdSet = new Set<String>();
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    for (Database.Error err : results[i].getErrors()) {
                        response.errors.add('Customer Sales Area error: ' + err.getMessage() + ' for sales org: ' + allSalesAreas[i].Sales_Organisation__r.Name);
                    }
                } else {
                    salesAreaMap.put(allSalesAreas[i].External_Id__c, allSalesAreas[i].Id);
                    salesAreaIdSet.add(allSalesAreas[i].Id);
                    System.debug('Processed Sales Area: ' + allSalesAreas[i]);
                }
            }

            // Get all partner functions for the successfully upserted sales areas
            List<Partner_Function__c> partnerFunctions = [
                SELECT Id, PARTNERFN__c, Customer_Sales_Area__c, Customer_Sales_Area__r.External_Id__c, External_Id__c,
                Partner_code__c, Name, TXT_SALES_ORG0079__c, TXT_DISTR_CHANN__c, TXT_DIVISION0081__c
                FROM Partner_Function__c
                WHERE Customer_Sales_Area__c IN :salesAreaIdSet
            ];

            Map<String, Partner_Function__c> pfMap = new Map<String, Partner_Function__c>();
            for (Partner_Function__c pf : partnerFunctions) {
                // String pfKey = pf.Customer_Sales_Area__r.External_Id__c + pf.PARTNERFN__c;
                // String pfKey = pf.External_Id__c;
                String pfKey = pf.Partner_code__c+'-'+pf.Name+'-'+pf.TXT_SALES_ORG0079__c+'-'+pf.TXT_DISTR_CHANN__c+'-'+pf.TXT_DIVISION0081__c;
                System.debug('pfKey: ' + pfKey);
                pfmap.put(pfKey, pf);
            }

            List < Account > accountList = new List < Account > ();
            accountList = [SELECT Id, Name, SAP_Customer_Code__c FROM Account WHERE SAP_Customer_Code__c IN: custNumberSet];

            for (Account va: accountList) {
                accountMap.put(va.SAP_Customer_Code__c, va);
            }

            
            // Process partner functions for successfully upserted sales areas
            if (!salesAreaMap.isEmpty() && !salesAreaPartnerFunctions.isEmpty()) {
                List<Partner_Function__c> partnerFunctionsToUpsert = new List<Partner_Function__c>();
                
                // Prepare partner functions for upsert
                for (String salesAreaExtId : salesAreaMap.keySet()) {
                    if (salesAreaPartnerFunctions.containsKey(salesAreaExtId)) {
                        for (PartnerFunction pf : salesAreaPartnerFunctions.get(salesAreaExtId)) {
                            System.debug('salesAreaExtId: ' + salesAreaExtId+pf.PARTNERFN);
                            // Set the lookup to the parent sales area
                            Partner_Function__c partnerFn = new Partner_Function__c();
                            if (pfmap.containsKey(pf.CUSTOMR_NO+'-'+pf.PARTNERFN+'-'+pf.SALES_ORG0079+'-'+pf.DISTR_CHANN+'-'+pf.DIVISION0081)) {
                                partnerFn.Id = pfmap.get(pf.CUSTOMR_NO+'-'+pf.PARTNERFN+'-'+pf.SALES_ORG0079+'-'+pf.DISTR_CHANN+'-'+pf.DIVISION0081).Id;
                            }
                            // partnerFn.Account__c = sapCodeToIdMap.get(pf.CUSTOMR_NO);
                            if (accountMap.containsKey(pf.CUSTOMR_NO)) {
                                partnerFn.Account__c = accountMap.get(pf.CUSTOMR_NO).id;    
                            }
                            partnerFn.Partner_code__c = pf.CUSTOMR_NO;
                            partnerFn.Name = pf.CUSTOMR_NO+'/'+pf.PARTNERFN;
                            partnerFn.PARTNERFN__c = pf.PARTNERFN;
                            partnerFn.PARTNER_FUNC__c = pf.PARTNER_FUNC;
                            partnerFn.TITLE0070__c = pf.TITLE0070;
                            partnerFn.Customer_Sales_Area__c = salesAreaMap.get(salesAreaExtId);
                            partnerFn.CUSTOMER_NAME__c = pf.NAME;
                            partnerFn.FIRST_NAME0088__c = pf.FIRST_NAME0088;
                            partnerFn.LAST_NAME0089__c = pf.LAST_NAME0089;
                            partnerFn.NAME2__c = pf.NAME2;
                            partnerFn.NAME3__c = pf.NAME3;
                            partnerFn.TXT_CITY0072__c = pf.CITY0072;
                            partnerFn.TXT_COUNTRY0073__c = pf.COUNTRY0073;
                            partnerFn.TXT_REGION0074__c = pf.REGION0074;
                            partnerFn.TXT_POST_CODE0075__c = pf.POST_CODE0075;
                            partnerFn.TXT_SALES_ORG0079__c = pf.SALES_ORG0079;
                            partnerFn.TXT_DISTR_CHANN__c = pf.DISTR_CHANN;
                            partnerFn.TXT_DIVISION0081__c = pf.DIVISION0081;
                            partnerFn.TXT_CITY1__c = pf.CITY1;
                            partnerFn.TXT_POSTL_CODE__c = pf.POSTL_CODE;
                            partnerFn.TXT_DISTRICT__c = pf.DISTRICT;
                            partnerFn.TXT_STATE__c = pf.STATE;
                            partnerFn.TXT_COUNTRY0097__c = pf.COUNTRY0097;
                            partnerFn.TXT_TAX_CLASS0099__c = pf.TAX_CLASS0099;
                            partnerFn.TXT_REGION0074__c = pf.REGION0074;
                            partnerFn.TXT_REGION0096__c = pf.REGION0096;
                            partnerFn.External_Id__c = pf.CUSTOMR_NO+'-'+pf.PARTNERFN+'-'+pf.SALES_ORG0079+'-'+pf.DISTR_CHANN+'-'+pf.DIVISION0081;
                            partnerFunctionsToUpsert.add(partnerFn);
                        }
                    }
                }
                
                // Upsert partner functions
                if (!partnerFunctionsToUpsert.isEmpty()) {
                    Database.UpsertResult[] pfResults = Database.upsert(
                        partnerFunctionsToUpsert,
                        Partner_Function__c.Fields.External_Id__c,
                        false
                    );
                    
                    // Handle partner function upsert results
                    for (Integer i = 0; i < pfResults.size(); i++) {
                        if (!pfResults[i].isSuccess()) {
                            for (Database.Error err : pfResults[i].getErrors()) {
                                response.errors.add('Partner Function error: ' + err.getMessage() + ' for partner function: ' + partnerFunctionsToUpsert[i].PARTNERFN__c);
                            }
                        }
                    }
                }
            }
        }
    }
    
    // private static void processSalesAreas(List<SalesArea> salesAreas, Account acc, ResponseWrapper response) {
    //     try {
    //         List<Customer_Sales_Area__c> salesAreasToUpsert = new List<Customer_Sales_Area__c>();
    //         List<Partner_Function__c> partnerFunctionsToUpsert = new List<Partner_Function__c>();
            
    //         // Get existing sales areas for this account to avoid duplicates
    //         Map<String, Customer_Sales_Area__c> existingSalesAreas = new Map<String, Customer_Sales_Area__c>();
    //         for (Customer_Sales_Area__c sa : [SELECT Id, External_Id__c, Account__c, Sales_Org__c, 
    //                                 Distribution_Channel__c, Division__c 
    //                                 FROM Customer_Sales_Area__c 
    //                                 WHERE Account__c = :acc.Id]) {
    //             existingSalesAreas.put(sa.External_Id__c, sa);
    //         }
            
    //         // Process each sales area from the request
    //         for (SalesArea saData : salesAreas) {
    //             // Create a unique external ID for the sales area
    //             String externalId = acc.SAP_Customer_Code__c + '-' + saData.SALES_ORG + '-' + 
    //                              saData.DISTR_CHL + '-' + saData.DIVISION;
                
    //             // Create or update sales area record
    //             Customer_Sales_Area__c salesArea = existingSalesAreas.containsKey(externalId) ? 
    //                 existingSalesAreas.get(externalId) : new Customer_Sales_Area__c();
                
    //             // Map fields from request to Customer_Sales_Area__c object
    //             salesArea.Account__c = acc.Id;
    //             salesArea.External_Id__c = externalId;
    //             salesArea.Company_Code__c = saData.COCODE;
    //             salesArea.Sales_Org__c = saData.SALES_ORG;
    //             salesArea.Distribution_Channel__c = saData.DISTR_CHL;
    //             salesArea.Division__c = saData.DIVISION;
    //             salesArea.Incoterms__c = saData.INCOTERMS;
    //             salesArea.Incoterms_Text__c = saData.INCO_TERM_1_C;
    //             salesArea.Delivery_Plant__c = saData.DELIVERY_PLANT;
    //             salesArea.Payment_Terms__c = saData.PAYT_TERMS;
    //             salesArea.Terms_Of_Payment__c = saData.TERMS_OF_PAYMENT_C;
    //             salesArea.Sales_District_Code__c = saData.SALES_DISTRICT;
    //             salesArea.Sales_District__c = saData.SALES_DISTRICT_C;
    //             salesArea.Sales_Office_Code__c = saData.SALES_OFF;
    //             salesArea.Sales_Office__c = saData.SALES_OFFICE_C;
    //             salesArea.Sales_Group_Code__c = saData.SALES_GRP;
    //             salesArea.Sales_Group__c = saData.SALES_GROUP_C;
    //             salesArea.Customer_Group__c = saData.CUSTGROUP;
    //             salesArea.Customer_Price_Group__c = saData.CUST_PRICE_GROUP_C;
    //             salesArea.ABC_Classification__c = saData.ABC_CLASS;
    //             salesArea.Price_Group_Code__c = saData.PRICEGRP;
    //             salesArea.Price_Group__c = saData.PRICE_GROUP_C;
    //             salesArea.Price_List_Type__c = saData.PRICE_LIST;
    //             salesArea.Customer_Statistics_Group__c = saData.CUSTSTATGR;
    //             salesArea.Invoice_Date_Type__c = saData.INVOIC_DAT;
    //             salesArea.Invoice_List_Schedule__c = saData.INVLISTSCH;
                
    //             salesAreasToUpsert.add(salesArea);
                
    //             // Process partner functions if they exist
    //             if (saData.PARTNER_FUNCTIONS != null && !saData.PARTNER_FUNCTIONS.isEmpty()) {
    //                 processPartnerFunctions(saData.PARTNER_FUNCTIONS, acc, salesArea, partnerFunctionsToUpsert, response);
    //             }
    //         }
            
    //         // Upsert sales areas
    //         if (!salesAreasToUpsert.isEmpty()) {
    //             Database.UpsertResult[] salesAreaResults = Database.upsert(salesAreasToUpsert, 
    //                 Customer_Sales_Area__c.Fields.External_Id__c, false);
                
    //             // Handle any errors from sales area upsert
    //             for (Integer i = 0; i < salesAreaResults.size(); i++) {
    //                 Database.UpsertResult sr = salesAreaResults[i];
    //                 if (!sr.isSuccess()) {
    //                     String errorMsg = 'Sales Area error for ' + salesAreas[i].SALES_ORG + 
    //                                    '-' + salesAreas[i].DISTR_CHL + '-' + salesAreas[i].DIVISION + ': ';
    //                     for (Database.Error err : sr.getErrors()) {
    //                         errorMsg += err.getMessage() + '; ';
    //                     }
    //                     response.errorMessages.add(errorMsg);
    //                 }
    //             }
    //         }
            
    //         // Upsert partner functions
    //         if (!partnerFunctionsToUpsert.isEmpty()) {
    //             Database.UpsertResult[] pfResults = Database.upsert(partnerFunctionsToUpsert, 
    //                 Partner_Function__c.Fields.External_Id__c, false);
                
    //             // Handle any errors from partner function upsert
    //             for (Integer i = 0; i < pfResults.size(); i++) {
    //                 Database.UpsertResult sr = pfResults[i];
    //                 if (!sr.isSuccess()) {
    //                     String errorMsg = 'Partner Function error: ';
    //                     for (Database.Error err : sr.getErrors()) {
    //                         errorMsg += err.getMessage() + '; ';
    //                     }
    //                     response.errorMessages.add(errorMsg);
    //                 }
    //             }
    //         }
            
    //     } catch (Exception e) {
    //         response.errorMessages.add('Error processing sales areas: ' + e.getMessage() + 
    //                                 ' at line ' + e.getLineNumber());
    //         throw e;
    //     }
    // }
    
    // private static void processPartnerFunctions(List<PartnerFunction> partnerFunctions, 
    //                                          Account acc, Customer_Sales_Area__c salesArea,
    //                                          List<Partner_Function__c> partnerFunctionsToUpsert,
    //                                          ResponseWrapper response) {
    //     // Get existing partner functions for this sales area to avoid duplicates
    //     Map<String, Partner_Function__c> existingPartnerFuncs = new Map<String, Partner_Function__c>();
    //     if (salesArea.Id != null) {
    //         for (Partner_Function__c pf : [SELECT Id, External_Id__c, Partner_Function_Code__c 
    //                                      FROM Partner_Function__c 
    //                                      WHERE Customer_Sales_Area__c = :salesArea.Id]) {
    //             existingPartnerFuncs.put(pf.External_Id__c, pf);
    //         }
    //     }
        
    //     // Process each partner function
    //     for (PartnerFunction pfData : partnerFunctions) {
    //         // Create a unique external ID for the partner function
    //         String externalId = acc.SAP_Customer_Code__c + '-' + salesArea.Sales_Org__c + '-' + 
    //                          salesArea.Distribution_Channel__c + '-' + salesArea.Division__c + '-' + 
    //                          pfData.PARTNERFN;
            
    //         // Create or update partner function record
    //         Partner_Function__c pf = existingPartnerFuncs.containsKey(externalId) ? 
    //             existingPartnerFuncs.get(externalId) : new Partner_Function__c();
            
    //         // Map fields from request to Partner_Function__c object
    //         pf.Customer_Sales_Area__c = salesArea.Id;
    //         pf.External_Id__c = externalId;
    //         pf.Partner_Function_Code__c = pfData.PARTNERFN;
    //         pf.Partner_Function_Description__c = pfData.PARTNER_FUNC;
    //         pf.Title__c = pfData.TITLE0070;
    //         pf.Title_Description__c = pfData.TITLE_C0071;
    //         pf.City__c = pfData.CITY0072;
    //         pf.Country__c = pfData.COUNTRY0073;
    //         pf.Region_Code__c = pfData.REGION0074;
    //         pf.Postal_Code__c = pfData.POST_CODE0075;
    //         pf.SAP_Customer_Code__c = pfData.CUSTOMR_NO;
    //         pf.Sales_Org_Code__c = pfData.SALES_ORG0079;
    //         pf.Distribution_Channel_Code__c = pfData.DISTR_CHANN;
    //         pf.Division_Code__c = pfData.DIVISION0081;
    //         pf.Name = pfData.NAME;
    //         pf.First_Name__c = pfData.FIRST_NAME0088;
    //         pf.Last_Name__c = pfData.LAST_NAME0089;
    //         pf.Name_2__c = pfData.NAME2;
    //         pf.Name_3__c = pfData.NAME3;
    //         pf.City_2__c = pfData.CITY1;
    //         pf.Postal_Code_2__c = pfData.POSTL_CODE;
    //         pf.District__c = pfData.DISTRICT;
    //         pf.State__c = pfData.STATE;
    //         pf.Region_Code_2__c = pfData.REGION0096;
    //         pf.Country_2__c = pfData.COUNTRY0097;
    //         pf.Tax_Classification__c = pfData.TAX_CLASS0099;
            
    //         partnerFunctionsToUpsert.add(pf);
    //     }
    // }

    global class AccountMasterRequest {
        public String SFDC_ID;
        public String CUSTOMER_NO;
        public String Account_ID;
        public String CUST_ACCT_GROUP;
        public String ACCOUNT_GROUP_C;
        public String TITLE;
        public String CUST_NAME;
        public String ADDRESS;
        public String C_TELEPHONE1;
        public String C_TELEPHONE2;
        public String EMAIL1;
        public String EMAIL2;
        public String EMAIL3;
        public String EMAIL4;
        public String EMAIL5;
        public String C_STREET;
        public String STREET2;
        public String STREET;
        public String HOUSE_NO;
        public String POST_CODE;
        public String CITY;
        public String COUNTRY;
        public String REGION;
        public String CURRNCY;
        public String PAN_NO;
        public String MOBILE_NO;
        public String TAXNO3;
        public String TAX_CLASS;
        public String GST_TYPE_C;
        public String CRED_LIMIT;
        public String INDUSTRY;
        public String INDUSTRY_C;
        public String RECON_ACCT;
        public String RECON_ACCOUNT;
        public String EXRATETYPE;
        public String EXCH_RATE_TYPE_C;
        public List<SalesArea> SALES_AREA;
        public List<ContactData> CONTACT;
        public List<BankData> BANK;
    }
    
    public class SalesArea {
        public String COCODE;
        public String SALES_ORG;
        public String DISTR_CHL;
        public String DIVISION;
        public String INCOTERMS;
        public String INCO_TERM_1_C;
        public String INCOTERMS2;
        public String DELIVERY_PLANT;
        public String PAYT_TERMS;
        public String TERMS_OF_PAYMENT_C;
        public String SALES_DISTRICT;
        public String SALES_DISTRICT_C;
        public String SALES_OFF;
        public String SALES_OFFICE_C;
        public String SALES_GRP;
        public String SALES_GROUP_C;
        public String CUSTGROUP;
        public String CUST_PRICE_GROUP_C;
        public String ABC_CLASS;
        public String PRICEGRP;
        public String PRICE_GROUP_C;
        public String PRICE_LIST;
        public String CUSTSTATGR;
        public String INVOIC_DAT;
        public String INVLISTSCH;
        public String CRED_LIMIT;
        public String CURR;
        public List<PartnerFunction> PARTNER_FUNCTIONS;
    }
    
    public class PartnerFunction {
        public String PARTNERFN;
        public String PARTNER_FUNC;
        public String TITLE0070;
        public String TITLE_C0071;
        public String CITY0072;
        public String COUNTRY0073;
        public String REGION0074;
        public String POST_CODE0075;
        public String CUSTOMR_NO;
        public String SALES_ORG0079;
        public String DISTR_CHANN;
        public String DIVISION0081;
        public String NAME;
        public String FIRST_NAME0088;
        public String LAST_NAME0089;
        public String NAME2;
        public String NAME3;
        public String CITY1;
        public String POSTL_CODE;
        public String DISTRICT;
        public String STATE;
        public String REGION0096;
        public String COUNTRY0097;
        public String TAX_CLASS0099;
    }
    
    public class ContactData {
        public String CUSTOMER_NO0103;
        public String FIRST_NAME0109;
        public String LAST_NAME0110;
        public String MOBILE;
        public String EMAIL_ID;
        public String ROLE_FUNCTION;
        public String TITLE0114;
        public String DEPARTMENT;
        public String TELEPHONE_1;
        public String PERSONALEMAIL;
        public String DOB;
        public String CONTACT_ADDRESS;
        public String CONTACT_CITY;
        public String CONTACT_STATE;
        public String CONTACT_COUNTRY;
        public String CONTACT_ZIP;
        public String CONTACT_POSTCODE;
    }
    
    public class BankData {
        public String CUSTOMER_NO0126;
        public String BANK_KEY;
        public String BANKL;
        public String BANKNAME;
        public String BANKBRANCH;
        public String BANK_ACC_NO;
    }
    
    global class ResponseWrapper {
        public String status;  // 'success' or 'error'
        public String message;
        public Map<String, Object> data;
        public List<String> errors;
        
        public ResponseWrapper() {
            this.status = 'success';
            this.message = 'Customer Upsert successfully';
            this.data = new Map<String, Object>();
            this.errors = new List<String>();
        }
    }

}