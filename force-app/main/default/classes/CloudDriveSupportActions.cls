public with sharing class CloudDriveSupportActions {
    public class CreateCaseRequest {
        @InvocableVariable(required=true label='Subject' description='Subject of the support case')
        public String subject;
        @InvocableVariable(required=true label='Description' description='Description of the issue')
        public String description;
        @InvocableVariable(label='Contact Email' description='Customer email')
        public String contactEmail;
        @InvocableVariable(label='Reservation Number' description='Reservation number related to the issue')
        public String reservationNumber;
        @InvocableVariable(label='Priority' description='Priority of the case (High, Medium, Low)')
        public String priority;
    }

    public class CreateCaseResponse {
        @InvocableVariable(label='Case Id')
        public String caseId;
        @InvocableVariable(label='Case Number')
        public String caseNumber;
        @InvocableVariable(label='Confirmation Message')
        public String confirmationMessage;
        @InvocableVariable(label='Case Response')
        public String caseResponse;
    }

    @InvocableMethod(label='Create Support Ticket' description='Creates a support case in Salesforce for the customer')
    public static List<CreateCaseResponse> createCase(List<CreateCaseRequest> requests) {
        List<CreateCaseResponse> responses = new List<CreateCaseResponse>();
        List<Case> casesToInsert = new List<Case>();
        for (CreateCaseRequest req : requests) {
            Case c = new Case();
            c.Subject = req.subject;
            c.Description = req.description;
            c.Origin = 'Agentforce';
            c.Status = 'New';
            c.Priority = (req.priority != null && req.priority != '') ? req.priority : 'Medium';
            if (req.contactEmail != null && req.contactEmail != '') {
                c.SuppliedEmail = req.contactEmail;
            }
            if (req.reservationNumber != null && req.reservationNumber != '') {
                c.Subject = c.Subject + ' [Reserva: ' + req.reservationNumber + ']';
            }
            casesToInsert.add(c);
        }
        insert casesToInsert;
        for (Integer i = 0; i < casesToInsert.size(); i++) {
            Case created = [SELECT Id, CaseNumber FROM Case WHERE Id = :casesToInsert[i].Id LIMIT 1];
            CreateCaseResponse resp = new CreateCaseResponse();
            resp.caseId = created.Id;
            resp.caseNumber = created.CaseNumber;
            resp.confirmationMessage = 'Seu chamado foi aberto com sucesso! Numero do chamado: ' + created.CaseNumber + '. Nossa equipe entrara em contato em breve.';
            String caseResp = '## Chamado Aberto com Sucesso!\n\n';
            caseResp += '**Numero do Chamado:** ' + created.CaseNumber + '\n';
            caseResp += '**Status:** Novo\n';
            caseResp += '**Assunto:** ' + requests[i].subject;
            if (requests[i].reservationNumber != null && requests[i].reservationNumber != '') {
                caseResp += ' [Reserva: ' + requests[i].reservationNumber + ']';
            }
            caseResp += '\n';
            caseResp += '**Prioridade:** ' + ((requests[i].priority != null && requests[i].priority != '') ? requests[i].priority : 'Media') + '\n\n';
            caseResp += '---\n\n';
            caseResp += 'Nossa equipe de suporte analisara seu caso e entrara em contato em ate **24 horas**.\n\n';
            caseResp += 'Posso ajudar com mais alguma coisa?';
            resp.caseResponse = caseResp;
            responses.add(resp);
        }
        return responses;
    }
}