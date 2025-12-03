public with sharing class ExpenseController {
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> initializeExpense() {
        Map<String, Object> result = new Map<String, Object>();
        try {
            // Get current user with Grade field
            User currentUser = [SELECT Id, Name, Division, Zone__c, Cost_Center__c, Grades__c 
                               FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            
            List<Map<String, String>> voucherOptions = new List<Map<String, String>>();
            for (Schema.PicklistEntry entry : Expense__c.Type_of_Voucher__c.getDescribe().getPicklistValues()) {
                if (entry.isActive()) {
                    voucherOptions.add(new Map<String, String>{
                        'label' => entry.getLabel(),
                        'value' => entry.getValue()
                    });
                }
            }
            
            // Get Cost Center record ID
            Id costCenterId = null;
            if (String.isNotBlank(currentUser.Cost_Center__c)) {
                List<Cost_Center__c> costCenters = [SELECT Id FROM Cost_Center__c 
                                                   WHERE Name = :currentUser.Cost_Center__c 
                                                   LIMIT 1];
                if (!costCenters.isEmpty()) {
                    costCenterId = costCenters[0].Id;
                }
            }
            
            // Get Grade details based on user's grade - without sales type for initial load
            Decimal dailyAllowance = 0;
            Decimal fourWheelerPerKm = 0;
            Decimal twoWheelerPerKm = 0;
            Decimal specialAllowance = 0;
            Decimal outOfPocket = 0;
            Decimal lodgingHotel = 0;
            Decimal boardingFood = 0;
            Decimal lodgingHotelBClass = 0;
            Decimal boardingFoodBClass = 0;
            List<String> modeOfTravelOptions = new List<String>();
            List<String> modeOfOutstationTravelOptions = new List<String>();
            Boolean canEditDailyAllowance = false;
            
            System.debug('User Grade: ' + currentUser.Grades__c);
            
            if (String.isNotBlank(currentUser.Grades__c)) {
                List<Grade__c> grades = [SELECT Id, Name, Daily_Allowance_A_class_cities__c, 
                                        Daily_Allowance_B_class_cities__c, Four_Wheeler_per_km__c, 
                                        Two_Wheeler_per_km__c, Mode_of_Travel__c, Sales_Type__c,
                                        Special_Allowance__c, Out_of_Pocket__c, Mode_of_Outstation_Travel__c,
                                        Lodging_Hotel__c, Boarding_Food__c, Lodging_Hotel_B_Class__c, Boarding_Food_B_Class__c
                                        FROM Grade__c 
                                        WHERE Name = :currentUser.Grades__c 
                                        LIMIT 1];
                
                System.debug('Found grades: ' + grades.size());
                
                if (!grades.isEmpty()) {
                    Grade__c userGrade = grades[0];
                    dailyAllowance = userGrade.Daily_Allowance_A_class_cities__c != null ? userGrade.Daily_Allowance_A_class_cities__c : 0;
                    fourWheelerPerKm = userGrade.Four_Wheeler_per_km__c != null ? userGrade.Four_Wheeler_per_km__c : 0;
                    twoWheelerPerKm = userGrade.Two_Wheeler_per_km__c != null ? userGrade.Two_Wheeler_per_km__c : 0;
                    specialAllowance = userGrade.Special_Allowance__c != null ? userGrade.Special_Allowance__c : 0;
                    outOfPocket = userGrade.Out_of_Pocket__c != null ? userGrade.Out_of_Pocket__c : 0;
                    lodgingHotel = userGrade.Lodging_Hotel__c != null ? userGrade.Lodging_Hotel__c : 0;
                    boardingFood = userGrade.Boarding_Food__c != null ? userGrade.Boarding_Food__c : 0;
                    lodgingHotelBClass = userGrade.Lodging_Hotel_B_Class__c != null ? userGrade.Lodging_Hotel_B_Class__c : 0;
                    boardingFoodBClass = userGrade.Boarding_Food_B_Class__c != null ? userGrade.Boarding_Food_B_Class__c : 0;
                    
                    System.debug('Grade Details - DA: ' + dailyAllowance + ', 4W: ' + fourWheelerPerKm + ', 2W: ' + twoWheelerPerKm);
                    System.debug('Special Allowance: ' + specialAllowance + ', Out of Pocket: ' + outOfPocket);
                    System.debug('Lodging Hotel: ' + lodgingHotel + ', Boarding Food: ' + boardingFood);
                    System.debug('Lodging Hotel B Class: ' + lodgingHotelBClass + ', Boarding Food B Class: ' + boardingFoodBClass);
                    
                    // Parse multi-picklist values for Mode_of_Travel__c
                    if (String.isNotBlank(userGrade.Mode_of_Travel__c)) {
                        modeOfTravelOptions = userGrade.Mode_of_Travel__c.split(';');
                        System.debug('Mode of Travel Options: ' + modeOfTravelOptions);
                    }
                    
                    // Parse multi-picklist values for Mode_of_Outstation_Travel__c
                    if (String.isNotBlank(userGrade.Mode_of_Outstation_Travel__c)) {
                        modeOfOutstationTravelOptions = userGrade.Mode_of_Outstation_Travel__c.split(';');
                        System.debug('Mode of Outstation Travel Options: ' + modeOfOutstationTravelOptions);
                    }
                    
                    // Check if user can edit daily allowance (only for DR or EM grades)
                    canEditDailyAllowance = (currentUser.Grades__c == 'DR' || currentUser.Grades__c == 'EM');
                }
            }
            
            result.put('currentUser', currentUser);
            result.put('voucherOptions', voucherOptions);
            result.put('costCenterId', costCenterId);
            result.put('dailyAllowance', dailyAllowance);
            result.put('fourWheelerPerKm', fourWheelerPerKm);
            result.put('twoWheelerPerKm', twoWheelerPerKm);
            result.put('specialAllowance', specialAllowance);
            result.put('outOfPocket', outOfPocket);
            result.put('lodgingHotel', lodgingHotel);
            result.put('boardingFood', boardingFood);
            result.put('lodgingHotelBClass', lodgingHotelBClass);
            result.put('boardingFoodBClass', boardingFoodBClass);
            result.put('modeOfTravelOptions', modeOfTravelOptions);
            result.put('modeOfOutstationTravelOptions', modeOfOutstationTravelOptions);
            result.put('canEditDailyAllowance', canEditDailyAllowance);
            
        } catch (Exception e) {
            System.debug('Error in initializeExpense: ' + e.getMessage() + ' - ' + e.getStackTraceString());
            throw new AuraHandledException('Error initializing expense: ' + e.getMessage());
        }
        return result;
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getGradeDetailsWithSalesType(String gradeName, String salesType) {
        try {
            Map<String, Object> result = new Map<String, Object>();
            
            System.debug('getGradeDetailsWithSalesType called with grade: ' + gradeName + ', salesType: ' + salesType);
            
            if (String.isBlank(gradeName)) {
                return result;
            }
            
            // Query Grade__c with both Name and Sales_Type__c
            List<Grade__c> grades = [SELECT Id, Name, Daily_Allowance_A_class_cities__c, 
                                    Daily_Allowance_B_class_cities__c, Four_Wheeler_per_km__c, 
                                    Two_Wheeler_per_km__c, Mode_of_Travel__c, Sales_Type__c,
                                    Special_Allowance__c, Out_of_Pocket__c, Mode_of_Outstation_Travel__c,
                                    Lodging_Hotel__c, Boarding_Food__c, Lodging_Hotel_B_Class__c, Boarding_Food_B_Class__c
                                    FROM Grade__c 
                                    WHERE Name = :gradeName 
                                    AND Sales_Type__c = :salesType
                                    LIMIT 1];
            
            System.debug('Found grades for ' + gradeName + ' with sales type ' + salesType + ': ' + grades.size());
            
            if (!grades.isEmpty()) {
                Grade__c grade = grades[0];
                result.put('dailyAllowance', grade.Daily_Allowance_A_class_cities__c != null ? grade.Daily_Allowance_A_class_cities__c : 0);
                result.put('dailyAllowanceBClass', grade.Daily_Allowance_B_class_cities__c != null ? grade.Daily_Allowance_B_class_cities__c : 0);
                result.put('fourWheelerPerKm', grade.Four_Wheeler_per_km__c != null ? grade.Four_Wheeler_per_km__c : 0);
                result.put('twoWheelerPerKm', grade.Two_Wheeler_per_km__c != null ? grade.Two_Wheeler_per_km__c : 0);
                result.put('specialAllowance', grade.Special_Allowance__c != null ? grade.Special_Allowance__c : 0);
                result.put('outOfPocket', grade.Out_of_Pocket__c != null ? grade.Out_of_Pocket__c : 0);
                result.put('lodgingHotel', grade.Lodging_Hotel__c != null ? grade.Lodging_Hotel__c : 0);
                result.put('boardingFood', grade.Boarding_Food__c != null ? grade.Boarding_Food__c : 0);
                result.put('lodgingHotelBClass', grade.Lodging_Hotel_B_Class__c != null ? grade.Lodging_Hotel_B_Class__c : 0);
                result.put('boardingFoodBClass', grade.Boarding_Food_B_Class__c != null ? grade.Boarding_Food_B_Class__c : 0);
                
                System.debug('Grade details - DA: ' + result.get('dailyAllowance') + 
                           ', 4W: ' + result.get('fourWheelerPerKm') + 
                           ', 2W: ' + result.get('twoWheelerPerKm') +
                           ', Special Allowance: ' + result.get('specialAllowance') +
                           ', Out of Pocket: ' + result.get('outOfPocket') +
                           ', Lodging Hotel: ' + result.get('lodgingHotel') +
                           ', Boarding Food: ' + result.get('boardingFood') +
                           ', Lodging Hotel B Class: ' + result.get('lodgingHotelBClass') +
                           ', Boarding Food B Class: ' + result.get('boardingFoodBClass'));
                
                // Parse multi-picklist values for Mode_of_Travel__c
                List<String> modeOfTravelOptions = new List<String>();
                if (String.isNotBlank(grade.Mode_of_Travel__c)) {
                    modeOfTravelOptions = grade.Mode_of_Travel__c.split(';');
                    System.debug('Mode of Travel Options: ' + modeOfTravelOptions);
                }
                result.put('modeOfTravelOptions', modeOfTravelOptions);
                
                // Parse multi-picklist values for Mode_of_Outstation_Travel__c
                List<String> modeOfOutstationTravelOptions = new List<String>();
                if (String.isNotBlank(grade.Mode_of_Outstation_Travel__c)) {
                    modeOfOutstationTravelOptions = grade.Mode_of_Outstation_Travel__c.split(';');
                    System.debug('Mode of Outstation Travel Options: ' + modeOfOutstationTravelOptions);
                }
                result.put('modeOfOutstationTravelOptions', modeOfOutstationTravelOptions);
                
                // Check if grade can edit daily allowance
                Boolean canEditDailyAllowance = (gradeName == 'DR' || gradeName == 'EM');
                result.put('canEditDailyAllowance', canEditDailyAllowance);
                
                result.put('success', true);
            } else {
                // If no grade found with sales type, try with just grade name
                List<Grade__c> fallbackGrades = [SELECT Id, Name, Daily_Allowance_A_class_cities__c, 
                                                Daily_Allowance_B_class_cities__c, Four_Wheeler_per_km__c, 
                                                Two_Wheeler_per_km__c, Mode_of_Travel__c, Sales_Type__c,
                                                Special_Allowance__c, Out_of_Pocket__c, Mode_of_Outstation_Travel__c,
                                                Lodging_Hotel__c, Boarding_Food__c, Lodging_Hotel_B_Class__c, Boarding_Food_B_Class__c
                                                FROM Grade__c 
                                                WHERE Name = :gradeName 
                                                LIMIT 1];
                
                if (!fallbackGrades.isEmpty()) {
                    Grade__c grade = fallbackGrades[0];
                    result.put('dailyAllowance', grade.Daily_Allowance_A_class_cities__c != null ? grade.Daily_Allowance_A_class_cities__c : 0);
                    result.put('dailyAllowanceBClass', grade.Daily_Allowance_B_class_cities__c != null ? grade.Daily_Allowance_B_class_cities__c : 0);
                    result.put('fourWheelerPerKm', grade.Four_Wheeler_per_km__c != null ? grade.Four_Wheeler_per_km__c : 0);
                    result.put('twoWheelerPerKm', grade.Two_Wheeler_per_km__c != null ? grade.Two_Wheeler_per_km__c : 0);
                    result.put('specialAllowance', grade.Special_Allowance__c != null ? grade.Special_Allowance__c : 0);
                    result.put('outOfPocket', grade.Out_of_Pocket__c != null ? grade.Out_of_Pocket__c : 0);
                    result.put('lodgingHotel', grade.Lodging_Hotel__c != null ? grade.Lodging_Hotel__c : 0);
                    result.put('boardingFood', grade.Boarding_Food__c != null ? grade.Boarding_Food__c : 0);
                    result.put('lodgingHotelBClass', grade.Lodging_Hotel_B_Class__c != null ? grade.Lodging_Hotel_B_Class__c : 0);
                    result.put('boardingFoodBClass', grade.Boarding_Food_B_Class__c != null ? grade.Boarding_Food_B_Class__c : 0);
                    
                    // Parse multi-picklist values for Mode_of_Travel__c
                    List<String> modeOfTravelOptions = new List<String>();
                    if (String.isNotBlank(grade.Mode_of_Travel__c)) {
                        modeOfTravelOptions = grade.Mode_of_Travel__c.split(';');
                    }
                    result.put('modeOfTravelOptions', modeOfTravelOptions);
                    
                    // Parse multi-picklist values for Mode_of_Outstation_Travel__c
                    List<String> modeOfOutstationTravelOptions = new List<String>();
                    if (String.isNotBlank(grade.Mode_of_Outstation_Travel__c)) {
                        modeOfOutstationTravelOptions = grade.Mode_of_Outstation_Travel__c.split(';');
                    }
                    result.put('modeOfOutstationTravelOptions', modeOfOutstationTravelOptions);
                    
                    Boolean canEditDailyAllowance = (gradeName == 'DR' || gradeName == 'EM');
                    result.put('canEditDailyAllowance', canEditDailyAllowance);
                    result.put('success', true);
                    result.put('fallback', true);
                } else {
                    result.put('success', false);
                    result.put('message', 'No grade configuration found');
                }
            }
            
            return result;
            
        } catch (Exception e) {
            System.debug('Error in getGradeDetailsWithSalesType: ' + e.getMessage());
            throw new AuraHandledException('Error getting grade details: ' + e.getMessage());
        }
    }

    // NEW METHOD: Get City details with City Type
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getCityDetails(String cityId) {
        try {
            Map<String, Object> result = new Map<String, Object>();
            
            if (String.isBlank(cityId)) {
                return result;
            }
            
            List<City__c> cities = [SELECT Id, Name, City_Type__c FROM City__c WHERE Id = :cityId LIMIT 1];
            
            if (!cities.isEmpty()) {
                City__c city = cities[0];
                result.put('cityId', city.Id);
                result.put('cityName', city.Name);
                result.put('cityType', city.City_Type__c);
                result.put('isAClassCity', city.City_Type__c == 'A Class City');
                result.put('success', true);
            } else {
                result.put('success', false);
                result.put('message', 'City not found');
            }
            
            return result;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error getting city details: ' + e.getMessage());
        }
    }

    // NEW METHOD: Get transport modes for Outstation Export
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getExportTransportModes(String gradeName) {
        try {
            List<Map<String, String>> options = new List<Map<String, String>>();
            
            if (String.isBlank(gradeName)) {
                return options;
            }
            
            // Get Mode_of_Travel__c multi-picklist values from Grade record with Sales_Type__c = 'Export'
            List<Grade__c> grades = [SELECT Id, Mode_of_Travel__c 
                                    FROM Grade__c 
                                    WHERE Name = :gradeName 
                                    AND Sales_Type__c = 'Export'
                                    LIMIT 1];
            
            if (!grades.isEmpty() && String.isNotBlank(grades[0].Mode_of_Travel__c)) {
                List<String> modeValues = grades[0].Mode_of_Travel__c.split(';');
                
                // Convert to combobox format
                for (String mode : modeValues) {
                    options.add(new Map<String, String>{
                        'label' => mode,
                        'value' => mode
                    });
                }
            }
            
            return options;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error getting export transport modes: ' + e.getMessage());
        }
    }

    
    // Add method to get Mode_of_Travel picklist values
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getModeOfTravelOptions() {
        try {
            List<Map<String, String>> options = new List<Map<String, String>>();
            
            // Get picklist values from Mode_of_Travel__c field on Expense_Line_Item__c
            Schema.DescribeFieldResult fieldResult = Expense_Line_Item__c.Mode_of_Travel__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            
            for (Schema.PicklistEntry entry : ple) {
                if (entry.isActive()) {
                    options.add(new Map<String, String>{
                        'label' => entry.getLabel(),
                        'value' => entry.getValue()
                    });
                }
            }
            
            return options;
        } catch (Exception e) {
            throw new AuraHandledException('Error getting mode of travel options: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getGradeDetails(String gradeName) {
        try {
            Map<String, Object> result = new Map<String, Object>();
            
            System.debug('getGradeDetails called with: ' + gradeName);
            
            if (String.isBlank(gradeName)) {
                return result;
            }
            
            List<Grade__c> grades = [SELECT Id, Name, Daily_Allowance_A_class_cities__c, 
                                     Daily_Allowance_B_class_cities__c, Four_Wheeler_per_km__c, 
                                     Two_Wheeler_per_km__c, Mode_of_Travel__c,
                                     Special_Allowance__c, Out_of_Pocket__c,
                                     Lodging_Hotel__c, Boarding_Food__c, Lodging_Hotel_B_Class__c, Boarding_Food_B_Class__c
                                     FROM Grade__c 
                                     WHERE Name = :gradeName 
                                     LIMIT 1];
            
            System.debug('Found grades for ' + gradeName + ': ' + grades.size());
            
            if (!grades.isEmpty()) {
                Grade__c grade = grades[0];
                result.put('dailyAllowance', grade.Daily_Allowance_A_class_cities__c != null ? grade.Daily_Allowance_A_class_cities__c : 0);
                result.put('fourWheelerPerKm', grade.Four_Wheeler_per_km__c != null ? grade.Four_Wheeler_per_km__c : 0);
                result.put('twoWheelerPerKm', grade.Two_Wheeler_per_km__c != null ? grade.Two_Wheeler_per_km__c : 0);
                result.put('specialAllowance', grade.Special_Allowance__c != null ? grade.Special_Allowance__c : 0);
                result.put('outOfPocket', grade.Out_of_Pocket__c != null ? grade.Out_of_Pocket__c : 0);
                result.put('lodgingHotel', grade.Lodging_Hotel__c != null ? grade.Lodging_Hotel__c : 0);
                result.put('boardingFood', grade.Boarding_Food__c != null ? grade.Boarding_Food__c : 0);
                result.put('lodgingHotelBClass', grade.Lodging_Hotel_B_Class__c != null ? grade.Lodging_Hotel_B_Class__c : 0);
                result.put('boardingFoodBClass', grade.Boarding_Food_B_Class__c != null ? grade.Boarding_Food_B_Class__c : 0);
                
                System.debug('Grade details - DA: ' + result.get('dailyAllowance') + 
                             ', 4W: ' + result.get('fourWheelerPerKm') + 
                             ', 2W: ' + result.get('twoWheelerPerKm') +
                             ', Special Allowance: ' + result.get('specialAllowance') +
                             ', Out of Pocket: ' + result.get('outOfPocket'));
                
                // Parse multi-picklist values
                List<String> modeOfTravelOptions = new List<String>();
                if (String.isNotBlank(grade.Mode_of_Travel__c)) {
                    modeOfTravelOptions = grade.Mode_of_Travel__c.split(';');
                    System.debug('Mode of Travel Options: ' + modeOfTravelOptions);
                }
                result.put('modeOfTravelOptions', modeOfTravelOptions);
                
                // Check if grade can edit daily allowance
                Boolean canEditDailyAllowance = (gradeName == 'DR' || gradeName == 'EM');
                result.put('canEditDailyAllowance', canEditDailyAllowance);
            }
            
            return result;
            
        } catch (Exception e) {
            System.debug('Error in getGradeDetails: ' + e.getMessage());
            throw new AuraHandledException('Error getting grade details: ' + e.getMessage());
        }
    }
    
    // Add this new method to get daily allowance by grade name
    @AuraEnabled(cacheable=true)
    public static Decimal getDailyAllowanceByGrade(String gradeName) {
        try {
            System.debug('getDailyAllowanceByGrade called with gradeName: ' + gradeName);
            
            if (String.isBlank(gradeName)) {
                System.debug('Grade name is blank, returning 0');
                return 0;
            }
            
            List<Grade__c> grades = [SELECT Id, Name, Daily_Allowance_A_class_cities__c 
                                    FROM Grade__c 
                                    WHERE Name = :gradeName 
                                    LIMIT 1];
            
            System.debug('Found grades: ' + grades.size());
            
            if (!grades.isEmpty() && grades[0].Daily_Allowance_A_class_cities__c != null) {
                Decimal allowance = grades[0].Daily_Allowance_A_class_cities__c;
                System.debug('Returning daily allowance: ' + allowance);
                return allowance;
            }
            
            System.debug('No grade found or allowance is null, returning 0');
            return 0;
            
        } catch (Exception e) {
            System.debug('Error in getDailyAllowanceByGrade: ' + e.getMessage());
            throw new AuraHandledException('Error getting daily allowance: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getUsers(String searchTerm) {
        try {
            searchTerm = '%' + String.escapeSingleQuotes(searchTerm) + '%';
            List<User> users = [SELECT Id, Name, Division, Zone__c, Cost_Center__c, Grades__c 
                                FROM User 
                                WHERE Name LIKE :searchTerm 
                                AND IsActive = true
                                ORDER BY Name 
                                LIMIT 150];
            
            List<Map<String, String>> options = new List<Map<String, String>>();
            for (User u : users) {
                options.add(new Map<String, String>{
                    'label' => u.Name,
                    'value' => u.Id,
                    'division' => u.Division != null ? u.Division : '',
                    'zone' => u.Zone__c != null ? u.Zone__c : '',
                    'costCenter' => u.Cost_Center__c != null ? u.Cost_Center__c : '',
                    'grade' => u.Grades__c != null ? u.Grades__c : ''
                });
            }
            return options;
        } catch (Exception e) {
            throw new AuraHandledException('Error getting users: ' + e.getMessage());
        }
    }
    
    // Fix the SOQL injection vulnerability in getTypeOfExpense method
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getTypeOfExpense(String searchTerm, String voucherType) {
        try {
            String baseQuery = 'SELECT Id, Name, Type_of_Voucher__c, GL_Code__c, GL_Code__r.Name, Is_Mandatory__c FROM Type_of_Expense__c';
            List<String> conditions = new List<String>();
            
            if (String.isNotBlank(searchTerm)) {
                conditions.add('Name LIKE :searchTerm');
            }
            
            if (String.isNotBlank(voucherType)) {
                conditions.add('Type_of_Voucher__c = :voucherType');
            }
            
            String whereClause = '';
            if (!conditions.isEmpty()) {
                whereClause = ' WHERE ' + String.join(conditions, ' AND ');
            }
            
            String finalQuery = baseQuery + whereClause + ' ORDER BY Name LIMIT 50';
            
            // Use dynamic SOQL with bind variables
            List<Type_of_Expense__c> expenses = Database.query(finalQuery);
            
            List<Map<String, String>> options = new List<Map<String, String>>();
            for (Type_of_Expense__c e : expenses) {
                options.add(new Map<String, String>{
                    'label' => e.Name,
                    'value' => e.Id,
                    'name' => e.Name,
                    'glCodeId' => e.GL_Code__c != null ? e.GL_Code__c : '',
                    'glCodeName' => e.GL_Code__r != null ? e.GL_Code__r.Name : '',
                    'isMandatory' => String.valueOf(e.Is_Mandatory__c)
                });
            }
            return options;
        } catch (Exception e) {
            throw new AuraHandledException('Error getting expense types: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String createExpenseWithFiles(
        Expense__c expense,
        List<Expense_Line_Item__c> lineItems,
        Map<String, List<String>> filesPerLineItem
    ) {
        Savepoint sp = Database.setSavepoint();
        try {
            // Get current user with Entity Code fields
            User currentUser = [SELECT Id, Cost_Center__c, User_Type__c, ManagerId 
                               FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            
            // Determine record type based on Entity Codes
            String recordTypeId = determineRecordType(currentUser);
            if (String.isNotBlank(recordTypeId)) {
                expense.RecordTypeId = recordTypeId;
            }
            
            // Set Cost Center
            if (String.isNotBlank(currentUser.Cost_Center__c)) {
                List<Cost_Center__c> costCenters = [SELECT Id FROM Cost_Center__c 
                                                   WHERE Name = :currentUser.Cost_Center__c 
                                                   LIMIT 1];
                if (!costCenters.isEmpty()) {
                    expense.Cost_Center__c = costCenters[0].Id;
                }
            }
            
            // Set default currency
            if (expense.CurrencyIsoCode == null) {
                expense.CurrencyIsoCode = 'INR';
            }
            
            // Apply user mappings based on business rules
            applyUserMappings(expense, currentUser, recordTypeId);
            
            insert expense;
                        
            // Process line items and GL codes
            Map<Id, Id> expenseTypeToGLCodeMap = new Map<Id, Id>();
            Set<Id> typeOfExpenseIds = new Set<Id>();
            for (Expense_Line_Item__c li : lineItems) {
                if (li.Type_of_Expense__c != null) {
                    typeOfExpenseIds.add(li.Type_of_Expense__c);
                }
            }
            
            if (!typeOfExpenseIds.isEmpty()) {
                for (Type_of_Expense__c et : [
                    SELECT Id, GL_Code__c
                    FROM Type_of_Expense__c
                    WHERE Id IN :typeOfExpenseIds
                ]) {
                    if (et.GL_Code__c != null) {
                        expenseTypeToGLCodeMap.put(et.Id, et.GL_Code__c);
                    }
                }
            }
            
            // Prepare and insert line items
            List<Expense_Line_Item__c> createdItems = new List<Expense_Line_Item__c>();
            for (Expense_Line_Item__c li : lineItems) {
                li.Expense__c = expense.Id;
                
                // Map GL Code from Type_of_Expense__c
                if (li.Type_of_Expense__c != null && expenseTypeToGLCodeMap.containsKey(li.Type_of_Expense__c)) {
                    li.GL_Code__c = expenseTypeToGLCodeMap.get(li.Type_of_Expense__c);
                }
                
                createdItems.add(li);
            }
            
            if (!createdItems.isEmpty()) {
                insert createdItems;
            }
            
            // Process file attachments
            if (filesPerLineItem != null && !filesPerLineItem.isEmpty()) {
                List<ContentDocumentLink> linksToCreate = new List<ContentDocumentLink>();
                
                for (Integer i = 0; i < createdItems.size(); i++) {
                    String indexKey = String.valueOf(i);
                    if (filesPerLineItem.containsKey(indexKey)) {
                        List<String> documentIds = filesPerLineItem.get(indexKey);
                        
                        for (String docId : documentIds) {
                            if (String.isNotBlank(docId)) {
                                ContentDocumentLink newLink = new ContentDocumentLink();
                                newLink.ContentDocumentId = docId;
                                newLink.LinkedEntityId = createdItems[i].Id;
                                newLink.ShareType = 'V';
                                newLink.Visibility = 'AllUsers';
                                
                                linksToCreate.add(newLink);
                            }
                        }
                    }
                }
                
                if (!linksToCreate.isEmpty()) {
                    insert linksToCreate;
                }
            }
            
            return expense.Id;
            
        } catch (Exception e) {
            Database.rollback(sp);
            throw new AuraHandledException('Error creating expense: ' + e.getMessage() + ' at line: ' + e.getLineNumber());
        }
    }
    
    /**
     * Apply user mappings based on business rules
     */
    private static void applyUserMappings(Expense__c expense, User currentUser, String recordTypeId) {
        String recordTypeName = getRecordTypeNameById(recordTypeId);
        
        if (recordTypeName == 'RBL') {
            applyRBLMappings(expense, currentUser);
        } else if (recordTypeName == 'Unitop_Tristar') {
            applyUnitopTristarMappings(expense, currentUser);
        }
    }
    
    /**
     * Apply mappings for RBL record type
     */
    private static void applyRBLMappings(Expense__c expense, User currentUser) {
        // For AHN or Textile users, set Zonal Head to manager
        if (currentUser.User_Type__c == 'AHN' || currentUser.User_Type__c == 'Textile') {
            expense.Zonal_Head__c = currentUser.ManagerId;
        }
        
        // Set Business HOD based on user type
        if (currentUser.User_Type__c == 'AHN') {
            expense.Business_HOD__c = getUserIdFromMapping('AHN_BUSINESS_HOD');
        } else if (currentUser.User_Type__c == 'Textile') {
            expense.Business_HOD__c = getUserIdFromMapping('TEXTILE_BUSINESS_HOD');
        }
    }
    
    /**
     * Apply mappings for Unitop_Tristar record type
     */
    private static void applyUnitopTristarMappings(Expense__c expense, User currentUser) {
        // Set Customer Success Incharge
        if (currentUser.User_Type__c == 'Synthetic') {
            if (expense.Sales_Type__c == 'Domestic') {
                expense.Customer_Success_Incharge__c = getUserIdFromMapping('SYNTHETIC_DOMESTIC_CSI');
            } else if (expense.Sales_Type__c == 'Export') {
                expense.Customer_Success_Incharge__c = getUserIdFromMapping('SYNTHETIC_EXPORT_CSI');
            }
        } else if (currentUser.User_Type__c == 'Application') {
            expense.Customer_Success_Incharge__c = getUserIdFromMapping('APPLICATION_CSI');
        }
        
        // Set Business HOD for Synthetic or Application users
        if (currentUser.User_Type__c == 'Synthetic' || currentUser.User_Type__c == 'Application') {
            expense.Business_HOD__c = getUserIdFromMapping('UNITOP_BUSINESS_HOD');
        }
    }
    
    /**
     * Get user ID from custom metadata mapping
     */
    private static Id getUserIdFromMapping(String mappingKey) {
        try {
            List<Expense_User_Mapping__mdt> mappings = [
                SELECT User_Name__c 
                FROM Expense_User_Mapping__mdt 
                WHERE Mapping_Key__c = :mappingKey 
                AND Is_Active__c = true 
                LIMIT 1
            ];
            
            if (!mappings.isEmpty() && String.isNotBlank(mappings[0].User_Name__c)) {
                List<User> users = [SELECT Id FROM User WHERE Username = :mappings[0].User_Name__c LIMIT 1];
                return !users.isEmpty() ? users[0].Id : null;
            }
        } catch (Exception e) {
            System.debug('Error getting user from mapping: ' + e.getMessage());
        }
        return null;
    }
    
    /**
     * Get record type name by ID
     */
    private static String getRecordTypeNameById(String recordTypeId) {
        if (String.isBlank(recordTypeId)) return null;
        
        try {
            List<RecordType> recordTypes = [
                SELECT DeveloperName 
                FROM RecordType 
                WHERE Id = :recordTypeId 
                LIMIT 1
            ];
            return !recordTypes.isEmpty() ? recordTypes[0].DeveloperName : null;
        } catch (Exception e) {
            return null;
        }
    }
    
    // Replace the existing determineRecordType method with this new version
    private static String determineRecordType(User currentUser) {
        Map<String, String> recordTypeMap = getExpenseRecordTypes();
        String recordTypeId = null;
        
        // Determine record type based on User_Type__c
        if (String.isNotBlank(currentUser.User_Type__c)) {
            String userType = currentUser.User_Type__c;
            
            System.debug('User Type: ' + userType);
            
            if ((userType == 'Textile' || userType == 'AHN') && recordTypeMap.containsKey('RBL')) {
                recordTypeId = recordTypeMap.get('RBL');
            } else if ((userType == 'Application' || userType == 'Synthetic') && 
                       recordTypeMap.containsKey('Unitop_Tristar')) {
                recordTypeId = recordTypeMap.get('Unitop_Tristar');
            }
            
            System.debug('Determined Record Type ID: ' + recordTypeId);
        } else {
            System.debug('User does not have a User_Type__c value');
        }
        
        return recordTypeId;
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getExpenseRecordTypes() {
        Map<String, String> recordTypeMap = new Map<String, String>();
        try {
            for (RecordType rt : [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Expense__c']) {
                recordTypeMap.put(rt.DeveloperName, rt.Id);
            }
        } catch (Exception e) {
            System.debug('Error getting record types: ' + e.getMessage());
        }
        return recordTypeMap;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getTransportModes() {
        try {
            List<Map<String, String>> options = new List<Map<String, String>>();
            
            // Get picklist values from Mode_of_Transport__c field on Expense_Line_Item__c
            Schema.DescribeFieldResult fieldResult = Expense_Line_Item__c.Mode_of_Transport__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            
            for (Schema.PicklistEntry entry : ple) {
                if (entry.isActive()) {
                    options.add(new Map<String, String>{
                        'label' => entry.getLabel(),
                        'value' => entry.getValue()
                    });
                }
            }
            
            return options;
        } catch (Exception e) {
            throw new AuraHandledException('Error getting transport modes: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Id createCustomerVisit(Id tourId, Id accountId) {
        try {
            // Validate inputs
            if (tourId == null) {
                throw new AuraHandledException('Tour ID is required.');
            }
            if (accountId == null) {
                throw new AuraHandledException('Account ID is required.');
            }

            // Check if Customer_Visited__c already exists
            List<Customer_Visited__c> existingVisits = [
                SELECT Id 
                FROM Customer_Visited__c 
                WHERE Tour__c = :tourId AND Account__c = :accountId
                LIMIT 1
            ];
            
            if (!existingVisits.isEmpty()) {
                return existingVisits[0].Id;
            }

            // Get account details
            Account acc = [SELECT Id, Name FROM Account WHERE Id = :accountId LIMIT 1];

            // Create new Customer_Visited__c record
            Customer_Visited__c visit = new Customer_Visited__c();
            visit.Tour__c = tourId;
            visit.Account__c = accountId;
            visit.Name = acc.Name;

            insert visit;
            return visit.Id;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error creating Customer Visit: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getSalesTypeOptions() {
        try {
            System.debug('Starting getSalesTypeOptions method');
            
            List<Map<String, String>> options = new List<Map<String, String>>();
            
            // First, let's check if Expense__c object is accessible
            if (!Schema.getGlobalDescribe().containsKey('Expense__c')) {
                throw new AuraHandledException('Expense__c object not found');
            }
            
            // Get the object describe
            Schema.DescribeSObjectResult objDescribe = Expense__c.sObjectType.getDescribe();
            if (!objDescribe.isAccessible()) {
                throw new AuraHandledException('Expense__c object is not accessible');
            }
            
            // Check if Sales_Type__c field exists and is accessible
            Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
            if (!fieldMap.containsKey('Sales_Type__c')) {
                throw new AuraHandledException('Sales_Type__c field not found on Expense__c object');
            }
            
            Schema.SObjectField salesTypeField = fieldMap.get('Sales_Type__c');
            Schema.DescribeFieldResult fieldResult = salesTypeField.getDescribe();
            
            if (!fieldResult.isAccessible()) {
                throw new AuraHandledException('Sales_Type__c field is not accessible');
            }
            
            // Get picklist values
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            System.debug('Number of picklist entries found: ' + ple.size());
            
            for (Schema.PicklistEntry entry : ple) {
                System.debug('Processing picklist entry: ' + entry.getLabel() + ' - ' + entry.getValue() + ' - Active: ' + entry.isActive());
                if (entry.isActive()) {
                    options.add(new Map<String, String>{
                        'label' => entry.getLabel(),
                        'value' => entry.getValue()
                    });
                }
            }
            
            System.debug('Final options count: ' + options.size());
            
            // If no active options found, return empty list
            return options;
            
        } catch (Exception e) {
            System.debug('Error in getSalesTypeOptions: ' + e.getMessage() + ' - Stack: ' + e.getStackTraceString());
            throw new AuraHandledException('Failed to load Sales Type options: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> checkAllowanceEligibility(String expenseDate, String userId) {
        try {
            Map<String, Object> result = new Map<String, Object>();
            
            if (String.isBlank(expenseDate) || String.isBlank(userId)) {
                result.put('isDailyAllowanceEligible', false);
                result.put('isOutOfPocketEligible', false);
                result.put('message', 'Date and User ID are required');
                return result;
            }
            
            // Convert string date to Date object
            Date selectedDate = Date.valueOf(expenseDate);
            
            // Check if user already has ANY expense with Daily Allowance OR Out of Pocket on this date
            List<Expense__c> existingAllowanceExpenses = [
                SELECT Id, Date__c, Type_of_Voucher__c 
                FROM Expense__c 
                WHERE Employee_Name__c = :userId 
                AND Date__c = :selectedDate
                AND Id IN (
                    SELECT Expense__c 
                    FROM Expense_Line_Item__c 
                    WHERE Daily_Allowance__c > 0
                )
            ];
            
            // Check if any existing expense has Daily Allowance (Local voucher)
            Boolean hasDailyAllowanceClaimed = false;
            Boolean hasOutOfPocketClaimed = false;
            
            for (Expense__c exp : existingAllowanceExpenses) {
                if (exp.Type_of_Voucher__c == 'Local') {
                    hasDailyAllowanceClaimed = true;
                } else if (exp.Type_of_Voucher__c == 'Outstation') {
                    hasOutOfPocketClaimed = true;
                }
            }
            
            // MUTUAL EXCLUSIVITY: Only one can be claimed per date
            Boolean isDailyAllowanceEligible = !hasDailyAllowanceClaimed && !hasOutOfPocketClaimed;
            Boolean isOutOfPocketEligible = !hasOutOfPocketClaimed && !hasDailyAllowanceClaimed;
            
            result.put('isDailyAllowanceEligible', isDailyAllowanceEligible);
            result.put('isOutOfPocketEligible', isOutOfPocketEligible);
            result.put('hasDailyAllowanceClaimed', hasDailyAllowanceClaimed);
            result.put('hasOutOfPocketClaimed', hasOutOfPocketClaimed);
            
            String message = '';
            if (hasDailyAllowanceClaimed && hasOutOfPocketClaimed) {
                message = 'Both Daily Allowance and Out of Pocket already claimed for this date';
            } else if (hasDailyAllowanceClaimed) {
                message = 'Daily Allowance already claimed for this date - Out of Pocket not available';
            } else if (hasOutOfPocketClaimed) {
                message = 'Out of Pocket already claimed for this date - Daily Allowance not available';
            } else {
                message = 'Eligible for both Daily Allowance and Out of Pocket';
            }
            
            result.put('message', message);
            result.put('existingExpenseCount', existingAllowanceExpenses.size());
            
            return result;
            
        } catch (Exception e) {
            System.debug('Error in checkAllowanceEligibility: ' + e.getMessage() + ' - ' + e.getStackTraceString());
            throw new AuraHandledException('Error checking allowance eligibility: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<Expense_Team_Member__c> createExpenseTeamMembers(List<Expense_Team_Member__c> teamMembers) {
        try {
            if (teamMembers != null && !teamMembers.isEmpty()) {
                // Check for duplicates before inserting
                Set<String> existingCombinations = new Set<String>();
                List<Expense_Team_Member__c> membersToInsert = new List<Expense_Team_Member__c>();
                
                for (Expense_Team_Member__c member : teamMembers) {
                    String combination = member.Expense__c + '-' + member.Attendee__c;
                    if (!existingCombinations.contains(combination)) {
                        membersToInsert.add(member);
                        existingCombinations.add(combination);
                    }
                }
                
                if (!membersToInsert.isEmpty()) {
                    insert membersToInsert;
                    return membersToInsert;
                }
            }
            return new List<Expense_Team_Member__c>();
        } catch (Exception e) {
            throw new AuraHandledException('Error creating team members: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Decimal getCombinedAllowances(String expenseOwnerId, List<String> teamMemberIds, String cityType, String salesType, String expenseType) {
        try {
            Decimal totalAllowance = 0;
            
            // Combine all user IDs (expense owner + team members)
            Set<String> allUserIds = new Set<String>();
            if (String.isNotBlank(expenseOwnerId)) {
                allUserIds.add(expenseOwnerId);
            }
            if (teamMemberIds != null) {
                allUserIds.addAll(teamMemberIds);
            }
            
            if (allUserIds.isEmpty()) {
                return totalAllowance;
            }
            
            // Get users with their grades
            List<User> users = [SELECT Id, Name, Grades__c FROM User WHERE Id IN :allUserIds AND IsActive = true];
            
            // Create a map to store grade allowances for each user
            Map<String, Decimal> userAllowances = new Map<String, Decimal>();
            
            // Get unique grade names
            Set<String> gradeNames = new Set<String>();
            for (User u : users) {
                if (String.isNotBlank(u.Grades__c)) {
                    gradeNames.add(u.Grades__c);
                }
            }
            
            if (!gradeNames.isEmpty()) {
                // Query grade details with sales type
                String query = 'SELECT Id, Name, Lodging_Hotel__c, ' +
                    'Lodging_Hotel_B_Class__c, Boarding_Food__c, Boarding_Food_B_Class__c ' +
                    'FROM Grade__c WHERE Name IN :gradeNames';
                
                if (String.isNotBlank(salesType)) {
                    query += ' AND Sales_Type__c = :salesType';
                }
                
                List<Grade__c> grades = Database.query(query);
                Map<String, Grade__c> gradeMap = new Map<String, Grade__c>();
                for (Grade__c grade : grades) {
                    gradeMap.put(grade.Name, grade);
                }
                
                // Calculate allowance for EACH user and SUM them
                for (User user : users) {
                    if (String.isNotBlank(user.Grades__c) && gradeMap.containsKey(user.Grades__c)) {
                        Grade__c userGrade = gradeMap.get(user.Grades__c);
                        
                        Decimal userAllowance = 0;
                        
                        // Determine allowance based on expense type and city type
                        if (expenseType == 'Hotel') {
                            if (cityType == 'A Class City') {
                                userAllowance = userGrade.Lodging_Hotel__c != null ? userGrade.Lodging_Hotel__c : 0;
                            } else {
                                userAllowance = userGrade.Lodging_Hotel_B_Class__c != null ? userGrade.Lodging_Hotel_B_Class__c : 
                                (userGrade.Lodging_Hotel__c != null ? userGrade.Lodging_Hotel__c : 0);
                                    }
                        } else if (expenseType == 'Food') {
                            if (cityType == 'A Class City') {
                                userAllowance = userGrade.Boarding_Food__c != null ? userGrade.Boarding_Food__c : 0;
                            } else {
                                userAllowance = userGrade.Boarding_Food_B_Class__c != null ? userGrade.Boarding_Food_B_Class__c : 
                                (userGrade.Boarding_Food__c != null ? userGrade.Boarding_Food__c : 0);
                                    }
                        }
                        
                        userAllowances.put(user.Id, userAllowance);
                        totalAllowance += userAllowance;
                        
                        System.debug('User ' + user.Name + ' with grade ' + user.Grades__c + ' adds: ' + userAllowance);
                    } else {
                        System.debug('No grade found for user: ' + user.Name);
                        userAllowances.put(user.Id, 0);
                    }
                }
            }
            
            System.debug('Total combined allowance for all users: ' + totalAllowance);
            System.debug('Individual user allowances: ' + userAllowances);
            
            return totalAllowance;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error getting combined allowances: ' + e.getMessage());
        }
    }
}