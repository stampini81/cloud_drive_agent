public with sharing class CloudDriveFeedbackActions {

    public class FeedbackRequest {
        @InvocableVariable(required=true label='Reservation Number' description='Reservation number for the feedback')
        public String reservationNumber;

        @InvocableVariable(required=true label='Rating' description='Rating from 1 to 5')
        public Integer rating;

        @InvocableVariable(label='Comments' description='Customer feedback comments')
        public String comments;
    }

    public class FeedbackResponse {
        @InvocableVariable(label='Success')
        public Boolean success;

        @InvocableVariable(label='Feedback Id')
        public String feedbackId;

        @InvocableVariable(label='Message')
        public String message;
    }

    @InvocableMethod(label='Submit Customer Feedback'
                     description='Records customer feedback and rating for a completed reservation'
                     category='CloudDrive')
    public static List<FeedbackResponse> submitFeedback(
            List<FeedbackRequest> requests) {

        List<FeedbackResponse> results = new List<FeedbackResponse>();

        for (FeedbackRequest req : requests) {
            FeedbackResponse resp = new FeedbackResponse();
            try {
                // Validate rating
                if (req.rating < 1 || req.rating > 5) {
                    resp.success = false;
                    resp.message = 'Avaliacao invalida. Por favor insira um valor de 1 a 5.';
                    results.add(resp);
                    continue;
                }

                // Find reservation
                List<Reservation__c> reservations = [
                    SELECT Id, Status__c, Reservation_Number__c
                    FROM Reservation__c
                    WHERE Reservation_Number__c = :req.reservationNumber LIMIT 1];

                if (reservations.isEmpty()) {
                    resp.success = false;
                    resp.message = 'Reserva nao encontrada: ' + req.reservationNumber;
                    results.add(resp);
                    continue;
                }

                Reservation__c res = reservations[0];

                // Create feedback
                Feedback__c fb = new Feedback__c();
                fb.Reservation__c = res.Id;
                fb.Rating__c = req.rating;
                fb.Comments__c = req.comments;
                insert fb;

                resp.success = true;
                resp.feedbackId = fb.Id;

                String ratingMsg = '';
                if (req.rating >= 5) ratingMsg = 'Excelente!';
                else if (req.rating >= 4) ratingMsg = 'Muito bom!';
                else if (req.rating >= 3) ratingMsg = 'Bom.';
                else ratingMsg = 'Obrigado pelo seu feedback.';

                resp.message = 'Obrigado pela sua avaliacao de ' + req.rating + '/5 estrelas! ' +
                               ratingMsg + ' Seu feedback e muito importante para nos.';

            } catch (Exception e) {
                resp.success = false;
                resp.message = 'Erro ao registrar feedback: ' + e.getMessage();
            }
            results.add(resp);
        }
        return results;
    }
}