public with sharing class CloudDriveVehicleActions {

    public class VehicleSearchRequest {
        @InvocableVariable(required=true label='City' description='City name to search for available vehicles (e.g. Sao Paulo, Rio de Janeiro)')
        public String city;

        @InvocableVariable(required=true label='Start Date' description='Rental start date in format YYYY-MM-DD or DD/MM/YYYY. For tomorrow use next day date.')
        public String startDate;

        @InvocableVariable(label='End Date' description='Rental end date in format YYYY-MM-DD or DD/MM/YYYY. Defaults to next day if blank.')
        public String endDate;

        @InvocableVariable(label='Vehicle Category' description='Category: SUV, Sedan, Luxury, Van or Electric')
        public String vehicleCategory;
    }

    public class VehicleSearchResponse {
        @InvocableVariable(label='Success') public Boolean success;
        @InvocableVariable(label='Message') public String message;
        @InvocableVariable(label='Vehicle Count') public Integer vehicleCount;
        @InvocableVariable(label='Vehicle List Formatted') public String vehicleListFormatted;
        @InvocableVariable(label='City Found') public String cityFound;
        @InvocableVariable(label='Start Date') public String startDateOut;
        @InvocableVariable(label='End Date') public String endDateOut;
        @InvocableVariable(label='Formatted Response') public String formattedResponse;
    }

    @InvocableMethod(label='Search Available Vehicles'
        description='Search available vehicles by city and date range. Returns formatted list of available vehicles.')
    public static List<VehicleSearchResponse> searchVehicles(List<VehicleSearchRequest> requests) {
        List<VehicleSearchResponse> responses = new List<VehicleSearchResponse>();
        for (VehicleSearchRequest req : requests) {
            VehicleSearchResponse resp = new VehicleSearchResponse();
            try {
                Date startDt = parseDate(req.startDate);
                Date endDt = (String.isNotBlank(req.endDate)) ? parseDate(req.endDate) : (startDt != null ? startDt.addDays(1) : null);

                if (startDt == null) {
                    resp.success = false;
                    resp.message = 'Data de inicio invalida: ' + req.startDate + '. Use o formato YYYY-MM-DD ou DD/MM/YYYY.';
                    responses.add(resp);
                    continue;
                }

                String cityNorm = normalizeCity(req.city);

                List<Vehicle__c> allVehicles = [
                    SELECT Id, Name, Category__c, DailyRate__c, Status__c, Location__r.City__c, Location__r.Name
                    FROM Vehicle__c
                    WHERE Available_From__c <= :startDt
                    AND Available_To__c >= :endDt
                    AND Status__c = 'Available'
                ];

                List<Vehicle__c> vehicles = new List<Vehicle__c>();
                for (Vehicle__c v : allVehicles) {
                    String vCity = (v.Location__r != null) ? normalizeCity(v.Location__r.City__c) : '';
                    String vLocName = (v.Location__r != null) ? normalizeCity(v.Location__r.Name) : '';
                    if (vCity.containsIgnoreCase(cityNorm) || vLocName.containsIgnoreCase(cityNorm)) {
                        vehicles.add(v);
                    }
                }

                if (String.isNotBlank(req.vehicleCategory)) {
                    List<Vehicle__c> filtered = new List<Vehicle__c>();
                    for (Vehicle__c v : vehicles) {
                        if (v.Category__c != null && v.Category__c.equalsIgnoreCase(req.vehicleCategory)) {
                            filtered.add(v);
                        }
                    }
                    vehicles = filtered;
                }

                resp.vehicleCount = vehicles.size();
                resp.cityFound = req.city;
                resp.startDateOut = fmtDate(startDt);
                resp.endDateOut = fmtDate(endDt);

                if (vehicles.isEmpty()) {
                    resp.success = true;
                    resp.message = 'Nenhum veiculo disponivel encontrado em ' + req.city + ' para o periodo solicitado.';
                    resp.vehicleListFormatted = resp.message;
                    resp.formattedResponse = resp.message;
                } else {
                    resp.success = true;
                    resp.message = 'Encontrados ' + vehicles.size() + ' veiculo(s) disponivel(is) em ' + req.city + '.';
                    String vehicleOutput = 'Veiculos disponiveis em ' + req.city + ' de ' + fmtDate(startDt) + ' ate ' + fmtDate(endDt) + ':\n';
                    Integer idx = 1;
                    for (Vehicle__c v : vehicles) {
                        vehicleOutput += idx + '. ' + v.Name;
                        if (v.Category__c != null) vehicleOutput += ' | Categoria: ' + v.Category__c;
                        if (v.DailyRate__c != null) vehicleOutput += ' | Diaria: R$ ' + v.DailyRate__c.format();
                        vehicleOutput += '\n';
                        idx++;
                    }
                    resp.vehicleListFormatted = vehicleOutput;
                    resp.formattedResponse = resp.message + '\n' + vehicleOutput;
                }
            } catch (Exception e) {
                resp.success = false;
                resp.message = 'Erro ao buscar veiculos: ' + e.getMessage();
                resp.formattedResponse = resp.message;
            }
            responses.add(resp);
        }
        return responses;
    }

    private static String normalizeCity(String s) {
        if (s == null) return '';
        s = s.trim();
        s = s.replace('\u00e3', 'a').replace('\u00c3', 'A');
        s = s.replace('\u00e2', 'a').replace('\u00c2', 'A');
        s = s.replace('\u00e1', 'a').replace('\u00c1', 'A');
        s = s.replace('\u00e0', 'a').replace('\u00c0', 'A');
        s = s.replace('\u00f5', 'o').replace('\u00d5', 'O');
        s = s.replace('\u00f3', 'o').replace('\u00d3', 'O');
        s = s.replace('\u00f4', 'o').replace('\u00d4', 'O');
        s = s.replace('\u00fa', 'u').replace('\u00da', 'U');
        s = s.replace('\u00ed', 'i').replace('\u00cd', 'I');
        s = s.replace('\u00e7', 'c').replace('\u00c7', 'C');
        return s;
    }

    private static String fmtDate(Date d) {
        if (d == null) return '';
        return d.day() + '/' + d.month() + '/' + d.year();
    }

    private static Date parseDate(String s) {
        if (String.isBlank(s)) return null;
        s = s.trim();
        try {
            if (s.length() == 10 && s.substring(4,5) == '-') {
                Integer yr = Integer.valueOf(s.substring(0,4));
                Integer mo = Integer.valueOf(s.substring(5,7));
                Integer dy = Integer.valueOf(s.substring(8,10));
                return Date.newInstance(yr, mo, dy);
            }
            if (s.length() == 10 && s.substring(2,3) == '/') {
                Integer dy = Integer.valueOf(s.substring(0,2));
                Integer mo = Integer.valueOf(s.substring(3,5));
                Integer yr = Integer.valueOf(s.substring(6,10));
                return Date.newInstance(yr, mo, dy);
            }
        } catch (Exception e) {}
        return null;
    }
}