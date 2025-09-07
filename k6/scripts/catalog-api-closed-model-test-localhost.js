import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');

// Test configuration
export let options = {
  stages: [
    { duration: '10s', target: 10 },   // Ramp up to 10 users over 10 seconds
    { duration: '10s', target: 20 }, // Stay at 20 users for 10 seconds
    { duration: '10s', target: 0 }, // Ramp down to 0 users in 10 seconds
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% of requests should be below 500ms
    http_req_failed: ['rate<0.1'],    // Error rate should be less than 10%
    errors: ['rate<0.1'],
  },
};

const CATALOG_API_URL = 'http://localhost:8080';

export default function () {
  // Test 1: Get catalog items with API versioning
  let catalogResponse = http.get(`${CATALOG_API_URL}/api/catalog/items?api-version=1.0`, {
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  });

  check(catalogResponse, {
    'catalog API status is 200': (r) => r.status === 200,
    'catalog API response time < 500ms': (r) => r.timings.duration < 500,
    'catalog API returns JSON data': (r) => {
      try {
        const data = JSON.parse(r.body);
        return data && data.data && Array.isArray(data.data);
      } catch (e) {
        return false;
      }
    },
  }) || errorRate.add(1);
} 