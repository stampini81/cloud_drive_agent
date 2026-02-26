public with sharing class CloudDriveAgentContext {

    public class CustomerContextRequest {
        @InvocableVariable(required=true label='Customer Email' description='Email of the customer to get context')
        public String customerEmail;
    }

    public class CustomerContextResponse {
        @InvocableVariable(label='Customer Name')
        public String customerName;

        @InvocableVariable(label='Active Reservations')
        public String activeReservations;

        @InvocableVariable(label='Total Reservations')
        public Integer totalReservations;

        @InvocableVariable(label='Context Summary')
        public String contextSummary;

        @InvocableVariable(label='Has Active Reservation')
        public Boolean hasActiveReservation;

        @InvocableVariable(label='Last Reservation Number')
        public String lastReservationNumber;
    }

    @InvocableMethod(label='Get Customer Context'
                     description='Retrieves current customer context including active reservations and history'
                     category='CloudDrive')
    public static List<CustomerContextResponse> getCustomerContext(
            List<CustomerContextRequest> requests) {

        List<CustomerContextResponse> results = new List<CustomerContextResponse>();

        for (CustomerContextRequest req : requests) {
            CustomerContextResponse resp = new CustomerContextResponse();
            try {
                // Find contact by email
                List<Contact> contacts = [SELECT Id, FirstName, LastName, Email
                                          FROM Contact WHERE Email = :req.customerEmail LIMIT 1];

                if (contacts.isEmpty()) {
                    resp.customerName = 'Cliente nao encontrado';
                    resp.contextSummary = 'Nenhum cliente encontrado com o email: ' + req.customerEmail;
                    resp.hasActiveReservation = false;
                    resp.totalReservations = 0;
                    results.add(resp);
                    continue;
                }

                Contact c = contacts[0];
                resp.customerName = c.FirstName + ' ' + c.LastName;

                // Find active reservations for this customer
                List<Reservation__c> activeRes = [
                    SELECT Id, Reservation_Number__c, Status__c,
                           Start_Date__c, End_Date__c, Total_Cost__c,
                           Vehicle__r.Name, Vehicle__r.Category__c
                    FROM Reservation__c
                    WHERE Customer__c = :c.Id
                    AND Status__c IN ('Confirmed', 'Active')
                    ORDER BY Start_Date__c DESC
                    LIMIT 5];

                List<Reservation__c> allRes = [
                    SELECT Id FROM Reservation__c
                    WHERE Customer__c = :c.Id];

                resp.totalReservations = allRes.size();
                resp.hasActiveReservation = !activeRes.isEmpty();

                if (!activeRes.isEmpty()) {
                    resp.lastReservationNumber = activeRes[0].Reservation_Number__c;
                    String resSummary = 'Reservas ativas de ' + resp.customerName + ':\n';
                    for (Reservation__c r : activeRes) {
                        String vName = r.Vehicle__r != null ? r.Vehicle__r.Name : 'N/A';
                        resSummary += '- ' + r.Reservation_Number__c + ' | ' + vName +
                                      ' | ' + r.Status__c + ' | ' +
                                      (r.Start_Date__c != null ? String.valueOf(r.Start_Date__c) : '') +
                                      ' a ' +
                                      (r.End_Date__c != null ? String.valueOf(r.End_Date__c) : '') + '\n';
                    }
                    resp.activeReservations = resSummary;
                    resp.contextSummary = 'Cliente: ' + resp.customerName +
                        ' | Reservas totais: ' + resp.totalReservations +
                        ' | Reservas ativas: ' + activeRes.size() + '\n' + resSummary;
                } else {
                    resp.activeReservations = 'Nenhuma reserva ativa.';
                    resp.contextSummary = 'Cliente: ' + resp.customerName +
                        ' | Reservas totais: ' + resp.totalReservations +
                        ' | Nenhuma reserva ativa no momento.';
                }

            } catch (Exception e) {
                resp.contextSummary = 'Erro ao buscar contexto: ' + e.getMessage();
                resp.hasActiveReservation = false;
            }
            results.add(resp);
        }
        return results;
    }
}