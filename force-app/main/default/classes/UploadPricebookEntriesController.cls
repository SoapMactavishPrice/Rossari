public with sharing class UploadPricebookEntriesController {

    @AuraEnabled
    public static List<Map<String,String>> processPriceChunk(String rowsJson) {
        List<Object> raw = (List<Object>) JSON.deserializeUntyped(rowsJson);
        Integer inputCount = raw.size();

        List<Map<String,String>> results = new List<Map<String,String>>();
        for (Integer i = 0; i < inputCount; i++) {
            results.add(new Map<String,String>{'Material'=>'','Status'=>'Pending','Message'=>'','sourceIndex'=>String.valueOf(i)});
        }

        Set<String> productCodes = new Set<String>();
        for (Integer i = 0; i < raw.size(); i++) {
            Map<String,Object> row = (Map<String,Object>) raw[i];
            String material = (row.containsKey('Material') && row.get('Material') != null) ? String.valueOf(row.get('Material')).trim() : null;
            if (material != null && material != '') productCodes.add(material);
            results[i].put('Material', material);
            if (row.containsKey('__rowIndex') && row.get('__rowIndex') != null) {
                results[i].put('__rowIndex', String.valueOf(row.get('__rowIndex')));
            }
        }

        Map<String, Product2> productsByCode = new Map<String, Product2>();
        if (!productCodes.isEmpty()) {
            for (Product2 p : [SELECT Id, Name, ProductCode FROM Product2 WHERE ProductCode IN :productCodes]) {
                productsByCode.put(p.ProductCode, p);
            }
        }

        Id pricebookId;
        try {
            List<Pricebook2> custom = [SELECT Id FROM Pricebook2 WHERE IsStandard = true AND IsActive = true LIMIT 1];
            if (!custom.isEmpty()) pricebookId = custom[0].Id;
        } catch (Exception e) {
            pricebookId = null;
        }
        if (pricebookId == null) {
            Pricebook2 std = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
            pricebookId = std.Id;
        }

        Set<Id> productIds = new Set<Id>();
        for (String code : productsByCode.keySet()) productIds.add(productsByCode.get(code).Id);

        Map<String, PricebookEntry> existingPbeByKey = new Map<String, PricebookEntry>();
        if (!productIds.isEmpty()) {
            for (PricebookEntry pbe : [
                SELECT Id, Product2Id, UnitPrice, CurrencyIsoCode, Conversion_Rate_Dollar__c, Conversion_Rate_Euro__c 
                FROM PricebookEntry 
                WHERE Pricebook2Id = :pricebookId AND Product2Id IN :productIds
            ]) {
                String currencyCode = (pbe.CurrencyIsoCode == null) ? '' : pbe.CurrencyIsoCode;
                existingPbeByKey.put(pbe.Product2Id + ':' + currencyCode, pbe);
            }
        }

        List<PricebookEntry> toInsert = new List<PricebookEntry>();
        List<Integer> toInsertIndexes = new List<Integer>();
        List<PricebookEntry> toUpdate = new List<PricebookEntry>();
        List<Integer> toUpdateIndexes = new List<Integer>();

        for (Integer i = 0; i < raw.size(); i++) {
            Map<String,Object> row = (Map<String,Object>) raw[i];

            String material = (row.containsKey('Material') && row.get('Material') != null) ? String.valueOf(row.get('Material')).trim() : null;
            results[i].put('Material', material);

            if (material == null || material == '') {
                results[i] = errorRow(material, results[i].get('__rowIndex'), 'Missing Material');
                continue;
            }

            Product2 prod = productsByCode.get(material);
            if (prod == null) {
                results[i] = errorRow(material, results[i].get('__rowIndex'), 'Product not found');
                continue;
            }

            Object unitObj = row.get('UnitPrice');
            Decimal unitPrice;
            try {
                if (unitObj == null) throw new CustomException('UnitPrice missing');
                unitPrice = Decimal.valueOf(String.valueOf(unitObj));
            }
            catch (Exception ex) {
                results[i] = errorRow(material, results[i].get('__rowIndex'), 'Invalid UnitPrice');
                continue;
            }

            String currencyCode = (row.containsKey('Currency') && row.get('Currency') != null) ? String.valueOf(row.get('Currency')).trim() : '';
            String key = prod.Id + ':' + (currencyCode == null ? '' : currencyCode);

            Decimal convDollar = null;
            Decimal convEuro = null;

            Object convDollarObj = row.get('ConvDollar');
            Object convEuroObj = row.get('ConvEuro');

            if (convDollarObj != null) {
                try {
                    String convDollarStr = String.valueOf(convDollarObj);
                    convDollarStr = convDollarStr.replace('₹', '').replace('$', '').replace('£', '').replace(',', '').trim();
                    convDollar = Decimal.valueOf(convDollarStr);
                } catch (Exception e) {
                }
            }

            if (convEuroObj != null) {
                try {
                    String convEuroStr = String.valueOf(convEuroObj);
                    convEuroStr = convEuroStr.replace('₹', '').replace('$', '').replace('£', '').replace(',', '').trim();
                    convEuro = Decimal.valueOf(convEuroStr);
                } catch (Exception e) {
                }
            }

            PricebookEntry existing = existingPbeByKey.get(key);
            if (existing == null) {
                PricebookEntry pbe = new PricebookEntry(
                    Pricebook2Id = pricebookId, 
                    Product2Id = prod.Id, 
                    UnitPrice = unitPrice, 
                    IsActive = true,
                    Conversion_Rate_Dollar__c = convDollar,
                    Conversion_Rate_Euro__c = convEuro
                );
                if (currencyCode != null && currencyCode != '') pbe.put('CurrencyIsoCode', currencyCode);
                toInsert.add(pbe);
                toInsertIndexes.add(i);
            } else {
                Boolean hasChanges = false;
                
                if (existing.UnitPrice == null || existing.UnitPrice != unitPrice) {
                    existing.UnitPrice = unitPrice;
                    hasChanges = true;
                }
                
                if (convDollar != null) {
                    if (existing.Conversion_Rate_Dollar__c == null || existing.Conversion_Rate_Dollar__c != convDollar) {
                        existing.Conversion_Rate_Dollar__c = convDollar;
                        hasChanges = true;
                    }
                }
                
                if (convEuro != null) {
                    if (existing.Conversion_Rate_Euro__c == null || existing.Conversion_Rate_Euro__c != convEuro) {
                        existing.Conversion_Rate_Euro__c = convEuro;
                        hasChanges = true;
                    }
                }
                
                if (hasChanges) {
                    toUpdate.add(existing);
                    toUpdateIndexes.add(i);
                } else {
                    results[i] = successRow(material, results[i].get('__rowIndex'), 'No Change');
                }
            }
        }

        if (!toInsert.isEmpty()) {
            Database.SaveResult[] insertResults = Database.insert(toInsert, false);
            for (Integer j = 0; j < insertResults.size(); j++) {
                Database.SaveResult sr = insertResults[j];
                Integer inputIdx = toInsertIndexes[j];
                Map<String,Object> rawRow = (Map<String,Object>) raw[inputIdx];
                String material = (rawRow.containsKey('Material') && rawRow.get('Material') != null) ? String.valueOf(rawRow.get('Material')) : null;
                String sourceIdx = results[inputIdx].get('__rowIndex');
                if (sr.isSuccess()) {
                    results[inputIdx] = successRow(material, sourceIdx, 'Inserted');
                } else {
                    String errMsg = collectFirstErrorMessage(sr.getErrors());
                    results[inputIdx] = errorRow(material, sourceIdx, 'Insert failed: ' + errMsg);
                }
            }
        }

        if (!toUpdate.isEmpty()) {
            Database.SaveResult[] updateResults = Database.update(toUpdate, false);
            for (Integer j = 0; j < updateResults.size(); j++) {
                Database.SaveResult sr = updateResults[j];
                Integer inputIdx = toUpdateIndexes[j];
                Map<String,Object> rawRow = (Map<String,Object>) raw[inputIdx];
                String material = (rawRow.containsKey('Material') && rawRow.get('Material') != null) ? String.valueOf(rawRow.get('Material')) : null;
                String sourceIdx = results[inputIdx].get('__rowIndex');
                if (sr.isSuccess()) {
                    results[inputIdx] = successRow(material, sourceIdx, 'Updated');
                } else {
                    String errMsg = collectFirstErrorMessage(sr.getErrors());
                    results[inputIdx] = errorRow(material, sourceIdx, 'Update failed: ' + errMsg);
                }
            }
        }

        for (Integer i = 0; i < results.size(); i++) {
            Map<String,String> r = results[i];
            if (r.get('Status') == 'Pending') {
                r.put('Status', 'Skipped');
                r.put('Message', 'No action taken');
            }
        }

        return results;
    }

    private static String collectFirstErrorMessage(Database.Error[] errs) {
        if (errs == null || errs.size() == 0) return 'Unknown error';
        for (Database.Error e : errs) if (e != null) return e.getStatusCode() + ': ' + e.getMessage();
        return 'Unknown error';
    }

    private static Map<String,String> successRow(String material, String rowIndex, String msg) {
        return new Map<String,String>{
            'Material' => material,
            'Status' => msg,
            'Message' => msg,
            '__rowIndex' => rowIndex
        };
    }

    private static Map<String,String> errorRow(String material, String rowIndex, String msg) {
        return new Map<String,String>{
            'Material' => material,
            'Status' => 'Failed',
            'Message' => msg,
            '__rowIndex' => rowIndex
        };
    }

    public class CustomException extends Exception {}
}