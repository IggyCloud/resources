import http from 'k6/http';
import { check } from 'k6';
import { getAuthHeaders } from './shared.js';

export const options = {
  vus: 2,
  duration: '10s',
};

export default function () {
  const order = {
    userId: "test-user",
    userName: "Test User",
    city: "Test City",
    street: "Test Street",
    state: "Test State",
    country: "Test Country",
    zipCode: "12345",
    cardNumber: "4012888888881881",
    cardHolderName: "Test User",
    cardExpiration: "12/25",
    cardSecurityNumber: "123",
    cardTypeId: 1,
    buyer: "Test Buyer"
  };

  const response = http.post(
    'http://localhost:5224/api/v1/orders',
    JSON.stringify(order),
    getAuthHeaders()
  );

  check(response, {
    'is status 201': (r) => r.status === 201,
    'order created': (r) => r.json().orderId !== undefined,
  });
}