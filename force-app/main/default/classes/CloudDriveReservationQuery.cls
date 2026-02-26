public with sharing class CloudDriveReservationQuery {

    public class ReservationQueryRequest {
        @InvocableVariable(required=true label='Reservation Number'
            description='Numero da reserva para consultar (ex: R-001). Obrigatorio.')
        public String reservationNumber;
    }

    public class ReservationQueryResponse {
        @InvocableVariable(label='Success') public Boolean success;
        @InvocableVariable(label='Message') public String message;
        @InvocableVariable(label='Reservation Id') public String reservationId;
        @InvocableVariable(label='Reservation Name') public String reservationName;
        @InvocableVariable(label='Reservation Number') public String reservationNum;
        @InvocableVariable(label='Status') public String status;
        @InvocableVariable(label='Start Date') public String startDate;
        @InvocableVariable(label='End Date') public String endDate;
        @InvocableVariable(label='Total Cost') public String totalCost;
        @InvocableVariable(label='Vehicle Name') public String vehicleName;
        @InvocableVariable(label='Formatted Response') public String formattedResponse;
    }

    @InvocableMethod(label='Get Reservation Status'
        description='Consulta uma reserva de veiculo pelo numero de confirmacao. Retorna detalhes e status atual da reserva.')
    public static List<ReservationQueryResponse> getReservationStatus(List<ReservationQueryRequest> requests) {
        List<ReservationQueryResponse> responses = new List<ReservationQueryResponse>();
        for (ReservationQueryRequest req : requests) {
            ReservationQueryResponse resp = new ReservationQueryResponse();
            try {
                String searchTerm = req.reservationNumber != null ? req.reservationNumber.trim() : '';
                if (String.isBlank(searchTerm)) {
                    resp.success = false;
                    resp.message = 'Por favor, informe o numero da reserva.';
                    resp.formattedResponse = resp.message;
                    responses.add(resp);
                    continue;
                }
                List<Reservation__c> reservations = [
                    SELECT Id, Name, Reservation_Number__c,
                           Vehicle__r.Name, Customer__r.Name,
                           Status__c, Start_Date__c, End_Date__c, Total_Cost__c
                    FROM Reservation__c
                    WHERE Reservation_Number__c = :searchTerm
                       OR Name = :searchTerm
                       OR Name LIKE :('%' + searchTerm + '%')
                    LIMIT 1
                ];
                if (reservations.isEmpty()) {
                    resp.success = false;
                    resp.message = 'Nenhuma reserva encontrada com o numero: ' + searchTerm + '. Por favor verifique o numero e tente novamente.';
                    resp.formattedResponse = resp.message;
                } else {
                    Reservation__c r = reservations[0];
                    resp.success = true;
                    resp.reservationId = r.Id;
                    resp.reservationName = r.Name;
                    resp.reservationNum = r.Reservation_Number__c != null ? r.Reservation_Number__c : r.Name;
                    resp.vehicleName = r.Vehicle__r != null ? r.Vehicle__r.Name : '-';
                    resp.status = r.Status__c != null ? r.Status__c : '-';
                    resp.startDate = r.Start_Date__c != null ? r.Start_Date__c.format() : '-';
                    resp.endDate = r.End_Date__c != null ? r.End_Date__c.format() : '-';
                    resp.totalCost = r.Total_Cost__c != null ? 'R$ ' + r.Total_Cost__c.format() : '-';
                    resp.message = 'Reserva encontrada!';
                    resp.formattedResponse =
                        'Reserva: ' + resp.reservationNum + '\n' +
                        'Veiculo: ' + resp.vehicleName + '\n' +
                        'Status: ' + resp.status + '\n' +
                        'Retirada: ' + resp.startDate + '\n' +
                        'Devolucao: ' + resp.endDate + '\n' +
                        'Total: ' + resp.totalCost;
                }
            } catch (Exception e) {
                resp.success = false;
                resp.message = 'Erro ao consultar reserva: ' + e.getMessage();
                resp.formattedResponse = resp.message;
            }
            responses.add(resp);
        }
        return responses;
    }
}