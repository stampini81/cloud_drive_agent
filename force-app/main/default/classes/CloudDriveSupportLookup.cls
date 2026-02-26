public with sharing class CloudDriveSupportLookup {

    public class LookupCaseRequest {
        @InvocableVariable(required=true label='Case Number Or Id'
            description='Numero do chamado (ex: 00001234) ou Salesforce Id para consultar. Obrigatorio.')
        public String caseNumberOrId;
    }

    public class LookupCaseResponse {
        @InvocableVariable(label='Success') public Boolean success;
        @InvocableVariable(label='Case Id') public String caseId;
        @InvocableVariable(label='Case Number') public String caseNumber;
        @InvocableVariable(label='Status') public String status;
        @InvocableVariable(label='Subject') public String subject;
        @InvocableVariable(label='Priority') public String priority;
        @InvocableVariable(label='Description') public String caseDescription;
        @InvocableVariable(label='Message') public String message;
        @InvocableVariable(label='Case Response') public String caseResponse;
    }

    @InvocableMethod(label='Get Support Ticket'
        description='Busca um chamado de suporte existente pelo numero do caso. Use quando o cliente informa que ja tem um chamado aberto e quer consultar o status ou quando diz que foi cobrado duas vezes e fornece um numero de chamado.')
    public static List<LookupCaseResponse> lookupCase(List<LookupCaseRequest> requests) {
        List<LookupCaseResponse> responses = new List<LookupCaseResponse>();
        for (LookupCaseRequest req : requests) {
            LookupCaseResponse resp = new LookupCaseResponse();
            try {
                String searchTerm = req.caseNumberOrId != null ? req.caseNumberOrId.trim() : '';
                if (String.isBlank(searchTerm)) {
                    resp.success = false;
                    resp.message = 'Por favor, informe o numero do chamado.';
                    resp.caseResponse = resp.message;
                    responses.add(resp);
                    continue;
                }
                List<Case> cases = new List<Case>();
                // Try by CaseNumber first
                cases = [SELECT Id, CaseNumber, Subject, Status, Priority, Description,
                         SuppliedEmail, CreatedDate
                         FROM Case WHERE CaseNumber = :searchTerm LIMIT 1];
                // If not found, try partial match with LIKE
                if (cases.isEmpty()) {
                    String likeSearch = '%' + searchTerm + '%';
                    cases = [SELECT Id, CaseNumber, Subject, Status, Priority, Description,
                             SuppliedEmail, CreatedDate
                             FROM Case WHERE CaseNumber LIKE :likeSearch LIMIT 1];
                }
                // If not found try by Salesforce Id
                if (cases.isEmpty() && (searchTerm.length() == 15 || searchTerm.length() == 18)) {
                    try {
                        Id cId = (Id) searchTerm;
                        cases = [SELECT Id, CaseNumber, Subject, Status, Priority, Description,
                                 SuppliedEmail, CreatedDate
                                 FROM Case WHERE Id = :cId LIMIT 1];
                    } catch (Exception ex) {}
                }
                if (cases.isEmpty()) {
                    resp.success = false;
                    resp.message = 'Chamado "' + searchTerm + '" nao encontrado. Verifique o numero e tente novamente.';
                    resp.caseResponse = '## Chamado Nao Encontrado\n\n' +
                        'Nao foi possivel localizar o chamado com o numero: **' + searchTerm + '**\n\n' +
                        'Por favor, verifique o numero e tente novamente, ou posso abrir um novo chamado para voce.';
                } else {
                    Case c = cases[0];
                    resp.success = true;
                    resp.caseId = c.Id;
                    resp.caseNumber = c.CaseNumber;
                    resp.status = c.Status;
                    resp.subject = c.Subject;
                    resp.priority = c.Priority;
                    resp.caseDescription = c.Description;
                    resp.message = 'Chamado encontrado!';
                    resp.caseResponse = '## Chamado #' + c.CaseNumber + '\n\n' +
                        '**Status:** ' + c.Status + '\n' +
                        '**Assunto:** ' + (c.Subject != null ? c.Subject : '-') + '\n' +
                        '**Prioridade:** ' + (c.Priority != null ? c.Priority : '-') + '\n' +
                        (String.isNotBlank(c.Description) ? '**Descricao:** ' + c.Description + '\n' : '') +
                        '**Aberto em:** ' + c.CreatedDate.format() + '\n\n' +
                        'Nossa equipe esta analisando seu caso. Posso ajudar com mais alguma coisa?';
                }
            } catch (Exception e) {
                resp.success = false;
                resp.message = 'Erro ao buscar chamado: ' + e.getMessage();
                resp.caseResponse = resp.message;
            }
            responses.add(resp);
        }
        return responses;
    }
}