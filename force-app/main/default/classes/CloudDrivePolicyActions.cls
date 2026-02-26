public with sharing class CloudDrivePolicyActions {

    public class PolicyRequest {
        @InvocableVariable(label='Policy Type' description='Tipo de politica: RENTAL, CANCELLATION, INSURANCE, PRICING, ou ALL. Se nao souber, use ALL')
        public String policyType;

        @InvocableVariable(label='Vehicle Category' description='Categoria do veiculo para precificacao: ECONOMY, STANDARD, SUV, LUXURY')
        public String vehicleCategory;

        @InvocableVariable(label='Customer Id' description='Id do cliente para personalizar resposta')
        public String customerId;
    }

    public class PolicyResponse {
        @InvocableVariable(label='Policy Title')
        public String policyTitle;

        @InvocableVariable(label='Policy Details')
        public String policyDetails;

        @InvocableVariable(label='Rental Policy')
        public String rentalPolicy;

        @InvocableVariable(label='Insurance Options')
        public String insuranceOptions;

        @InvocableVariable(label='Pricing Info')
        public String pricingInfo;

        @InvocableVariable(label='Summary')
        public String summary;

        @InvocableVariable(label='Success')
        public Boolean success;
    }

    @InvocableMethod(label='Get Policy Information' description='Retorna informacoes sobre politicas da CloudDrive incluindo cancelamento, seguro e precos')
    public static List<PolicyResponse> getPolicyInfo(List<PolicyRequest> requests) {
        List<PolicyResponse> results = new List<PolicyResponse>();

        String rentalPolicy = 'POLITICA DE LOCACAO CLOUDDRIVE:\n' +
            '- Idade minima: 21 anos (taxa adicional para menores de 25 anos)\n' +
            '- CNH valida com minimo 2 anos\n' +
            '- Cartao de credito em nome do locatario\n' +
            '- POLITICA DE CANCELAMENTO:\n' +
            '  * Cancelamento gratis ate 48h antes da retirada\n' +
            '  * Cancelamento entre 24-48h: multa de 20% do valor total\n' +
            '  * Cancelamento com menos de 24h: multa de 50% do valor total\n' +
            '  * No-show (nao retirada): cobranca de 100% do valor\n' +
            '- Combustivel: devolucao com mesmo nivel de abastecimento\n' +
            '- Quilometragem: livre (sem restricao de KM)';

        String insuranceOptions = 'OPCOES DE SEGURO CLOUDDRIVE:\n' +
            '- Basico (incluso): cobertura contra terceiros\n' +
            '- Intermediario (+R$30/dia): cobertura completa com franquia de R$1.500\n' +
            '- Premium (+R$55/dia): cobertura total sem franquia';

        String pricingInfo = 'TABELA DE PRECOS CLOUDDRIVE (por dia):\n' +
            '- ECONOMY: R$89-120/dia\n' +
            '- STANDARD: R$120-180/dia\n' +
            '- SUV: R$180-280/dia\n' +
            '- LUXURY: R$350-600/dia';

        for (PolicyRequest req : requests) {
            PolicyResponse resp = new PolicyResponse();
            resp.success = true;
            String pType = req.policyType != null ? req.policyType.toUpperCase() : 'ALL';

            if (pType == 'RENTAL' || pType == 'CANCELLATION') {
                resp.policyTitle = 'Politica de Locacao e Cancelamento CloudDrive';
                resp.policyDetails = rentalPolicy;
                resp.summary = 'Politica de locacao e cancelamento CloudDrive';
            } else if (pType == 'INSURANCE') {
                resp.policyTitle = 'Opcoes de Seguro CloudDrive';
                resp.policyDetails = insuranceOptions;
                resp.summary = 'Opcoes de seguro CloudDrive';
            } else if (pType == 'PRICING') {
                resp.policyTitle = 'Tabela de Precos CloudDrive';
                resp.policyDetails = pricingInfo;
                resp.summary = 'Tabela de precos CloudDrive';
            } else {
                resp.policyTitle = 'Informacoes Completas CloudDrive';
                resp.policyDetails = rentalPolicy + '\n\n' + insuranceOptions + '\n\n' + pricingInfo;
                resp.summary = 'Informacoes completas de politicas e precos CloudDrive';
            }

            resp.rentalPolicy = rentalPolicy;
            resp.insuranceOptions = insuranceOptions;
            resp.pricingInfo = pricingInfo;
            results.add(resp);
        }

        return results;
    }
}