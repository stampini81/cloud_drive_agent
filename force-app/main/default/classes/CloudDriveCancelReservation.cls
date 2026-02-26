public with sharing class CloudDriveCancelReservation {

    public class CancelReservationRequest {
        @InvocableVariable(required=true label='Reservation Number' description='Reservation number (RES-XXXXXXXXX) or Salesforce ID to cancel')
        public String reservationNumber;
    }

    public class CancelReservationResponse {
        @InvocableVariable(label='Success') public Boolean success;
        @InvocableVariable(label='Message') public String message;
        @InvocableVariable(label='Reservation Number') public String reservationNumber;
        @InvocableVariable(label='Vehicle Name') public String vehicleName;
    }

    @InvocableMethod(label='Cancel Vehicle Reservation'
        description='Cancels an existing vehicle reservation by reservation number (RES-XXXXXXXXX)')
    public static List<CancelReservationResponse> cancelReservation(List<CancelReservationRequest> requests) {
        List<CancelReservationResponse> results = new List<CancelReservationResponse>();
        for (CancelReservationRequest req : requests) {
            CancelReservationResponse resp = new CancelReservationResponse();
            try {
                String resNum = req.reservationNumber == null ? '' : req.reservationNumber.trim();
                // Remove prefix if user typed just the number
                if (!resNum.startsWith('RES-') && resNum.length() > 5 && resNum.isNumeric()) {
                    resNum = 'RES-' + resNum;
                }

                List<Reservation__c> resList = new List<Reservation__c>();

                // PRIMARY: search by reservation_number__c (RES-XXXXXXXXX)
                if (resNum.startsWith('RES-')) {
                    resList = [
                        SELECT Id, Name, reservation_number__c, Status__c, vehicle__c,
                               vehicle__r.Name, Start_Date__c, End_Date__c
                        FROM Reservation__c
                        WHERE reservation_number__c = :resNum
                        LIMIT 1
                    ];
                }

                // FALLBACK: try by Salesforce ID if 15 or 18 chars
                if (resList.isEmpty() && (resNum.length() == 15 || resNum.length() == 18)) {
                    try {
                        Id resId = (Id) resNum;
                        resList = [
                            SELECT Id, Name, reservation_number__c, Status__c, vehicle__c,
                                   vehicle__r.Name, Start_Date__c, End_Date__c
                            FROM Reservation__c
                            WHERE Id = :resId
                            LIMIT 1
                        ];
                    } catch (Exception ex) {}
                }

                // FALLBACK: search by Name (autonumber)
                if (resList.isEmpty()) {
                    resList = [
                        SELECT Id, Name, reservation_number__c, Status__c, vehicle__c,
                               vehicle__r.Name, Start_Date__c, End_Date__c
                        FROM Reservation__c
                        WHERE Name = :resNum
                        LIMIT 1
                    ];
                }

                if (resList.isEmpty()) {
                    resp.success = false;
                    resp.message = 'Reserva "' + req.reservationNumber + '" nao encontrada. Verifique o numero e tente novamente.';
                } else {
                    Reservation__c res = resList[0];
                    String displayNum = res.reservation_number__c != null ? res.reservation_number__c : res.Name;

                    if (res.Status__c == 'Cancelled') {
                        resp.success = false;
                        resp.message = 'A reserva ' + displayNum + ' ja esta cancelada.';
                    } else {
                        // Check cancellation policy: free if > 24h before start
                        DateTime startDT = DateTime.newInstance(res.Start_Date__c, Time.newInstance(0, 0, 0, 0));
                        DateTime now = DateTime.now();
                        Long hoursUntilStart = (startDT.getTime() - now.getTime()) / 3600000;

                        // Update reservation status
                        res.Status__c = 'Cancelled';
                        update res;

                        // Free up vehicle
                        if (res.vehicle__c != null) {
                            Vehicle__c v = new Vehicle__c(Id = res.vehicle__c);
                            v.Status__c = 'Available';
                            update v;
                        }

                        String cancellationNote = hoursUntilStart >= 24
                            ? 'Cancelamento gratuito aplicado.'
                            : 'Aviso: cancelamento realizado com menos de 24h de antecedencia. Taxas podem ser aplicadas.';

                        resp.success = true;
                        resp.reservationNumber = displayNum;
                        resp.vehicleName = res.vehicle__r != null ? res.vehicle__r.Name : '';
                        resp.message = 'Reserva ' + displayNum + ' cancelada com sucesso! ' + cancellationNote;
                    }
                }
            } catch (Exception e) {
                resp.success = false;
                resp.message = 'Erro ao cancelar: ' + e.getMessage();
            }
            results.add(resp);
        }
        return results;
    }
}