public class GetInventory_FromSAP {
    
    @future(callout=true)
    public static void fetchInventoryData() {
        try {

            Http http = new Http();
            HttpRequest req = new HttpRequest();
            
            // Named Credential endpoint
            req.setEndpoint(System.Label.SAP_Inventory_API);
            req.setMethod('GET');
            req.setHeader('Accept', 'application/xml');
            req.setTimeout(120000);
            
            HttpResponse res = http.send(req);
            
            if(res.getStatusCode() == 200) {
                String xmlResponse = res.getBody();
                // System.debug('Inventory xmlResponse: ' + xmlResponse);
                // Parse JSON into list of wrappers
                List<SAPInventoryWrapper> records = (List<SAPInventoryWrapper>) JSON.deserialize(xmlResponse, List<SAPInventoryWrapper>.class);
    
                System.debug('Total records: ' + records.size());
                
            } else {
                System.debug('Error: ' + res.getStatus() + ' Body: ' + res.getBody());
            }
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }

    public class SAPInventoryWrapper {
        public String WERKS;
        public String MATNR;
        public String MAKTX;
        public String MTART;
        public String LGORT;
        public String HSDAT;
        public String VFDAT;
        public String MEINS;
        public String LABST;
        public String CHARG;
        public String INSME;
        public String SPEME;
        public String CUST_NAME;
        public String LGOBE;
        public String SGT_SCAT;
        public String NAME1;
        public String WAERS;
        public String MATKL;
        public String WLABS;
        public String VTEXT;
        public String SPART;
        public String WUMLM;
        public String PRODH;
        public String PRODT;
        public String WINSM;
        public String LVORM;
        public String DRUM;
        public String WEINM;
        public String BWESB;
        public String EINME;
        public String WSPEM;
        public String GLGMG;
        public String RETME;
        public String WRETM;
        public String TRAME;
        public String WBWESB;
        public String UMLMC;
        public String UMLME;
        public String WGLGM;
        public String WTRAM;
        public String WUMLC;
    }


}