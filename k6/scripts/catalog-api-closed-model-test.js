import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');

// Test configuration
export let options = {
  stages: [
    { duration: '30s', target: 50 },   // Ramp up to 50 users over 30 seconds
    { duration: '30s', target: 100 }, // Stay at 100 users for 30 seconds
    { duration: '30s', target: 200 }, // Stay at 200 users for 30 seconds
    { duration: '30s', target: 0 }, // Ramp down to 0 users in 30 seconds
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% of requests should be below 500ms
    http_req_failed: ['rate<0.1'],    // Error rate should be less than 10%
    errors: ['rate<0.1'],
  },
};

// Base URL for the catalog-api service (using Kubernetes service name)
const CATALOG_API_URL = 'http://catalog-api.default.svc.cluster.local:8080';

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