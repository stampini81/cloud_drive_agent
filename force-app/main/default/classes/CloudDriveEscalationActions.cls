public with sharing class CloudDriveEscalationActions {

    public class EscalationRequest {
        @InvocableVariable(required=true label='Customer Email' description='Customer email for escalation')
        public String customerEmail;

        @InvocableVariable(required=true label='Issue Description' description='Description of the issue to escalate')
        public String issueDescription;

        @InvocableVariable(label='Reservation Number' description='Related reservation number if applicable')
        public String reservationNumber;

        @InvocableVariable(label='Priority' description='Priority: High, Medium, Low')
        public String priority;
    }

    public class EscalationResponse {
        @InvocableVariable(label='Success')
        public Boolean success;

        @InvocableVariable(label='Case Number')
        public String caseNumber;

        @InvocableVariable(label='Message')
        public String message;

        @InvocableVariable(label='Escalation Id')
        public String escalationId;
    }

    @InvocableMethod(label='Escalate to Human Agent'
                     description='Creates a support case and escalates issue to a human agent'
                     category='CloudDrive')
    public static List<EscalationResponse> escalateToHuman(
            List<EscalationRequest> requests) {

        List<EscalationResponse> results = new List<EscalationResponse>();

        for (EscalationRequest req : requests) {
            EscalationResponse resp = new EscalationResponse();
            try {
                String priorityVal = String.isNotBlank(req.priority) ? req.priority : 'Medium';

                // Find or create contact
                List<Contact> contacts = [SELECT Id, FirstName, LastName, AccountId
                                          FROM Contact WHERE Email = :req.customerEmail LIMIT 1];

                // Create a Case for escalation
                Case escalationCase = new Case();
                escalationCase.Subject = 'CloudDrive - Escalacao: ' + req.issueDescription.abbreviate(100);
                escalationCase.Description = req.issueDescription +
                    (String.isNotBlank(req.reservationNumber) ?
                        '\nReserva relacionada: ' + req.reservationNumber : '');
                escalationCase.Status = 'New';
                escalationCase.Priority = priorityVal;
                escalationCase.Origin = 'Agentforce';

                if (!contacts.isEmpty()) {
                    escalationCase.ContactId = contacts[0].Id;
                    if (contacts[0].AccountId != null) {
                        escalationCase.AccountId = contacts[0].AccountId;
                    }
                }

                insert escalationCase;

                resp.success = true;
                resp.caseNumber = escalationCase.CaseNumber;
                resp.escalationId = escalationCase.Id;
                resp.message = 'Sua solicitacao foi escalada para um agente humano. ' +
                    'Numero do caso: ' + escalationCase.CaseNumber + '. ' +
                    'Um especialista CloudDrive entrara em contato em breve. ' +
                    'Prioridade: ' + priorityVal + '.';

            } catch (Exception e) {
                resp.success = false;
                resp.message = 'Erro ao criar escalacao: ' + e.getMessage();
            }
            results.add(resp);
        }
        return results;
    }
}