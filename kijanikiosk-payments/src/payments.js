function calculateFee(amount) {
    if (amount <= 0) throw new Error('Amount must be positive');
    return parseFloat((amount * 0.025).toFixed(2));
  }
  
  function validatePayment(payment) {
    if (!payment.amount || !payment.currency) return false;
    if (payment.amount <= 0) return false;
    return true;
  }
  
  module.exports = { calculateFee, validatePayment };