const { calculateFee, validatePayment } = require('../src/payments');

describe('calculateFee', () => {
  test('calculates 2.5% fee correctly', () => {
    expect(calculateFee(1000)).toBe(25);
  });
  test('throws on zero amount', () => {
    expect(() => calculateFee(0)).toThrow('Amount must be positive');
  });
  test('throws on negative amount', () => {
    expect(() => calculateFee(-100)).toThrow('Amount must be positive');
  });
});

describe('validatePayment', () => {
  test('returns true for valid payment', () => {
    expect(validatePayment({ amount: 500, currency: 'KES' })).toBe(true);
  });
  test('returns false when amount missing', () => {
    expect(validatePayment({ currency: 'KES' })).toBe(false);
  });
  test('returns false when currency missing', () => {
    expect(validatePayment({ amount: 500 })).toBe(false);
  });
});