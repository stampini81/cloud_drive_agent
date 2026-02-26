public with sharing class CloudDriveCustomerRegistration {

    public class RegistrationRequest {
        @InvocableVariable(required=true label='Full Name' description='Full name of the customer')
        public String fullName;
        @InvocableVariable(required=true label='Email' description='Email address of the customer')
        public String email;
        @InvocableVariable(label='Phone' description='Phone number of the customer')
        public String phone;
        @InvocableVariable(label='CPF' description='CPF document number of the customer')
        public String cpf;
        @InvocableVariable(label='Birth Date' description='Birth date of the customer (YYYY-MM-DD)')
        public String birthDate;
        @InvocableVariable(label='Drivers License' description='Drivers license number of the customer')
        public String driversLicense;
    }

    public class RegistrationResponse {
        @InvocableVariable(label='Success') public Boolean success;
        @InvocableVariable(label='Message') public String message;
        @InvocableVariable(label='Customer Id') public String customerId;
        @InvocableVariable(label='Customer Name') public String customerName;
        @InvocableVariable(label='Registration Number') public String registrationNumber;
        @InvocableVariable(label='Summary') public String summary;
    }

    @InvocableMethod(
        label='Register Customer'
        description='Registers a new customer in the CloudDrive system creating a Contact record'
    )
    public static List<RegistrationResponse> registerCustomer(List<RegistrationRequest> requests) {
        List<RegistrationResponse> results = new List<RegistrationResponse>();
        for (RegistrationRequest req : requests) {
            RegistrationResponse resp = new RegistrationResponse();
            try {
                if (String.isBlank(req.fullName) || String.isBlank(req.email)) {
                    resp.success = false;
                    resp.message = 'Nome completo e email sao obrigatorios para o cadastro.';
                    results.add(resp); continue;
                }
                List<Contact> existing = [SELECT Id, Name, Email FROM Contact WHERE Email = :req.email LIMIT 1];
                if (!existing.isEmpty()) {
                    resp.success = false;
                    resp.customerId = existing[0].Id;
                    resp.customerName = existing[0].Name;
                    resp.message = 'Cliente ja cadastrado com este email.';
                    resp.summary = 'Cliente ' + existing[0].Name + ' ja possui cadastro ativo na CloudDrive.';
                    results.add(resp); continue;
                }
                String primeiroNome = req.fullName;
                String ultimoNome = 'CloudDrive';
                if (req.fullName.contains(' ')) {
                    Integer idx = req.fullName.indexOf(' ');
                    primeiroNome = req.fullName.substring(0, idx);
                    ultimoNome = req.fullName.substring(idx + 1);
                }
                Contact c = new Contact();
                c.FirstName = primeiroNome;
                c.LastName = ultimoNome;
                c.Email = req.email;
                if (String.isNotBlank(req.phone)) c.Phone = req.phone;
                String notas = '';
                if (String.isNotBlank(req.cpf)) notas += 'CPF: ' + req.cpf;
                if (String.isNotBlank(req.driversLicense)) notas += (notas != '' ? ' | ' : '') + 'CNH: ' + req.driversLicense;
                if (notas != '') c.Description = notas;
                insert c;
                String regNum = 'CD-' + String.valueOf(System.currentTimeMillis()).right(8);
                resp.success = true;
                resp.customerId = c.Id;
                resp.customerName = req.fullName;
                resp.registrationNumber = regNum;
                resp.message = 'Cadastro realizado com sucesso!';
                resp.summary = 'Cliente ' + req.fullName + ' cadastrado com sucesso na CloudDrive. Numero: ' + regNum + '. Agora pode realizar reservas de veiculos.';
            } catch (Exception e) {
                resp.success = false;
                resp.message = 'Erro ao realizar cadastro: ' + e.getMessage();
                resp.summary = 'Nao foi possivel completar o cadastro. Tente novamente.';
            }
            results.add(resp);
        }
        return results;
    }
}