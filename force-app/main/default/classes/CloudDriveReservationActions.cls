public with sharing class CloudDriveReservationActions {

    public class ReservationRequest {
        @InvocableVariable(required=true label='Customer Name' description='Full name of the customer making the reservation')
        public String customerName;

        @InvocableVariable(required=true label='Vehicle Id' description='Vehicle name (e.g. Toyota Corolla 2024) or Salesforce record ID')
        public String vehicleId;

        @InvocableVariable(required=true label='Start Date' description='Rental start date in YYYY-MM-DD or DD/MM/YYYY format')
        public String startDateStr;

        @InvocableVariable(required=true label='End Date' description='Rental end date in YYYY-MM-DD or DD/MM/YYYY format')
        public String endDateStr;

        @InvocableVariable(label='City' description='City where the vehicle will be picked up')
        public String city;
    }

    public class ReservationResponse {
        @InvocableVariable(label='Success')
        public Boolean success;
        @InvocableVariable(label='Message')
        public String message;
        @InvocableVariable(label='Reservation Id')
        public String reservationId;
        @InvocableVariable(label='Reservation Number')
        public String reservationNumber;
        @InvocableVariable(label='Confirmation Message')
        public String confirmationMessage;
        @InvocableVariable(label='Error Message')
        public String errorMessage;
        @InvocableVariable(label='Vehicle Name')
        public String vehicleName;
        @InvocableVariable(label='Start Date Out')
        public String startDateOut;
        @InvocableVariable(label='End Date Out')
        public String endDateOut;
        @InvocableVariable(label='Total Cost')
        public String totalCost;
        @InvocableVariable(label='Formatted Response')
        public String formattedResponse;
    }

    @InvocableMethod(label='Create Vehicle Reservation'
        description='Creates a new vehicle reservation. The vehicleName parameter accepts the vehicle name (e.g. Toyota Corolla 2024) or its Salesforce record ID. Use the vehicle name provided by the customer directly.'
    )
    public static List<ReservationResponse> createReservation(List<ReservationRequest> requests) {
        List<ReservationResponse> responses = new List<ReservationResponse>();
        for (ReservationRequest req : requests) {
            ReservationResponse resp = new ReservationResponse();
            try {
                // Parse dates
                Date startDt = parseDate(req.startDateStr);
                Date endDt = parseDate(req.endDateStr);
                if (startDt == null || endDt == null) {
                    resp.success = false;
                    resp.message = 'Data invalida. Use o formato YYYY-MM-DD ou DD/MM/YYYY.';
                    resp.errorMessage = resp.message;
                    resp.formattedResponse = resp.message;
                    resp.confirmationMessage = resp.message;
                    responses.add(resp);
                    continue;
                }

                // Find contact
                Contact customer = findContact(req.customerName);
                if (customer == null) {
                    resp.success = false;
                    resp.message = 'Cliente nao encontrado: ' + req.customerName + '. Por favor, realize o cadastro primeiro.';
                    resp.errorMessage = resp.message;
                    resp.formattedResponse = resp.message;
                    resp.confirmationMessage = resp.message;
                    responses.add(resp);
                    continue;
                }

                // Find vehicle
                Vehicle__c vehicle = findVehicle(req.vehicleId, req.city);
                if (vehicle == null) {
                    resp.success = false;
                    resp.message = 'Veiculo nao encontrado ou nao disponivel: ' + req.vehicleId;
                    resp.errorMessage = resp.message;
                    resp.formattedResponse = resp.message;
                    resp.confirmationMessage = resp.message;
                    responses.add(resp);
                    continue;
                }

                // Calculate cost
                Integer days = startDt.daysBetween(endDt);
                if (days <= 0) days = 1;
                Decimal totalCostAmt = (vehicle.DailyRate__c != null ? vehicle.DailyRate__c : 0) * days;

                // Generate reservation number
                String resNum = 'RES-' + String.valueOf(Math.abs(Crypto.getRandomInteger()));

                // Create reservation record
                Reservation__c res = new Reservation__c();
                                    res.Customer__c = customer.Id;
                res.Vehicle__c = vehicle.Id;
                res.Start_Date__c = startDt;
                res.End_Date__c = endDt;
                res.Status__c = 'Confirmed';
                res.Total_Cost__c = totalCostAmt;
                res.Reservation_Number__c = resNum;
                insert res;

                // Update vehicle status
                vehicle.Status__c = 'Reserved';
                update vehicle;

                // Build detailed response
                String details = 'Reserva: ' + resNum + '\n' +
                    'Veiculo: ' + vehicle.Name + '\n' +
                    'Status: Confirmed\n' +
                    'Retirada: ' + fmtDate(startDt) + '\n' +
                    'Devolucao: ' + fmtDate(endDt) + '\n' +
                    'Total: R$ ' + totalCostAmt.format();

                resp.success = true;
                resp.message = 'Reserva confirmada com sucesso!\n\n' + details;
                resp.reservationId = res.Id;
                resp.reservationNumber = resNum;
                resp.vehicleName = vehicle.Name;
                resp.startDateOut = fmtDate(startDt);
                resp.endDateOut = fmtDate(endDt);
                resp.totalCost = 'R$ ' + totalCostAmt.format();
                resp.confirmationMessage = resp.message;
                resp.errorMessage = '';
                resp.formattedResponse = 'Sua reserva foi confirmada com sucesso! Aqui estao os detalhes:\n\n' + details;

            } catch (Exception e) {
                resp.success = false;
                resp.message = 'Erro ao criar reserva: ' + e.getMessage();
                resp.errorMessage = resp.message;
                resp.formattedResponse = resp.message;
                resp.confirmationMessage = resp.message;
            }
            responses.add(resp);
        }
        return responses;
    }

    private static Contact findContact(String name) {
        if (name == null || name.trim() == '') return null;
        String n = '%' + name.trim() + '%';
        List<Contact> contacts = [SELECT Id, FirstName, LastName, Name FROM Contact WHERE Name LIKE :n LIMIT 1];
        return contacts.isEmpty() ? null : contacts[0];
    }

    private static Vehicle__c findVehicle(String vehicleId, String city) {
        if (vehicleId == null || vehicleId.trim() == '') return null;
        String v = '%' + vehicleId.trim() + '%';
        List<Vehicle__c> vehicles = [SELECT Id, Name, Status__c, DailyRate__c, Location__r.City__c, Location__r.Name FROM Vehicle__c WHERE (Name LIKE :v OR Id = :vehicleId.trim()) AND Status__c = 'Available' LIMIT 5];
        if (vehicles.isEmpty()) return null;
        if (city == null || city.trim() == '') return vehicles[0];
        String cityNorm = normalizeCity(city);
        for (Vehicle__c veh : vehicles) {
            String vCity = veh.Location__r != null ? normalizeCity(veh.Location__r.City__c) : '';
            String vLoc = veh.Location__r != null ? normalizeCity(veh.Location__r.Name) : '';
            if (vCity.containsIgnoreCase(cityNorm) || vLoc.containsIgnoreCase(cityNorm)) return veh;
        }
        return vehicles[0];
    }

    private static String normalizeCity(String s) {
        if (s == null) return '';
        s = s.trim();
        s = s.replace('\u00e3','a').replace('\u00c3','A');
        s = s.replace('\u00e1','a').replace('\u00c1','A');
        s = s.replace('\u00e2','a').replace('\u00c2','A');
        s = s.replace('\u00e9','e').replace('\u00c9','E');
        s = s.replace('\u00ea','e').replace('\u00ca','E');
        s = s.replace('\u00ed','i').replace('\u00cd','I');
        s = s.replace('\u00f3','o').replace('\u00d3','O');
        s = s.replace('\u00f4','o').replace('\u00d4','O');
        s = s.replace('\u00fa','u').replace('\u00da','U');
        s = s.replace('\u00ed','i').replace('\u00cd','I');
        s = s.replace('\u00e7','c').replace('\u00c7','C');
        return s;
    }

    private static Date parseDate(String s) {
        if (s == null || s.trim() == '') return null;
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

    private static String fmtDate(Date d) {
        if (d == null) return '';
        return String.valueOf(d.day()).leftPad(2,'0') + '/' + String.valueOf(d.month()).leftPad(2,'0') + '/' + String.valueOf(d.year());
    }
}