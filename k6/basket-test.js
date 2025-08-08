import http from 'k6/http';
import { check } from 'k6';
import { getAuthHeaders } from './shared.js';

export const options = {
  vus: 5,
  duration: '20s',
};

export default function () {
  const basketItem = {
    catalogItemId: 1,
    quantity: 1,
    basketId: 'test-basket'
  };

  const response = http.post(
    'http://localhost:5221/api/v1/basket',
    JSON.stringify(basketItem),
    getAuthHeaders()
  );

  check(response, {
    'is status 201': (r) => r.status === 201,
    'basket created': (r) => r.json().basketId === 'test-basket',
  });
}