trigger BookingTrigger on Reservation__c (before insert) {
    for(Reservation__c r : Trigger.new) {
        r.Status__c = 'Confirmed';
    }
}